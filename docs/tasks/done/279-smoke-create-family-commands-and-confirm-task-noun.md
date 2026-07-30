# Task 279: Smoke create-family commands and confirm task noun paths

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Create-family commands mint durable artifacts. We must prove each still
dispatches and that the task *noun* (`docs/tasks/`, `newtask`) survived the
work-verb rename.

## Success criteria

- [x] `./sprint.sh help newidea|newfeature|newtask|newplan|newbug|newtest` each prints usage
- [x] `test -d docs/tasks` and lifecycle folders `backlog next doing blocked review done` exist
- [x] `newtask` still creates under `docs/tasks/backlog/` (prove with one **throwaway** task titled clearly for deletion, e.g. "TEMP matrix-smoke delete me", then **delete the file** and restore DOC_STATE only if the counter policy allows — prefer leave the temp task for #285 cleanup if shared; otherwise delete and note ID)
- [x] Confirm no path renamed `docs/tasks/` → something else; `validate-tasks.sh` still exists as filename
- [x] Record smoke results in `## Completed`

## Notes

- Prefer not leaving permanent junk: if you create a temp task, either hand it to #285 or delete it before finishing.
- Do not rename create commands.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/create-task.sh
docs/tasks/

**Status: READY**
