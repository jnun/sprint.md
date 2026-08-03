# Task 330: Upgrade work completion path outcome stamps and missing-prereq class

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 327, 328
**Dependents**: 332, 333
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 1

## Problem

`work` already stage-classifies open prereqs (doing resume; backlog/blocked →
chat). Gaps remain: a missing prereq id is treated as complete (false green);
a failed or incomplete prereq leaves no durable stamp; hold lines do not ask
“was this folded?” Failures in doing/ look like mystery holds, not diagnosable
outcomes. Stress should leave clearer stamps, not quieter failures.

## Success criteria

- [x] Missing prereq ids classified via #328 (broken vs archived-complete vs
      folded-into-N) — no silent false green
- [x] On route to blocked/ or hard fail, work writes durable **Outcome**:
      ```
      ## Outcome
      **Result**: incomplete | failed | blocked
      **Reason**: …
      **At**: YYYY-MM-DD
      ```
- [x] Hold/report lines for dependents mention that outcome
      (e.g. `needs: 294 (blocked/ — incomplete: budget) — chat 294`)
- [x] doing/ resume remains: `## Completed` → review/; else re-run; loop orphan
      recovery stays compatible
- [x] Backlog prereqs never auto-promote; message stays
      `Consider: ./sprint.sh chat <id>`

## Notes

- Extend the existing work prepass; do not replace it.
- v1: stamp the failed prereq + surface in messaging; do not rewrite every
  dependent file on each failure.
- **Dependents** (legacy **Blocks**) is how we find who to mention in reports.

## References

docs/sprintmd/scripts/work.sh
docs/sprintmd/help/work.md
docs/sprintmd/lib.sh
docs/sprintmd/scripts/loop.sh
docs/tests/fixtures/dep-glitch-matrix/MATRIX.md
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Completed

Extended `work`'s existing prepass and completion router (did not replace them)
to make failure legible instead of quiet:

- **Missing-id classification (no silent green).** New `_scan_broken_deps_from`
  runs over every queued task and classifies each declared **Depends on** id via
  #328's `sprintmd_classify_dep`. A `missing` id is reported as a broken
  reference; a `folded` id is reported as "folded into N — update **Depends
  on**" (fold target via `sprintmd_fold_target`). Archived-complete (review/
  done) ids stay quiet. The gate (`sprintmd_unmet_deps`) is left untouched so a
  stale ref still can't wedge the queue — the pass surfaces, it doesn't hold.
- **Durable `## Outcome` stamps.** New `_stamp_outcome FILE RESULT REASON`
  (with `_strip_outcome`) writes the plan-15 §5 block. Wired into
  `_route_result`: incomplete → blocked/ stamps `incomplete`; hard fail (left in
  doing/) stamps `failed` before loop's orphan sweep moves it to blocked/. Drift
  routes to blocked/ (OUTDATED, manual-review choice) stamp `blocked`. A task
  that later completes drops any stale stamp on the way to review/. Emit-mode
  prompts (orchestrator + sequential fallback) now instruct the surrounding
  agent to write the same block before moving to blocked/, so behavior can't
  drift between exec and emit.
- **Hold lines name the outcome.** `_format_dep` now reads a dep's `## Outcome`
  via `_outcome_brief` and renders `294 (blocked/ — incomplete: budget) — chat
  294` and `9007 (doing/ — failed: …)`, matching MATRIX rows 177/178 and the
  fixture stamps on board tasks 9007/9032. The missing branch classifies via
  #328 instead of the old "treated complete" line.
- **Unchanged invariants.** doing/ resume (`## Completed` → review/, else
  re-run) and loop orphan recovery are untouched; the Outcome stamp only rides
  along on the doing/ file loop already sweeps. Backlog prereqs still surface
  `Consider: ./sprint.sh chat <id>` with no auto-promote.

Verified with isolated sandbox boards and against the real dep-glitch-matrix
fixtures: `_format_dep` renders the MATRIX-expected doing/failed and
blocked/incomplete lines; the scan classifies a missing id as broken and a
fold-marked id as folded-into-N while leaving existing deps out of the broken
list; `_stamp_outcome` is idempotent (replaces a prior block) and
`_strip_outcome` clears it. `bash -n` clean.

Not shipped: `./ship.sh` mirrors the whole `docs/sprintmd/` tree and would pull
sibling plan-15 tasks' unshipped edits (lib.sh, chat.sh, split.sh, …) into
`src/` under one version bump — that batch mirror is the developer's call, not
this task's scope.

### Files changed
docs/sprintmd/scripts/work.sh
docs/sprintmd/help/work.md

## Rework (round 1)

