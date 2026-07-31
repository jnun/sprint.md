# shellcheck shell=bash
# docs/sprintmd/scripts/gate.sh — the shared workability gate.
#
# Sourced (not executed) helper — no shebang or `set`; the caller provides those,
# and must have sourced lib.sh first. This is NOT a CLI command: there is no
# registry row, no dispatch arm, no help page. It is a library of gate functions.
#
# The gate runs the READY/BLOCKED/COMPLETE workability review on task files. For each
# file it runs the invariant review contract, writes the ## Questions section +
# stamp, applies the dependency-vs-definition rules, and routes the file by
# verdict (BLOCKED → blocked/, COMPLETE → review/, READY stays where it is — or moves
# to a caller-supplied READY_DIR, e.g. `plan start` promoting a vetted backlog
# member into next/). COMPLETE means work is already in the codebase — not the
# docs/tasks/done/ lifecycle folder.
#
# Every surface that may send a task into next/ (the sprint) shares this one
# implementation so verdicts never drift: `gate` (next/ CLI), `plan start`,
# `chat` folder promote, `chat` close-the-loop from blocked/, and `polish`
# REOPEN. The only supported promote is sprintmd_promote_to_sprint (or the
# same READY_DIR=next/ init + review plan start uses in bulk).
#
# Requires from lib.sh: sprintmd_run, sprintmd_ai_mode, sprintmd_ai_tier,
# sprintmd_resolve_model, sprintmd_profile_line, sprintmd_review_verdict,
# move_file, sprintmd_log_path.
#
# Usage:
#   sprintmd_gate_init [KIND] [STAY_DIR] [READY_DIR]  # once — invariant context
#   sprintmd_gate_review FILE              # one task: run + route; sets outputs
#   sprintmd_gate_parallel FILE...         # emit-mode orchestration fan-out
#   sprintmd_promote_to_sprint FILE [KIND] # gate then READY→next/ (only entry)
#
# sprintmd_gate_review sets, on return:
#   SPRINTMD_GATE_VERDICT  READY | BLOCKED | COMPLETE | EMIT | NOSTAMP | FAILED
#     EMIT    — emit mode: the surrounding agent runs the review and moves the
#               file itself; nothing to count here.
#     NOSTAMP — the review ran but wrote no verdict stamp; file left in place.
#     FAILED  — the review process errored; file left in place.
#   SPRINTMD_GATE_LOG      exec-mode log path, else empty
#   SPRINTMD_GATE_ERROR    raw failure cause when VERDICT=FAILED (may be empty),
#                          else empty. Callers apply their own default text.

SPRINTMD_GATE_BLOCKED_DIR="docs/tasks/blocked"
SPRINTMD_GATE_REVIEW_DIR="docs/tasks/review"

# Sprint context — an index of every OTHER task queued in next/ and waiting in
# backlog/. The reviewer sees one task at a time; without this it reads the task
# in isolation, finds that the code the task builds on doesn't exist yet, and —
# blind to the sibling task that will create it — mistakes a sequencing
# dependency for a blocker. With the index it can attribute a missing
# prerequisite to a real queued task, record it in '**Depends on**', and stay
# READY. Built once; identical for every task's review.
_sprintmd_gate_sprint_index() {
  local label dir f id title
  for label in next backlog; do
    dir="docs/tasks/$label"
    [ -d "$dir" ] || continue
    for f in "$dir"/*.md; do
      [ -e "$f" ] || continue
      id="${f##*/}"; id="${id%%-*}"
      title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^#[[:space:]]*//')
      [ -n "$title" ] || title="${f##*/}"
      printf '  - %s (%s): %s\n' "$id" "$label" "$title"
    done
  done
}

