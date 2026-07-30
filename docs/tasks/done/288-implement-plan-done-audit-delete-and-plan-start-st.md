# Task 288: Implement plan done audit-delete and plan start STARTED stamp

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: 289 290
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Plan files only support authoring status (DRAFT/READY). After `plan start`,
nothing records that the plan has been switched on, and nothing can
deterministically retire a plan when every member is in `docs/tasks/done/`.
Hand-stamped DONE on plan files is wrong. Scripts must implement the live
lifecycle: DRAFT → READY → STARTED (one-way) → plan done deletes the file.

## Success criteria

- [x] `./sprint.sh plan done [id]` runs pure shell (no AI): for each member ID,
      require `docs/tasks/done/<id>-*.md`; missing or any other folder → FAIL
      report and exit 1 without deleting
- [x] On full pass, member lines normalized to `- [x] #id — …`, then plan file
      removed with `git rm || rm`
- [x] `plan start` sets `**Status:** STARTED` after a successful start (one-way;
      does not change again as members leave `next/`)
- [x] `plan.sh` dispatches `done`; bare `plan` / help lists `think`, `start`, `done`
- [x] `loop --refill` still selects only plans with `**Status:** READY` (not
      STARTED, not DRAFT)
- [x] `create-plan` / template path still creates `DRAFT`; `chat-plan` may only
      set READY (never STARTED/DONE/NEXT)
- [x] Plan status tokens in code paths are only DRAFT | READY | STARTED; no
      NEXT; no stored DONE

## Notes

- Member complete for sign-off = **`done/` only** (not `review/`). Missing file = fail.
- STARTED is a latch, not "all files currently in `next/`".
- DONE on a plan is delete, never a written status.
- Shared helper for parsing member IDs is fine (`^- (\[[ xX]\] )?#[0-9]+`).
- Edit `docs/sprintmd/` then later task ships via `./ship.sh`.

## References

docs/sprintmd/scripts/plan.sh  
docs/sprintmd/scripts/plan-start.sh  
docs/sprintmd/scripts/loop.sh  
docs/sprintmd/scripts/chat-plan.sh  
docs/sprintmd/scripts/create-plan.sh  
docs/tasks/backlog/287-plan-lifecycle-draft-ready-started-and-plan-done-d.md  

## Questions

**Status: READY**

### Already complete

- **SC5 — `loop --refill` starts only READY plans.** `loop.sh` `next_ready_plan()`
  (lines 150–166) skips any plan whose `**Status:**` is not exactly `READY`, so
  STARTED and DRAFT plans are never auto-started. Clean and correct.
- **SC6 (template/create-plan side) — DRAFT on creation.** `.TEMPLATE-plan.md`
  ships `**Status:** DRAFT` and already documents the full `DRAFT | READY |
  STARTED` lifecycle plus `plan done` delete. `create-plan.sh` copies the
  template verbatim, so new plans are DRAFT.
- **SC6 (chat side) — chat-plan sets only READY.** `chat-plan.sh`'s prompt flips
  `**Status:**` to READY on confirmation and DRAFT otherwise; it is instructed
  "Never invent other status values." No STARTED/DONE/NEXT path.
- **SC7 (partial) — no NEXT / stored DONE.** Grep confirms no `Status: NEXT` or
  `Status: DONE` token in any plan script. The only missing token is STARTED,
  which SC3 adds.

### Remaining work

1. **New `plan-done.sh`** (pure shell, no AI): resolve the plan file, parse
   member IDs with the shared `^- (\[[ xX]\] )?#[0-9]+` pattern (already used at
   `plan-start.sh:157`), and require `docs/tasks/done/<id>-*.md` for **every**
   member. Any member missing or in a non-`done/` folder → print a FAIL report
   and `exit 1` without touching the plan. On full pass, normalize each member
   line to `- [x] #id — …` and delete the plan file with `move_file`/`git rm ||
   rm`. (SC1, SC2)