**Why:** The task's own invariant — "a task that later completes drops any
stale stamp on the way to review/" — is enforced only on the success route
(`work.sh:978` calls `_strip_outcome` before moving to review/). The drift
`COMPLETE` branch (`work.sh:1271-1281`) is a second completion route to review/
and it moves the file without stripping. A task stopped short → blocked/ with
`## Outcome: incomplete`, re-promoted (nothing on the blocked→next promote path
strips the stamp), then re-worked with `--drift` where drift concludes
`COMPLETE`, lands in review/ carrying a stale failure stamp — a success wearing
a failure `## Outcome`, the exact inversion of this task's "make failure
legible" thesis. One-line gap, a direct mirror of the existing `work.sh:978`
call.

**Improve:**
- [ ] In the drift `COMPLETE` branch (`work.sh` ~line 1275, before the
      `move_file "$WORKING_DIR/$TASK_NAME" "$REVIEW_DIR/$TASK_NAME"`), add
      `_strip_outcome "$WORKING_DIR/$TASK_NAME"` so a task drift decides is
      already complete drops any stale `## Outcome` stamp on its way to review/,
      matching the success route at `work.sh:978`.
- [ ] Confirm no other route into review/ carries a stale stamp: the FIXED
      →proceed path (falls through to normal work → success route strips) and
      FIXED→blocked / OUTDATED paths (re-stamp via `_stamp_outcome`, which is
      idempotent) are already covered — verify the `COMPLETE` branch was the
      only miss.

## Questions

**Status: READY**

### Already complete

All five original success criteria are implemented and verified in the current
code — this is quality, not incomplete work:

- **Missing-id classification (no silent green).** `_scan_broken_deps_from`
  (`work.sh` ~468-508) classifies each declared **Depends on** id via #328's
  `sprintmd_classify_dep`, reporting `missing` as broken and `folded` as
  "folded into N" (target via `sprintmd_fold_target`); archived-complete ids
  stay quiet. The gate is left untouched, so the pass surfaces without wedging
  the queue.
- **Durable `## Outcome` stamps.** `_stamp_outcome` / `_strip_outcome`
  (`work.sh:193-215`) write the plan-15 §5 block and are idempotent (strip runs
  before every stamp). Wired into `_route_result`: incomplete → blocked/ stamps
  `incomplete` (988); hard fail stamps `failed` in doing/ (998); drift OUTDATED
  and FIXED→blocked stamp `blocked` (1323, 1308). Success route strips a stale
  stamp before review/ (978).
- **Hold lines name the outcome.** `_outcome_brief` (`work.sh:220`) + `_format_dep`
  render `294 (blocked/ — incomplete: budget)` style lines.
- **doing/ resume and loop orphan recovery** remain intact; backlog prereqs
  still surface `Consider: ./sprint.sh chat <id>` with no auto-promote.

Implementation is clean, idempotent, and matches the fixture expectations noted
in the ## Completed log.

### Remaining work

Scope for the sprint is Rework round 1 — closing the stale-stamp gap on the
non-success routes into review/:

1. **Drift `COMPLETE` branch (checkbox 1).** Add
   `_strip_outcome "$WORKING_DIR/$TASK_NAME"` immediately before the `move_file`
   at `work.sh:1275`, mirroring the success route at `work.sh:978`. Confirmed
   not yet applied: line 1275 moves straight to review/ with no strip, so a task
   re-promoted from blocked/ (carrying `## Outcome: incomplete`) that drift later
   judges `COMPLETE` lands in review/ wearing a stale failure stamp.
2. **Audit remaining review/ routes (checkbox 2).** The FIXED→proceed path falls
   through to the success route (strips) and FIXED→blocked / OUTDATED re-stamp
   idempotently — both covered. One additional route to check: the
   prereq-resume path at `work.sh:521` moves a `## Completed` prereq to review/
   without stripping (see question 1).

Not shipped by design — `./ship.sh` mirrors the whole `docs/sprintmd/` tree and
would batch in sibling plan-15 edits; that mirror is the developer's call.

### Questions for the developer

1. Should the prereq-resume route at `work.sh:521` also call `_strip_outcome`
   before moving a `## Completed` prereq to review/? (Suggestion: yes, add the
   same one-line strip. It is the same class of gap the rework identified — a
   `## Completed` file re-worked from blocked/ could still carry a stale
   `## Outcome`, and this path moves it to review/ without clearing it, unlike
   the success route at 978. It is a one-line mirror and satisfies the intent of
   checkbox 2. If the developer judges the scenario impossible for prereqs, it
   can be left as-is with a note — but it is worth an explicit verification since
   checkbox 2 asks to confirm the drift branch was the *only* miss.)
