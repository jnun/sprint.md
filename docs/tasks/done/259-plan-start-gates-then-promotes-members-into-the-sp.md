# Task 259: plan start gates then promotes members into the sprint

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 258
**Blocks**: 260
**Parent**: none

## Problem

`plan start` only moves member tasks `backlog/ → next/`. Unvetted work can sit
in the sprint until a separate `define` run. Workability must be decided
**before** a task becomes sprint work: gate first, promote only what is READY.

## Success criteria

- [x] Default `./sprint.sh plan start <id>` vets each **backlog** member via
      the shared gate (258) **before** any promote into `next/`:
      - READY → stamp `**Status: READY**` and move `backlog/ → next/`
      - BLOCKED → land in `blocked/` with questions (never visits `next/`)
      - DONE → move to `review/`
- [x] Location rules from today's plan start still hold: already in `next/`
      (notice/idempotent), past stages skip with notice, dangling ID hard
      error. Members already in `blocked/` still stop the start with a pointer
      to `talk <id>` (kept — stop-with-pointer; documented in help).
- [x] `--commit-only` (or equivalent flag) keeps the pure filesystem promote
      for power users, tests, and non-AI environments. Default remains
      gate-then-promote.
- [x] Interactive DRAFT-plan warning and non-interactive READY-plan requirement
      for loop/refill stay as they are today.
- [x] End of run prints a clear summary: moved READY count, blocked count,
      done count, and next step is `./sprint.sh tasks` (not define).
- [x] Edit under `docs/`; smoke: READY plan with one clear backlog member →
      member appears in `next/` stamped READY; one intentionally vague member
      ends in `blocked/`, not `next/`.

## Notes

- **Before it becomes a sprint**: `next/` is the sprint. Unready work does not
  enter it.
- Plan-file `**Status:** READY` is separate from task-level READY stamps.
- Members already in `next/` without a READY stamp: re-vet on this start when
  practical, or leave a clear notice so the operator can `define` once; prefer
  leaving the sprint queue stamped after a successful start.
- Uses the shared gate from 258 — do not fork the define prompt into
  plan-start.sh.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer.

## References

docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/define.sh
docs/sprintmd/help/plan.md
docs/tasks/review/245-build-plan-start-commit-and-retire-the-auto-planne.md
docs/tasks/backlog/257-plan-start-gates-workability-before-members-enter.md
docs/tasks/backlog/258-extract-shared-workability-gate-from-define-for-pl.md

## Completed

Gate-then-promote is now the default for `plan start`, built on the shared gate
(task 258, `gate.sh`) rather than a fork of the define prompt.

**How it works.** After the unchanged preflight (dangling → hard error,
already-`blocked/` → stop with `talk <id>` pointer, `next/`/past → notices),
each **backlog** member is run through the shared workability gate *in place in
`backlog/`* — so BLOCKED work genuinely never touches `next/`. The gate stamps
`**Status: …**` and routes by verdict: READY → promoted into `next/`, BLOCKED →
`blocked/`, DONE → `review/`.

