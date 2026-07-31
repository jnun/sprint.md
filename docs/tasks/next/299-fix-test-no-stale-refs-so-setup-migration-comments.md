# Task 299: Fix test-no-stale-refs so setup migration comments for retired MODEL_TALK keys do not fail the suite

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: 302
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

`docs/tests/test-no-stale-refs.sh` fails the full suite even when the product is
healthy. It greps for retired names like `MODEL_TALK` / `BUDGET_TASKS` and hits
**intentional migration comments** in `setup.sh` that document how old config
keys are rewritten. Maintainers cannot trust “all tests green” as a gate.

## Success criteria

- [ ] Running `bash docs/tests/test-no-stale-refs.sh` exits 0 on current main
- [ ] True stale product refs (dispatch, help, live config keys) still fail the test
- [ ] Migration/history comments in `setup.sh` (or equivalent) are allowlisted or
      scoped out without silencing real regressions
- [ ] Document the allowlist rule in the test header in one short paragraph

## Notes

- Failure observed 2026-07-30: `setup.sh` lines around dead-key rewrite of
  `MODEL_TALK`, `MODEL_DEFINE`, `MODEL_TASKS`, `BUDGET_TASKS`.
- Prefer tightening the grep (code vs comments, word boundaries, exclude
  migration blocks) over deleting the historical comments.
- Keep the rename-guard intent: catch leftover `talk`/`tasks` command paths in
  shipped surfaces.

## References

docs/tests/test-no-stale-refs.sh
setup.sh
docs/guides/command-matrix.md