# sprintmd_gate_init [KIND] [STAY_DIR] [READY_DIR]
# Resolve the model/tool surface and build the task-independent context every
# review shares: the emit-mode move instruction, the profile pointer, and the
# next/backlog index block. Call once before sprintmd_gate_review /
# sprintmd_gate_parallel.
#   KIND      log-file kind for sprintmd_log_path (default "gate").
#   STAY_DIR  where a READY task stays, for the emit move instruction's wording
#             (default: "its current location"). Ignored when READY_DIR is set.
#   READY_DIR when set, a READY task is MOVED here instead of staying in place —
#             `plan start` passes next/ so a vetted backlog member is promoted
#             into the sprint. Empty (gate) = READY stays where it was.
sprintmd_gate_init() {
  SPRINTMD_GATE_KIND="${1:-gate}"
  local stay_dir="${2:-}"
  SPRINTMD_GATE_READY_DIR="${3:-}"

  SPRINTMD_GATE_MODEL="$(sprintmd_resolve_model GATE)"
  SPRINTMD_GATE_TOOLS="Read,Bash,Grep,Glob,Edit,Write"
  SPRINTMD_GATE_PERMISSIONS="auto"
  SPRINTMD_GATE_MAX_TURNS=40

  # In emit mode the agent moves files itself per its verdict; fold the moves
  # into the prompt. In exec mode the shell moves them by reading the verdict.
  SPRINTMD_GATE_MOVE_INSTR=""
  if [ "$(sprintmd_ai_mode)" = "emit" ]; then
    local ready_instr
    if [ -n "$SPRINTMD_GATE_READY_DIR" ]; then
      ready_instr="- READY   → git mv the task file to $SPRINTMD_GATE_READY_DIR/ || mv it there"
    else
      local stay_where="its current location"
      [ -n "$stay_dir" ] && stay_where="$stay_dir/"
      ready_instr="- READY   → leave the file in $stay_where"
    fi
    SPRINTMD_GATE_MOVE_INSTR="

After writing the verdict, act on it. Always move with: git mv SRC DEST || mv SRC DEST
(git mv first; plain mv finishes when the file is untracked).
- BLOCKED → git mv the task file to $SPRINTMD_GATE_BLOCKED_DIR/ || mv it there
- COMPLETE → git mv the task file to $SPRINTMD_GATE_REVIEW_DIR/ || mv it there
  (COMPLETE = work already in the codebase; not docs/tasks/done/)
$ready_instr"
  fi

  # Profile line is task-independent — resolve it once, not per task.
  SPRINTMD_GATE_PROFILE_LINE="$(sprintmd_profile_line)"

  local idx
  idx="$(_sprintmd_gate_sprint_index)"
  SPRINTMD_GATE_SPRINT_BLOCK=""
  if [ -n "$idx" ]; then
    SPRINTMD_GATE_SPRINT_BLOCK="

Other tasks already in this sprint (next/) and the backlog — a prerequisite this
task builds on is very likely one of these, NOT an undefined blocker:
$idx"
  fi
}

