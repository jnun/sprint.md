# Task 289: Sweep product docs help template registry for plan DRAFT READY STARTED lifecycle

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 288
**Blocks**: 290
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Product docs and help still teach "binary DRAFT → READY only" and never
mention STARTED or `plan done`. Until every human- and agent-facing surface
tells the same story, the new scripts will not land safely.

## Success criteria

- [x] `docs/plans/.TEMPLATE-plan.md` teaches DRAFT | READY | STARTED and that
      retirement is delete via `plan done` (not a stored DONE; not NEXT)
- [x] Help updated: `plan.md` (think/start/**done**), `newplan.md`, `chat.md`
      (chat plan → READY only), `loop.md` / `work.md` as needed for READY vs STARTED
- [x] `_registry` plan-family summary mentions `plan done` if usage field allows
- [x] `DOCUMENTATION.md` plan section replaces "binary DRAFT → READY only" with
      full lifecycle; disambiguates plan Status from task folders and task READY
- [x] `README.md` and `GETSTARTED.md` (if they teach plans) match
- [x] `docs/guides/command-matrix.md` includes `plan done` and STARTED semantics
- [x] Live plans: plan 5 callout updated to new status prose (stays READY until
      start); plans 8/9 not rewritten as long-lived DONE stamps (retirement is #290)
- [x] No live product path claims plan Status is binary-only or uses NEXT as a
      plan status product value

## Notes

- STARTED ≠ members currently in `docs/tasks/next/`.
- Plan READY ≠ task `**Status: READY**` — one sentence of disambiguation in help/manual.
- Historical `docs/tasks/done/*` may keep old language; do not bulk-rewrite.
- Edit live `docs/` + root manuals; ship is #290.

## References

DOCUMENTATION.md  
README.md  
GETSTARTED.md  
docs/guides/command-matrix.md  
docs/sprintmd/help/plan.md  
docs/sprintmd/help/newplan.md  
docs/sprintmd/help/chat.md  
docs/plans/.TEMPLATE-plan.md  
docs/sprintmd/help/_registry  

## Questions

**Status: READY**

### Already complete

- **SC1 — template teaches the full lifecycle.** `docs/plans/.TEMPLATE-plan.md`
  already carries the callout: Status is `DRAFT | READY | STARTED` only, STARTED
  is a one-way switch set by `plan start`, and retirement is `./sprint.sh plan
  done <id>` deleting the file (never a stored DONE, never NEXT). Correct and clean.
- **SC7 — live plans already reworked.** Plans 5, 8, 9 all carry the new callout.
  Plan 5 stays `**Status:** READY`; plans 8 and 9 are `**Status:** STARTED` with a
  `<!-- Retire with: ./sprint.sh plan done N -->` comment, not rewritten as stored
  DONE stamps (retirement stays #290). Nothing to change here.
- **SC2 (partial) — chat/loop/work already READY-only.** `help/chat.md` sets
  `**Status:** DRAFT → READY` on confirm (never STARTED/DONE). `help/loop.md` and
  `help/work.md` already say `--refill` starts "the next READY plan," matching
  #288's loop-selects-READY behavior. No contradiction to fix; at most a one-line
  note that STARTED plans are not re-refilled.
- **SC8 (NEXT half) — clean.** No product path uses `NEXT` as a plan status value
  (the only `NEXT_DIR` hit is a shell variable in `plan-start.sh`). The remaining
  SC8 violation is the "binary" phrasing, covered by SC4 below.

### Remaining work

Doc/help/registry/matrix sweep only (no scripts, no ship — #288 owns the scripts,
#290 owns ship + tests). All edits under live `docs/` + root manuals:

1. **`DOCUMENTATION.md` line 82 (SC4/SC8):** replace "carries a binary
   `**Status:** DRAFT → READY` for authoring readiness only" with the full
   `DRAFT | READY | STARTED` lifecycle + `plan done` delete, and add the two
   disambiguation sentences already staged in the Notes: plan Status is not a task
   folder, and plan-level READY is not task-level `**Status: READY**`.
2. **`help/plan.md` (SC2):** document the `plan done` subcommand (delete when every
   member is in `done/`), add it to the bare-`plan` usage block so it lists
   `think`, `start`, `done`, and note that `plan start` latches `**Status:**
   STARTED`.
3. **`help/_registry` line 26 (SC3):** extend the `plan` row's usage-suffix/summary
   to surface `done` (e.g. `think/start/done [id]`) so the generated index and
   `validate --commands` stay in sync with the new dispatch.
4. **`docs/guides/command-matrix.md` (SC6):** add a `plan done` row to the plan
   section (~lines 88–95) and the numbered flow (~lines 152–154), and mention
   STARTED semantics.
5. **`help/newplan.md` (SC2, minor):** the "flip to READY" prose is fine; add a
   short pointer to the STARTED/`plan done` tail so newplan isn't the only surface
   still implying a two-state life.
6. **`README.md` / `GETSTARTED.md` (SC5, minor):** they teach plans lightly
   ("author / mark READY") and make no binary claim — a light touch to mention the
   full lifecycle keeps them consistent; not a blocker.

Because these pages describe behavior implemented by #288 (`plan done`, STARTED
latch, loop READY-only), keep #288 as the recorded dependency — write the docs to
match the behavior #288 lands.

### Questions for the developer

None — task is fully defined.

## Completed

Doc/help/registry/matrix sweep to teach the full plan lifecycle
`DRAFT | READY | STARTED` + `plan done` retirement. Scripts and ship are out of
scope (#288 owns scripts, #290 owns ship + tests).

- **SC1 (template)** — already correct on entry; `.TEMPLATE-plan.md` already
  teaches DRAFT | READY | STARTED and `plan done` deletion. No change.
- **SC2 (help)** — `help/plan.md`: header now "critique, commit, and retire";
  documented the `plan done` subcommand, added it to Usage + Family order, and
  noted `plan start` latches STARTED (one-way, not re-refilled). `help/newplan.md`:
  added the STARTED-latch + `plan done` tail. `help/chat.md`: already READY-only
  and points to `plan start` — correct as-is, no change. `loop.md`/`work.md`:
  already READY-only (verified); the STARTED-not-refilled note lives in plan.md.
- **SC3 (_registry)** — plan row usage-suffix now `think/start/done [id]` and the
  summary surfaces `done` + STARTED; matches the existing `plan.sh` dispatch
  (`done) run_sub plan-done.sh`) landed by #288, so `validate --commands` stays
  consistent.
- **SC4/SC8 (DOCUMENTATION.md)** — line 82 "binary `**Status:** DRAFT → READY`"
  replaced with the full `DRAFT | READY | STARTED` lifecycle + `plan done` delete
  and both disambiguation sentences (plan Status ≠ task folder; plan READY ≠ task
  `**Status: READY**`). Quick-reference block gains a `plan done` line and a
  STARTED note on `plan start`. Remaining `DRAFT → READY` hits (line 154,
  chat.md:79) describe chat's correct READY-only flip, not a binary claim.
- **SC5 (README/GETSTARTED)** — README plan snippet gains `plan start` STARTED
  note + a `plan done` line. GETSTARTED adds a paragraph on the plan's own
  DRAFT | READY | STARTED status and `plan done` retirement.
- **SC6 (command-matrix)** — plan section gains a `plan done` row and a paragraph
  on STARTED-as-one-way-latch + retirement-is-deletion.
- **SC7 (live plans)** — plans 5/8/9 already reworked on entry; no change.
- **SC8 (no binary/NEXT on live paths)** — verified via grep: no live product
  path claims binary-only status or uses NEXT as a plan status. Remaining
  `binary`/`DRAFT → READY only` hits are historical `docs/tasks/done/*`,
  `src/` (mirrored by #290's ship), or the #288/#289/#290/plan-10 tracking docs.

### Files changed
DOCUMENTATION.md
README.md
GETSTARTED.md
docs/guides/command-matrix.md
docs/sprintmd/help/plan.md
docs/sprintmd/help/newplan.md
docs/sprintmd/help/_registry
docs/tasks/doing/289-sweep-product-docs-help-template-registry-for-plan.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
