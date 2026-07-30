# Task 278: Prove retired command names do not dispatch

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Retired matrix names must fail closed. Any surviving alias or dispatch arm
teaches agents the old surface and re-opens dual-language debt.

## Success criteria

- [x] For each retired name, run `./sprint.sh <name>` and confirm **Unknown command** (or equivalent non-dispatch):
  `talk`, `tasks`, `define`, `checkfeatures`, `ai-context`, `audit-deps`,
  `triage`, `find`, `review-sprint`, `newepic`, `audit`, `excellence`, `review-code`
  (skip ecosystem CLIs; these are sprint.md top-level only)
- [x] Confirm successors work: `chat`, `work`, `gate`, `align`, `context`, `deps` at least `help <cmd>` succeeds
- [x] Record results in `## Completed` as a two-column table (old → unknown / new → ok)
- [x] Zero unexpected successes on retired names (if any succeed, note for #284)

## Notes

- No re-adding aliases "for convenience."
- `sprint` as a bare command should not dispatch as a plan synonym if retired.

## References

docs/guides/command-matrix.md
sprint.sh

**Status: READY**
