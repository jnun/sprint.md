# Task 282: Smoke work-family gate/work/loop help and off-spine labels

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Work-family is the spine plus off-spine tools. Help text must rank
`work` / `loop` as happy path and label `gate` / `split` off-spine, `polish`
after work — a flat equal list re-invites misuse.

## Success criteria

- [x] `./sprint.sh help work` describes happy-path execute READY queue (verb work, noun task)
- [x] `./sprint.sh help loop` describes autopilot spine (plan start + work)
- [x] `./sprint.sh help gate` labels off-spine / not the default after plan start
- [x] `./sprint.sh help split` off-spine one-shot
- [x] `./sprint.sh help polish` after-work quality
- [x] `./sprint.sh help` work-section one-liners use spine language (Happy path / Off-spine / After work / Autopilot)
- [x] `./sprint.sh gate` dry run on next/ is safe: either skips already READY or reports; do **not** require AI spend — if it would call AI, stop at help + `gate` usage path and note
- [x] Retired `tasks` / `define` still Unknown command

## Notes

- Prefer help/dispatch proof over starting a multi-dollar `work` run on this plan's own tasks from inside this task (that's the outer sprint).
- Script basenames: `work.sh`, `gate.sh` CLI, `gate-lib.sh` library only.

## References

docs/sprintmd/help/work.md
docs/sprintmd/help/gate.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/_registry

**Status: READY**

## Completed

- help work/gate/loop/split/polish: OK
- help Work section labels: Happy path / Autopilot / Off-spine / After work present
- help loop still said "Wraps tasks" / "forwarded to tasks" → fixed in #284
- tasks/define: Unknown command
- gate.sh CLI + gate-lib.sh layout confirmed

### Files changed
(none in this task; fix landed under #284)
