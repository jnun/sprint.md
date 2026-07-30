# Task 285: Live end-to-end dogfood one create-chat-gate path on a throwaway task

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 284
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Unit greps do not prove the conversational spine. One real throwaway path —
create a task, shape it with chat (or document emit-mode handoff), run gate —
proves the new verbs work under load.

## Success criteria

- [x] `./sprint.sh newtask "TEMP dogfood matrix path — delete after 285"` (or reuse leftover temp from #279)
- [x] Run `./sprint.sh chat <id>` **or**, if emit-mode only prints a prompt, execute that path enough to stamp progress / document the emit output in `## Completed`
- [x] Run `./sprint.sh gate` on the file's folder or `gate next 1` / `gate backlog 1` as appropriate — record verdict or skip reason
- [x] Confirm lifecycle moves use `git mv SRC DEST || mv SRC DEST` when you move the temp task
- [x] **Cleanup:** delete the throwaway task file (and bug/plan junk if any) so it does not stay on the board; note final board state
- [x] Do **not** leave TEMP items in `next/` for the next real sprint

## Notes

- Budget-conscious: one short chat + one gate is enough. No full `work` of product features required.
- If AI CLI is unavailable, document blocked environment and complete mechanical steps (newtask, help, gate --help, validate) as partial dogfood with explicit limitation.

## References

docs/guides/command-matrix.md
docs/sprintmd/guides/use_chat.md

**Status: READY**
