# Task 246: define absorbs audit: vet task quality on any folder and retire the audit command

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

`audit` (`audit-tasks.sh`) and `define` (`define.sh`) both vet task-file quality
before execution. `audit` reports quality on any folder (backlog/next/doing/
blocked), read-mostly; `define` vets `next/` and gates each task to READY (or
moves it to `blocked/`). Two commands, overlapping jobs — and `audit` carries a
compliance-discipline word the matrix wants gone. Per the matrix, `audit` rolls
into `define`: extend `define` to accept a folder argument so it can vet quality
anywhere, and retire the standalone `audit` command.

## Success criteria

- [x] `define [folder] [limit]` accepts an optional folder (backlog/next/doing/
      blocked, default `next/`) and vets task quality there. `next/` keeps its
      READY-gating behavior (unready tasks move to `blocked/`); on a non-`next`
      folder `define <folder>` writes no files and moves no tasks (verifiable:
      run `define backlog`, assert `git status` shows no task moves) and emits
      the same quality-report fields `audit` did.
- [x] `audit` is removed from all four surfaces — `_registry`, dispatch in
      `sprint.sh`, help page, and `DOCUMENTATION.md`; `audit-tasks.sh` is deleted
      and its folder-targeting + read-only quality-report logic is merged into
      `define.sh`. `./sprint.sh audit` gets the unknown-command message.
- [x] The concrete `audit` deltas `define` lacked are all preserved as `define`
      modes: (a) accepts a folder arg in {backlog, next, doing, blocked};
      (b) non-`next` runs are non-gating and non-mutating; (c) the report carries
      a per-task quality verdict — nothing silently lost in the merge.
- [x] `./sprint.sh validate --commands` passes; `./ship.sh --dry-run` clean; a
      fresh `./setup.sh` install runs `define` on a chosen folder end-to-end.

## Notes

- The matrix retires the word "audit" for task-quality (a compliance-discipline
  term); `define` is the plain survivor. `audit-deps` keeps its name separately —
  "dependency audit" is accurate common language — and is out of scope here.
- Two internal paths, one surface: `next/` keeps the deep READY-gate; other
  folders use the quality-report path (DONE/OUTDATED/UNDEFINED/KEEP, no moves).
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  user.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/define.sh
docs/sprintmd/help/define.md
docs/sprintmd/help/_registry
DOCUMENTATION.md

## Completed

### Files changed
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/audit-tasks.sh
docs/sprintmd/help/define.md
docs/sprintmd/help/audit.md
docs/sprintmd/help/audit-deps.md
docs/sprintmd/help/_registry
sprint.sh
DOCUMENTATION.md
README.md
src/sprint.sh
src/DOCUMENTATION.md
src/docs/sprintmd/scripts/define.sh
src/docs/sprintmd/scripts/audit-tasks.sh
src/docs/sprintmd/help/define.md
src/docs/sprintmd/help/audit.md
src/docs/sprintmd/help/audit-deps.md
src/docs/sprintmd/help/_registry
src/VERSION
docs/plans/2-command-matrix-redesign.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
