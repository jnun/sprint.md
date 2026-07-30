# Task 290: Test ship dogfood plan done and universal plan-status surface audit

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 288 289
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Without tests, ship, dogfood, and a grep audit, the plan lifecycle can look
done in one script while README/help still teach binary DRAFT→READY, or
completed plans 8/9 can linger forever. This task is the landing gate for
plan 10.

## Success criteria

- [x] Test coverage (new or extended under `docs/tests/`): `plan start` stamps
      STARTED; `plan done` refuses when a member is not in `done/`; `plan done`
      deletes the plan when all members are in `done/`
- [x] `./ship.sh` clean mirror of framework changes into `src/`
- [x] Fresh-install or equivalent smoke: help lists `plan done`; create path
      still DRAFT
- [x] Dogfood on this repo: `./sprint.sh plan done 8` and `plan done 9` succeed
      (all members already in `done/`); plan 5 remains READY and is not deleted
- [x] Universal audit greps on live product paths (not `docs/tasks/done/`
      history) report zero unexplained hits for:
      - plan status taught as binary-only (`binary` + `DRAFT` + `READY` in plan context)
      - `**Status:** DONE` on files under `docs/plans/`
      - plan status token NEXT as a product value
- [x] `./sprint.sh status` no longer lists retired plans 8/9; plan 5 still rolls up
- [x] Paste a short audit checklist result into `## Completed` (pass/fail per row)

## Notes

### Universal audit checklist (run and record)

1. `./sprint.sh help plan` documents think, start, done  
2. Template status line is DRAFT | READY | STARTED only  
3. DOCUMENTATION + README + matrix agree with template  
4. `plan start` → STARTED on a throwaway or on dogfood path  
5. `plan done` fail path (member in review/backlog) exits non-zero  
6. `plan done` 8 and 9 delete those plan files  
7. Grep clean on live paths for stale binary-only / DONE plan status / NEXT  
8. `ship.sh` verify clean; src help/scripts match docs  

### Grep starters (adjust allowlists carefully)

```bash
# Live product paths only — exclude docs/tasks/done and this task's notes if needed
rg -n 'binary.*DRAFT|DRAFT → READY only|\*\*Status:\*\* DONE|Status:\*\* NEXT' \
  README.md DOCUMENTATION.md GETSTARTED.md \
  docs/guides docs/sprintmd docs/plans \
  sprint.sh --glob '!docs/tasks/**'
```

## References

docs/tests/  
ship.sh  
docs/plans/8-command-surface-remap-to-chat-work-gate-and-six-fa.md  
docs/plans/9-command-matrix-live-audit-and-dogfood.md  
docs/plans/5-grok-build-first-class-provider.md  
docs/tasks/backlog/287-plan-lifecycle-draft-ready-started-and-plan-done-d.md  

## Questions

**Status: READY**

### Already complete

Nothing in this task's own scope is done yet — that is expected, because it is
the landing gate that runs *after* its dependencies. The surrounding state is
in place and verified:

- **Test home exists.** `docs/tests/` already holds the test suite (e.g.
  `test-sprint.sh`, `test-validate-tasks.sh`, `test-no-stale-refs.sh`). New/extended
  coverage for `plan start`/`plan done` lands here. Note: `docs/tests/` is a
  dev-only tree — only `.TEMPLATE-test.md` ships (`ship.sh` line ~64), so these
  tests verify the framework but never reach users, which is correct.
- **`ship.sh` present** at repo root — the SC2 mirror step is available.
- **Dogfood preconditions hold.** Plans 8 and 9 are `**Status:** STARTED` and
  *every* listed member (#265–274, #277–285) is confirmed in `docs/tasks/done/`,
  so `plan done 8` / `plan done 9` will pass the all-members-in-`done/` audit once
  #288's `plan-done.sh` exists. Plan 5 is `**Status:** READY` with members still in
  `backlog/`, so it correctly stays un-deleted — the negative case in SC4.

### Remaining work

All of this task's scope is unstarted and unblocked by definition — it executes
once #288 (scripts) and #289 (docs) are in `review/`/`done/`:

1. **Tests** (SC1) under `docs/tests/`: `plan start` stamps STARTED; `plan done`
   exits non-zero when any member is outside `done/`; `plan done` deletes the plan
   when all members are in `done/`.
2. **`./ship.sh`** (SC2): clean mirror of #288/#289 framework changes into `src/`
   with byte-verify.
3. **Fresh-install smoke** (SC3): `help plan` lists `plan done`; create path still
   yields DRAFT.
4. **Dogfood** (SC4): `./sprint.sh plan done 8` and `plan done 9` succeed and
   delete those plan files; plan 5 remains READY and undeleted.
5. **Universal grep audit** (SC5) on live product paths only (exclude
   `docs/tasks/**` history): zero unexplained hits for binary-only plan-status
   language, `**Status:** DONE` under `docs/plans/`, and NEXT as a plan-status value.
6. **`./sprint.sh status`** (SC6): no longer lists retired plans 8/9; plan 5 still
   rolls up.
7. **Record results** (SC7): paste the 8-row audit checklist pass/fail into a
   `## Completed` section.

Note (minor, for the executor — not a blocker): plan 8's member list contains a
duplicate `#274`. #288's `plan-done.sh` dedups member IDs (`awk '!seen[$0]++'`,
mirroring `plan-start.sh:157`), so this is harmless — but if that dedup is ever
dropped, the `plan done 8` dogfood is where it would surface. Worth an assertion in
the SC1 test.

