# Task 281: Smoke keep-family validate profile-show cleanup

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Keep-family integrity commands are the safety net. After the remap they must
still validate the surface and not require old config keys.

## Success criteria

- [x] `./sprint.sh validate --commands` passes
- [x] `./sprint.sh validate --docs` passes
- [x] `./sprint.sh validate` (task ID/deps) runs; record exit code (0 preferred if tree clean)
- [x] `./sprint.sh profile show` prints profile or a clear empty-state message (no hang)
- [x] `./sprint.sh help cleanup` and `./sprint.sh help deps` succeed
- [x] `./sprint.sh deps` is **not** required to finish a full AI pass in this smoke — `help deps` + confirm dispatch is enough unless deps is fast/no-AI; if it files a real backlog task, note the ID for human triage
- [x] Confirm config still has `MODEL_CHAT` / `MODEL_WORK` / `MODEL_GATE` / `BUDGET_WORK` (not retired keys)

## Notes

- Do not run `sync` against GitHub in this task.
- Do not run interactive `profile` without a human.

## References

docs/sprintmd/config
docs/sprintmd/scripts/validate-tasks.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/scripts/check-docs.sh

**Status: READY**

## Completed

- validate --commands: PASS
- validate --docs: PASS
- validate (task IDs/deps): PASS (60/60)
- profile show: empty state + pointer to ./sprint.sh profile
- help cleanup / help deps: OK
- config keys: MODEL_CHAT, MODEL_GATE, MODEL_WORK, BUDGET_WORK present; retired keys absent

### Files changed
(none)
