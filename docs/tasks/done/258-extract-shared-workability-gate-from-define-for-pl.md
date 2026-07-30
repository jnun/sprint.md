# Task 258: extract shared workability gate from define for plan start

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 246
**Blocks**: 259
**Parent**: none

## Problem

The READY/BLOCKED/DONE workability gate lives only inside `define.sh` (next/
mode). `plan start` needs the same gate *before* promoting members into the
sprint, and both surfaces must share one implementation so verdicts, questions,
and dependency-vs-definition rules never drift. Today there is nothing reusable
to call from `plan-start.sh`.

## Success criteria

- [x] A shared gate path exists (library function, sourced helper, or thin
      script) that takes one or more task file paths, runs the current define
      READY-gate logic (verdict, `## Questions`, stamp, dependency rules), and
      returns/applies READY, BLOCKED, or DONE per task.
- [x] `define.sh` next/ mode calls that shared path instead of inlining a
      second copy of the gate. Folder-report mode (backlog/doing/blocked) is
      unchanged.
- [x] Behavior of bare `./sprint.sh define` on `next/` matches pre-change
      verdicts and moves for the same inputs (READY stays/stamped, BLOCKED →
      blocked/, DONE → review/). Verifiable by a quick smoke on a fixture or
      existing next/ task with `--force` if needed.
- [x] Edit lives under `docs/`; `./ship.sh --dry-run` clean after the change.

## Notes

- Prefer extract-and-call over rewrite: lift what `define.sh` already does for
  next/, keep prompts and `sprintmd_review_verdict` conventions.
- Plan start is not wired in this task — that is 259. This task only makes the
  gate callable without going through the full `define` CLI entrypoint.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer.

## References

docs/sprintmd/scripts/define.sh
docs/sprintmd/lib.sh
docs/sprintmd/help/define.md
docs/tasks/review/246-define-absorbs-audit-vet-task-quality-on-any-folde.md
docs/tasks/backlog/257-plan-start-gates-workability-before-members-enter.md

## Questions

**Status: READY**

### Already complete

Nothing is extracted yet. The READY-gate is still fully inlined in
`define.sh` (the entire "READY-gate mode (next/)" block, lines ~181–647):
the per-task review loop, the `_review_contract()` prompt builder, the
`_sprint_index`/`_SPRINT_BLOCK` context, emit vs. exec dispatch, the
claude-code parallel-subagent fast path, and the verdict routing
(BLOCKED → `blocked/`, DONE → `review/`, READY stays). `lib.sh` exposes
only `sprintmd_review_verdict` (the stamp reader at lib.sh:332) — there
is no shared function or helper that *runs* the gate. So there is no
reusable path for `plan-start.sh` to call today, exactly as the Problem
states.

The dependency (246, which created this gate) is in `done/`, so the code
being extracted is present and stable.

### Remaining work

Lift the next/ READY-gate out of `define.sh` into a shared, callable path
(library function in `lib.sh`, a sourced helper, or a thin script — the
task explicitly leaves the mechanism to the implementer) that accepts one
or more task-file paths and, per task, runs the current review contract,
writes the `## Questions` section + stamp, applies the dependency-vs-
definition rules, and returns/applies READY, BLOCKED, or DONE. Then have
`define.sh` next/ mode call that shared path instead of holding a second
copy. Keep folder-report mode (backlog/doing/blocked) and the CLI
orchestration that stays define-specific (arg parsing, run summary, talk
queue) untouched. Preserve the existing prompts and
`sprintmd_review_verdict` conventions — extract-and-call, not rewrite.

Then verify: bare `./sprint.sh define` on `next/` produces the same
verdicts and moves as before (READY stays/stamped, BLOCKED → `blocked/`,
DONE → `review/`) on a fixture or an existing next/ task (use `--force`),
and `./ship.sh --dry-run` is clean. `plan-start.sh` is intentionally NOT
wired here — that is task 259.

### Questions for the developer

None — task is fully defined.

## Completed

Extracted the next/ READY-gate out of `define.sh` into a new sourced helper
`docs/sprintmd/scripts/gate.sh` — the shared workability gate. Extract-and-call,
not rewrite: the review contract, sprint/backlog index builder, emit-mode move
instruction, claude-code parallel fast path, and the exec-mode run + verdict
routing (BLOCKED → `blocked/`, DONE → `review/`, READY stays) were lifted
verbatim, keeping the existing prompt text and `sprintmd_review_verdict`
convention.

**The shared gate (`gate.sh`), sourced-only (no registry/dispatch/help — so
`check-commands.sh` doesn't flag it; `ship.sh` mirrors it into `src/`
automatically as a new file under the `docs/sprintmd/` tree):**

- `sprintmd_gate_init [KIND] [STAY_DIR]` — builds the task-independent context
  once (model/tool surface, profile pointer, next/backlog index, emit move
  instruction). `STAY_DIR` is where a READY task stays (define passes `next/`);
  `KIND` names the log file.
- `sprintmd_gate_contract FILE` — the invariant review contract prompt.
- `sprintmd_gate_parallel FILE...` — the emit-mode claude-code parallel fan-out.
- `sprintmd_gate_review FILE` — runs the gate on one task in the current AI mode
  and, in exec mode, applies the verdict + move + `## BLOCKED` synthesis. Reports
  the outcome via `SPRINTMD_GATE_VERDICT` (READY|BLOCKED|DONE|EMIT|NOSTAMP|
  FAILED), `SPRINTMD_GATE_LOG`, and `SPRINTMD_GATE_ERROR`.

**`define.sh`** now sources `gate.sh`, calls `sprintmd_gate_init define
"$NEXT_DIR"` once, dispatches the parallel path via `sprintmd_gate_parallel`, and
in the per-task loop calls `sprintmd_gate_review` then maps the returned verdict
to its own screen output / counts / talk-queue. The define-specific orchestration
(arg parsing, skip-already-reviewed, run summary, `_talk_queue`) is untouched, and
the folder-report mode (backlog/doing/blocked) is entirely unchanged. `plan
start` is intentionally NOT wired — that is task 259; the gate is now callable
without going through the `define` CLI entrypoint.

**Verification:**

- `bash -n` clean on both scripts; `shellcheck -x` shows only pre-existing
  info-level notices (SC1091 dynamic source paths, SC2012 on an unchanged line).
  The `SPRINTMD_GATE_*` output vars carry a function-level `SC2034` disable,
  matching `lib.sh`'s output-var convention.
- Deterministic routing smoke (stubbed AI runner, temp dirs — no real task files
  touched) confirmed all five paths: READY stays in place, BLOCKED → `blocked/`
  with a synthesized `## BLOCKED` section, DONE → `review/`, missing stamp →
  NOSTAMP (file stays), review error → FAILED with the cause captured.
- `./ship.sh --dry-run` clean; ran `./ship.sh` — `src/` verified as a clean
  mirror, version 0.0.24 → 0.0.25. Git left to the developer.

### Files changed

docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/define.sh
src/docs/sprintmd/scripts/gate.sh
src/docs/sprintmd/scripts/define.sh
src/VERSION
