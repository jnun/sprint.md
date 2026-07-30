#!/usr/bin/env bash
# plan-start.sh — Commit a plan's members into next/ (the sprint).
# See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan start [id] [--commit-only]
#
# next/ IS the sprint, so workability is decided BEFORE a member enters it: each
# backlog member is run through the shared workability gate (gate-lib.sh — same
# code `./sprint.sh gate` runs) while still in backlog/ — READY is promoted into
# next/, BLOCKED lands in blocked/ (never visits next/), DONE goes to review/.
# --commit-only skips the gate and does the pure, deterministic backlog→next mv
# (power users, tests, non-AI environments).
#
# Location-aware regardless of mode: next=idempotent, already-blocked=stop,
# past=skip, missing=hard error. Moves use move_file (git mv || mv); developer owns commits.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# Shared workability review — same implementation as `./sprint.sh gate`. Both
# surfaces call one library so their verdicts and rules never drift.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

PLANS_DIR="docs/plans"
NEXT_DIR="docs/tasks/next"
BLOCKED_DIR="docs/tasks/blocked"
REVIEW_DIR="docs/tasks/review"

# ── Args: plan id (any position) + optional --commit-only ────────────
COMMIT_ONLY=0
PLAN_ID=""
for _arg in "$@"; do
  case "$_arg" in
    --commit-only) COMMIT_ONLY=1 ;;
    *) [ -z "$PLAN_ID" ] && PLAN_ID="$_arg" ;;
  esac
done
unset _arg

# ── Plan helpers ─────────────────────────────────────────────────────

list_plans() {
  local f id title status
  for f in "$PLANS_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
    id=$(basename "$f" | grep -oE '^[0-9]+' || true)
    [ -n "$id" ] || continue
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//; s/^Plan [0-9]*: *//')
    status=$(grep -m1 -E '^\*\*Status:\*\*' "$f" 2>/dev/null | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')
    [ -n "$status" ] || status="(no status)"
    printf '  %s  %s  [%s]\n' "$id" "${title:-$(basename "$f" .md)}" "$status"
  done
}

find_plan() {
  local id="$1" match
  match=$(find "$PLANS_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
  [ -n "$match" ] && printf '%s' "$match" && return 0
  return 1
}

plan_status() {
  grep -m1 -E '^\*\*Status:\*\*' "$1" 2>/dev/null \
    | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]' || true
}

# STARTED latch: set-or-replace the **Status:** line to STARTED (one-way).
# Idempotent — re-running plan start just re-stamps the single status line; it
# never appends a duplicate. Set regardless of how many members moved this run,
# because STARTED means "this plan has been committed to the sprint," not
# "members moved just now." Only DRAFT | READY are ever replaced here.
stamp_started() {
  local f="$1"
  if grep -qE '^\*\*Status:\*\*' "$f" 2>/dev/null; then
    sed_inplace 's/^\*\*Status:\*\*.*/**Status:** STARTED/' "$f"
  else
    # No status line at all (malformed plan) — append one; plan_status reads the
    # first match, so a single appended line still reports STARTED.
    printf '\n**Status:** STARTED\n' >> "$f"
  fi
}

# Extract ## Goal body (until next ## heading), first non-empty lines collapsed.
plan_goal_text() {
  local f="$1"
  awk '
    BEGIN{g=0}
    /^## Goal/{g=1; next}
    g && /^## /{exit}
    g && NF{print}
  ' "$f" | head -5 | tr '\n' ' ' | sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//'
}

# Find task file by id across all stages. Prints "path<TAB>stage" or returns 1.
resolve_member() {
  local id="$1" stage dir match
  for stage in backlog next doing blocked review done; do
    dir="docs/tasks/$stage"
    match=$(find "$dir" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
    if [ -n "$match" ]; then
      printf '%s\t%s' "$match" "$stage"
      return 0
    fi
  done
  return 1
}

# ── Pick / resolve plan ──────────────────────────────────────────────

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan start — pick a plan to commit into next/"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans yet. Author one first:"
    echo "  ./sprint.sh newplan \"<name>\""
    echo "  ./sprint.sh chat plan <id>"
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to start (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh plan start <id>"
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan start [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

STATUS="$(plan_status "$PLAN_FILE")"
[ -n "$STATUS" ] || STATUS="(none)"

echo "▸ Starting plan: $(basename "$PLAN_FILE")"
echo "  Status: $STATUS"
echo ""

# DRAFT warning — interactive may proceed; non-interactive refuses.
if [ "$STATUS" != "READY" ]; then
  echo "⚠ Plan is not marked READY (status: $STATUS)."
  echo "  Author/refine with: ./sprint.sh chat plan $PLAN_ID"
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Start it anyway? [y/N]: "
    read -r _ans </dev/tty 2>/dev/null || _ans="n"
    case "$_ans" in
      y|Y|yes|YES) echo "  Proceeding with DRAFT plan..." ;;
      *) echo "Cancelled."; exit 0 ;;
    esac
  else
    echo "  Non-interactive start requires **Status:** READY (loop --refill only starts READY plans)."
    exit 1
  fi
  echo ""
fi

# ── Collect members ──────────────────────────────────────────────────

MEMBER_IDS=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$PLAN_FILE" 2>/dev/null | grep -oE '[0-9]+' | awk '!seen[$0]++' || true)
if [ -z "$MEMBER_IDS" ]; then
  echo "Plan $PLAN_ID has no member tasks."
  echo "Add members with: ./sprint.sh chat plan $PLAN_ID"
  exit 1
fi

mkdir -p "$NEXT_DIR"

# Preflight: classify every member before any move.
declare -a MOVE_PATHS=() MOVE_NAMES=()
declare -a SKIP_NEXT=() SKIP_PAST=()
declare -a BLOCKED_IDS=() MISSING_IDS=()

for id in $MEMBER_IDS; do
  if ! hit=$(resolve_member "$id"); then
    MISSING_IDS+=("$id")
    continue
  fi
  fpath="${hit%%$'\t'*}"
  stage="${hit##*$'\t'}"
  name=$(basename "$fpath")
  case "$stage" in
    backlog)
      MOVE_PATHS+=("$fpath")
      MOVE_NAMES+=("$name")
      ;;
    next)
      SKIP_NEXT+=("#$id $name")
      ;;
    blocked)
      BLOCKED_IDS+=("$id")
      ;;
    doing|review|done)
      SKIP_PAST+=("#$id $name ($stage/)")
      ;;
  esac