# The invariant review contract. Both the sequential per-task path and the
# claude-code parallel-subagent path build their prompt from this one source so
# the two can never drift. $1 is the task file the reviewer must read and edit.
sprintmd_gate_contract() {
  cat <<EOF
You are a senior developer reviewing a task before it enters a sprint.

CLAUDE.md is auto-loaded with project context and conventions.
For task workflow details, see DOCUMENTATION.md.${SPRINTMD_GATE_PROFILE_LINE}${SPRINTMD_GATE_SPRINT_BLOCK}

The task file is at: $1 — read it first.

Your job:
1. Read the task file at $1.
2. Read the actual source files referenced by this task. Thoroughly check the current state of the code for every action item.
3. Classify each action item into one of three categories:
   - COMPLETE: Already implemented in the current code.
   - REMAINING: Not yet done, and the action item is clear enough to execute.
   - UNCLEAR: Not yet done, but requires a decision or clarification before work can start.
   Before you mark anything UNCLEAR because the code it builds on is missing,
   check the next/backlog index above: if a sibling task will create that
   prerequisite, this is a DEPENDENCY, not an unclear item — keep it REMAINING
   and record the dependency (see "Dependencies on other tasks" below).
4. Produce an overall verdict: READY or BLOCKED.

How to handle COMPLETE items (already implemented in code):
- Do NOT suggest removing them. They are context for the developer.
- Briefly note that they're complete and whether the implementation looks correct and clean.
- If the implementation has issues (bugs, missing edge cases, inelegant code), flag that as remaining work.
- COMPLETE is a workability verdict, not the docs/tasks/done/ folder.

A task is READY if:
- There is remaining work to do
- All remaining action items are clear enough to execute without asking questions
- No major design decisions are unresolved
- It depends on other tasks being finished first. A dependency on other work is a
  sequencing constraint, not a definition blocker — record it and stay READY
  (see "Dependencies on other tasks" below).

A task is BLOCKED only if:
- Remaining action items require decisions the developer hasn't made yet
- Action items contradict each other, or contradict the current code in a way
  that no other queued task would resolve. Code the task builds on being absent
  because a sibling or backlog task hasn't run yet is NOT a contradiction — it is
  a dependency. Only treat a conflict with current code as a blocker when nothing
  in the next/backlog index would produce what the task assumes.
- The task is entirely implemented already and there is nothing left to do (mark as COMPLETE instead of BLOCKED — stamp **Status: COMPLETE**, which routes to review/, not done/)

Dependencies on other tasks:
Do NOT block a task merely because another task must be completed first — that is
exactly what the dependency field is for. Use the next/backlog index above to
identify prerequisites: if the code, file, or API this task builds on will be
produced by another task in next/ or backlog/, that is a dependency to record,
not a reason to block. If executing this task requires other tasks to be finished
first, ensure the task file records them in a bold '**Depends on**:' field near
the top (after the title), listing the task numbers, e.g.
'**Depends on**: 900-920, 922'. Add the field if it is missing, or update it
if it is incomplete. An unmet dependency keeps the task READY (or COMPLETE if already
implemented): the task runner holds it in next/ until those dependencies reach
review/ or done/, then runs it automatically — no one has to babysit the order.
A prerequisite task being *itself* rough, undefined, or not-yet-reviewed is STILL
a dependency, not a reason to block THIS task: that upstream task will get defined
on its own turn. Record it in '**Depends on**' and keep this task READY. Only its
own undefined-ness — a decision this task's developer must personally make — blocks
this task.
Reserve BLOCKED strictly for work that cannot be *defined* yet: genuine unresolved
decisions, contradictions, or missing clarifications a developer must supply. The
test is "could a developer start this if the prerequisite tasks were already
done?" — if yes, it is READY with a dependency, not BLOCKED.

Then update the task file by adding a ## Questions section at the end (before any HTML comments).
If a ## Questions section from a previous review already exists, replace it instead of adding a second one.

Structure the ## Questions section exactly like this:

## Questions

**Status: READY**

(or **Status: BLOCKED** / **Status: COMPLETE** — write the stamp exactly in
that bold form, on its own line, directly under the ## Questions heading.
COMPLETE = work already in the codebase → review/. Never use DONE for this stamp;
done/ is only a lifecycle folder after human approval.)

### Already complete
Items that are implemented and verified in the current code. Note any quality concerns.

### Remaining work
Summarize what's left to do. This is the actual scope for the sprint.

### Questions for the developer
Numbered list. Only include genuine questions where a decision is needed.
Each question must include a concrete suggestion with reasoning.
Format: '1. [Question]? (Suggestion: [recommendation and why])'

If there are no questions, write 'None — task is fully defined.' under this heading.

If the verdict is BLOCKED, ALSO add a '## BLOCKED' section directly above ## Questions:

## BLOCKED

One short plain-English paragraph: exactly why this task cannot proceed and what
decision or input would unblock it. Another agent (or the developer) must be able
to understand the blocker from this section alone, without reading anything else.
End the paragraph by pointing the developer to chat it through interactively:
"Run ./sprint.sh chat <task-number> to resolve these questions." A BLOCKED verdict
means the work needs human definition — this is precisely what chat is for.

If the verdict is not BLOCKED, delete any ## BLOCKED section left from a previous review.

You may only use Edit/Write on the task file at $1.
EOF
}

