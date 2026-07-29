#!/usr/bin/env bash
# loop.sh — Continuous task runner. See: ./sprint.sh help loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ────────────────────────────────────────────────────────
MAX_HOURS=0
MAX_ATTEMPTS=0
COOLDOWN=10
REFILL=0
REFILL_SIZE=5
RETRY=0
PASSTHROUGH=()

# ── Argument parsing ────────────────────────────────────────────────
# --hours/--max/--cooldown take a numeric value. Validate it here: unlike
# tasks.sh's boolean --max, loop's --max expects a count, so a bare
# `loop --max --audit` would otherwise capture "--audit" as the limit, and
# every later `[ "$MAX_ATTEMPTS" -gt 0 ]` test would error to stderr and never
# trip — a silent runaway. Reject a missing or non-integer value up front.
_require_int() {  # _require_int FLAG VALUE
  if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "✗ $1 needs a whole number, got '${2:-}'" >&2
    echo "  e.g. ./sprint.sh loop $1 10" >&2
    exit 1
  fi
}
while [ $# -gt 0 ]; do
  case "$1" in
    --hours)     _require_int --hours "${2:-}";    MAX_HOURS="$2"; shift 2 ;;
    --max)       _require_int --max "${2:-}";       MAX_ATTEMPTS="$2"; shift 2 ;;
    --cooldown)  _require_int --cooldown "${2:-}";  COOLDOWN="$2"; shift 2 ;;
    --refill)    REFILL=1
                 if [ $# -gt 1 ] && [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" != "0" ]; then
                   REFILL_SIZE="$2"; shift
                 fi
                 shift ;;
    --retry)     RETRY=1; shift ;;
    *)           PASSTHROUGH+=("$1"); shift ;;
  esac
done

# ── Directories ─────────────────────────────────────────────────────
NEXT_DIR="docs/tasks/next"
DOING_DIR="docs/tasks/doing"
BLOCKED_DIR="docs/tasks/blocked"
REVIEW_DIR="docs/tasks/review"
BACKLOG_DIR="docs/tasks/backlog"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── State ───────────────────────────────────────────────────────────
COMPLETED=0
FAILED=0
RETRIED=0
REFILLS=0
TOTAL_START=$SECONDS
_RETRY_USED=0

