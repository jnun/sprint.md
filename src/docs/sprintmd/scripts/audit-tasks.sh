#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# audit-tasks.sh — Audit tasks for quality. See: ./sprint.sh help audit

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

folder="${1:-next}"
limit="${2:-0}"       # 0 = no limit
offset="${3:-0}"      # skip first N tasks

# Resolve folder name to path
case "$folder" in
    backlog|next|doing|blocked)
        dir="docs/tasks/$folder"
        ;;
    review|done)
        echo "Error: Cannot audit $folder/ — those are completed tasks." >&2
        echo "Audit is for finding stale, done, or undefined work in backlog, next, doing, or blocked." >&2
        exit 1
        ;;
    *)
        # Treat as a direct path for backwards compatibility
        dir="$folder"
        ;;
esac

# Support single-file audit: ./sprint.sh audit path/to/task.md
single_file=""
if [ -f "$dir" ]; then
    single_file="$dir"
elif [ ! -d "$dir" ]; then
    echo "Error: Not found: $dir" >&2
    exit 1
fi
timeout_sec=120       # kill hung AI CLI calls after this
# The per-task audit is a single-shot classification (verdict + reason). Cap
# turns so a misbehaving model can't burn a long session before the timeout
# fires. Consistent with define/sprint/split/review-sprint/triage.
MAX_TURNS=15
AI_MODE="$(fiveday_ai_mode)"

# The CLI binary is only required in exec mode; emit mode hands the prompt to
# the surrounding agent and never spawns it.
if [ "$AI_MODE" != "emit" ]; then
  command -v "$FIVEDAY_CLI" &>/dev/null || { echo "Error: AI CLI '$FIVEDAY_CLI' not found in PATH. Edit docs/sprintmd/config (CLI) or install the tool. Claude Code: https://docs.anthropic.com/en/docs/claude-code/overview" >&2; exit 1; }
fi

# Build --model args (empty = let CLI pick its own default)
_audit_model="$(fiveday_resolve_model AUDIT)"
_model_args=()
[ -n "$_audit_model" ] && _model_args=(--model "$_audit_model")

# Portable timeout comes from lib.sh (run_with_timeout SECONDS CMD…), which
# handles shell functions like fiveday_run via its watchdog path.

review_dir="docs/tasks/review"
blocked_dir="docs/tasks/blocked"

mkdir -p "$review_dir" "$blocked_dir"

# Get sorted list of numbered task files
if [ -n "$single_file" ]; then
  files=("$single_file")
else
  IFS=$'\n' files=($(
    find "$dir" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | if [ "$offset" -gt 0 ]; then tail -n +"$((offset + 1))"; else cat; fi \
      | if [ "$limit" -gt 0 ]; then head -"$limit"; else cat; fi \
      | sed "s|^|$dir/|"
  ))
  unset IFS
fi

