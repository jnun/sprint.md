#!/usr/bin/env bash
# chat.sh — Talk a task through, refining it one detail at a time. See: ./sprint.sh help chat

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── Args ─────────────────────────────────────────────────────────────

TASK_ID="${1:-}"

# `chat [target]` cases, decided by the argument's SHAPE:
#   (empty)                     → walk the whole sprint's structural health
#   numeric id                  → chat that one task through (the rest of this file)
#   stage name (blocked/next/backlog) → express one-at-a-time sweep of that folder
#   bugs                        → sweep the bug inbox
#   plan [id]                   → author a plan conversationally (chat-plan.sh)
#
# No task id → walk the whole sprint instead of erroring. chat-sprint.sh runs a
# deterministic structural-health preflight over next/ + blocked/, then walks the
# findings one at a time in this same one-detail voice.
if [ -z "$TASK_ID" ]; then
  _TALK_SPRINT="$(dirname "${BASH_SOURCE[0]}")/chat-sprint.sh"
  # exec directly when the exec bit survived; fall back to `bash` on filesystems
  # that drop it (WSL/Docker/FAT32) — the same guard run_script uses.
  if [ -x "$_TALK_SPRINT" ]; then exec "$_TALK_SPRINT"; else exec bash "$_TALK_SPRINT"; fi
fi

# A stage name → sweep that whole folder one task at a time (chat-folder.sh,
# which absorbed the retired `triage`). This is checked BEFORE the numeric-id
# path so a folder name never falls through to sprintmd_find_task.
case "$TASK_ID" in
  blocked|next|backlog)
    _TALK_FOLDER="$(dirname "${BASH_SOURCE[0]}")/chat-folder.sh"
    if [ -x "$_TALK_FOLDER" ]; then exec "$_TALK_FOLDER" "$TASK_ID"; else exec bash "$_TALK_FOLDER" "$TASK_ID"; fi
    ;;
  bugs)
    # `bugs` is NOT a task stage — it is the flat bug inbox (docs/bugs/), whose
    # sweep turns reports into fix tasks. Its own script (chat-bugs.sh), routed
    # here alongside the stage folders so the whole chat grammar lives in one place.
    _TALK_BUGS="$(dirname "${BASH_SOURCE[0]}")/chat-bugs.sh"
    if [ -x "$_TALK_BUGS" ]; then exec "$_TALK_BUGS"; else exec bash "$_TALK_BUGS"; fi
    ;;
  plan)
    # `plan` is NOT a task stage — author/refine a plan file in docs/plans/.
    # Optional second arg is a *plan* id (never a task id). Bare `chat plan`
    # picks one. Writes only the plan file; backlog is read-only.
    _TALK_PLAN="$(dirname "${BASH_SOURCE[0]}")/chat-plan.sh"
    if [ -x "$_TALK_PLAN" ]; then exec "$_TALK_PLAN" "${2:-}"; else exec bash "$_TALK_PLAN" "${2:-}"; fi
    ;;
esac