### Questions for the developer

None — task is fully defined. It is READY behind its recorded **Depends on: 288
289**; the runner holds it in `next/` until both reach `review/`/`done/`, then
runs it automatically.

## Completed

Landing gate for plan 10: tested, shipped, dogfooded, and audited the live plan
lifecycle (DRAFT → READY → STARTED → `plan done` deletes) that #288 implemented
and #289 documented.

**SC1 — tests.** New `docs/tests/test-plan-lifecycle.sh` (9 assertions, all
pass): `plan start --commit-only` flips READY → STARTED and promotes the member
into `next/` with exactly one `**Status:**` line (set-or-replace, not append);
`plan done` exits non-zero and leaves the plan intact when a member sits in
`review/`; `plan done` deletes the plan when every member is in `done/`; and a
member id listed twice is deduped to one required file (the plan-8 duplicate-#274
case) rather than demanding two. `docs/tests/` is dev-only — only
`.TEMPLATE-test.md` ships — so this verifies the framework without reaching users.

**SC2 — ship.** `./ship.sh` mirrored the #288/#289 framework changes into `src/`
(new `src/docs/sprintmd/scripts/plan-done.sh`, updated `plan-start.sh`, `plan.sh`,
`help/plan.md`, `_registry`, `newplan.md`, `DOCUMENTATION.md`, `GETSTARTED.md`,
`.TEMPLATE-plan.md`, plus this task's `chat-plan.sh` fix). Verify reported
"src/ is a clean mirror of the live tree"; version 0.0.37 → 0.0.39.

**SC3 — smoke.** `./sprint.sh help plan` lists `plan think | start | done`; the
create path (`.TEMPLATE-plan.md`, both trees) still stamps `**Status:** DRAFT`;
`src/docs/sprintmd/scripts/plan-done.sh` present.

**SC4 — dogfood.** `./sprint.sh plan done 8` and `plan done 9` both exited 0 and
removed those plan files (all members #265–274 / #277–285 confirmed in `done/`
first). Plan 5 stayed `**Status:** READY` and undeleted; plan-8's duplicate #274
deduped harmlessly. Deletions are staged via `git rm` — commit left to the
developer.

**SC5 — universal audit.** One real hit fixed: `chat-plan.sh` called the plan
Status "binary" — stale under the three-value lifecycle. Reworded to "authoring
writes only the first two of the plan's three statuses … STARTED is latched later
by plan start." Post-fix, live product paths are clean; the only remaining matches
are the plan-10 tracking doc (describes the problem/rules by design) and
`DOCUMENTATION.md:82` correctly negating them ("no stored DONE and no NEXT plan
status").

**SC6 — status.** `./sprint.sh status` no longer lists plans 8/9; plans 10 (2/3)
and 5 (0/6) still roll up.

### Audit checklist (SC7)

1. help plan documents think/start/done — **PASS**
2. Template status line is DRAFT | READY | STARTED only — **PASS**
3. DOCUMENTATION + README + matrix agree with template — **PASS** (matrix has
   `plan done` row + STARTED-latch prose; DOCUMENTATION.md:82 full lifecycle)
4. `plan start` → STARTED (throwaway + dogfood) — **PASS**
5. `plan done` fail path (member in review/) exits non-zero — **PASS**
6. `plan done` 8 and 9 delete those plan files — **PASS**
7. Grep clean on live paths (binary-only / stored DONE / NEXT) — **PASS**
   (after the `chat-plan.sh` fix; plan-10 tracking doc excluded by design)
8. `ship.sh` verify clean; src matches docs — **PASS**

### Files changed

docs/tests/test-plan-lifecycle.sh
docs/sprintmd/scripts/chat-plan.sh
src/docs/sprintmd/scripts/chat-plan.sh
docs/plans/8-command-surface-remap-to-chat-work-gate-and-six-fa.md
docs/plans/9-command-matrix-live-audit-and-dogfood.md
docs/tasks/doing/290-test-ship-dogfood-plan-done-and-universal-plan-sta.md

Note: `./ship.sh` (SC2) also mirrored the already-live #288/#289 docs edits and
bumped `src/VERSION`; those `src/docs/sprintmd/**` paths change as a mechanical
whole-tree mirror, not as content authored by this task.

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