total=${#files[@]}
run_log=""

# ── Emit mode: hand the whole audit to the surrounding agent ──────────
# In emit mode fiveday_run prints the prompt instead of running the CLI, so
# the per-task exec loop below cannot parse a verdict out of a command
# substitution (the emitted prompt text — which literally contains
# "DONE - …" — would be mis-read as the verdict and move every task to
# review/). Instead emit one combined prompt describing the whole audit,
# mirroring triage.sh.
if [ "$AI_MODE" = "emit" ]; then
  if [ "$total" -eq 0 ]; then
    echo "No tasks to audit in $folder/."
    exit 0
  fi
  _file_list=$(printf '%s\n' "${files[@]}")
  fiveday_run -p "You are auditing task files from $folder/ for the developer, one at a time.

CLAUDE.md is auto-loaded with project context and conventions. Read it first.

Task files to audit, in order:
$_file_list

For EACH task file in order:
1. Read the task file, then check the current codebase.
2. Decide EXACTLY ONE verdict:
   - DONE      — the work described is already present in the codebase
   - OUTDATED  — it references files/patterns/features that no longer exist
   - UNDEFINED — it is too vaguely defined to be actionable
   - KEEP      — still relevant, well-defined, and not yet completed
   Be conservative: if in doubt, KEEP.
3. Take the action for that verdict:
   - DONE      → move the file to docs/tasks/review/ (use 'git mv' if the
                 repo is a git working tree, else plain 'mv')
   - OUTDATED  → remove the file ('git rm' or plain 'rm')
   - UNDEFINED → insert a bold '**This task is not defined yet. Define it
                 first.**' note under its '## Problem' heading, then move it
                 to docs/tasks/blocked/
   - KEEP      → leave it in $folder/
4. Print one line per task: 'VERDICT | <taskname> | <one-line reason>'.

After all tasks, print a short summary count per verdict."
  exit 0
fi

echo "=== Task Audit ($folder): $total tasks (${timeout_sec}s timeout) ==="

for i in "${!files[@]}"; do
  file="${files[$i]}"
  idx=$((i + 1))
  taskname=$(basename "$file")
  echo ""
  echo "[$idx/$total] Auditing: $taskname"

  # Run claude with timeout
  _audit_prompt="You are auditing a task file from $folder/.

CLAUDE.md is auto-loaded with project context and conventions.
Read it first to understand the project's tech stack and structure.

Read the task file at: $file

Then check the current codebase to determine if this task has ALREADY been completed,
if the task references files/features that no longer exist or are unrecognizable,
or if the task is too vaguely defined to be actionable.

Your job is to output EXACTLY ONE of these verdicts on the first line, followed by
a brief one-line reason on the second line:

DONE - The task has already been completed (the features/fixes described exist in the codebase)
OUTDATED - The task references files, patterns, or features that no longer exist or are unrecognizable
UNDEFINED - The task is not defined well enough to work (missing problem statement, success criteria, or actionable details)
KEEP - The task is still relevant, well-defined, and not yet completed

Rules:
- Be conservative: if in doubt, say KEEP
- DONE means the specific work described is clearly present in the codebase
- OUTDATED means the task cannot be worked because its context is gone
- UNDEFINED means someone would need to rewrite the task before working it
- Only output the verdict line and reason line, nothing else"

  verdict=$(run_with_timeout "$timeout_sec" fiveday_run -p "$_audit_prompt" \
    ${_model_args[@]+"${_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions 2>/dev/null) || true

  # Parse verdict — scan for keyword (Sonnet sometimes buries it)
  action=$(echo "$verdict" | grep -oE '^(DONE|OUTDATED|UNDEFINED|KEEP)' | head -1 || true)
  if [ -z "$action" ]; then
    action=$(echo "$verdict" | grep -oE '\b(DONE|OUTDATED|UNDEFINED|KEEP)\b' | head -1 || true)
  fi
  [ -z "$action" ] && action="TIMEOUT"

  reason=$(echo "$verdict" | tail -1)
  [ -z "$reason" ] && reason="No response (timed out after ${timeout_sec}s)"

  echo "  Verdict: $action"
  echo "  Reason:  $reason"

  case "$action" in
    DONE)
      echo "  -> Moving to review/"
      git mv "$file" "$review_dir/" 2>/dev/null || mv "$file" "$review_dir/"
      run_log+="DONE | $taskname | $reason"$'\n'
      ;;
    OUTDATED)
      echo "  -> Removing (outdated)"
      git rm "$file" 2>/dev/null || rm "$file"
      run_log+="OUTDATED | $taskname | $reason"$'\n'
      ;;
    UNDEFINED)
      echo "  -> Marking as undefined, moving to blocked/"
      if grep -q '^## Problem' "$file"; then
        sed_inplace '/^## Problem$/a\
\
**This task is not defined yet. Define it first.**\
' "$file"
      else
        sed_inplace '1,/^#/{/^#/a\
\
## Problem\
\
**This task is not defined yet. Define it first.**\
}' "$file"
      fi
      git mv "$file" "$blocked_dir/" 2>/dev/null || mv "$file" "$blocked_dir/"
      run_log+="UNDEFINED | $taskname | $reason"$'\n'
      ;;
    KEEP)
      echo "  -> Keeping in $folder"
      run_log+="KEEP | $taskname | $reason"$'\n'
      ;;
    *)
      echo "  -> Timed out, keeping in $folder (retry later)"
      run_log+="TIMEOUT | $taskname | $reason"$'\n'
      ;;
  esac
done

echo ""
echo "=== Audit complete ==="
echo ""
echo "--- Summary (this run) ---"
echo "  Moved to review:  $(echo "$run_log" | grep -c '^DONE' || true)"
echo "  Removed (outdated): $(echo "$run_log" | grep -c '^OUTDATED' || true)"
echo "  Marked undefined: $(echo "$run_log" | grep -c '^UNDEFINED' || true)"
echo "  Kept in place:    $(echo "$run_log" | grep -c '^KEEP' || true)"
echo "  Timed out:        $(echo "$run_log" | grep -c '^TIMEOUT' || true)"