# Anything else that is not a task id is a mistake — guide, don't silently
# search for a nonexistent task. (doing/, review/, done/ are not sweep targets:
# chat works the pipeline forward, not over in-flight or finished work.)
if ! [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$TASK_ID' is not a task id, a stage folder, 'bugs', or 'plan'."
  echo "Usage:"
  echo "  ./sprint.sh chat              walk the whole sprint's structural health"
  echo "  ./sprint.sh chat <id>         chat one task through (e.g. chat 42)"
  echo "  ./sprint.sh chat <folder>     sweep a folder: blocked, next, or backlog"
  echo "  ./sprint.sh chat bugs         sweep the bug inbox → fix tasks"
  echo "  ./sprint.sh chat plan [id]    author a plan (plan id; bare = pick one)"
  exit 1
fi

# ── Find the task file ───────────────────────────────────────────────

if ! _RESULT="$(sprintmd_find_task "$TASK_ID")"; then
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
_MODEL="$(sprintmd_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

# ── Launch the conversational review ─────────────────────────────────

_PROFILE_LINE="$(sprintmd_profile_line)"

# When the user chooses to split, the original file is retired once its
# children exist. In emit mode the surrounding agent performs the delete
# (the shell can't act after an emitted prompt); in exec mode the spawned
# CLI does it inline via Bash. Same wording pattern as split.sh.
if [ "$(sprintmd_ai_mode)" = "emit" ]; then
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
  _STAGE_MOVE="Each child is created in backlog/, but the original lives in ${STAGE}/ — move every finished child there with: git mv docs/tasks/backlog/<child-file> $TASK_DIR/<child-file> || mv docs/tasks/backlog/<child-file> $TASK_DIR/<child-file>  so this work stays in ${STAGE}/. "
fi

# ── Close-the-loop: a blocked task that chat fully defines goes straight back
# into the sprint. Only meaningful when the task is in blocked/ (that's where
# gate parked it); for any other stage there is no loop to close, so this is
# empty and the closing section reads clean. A human-supervised chat is a
# stronger readiness signal than gate's automated pass, so chat stamps the
# READY verdict itself instead of bouncing the task through another gate run.
if [ "$STAGE" = "blocked" ]; then
  _CLOSE_LOOP_INSTR="
1b. CLOSE THE LOOP (this task is in blocked/):
gate parked this task in blocked/ because it wasn't defined enough to work.
If — and ONLY if — the conversation has genuinely resolved it (no open decision
remains and it now reads as fully defined), close the loop so it can be worked:
1. Make the file END with a '## Questions' section whose first line is EXACTLY:
     **Status: READY**
   Keep the brief '### Already complete / ### Remaining work / ### Questions for
   the developer' structure under it; if nothing is open write 'None — task is
   fully defined.' Replace any earlier '## Questions' section, don't add a second.
2. DELETE any '## BLOCKED' section — it no longer applies.
3. Move it into the sprint queue:  git mv $TASK_FILE docs/tasks/next/$TASK_NAME || mv $TASK_FILE docs/tasks/next/$TASK_NAME
Then tell the user it's back in next/ and runnable with ./sprint.sh work.
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
# chat states the demotion plainly because a user who ran chat on a "finished"
# next/ task will not expect it to leave the sprint.
if [ "$STAGE" != "blocked" ]; then
  _DEMOTE_INSTR="

═══ IF A BLOCKING QUESTION REMAINS — RECORD, THEN DEMOTE ═══
If instead the session ends with a question that genuinely must be answered before anyone can work this task (a real blocker, not a minor nicety), then it is NOT workable — do not leave it in ${STAGE}/ as if it were ready. Do these in order:
1. RECORD the blocker: make the file END with a '## Questions' section whose first line is EXACTLY:
     **Status: BLOCKED**
   Under it, state the blocking question(s) plainly (a '### Questions for the developer' list) so a later chat or report can pick them up. Replace any earlier '## Questions' section, don't add a second.
2. DEMOTE it:  git mv $TASK_FILE docs/tasks/blocked/$TASK_NAME || mv $TASK_FILE docs/tasks/blocked/$TASK_NAME
3. TELL THE USER PLAINLY that you moved this task out of ${STAGE}/ into blocked/ and why — name the blocking question in one line, since a user who ran chat on a task they thought was finished will not expect the demotion."
else
  _DEMOTE_INSTR=""
fi

# ── Chain to the next dependency in a FRESH context. Defining one task often
# surfaces that it depends on another undefined task; walking that chain in THIS
# conversation piles context up and burns tokens. So we hand the next task off
# through its FILE (a durable note the fresh session reads) and start clean:
# emit mode on orchestration-capable tiers spawns a brand-new subagent;
# exec mode can't open a window, so it prints the command for the user to run.
if [ "$(sprintmd_ai_mode)" = "emit" ] && sprintmd_orchestration_capable; then
  _CONTINUE_INSTR="Then CONTINUE THE CHAIN in a fresh context so this session's tokens don't pile up: $(sprintmd_subagent_spawn_phrase "<next-id>"). Its entire instruction: 'Run ./sprint.sh chat <next-id> and carry that task as far toward READY as you can on your own — read the *Context from chat* note already in its file, refine it, and if a question genuinely needs the human, leave it in the file's ## Questions section and report it back.' Tell the user you have spun up a fresh agent for <next-id> and say in one line what it is picking up."
else
  _CONTINUE_INSTR="Then, to keep each session's context small, do NOT keep going here. Tell the user the next task to define and the exact command to run in a FRESH window:  ./sprint.sh chat <next-id>  — the *Context from chat* note you just wrote means that fresh session already has what it needs."
fi

# ── Context for the size-up and (especially) the stress-test ─────────
# Sprint theme is derived live from next/ (next/ IS the sprint — plan start
# put those tasks there). No cached plan file. Optional supplement: a plan
# file in docs/plans/ whose members currently sit in next/, Goal only.
# Sibling-task overlap scan of the current stage caps at 20 names.
_SPRINT_LINE=""
_next_list=""
_next_count=0
_next_ids=""
for _nf in docs/tasks/next/*.md; do
  [ -f "$_nf" ] || continue
  _next_count=$((_next_count + 1))
  _nid="${_nf##*/}"; _nid="${_nid%%-*}"
  _ntitle=$(grep -m1 '^# ' "$_nf" 2>/dev/null | sed 's/^#[[:space:]]*//')
  [ -n "$_ntitle" ] || _ntitle="${_nf##*/}"
  _next_list="${_next_list}
  - ${_nid}: ${_ntitle}"
  _next_ids="${_next_ids} ${_nid}"