2. **STARTED latch in `plan-start.sh`** (SC3): after a successful start, write
   `**Status:** STARTED` once. It is a one-way latch — set it regardless of how
   many members are still in `next/`, and never revert it. Decide placement so
   it fires on both the gated and `--commit-only` paths (see Q1).
3. **Dispatch + usage in `plan.sh`** (SC4): add a `done)` case routing to
   `plan-done.sh`, and add `plan done` to the `usage()` block so bare `plan` /
   `plan help` list `think`, `start`, `done`.

Docs/help/registry/matrix updates and tests/ship are explicitly out of scope
here — they are #289 and #290 (which this task **Blocks**). Edit under
`docs/sprintmd/`; #290 runs `./ship.sh`.

### Questions for the developer

1. Should `plan start` stamp STARTED on the `--commit-only` path too, and when a
   run promotes zero backlog members (all already in next/ or past)? (Suggestion:
   yes to both — STARTED is a latch meaning "this plan has been committed to the
   sprint," not "members moved this run." Stamp it whenever `plan start` reaches
   a successful exit for a resolved plan, including `--commit-only` and idempotent
   re-runs. This keeps the one-way semantic simple and matches loop `--refill`,
   which calls the gated path.)
2. When a plan is already STARTED and `plan start` is re-run, do anything special?
   (Suggestion: no — re-stamping STARTED is idempotent and harmless; just ensure
   the write is a set-or-replace of the `**Status:**` line, not an append, so
   repeated runs don't accumulate duplicate status lines.)

## Completed

Implemented the live plan lifecycle DRAFT → READY → STARTED (one-way) → `plan
done` deletes the file.

1. **New `plan-done.sh`** (pure shell, no AI). Resolves the plan, parses member
   IDs with the shared `^- (\[[ xX]\] )?#[0-9]+` pattern, and requires
   `docs/tasks/done/<id>-*.md` for **every** member. Any member missing or in a
   non-`done/` folder → prints a per-member FAIL report (naming the folder it's
   actually in, or "no task file found") and `exit 1` without touching the plan.
   On a full pass it ticks every member line to `- [x] #id — …` (portable
   `sed_inplace -E`, handles a missing or unticked box alike, preserves title
   text), then deletes the file with `git rm -q || rm -f` — DONE on a plan is a
   delete, never a stored status. Dispatched via `run_sub`; marked executable.
   (SC1, SC2)

2. **STARTED latch in `plan-start.sh`** — added `stamp_started()` (set-or-replace
   of the single `**Status:**` line; malformed no-status plans get one appended)
   and call it on every successful exit, before the summary/exports. Fires on the
   gated, emit, `--commit-only`, and idempotent re-run paths (Q1: yes to both);
   re-running is a replace, never an append, so no duplicate status lines (Q2).
   It never reverts as members flow through `next/doing/review/done`. (SC3)

3. **Dispatch + usage in `plan.sh`** — added the `done)` case and a
   `plan done [id]` line to the header comment and `usage()` block, so bare
   `plan` / `plan help` list `think`, `start`, `done`. (SC4)

**Already correct, verified unchanged:** SC5 — `loop.sh` `next_ready_plan()`
selects only exact-`READY` plans (STARTED/DRAFT skipped). SC6 —
`.TEMPLATE-plan.md` + `create-plan.sh` create `DRAFT`; `chat-plan.sh` only ever
writes DRAFT/READY. SC7 — grep confirms plan scripts reference only DRAFT |
READY | STARTED; no NEXT, no stored plan DONE. (The `Status: DONE` in
`gate-lib.sh` is a *task* stamp, not a plan status — out of scope.)

Tested in place: bare `plan` usage lists the three verbs; `plan done` FAILs and
leaves the plan intact when a member sits in `review/`; passes (normalize +
delete) once all members are in `done/`; `plan start` on a READY plan stamps
STARTED and a re-run stays a single STARTED line. Docs/help/registry/matrix and
`./ship.sh` are out of scope here (#289, #290).

### Files changed

docs/sprintmd/scripts/plan-done.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/plan.sh
docs/tasks/doing/288-implement-plan-done-audit-delete-and-plan-start-st.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
