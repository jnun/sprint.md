# Task 284: Fix any matrix or surface drift found and re-validate

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 277, 278, 279, 280, 281, 282, 283
**Blocks**: 285
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Audit tasks #277–#283 may find drift (stale help, wrong one-liner, config key,
stray old command string). Leaving findings unfixed wastes the sprint.

## Success criteria

- [x] Collect findings from #277–#283 `## Completed` sections (or re-run checks if those tasks are parallel)
- [x] Fix every **live-surface** issue under `docs/sprintmd/`, root manuals, `sprint.sh` (matrix only if matrix is wrong)
- [x] Re-run `./sprint.sh validate --commands` and `./sprint.sh validate --docs` — both green
- [x] Re-run `bash docs/tests/test-no-stale-refs.sh` — green
- [x] If ship-worthy paths changed, run `./ship.sh` and note version
- [x] If zero findings, document that explicitly — task still completes

## Notes

- Prefer smallest fix. No scope creep into plan 5 (Grok).
- Historical `docs/tasks/done/**` not required to rewrite.

## References

docs/guides/command-matrix.md
docs/tests/test-no-stale-refs.sh

**Status: READY**
