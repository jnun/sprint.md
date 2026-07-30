# Task 230: retire the sprint-plan cache and derive sprint theme from next live

**Feature**: none
**Created**: 2026-07-28
**Docs**: docs/guides/command-matrix.md
**Depends on**: 245
**Blocks**: none

## Problem

`docs/tmp/sprint-plan.md` is a cached, hand-or-machine-written description of
"the current sprint" that `talk.sh` injects into every session as theme context.
A cache of a fact that lives elsewhere inevitably drifts: the file recently
still described a finished April installer sprint, silently misleading anyone
(and any command) that trusted it. The real source of truth is `next/` —
whatever tasks sit there *are* the sprint, put there on purpose (by `plan start`
once task 245 lands). Retire the cache entirely and have `talk` derive the
sprint theme from `next/` live, so there is nothing stored to go stale. This
removes the staleness *category*, not just the current stale instance.

## Success criteria

- [x] `docs/tmp/sprint-plan.md` is deleted, and nothing in the codebase writes
      or reads it (verified by grep — task 245 already stopped emitting the
      writer).
- [x] `talk.sh` (currently the `_SPRINT_LINE` block at ~lines 165–172, plus the
      STRESS-TEST prompt phrasing "if a sprint plan exists" at ~line 239) no
      longer points at the cache; the sprint context it supplies is derived
      live from `docs/tasks/next/` (its current task set), so it is accurate
      the moment it's read. If an active plan file in `docs/plans/` exists
      (authored by 244), its goal may supplement the live `next/` listing — but
      never replace reading `next/` directly.
- [x] Running `talk` on any task shows sprint context matching
      `ls docs/tasks/next/` at that moment, with no stored plan file involved.
- [x] No command or doc still references `docs/tmp/sprint-plan.md` — including
      `docs/sprintmd/help/plan.md` (lines ~4 and ~25 today; 244/245 rewrite this
      page, the final grep is the backstop for whichever task lands last).
- [x] `./ship.sh --dry-run` clean; a fresh `./setup.sh` install has no
      `sprint-plan.md` and `talk` still supplies sprint context.

## Notes

- **Antifragile rationale (user, 2026-07-28):** elegant / simple / antifragile.
  A hand-refreshed cache fails all three — a second copy of `next/` that must be
  kept in sync and rots when it isn't. Reading `next/` live is one source, no
  copy, cannot drift. (The original "refresh the stale plan" task 227 was
  retired for this reason — refreshing a cache only resets the clock on the
  same failure.)
- **Terminology (settled plan design):** the grouping is a *plan* in
  `docs/plans/`; `next/` IS the sprint; the old auto-planner (today's
  `plan.sh:8`, `PLAN_FILE="docs/tmp/sprint-plan.md"`) is retired by 245.
- **Depends on 245:** once `plan start` lands and the auto-planner is retired,
  nothing produces `sprint-plan.md`, so deleting it and repointing `talk` is
  clean. If this is somehow worked first, confirm nothing live still writes the
  file — removing the writer is 245's job, not this task's.
- **Theme derivation stays minimal:** a few lines listing `next/` task
  IDs/titles at read time, inline in `talk.sh`. Resist rebuilding a stored
  "theme" field — the point is to *not* cache. Promote to a `lib.sh` helper
  only when a second caller wants the same view.
- Standard dogfood: edit `docs/`, ship, verify fresh install; git left to the
  user.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/talk.sh
docs/tmp/sprint-plan.md
docs/sprintmd/scripts/plan.sh
docs/sprintmd/help/plan.md

## Questions

**Status: READY**

### Already complete
- The cache artifact itself is already absent: `docs/tmp/sprint-plan.md` does not
  exist on disk (only `.gitkeep` and unrelated logs live in `docs/tmp/`). So the
  "file is deleted" half of criterion 1 is trivially satisfied today — the real
  remaining work is removing the code/doc references that still point at it.
- **Depends on: 245** is correctly recorded. 245 owns retiring the *writer*
  (`plan.sh:8` `PLAN_FILE=...` and its auto-move/theme-guess flow); this task
  owns removing the *reader* and repointing `talk`. That split is consistent
  between both files.

### Remaining work
Only one file carries this task's unique work today; the rest is dependency-gated
or a verification backstop:

1. **`talk.sh` — the reader (the core, un-gated work).**
   - Lines 170–172: the `_SPRINT_LINE` block does
     `[ -f "docs/tmp/sprint-plan.md" ] && _SPRINT_LINE=...`. Replace it with a
     few inline lines that list `docs/tasks/next/*.md` IDs/titles at read time
     (per the "theme derivation stays minimal" note — inline, no stored field,
     no `lib.sh` helper until a second caller needs it). Optionally supplement
     with an active plan's goal from `docs/plans/` if one exists, but always read
     `next/` directly.
   - Line 239 (STRESS-TEST prompt): the phrase "fit the current sprint theme
     (if a sprint plan exists)" should be repointed to the live `next/`-derived
     theme so the wording matches the new source of truth.
2. **`plan.sh:8` writer** — retired by **245**, not this task (per the notes and
   245's own criteria). Leave to 245; if 230 is somehow worked first, confirm
   nothing live still writes the file before deleting references.
3. **`docs/sprintmd/help/plan.md` (lines 4, 25)** — 244/245 rewrite this page;
   the final grep is the backstop for whichever task lands last. Sweep it as part
   of this task's closing grep.
4. **Final grep backstop** — `grep -rn 'sprint-plan\.md' docs/sprintmd/` returns
   nothing after the above land. (Matches in `docs/tasks/`, `docs/plans/` are our
   own dogfood task/plan files, not distributed — ignore them.)
5. **Ship + verify** — `./ship.sh --dry-run` clean, then a fresh `./setup.sh`
   install has no `sprint-plan.md` and `talk` still supplies sprint context.

### Questions for the developer
None — task is fully defined. The scope, the exact lines to touch, the
source-of-truth (`next/` live, plan goal as optional supplement), and the
dependency split with 245 are all settled.

### Implementation notes (2026-07-29)

- Deleted the stale `docs/tmp/sprint-plan.md` cache artifact.
- `talk.sh` `_SPRINT_LINE` now lists live `docs/tasks/next/*.md` IDs/titles at
  read time; optionally appends the Goal of a `docs/plans/[0-9]*.md` plan that
  names a current `next/` member. STRESS-TEST GOAL ALIGNMENT points at the live
  sprint, not a cache.
- `plan.sh` comment no longer names `sprint-plan.md` (grep backstop clean under
  `docs/sprintmd/`). `help/plan.md` was already clean from 244/245.
- Shipped v0.0.15. Fresh `./setup.sh` install has no `sprint-plan.md`; talk
  theme derivation works against live `next/`.

## Completed

### Files changed
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/plan.sh
docs/tmp/sprint-plan.md
src/docs/sprintmd/scripts/talk.sh
src/docs/sprintmd/scripts/plan.sh
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
