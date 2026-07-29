#!/usr/bin/env bash
# tasks.sh — Execute tasks from next/. See: ./sprint.sh help tasks

set -euo pipefail

# ── Argument parsing ────────────────────────────────────────────────
MAX_TASKS=999
PARALLEL=0
MAX_JOBS=2
FIVEDAY_SKIP_DRIFT_CHECK=1
RUN_AUDIT=0
RUN_EXCELLENCE=0
FORCE=0
_NO_LIMITS=0
_next_is_jobs=0
VERBOSE=0
for arg in "$@"; do
  if [ "$_next_is_jobs" -eq 1 ]; then
    MAX_JOBS="$arg"
    _next_is_jobs=0
    continue
  fi
  case "$arg" in
    --drift)      FIVEDAY_SKIP_DRIFT_CHECK=0 ;;
    --audit)      RUN_AUDIT=1 ;;
    --excellence) RUN_EXCELLENCE=1 ;;
    --parallel) PARALLEL=1 ;;
    --fast)     PARALLEL=1; MAX_JOBS=4 ;;
    --max)      _NO_LIMITS=1 ;;
    --force)    FORCE=1 ;;
    --assist)   _ASSIST=1 ;;
    --jobs)     _next_is_jobs=1 ;;
    --verbose)  VERBOSE=1 ;;
    [0-9]*)     MAX_TASKS="$arg" ;;
  esac
done
unset _next_is_jobs

# ── Interactive assist mode ─────────────────────────────────────────
if [ "${_ASSIST:-0}" -eq 1 ]; then
  echo ""
  echo "  ┌─────────────────────────────────────────┐"
  echo "  │         sprint.md Task Runner             │"
  echo "  └─────────────────────────────────────────┘"
  echo ""
  echo "  Pick a run mode:"
  echo ""
  echo "  1) Standard              sequential"
  echo "  2) Fast parallel         --fast (4 concurrent jobs)"
  echo "  3) Full quality          --max --audit --excellence (correctness + excellence)"
  echo "  4) Full quality + fast   --max --audit --excellence --fast"
  echo ""
  printf "  Choice [1-4]: "
  read -r _choice </dev/tty 2>/dev/null || _choice="1"
  echo ""
  case "$_choice" in
    1) set -- ;;
    2) set -- --fast ;;
    3) set -- --max --audit --excellence ;;
    4) set -- --max --audit --excellence --fast ;;
    *) echo "  Invalid choice, running standard."; set -- ;;
  esac

  # Re-parse the selected flags
  MAX_TASKS=999; PARALLEL=0; MAX_JOBS=2; RUN_AUDIT=0; RUN_EXCELLENCE=0
  _NO_LIMITS=0; FIVEDAY_SKIP_DRIFT_CHECK=1
  for arg in "$@"; do
    case "$arg" in
      --drift)      FIVEDAY_SKIP_DRIFT_CHECK=0 ;;
      --audit)      RUN_AUDIT=1 ;;
      --excellence) RUN_EXCELLENCE=1 ;;
      --parallel) PARALLEL=1 ;;
      --fast)     PARALLEL=1; MAX_JOBS=4 ;;
      --max)      _NO_LIMITS=1 ;;
    esac
  done
fi
unset _ASSIST

NEXT_DIR="docs/tasks/next"
WORKING_DIR="docs/tasks/doing"
REVIEW_DIR="docs/tasks/review"
BLOCKED_DIR="docs/tasks/blocked"
LOG_DIR="docs/tmp"

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# To run one invocation against a different CLI or mode, prefix the command:
#   FIVEDAY_CLI=codex ./sprint.sh tasks      (exec that CLI in a plain terminal)
#   FIVEDAY_MODE=emit ./sprint.sh tasks      (force prompt emit for any agent)

MODEL="$(fiveday_resolve_model TASKS)"

TOOLS="Read,Edit,Write,Bash,Grep,Glob,Agent"
PERMISSIONS="auto"

# No turn cap: readiness (define) gates entry and the budget cap below is the
# backstop. A turn cap decapitates normal runs mid-work and mislabels them
# "too complex" — a healthy task run is ~25-30 turns.
# --max removes the budget cap (the only per-run guardrail)
if [ "$_NO_LIMITS" -eq 1 ]; then
  FIVEDAY_BUDGET_TASKS=""
