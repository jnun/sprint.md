#!/usr/bin/env bash
# talk.sh — Talk a task through, refining it one detail at a time. See: ./sprint.sh help talk

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── Args ─────────────────────────────────────────────────────────────

TASK_ID="${1:-}"

# `talk [target]` has three cases, decided purely by the argument's SHAPE:
#   (empty)                     → walk the whole sprint's structural health
#   numeric id                  → talk that one task through (the rest of this file)
#   stage name (blocked/next/backlog) → an express one-at-a-time sweep of that folder
# The argument only chooses WHICH files talk opens; what talk does to each —
# including its intrinsic dependency resolution — is the same across all three.
#
# No task id → walk the whole sprint instead of erroring. talk-sprint.sh runs a
# deterministic structural-health preflight over next/ + blocked/, then walks the
# findings one at a time in this same one-detail voice.
if [ -z "$TASK_ID" ]; then
  _TALK_SPRINT="$(dirname "${BASH_SOURCE[0]}")/talk-sprint.sh"
  # exec directly when the exec bit survived; fall back to `bash` on filesystems
  # that drop it (WSL/Docker/FAT32) — the same guard run_script uses.
  if [ -x "$_TALK_SPRINT" ]; then exec "$_TALK_SPRINT"; else exec bash "$_TALK_SPRINT"; fi
fi

# A stage name → sweep that whole folder one task at a time (talk-folder.sh,
# which absorbed the retired `triage`). This is checked BEFORE the numeric-id
# path so a folder name never falls through to fiveday_find_task.
case "$TASK_ID" in
  blocked|next|backlog)
    _TALK_FOLDER="$(dirname "${BASH_SOURCE[0]}")/talk-folder.sh"
    if [ -x "$_TALK_FOLDER" ]; then exec "$_TALK_FOLDER" "$TASK_ID"; else exec bash "$_TALK_FOLDER" "$TASK_ID"; fi
    ;;
  bugs)
    # `bugs` is NOT a task stage — it is the flat bug inbox (docs/bugs/), whose
    # sweep turns reports into fix tasks. Its own script (talk-bugs.sh), routed
    # here alongside the stage folders so the whole talk grammar lives in one place.
    _TALK_BUGS="$(dirname "${BASH_SOURCE[0]}")/talk-bugs.sh"
    if [ -x "$_TALK_BUGS" ]; then exec "$_TALK_BUGS"; else exec bash "$_TALK_BUGS"; fi
    ;;
esac