# ── Orchestration-capable fast path: parallel subagents ─────────────────────
# On claude-code / grok-build in emit mode, one subagent per task is faster than
# N sequential prompts; reviews are independent. Subagent wording comes from
# sprintmd_subagent_parallel_dispatch (Task tool vs spawn_subagent). Args: the
# task file paths to review (one subagent each).
sprintmd_gate_parallel() {
  local count=$# f _parallel_files=""
  for f in "$@"; do
    _parallel_files="${_parallel_files}
- ${f}"
  done

  sprintmd_run -p "You are orchestrating a parallel task-definition review of $count tasks.

$(sprintmd_subagent_parallel_dispatch) Each subagent reviews exactly one file and
follows this contract verbatim, substituting its assigned file path:

────────────────────────────────────────────────────────────
$(sprintmd_gate_contract "<the task file assigned to this subagent>")${SPRINTMD_GATE_MOVE_INSTR}
────────────────────────────────────────────────────────────

Task files to review (one subagent each):${_parallel_files}

When every subagent has finished, print a summary table: one row per task with
its file name and final verdict (READY / BLOCKED / COMPLETE)."
}

# If the review stamped BLOCKED but didn't write a ## BLOCKED section, synthesize
# one from the open questions so the file stands alone. The reason must live IN
# the file — screen output is evanescent and other agents can only work what is
# written down. $1 is the (already-moved) blocked task file.
_sprintmd_gate_ensure_blocked_section() {
  local file="$1" name
  name="$(basename "$file")"
  grep -q '^## BLOCKED' "$file" && return 0
  # Extract the questions BEFORE opening the append redirection — reading the
  # file while appending to it would copy the half-written section back into
  # itself.
  local _qs
  _qs=$(awk '/^## Questions[[:space:]]*$/{s=""; f=1} f{s=s $0 "\n"} END{printf "%s", s}' "$file" \
          | sed -n '/^### Questions for the developer/,$p' | sed '1d')
  {
    echo ""
    echo "## BLOCKED"
    echo ""
    echo "Blocked by gate review on $(date +%Y-%m-%d). The open questions"
    echo "below must be answered before work can start. Talk them through"
    echo "interactively with: ./sprint.sh chat ${name%%-*}"
    echo "$_qs"
  } >> "$file" \
    || echo "  ⚠ Could not write ## BLOCKED section to $file"
}

# sprintmd_gate_review FILE
# Run the gate on ONE task file in the current AI mode, apply its verdict, and
# report the outcome via the SPRINTMD_GATE_* output variables (see header).
# In exec mode the file is moved here (BLOCKED → blocked/, COMPLETE → review/); in
# emit mode the surrounding agent performs the move per the folded-in instruction.
# shellcheck disable=SC2034  # SPRINTMD_GATE_VERDICT/LOG/ERROR are outputs read by callers
sprintmd_gate_review() {
  local task_file="$1" task_name
  task_name="$(basename "$task_file")"
  SPRINTMD_GATE_LOG=""
  SPRINTMD_GATE_ERROR=""

  local prompt
  prompt="$(sprintmd_gate_contract "$task_file")${SPRINTMD_GATE_MOVE_INSTR}"

  local _model_args=()
  [ -n "$SPRINTMD_GATE_MODEL" ] && _model_args=(--model "$SPRINTMD_GATE_MODEL")

  # Emit mode: print the review prompt for the current agent to run and move.
  if [ "$(sprintmd_ai_mode)" = "emit" ]; then
    sprintmd_run -p "$prompt" \
      ${_model_args[@]+"${_model_args[@]}"} \
      --tools "$SPRINTMD_GATE_TOOLS" --permissions "$SPRINTMD_GATE_PERMISSIONS"
    SPRINTMD_GATE_VERDICT="EMIT"
    return 0
  fi

  local log_file
  log_file="$(sprintmd_log_path "$SPRINTMD_GATE_KIND" "$task_name")"
  SPRINTMD_GATE_LOG="$log_file"

  if sprintmd_run -p "$prompt" \
    ${_model_args[@]+"${_model_args[@]}"} \
    --tools "$SPRINTMD_GATE_TOOLS" \
    --permissions "$SPRINTMD_GATE_PERMISSIONS" \
    --max-turns "$SPRINTMD_GATE_MAX_TURNS" \
    --output-format json > "$log_file"; then

    # Route by the review's verdict stamp (anchored — body text that merely
    # mentions the verdict vocabulary cannot mis-route, see lib.sh).
    case "$(sprintmd_review_verdict "$task_file")" in
      BLOCKED)
        move_file "$task_file" "$SPRINTMD_GATE_BLOCKED_DIR/$task_name"
        _sprintmd_gate_ensure_blocked_section "$SPRINTMD_GATE_BLOCKED_DIR/$task_name"
        SPRINTMD_GATE_VERDICT="BLOCKED"
        ;;
      COMPLETE)
        move_file "$task_file" "$SPRINTMD_GATE_REVIEW_DIR/$task_name"
        SPRINTMD_GATE_VERDICT="COMPLETE"
        ;;
      READY)
        # Default (gate): READY stays put. With READY_DIR set (plan start),
        # a vetted member is promoted — moved into next/ — only now that it
        # graded READY, so unready work never touches the sprint.
        if [ -n "${SPRINTMD_GATE_READY_DIR:-}" ]; then
          move_file "$task_file" "$SPRINTMD_GATE_READY_DIR/$task_name"
        fi
        SPRINTMD_GATE_VERDICT="READY"
        ;;
      *)
        SPRINTMD_GATE_VERDICT="NOSTAMP"
        ;;
    esac
  else
    SPRINTMD_GATE_ERROR=$(grep -oE 'API Error[^"]*' "$log_file" 2>/dev/null | tail -1 || true)
    SPRINTMD_GATE_VERDICT="FAILED"
  fi
  return 0
}