fi
unset _NO_LIMITS

# ── Preflight ───────────────────────────────────────────────────────
# run_with_timeout comes from lib.sh. In emit mode no CLI binary is needed;
# in exec mode fiveday_ai_mode already verified the binary exists.
DRIFT_TIMEOUT=120
AI_MODE="$(fiveday_ai_mode)"

mkdir -p "$LOG_DIR"

for dir in "$NEXT_DIR" "$WORKING_DIR" "$REVIEW_DIR" "$BLOCKED_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing directory: $dir"
    exit 1
  fi
done

TASK_FILES=()
while IFS= read -r f; do
  TASK_FILES+=("$f")
done < <(
  ls -1 "$NEXT_DIR"/*.md 2>/dev/null \
    | sed 's|.*/||' \
    | sort -t- -k1,1n \
    | sed "s|^|$NEXT_DIR/|"
)

if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No tasks in $NEXT_DIR"
  exit 0
fi

# ── Readiness gate ──────────────────────────────────────────────────
# define.sh stamps '**Status: READY**' into tasks it has vetted. A task
# without that verdict hasn't been checked for clarity — and a headless
# run can't ask clarifying questions, so ambiguity turns into wandering
# and failure. Undefined tasks are skipped, not executed. --force overrides.
# A dependency wait is separate from readiness: define stamps a task READY once
# it is fully defined, but records unfinished prerequisites in '**Depends on**'
# instead of blocking on them. This gate holds such a task in next/ until every
# prerequisite reaches review/ or done/, then releases it automatically — so
# nothing executes out of order and no human has to babysit the sequence.
# (Dependency state is evaluated once, up front. If task B depends on task A and
# both are queued in this run, B is held this pass and becomes runnable on the
# next one, after A has landed in review/. --force bypasses both gates.)
if [ "$FORCE" -ne 1 ]; then
  _defined=()
  _skipped=()
  for _f in "${TASK_FILES[@]}"; do
    if [ "$(fiveday_review_verdict "$_f")" != "READY" ]; then
      _skipped+=("$_f")
    else
      _defined+=("$_f")
    fi
  done
  if [ ${#_skipped[@]} -gt 0 ]; then
    echo "⊘ Skipping ${#_skipped[@]} task(s) not yet defined (no 'Status: READY' verdict):"
    for _f in "${_skipped[@]}"; do echo "    ${_f##*/}"; done
    echo "  Vet them first:  ./sprint.sh define"
    echo "  Or run anyway:   ./sprint.sh tasks --force"
    echo ""
  fi
  TASK_FILES=(${_defined[@]+"${_defined[@]}"})
  if [ ${#TASK_FILES[@]} -eq 0 ]; then
    echo "No ready tasks in $NEXT_DIR"
    exit 0
  fi
  # Dependency-waiting tasks are NO LONGER dropped from the run. The scheduler
  # below re-checks dependencies as each task lands in review/, so a chain
  # (A→B→C queued together) drains in a single pass and independent tasks run
  # first. This is purely informational — the tasks still execute.
  _waiting=()
  for _f in "${TASK_FILES[@]}"; do
    _unmet="$(fiveday_unmet_deps "$_f")"
    [ -n "$_unmet" ] && _waiting+=("${_f##*/}  (needs: ${_unmet})")
  done
  if [ ${#_waiting[@]} -gt 0 ]; then
    echo "⏳ ${#_waiting[@]} task(s) start blocked on dependencies — released automatically"
    echo "   as those prerequisites land in review/ during this run:"
    for _w in "${_waiting[@]}"; do echo "    ${_w}"; done
    echo ""
  fi
  unset _defined _skipped _waiting _f _w _unmet
fi

# COUNT is the launch cap for this pass (how many tasks may execute). It bounds
# the scheduler below; a run may execute fewer if some tasks stay blocked on
# dependencies that never land this pass. loop.sh passes MAX_TASKS=1 to run a
# single task per iteration — that still holds here.
COUNT=${#TASK_FILES[@]}
if [ "$COUNT" -gt "$MAX_TASKS" ]; then
  COUNT=$MAX_TASKS
fi

echo "▸ up to $COUNT task(s) queued from $NEXT_DIR"
echo ""

if [ "$VERBOSE" -eq 1 ]; then
  for ((i=0; i<COUNT; i++)); do
    _vf="${TASK_FILES[$i]}"
    _vn="${_vf##*/}"
    echo "──────────────────────────────────────────────────────────"
    echo "  $((i + 1))/$COUNT: $_vn"
    echo "──────────────────────────────────────────────────────────"
    sed 's/^/  /' "$_vf"
    echo ""
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ── Runner ──────────────────────────────────────────────────────────

COMPLETED=0
FAILED=0
INCOMPLETE=0
BLOCKERS=0
HARD_FAIL=0
TOTAL_START=$SECONDS
AUDIT_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/audit-code.sh"
EXCELLENCE_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/audit-excellence.sh"

_model_args=();  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
_budget_args=(); [ -n "${FIVEDAY_BUDGET_TASKS:-}" ] && _budget_args=(--budget "$FIVEDAY_BUDGET_TASKS")

# Shared execution rules — used by both the exec prompt and the emit
# subagent instruction so they can't drift.
_TASK_RULES="- Change ONLY files relevant to this task.
- Grep/Glob first, read minimal code.
- Use Edit/Write for changes.
- Run only relevant tests/linters on files you touched.
- If you cannot finish, document what remains in the task file.
- When done, check off items and add a ## Completed section. End it with a
  '### Files changed' subsection listing one repo-relative path per line —
  every file this task created or modified, and only those.
- Do NOT commit."

# Build the execution prompt for a task file at a given path (exec mode).
_task_prompt() {
  local path="$1" content profile_line
  content=$(<"$path")
  profile_line="$(fiveday_profile_line)"
  cat <<PROMPT
You are executing ONE task from the project queue.
CLAUDE.md is auto-loaded.${profile_line}
Task file: $path

TASK:
---
$content
---

Rules:
$_TASK_RULES
PROMPT
}

# ── Emit mode: hand the queue to the surrounding agent ───────────────
# On claude-code the driver has a Task/subagent tool, so we emit an
# orchestration plan: dispatch each task to a FRESH subagent so tasks don't
# share context, run them in parallel, and move each file by result — this
# mirrors exec mode's per-task isolation natively. Other tiers (cursor, openai,
# generic) can't be assumed to have a subagent tool; handing them the
# orchestration prompt is a broken imitation. They get the honest sequential
# fallback: work the tasks one at a time in the current context, resetting focus
# between them. Same routing rules either way, so behavior can't drift.
if [ "$AI_MODE" = "emit" ]; then
  _profile_line="$(fiveday_profile_line)"

  _task_list=""
  for ((i=0; i<COUNT; i++)); do
    _task_list="${_task_list}
- ${TASK_FILES[$i]}"
  done

  _jobs_hint="in parallel, a few at a time"
  [ "$PARALLEL" -eq 1 ] && _jobs_hint="in parallel, up to $MAX_JOBS at a time"

  _audit_step=""
  [ "$RUN_AUDIT" -eq 1 ] && _audit_step="
   c. If it landed in review/, run: ./sprint.sh review-code docs/tasks/review/<name>"

  # Excellence presumes correctness, so it runs AFTER the code audit. A
  # BLOCKER verdict does not halt the queue — the file stays in review/.
  _excellence_step=""
  [ "$RUN_EXCELLENCE" -eq 1 ] && _excellence_step="
   d. If it landed in review/, run: ./sprint.sh excellence docs/tasks/review/<name>
      (leave it in review/ even if the verdict is BLOCKER)"

  if [ "$(fiveday_ai_tier)" = "claude-code" ]; then
    fiveday_run -p "You are running the sprint.md task queue: $COUNT task(s) to execute.
CLAUDE.md is auto-loaded.${_profile_line}

Execute each task in its OWN fresh subagent (Task tool) so tasks never share
context. Dispatch them $_jobs_hint. You are the orchestrator — the subagents
do the work, you move the files.

For EACH task file listed below:
1. Move it into doing/:   git mv <path> docs/tasks/doing/
2. Launch a subagent whose entire instruction is:
     \"Execute ONE task. Read the task file at docs/tasks/doing/<name> and do the work.
$_TASK_RULES\"
3. When the subagent returns, read docs/tasks/doing/<name> and route it:
   a. contains a '## Completed' section → git mv it to docs/tasks/review/
   b. otherwise → git mv it to docs/tasks/blocked/ and note what remains${_audit_step}${_excellence_step}

Tasks (in order):$_task_list

When every task has been routed, report a one-line summary:
how many landed in review/ vs blocked/."
  else
    # Honest sequential fallback — no subagent tool assumed.
    fiveday_run -p "You are running the sprint.md task queue: $COUNT task(s) to execute.
CLAUDE.md is auto-loaded.${_profile_line}

Work the tasks ONE AT A TIME, in the listed order. You do not have a subagent
tool, so you are the worker, not an orchestrator — after finishing each task,
reset your focus and start the next one from a clean slate.

For EACH task file listed below:
1. Move it into doing/:   git mv <path> docs/tasks/doing/
2. Read docs/tasks/doing/<name> and do the work:
$_TASK_RULES
3. Route it:
   a. you wrote a '## Completed' section → git mv it to docs/tasks/review/
   b. otherwise → git mv it to docs/tasks/blocked/ and note what remains${_audit_step}${_excellence_step}

Tasks (in order):$_task_list

When every task has been routed, report a one-line summary:
how many landed in review/ vs blocked/."
  fi
  exit 0
fi

# ── exec helpers (shared by sequential and parallel) ─────────────────

# Render stream-json events as one line per step so a live run is visible.
# Non-JSON lines (CLI errors on stderr) pass through prefixed with '!'.
_stream_filter() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -u -c '
import json, sys
def hint(inp):
    for k in ("file_path", "command", "pattern", "description", "path"):
        if inp.get(k):
            return " ".join(str(inp[k]).split())[:100]
    return ""
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    try:
        e = json.loads(line)
    except ValueError:
        print("  ! " + line)
        continue
    t = e.get("type")
    if t == "assistant":
        for b in e.get("message", {}).get("content", []):
            if b.get("type") == "tool_use":
                print("  -> %s %s" % (b.get("name", "?"), hint(b.get("input", {}))))
            elif b.get("type") == "text" and b.get("text", "").strip():
                txt = " ".join(b["text"].split())
                print("   · " + (txt[:200] + "..." if len(txt) > 200 else txt))
    elif t == "result":
        secs = int(e.get("duration_ms", 0) / 1000)
        print("  == %s: %s turns, %dm %02ds, $%.2f" % (
            e.get("subtype", "?"), e.get("num_turns", "?"),
            secs // 60, secs % 60, e.get("total_cost_usd") or 0))
' || cat
  else
    cat
  fi
}

# Run the AI on a task already in doing/. The raw stream-json event log
# always lands in docs/tmp/; pass display=1 (sequential mode) to also
# render live progress on the terminal. Returns the CLI's exit code.
_run_task() {
  local name="$1" display="${2:-0}" log
  log="$(fiveday_log_path tasks "$name")"
  if [ "$display" -eq 1 ]; then
    fiveday_run -p "$(_task_prompt "$WORKING_DIR/$name")" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$TOOLS" \
      --permissions "$PERMISSIONS" \
      --output-format stream-json --verbose 2>&1 \
      | tee "$log" | _stream_filter
  else
    fiveday_run -p "$(_task_prompt "$WORKING_DIR/$name")" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$TOOLS" \
      --permissions "$PERMISSIONS" \
      --output-format stream-json --verbose > "$log" 2>&1
  fi
}

# Route a finished task (in doing/) to review/ or blocked/, update counters.
# Args: name  exit_code
_route_result() {
  local name="$1" rc="$2"
  if [ "$rc" -eq 0 ] && grep -q '^## Completed' "$WORKING_DIR/$name"; then
    if [ "$RUN_AUDIT" -eq 1 ] && [ -f "$AUDIT_SCRIPT" ]; then
      echo "  ▸ Running code audit..."
      if bash "$AUDIT_SCRIPT" "$WORKING_DIR/$name"; then
        echo "  ✓ Audit passed"
      else
        echo "  ⚠ Audit completed with warnings (see task file)"
      fi
    fi
    # Excellence presumes correctness, so it runs AFTER the code audit. It
    # appends its own '## Excellence' section to the task file. A BLOCKER
    # verdict does NOT halt the queue — the task still routes to review/;
    # the blocker is only counted in the end-of-run summary. Detect it by
    # the appended verdict line, not the exit code: exit 1 also covers the
    # UNCLEAR/parse-failure case, which is not a blocker.
    if [ "$RUN_EXCELLENCE" -eq 1 ] && [ -f "$EXCELLENCE_SCRIPT" ]; then
      echo "  ▸ Running excellence audit..."
      if bash "$EXCELLENCE_SCRIPT" "$WORKING_DIR/$name"; then
        echo "  ✓ Excellence audit passed"
      else
        echo "  ⚠ Excellence audit completed with findings (see task file)"
      fi
      if grep -q '^- \*\*Verdict\*\*: BLOCKER' "$WORKING_DIR/$name"; then
        BLOCKERS=$((BLOCKERS + 1))
        echo "  ⚠ Excellence: BLOCKER recorded — routing to review/ for human attention"
      fi
    fi
    move_file "$WORKING_DIR/$name" "$REVIEW_DIR/$name"
    COMPLETED=$((COMPLETED + 1))
    echo "  ✓ Complete → $REVIEW_DIR/$name"
  elif [ "$rc" -eq 0 ]; then
    # Ran to completion but never wrote ## Completed — the run stopped short
    # (or hit the budget cap). The prompt requires documenting what remains.
    move_file "$WORKING_DIR/$name" "$BLOCKED_DIR/$name"
    INCOMPLETE=$((INCOMPLETE + 1))
    echo "  ⚠ Incomplete — no '## Completed' section."
    echo "    → Moved to $BLOCKED_DIR/$name (task file should note what remains)"
  else
    FAILED=$((FAILED + 1))
    HARD_FAIL=1
    echo "  ✗ Failed (exit $rc) — left in $WORKING_DIR/$name"
    echo "    Log: docs/tmp/log-tasks-${name%.md}-*.json"
  fi
}

trap 'echo ""; [ -n "${TASK_NAME:-}" ] && echo "▸ Interrupted — current task left in $WORKING_DIR/$TASK_NAME" || echo "▸ Interrupted"; exit 130' INT TERM

# Recursively kill a process and all of its descendants. `_run_task` runs in a
# wrapper subshell whose PID we track, but the actual CLI child (and whatever it
# spawns) is a grandchild — killing only the tracked PID would orphan the CLI,
# leaving a zombie burning tokens. Walk the tree leaves-first so parents don't
# reap-and-replace before we reach the children.
_kill_tree() {
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    _kill_tree "$child"
  done
  kill "$pid" 2>/dev/null || true
}

# _is_runnable FILE -> 0 if every declared dependency is complete (has reached
# review/ or done/, or was never a real task), 1 if it still waits on one. The
# check is filesystem-based (fiveday_unmet_deps scans backlog/next/doing/blocked),
# so it is always current: re-calling it after a task routes to review/ is how a
# dependent releases mid-run. A task in doing/ (actively running) still reads as
# incomplete, so a dependent correctly waits until its prerequisite finishes.
_is_runnable() { [ -z "$(fiveday_unmet_deps "$1")" ]; }

# Print any never-launched tasks passed as arguments (their next/ paths),
# splitting genuine dependency holds from tasks left only because the launch cap
# was hit. Positional-arg based — no bash-4 namerefs (this repo targets 3.2).
_report_held() {
  local f unmet _held_dep=() _held_cap=()
  for f in "$@"; do
    unmet="$(fiveday_unmet_deps "$f")"
    if [ -n "$unmet" ]; then
      _held_dep+=("${f##*/}  (needs: ${unmet})")
    else
      _held_cap+=("${f##*/}")
    fi
  done
  if [ ${#_held_dep[@]} -gt 0 ]; then
    echo "⏳ ${#_held_dep[@]} task(s) still waiting on unfinished dependencies — left in $NEXT_DIR/:"
    for f in "${_held_dep[@]}"; do echo "    ${f}"; done
    echo "  They run automatically once those dependencies reach review/ or done/."
    echo ""
  fi
  if [ ${#_held_cap[@]} -gt 0 ]; then
    echo "▸ ${#_held_cap[@]} runnable task(s) not started — launch cap reached. Run again to continue."
    echo ""
  fi
}

# ── Parallel runner ────────────────────────────────────────────────
# Dependency-aware job pool. Unlike a fixed index sweep, this only launches a
# task whose prerequisites are already complete, moves it to doing/ AT launch
# time (a task still waiting stays in next/, where dependents correctly read it
# as incomplete), and routes each finished task IMMEDIATELY — so a dependent
# becomes launchable the moment its prerequisite lands in review/, all within
# this one run. Sequential order among ready tasks is preserved (lowest ID first).
if [ "$PARALLEL" -eq 1 ]; then

  NTASK=${#TASK_FILES[@]}
  STATE=(); PIDS=()                       # STATE[i]: 0 pending, 1 running, 2 done
  for ((i=0; i<NTASK; i++)); do STATE+=(0); PIDS+=(0); done

  # Interrupt handling. Kill the whole process tree of every running task (the
  # CLI child is a grandchild of the tracked wrapper PID and would otherwise
  # orphan). Running tasks stay in doing/ for inspection — loop.sh's orphan
  # sweep rescues them; pending tasks were never moved, so they remain in next/.
  # shellcheck disable=SC2154
  trap '
    echo ""; echo "▸ Interrupted — killing background tasks..."
    for p in "${PIDS[@]}"; do [ "$p" -ne 0 ] && _kill_tree "$p"; done
    wait 2>/dev/null
    echo "▸ In-progress tasks left in $WORKING_DIR/ (loop rescues them); pending tasks remain in $NEXT_DIR/"
    exit 130' INT TERM

  LAUNCHED=0; RUNNING=0

  # Launch lowest-ID pending+runnable tasks while a slot and the cap remain.
  _try_launch() {
    local idx j name
    while [ "$RUNNING" -lt "$MAX_JOBS" ] && [ "$LAUNCHED" -lt "$COUNT" ]; do
      idx=-1
      for ((j=0; j<NTASK; j++)); do
        [ "${STATE[$j]}" -eq 0 ] || continue
        if _is_runnable "${TASK_FILES[$j]}"; then idx=$j; break; fi
      done
      [ "$idx" -lt 0 ] && break          # nothing runnable right now
      name="${TASK_FILES[$idx]##*/}"
      move_file "${TASK_FILES[$idx]}" "$WORKING_DIR/$name"
      _run_task "$name" &
      PIDS[$idx]=$!
      STATE[$idx]=1
      RUNNING=$((RUNNING + 1)); LAUNCHED=$((LAUNCHED + 1))
      echo "  ▸ Launched $LAUNCHED/$COUNT: $name"
    done
  }

  echo "▸ Running up to $COUNT task(s), --jobs $MAX_JOBS (dependency-aware)..."
  echo ""
  _try_launch
  if [ "$RUNNING" -eq 0 ]; then
    echo "  (no tasks are currently runnable — all remaining wait on unfinished dependencies)"
  fi
  echo ""

  # Poll for completions; route each immediately, then try to launch more so
  # freshly-unblocked dependents start without waiting for the whole batch.
  while [ "$RUNNING" -gt 0 ]; do
    _progressed=0
    for ((i=0; i<NTASK; i++)); do
      if [ "${STATE[$i]}" -eq 1 ] && ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
        _rc=0
        wait "${PIDS[$i]}" 2>/dev/null && _rc=0 || _rc=$?
        STATE[$i]=2
        RUNNING=$((RUNNING - 1))
        _elapsed=$((SECONDS - TOTAL_START))
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "▸ Finished ${TASK_FILES[$i]##*/} (${_elapsed}s)"
        _route_result "${TASK_FILES[$i]##*/}" "$_rc"
        echo ""
        _progressed=1
      fi
    done
    [ "$_progressed" -eq 1 ] && _try_launch
    [ "$RUNNING" -gt 0 ] && sleep 3
  done

  # Report anything never launched (dependency-held, or cap reached).
  _undone=()
  for ((i=0; i<NTASK; i++)); do
    [ "${STATE[$i]}" -eq 2 ] || _undone+=("${TASK_FILES[$i]}")
  done
  [ ${#_undone[@]} -gt 0 ] && _report_held "${_undone[@]}"

# ── Sequential runner (default) ───────────────────────────────────
# Dependency-aware, one task at a time. Each pass picks the lowest-ID task that
# is not yet done and whose prerequisites are complete, so a chain queued in the
# same run drains here too: A runs and lands in review/, then B becomes runnable
# on the very next pick. Undefined/blocked-dependency tasks are simply never
# picked and reported at the end. --fast (above) is what overlaps independents.
else

DONE_FLAG=()
for ((i=0; i<${#TASK_FILES[@]}; i++)); do DONE_FLAG+=(0); done
LAUNCHED=0

while [ "$LAUNCHED" -lt "$COUNT" ]; do
  # Pick the lowest-ID pending, runnable task.
  _pick=-1
  for ((i=0; i<${#TASK_FILES[@]}; i++)); do
    [ "${DONE_FLAG[$i]}" -eq 0 ] || continue
    if _is_runnable "${TASK_FILES[$i]}"; then _pick=$i; break; fi
  done
  [ "$_pick" -lt 0 ] && break             # nothing runnable remains

  i=$_pick
  TASK_FILE="${TASK_FILES[$i]}"
  TASK_NAME="${TASK_FILE##*/}"
  DONE_FLAG[$i]=1
  LAUNCHED=$((LAUNCHED + 1))
  N=$LAUNCHED
  TASK_START=$SECONDS

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Task $N/$COUNT: $TASK_NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  move_file "$TASK_FILE" "$WORKING_DIR/$TASK_NAME"
  TASK_CONTENT=$(<"$WORKING_DIR/$TASK_NAME")

  # ── Pre-work drift check (opt-in via --drift) ──────────────────────
  if [ "${FIVEDAY_SKIP_DRIFT_CHECK:-}" != "1" ]; then
    echo "  ▸ Drift check..."

    _drift_model="$(fiveday_resolve_model DRIFT)"
    _drift_model_args=()
    [ -n "$_drift_model" ] && _drift_model_args=(--model "$_drift_model")

    DRIFT_PROMPT="You are checking whether a task is still relevant before it gets worked.

CLAUDE.md is auto-loaded with project context and conventions.

Read the task file at: $WORKING_DIR/$TASK_NAME

Then check the current codebase to determine:
- Has this work ALREADY been completed? (the features/fixes described exist)
- Does the task reference files, patterns, or APIs that no longer exist?

If the task is OUTDATED, try to fix it:
- Identify what changed (renamed files, moved APIs, refactored code)
- Update the task file with corrected references and adjusted action items
- After editing the file, list the fixes you made as bullet points

Output EXACTLY ONE of these verdicts on the LAST line of your response:

DONE - The task has already been completed (nothing to do)
FIXED - The task was outdated but you updated the file with corrections
OUTDATED - The task is outdated and you cannot resolve the drift
PROCEED - The task is still relevant and ready to work

Rules:
- Be conservative: if in doubt, say PROCEED
- DONE means the specific work is clearly already present in the codebase
- FIXED means you edited the task file to account for codebase drift
- OUTDATED means the drift is too severe for you to fix — needs human rewrite
- Before your verdict, list any fixes you made as bullet points (for FIXED)"

    DRIFT_VERDICT=$(run_with_timeout "$DRIFT_TIMEOUT" fiveday_run -p "$DRIFT_PROMPT" \
      "${_drift_model_args[@]}" \
      --tools "Read,Edit,Write,Grep,Glob,Bash" \
      --skip-permissions \
      --max-turns 20 2>/dev/null) || true

    _drift_action=$(echo "$DRIFT_VERDICT" | grep -oE '\b(DONE|FIXED|OUTDATED|PROCEED)\b' | tail -1 || true)
    [ -z "$_drift_action" ] && _drift_action="PROCEED"

    case "$_drift_action" in
      DONE)
        _drift_reason=$(echo "$DRIFT_VERDICT" | grep -i 'done' | head -1)
        echo "  ✓ Drift check: already done — $_drift_reason"
        echo "    → Moving to review/"
        move_file "$WORKING_DIR/$TASK_NAME" "$REVIEW_DIR/$TASK_NAME"
        COMPLETED=$((COMPLETED + 1))
        echo ""
        continue
        ;;
      FIXED)
        echo "  ⚠ Drift check: task was outdated — fixes applied."
        echo ""
        _updated_content=$(<"$WORKING_DIR/$TASK_NAME")
        _diff_output=$(diff --unified=2 <(echo "$TASK_CONTENT") <(echo "$_updated_content") || true)
        if [ -n "$_diff_output" ]; then
          echo "  Changes made to task file:"
          echo "$_diff_output" | head -40 | sed 's/^/    /'
          echo ""
        fi
        _drift_explanation=$(echo "$DRIFT_VERDICT" | sed '/^[[:space:]]*FIXED[[:space:]]*$/d' | tail -20)
        if [ -n "$_drift_explanation" ]; then
          echo "  AI reasoning:"
          echo "$_drift_explanation" | sed 's/^/    /'
          echo ""
        fi
        echo "  Updated task: $WORKING_DIR/$TASK_NAME"
        echo ""
        echo "  1) Looks good, work the task"
        echo "  2) Move to blocked for manual review"
        echo ""
        printf "  Choice [1/2] (auto-proceeds in 15s): "
        if read -r -t 15 _drift_choice </dev/tty 2>/dev/null; then :; else _drift_choice="1"; echo "1"; fi
        case "$_drift_choice" in
          2)
            echo "    → Moving to $BLOCKED_DIR/$TASK_NAME"
            move_file "$WORKING_DIR/$TASK_NAME" "$BLOCKED_DIR/$TASK_NAME"
            echo ""
            continue
            ;;
          *)
            echo "    → Proceeding with updated task"
            ;;
        esac
        ;;
      OUTDATED)
        _drift_reason=$(echo "$DRIFT_VERDICT" | grep -i 'outdated' | head -1)
        echo "  ✗ Drift check: outdated — $_drift_reason"
        echo "    → Moving to $BLOCKED_DIR/$TASK_NAME (needs human intervention)"
        move_file "$WORKING_DIR/$TASK_NAME" "$BLOCKED_DIR/$TASK_NAME"
        echo ""
        continue
        ;;
      *)
        echo "  ✓ Drift check: proceed"
        ;;
    esac
  fi

  # '|| _rc=$?' keeps set -e from killing the whole queue on a CLI error —
  # the result must reach _route_result so the task gets routed and reported.
  _rc=0
  _run_task "$TASK_NAME" 1 || _rc=$?
  _route_result "$TASK_NAME" "$_rc"

  TASK_ELAPSED=$((SECONDS - TASK_START))
  echo "⏱ Elapsed: $((TASK_ELAPSED / 60))m $((TASK_ELAPSED % 60))s"
  echo ""

  # Stop the queue on a genuine crash (non-zero exit with no turn cap).
  [ "$HARD_FAIL" -eq 1 ] && break
done

# Report anything never picked (dependency-held, or cap reached).
_undone=()
for ((i=0; i<${#TASK_FILES[@]}; i++)); do
  [ "${DONE_FLAG[$i]}" -eq 1 ] || _undone+=("${TASK_FILES[$i]}")
done
[ ${#_undone[@]} -gt 0 ] && _report_held "${_undone[@]}"

fi # end parallel/sequential branch

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# "skipped" = tasks left in next/ this pass (held on deps, or beyond the launch
# cap) = defined tasks minus those that executed. Uses the full defined set, not
# COUNT, so held dependents are counted even when the cap was not the limiter.
echo "▸ Done: $COMPLETED completed, $FAILED failed, $INCOMPLETE incomplete, $(( ${#TASK_FILES[@]} - COMPLETED - FAILED - INCOMPLETE )) skipped — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s"
# `if`, not `&&`: this is the script's last statement, and a false `[ ]` on a
# blocker-free run would become the script's non-zero exit status.
if [ "$BLOCKERS" -gt 0 ]; then
  echo "  ⚠ $BLOCKERS excellence blocker(s) recorded — inspect the '## Excellence' section in review/ before merging"
fi
