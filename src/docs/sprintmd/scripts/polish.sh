#!/usr/bin/env bash
# polish.sh — Serialized excellence pass over review/. Judges each finished
# task in its OWN fresh context; when a second execution pass would close a
# real gap, it rewrites the task with concrete improvements and reopens it to
# next/ so `tasks` re-runs it. See: ./sprint.sh help polish
#
# Contrast with `excellence`: excellence never moves the task and files
# *separate* backlog tasks. polish reopens the SAME task for another pass.
# A per-task round cap stops a task from reopening forever.

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

MODEL="$(fiveday_resolve_model POLISH)"
TOOLS="Read,Edit,Grep,Glob,Bash,Agent"
PERMISSIONS="auto"
MAX_TURNS=30
PROTOCOL="docs/sprintmd/ai/refine.md"

REVIEW_DIR="docs/tasks/review"
NEXT_DIR="docs/tasks/next"
LOG_DIR="docs/tmp"

# ── Argument parsing ────────────────────────────────────────────────
# polish [limit] [--rounds N] [--max] [--force]
MAX_TASKS=999
MAX_ROUNDS=1          # how many times a single task may be reopened
_NO_LIMITS=0
FORCE=0
_next_is_rounds=0
for arg in "$@"; do
  if [ "$_next_is_rounds" -eq 1 ]; then
    MAX_ROUNDS="$arg"; _next_is_rounds=0; continue
  fi
  case "$arg" in
    --rounds) _next_is_rounds=1 ;;
    --max)    _NO_LIMITS=1 ;;
    --force)  FORCE=1 ;;
    [0-9]*)   MAX_TASKS="$arg" ;;
  esac
done
unset _next_is_rounds

if ! [[ "$MAX_ROUNDS" =~ ^[0-9]+$ ]]; then
  echo "✗ --rounds needs a number (got: $MAX_ROUNDS)" >&2
  exit 1
fi

if [ "$_NO_LIMITS" -eq 1 ]; then
  FIVEDAY_BUDGET_AUDIT=""
fi
unset _NO_LIMITS

# ── Preflight ───────────────────────────────────────────────────────
if [ ! -f "$PROTOCOL" ]; then
  echo "✗ Protocol file missing: $PROTOCOL" >&2
  exit 1
fi
for dir in "$REVIEW_DIR" "$NEXT_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing directory: $dir" >&2
    exit 1
  fi
done
mkdir -p "$LOG_DIR"

AI_MODE="$(fiveday_ai_mode)"

# ── Collect tasks (review/, sorted by leading number) ────────────────
TASK_FILES=()
while IFS= read -r f; do
  TASK_FILES+=("$f")
done < <(
  ls -1 "$REVIEW_DIR"/*.md 2>/dev/null \
    | sed 's|.*/||' \
    | sort -t- -k1,1n \
    | sed "s|^|$REVIEW_DIR/|"
)

if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No tasks in $REVIEW_DIR — nothing to polish"
  exit 0
fi

# ── Round cap ────────────────────────────────────────────────────────
# A task carries one '## Refine (round N)' section per reopen. Once it has
# been reopened MAX_ROUNDS times it is capped: judged no further, left in
# review/ for a human. --force bypasses the cap for a one-off deeper pass.
# _refine_round FILE -> number of '## Refine' sections already present.
# grep -c prints "0" and exits 1 on no match, so capture and swallow the exit
# rather than chaining '|| echo 0' (which would print a second line).
_refine_round() { local n; n=$(grep -c '^## Refine' "$1" 2>/dev/null) || true; echo "${n:-0}"; }

ELIGIBLE=()
CAPPED=()
for f in "${TASK_FILES[@]}"; do
  if [ "$FORCE" -ne 1 ] && [ "$(_refine_round "$f")" -ge "$MAX_ROUNDS" ]; then
    CAPPED+=("$f")
  else
    ELIGIBLE+=("$f")
  fi
done

