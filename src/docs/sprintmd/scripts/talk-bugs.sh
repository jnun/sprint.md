#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# talk-bugs.sh — Express one-at-a-time sweep of the bug inbox (docs/bugs/).
# Reached via `./sprint.sh talk bugs` — talk.sh's dispatcher routes here. This is
# the bug-shaped sibling of talk-folder.sh, completing talk's grammar:
#   talk            → walk the whole sprint's structural health (talk-sprint.sh)
#   talk <id>       → talk one task through (talk.sh)
#   talk <folder>   → sweep a task stage folder: blocked/next/backlog (talk-folder.sh)
#   talk bugs       → this: sweep the bug inbox, verdict-first
#
# A bug report is NOT a task and docs/bugs/ is NOT a task stage — it is flat, it
# has no Depends-on/Status metadata, and its terminal move is "turn the report
# into a fix task, then retire the report to archived/." So this cannot ride on
# talk-folder.sh's task-pipeline machinery; the verdicts and the per-bug actions
# are bug-specific:
#   [w] work it   → create the fix task (newtask), cross-link bug↔task, archive bug
#   [d] define it → go deep: refine the report itself (repro steps, severity, criteria)
#   [a] archive   → already fixed / obsolete → docs/bugs/archived/, no task
#   [k] kill it   → delete a non-bug
#   [s] skip / [q] quit
#
# TWO-TIER by model, same as talk-folder: the per-bug verdict runs on the cheap
# TRIAGE model; only "define it" escalates to the strong TALK model. See: help talk

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

BUGS_DIR="docs/bugs"
ARCHIVE_DIR="docs/bugs/archived"

# Colours (RED/YELLOW/BLUE/CYAN/DIM/BOLD/NC) come from lib.sh.
timeout_sec=120
# The per-bug verdict is a single-shot classification (three lines out). Cap
# turns so a misbehaving model can't burn a long session before the wall-clock
# timeout fires — same guard talk-folder/define/split use.
MAX_TURNS=15
AI_MODE="$(fiveday_ai_mode)"

# Cheap model for the fast verdict pass. The deep "define it" path runs the full
# refinement conversation on the strong TALK model, chosen at that point.
_triage_model="$(fiveday_resolve_model TRIAGE)"
_verdict_model_args=()
[ -n "$_triage_model" ] && _verdict_model_args=(--model "$_triage_model")

_talk_model="$(fiveday_tier_model TALK)"
_talk_model_args=()
[ -n "$_talk_model" ] && _talk_model_args=(--model "$_talk_model")

trap 'echo ""; echo "Sweep interrupted."; exit 130' INT TERM

