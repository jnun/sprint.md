#!/usr/bin/env bash
# audit-excellence.sh — Excellence audit: judges finished work against a
# higher bar than "it runs". Single read-mostly pass; enhancements are filed
# as backlog tasks via ./sprint.sh newtask, never fixed inline.
# See: ./sprint.sh help excellence

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

MODEL="$(fiveday_resolve_model EXCELLENCE)"
TOOLS="Read,Grep,Glob,Bash,Edit,Agent"
PERMISSIONS="auto"
MAX_TURNS=30
LOG_DIR="docs/tmp"
PROTOCOL="docs/sprintmd/ai/audit-excellence.md"

# ── Parse arguments ─────────────────────────────────────────────────
# Accepts:
#   audit-excellence.sh <task-id>          (e.g. 203 — resolved to its file)
#   audit-excellence.sh <task.md>
#   audit-excellence.sh <file1> <file2> ...
TASK_FILE=""
EXPLICIT_FILES=()

if [ $# -eq 0 ]; then
  echo "Usage:" >&2
  echo "  audit-excellence.sh <task-id>" >&2
  echo "  audit-excellence.sh <task-file.md>" >&2
  echo "  audit-excellence.sh <file1> <file2> ..." >&2
  exit 1
fi

if [[ "$1" == *.md ]] && [ -f "$1" ]; then
  TASK_FILE="$1"
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  # Bare task ID. Excellence audits finished work, so search review first,
  # then the rest of the lifecycle. This is why we override the default
  # fiveday_find_task order (which is oriented toward not-yet-done work).
  if _res="$(fiveday_find_task "$1" \
      docs/tasks/review docs/tasks/done docs/tasks/doing \
      docs/tasks/blocked docs/tasks/next docs/tasks/backlog)"; then
    TASK_FILE="${_res%%$'\t'*}"
  else
    echo "✗ No task found with ID: $1" >&2
    exit 1
  fi
else
  for f in "$@"; do
    if [ -f "$f" ]; then
      EXPLICIT_FILES+=("$f")
    else
      echo "✗ File not found: $f" >&2
      exit 1
    fi
  done
fi

# ── Preflight ───────────────────────────────────────────────────────
if [ ! -f "$PROTOCOL" ]; then
  echo "✗ Protocol file missing: $PROTOCOL" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

# ── Build the change manifest ───────────────────────────────────────
# Priority: AUDIT_MANIFEST env > explicit files > task ## Completed > git diff
fiveday_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
CHANGED_FILES="$FIVEDAY_CHANGED_FILES"
CONTEXT_SOURCE="$FIVEDAY_CONTEXT_SOURCE"

if [ -z "$CHANGED_FILES" ]; then
  echo "▸ No changed files found — nothing to audit"
  echo "  Context source: $CONTEXT_SOURCE"
  echo ""
  echo "  Provide files explicitly:  ./sprint.sh excellence file1.py file2.ts"
  echo "  Or ensure the task has a ## Completed section listing changed files."
  exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
TASK_NAME=""
if [ -n "$TASK_FILE" ]; then
  TASK_NAME=$(basename "$TASK_FILE")
fi

echo "▸ Excellence audit: $FILE_COUNT file(s)${TASK_NAME:+ for: $TASK_NAME}"
echo "  Context source: $CONTEXT_SOURCE"
echo "  Files:"
echo "$CHANGED_FILES" | sed 's/^/    /'
echo ""

# ── Build prompt ────────────────────────────────────────────────────
if [ -n "$TASK_FILE" ]; then
  TASK_BLOCK="TASK FILE: $TASK_FILE

ORIGINAL TASK:
---
$(<"$TASK_FILE")
---"
else
  TASK_BLOCK="No task file provided. Audit the listed files directly; infer the
intended goal from the code and recent git history."
fi

PROFILE_LINE="$(fiveday_profile_line)"
AI_MODE="$(fiveday_ai_mode)"

# In emit mode the surrounding agent appends the report section itself; in
# exec mode this script appends it from the captured output.
APPEND_STEP=""
if [ "$AI_MODE" = "emit" ] && [ -n "$TASK_FILE" ]; then
  APPEND_STEP="
6. Append a '## Excellence' section to $TASK_FILE: date, verdict, and your
   Summary. Do not modify any other part of the task file."
fi

# The protocol is embedded rather than referenced: it costs the same tokens
# either way, saves the read round-trip, and can't be skimmed or skipped.
PROMPT="Excellence audit. CLAUDE.md is auto-loaded.${PROFILE_LINE}

Follow this protocol exactly. The two hard rules:
- You NEVER edit code — enhancements become backlog tasks, not edits.
- The work is presumed correct — you audit altitude, not syntax.

PROTOCOL ($PROTOCOL):
---
$(<"$PROTOCOL")
---

$TASK_BLOCK

CHANGED FILES:
$CHANGED_FILES

1. Read the task, the changed files, and their blast radius (grep for
   imports/references to the changed files).
2. Trace the end-to-end path as the person who will actually use this work.
3. Judge: effectiveness, efficiency, design fit, operability, robustness.
4. For each ENHANCEMENT finding, run: ./sprint.sh newtask \"<description>\"
   then append Why and Scope to the created task file in docs/tasks/backlog/.
5. Output the report per the protocol. Your VERY LAST line must be the verdict
   and nothing after it — the literal word VERDICT, a colon, a space, then ONE
   uppercase token (EXCELLENT, FILED, or BLOCKER), no bold. A short reason may
   follow the token:
   VERDICT: EXCELLENT | VERDICT: FILED — <n> enhancement task(s) | VERDICT: BLOCKER — <reason>$APPEND_STEP"

# ── Run ─────────────────────────────────────────────────────────────
_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")
_budget_args=()
[ -n "${FIVEDAY_BUDGET_AUDIT:-}" ] && _budget_args=(--budget "$FIVEDAY_BUDGET_AUDIT")

# Emit mode: print the prompt for the surrounding agent — nothing to parse.
# (Checked via AI_MODE, not fiveday_emitted: the exec path below runs
# fiveday_run in a command substitution, where the mode flag can't propagate.)
if [ "$AI_MODE" = "emit" ]; then
  fiveday_run -p "$PROMPT"
  exit 0
fi

LOG_FILE="$(fiveday_log_path excellence "${TASK_NAME:-adhoc}")"

OUTPUT=$(fiveday_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  ${_budget_args[@]+"${_budget_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS" \
  --output-format json 2>/dev/null | tee "$LOG_FILE") || true

# ── Parse result (exec mode) ────────────────────────────────────────
VERDICT=$(printf '%s' "$OUTPUT" | fiveday_parse_verdict 'EXCELLENT|FILED|BLOCKER')
[ -z "$VERDICT" ] && VERDICT="UNCLEAR"

SUMMARY=$(fiveday_extract_summary "$LOG_FILE")

# grep -o, not -c: the JSON result is one physical line, so -c would report
# at most 1 no matter how many tasks were filed.
FILED_COUNT=$(echo "$OUTPUT" | grep -oE 'FILED: docs/tasks/backlog/' | wc -l | tr -d ' ' || true)

# ── Append report to task file ──────────────────────────────────────
if [ -n "$TASK_FILE" ]; then
  {
    echo ""
    echo "## Excellence"
    echo ""
    echo "- **Date**: $(date +%Y-%m-%d)"
    echo "- **Verdict**: $VERDICT"
    echo "- **Tasks filed**: $FILED_COUNT"
    echo "- **Files reviewed**: $FILE_COUNT"
    echo "- **Context source**: $CONTEXT_SOURCE"
    echo ""
    echo "$SUMMARY"
  } >> "$TASK_FILE" \
    || echo "⚠ Could not append ## Excellence section to $TASK_FILE (see $LOG_FILE)"
fi

echo ""
case "$VERDICT" in
  EXCELLENT)
    echo "✓ Excellence audit: meets the bar — nothing filed"
    exit 0
    ;;
  FILED)
    echo "✓ Excellence audit: $FILED_COUNT enhancement task(s) filed to docs/tasks/backlog/"
    exit 0
    ;;
  BLOCKER)
    echo "✗ Excellence audit: BLOCKER — the work does not meet its own task's goal"
    echo "  See ${TASK_FILE:-$LOG_FILE} for details"
    exit 1
    ;;
  *)
    echo "? Excellence audit: could not parse a verdict — see $LOG_FILE"
    if [ ! -s "$LOG_FILE" ]; then
      echo "  Log is empty — the AI CLI likely failed to start (check '$FIVEDAY_CLI' install/auth)"
    fi
    exit 1
    ;;
esac
