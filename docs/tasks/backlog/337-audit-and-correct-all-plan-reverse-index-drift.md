# Task 337: Audit and correct all Plan reverse-index drift

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 16
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

Each task file carries a **Plan** field that should mirror the plan file's
member list — the plan file (`docs/plans/N-…`) is the authority, and the task
field is a reverse index so a reader sees a task's plan without opening every
plan. Right now 23 active tasks read `Plan: none` while their plan files list
them as members. A reader of the task can't tell which plan it belongs to, and
`./sprint.sh validate` exits non-zero on the drift — real integrity failures
end up buried under drift noise. Reconcile every task's **Plan** field to its
plan file, and record why the drift happened so it does not silently return.

## Success criteria

- [ ] `./sprint.sh validate` prints no "Plan reverse-index drift" section and reports 0 drift
- [ ] Each of the 23 tasks listed in Notes carries the correct **Plan** field matching its plan file
- [ ] Notes records the root cause and when a re-run of `validate --fix` is needed, so the drift does not silently recur

## Notes

The fix already exists: `./sprint.sh validate --fix` rewrites each task's
**Plan** field to the primary (lowest-numbered) plan whose member list contains
it, in one pass. `done/` tasks are skipped (they migrate on next touch). Run it,
then run a plain `./sprint.sh validate` to confirm 0 drift.

Root cause: these members were added to plan files before their reverse **Plan**
field was stamped — older plans predate `create-plan.sh` stamping members on
creation, and any member added by hand-editing a plan's "Member tasks" list
still needs a `validate --fix` afterward. `create-plan.sh` now stamps members at
creation, so new plans start clean; the gap is hand-edits to an existing plan.

Drift snapshot as of 2026-08-03 (authoritative list is `./sprint.sh validate`),
grouped by the plan that should own each task:

Plan 11 (grok firm-up model, cli, dual smoke): 291, 292, 293, 294, 295, 296, 297, 298
Plan 12 (simplify setup): 306, 307
Plan 13 (autolearning): 313, 314, 315, 316, 317, 324, 325, 326
Plan 14 (SprintBias visibility): 318, 319, 320, 321, 322

## References

docs/sprintbias/scripts/validate-tasks.sh
docs/sprintbias/lib.sh
docs/sprintbias/scripts/create-plan.sh
docs/plans/11-grok-firm-up-model-cli-and-dual-smoke.md
docs/plans/12-simplify-setup.md
docs/plans/13-autolearning.md
docs/plans/14-sprint-md-visibility.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
