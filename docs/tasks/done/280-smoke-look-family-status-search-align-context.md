# Task 280: Smoke look-family status search align context

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Look commands are read-only and high-traffic for agents. Broken renames
(`checkfeatures`→`align`, `ai-context`→`context`) show up here first.

## Success criteria

- [x] `./sprint.sh status` exits 0 and shows board-ish counts
- [x] `./sprint.sh search matrix` or `search command` returns without error
- [x] `./sprint.sh align` runs (may print analysis; non-zero only on hard failure)
- [x] `./sprint.sh context` prints a project context summary (header or sections)
- [x] Retired: `./sprint.sh checkfeatures` and `./sprint.sh ai-context` are Unknown command
- [x] Note any unexpected mutation of files (look must not write task bodies)

## Notes

- No AI budget required if scripts run deterministically; emit-mode is fine.
- Paste key first lines of each command's output into `## Completed`.

## References

docs/sprintmd/scripts/check-alignment.sh
docs/sprintmd/scripts/context.sh
docs/sprintmd/scripts/search.sh

**Status: READY**
