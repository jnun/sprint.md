#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# chat-folder.sh — Express one-at-a-time sweep of a single stage folder
# (blocked/, next/, or backlog/). Reached via `./sprint.sh chat <stage>` —
# chat.sh's dispatcher validates the stage name and routes here. This is the
# THIRD case of chat's grammar, completing `chat [target]`:
#   chat            → walk the whole sprint's structural health (chat-sprint.sh)
#   chat <id>       → chat one task through (chat.sh)
#   chat <folder>   → this: a fast verdict-first sweep of one stage folder
#
# It absorbs the retired `triage` verb: auto-assess each task, you decide per
# task (promote/define/kill/skip/quit), moving briskly through the queue.
#
# TWO-TIER by model to keep triage's fast tempo: the per-task verdict runs on
# the cheap TRIAGE model (single-shot STATUS/SUMMARY/RECOMMENDATION); only
# escalating a task to "define it" hands it to chat.sh, whose full conversation
# runs on the strongest TALK model. Fast cheap sort by default, full depth only
# where you ask for it.
#
# Dependency resolution is INTRINSIC to chat and runs on every file the sweep
# analyzes, exactly as it does for `chat <id>` and the no-arg walk: whenever a
# swept task's `Depends on` points into blocked/, the sweep lifts and defines
# that dependency (via the shared sprintmd_next_blocked_resolution helper and
# chat's own fresh-context chain) so the dependent task can actually be worked.
# The folder argument only selects WHICH files are swept.  See: help chat

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

STAGE="${1:-}"
case "$STAGE" in
  blocked|next|backlog) : ;;
  *)
    echo "Usage: chat <folder>   (folder must be one of: blocked, next, backlog)"
    exit 1 ;;
esac
DIR="docs/tasks/$STAGE"

# Colours (RED/YELLOW/BLUE/CYAN/DIM/BOLD/NC) come from lib.sh.
timeout_sec=120
# The per-task verdict is a single-shot classification (three lines out). Cap
# turns so a misbehaving model can't burn a long session before the wall-clock
# timeout fires — same guard triage/define/split use.
MAX_TURNS=15
AI_MODE="$(sprintmd_ai_mode)"

# Cheap model for the fast verdict pass (as the old triage did). The deep
# "define it" path shells to chat.sh, which picks the strong TALK model itself.
_triage_model="$(sprintmd_resolve_model TRIAGE)"
_model_args=()
[ -n "$_triage_model" ] && _model_args=(--model "$_triage_model")

trap 'echo ""; echo "Sweep interrupted."; exit 130' INT TERM

# ── Collect tasks in this folder, numerically ─────────────────────────
all_files=()
if [ -d "$DIR" ]; then
  IFS=$'\n' all_files=($(
    find "$DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | sed "s|^|$DIR/|"
  )) || true
  unset IFS
fi