# Anything else that is not a task id is a mistake — guide, don't silently
# search for a nonexistent task. (doing/, review/, done/ are not sweep targets:
# talk works the pipeline forward, not over in-flight or finished work.)
if ! [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$TASK_ID' is not a task id, a stage folder, or 'bugs'."
  echo "Usage:"
  echo "  ./sprint.sh talk            walk the whole sprint's structural health"
  echo "  ./sprint.sh talk <id>       talk one task through (e.g. talk 42)"
  echo "  ./sprint.sh talk <folder>   sweep a folder: blocked, next, or backlog"
  echo "  ./sprint.sh talk bugs       sweep the bug inbox → fix tasks"
  exit 1
fi

# ── Find the task file ───────────────────────────────────────────────

if ! _RESULT="$(fiveday_find_task "$TASK_ID")"; then
  echo "Error: No task found with ID $TASK_ID in blocked/, backlog/, next/, or doing/"
  exit 1
fi
TASK_FILE="${_RESULT%%$'\t'*}"
TASK_DIR="${_RESULT##*$'\t'}"

TASK_NAME=$(basename "$TASK_FILE")
PARENT_NUM="${TASK_NAME%%-*}"
STAGE="$(basename "$TASK_DIR")"
echo "▸ Talking through: $TASK_NAME"
echo "  Location: $TASK_DIR/"
echo ""

# Interactive, reasoning-heavy review — worth the strongest model unless pinned.
_MODEL="$(fiveday_tier_model TALK)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

# ── Launch the conversational review ─────────────────────────────────

_PROFILE_LINE="$(fiveday_profile_line)"

# When the user chooses to split, the original file is retired once its
# children exist. In emit mode the surrounding agent performs the delete
# (the shell can't act after an emitted prompt); in exec mode the spawned
# CLI does it inline via Bash. Same wording pattern as split.sh.
if [ "$(fiveday_ai_mode)" = "emit" ]; then
  _RETIRE_INSTR="delete it yourself: git rm $TASK_FILE   (or: rm $TASK_FILE)"
else
  _RETIRE_INSTR="delete it: git rm $TASK_FILE   (or: rm $TASK_FILE)"
fi

# newtask always creates children in backlog/. If the original is further
# along the pipeline (next/doing/blocked), the children must follow it there
# or a split silently drops the work out of that stage. Empty when the
# original is already in backlog, so the common case reads clean.
if [ "$STAGE" = "backlog" ]; then
  _STAGE_MOVE=""
else
  _STAGE_MOVE="Each child is created in backlog/, but the original lives in ${STAGE}/ — move every finished child there with 'git mv docs/tasks/backlog/<child-file> $TASK_DIR/<child-file>' so this work stays in ${STAGE}/. "
fi

# ── Close-the-loop: a blocked task that talk fully defines goes straight back
# into the sprint. Only meaningful when the task is in blocked/ (that's where
# define parked it); for any other stage there is no loop to close, so this is
# empty and the closing section reads clean. A human-supervised talk is a
# stronger readiness signal than define's automated pass, so talk stamps the
# READY verdict itself instead of bouncing the task through another define run.
if [ "$STAGE" = "blocked" ]; then
  _CLOSE_LOOP_INSTR="
1b. CLOSE THE LOOP (this task is in blocked/):
define parked this task in blocked/ because it wasn't defined enough to work.
If — and ONLY if — the conversation has genuinely resolved it (no open decision
remains and it now reads as fully defined), close the loop so it can be worked:
1. Make the file END with a '## Questions' section whose first line is EXACTLY:
     **Status: READY**
   Keep the brief '### Already complete / ### Remaining work / ### Questions for
   the developer' structure under it; if nothing is open write 'None — task is
   fully defined.' Replace any earlier '## Questions' section, don't add a second.
2. DELETE any '## BLOCKED' section — it no longer applies.
3. Move it into the sprint queue:  git mv $TASK_FILE docs/tasks/next/$TASK_NAME   (or, if git mv fails because the file is uncommitted: mv $TASK_FILE docs/tasks/next/$TASK_NAME)
Then tell the user it's back in next/ and runnable with ./sprint.sh tasks.
If ANY open question remains, do NONE of this: leave the file in blocked/ and say
plainly what still needs deciding."
else
  _CLOSE_LOOP_INSTR=""
fi

# ── Demote-the-other-way: the symmetric partner of close-the-loop. blocked/
# means "not workable" — so a task that ENDS the session with a real blocking
# question shouldn't keep sitting in a workable stage pretending to be ready.
# Only meaningful when the task is NOT already in blocked/ (a blocked task that
# stays unresolved is handled by close-the-loop's own "leave it in blocked/"
# branch), so this is empty for blocked/ and the closing prompt reads clean.
# talk states the demotion plainly because a user who ran talk on a "finished"
# next/ task will not expect it to leave the sprint.
if [ "$STAGE" != "blocked" ]; then
  _DEMOTE_INSTR="

═══ IF A BLOCKING QUESTION REMAINS — RECORD, THEN DEMOTE ═══
If instead the session ends with a question that genuinely must be answered before anyone can work this task (a real blocker, not a minor nicety), then it is NOT workable — do not leave it in ${STAGE}/ as if it were ready. Do these in order:
1. RECORD the blocker: make the file END with a '## Questions' section whose first line is EXACTLY:
     **Status: BLOCKED**
   Under it, state the blocking question(s) plainly (a '### Questions for the developer' list) so a later talk or report can pick them up. Replace any earlier '## Questions' section, don't add a second.
2. DEMOTE it:  git mv $TASK_FILE docs/tasks/blocked/$TASK_NAME   (or, if git mv fails because the file is uncommitted: mv $TASK_FILE docs/tasks/blocked/$TASK_NAME)
3. TELL THE USER PLAINLY that you moved this task out of ${STAGE}/ into blocked/ and why — name the blocking question in one line, since a user who ran talk on a task they thought was finished will not expect the demotion."
else
  _DEMOTE_INSTR=""
fi

# ── Chain to the next dependency in a FRESH context. Defining one task often
# surfaces that it depends on another undefined task; walking that chain in THIS
# conversation piles context up and burns tokens. So we hand the next task off
# through its FILE (a durable note the fresh session reads) and start clean:
# emit mode spawns a brand-new subagent (the driving agent has a Task tool);
# exec mode can't open a window, so it prints the command for the user to run.
if [ "$(fiveday_ai_mode)" = "emit" ] && [ "$(fiveday_ai_tier)" = "claude-code" ]; then
  _CONTINUE_INSTR="Then CONTINUE THE CHAIN in a fresh context so this session's tokens don't pile up: launch a NEW subagent (Task tool) for <next-id>. Its entire instruction: 'Run ./sprint.sh talk <next-id> and carry that task as far toward READY as you can on your own — read the *Context from talk* note already in its file, refine it, and if a question genuinely needs the human, leave it in the file's ## Questions section and report it back.' Tell the user you have spun up a fresh agent for <next-id> and say in one line what it is picking up."
else
  _CONTINUE_INSTR="Then, to keep each session's context small, do NOT keep going here. Tell the user the next task to define and the exact command to run in a FRESH window:  ./sprint.sh talk <next-id>  — the *Context from talk* note you just wrote means that fresh session already has what it needs."
fi

# ── Context for the size-up and (especially) the stress-test ─────────
# From the merged stress-test flow: a sprint-plan theme pointer and a
# sibling-task overlap scan of the current stage. Both are optional — when
# neither exists the CONTEXT block is empty and the prompt reads clean. The
# sibling scan caps at 20 names so a crowded stage can't bloat the prompt.
_SPRINT_LINE=""
[ -f "docs/tmp/sprint-plan.md" ] && _SPRINT_LINE="
- docs/tmp/sprint-plan.md (current sprint plan — check theme and inclusion rationale)"

_SIBLING_LIST=""
_sibling_count=0
_sibling_collected=0
for sibling in "$TASK_DIR"/*.md; do
  [ -f "$sibling" ] || continue
  _sib_name="$(basename "$sibling")"
  [ "$_sib_name" = "$TASK_NAME" ] && continue
  _sibling_count=$((_sibling_count + 1))
  if [ "$_sibling_collected" -lt 20 ]; then
    _SIBLING_LIST="${_SIBLING_LIST}
  - ${_sib_name}"
    _sibling_collected=$((_sibling_collected + 1))
  fi
done

_SIBLING_LINE=""
if [ "$_sibling_count" -gt 0 ]; then
  _sibling_label="$_sibling_count other tasks"
  [ "$_sibling_count" -gt 20 ] && _sibling_label="first 20 of $_sibling_count tasks"
  _SIBLING_LINE="
- sibling tasks in ${STAGE}/ ($_sibling_label — scan titles for overlap):${_SIBLING_LIST}"
fi

_CONTEXT_BLOCK=""
if [ -n "${_SPRINT_LINE}${_SIBLING_LINE}" ]; then
  _CONTEXT_BLOCK="

CONTEXT — also read these if present; they inform the size-up and especially the stress-test:${_SPRINT_LINE}${_SIBLING_LINE}"
fi

APPEND_PROMPT="You are a senior engineer reviewing a task with the colleague who wrote it. They already sense it is not fully thought out and want to talk it through, one detail at a time, until it reads like a crisp, executive-summary-level brief that any developer could pick up.

The task file is at: $TASK_FILE — read it now, before you say anything.${_PROFILE_LINE}${_CONTEXT_BLOCK}

YOUR GOAL: Through a focused back-and-forth, turn a rough task into clear, actionable work. Depending on the task's state you might fill in a blank stub, refine a single rough job in place, split a task that is several jobs in a trench coat, or stress-test one that already looks done. Either way the result states what \"done\" looks like, names sensible technology choices with the reasoning behind them, and points to helpful references. You raise the open questions and technical decisions; the developer who later works the task makes the final call and writes the code.

STEP 0 — SIZE IT UP FIRST:
After reading the file (and skimming any code or context it references), tell the user in one or two sentences what this task really is. Then make and state a two-part call:
  (a) DEFINITION STATE — is it an UNDEFINED STUB (Problem/Success empty or placeholder, or a \"This task is not defined yet\" marker), ROUGH or SEVERAL JOBS (it exists but is thin, or bundles distinct pieces of work), or LOOKS DEFINED (Problem plus verifiable criteria that already read clearly)?
  (b) the MODE that state points to — FILL-IN, REFINE, SPLIT, or STRESS-TEST below.
This is the OPENING FRAME, not a locked gate. As facts emerge you may cross into another mode mid-session — a LOOKS-DEFINED task with one hollow success criterion drops into FILL-IN for just that section; a stub the user reveals is really several jobs moves to SPLIT; a task that now reads clean can take a STRESS-TEST pass. Say so plainly whenever you switch. If it is a borderline call, say so and let the user decide. And if the task is already clear and well-scoped, say so plainly and confirm rather than inventing gaps — improve only what genuinely needs it.

═══ MODE: FILL-IN — the task is an undefined stub ═══
Build the blank sections up through the same one-detail-at-a-time loop as REFINE below. Open by asking, in one sentence, what this task needs to accomplish and why; then work outward — scope, the definition of done, dependencies, edge cases — one question at a time, editing the file as each answer lands rather than batching to the end. As soon as real content replaces the placeholders, remove any \"This task is not defined yet\" marker. Aim for the shape in \"WHAT A FINISHED TASK LOOKS LIKE.\"

═══ MODE: SPLIT — the task bundles several pieces ═══
1. PROPOSE the breakdown before creating anything: list the candidate sub-tasks (3-10, each atomic and independently completable), ordered so that dependencies come first. Ask the user to confirm or adjust the list.
2. On agreement, CREATE each sub-task with the CLI so it gets a real ID and the standard template:
     ./sprint.sh newtask 'short action-oriented description'
   Then open each newly created file in docs/tasks/backlog/ and fill it in:
     - **Parent**: $PARENT_NUM   (exactly this number — it is what './sprint.sh plan N \"parent:$PARENT_NUM\"' matches to gather the children, so do not omit it)
     - **Depends on**: the previous sub-task's number when order matters, else 'none'
     - ## Problem, ## Success criteria, ## Notes — see \"WHAT A FINISHED TASK LOOKS LIKE\" below
3. TALK THROUGH each sub-task to add detail — same one-detail-at-a-time loop as REFINE (ask, polish, edit, move on). Add the depth that makes each child genuinely workable; do not leave them as one-line stubs.
4. FINISH UP once its children exist and are filled in — the original's content now lives in the sub-tasks. ${_STAGE_MOVE}Then confirm with the user and retire the original: ${_RETIRE_INSTR}

═══ MODE: REFINE — the task is genuinely one job, just rough ═══
Work one detail at a time. For EACH detail:
1. ASK one question — the single most important gap right now (scope, the definition of done, an unstated technical decision, a dependency, an edge case, a security or performance concern). One question, no preamble. When a decision is open, lay out the realistic choices in a sentence or two each and say which you would lean toward and why — cite the relevant best practice and flag any performance or security implication.
2. POLISH the answer together — tighten it and read it back in a sentence: \"So the crux is …\" Let them correct you before it lands in the file.
3. UPDATE the document immediately, while the detail is fresh — one small atomic edit to the relevant section. Do not batch edits for the end.
4. MOVE to the next detail — note briefly what is settled and what still feels thin, then return to step 1.

═══ MODE: STRESS-TEST — the task already looks defined ═══
Pressure-test the definition before work begins: find the gaps, challenge the assumptions, sharpen the spec. Open with a two-to-three-sentence summary of what the task accomplishes and your overall verdict (well-defined / roughly-defined / has issues), then run a focused Q&A — one question at a time, most impactful first, each grounded in a specific criterion, file, or section, with a suggestion when you have one — across these dimensions:
1. GOAL ALIGNMENT: Does it advance its linked feature's goals and fit the current sprint theme (if a sprint plan exists)? Any mismatch between what it does and what the feature/sprint needs?
2. SCOPE: Right size for one task? Should it split? Too narrow to justify its overhead? Does it overlap a sibling task in the same folder?
3. SUCCESS CRITERIA: Verifiable by someone who didn't write it? Complete against the Problem? Any vague, subjective, or missing edge cases?
4. ASSUMPTIONS: What is it taking for granted? Do referenced files, APIs, patterns, or conventions still exist in the current codebase? Any unstated prerequisites?
5. RISK: What could go wrong in implementation — failure modes, performance, security, compatibility?
6. DEPENDENCIES: Are declared Depends on / Blocks real and current? Any undeclared ones that must land first?
7. ALTERNATIVES: Is there a simpler way? Has it locked in an approach prematurely?
Stop once the material findings are covered (typically 3-7 questions). With the user's agreement, sharpen Problem, Success criteria, and Notes to close the gaps you found, and record what does not fit those sections in a '## Think Notes' block at the end of the file (before any HTML comments): a '**Reviewed**: <date>' line, then the key risks, alternatives weighed, and assumptions validated. Do not change metadata (Feature, Created, Depends on, Blocks) unless the user asks.

WHAT A FINISHED TASK LOOKS LIKE (applies to the parent in FILL-IN/REFINE and to every child in SPLIT):
- ## Problem — 2-5 sentences: what needs to happen and why it matters.
- ## Success criteria — observable, verifiable checkboxes that together define \"done.\"
- ## Notes — technology suggestions with their rationale, decisions made, open questions left for the implementer, and references. For references, link to concrete files already in this repository (paths) and to external documentation (URLs) that would help whoever builds it. Suggest, don't mandate.

RULES:
- Keep it at an executive-summary altitude: what and why, not how. Name technologies and approaches; do NOT write code snippets or pseudo-code — that is the implementer's call. STRESS-TEST is analysis only: it sharpens the spec, it never implements.
- Ask ONE question at a time and wait for the answer.
- Edit as each detail is settled — small atomic edits, not one big rewrite at the end.
- Lead with the best practice when a question has a widely accepted one; call out security and performance trade-offs.
- On an OPEN DECISION, don't force the user to adjudicate: lay out the realistic options AND offer an escape hatch — \"want me to pick the sensible default?\" If they defer, choose the best-practice option yourself, breaking ties toward the simpler/faster path that keeps future options open, and record the choice with a one-line rationale in the file. This holds in every mode.
- Keep the conversation moving — do not parrot the user's words back at length.
- WRITES stay within the task pipeline: you may edit $TASK_FILE, any sub-task files you create via ./sprint.sh newtask, and — for the handoff note described below — the file of the one next dependency you chain to. You may READ any file in the repo to check assumptions (does a referenced file, API, or pattern still exist?), but write nothing else.

═══ WHEN THE TASK READS CLEARLY — FINISH, CLOSE, CHAIN ═══
Once the task in front of you (the FILL-IN/REFINE/STRESS-TEST parent, or — for a split — its children) reads as fully defined, do these in order:

1. FINISH: tell the user, and show the final state (the refined task, or the list of children with the original retired). If a \"This task is not defined yet\" marker still remains, remove it — the task is defined now. If this session produced both filled-in sections and a '## Think Notes' block, keep '## Think Notes' ahead of any closing '## Questions' section so the file stays coherent.
${_CLOSE_LOOP_INSTR}

2. FIND THE NEXT TASK TO DEFINE: read this task's '**Depends on**:' line. For each dependency number N, look for docs/tasks/blocked/N-*.md or docs/tasks/backlog/N-*.md. A dependency is UNDEFINED if that file exists and does NOT contain a line '**Status: READY**'. Among the undefined dependencies, pick the most upstream one — the dependency whose OWN '**Depends on**' has no undefined dependencies left (nothing must be defined before it); break ties by lowest number. Call it <next-id>. If there are NO undefined dependencies, the chain is complete: say so and STOP — do not spawn or recommend anything.

3. HAND OFF THROUGH THE FILE: into <next-id>'s file, under its ## Notes (create the section if absent), write a short blockquote note capturing ONLY what this conversation decided that <next-id>'s author needs to know — the constraints, choices, and interface details that flow downstream. Start it exactly '> **Context from talk (task $PARENT_NUM):**' so a later run can find and replace it instead of stacking a second copy. Keep it to a few sentences; it is a seed, not a transcript.

4. CHAIN: ${_CONTINUE_INSTR}${_DEMOTE_INSTR}"

# talk is a dialogue, not a one-shot job — fiveday_run_interactive keeps the
# CLI attached to the terminal so the user answers each question in turn. In
# emit mode the surrounding agent supplies that back-and-forth. In exec mode it
# needs an interactive-capable provider on a real terminal; when that is not
# available the run degrades to a single refinement pass — say so plainly and
# point to the guide, rather than pretending the conversation happened. The
# same fiveday_interactive_ok that routes the run decides the warning, so the
# two can never disagree.
if [ "$(fiveday_ai_mode)" = "exec" ] && ! fiveday_interactive_ok; then
  echo -e "${YELLOW}Note: a live back-and-forth needs an interactive-capable AI CLI (claude) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single refinement pass instead. To wire up the full talk experience,${NC}"
  echo -e "${YELLOW}see docs/sprintmd/guides/use_talk.md${NC}"
  echo ""
fi

fiveday_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "talk-${TASK_ID}" \
  "Read the task file at $TASK_FILE, size it up, and start talking it through — one detail at a time."