# Snapshot pre-existing blocked tasks so retry only touches new ones
_INITIAL_BLOCKED=$(mktemp)
trap 'rm -f "$_INITIAL_BLOCKED"' EXIT
ls "$BLOCKED_DIR"/*.md 2>/dev/null | while read -r f; do basename "$f"; done > "$_INITIAL_BLOCKED" 2>/dev/null || true

# ── Helpers ─────────────────────────────────────────────────────────
count_tasks() { find "$1" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '; }

# The limit is checked between iterations, not mid-task. A task that starts at
# 3h59m of a 4h cap runs to completion — deliberate: killing a task mid-flight
# would strand a half-edited tree, and the CLI's own --budget cap already bounds
# a single run. Treat --hours as "stop starting new work after N hours".
time_up() {
  [ "$MAX_HOURS" -gt 0 ] || return 1
  local elapsed=$(( SECONDS - TOTAL_START ))
  local limit=$(( MAX_HOURS * 3600 ))
  [ "$elapsed" -ge "$limit" ]
}

attempts_up() {
  [ "$MAX_ATTEMPTS" -gt 0 ] && [ $(( COMPLETED + FAILED )) -ge "$MAX_ATTEMPTS" ]
}

status_line() {
  local next_n blocked_n review_n doing_n elapsed
  next_n=$(count_tasks "$NEXT_DIR")
  blocked_n=$(count_tasks "$BLOCKED_DIR")
  review_n=$(count_tasks "$REVIEW_DIR")
  doing_n=$(count_tasks "$DOING_DIR")
  elapsed=$(( SECONDS - TOTAL_START ))
  echo ""
  echo "  ┌─ Loop ─────────────────────────────────"
  echo "  │  ✓ $COMPLETED completed  ✗ $FAILED failed"
  echo "  │  ↻ $RETRIED retried  ⟳ $REFILLS refills"
  echo "  │  Queue: $next_n next, $doing_n doing, $blocked_n blocked, $review_n review"
  printf '  │  Elapsed: %dh %dm %ds\n' "$((elapsed/3600))" "$(((elapsed%3600)/60))" "$((elapsed%60))"
  echo "  └────────────────────────────────────────"
  echo ""
}

cleanup_and_exit() {
  echo ""
  status_line
  echo "▸ Loop interrupted."
  rm -f "$_INITIAL_BLOCKED"
  exit 130
}
trap cleanup_and_exit INT TERM

# ── Preflight ───────────────────────────────────────────────────────
for dir in "$NEXT_DIR" "$DOING_DIR" "$BLOCKED_DIR" "$REVIEW_DIR"; do
  [ -d "$dir" ] || { echo "✗ Missing: $dir"; exit 1; }
done

# ── Recover orphaned doing/ tasks ───────────────────────────────────
DOING_COUNT=$(count_tasks "$DOING_DIR")
if [ "$DOING_COUNT" -gt 0 ]; then
  echo "⚠ Found $DOING_COUNT task(s) in doing/ from an interrupted run"
  for f in "$DOING_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    move_file "$f" "$NEXT_DIR/$name"
    echo "  ↻ $name → next/"
  done
  echo ""
fi

# ── Banner ──────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ sprint.md Loop Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Queue:      $(count_tasks "$NEXT_DIR") tasks in next/"
echo "  Blocked:    $(count_tasks "$BLOCKED_DIR") in blocked/"
echo "  Backlog:    $(count_tasks "$BACKLOG_DIR") in backlog/"
[ "$MAX_HOURS" -gt 0 ]    && echo "  Time limit: ${MAX_HOURS}h"
[ "$MAX_ATTEMPTS" -gt 0 ] && echo "  Task limit: $MAX_ATTEMPTS"
echo "  Cooldown:   ${COOLDOWN}s"
[ "$REFILL" -eq 1 ]       && echo "  Refill:     plan $REFILL_SIZE when empty"
[ "$RETRY" -eq 1 ]        && echo "  Retry:      re-queue newly-blocked tasks (once)"
[ ${#PASSTHROUGH[@]} -gt 0 ] && echo "  Flags:      ${PASSTHROUGH[*]}"
echo ""

# ── Main loop ───────────────────────────────────────────────────────
ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  # ── Check limits ────────────────────────────────────────────────
  if time_up; then
    echo "▸ Time limit reached (${MAX_HOURS}h)"
    break
  fi
  if attempts_up; then
    echo "▸ Task limit reached ($MAX_ATTEMPTS)"
    break
  fi

  NEXT_COUNT=$(count_tasks "$NEXT_DIR")

  # ── Retry: re-queue tasks blocked during this run ───────────────
  if [ "$NEXT_COUNT" -eq 0 ] && [ "$RETRY" -eq 1 ] && [ "$_RETRY_USED" -eq 0 ]; then
    _RETRY_USED=1
    _retried_any=0
    for f in "$BLOCKED_DIR"/*.md; do
      [ -f "$f" ] || continue
      name="${f##*/}"
      # Only retry tasks that weren't already blocked before this run
      if ! grep -qxF "$name" "$_INITIAL_BLOCKED" 2>/dev/null; then
        move_file "$f" "$NEXT_DIR/$name"
        RETRIED=$((RETRIED + 1))
        _retried_any=1
        echo "  ↻ Retrying: $name"
      fi
    done
    [ "$_retried_any" -eq 1 ] && echo ""
    NEXT_COUNT=$(count_tasks "$NEXT_DIR")
  fi

  # ── Refill: plan + define from backlog ──────────────────────────
  if [ "$NEXT_COUNT" -eq 0 ] && [ "$REFILL" -eq 1 ]; then
    BACKLOG_COUNT=$(count_tasks "$BACKLOG_DIR")
    if [ "$BACKLOG_COUNT" -gt 0 ]; then
      echo "▸ Refilling from backlog ($BACKLOG_COUNT available)..."
      # stdin redirect auto-approves plan's confirmation prompt
      bash "$SCRIPT_DIR/plan.sh" "$REFILL_SIZE" < /dev/null || true
      bash "$SCRIPT_DIR/define.sh" < /dev/null || true
      REFILLS=$((REFILLS + 1))
      NEXT_COUNT=$(count_tasks "$NEXT_DIR")
      echo ""
    fi
  fi

  # ── Nothing left ────────────────────────────────────────────────
  if [ "$NEXT_COUNT" -eq 0 ]; then
    echo "▸ No tasks remaining in next/"
    break
  fi

  # ── Identify next task ──────────────────────────────────────────
  CURRENT_TASK=$(ls -1 "$NEXT_DIR"/*.md 2>/dev/null | sed 's|.*/||' | sort -t- -k1,1n | head -1)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Iteration $ITERATION: $CURRENT_TASK ($NEXT_COUNT in queue)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # ── Run one task ────────────────────────────────────────────────
  BEFORE_REVIEW=$(count_tasks "$REVIEW_DIR")
  BEFORE_BLOCKED=$(count_tasks "$BLOCKED_DIR")

  bash "$SCRIPT_DIR/tasks.sh" 1 "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}" || true

  # Rescue any task left in doing/ (crash recovery)
  for f in "$DOING_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    move_file "$f" "$BLOCKED_DIR/$name"
    echo "  ⚠ $name incomplete → blocked/"
  done

  AFTER_REVIEW=$(count_tasks "$REVIEW_DIR")
  AFTER_BLOCKED=$(count_tasks "$BLOCKED_DIR")
  AFTER_NEXT=$(count_tasks "$NEXT_DIR")

  # Nothing moved at all → the runner's readiness gate declined every task.
  # Iterating again would spin forever on the same undefined queue.
  if [ "$AFTER_NEXT" -eq "$NEXT_COUNT" ] && [ "$AFTER_REVIEW" -eq "$BEFORE_REVIEW" ] \
     && [ "$AFTER_BLOCKED" -eq "$BEFORE_BLOCKED" ]; then
    echo "▸ No progress — $AFTER_NEXT task(s) in next/ but none are ready to execute."
    echo "  Vet them with ./sprint.sh define, or loop with --force."
    break
  fi

  if [ "$AFTER_REVIEW" -gt "$BEFORE_REVIEW" ]; then
    COMPLETED=$((COMPLETED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  status_line

  # ── Cooldown ────────────────────────────────────────────────────
  NEXT_COUNT=$(count_tasks "$NEXT_DIR")
  if [ "$COOLDOWN" -gt 0 ] && [ "$NEXT_COUNT" -gt 0 ]; then
    echo "  ⏳ ${COOLDOWN}s cooldown"
    sleep "$COOLDOWN"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────
TOTAL_ELAPSED=$(( SECONDS - TOTAL_START ))
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Loop complete"
echo "  Completed: $COMPLETED"
echo "  Failed:    $FAILED"
echo "  Retried:   $RETRIED"
echo "  Refills:   $REFILLS"
printf '  Duration:  %dh %dm %ds\n' "$((TOTAL_ELAPSED/3600))" "$(((TOTAL_ELAPSED%3600)/60))" "$((TOTAL_ELAPSED%60))"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