total=${#all_files[@]}
if [ "$total" -eq 0 ]; then
  echo "▸ Sweep $STAGE/"
  echo "  $DIR/ is empty — nothing to walk."
  exit 0
fi

echo -e "${CYAN}=== Sweep $STAGE/: $total task(s), one at a time ===${NC}"

# ── Shared dependency-resolution block (task 225's helper) ────────────
# Written once in lib.sh so the no-arg sprint walk, `chat <id>`, and this folder
# sweep all resolve a dependency that points into blocked/ identically.
NEXT_BLOCKED_RESOLUTION="$(sprintmd_next_blocked_resolution)"

# blocked_deps FILE -> space-separated dependency ids that currently sit in
# blocked/. These are why a dependent task can't actually be worked; the sweep
# lifts/defines them via the shared resolution above.
blocked_deps() {
  local file="$1" u out=""
  for u in $(sprintmd_unmet_deps "$file"); do
    if sprintmd_find_task "$u" docs/tasks/blocked >/dev/null 2>&1; then
      out="$out $u"
    fi
  done
  printf '%s' "${out# }"
}

# ── Emit mode: hand the whole sweep to the surrounding agent ──────────
# The agent IS the model here, so there is no separate cheap/strong split to
# make — instead the tempo is a prompt contract: fast verdict first, go deep
# ONLY on request. Dependency resolution rides along on every file.
if [ "$AI_MODE" = "emit" ]; then
  _file_list=$(printf '%s\n' "${all_files[@]}")
  sprintmd_run -p "You are sweeping the $STAGE/ task folder with the developer, one task at a time — a fast verdict-first sort, NOT a full conversation on every file. Rip through the queue; go deep only where asked.

CLAUDE.md is auto-loaded with project context and conventions.

Tasks to sweep, in order:
$_file_list

For EACH task in order:
1. Read the task file and do a QUICK check of the current codebase — a fast size-up, not a deep review.
2. Give a fast VERDICT: task name, stage ($STAGE/), a STATUS (DONE/BLOCKED/UNDEFINED/READY/STALE), a one-sentence summary, and a one-sentence recommendation. Keep it tight — this is the cheap sort pass.
3. Offer the developer the choice:
   [w] work it   — promote (blocked|backlog → next/) or start (next/ → doing/): git mv SRC DEST || mv SRC DEST
   [d] define it — go DEEP: run './sprint.sh chat <id>' so the full chat conversation (strongest model) refines the task and closes the loop. This is the only step that escalates past the fast verdict.
   [k] kill it   — delete after confirming: git rm -f PATH || rm -f PATH
   [s] skip      — leave it where it is
   [q] quit      — stop the sweep
4. Act on the choice within the task pipeline. Always move with: git mv SRC DEST || mv SRC DEST (git mv first; plain mv finishes when untracked). Always delete with: git rm -f PATH || rm -f PATH. Then continue to the next task.

DEPENDENCY RESOLUTION — intrinsic to chat, applied to EVERY task you sweep (not only on [d]):
When a swept task's '**Depends on**:' names a task that currently sits in blocked/, that dependent task can NEVER be worked until the dependency is defined and leaves blocked/. Do not just note it — resolve it, following the shared rule below. The folder you are sweeping only chose WHICH files to open; what you do to each is the same as 'chat <id>'.

$NEXT_BLOCKED_RESOLUTION

Be concise and move briskly. One task at a time; wait for the developer between tasks." \
    ${_model_args[@]+"${_model_args[@]}"} \
    --tools "Read,Edit,Write,Bash,Grep,Glob"
  exit 0
fi

# ── Exec mode: interactive loop ──────────────────────────────────────
worked=0
defined=0
killed=0
skipped=0

mkdir -p docs/tasks/next docs/tasks/doing

for i in "${!all_files[@]}"; do
  file="${all_files[$i]}"
  idx=$((i + 1))

  # A prior define action may have moved the file out of this folder.
  if [ ! -f "$file" ]; then
    echo -e "\n${DIM}[$idx/$total] (moved or deleted, skipping)${NC}"
    continue
  fi

  taskname=$(basename "$file")

  # ── Fast verdict — cheap TRIAGE model, single shot ─────────────────
  _verdict_prompt="You are sweeping a task file from $STAGE/.

CLAUDE.md is auto-loaded with project context and conventions.
Read the task file at: $file

Then do a quick check of the current codebase to assess the task's status.

Output EXACTLY three lines in this format:

STATUS: <one of: DONE, BLOCKED, UNDEFINED, READY, STALE>
SUMMARY: <one sentence describing what this task is about>
RECOMMENDATION: <one sentence telling the user what to do with it>

Status definitions:
- DONE: The work described in this task is already present in the codebase
- BLOCKED: The task references files/APIs/patterns that no longer exist or has unmet dependencies
- UNDEFINED: The task lacks a clear problem statement or actionable success criteria
- READY: The task is well-defined, relevant, and ready to be worked
- STALE: The task is not wrong but feels low-priority or superseded by other work

Rules:
- Be conservative: if in doubt, say READY
- Keep SUMMARY and RECOMMENDATION each to ONE sentence
- Do not output anything else"

  verdict=$(run_with_timeout "$timeout_sec" sprintmd_run -p "$_verdict_prompt" \
    ${_model_args[@]+"${_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions 2>/dev/null) || true

  status=$(echo "$verdict" | grep -oE '^STATUS: (DONE|BLOCKED|UNDEFINED|READY|STALE)' | head -1 | sed 's/^STATUS: //' || true)
  if [ -z "$status" ]; then
    status=$(echo "$verdict" | grep -oE '\b(DONE|BLOCKED|UNDEFINED|READY|STALE)\b' | head -1 || true)
  fi
  [ -z "$status" ] && status="UNKNOWN"

  summary=$(echo "$verdict" | grep '^SUMMARY:' | head -1 | sed 's/^SUMMARY: //' || true)
  [ -z "$summary" ] && summary="(no summary returned)"

  recommendation=$(echo "$verdict" | grep '^RECOMMENDATION:' | head -1 | sed 's/^RECOMMENDATION: //' || true)
  [ -z "$recommendation" ] && recommendation="(no recommendation returned)"

  # Dependency awareness — deps of this task that are stuck in blocked/. A
  # dependent task can't be worked until these are defined; [d] resolves them
  # (chat.sh's chain lifts the most-upstream one first).
  bdeps="$(blocked_deps "$file")"

  # ── Display ────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}[$idx/$total] $taskname${NC}"
  echo -e "  Stage:  ${BLUE}$STAGE/${NC}"
  if [ "$status" = "UNKNOWN" ]; then
    echo -e "  Status: ${DIM}(timed out)${NC}"
  elif [ "$status" = "DONE" ]; then
    echo -e "  Status: ${CYAN}$status${NC}"
  elif [ "$status" = "BLOCKED" ] || [ "$status" = "UNDEFINED" ]; then
    echo -e "  Status: ${RED}$status${NC}"
  elif [ "$status" = "STALE" ]; then
    echo -e "  Status: ${YELLOW}$status${NC}"
  else
    echo -e "  Status: $status"
  fi
  echo "  $summary"
  echo -e "  ${DIM}$recommendation${NC}"
  if [ -n "$bdeps" ]; then
    echo -e "  ${RED}⚠ depends on $bdeps (in blocked/) — can't be worked until defined; [d] lifts it${NC}"
  fi
  echo ""
  case "$STAGE" in
    next) _w_label="Start it" ;;
    *)    _w_label="Promote" ;;
  esac
  echo -e "  ${BOLD}[w]${NC} $_w_label  ${BOLD}[d]${NC} Define it (go deep)  ${BOLD}[k]${NC} Kill it  ${BOLD}[s]${NC} Skip  ${BOLD}[q]${NC} Quit"
  printf "  > "
  read -r choice </dev/tty 2>/dev/null || choice="s"

  # ── Act ────────────────────────────────────────────────────────────
  case "$choice" in
    w|W)
      case "$STAGE" in
        blocked|backlog)
          move_file "$file" "docs/tasks/next/$taskname"
          echo -e "  ${CYAN}-> Moved to next/${NC}"
          ;;
        next)
          move_file "$file" "docs/tasks/doing/$taskname"
          echo -e "  ${CYAN}-> Moved to doing/${NC}"
          ;;
      esac
      worked=$((worked + 1))
      ;;
    d|D)
      task_id=$(echo "$taskname" | grep -oE '^[0-9]+' || true)
      if [ -n "$task_id" ]; then
        echo -e "  ${BLUE}-> Going deep: launching chat on $task_id...${NC}"
        # chat.sh runs the full conversation on the strong TALK model AND, being
        # chat, resolves this task's blocked dependencies via its own fresh-
        # context chain — the intrinsic dep resolution, not reimplemented here.
        bash "$(dirname "${BASH_SOURCE[0]}")/chat.sh" "$task_id" </dev/tty || true
        echo ""
        echo -e "  ${DIM}Talk session complete. Continuing the sweep...${NC}"
        defined=$((defined + 1))
      else
        echo -e "  ${YELLOW}Could not extract task ID. Skipping define.${NC}"
        skipped=$((skipped + 1))
      fi
      ;;
    k|K)
      printf "  Delete %s? [y/N]: " "$taskname"
      read -r confirm </dev/tty 2>/dev/null || confirm="n"
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git rm "$file" 2>/dev/null || rm "$file"
        echo -e "  ${RED}-> Deleted${NC}"
        killed=$((killed + 1))
      else
        echo -e "  ${DIM}-> Kept${NC}"
        skipped=$((skipped + 1))
      fi
      ;;
    q|Q)
      echo -e "  ${DIM}-> Quitting sweep${NC}"
      break
      ;;
    *)
      skipped=$((skipped + 1))
      ;;
  esac
done

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}=== Sweep complete ===${NC}"
echo "  Worked:   $worked"
echo "  Defined:  $defined"
echo "  Killed:   $killed"
echo "  Skipped:  $skipped"