done

# Hard errors first: dangling members
if [ ${#MISSING_IDS[@]} -gt 0 ]; then
  echo "✗ Dangling member(s) — no task file found:"
  for id in "${MISSING_IDS[@]}"; do
    echo "    #$id"
  done
  echo "  Fix the plan member list (chat plan $PLAN_ID) and re-run."
  exit 1
fi

# Blocked: stop entirely so the sprint is not half-committed around undefined work
if [ ${#BLOCKED_IDS[@]} -gt 0 ]; then
  echo "✗ Member(s) still in blocked/ — define them before starting this plan:"
  for id in "${BLOCKED_IDS[@]}"; do
    echo "    ./sprint.sh chat $id"
  done
  echo "  Then re-run: ./sprint.sh plan start $PLAN_ID"
  exit 1
fi

# Notices for skips
if [ ${#SKIP_NEXT[@]} -gt 0 ]; then
  for line in "${SKIP_NEXT[@]}"; do
    echo "  · already in next/: $line"
  done
fi
if [ ${#SKIP_PAST[@]} -gt 0 ]; then
  for line in "${SKIP_PAST[@]}"; do
    echo "  · past next/ (skipped): $line"
  done
fi

# ── Promote backlog members ──────────────────────────────────────────
# Default: gate each member IN PLACE (still in backlog/) before it can enter
# next/. Only READY is promoted; BLOCKED never touches the sprint. --commit-only
# skips the gate for the pure, deterministic filesystem promote.

READY_MOVED=0   # READY members that reached next/
BLOCKED_CT=0    # graded BLOCKED, landed in blocked/
DONE_CT=0       # graded DONE, landed in review/
ERR_CT=0        # gate errored, member left in backlog/
EMITTED=0       # a review prompt was emitted for the surrounding agent to run

if [ "$COMMIT_ONLY" -eq 1 ]; then
  # Pure filesystem promote — no AI, no vetting. For power users, tests, and
  # non-AI environments that want today's raw backlog→next mv.
  if [ ${#MOVE_PATHS[@]} -gt 0 ]; then
    i=0
    while [ "$i" -lt "${#MOVE_PATHS[@]}" ]; do
      src="${MOVE_PATHS[$i]}"
      name="${MOVE_NAMES[$i]}"
      dest="$NEXT_DIR/$name"
      if [ -e "$dest" ]; then
        echo "  ⚠ destination exists, skipping: $dest"
      else
        move_file "$src" "$dest"
        echo "  → $name  backlog/ → next/"
        READY_MOVED=$((READY_MOVED + 1))
      fi
      i=$((i + 1))
    done
  fi
elif [ ${#MOVE_PATHS[@]} -gt 0 ]; then
  mkdir -p docs/tmp
  # READY_DIR = next/: a member that grades READY is promoted into the sprint;
  # BLOCKED → blocked/, DONE → review/ (handled inside the shared gate).
  sprintmd_gate_init plan "$NEXT_DIR" "$NEXT_DIR"

  # Orchestration-capable emit fast path: one subagent per member, in parallel.
  # The agent runs each review and promote/move per folded-in instructions.
  # Only worth the orchestration for more than one member.
  if [ "$(sprintmd_ai_mode)" = "emit" ] && sprintmd_orchestration_capable \
     && [ ${#MOVE_PATHS[@]} -gt 1 ]; then
    sprintmd_gate_parallel "${MOVE_PATHS[@]}"
    EMITTED=1
  else
    for src in "${MOVE_PATHS[@]}"; do
      name="$(basename "$src")"
      echo "▸ Gating: $name"
      sprintmd_gate_review "$src"
      case "$SPRINTMD_GATE_VERDICT" in
        EMIT)    EMITTED=1 ;;
        READY)   READY_MOVED=$((READY_MOVED + 1)); echo "  ✓ READY → next/: $name" ;;
        BLOCKED) BLOCKED_CT=$((BLOCKED_CT + 1));   echo "  ⊘ BLOCKED → blocked/: $name" ;;
        DONE)    DONE_CT=$((DONE_CT + 1));         echo "  ✓ DONE → review/: $name" ;;
        NOSTAMP|FAILED)
          ERR_CT=$((ERR_CT + 1))
          echo "  ✗ gate $SPRINTMD_GATE_VERDICT: $name — left in backlog/"
          [ -n "$SPRINTMD_GATE_LOG" ] && echo "    log: $SPRINTMD_GATE_LOG"
          ;;
      esac
    done
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
if [ "$EMITTED" -eq 1 ]; then
  echo "▸ Plan $PLAN_ID: gating ${#MOVE_PATHS[@]} backlog member(s) — run the review prompt(s) above."
  echo "  Each READY member is promoted into next/; BLOCKED → blocked/, DONE → review/."
elif [ "$COMMIT_ONLY" -eq 1 ]; then
  echo "▸ Plan $PLAN_ID committed (--commit-only): moved $READY_MOVED task(s) into next/ (gate skipped — not vetted)"
else
  echo "▸ Plan $PLAN_ID started: $READY_MOVED ready → next/, $BLOCKED_CT blocked, $DONE_CT done"
  [ "$ERR_CT" -gt 0 ] && echo "  ($ERR_CT gate error(s) — left in backlog/)"
fi
[ ${#SKIP_NEXT[@]} -gt 0 ] && echo "  (already queued: ${#SKIP_NEXT[@]})"
[ ${#SKIP_PAST[@]} -gt 0 ] && echo "  (already past next/: ${#SKIP_PAST[@]})"

# One-way STARTED latch: this plan has now been committed to the sprint. Set on
# every successful exit — gated, emit, --commit-only, and idempotent re-runs —
# regardless of how many members moved this run. It never reverts as members
# flow through next/doing/review/done; `plan done` later deletes the file.
stamp_started "$PLAN_FILE"

GOAL="$(plan_goal_text "$PLAN_FILE")"
if [ -n "$GOAL" ]; then
  echo ""
  echo "  Goal: $GOAL"
fi

# Export for parent (loop) and any child process in this shell tree.
# shellcheck disable=SC2034
export SPRINTMD_ACTIVE_PLAN_ID="$PLAN_ID"
export SPRINTMD_ACTIVE_PLAN_FILE="$PLAN_FILE"
export SPRINTMD_ACTIVE_PLAN_GOAL="${GOAL:-}"

echo ""
echo "Next: ./sprint.sh work"
exit 0