# ── Bug field helpers ─────────────────────────────────────────────────
# bug_desc FILE -> the human title after "# Bug N:", falling back to the
# filename slug so a mangled header never yields an empty task description.
bug_desc() {
  local file="$1" name desc
  desc="$( { grep -m1 -E '^# Bug [0-9]+:' "$file" 2>/dev/null || true; } \
          | sed -E 's/^# Bug [0-9]+:[[:space:]]*//' )"
  if [ -z "$desc" ]; then
    name="$(basename "$file" .md)"
    desc="$(printf '%s' "${name#*-}" | tr '-' ' ')"
  fi
  printf '%s' "$desc"
}

# add_note_ref FILE TEXT -> insert TEXT into FILE's "## Notes" section (right
# after the header), or append a Notes section if none exists. Deterministic
# cross-reference writing — no model needed for a metadata link.
add_note_ref() {
  local file="$1" ref="$2" tmp
  tmp="$(mktemp)"
  awk -v ref="$ref" '
    /^## Notes[[:space:]]*$/ && !done { print; print ""; print ref; done=1; next }
    { print }
    END { if (!done) { print ""; print "## Notes"; print ""; print ref } }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# work_bug FILE -> the [w] action: create a fix task, cross-link both files,
# archive the bug. Echoes a one-line result. Pure shell so the sweep can do it
# without spending a token. Mirrors create-task/create-bug's own git staging.
work_bug() {
  local file="$1" name desc newout taskfile bugid archived_path
  name="$(basename "$file")"
  bugid="$(printf '%s' "$name" | grep -oE '^[0-9]+' || true)"
  desc="$(bug_desc "$file")"

  # Create the fix task via the real creator so it gets a proper ID + template.
  newout="$(bash "$(dirname "${BASH_SOURCE[0]}")/create-task.sh" "Fix: $desc" 2>&1)" || {
    echo "  ${RED}Could not create the fix task:${NC}"
    printf '%s\n' "$newout" | sed 's/^/    /'
    return 1
  }
  taskfile="$(printf '%s' "$newout" | grep -oE 'docs/tasks/backlog/[0-9]+-[^ ]*\.md' | head -1)"
  if [ -z "$taskfile" ] || [ ! -f "$taskfile" ]; then
    echo "  ${RED}Fix task was created but its path could not be located — leaving the bug in place.${NC}"
    return 1
  fi

  # Cross-link: the bug points at its fix task; the task points back at the
  # report where it will live once archived. Write the bug's link BEFORE moving.
  archived_path="$ARCHIVE_DIR/$name"
  add_note_ref "$file" "> **Fix task:** $taskfile"
  add_note_ref "$taskfile" "> **Bug report:** $archived_path (filed as bug #${bugid:-?})"

  # Retire the report to archived/ now that the task carries the work.
  mkdir -p "$ARCHIVE_DIR"
  move_file "$file" "$archived_path"

  git add "$taskfile" "$archived_path" 2>/dev/null || true
  echo "  ${CYAN}-> Created ${taskfile#docs/tasks/backlog/} and archived the report${NC}"
}

# ── Collect bugs (flat, numeric-prefixed; archived/ and the template excluded) ─
all_files=()
if [ -d "$BUGS_DIR" ]; then
  IFS=$'\n' all_files=($(
    find "$BUGS_DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | sed "s|^|$BUGS_DIR/|"
  )) || true
  unset IFS
fi

total=${#all_files[@]}
if [ "$total" -eq 0 ]; then
  echo "▸ Sweep bugs/"
  echo "  $BUGS_DIR/ has no open bug reports — nothing to walk."
  echo "  File one with:  ./sprint.sh newbug \"Brief description\""
  exit 0
fi

echo -e "${CYAN}=== Sweep bugs/: $total report(s), one at a time ===${NC}"

# ── Emit mode: hand the whole sweep to the surrounding agent ──────────
# The agent IS the model, so there is no cheap/strong split — the tempo is a
# prompt contract: fast verdict first, go deep ONLY on request.
if [ "$AI_MODE" = "emit" ]; then
  _file_list=$(printf '%s\n' "${all_files[@]}")
  fiveday_run -p "You are sweeping the bug inbox ($BUGS_DIR/) with the developer, one report at a time — a fast verdict-first sort, NOT a full conversation on every bug. Rip through the queue; go deep only where asked.

CLAUDE.md is auto-loaded with project context and conventions. A bug report is NOT a task: it lives flat in $BUGS_DIR/, has no Depends-on/Status metadata, and its lifecycle ends by becoming a fix task and retiring to $ARCHIVE_DIR/.

Bug reports to sweep, in order:
$_file_list

For EACH report in order:
1. Read the bug file and do a QUICK check of the current codebase — is this still reproducible, or already fixed? A fast size-up, not a deep review.
2. Give a fast VERDICT: bug name, a STATUS (REPRODUCIBLE / FIXED / UNDEFINED / DUPLICATE / STALE), a one-sentence summary, and a one-sentence recommendation. Keep it tight — this is the cheap sort pass.
   - REPRODUCIBLE: the described defect still exists in the code.
   - FIXED: the code already behaves correctly; the report is stale.
   - UNDEFINED: no clear problem, repro steps, or success criteria to act on.
   - DUPLICATE: another bug or task already covers this.
   - STALE: not wrong, but low-value or superseded.
3. Offer the developer the choice:
   [w] work it   — create the FIX TASK, then archive the report. Do EXACTLY this, in order:
                   a. Run: ./sprint.sh newtask \"Fix: <the bug's short description>\"  (gives it a real ID + template)
                   b. Open the newly created docs/tasks/backlog/<id>-*.md and, in its ## Notes, add a line:  > **Bug report:** $ARCHIVE_DIR/<bug-filename> (filed as bug #<id>)
                   c. In the bug file's ## Notes, add a line:  > **Fix task:** docs/tasks/backlog/<task-filename>
                   d. Archive the report:  git mv <bug-file> $ARCHIVE_DIR/<bug-filename>  (fall back to plain mv if uncommitted)
                   Then define the new fix task only if the developer asks — otherwise move on; ./sprint.sh talk <id> can refine it later.
   [d] define it — go DEEP on the REPORT itself (not a task): refine ## Problem, ## Steps to reproduce, the Severity line, and ## Success criteria until any developer could reproduce and verify the fix. One detail at a time, editing as you go. This is the only step that escalates past the fast verdict.
   [a] archive   — the bug is already fixed or obsolete and needs no task:  git mv <bug-file> $ARCHIVE_DIR/<bug-filename>
   [k] kill it   — not a real bug: delete after confirming (git rm).
   [s] skip      — leave it where it is.
   [q] quit      — stop the sweep.
4. Act on the choice (prefer 'git mv' / 'git rm'; fall back to plain 'mv' / 'rm' when the file is uncommitted), then continue to the next report.

Be concise and move briskly. One report at a time; wait for the developer between reports." \
    ${_talk_model_args[@]+"${_talk_model_args[@]}"} \
    --tools "Read,Edit,Write,Bash,Grep,Glob"
  exit 0
fi

# ── Exec mode: interactive loop ──────────────────────────────────────
worked=0
defined=0
archived=0
killed=0
skipped=0

mkdir -p "$ARCHIVE_DIR"

for i in "${!all_files[@]}"; do
  file="${all_files[$i]}"
  idx=$((i + 1))

  # A prior action may have moved the file out of the inbox.
  if [ ! -f "$file" ]; then
    echo -e "\n${DIM}[$idx/$total] (moved or deleted, skipping)${NC}"
    continue
  fi

  bugname=$(basename "$file")

  # ── Fast verdict — cheap TRIAGE model, single shot ─────────────────
  _verdict_prompt="You are sweeping a BUG REPORT (not a task) from $BUGS_DIR/.

CLAUDE.md is auto-loaded with project context and conventions.
Read the bug file at: $file

Then do a quick check of the current codebase to assess whether the defect still exists.

Output EXACTLY three lines in this format:

STATUS: <one of: REPRODUCIBLE, FIXED, UNDEFINED, DUPLICATE, STALE>
SUMMARY: <one sentence describing the defect this report is about>
RECOMMENDATION: <one sentence telling the user what to do with it>

Status definitions:
- REPRODUCIBLE: The described defect still exists in the current codebase
- FIXED: The code already behaves correctly; this report is stale
- UNDEFINED: No clear problem, reproduction steps, or success criteria to act on
- DUPLICATE: Another bug report or task already covers this
- STALE: Not wrong, but low-value or superseded by other work

Rules:
- Be conservative: if in doubt, say REPRODUCIBLE
- Keep SUMMARY and RECOMMENDATION each to ONE sentence
- Do not output anything else"

  verdict=$(run_with_timeout "$timeout_sec" fiveday_run -p "$_verdict_prompt" \
    ${_verdict_model_args[@]+"${_verdict_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions 2>/dev/null) || true

  status=$(echo "$verdict" | grep -oE '^STATUS: (REPRODUCIBLE|FIXED|UNDEFINED|DUPLICATE|STALE)' | head -1 | sed 's/^STATUS: //' || true)
  if [ -z "$status" ]; then
    status=$(echo "$verdict" | grep -oE '\b(REPRODUCIBLE|FIXED|UNDEFINED|DUPLICATE|STALE)\b' | head -1 || true)
  fi
  [ -z "$status" ] && status="UNKNOWN"

  summary=$(echo "$verdict" | grep '^SUMMARY:' | head -1 | sed 's/^SUMMARY: //' || true)
  [ -z "$summary" ] && summary="(no summary returned)"

  recommendation=$(echo "$verdict" | grep '^RECOMMENDATION:' | head -1 | sed 's/^RECOMMENDATION: //' || true)
  [ -z "$recommendation" ] && recommendation="(no recommendation returned)"

  # ── Display ────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}[$idx/$total] $bugname${NC}"
  if [ "$status" = "UNKNOWN" ]; then
    echo -e "  Status: ${DIM}(timed out)${NC}"
  elif [ "$status" = "FIXED" ]; then
    echo -e "  Status: ${CYAN}$status${NC}"
  elif [ "$status" = "REPRODUCIBLE" ]; then
    echo -e "  Status: ${RED}$status${NC}"
  elif [ "$status" = "UNDEFINED" ] || [ "$status" = "DUPLICATE" ]; then
    echo -e "  Status: ${YELLOW}$status${NC}"
  else
    echo -e "  Status: $status"
  fi
  echo "  $summary"
  echo -e "  ${DIM}$recommendation${NC}"
  echo ""
  echo -e "  ${BOLD}[w]${NC} Work it (make fix task)  ${BOLD}[d]${NC} Define it (go deep)  ${BOLD}[a]${NC} Archive  ${BOLD}[k]${NC} Kill it  ${BOLD}[s]${NC} Skip  ${BOLD}[q]${NC} Quit"
  printf "  > "
  read -r choice </dev/tty 2>/dev/null || choice="s"

  # ── Act ────────────────────────────────────────────────────────────
  case "$choice" in
    w|W)
      if work_bug "$file"; then
        worked=$((worked + 1))
      else
        skipped=$((skipped + 1))
      fi
      ;;
    d|D)
      echo -e "  ${BLUE}-> Going deep: refining the report...${NC}"
      _define_prompt="You are a senior engineer reviewing a BUG REPORT with the developer who filed it, one detail at a time, until any developer could reproduce the defect and verify its fix.

The bug file is at: $file — read it now, before you say anything. It is a bug report, NOT a task: it has ## Problem, ## Steps to reproduce, a **Severity:** line, ## Success criteria, and ## Notes. Do NOT add task metadata (Depends on, Blocks, Parent, Status) — those do not belong on a bug.

YOUR GOAL: through a focused back-and-forth, turn a rough report into one that is unambiguous and actionable. Work the gaps one at a time — a vague Problem, missing or non-deterministic reproduction steps, a Severity that does not match the impact, success criteria that are not observable. For EACH gap: ask ONE focused question, polish the answer together, then edit the file immediately (small atomic edits, not one rewrite at the end). Move on to the next gap.

RULES:
- One question at a time; wait for the answer.
- Executive-summary altitude — describe observable behaviour (what happens vs. what should), not code. No code snippets or patches; fixing is a separate task.
- Steps to reproduce must be numbered, start from a clear state, and be followable by someone who has never seen the bug.
- Success criteria must be observable checkboxes that confirm the fix (\"User can …\", \"System shows …\", \"[action] no longer causes [problem]\").
- WRITES stay within this one file: you may edit $file. Read anything to verify; write nothing else.
- When the report reads clearly, say so, show the final state, and remind the developer they can turn it into a fix task with:  ./sprint.sh talk bugs  → [w]  (or ./sprint.sh newtask \"Fix: …\")."
      fiveday_run_interactive \
        --append-system-prompt "$_define_prompt" \
        ${_talk_model_args[@]+"${_talk_model_args[@]}"} \
        --tools "Read,Edit,Write,Bash,Grep,Glob" \
        --permissions "auto" \
        --name "talk-bug-${bugname%%-*}" \
        "Read the bug report at $file, size it up, and start refining it — one detail at a time." </dev/tty || true
      echo ""
      echo -e "  ${DIM}Refinement complete. Continuing the sweep...${NC}"
      defined=$((defined + 1))
      ;;
    a|A)
      move_file "$file" "$ARCHIVE_DIR/$bugname"
      echo -e "  ${CYAN}-> Archived to $ARCHIVE_DIR/${NC}"
      archived=$((archived + 1))
      ;;
    k|K)
      printf "  Delete %s? [y/N]: " "$bugname"
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
echo "  Worked (→ fix task):  $worked"
echo "  Defined:              $defined"
echo "  Archived:             $archived"
echo "  Killed:               $killed"
echo "  Skipped:              $skipped"
