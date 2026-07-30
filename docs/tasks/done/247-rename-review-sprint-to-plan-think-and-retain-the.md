# Task 247: rename review-sprint to plan think and retain the dual-persona plan review as a plan verb

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 243
**Blocks**: none
**Parent**: none

## Problem

`review-sprint` (`review-sprint.sh`) runs an automated dual-persona review
(Platform Architect + Experience Officer) of the queued sprint. Per the matrix
it is **retained but renamed** into the `plan` namespace as **`plan think`** — a
decisive plan verb beside `plan start` — dropping the "review-" discipline word
and the "sprint" command name. The dual-minded critical debate is the value and
is kept; what changes is the name and what it reviews: a **plan**, run in the
family order `talk plan` (author) → `plan think` (critique) → `plan start`
(commit), so the critique happens before a plan becomes the sprint.

## Success criteria

- [x] `plan think <id>` runs the automated dual-persona review (Platform
      Architect + Experience Officer) over plan `<id>` — its goal and ordered
      member tasks — and records the critique (per-member annotations + a
      plan-level analysis), the way `review-sprint` did for the queued sprint.
      It is **automated and decisive**, not conversational (authoring is
      `talk plan`).
- [x] It lives in the `plan` namespace beside `plan start` (dispatched via
      `plan think`, implemented in `plan.sh` or a `plan-think.sh` it calls);
      `review-sprint.sh` is renamed/folded accordingly.
- [x] It takes a *plan* ID, never a task ID (consistent with `talk plan` /
      `plan start`). Bare `plan think` picks a plan — the same picker affordance
      as `plan start`.
- [x] `review-sprint` is removed from all four surfaces (`_registry`, dispatch,
      help page, `DOCUMENTATION.md`) and `plan think` is added to all four;
      `./sprint.sh review-sprint` gets the unknown-command message;
      `./sprint.sh validate --commands` passes.
- [x] `./ship.sh --dry-run` clean; a fresh `./setup.sh` install runs
      `plan think <id>` end-to-end over a plan.

## Notes

- Retains the dual-persona logic wholesale; drops only the "review-" prefix and
  the "sprint" command word (matrix: both carry professions we don't want the
  agent to adopt). The critical internal debate is what earns its keep.
- Retargets from "the queued `next/` sprint" to "a plan file" — the plan is the
  authored artifact; critiquing it before `plan start` catches problems before
  they reach `next/`. Depends on the plan-file shape from 243.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  user.

### Implementation notes (2026-07-29)

- New `docs/sprintmd/scripts/plan-think.sh` (dual-persona, plan-scoped).
- `sprint.sh` `cmd_plan`: `think` → plan-think.sh; `start` → clear "not yet"
  until 245; other args → legacy auto-planner in plan.sh.
- Removed `review-sprint` from registry, dispatch, help, manual.
- Outputs: `## Plan Think` on member tasks; `docs/tmp/plan-think.md` with
  `PLAN THINK COMPLETE — N members annotated`.
- Config: `MODEL_PLAN_THINK` (falls back to `MODEL_REVIEW_SPRINT`).
- Cross-refs: talk-sprint, talk help, README, audit-tasks comment.
- Verified: emit path for plan 2 (13 members); `review-sprint` unknown;
  `validate --commands` / `--docs` green. Shipped v0.0.13.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/plan-think.sh
docs/sprintmd/help/plan.md
docs/sprintmd/scripts/plan.sh
docs/plans/.TEMPLATE-plan.md
docs/sprintmd/help/_registry
DOCUMENTATION.md

## Completed

### Files changed
docs/sprintmd/scripts/plan-think.sh
sprint.sh
docs/sprintmd/help/plan.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
docs/sprintmd/help/talk.md
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/scripts/audit-tasks.sh
docs/sprintmd/config
docs/guides/command-matrix.md
README.md
src/sprint.sh
src/DOCUMENTATION.md
src/docs/sprintmd/scripts/plan-think.sh
src/docs/sprintmd/help/plan.md
src/docs/sprintmd/help/_registry
src/docs/sprintmd/help/talk.md
src/docs/sprintmd/scripts/talk-sprint.sh
src/docs/sprintmd/scripts/audit-tasks.sh
src/docs/sprintmd/config
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
