#!/usr/bin/env bash
# chat-plan.sh — Conversational plan authoring. See: ./sprint.sh help chat
#
# Reached via `./sprint.sh chat plan [id]`. chat.sh routes here. This is the
# plan-shaped sibling of chat <id> / chat <folder> / chat bugs:
#   chat plan        → pick a plan to author (like bare chat backlog)
#   chat plan <id>   → author/refine that plan conversationally
#
# chat shapes; plan acts. This walk only writes docs/plans/<id>-*.md — it never
# moves or edits task files. Member tasks are chosen from backlog/ by ID
# reference. The shared Conversation Method (ai/conversation.md) is injected
# unchanged. Status is binary: DRAFT while authoring → READY when the user
# confirms (the signal plan start / loop --refill gate on).

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
PLAN_ID="${1:-}"

# ── Resolve / pick a plan ────────────────────────────────────────────

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

if [ -z "$PLAN_ID" ]; then
  echo "▸ chat plan — pick a plan to author"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans yet. Create one first:"
    echo "  ./sprint.sh newplan \"<name>\" [task-id ...]"
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to author (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh chat plan <id>"
    echo "Pass a plan id, or run interactively to pick one."
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage:"
  echo "  ./sprint.sh chat plan          pick a plan to author"
  echo "  ./sprint.sh chat plan <id>     author plan <id> (plan id, not a task id)"
  echo "Create a plan first with: ./sprint.sh newplan \"<name>\""
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Create one with: ./sprint.sh newplan \"<name>\""
  echo "Existing plans:"
  list_plans
  exit 1
fi

PLAN_NAME=$(basename "$PLAN_FILE")
echo "▸ Authoring plan: $PLAN_NAME"
echo "  File: $PLAN_FILE"
echo "  (read-only over backlog/ — only this plan file will be written)"
echo ""

# ── Model + method ──────────────────────────────────────────────────

_MODEL="$(sprintmd_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

_PROFILE_LINE="$(sprintmd_profile_line)"
_METHOD="$(sprintmd_conversation_method)" || exit 1

# Snapshot of backlog for the prompt (titles only — agent re-reads files as needed).
_BACKLOG_LIST=""
_backlog_n=0
for _bf in docs/tasks/backlog/*.md; do
  [ -f "$_bf" ] || continue
  _backlog_n=$((_backlog_n + 1))
  if [ "$_backlog_n" -le 40 ]; then
    _BACKLOG_LIST="${_BACKLOG_LIST}
  - $(basename "$_bf") — $(task_title "$_bf")"
  fi
done
if [ "$_backlog_n" -eq 0 ]; then
  _BACKLOG_BLOCK="backlog/ is empty — the user may still name IDs that live in other folders, or decide the plan needs newtask first."
elif [ "$_backlog_n" -gt 40 ]; then
  _BACKLOG_BLOCK="backlog/ has $_backlog_n tasks (first 40 titles below; read the rest from disk as needed):${_BACKLOG_LIST}"
else
  _BACKLOG_BLOCK="backlog/ tasks available to group (${_backlog_n}):${_BACKLOG_LIST}"
fi

APPEND_PROMPT="You are a senior engineer authoring a PLAN with the colleague who owns the project — a named, ordered grouping of tasks with a clear goal. This is NOT task refinement and NOT the auto-planner. You shape intent; you never move or edit task files.

Plan file: $PLAN_FILE — read it now, before you say anything.${_PROFILE_LINE}

$_METHOD

BOUNDARY — group vs refine
- You operate on PLANS only. The id in play is a plan id. Plan creation/ID allocation is newplan's job — never invent a new plan file.
- Your ONLY durable write is $PLAN_FILE. Read docs/tasks/backlog/ (and any other task file you need for conflict analysis) but do not edit, move, or create task files. If a needed task does not exist, recommend './sprint.sh newtask \"…\"' and let the user run it — do not run it yourself.
- chat backlog mutates task files; chat plan only records IDs into the plan. Keep that boundary absolute.

CURRENT BACKLOG SNAPSHOT
$_BACKLOG_BLOCK

YOUR GOAL
Through focused Q&A, fill or refine this plan until it is an ordered, non-conflicting group of work with a clear goal. When the user confirms it is done, flip **Status:** to READY. Partial sessions leave **Status:** DRAFT so nothing is lost.

WHAT THE PLAN FILE MUST HOLD
- Heading: # Plan $PLAN_ID: <name>
- **Created**: (keep existing)
- **Status:** DRAFT while authoring; READY only when the user confirms the plan is ready to start
- ## Goal — what this clump of work achieves and why (2–5 sentences)
- ## Why — optional short rationale if useful
- ## Member tasks — ordered list, one line each:
    - #ID — short title
  Order = execution order (dependencies first). Checkboxes optional.
- Parallelism notes (optional, under Goal/Why or Notes): record independence found during the walk, e.g. '231 ∥ 234, disjoint files; 237 after 234'. V1 execution stays sequential — capture the intelligence, do not schedule parallel runs.

HOW TO WALK
1. SIZE UP: read the plan file and skim backlog titles. In 1–2 sentences, say what this plan currently is (empty scaffold / partial draft / looks READY).
2. GOAL first if thin: probe what the user wants this clump to achieve; ground in project profile and existing features; recommend a crisp Goal and write it.
3. MEMBERS: propose an ordered set of backlog tasks that serve the goal. Prefer existing backlog items over inventing work. Name trade-offs (scope too wide, missing prereq, conflict). On agreement, write the member list by ID + title. Re-read task files when titles alone are not enough.
4. ORDER + CONFLICTS: walk dependency edges between members; put prerequisites first. Flag file-overlap / independence as parallelism annotations (recorded only).
5. STATUS: keep DRAFT until the user confirms the plan is ready to start; then set **Status:** READY exactly (same READY word tasks use). Never invent other status values.
6. STOP when READY and the member list is ordered and non-conflicting — show the final plan state and remind: './sprint.sh plan start $PLAN_ID' commits members into next/ (or move them by hand). The plan file itself never moves.

RULES
- One question at a time; wait for the answer.
- Executive-summary altitude: what and why, not how. No code.
- WRITES: only $PLAN_FILE. READ anything else to ground recommendations.
- Do not run plan start, do not mv task files, do not edit tasks."

# ── Interactive contract (same as chat.sh) ───────────────────────────
if [ "$(sprintmd_ai_mode)" = "exec" ] && ! sprintmd_interactive_ok; then
  echo -e "${YELLOW}Note: a live plan-authoring walk needs an interactive-capable AI CLI (claude) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single pass instead. To wire up the full experience,${NC}"
  echo -e "${YELLOW}see docs/sprintmd/guides/use_chat.md${NC}"
  echo ""
fi

sprintmd_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "chat-plan-${PLAN_ID}" \
  "Read the plan at $PLAN_FILE and the backlog, size it up, and start authoring — one detail at a time. Write only the plan file."
