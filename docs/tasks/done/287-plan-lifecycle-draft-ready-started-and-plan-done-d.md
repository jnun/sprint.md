# Task 287: Plan lifecycle DRAFT READY STARTED and plan done delete with universal surface audit

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Superseded by **plan 10** (`docs/plans/10-plan-lifecycle-draft-ready-started-and-plan-done.md`).

This seed was split so the lifecycle can land in layers:

| Task | Scope |
|------|--------|
| **#288** | Scripts: `plan done`, STARTED stamp, loop READY-only |
| **#289** | Docs/help/template/registry/matrix/README/DOCUMENTATION |
| **#290** | Tests, ship, dogfood retire 8/9, universal grep audit |

Do **not** execute this task as a fourth member. Work #288 → #289 → #290 via
`./sprint.sh plan start 10`.

## Success criteria

- [x] Scope captured in plan 10 with decision locks and surface audit
- [x] Split into #288, #289, #290
- [ ] (N/A — implement via plan 10 members)

## Notes

Lifecycle locked:

```
newplan → DRAFT → chat plan → READY → plan start → STARTED → plan done → delete
```

STARTED is one-way. DONE is delete when every member is in `docs/tasks/done/`.

## References

docs/plans/10-plan-lifecycle-draft-ready-started-and-plan-done.md  
docs/tasks/backlog/288-implement-plan-done-audit-delete-and-plan-start-st.md  
docs/tasks/backlog/289-sweep-product-docs-help-template-registry-for-plan.md  
docs/tasks/backlog/290-test-ship-dogfood-plan-done-and-universal-plan-sta.md  
