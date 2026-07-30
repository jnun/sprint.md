# Task 263: talk bugs conversion step (bug → task hand-off)

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/sprintmd/help/talk.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

`talk bugs` already owns the bug inbox conversationally, but the convert path
was thin: [w] minted a title-only `Fix: …` task and parked the report in
`archived/`. The hand-off should be a real conversion step inside talk — fill a
workable task from the report, then remove the bug from the workspace — without
adding a separate Process command for now.

## Success criteria

- [x] In `talk bugs`, the convert action ([w] work it) creates a real fix task
      in `backlog/`: Problem and Success criteria come from the bug report
      (not title-only). Task Notes record origin (bug id / title).
- [x] After a successful convert, the bug file is **deleted** from `docs/bugs/`
      (not moved to `archived/`). Inbox stays open reports only.
- [x] Close-without-task ([a]) also **deletes** the report when fixed/obsolete
      with no task. Kill still deletes. Help and `bug-creation.md` match.
- [x] `talk bugs` stays conversational — human still chooses per report. No new
      top-level command and no `talk bugs --auto`.
- [x] Shared `work_bug` helper used by [w]; docs/matrix/README/manual updated.

## Notes

- **For now:** conversion lives in talk. A separate Process verb is deferred.
- Delete-on-convert matches workspace rule: handled report leaves the inbox.

## References

docs/sprintmd/scripts/talk-bugs.sh
docs/sprintmd/help/talk.md
docs/sprintmd/ai/bug-creation.md
docs/guides/command-matrix.md

## Completed

### Files changed
docs/sprintmd/scripts/talk-bugs.sh
docs/sprintmd/help/talk.md
docs/sprintmd/help/newbug.md
docs/sprintmd/ai/bug-creation.md
docs/guides/command-matrix.md
DOCUMENTATION.md
README.md
GETSTARTED.md
setup.sh
docs/features/bug-tracking.md
