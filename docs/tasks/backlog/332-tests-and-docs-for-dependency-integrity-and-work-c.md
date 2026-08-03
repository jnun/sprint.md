# Task 332: Suite tests and docs for dependency integrity and completion path

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/guides/running-tests.md
**Plan**: 15
**Depends on**: 327, 328, 329, 330, 331, 333
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Without hard asserts, fold rewrite and stage classification regress quietly.
Without manual language locked in DOCUMENTATION/help, agents invent fields or
forget **Plan** / **Tests**. This task locks the contract in the platform suite
and user-facing docs so stress fails loud.

## Success criteria

- [ ] Fixture tests cover: reciprocal edge ensure, fold A→B rewrite, missing vs
      archived class, work hold messaging (backlog/blocked/doing), Outcome
      stamp on incomplete route, Plan field drift warning, **Tests**/**Proven by**
      alias on promote
- [ ] DOCUMENTATION.md + help (work/chat/validate/promote/newtask) describe:
      Depends on, Dependents, Plan, Tests, fold protocol, backlog never
      auto-promotes, Docs vs Tests
- [ ] `bash docs/tests/run-all.sh` and `validate --commands` green after help
      changes
- [ ] Plan 15 member checklist updated; decisions remain locked (no reopen)

## Notes

- Start from `docs/tests/fixtures/dep-glitch-matrix/` (MATRIX, seed,
  check-inventory false-green detector). Promote diagnostics into
  `docs/tests/test-dep-*.sh` and discover via run-all.
- Guide for agents: `docs/guides/running-tests.md`.
- After `test-dep-*.sh` exists and is green, set this task’s **Tests** to that
  path so promote can close it.
- No live AI required for these asserts.

## References

docs/tests/
docs/tests/run-all.sh
docs/tests/fixtures/dep-glitch-matrix/
docs/guides/running-tests.md
docs/sprintmd/help/work.md
docs/sprintmd/help/chat.md
docs/sprintmd/help/validate.md
docs/sprintmd/help/promote.md
DOCUMENTATION.md
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Questions

**Status: READY**