if [ ${#CAPPED[@]} -gt 0 ]; then
  echo "⊘ Skipping ${#CAPPED[@]} task(s) already at the round cap ($MAX_ROUNDS):"
  for f in "${CAPPED[@]}"; do echo "    ${f##*/}"; done
  echo "  Re-polish anyway:  ./sprint.sh polish --force"
  echo ""
fi

TASK_FILES=(${ELIGIBLE[@]+"${ELIGIBLE[@]}"})
if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No eligible tasks to polish in $REVIEW_DIR"
  exit 0
fi

COUNT=${#TASK_FILES[@]}
[ "$COUNT" -gt "$MAX_TASKS" ] && COUNT=$MAX_TASKS

echo "▸ $COUNT task(s) queued from $REVIEW_DIR (round cap: $MAX_ROUNDS)"
echo ""

# ── Shared prompt builder ───────────────────────────────────────────
# Builds the refine prompt for one task file, embedding the protocol, the
# task, its changed files, and the round number to stamp. Used by both exec
# (nested CLI) and the emit fallbacks.
_refine_prompt() {
  local task_file="$1" next_round="$2"
  fiveday_change_manifest "$task_file"
  local changed="$FIVEDAY_CHANGED_FILES"
  local ctx="$FIVEDAY_CONTEXT_SOURCE"
  local profile_line; profile_line="$(fiveday_profile_line)"

  local changed_block
  if [ -n "$changed" ]; then
    changed_block="CHANGED FILES (source: $ctx):
$changed"
  else
    changed_block="CHANGED FILES: none detected ($ctx). Infer the change from
the task's ## Completed section and recent git history."
  fi

  cat <<PROMPT
Refine pass on ONE finished task. CLAUDE.md is auto-loaded.${profile_line}

Follow this protocol exactly. The hard rules:
- You NEVER edit product code — your only write is this task file.
- The work is presumed correct — you judge altitude, not syntax.
- Reopen only when a second execution pass would close a real, bounded gap.
- If you reopen, title the appended section exactly: ## Refine (round $next_round)

PROTOCOL ($PROTOCOL):
---
$(<"$PROTOCOL")
---

TASK FILE: $task_file

ORIGINAL TASK:
---
$(<"$task_file")
---

$changed_block

Steps:
1. Read the task (header included), the changed files, and their blast radius.
2. Trace the end-to-end path; judge the excellence dimensions.
3. Decide: PASS, REOPEN, or BLOCKER per the protocol's reopen test.
4. If REOPEN: use Edit to APPEND a '## Refine (round $next_round)' section to
   $task_file with a Why and an unchecked '- [ ]' improvement checklist.
   Do not alter the task's existing Success criteria, ## Completed section, or
   its '**Status: READY**' stamp.
5. Output the report per the protocol. Your VERY LAST line must be the verdict
   and nothing after it:
   VERDICT: PASS | VERDICT: REOPEN — <n> improvement(s) | VERDICT: BLOCKER — <reason>
PROMPT
}

# ── Emit mode: hand the queue to the surrounding agent ───────────────
# Mirrors tasks.sh: on the claude-code tier the driver has a subagent tool, so
# we emit an orchestration plan — one FRESH subagent per task so contexts never
# mix. Other tiers get an honest sequential fallback. Routing rules are shared
# so the two paths can't drift.
if [ "$AI_MODE" = "emit" ]; then
  _profile_line="$(fiveday_profile_line)"

  _task_list=""
  for ((i=0; i<COUNT; i++)); do
    _f="${TASK_FILES[$i]}"
    _n=$(( $(_refine_round "$_f") + 1 ))
    _task_list="${_task_list}
- ${_f}  (next round: $_n)"
  done

  _RULES="Follow docs/sprintmd/ai/refine.md exactly. You never edit product
code — your only write is the task file. Reopen only when a second execution
pass would close a real, bounded gap; otherwise PASS. If you reopen, APPEND a
'## Refine (round N)' section (use the next-round number shown for that task)
with a Why and an unchecked '- [ ]' checklist, and leave the task's existing
Success criteria, ## Completed, and '**Status: READY**' stamp untouched. End
with: VERDICT: PASS | REOPEN — <n> | BLOCKER — <reason>."

  if [ "$(fiveday_ai_tier)" = "claude-code" ]; then
    fiveday_run -p "You are running the sprint.md polish queue: $COUNT finished
task(s) in review/ to judge. CLAUDE.md is auto-loaded.${_profile_line}

Judge each task in its OWN fresh subagent (Task tool) so contexts never mix.
You are the orchestrator — the subagents judge and rewrite; you move the files.

For EACH task file below:
1. Launch a subagent whose entire instruction is:
     \"Refine ONE finished task. Read the task file at <path> and judge it.
$_RULES\"
2. When it returns, read the task file and route by the subagent's verdict:
   - REOPEN (it appended a '## Refine (round N)' section) → git mv <path> $NEXT_DIR/
   - PASS    → leave it in $REVIEW_DIR/
   - BLOCKER → leave it in $REVIEW_DIR/ (note it for the human)

Tasks (in order):$_task_list

When every task is routed, report a one-line summary: how many reopened to
next/ vs left in review/ (and any blockers)."
  else
    fiveday_run -p "You are running the sprint.md polish queue: $COUNT finished
task(s) in review/ to judge. CLAUDE.md is auto-loaded.${_profile_line}

Work the tasks ONE AT A TIME, in the listed order. You have no subagent tool,
so you are the judge, not an orchestrator — after each task, reset your focus
and start the next from a clean slate.

For EACH task file below:
1. Read the task file at <path> and judge it.
$_RULES
2. Route by your verdict:
   - REOPEN (you appended a '## Refine (round N)' section) → git mv <path> $NEXT_DIR/
   - PASS    → leave it in $REVIEW_DIR/
   - BLOCKER → leave it in $REVIEW_DIR/ (note it for the human)

Tasks (in order):$_task_list

When every task is routed, report a one-line summary: how many reopened to
next/ vs left in review/ (and any blockers)."
  fi
  exit 0
fi

# ── Exec mode: nested CLI, one fresh context per task ────────────────
REOPENED=0
PASSED=0
BLOCKED=0
UNCLEAR=0
TOTAL_START=$SECONDS

_model_args=();  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
_budget_args=(); [ -n "${FIVEDAY_BUDGET_AUDIT:-}" ] && _budget_args=(--budget "$FIVEDAY_BUDGET_AUDIT")

for ((i=0; i<COUNT; i++)); do
  TASK_FILE="${TASK_FILES[$i]}"
  TASK_NAME="${TASK_FILE##*/}"
  N=$((i + 1))
  TASK_START=$SECONDS
  BEFORE_ROUNDS="$(_refine_round "$TASK_FILE")"
  NEXT_ROUND=$((BEFORE_ROUNDS + 1))

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Polish $N/$COUNT: $TASK_NAME (round $NEXT_ROUND)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  LOG_FILE="$(fiveday_log_path polish "$TASK_NAME")"

  OUTPUT=$(fiveday_run -p "$(_refine_prompt "$TASK_FILE" "$NEXT_ROUND")" \
    ${_model_args[@]+"${_model_args[@]}"} \
    ${_budget_args[@]+"${_budget_args[@]}"} \
    --tools "$TOOLS" \
    --permissions "$PERMISSIONS" \
    --max-turns "$MAX_TURNS" \
    --output-format json 2>/dev/null | tee "$LOG_FILE") || true

  VERDICT=$(printf '%s' "$OUTPUT" | fiveday_parse_verdict 'PASS|REOPEN|BLOCKER')
  [ -z "$VERDICT" ] && VERDICT="UNCLEAR"
  AFTER_ROUNDS="$(_refine_round "$TASK_FILE")"

  case "$VERDICT" in
    REOPEN)
      # Only move if the audit actually appended its Refine section — a REOPEN
      # verdict with no new section means the Edit step was skipped; do not
      # ship a task back to next/ with no new work in it.
      if [ "$AFTER_ROUNDS" -gt "$BEFORE_ROUNDS" ]; then
        move_file "$TASK_FILE" "$NEXT_DIR/$TASK_NAME"
        REOPENED=$((REOPENED + 1))
        echo "  ↩ Reopened → $NEXT_DIR/$TASK_NAME (round $NEXT_ROUND queued for tasks)"
      else
        PASSED=$((PASSED + 1))
        echo "  ⚠ Verdict REOPEN but no '## Refine' section was written — left in review/"
        echo "    Log: $LOG_FILE"
      fi
      ;;
    PASS)
      PASSED=$((PASSED + 1))
      echo "  ✓ Meets the bar — left in review/"
      ;;
    BLOCKER)
      BLOCKED=$((BLOCKED + 1))
      echo "  ✗ BLOCKER — needs a human, not a re-run. Left in review/"
      echo "    See $TASK_FILE (or $LOG_FILE)"
      ;;
    *)
      UNCLEAR=$((UNCLEAR + 1))
      echo "  ? Could not parse a verdict — left in review/. See $LOG_FILE"
      [ -s "$LOG_FILE" ] || echo "    Log is empty — the AI CLI likely failed to start (check '$FIVEDAY_CLI')"
      ;;
  esac

  TASK_ELAPSED=$((SECONDS - TASK_START))
  echo "⏱ Elapsed: $((TASK_ELAPSED / 60))m $((TASK_ELAPSED % 60))s"
  echo ""
done

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Done: $REOPENED reopened → next/, $PASSED passed, $BLOCKED blocker(s), $UNCLEAR unclear — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s"
if [ "$REOPENED" -gt 0 ]; then
  echo "  ↩ Run ./sprint.sh tasks to re-execute the $REOPENED reopened task(s)."
fi