# sprintmd_promote_to_sprint FILE [KIND]
# The only supported way to move a task into next/ (the sprint). Runs the shared
# workability gate; routes by verdict:
#   READY    → next/   (stamped workable)
#   BLOCKED  → blocked/ (reason written into the file)
#   COMPLETE → review/ (work already in the codebase)
# Never raw-mv into next/. KIND is the log-file kind (default: promote).
# Sets SPRINTMD_GATE_* like sprintmd_gate_review. Returns 0 after a completed
# review attempt; non-zero only when the file is missing.
sprintmd_promote_to_sprint() {
  local task_file="${1:?sprintmd_promote_to_sprint: file required}"
  local kind="${2:-promote}"
  if [ ! -f "$task_file" ]; then
    SPRINTMD_GATE_VERDICT="FAILED"
    SPRINTMD_GATE_ERROR="file not found: $task_file"
    SPRINTMD_GATE_LOG=""
    return 1
  fi
  mkdir -p docs/tasks/next "$SPRINTMD_GATE_BLOCKED_DIR" "$SPRINTMD_GATE_REVIEW_DIR"
  # Always re-init so READY_DIR is next/ even if a prior stay-in-place gate init
  # ran in this process.
  sprintmd_gate_init "$kind" "docs/tasks/next" "docs/tasks/next"
  sprintmd_gate_review "$task_file"
}

# Human one-liner for a promote/gate verdict (stdout). Safe when VERDICT unset.
sprintmd_promote_summary() {
  local name="${1:-task}"
  case "${SPRINTMD_GATE_VERDICT:-}" in
    READY)    echo "✓ READY → next/: $name" ;;
    BLOCKED)  echo "⊘ BLOCKED → blocked/: $name" ;;
    COMPLETE) echo "✓ COMPLETE → review/: $name" ;;
    EMIT)     echo "▸ Gate review emitted for $name — run the prompt above (READY → next/)." ;;
    NOSTAMP)  echo "✗ gate NOSTAMP: $name — left in place (no verdict written)" ;;
    FAILED)
      echo "✗ gate FAILED: $name — left in place"
      [ -n "${SPRINTMD_GATE_ERROR:-}" ] && echo "  ${SPRINTMD_GATE_ERROR}"
      [ -n "${SPRINTMD_GATE_LOG:-}" ] && echo "  log: $SPRINTMD_GATE_LOG"
      ;;
    *)        echo "? gate ${SPRINTMD_GATE_VERDICT:-unknown}: $name" ;;
  esac
}