done
_plan_supp=""
if [ "$_next_count" -gt 0 ] && [ -d "docs/plans" ]; then
  for _pf in docs/plans/[0-9]*.md; do
    [ -f "$_pf" ] || continue
    for _nid in $_next_ids; do
      if grep -qE "#${_nid}([^0-9]|$)" "$_pf" 2>/dev/null; then
        _goal=$(awk '/^## Goal/{f=1; next} f && /^## /{exit} f && NF{print; if(++n>=3) exit}' "$_pf" \
          | tr '\n' ' ' | sed 's/[[:space:]]*$//')
        if [ -n "$_goal" ]; then
          _pname=$(grep -m1 '^# ' "$_pf" 2>/dev/null | sed 's/^#[[:space:]]*//')
          [ -n "$_pname" ] || _pname="${_pf##*/}"
          _plan_supp="
- active plan goal (${_pname}): ${_goal}"
        fi
        break 2
      fi
    done
  done
fi
if [ "$_next_count" -gt 0 ]; then
  _SPRINT_LINE="
- current sprint (docs/tasks/next/ — live, ${_next_count} task(s); this IS the sprint):${_next_list}${_plan_supp}"
elif [ -d "docs/tasks/next" ]; then
  _SPRINT_LINE="
- current sprint (docs/tasks/next/): empty — no tasks queued"
fi

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

# Shared Conversation Method (probe → ground → recommend → open floor). Loaded
# once here so the method is stated in ai/conversation.md, not restated below.
_METHOD="$(sprintmd_conversation_method)" || exit 1

APPEND_PROMPT="You are a senior engineer reviewing a task with the colleague who wrote it. Talk it through one detail at a time until it is a crisp, executive-summary brief any developer could pick up.

The task file is at: $TASK_FILE — read it now, before you say anything.${_PROFILE_LINE}${_CONTEXT_BLOCK}

$_METHOD

YOUR GOAL: Turn a rough task into clear, actionable work — fill in a stub, refine one rough job, split several jobs, or stress-test one that already looks done. Result: what \"done\" looks like, sensible technology choices with reasoning, and references. You raise open questions; the implementer writes the code.