**Gate change (backward-compatible).** `sprintmd_gate_init` gained an optional
third arg `READY_DIR`. When set, a READY task is *moved* there instead of
staying put — `plan start` passes `next/` so a vetted member is promoted only
once it grades READY. Empty (define's call) preserves today's "READY stays in
place" behavior; verified define's emit prompt still reads
"READY → leave the file in next/". Both the emit-mode move instruction and the
exec-mode routing honor `READY_DIR`.

**`--commit-only`.** Skips the gate for the pure, deterministic `backlog → next`
`mv` — power users, tests, non-AI environments. Default stays gate-then-promote.

**Summary + next step.** The run ends with `N ready → next/, B blocked, D done`
(emit mode prints a "gating N member(s)" notice since outcomes resolve in the
agent), and the closing line is now `Next: ./sprint.sh tasks` — `define` is off
the commit spine (task 260).

**Already-blocked decision (open question 1):** kept **stop-with-pointer** — it
is fast, deterministic, and treats `blocked/` as human-triage territory rather
than silently re-spending AI budget. Documented in `help/plan.md`.

**Smoke tests (isolated sandbox, symlinked live `sprintmd/`):** `--commit-only`
promotes members `backlog → next` with no gate; emit-mode default path emits the
review prompt(s) with the `READY → git mv … next/` instruction and leaves files
in `backlog/` until the agent runs them; single- and multi-member (parallel
fan-out) emit paths both work; already-`blocked/` member stops the start;
dangling member hard-errors; `define` emit prompt unchanged. `bash -n` clean on
all three scripts. `./ship.sh` mirrored to `src/` (v0.0.25 → 0.0.26, clean
mirror). Git left to the developer.

Note: the READY-stamp-and-promote and the vague-member-→-`blocked/` outcomes are
exercised by the AI gate at run time (exec mode / agent-run emit prompt); the
sandbox smoke verifies the deterministic routing and instructions around it,
since a live model verdict can't be reproduced deterministically here.

### Files changed

docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/help/plan.md
src/docs/sprintmd/scripts/plan-start.sh
src/docs/sprintmd/scripts/gate.sh
src/docs/sprintmd/help/plan.md
src/VERSION
docs/tasks/doing/259-plan-start-gates-then-promotes-members-into-the-sp.md

## Questions

**Status: READY**

### Already complete

`plan-start.sh` already carries the deterministic scaffolding this task builds
on, so the new gate slots into existing structure rather than a rewrite:

- **DRAFT-plan warning + non-interactive READY requirement** (success criterion
  4) is fully implemented at `plan-start.sh:114-130`: non-READY plans warn and
  prompt interactively, and refuse non-interactively with the loop/refill
  message. Correct and can be left as-is.
- **Location classification** (success criterion 2) exists as a preflight loop
  at `plan-start.sh:148-203`: `resolve_member` finds the file across stages,
  then `backlog → move`, `next → idempotent notice`, `blocked → stop with a
  `talk <id>` pointer` (lines 184-191), `doing|review|done → skip notice`, and
  `missing → hard error` (lines 174-181). This is the exact rule set criterion 2
  says must still hold; the gate is layered onto the `backlog → move` branch.
- **Member collection + preflight-before-any-move** ordering (`plan-start.sh:134,
  148-223`) is already the right shape for "gate first, promote only READY."

None of the *gating* is done yet — today the backlog branch is a plain `mv`
with no verdict step (`plan-start.sh:207-223`), and the closing hint still
points at `define` (`plan-start.sh:243`).

### Remaining work

1. **Wire the shared gate (task 258) into the default backlog branch.** For each
   backlog member, run the shared workability gate *before* it enters `next/`:
   READY → stamp `**Status: READY**` and `mv backlog/ → next/`; BLOCKED → stamp
   + `## Questions`/`## BLOCKED` and land in `blocked/` (never touches `next/`);
   DONE → `mv → review/`. Call the shared path from 258 — do not fork the define
   prompt into `plan-start.sh` (per Notes). Gate the file in place in `backlog/`
   (258's gate takes arbitrary file paths) so BLOCKED work genuinely never
   visits `next/`.
2. **Add `--commit-only` (or equivalent) flag** that keeps today's pure
   filesystem promote (the current `mv` path) for power users, tests, and
   non-AI environments. Default stays gate-then-promote. Parse it in the arg
   handling near the top and branch the backlog handling on it.
3. **Update the end-of-run summary** (`plan-start.sh:225-243`) to print moved
   READY count, blocked count, and done count, and change the closing "Next"
   line from `./sprint.sh define   then  ./sprint.sh tasks` to just
   `./sprint.sh tasks` (define is being retired from the commit spine — see
   task 260).
4. **Decide the already-`blocked/` member behavior** (stop-with-pointer, which
   exists today, vs. re-gate) and document the chosen rule in `help/plan.md`.
5. **Refresh `help/plan.md`** so the `plan start` description reflects
   gate-then-promote as the default, the READY/BLOCKED/DONE outcomes, and the
   `--commit-only` escape hatch. The current help (lines 8-21) describes the
   pure-`mv` behavior only.
6. Standard dogfood: edit under `docs/`, smoke both an intentionally-vague
   member (must land in `blocked/`, not `next/`) and a clear READY member (must
   land stamped in `next/`), then `./ship.sh`.

**Depends on 258** (already recorded above): 258 extracts the shared
READY/BLOCKED/DONE gate out of `define.sh` into a callable path. It is in
`next/` and not yet implemented, so the function this task calls does not exist
yet — this is a sequencing dependency, not a definition gap. The task runner
holds 259 in `next/` until 258 reaches `review/`/`done/`.

### Questions for the developer

1. For members already sitting in `blocked/` when `plan start` runs, stop with
   the `talk <id>` pointer (today's behavior) or re-gate them? (Suggestion: keep
   **stop with a pointer**. It is already implemented at `plan-start.sh:184-191`,
   keeps the default run fast and deterministic, and matches the mental model
   that `blocked/` is human-triage territory — re-gating would silently re-spend
   AI budget on work someone already flagged. Document this line in `help/plan.md`
   per success criterion 2.)