STEP 0 — SIZE IT UP FIRST:
In one or two sentences, what this task really is. Then a two-part call:
  (a) DEFINITION STATE — UNDEFINED STUB (Problem/Success empty/placeholder or \"This task is not defined yet\"), ROUGH or SEVERAL JOBS (thin, or bundles distinct work), or LOOKS DEFINED (Problem plus verifiable criteria already clear)?
  (b) MODE — FILL-IN, REFINE, SPLIT, or STRESS-TEST below.
Opening frame, not a locked gate: switch modes mid-session when facts warrant (hollow criterion → FILL-IN; multi-job stub → SPLIT; now-clean task → STRESS-TEST). Say so when you switch. Borderline → ask the user. Already clear → confirm, don't invent gaps.

═══ MODE: FILL-IN — undefined stub ═══
Build blank sections via the REFINE loop. Open: what does this need to accomplish and why? Then scope, done definition, dependencies, edge cases — one question at a time, edit as each lands. Drop any \"This task is not defined yet\" marker once content is real. Aim for \"WHAT A FINISHED TASK LOOKS LIKE.\"

═══ MODE: SPLIT — several pieces ═══
1. PROPOSE breakdown first: 3–10 atomic, independently completable sub-tasks, dependencies first. Confirm with the user.
2. On agreement, CREATE each via CLI:
     ./sprint.sh newtask 'short action-oriented description'
   Fill each new docs/tasks/backlog/ file:
     - **Parent**: $PARENT_NUM   (exact — './sprint.sh plan N \"parent:$PARENT_NUM\"' matches on this)
     - **Depends on**: previous sub-task number when order matters, else 'none'
     - ## Problem, ## Success criteria, ## Notes — see finished-task shape below
3. TALK THROUGH each child with the REFINE loop (not one-line stubs).
4. FINISH: original's content lives in children. ${_STAGE_MOVE}Confirm, then retire original: ${_RETIRE_INSTR}

═══ MODE: REFINE — one rough job ═══
For EACH detail:
1. ASK one question — the single most important gap (scope, done definition, technical decision, dependency, edge case, security/performance). One question, no preamble.
2. POLISH — tighten and read back: \"So the crux is …\" Correct before it lands.
3. UPDATE the file immediately — one small atomic edit. No batching to the end.
4. MOVE ON — note settled vs thin; return to step 1.

═══ MODE: STRESS-TEST — already looks defined ═══
Pressure-test before work: gaps, assumptions, sharper spec. Open with 2–3 sentences (what it does + verdict: well-defined / roughly-defined / has issues), then Q&A one question at a time, most impactful first, each grounded in a criterion/file/section:
1. GOAL ALIGNMENT: feature goals + live sprint in next/ (see CONTEXT)? Mismatch?
2. SCOPE: right size? Split? Too narrow? Sibling overlap?
3. SUCCESS CRITERIA: verifiable by someone else? Complete vs Problem? Vague/missing edges?
4. ASSUMPTIONS: taken for granted? Referenced files/APIs/patterns still exist? Unstated prereqs?
5. RISK: failure modes, performance, security, compatibility.
6. DEPENDENCIES: Depends on / Blocks real? Undeclared must-lands?
7. ALTERNATIVES: simpler way? Premature lock-in?
Stop after material findings (typically 3–7). With agreement, sharpen Problem/Success/Notes; put residual analysis in '## Think Notes' before HTML comments ('**Reviewed**: <date>', risks, alternatives, assumptions). Do not change Feature/Created/Depends on/Blocks unless asked.

WHAT A FINISHED TASK LOOKS LIKE (FILL-IN/REFINE parent and every SPLIT child):
- ## Problem — 2–5 sentences: what and why.
- ## Success criteria — observable, verifiable checkboxes for \"done.\"
- ## Notes — tech suggestions + rationale, decisions, open questions, references (repo paths + external URLs). Suggest, don't mandate.

RULES:
- Executive-summary altitude: what/why, not how. Name approaches; no code or pseudo-code. STRESS-TEST sharpens the spec only — never implements.
- One question at a time; wait for the answer.
- Edit as each detail settles — small atomic edits.
- Keep moving — no long parroting.
- WRITES: $TASK_FILE, sub-tasks from ./sprint.sh newtask, and the one next-dependency handoff file below. READ anything to check assumptions; write nothing else.

═══ RECORD THE REFINEMENT — BUMP THE PRE-WORK COUNTER ═══
If this session actually SHARPENED the task's definition (any edit to its Problem, Success criteria, Notes, or Think Notes — the FILL-IN, REFINE, or STRESS-TEST work above), record it ONCE for the whole conversation before you finish:
1. Read the current '**Refined**:' header integer (seed it as 0 if the field is somehow absent) and let N = that value + 1. Set the header line to exactly '**Refined**: N'.
2. Add a short pre-work record — place it just BEFORE any closing '## Questions' section if the file has one (so '## Questions' stays last), else at the END of the file:

    ## Refine (round N)

    **Sharpened:** 1–3 sentences naming what this pass clarified — the scope, criterion, or decision that changed.

This is definition-refinement's own record — a PRE-work operation. Use the heading '## Refine (round N)', NEVER '## Rework': '## Rework' and the '**Reworked**:' header belong to polish's POST-work pass, and this pre-work pass must not touch either of them. Only ever move '**Refined**:'.
Do NOT bump or write anything if the conversation changed nothing (a pure STRESS-TEST that confirmed the task was already clean), and do NOT record on a SPLIT's retired parent — its content moved to fresh children that each start at '**Refined**: 0'.

═══ WHEN THE TASK READS CLEARLY — FINISH, CLOSE, CHAIN ═══
Once the task in front of you (the FILL-IN/REFINE/STRESS-TEST parent, or — for a split — its children) reads as fully defined, do these in order:

1. FINISH: tell the user, and show the final state (the refined task, or the list of children with the original retired). If a \"This task is not defined yet\" marker still remains, remove it — the task is defined now. If this session produced both filled-in sections and a '## Think Notes' block, keep '## Think Notes' ahead of any closing '## Questions' section so the file stays coherent.
${_CLOSE_LOOP_INSTR}

2. FIND THE NEXT TASK TO DEFINE: read this task's '**Depends on**:' line. For each dependency number N, look for docs/tasks/blocked/N-*.md or docs/tasks/backlog/N-*.md. A dependency is UNDEFINED if that file exists and does NOT contain a line '**Status: READY**'. Among the undefined dependencies, pick the most upstream one — the dependency whose OWN '**Depends on**' has no undefined dependencies left (nothing must be defined before it); break ties by lowest number. Call it <next-id>. If there are NO undefined dependencies, the chain is complete: say so and STOP — do not spawn or recommend anything.

3. HAND OFF THROUGH THE FILE: into <next-id>'s file, under its ## Notes (create the section if absent), write a short blockquote note capturing ONLY what this conversation decided that <next-id>'s author needs to know — the constraints, choices, and interface details that flow downstream. Start it exactly '> **Context from chat (task $PARENT_NUM):**' so a later run can find and replace it instead of stacking a second copy. Keep it to a few sentences; it is a seed, not a transcript.

4. CHAIN: ${_CONTINUE_INSTR}${_DEMOTE_INSTR}"

# chat is a dialogue, not a one-shot job — sprintmd_run_interactive keeps the
# CLI attached to the terminal so the user answers each question in turn. In
# emit mode the surrounding agent supplies that back-and-forth. In exec mode it
# needs an interactive-capable provider on a real terminal; when that is not
# available the run degrades to a single refinement pass — say so plainly and
# point to the guide, rather than pretending the conversation happened. The
# same sprintmd_interactive_ok that routes the run decides the warning, so the
# two can never disagree.
if [ "$(sprintmd_ai_mode)" = "exec" ] && ! sprintmd_interactive_ok; then
  echo -e "${YELLOW}Note: a live back-and-forth needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single refinement pass instead. To wire up the full chat experience,${NC}"
  echo -e "${YELLOW}see docs/sprintmd/guides/use_chat.md${NC}"
  echo ""
fi

sprintmd_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "chat-${TASK_ID}" \
  "Read the task file at $TASK_FILE, size it up, and start chating it through — one detail at a time."
