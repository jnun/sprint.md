# Task 230: retire sprint-plan.md cache and read sprint theme from next live

**Feature**: none
**Created**: 2026-07-28
**Depends on**: 229

## Problem

`docs/tmp/sprint-plan.md` is a cached, hand-or-machine-written description of "the
current sprint" that `talk.sh:135` injects into every `talk`/`sprint` session as
theme context. A cache of a fact that lives elsewhere inevitably drifts: the file
recently still described a finished April installer sprint, silently misleading
anyone (and any command) that trusted it. The real source of truth is `next/` —
whatever tasks sit there *are* the sprint, put there on purpose. Retire the cache
entirely and have `talk` derive the sprint theme from `next/` live, so there is
nothing stored to go stale. This is the antifragile fix: it removes the staleness
*category*, not just the current stale instance.

## Success criteria

- [ ] `docs/tmp/sprint-plan.md` is deleted, and nothing in the codebase writes or reads it (verified by grep — the `epic` command from task 229 already stopped emitting it).
- [ ] `talk.sh` (currently line ~135) no longer points at `sprint-plan.md`; the "current sprint theme" it supplies as context is derived live from `docs/tasks/next/` (its current task set), so it is always accurate the moment it's read.
- [ ] Running `talk` on any task shows sprint context that matches `ls docs/tasks/next/` at that moment, with no stored plan file involved.
- [ ] No command or doc still references `docs/tmp/sprint-plan.md`; help/manual mentions of a "sprint plan" file are removed or repointed to the live `next/`-derived view.
- [ ] `./ship.sh --dry-run` clean; a fresh `./setup.sh` install has no `sprint-plan.md` and `talk` still supplies sprint context.

## Notes

- **Antifragile rationale (user, 2026-07-28):** the three lenses are elegant / simple / antifragile. A hand-refreshed cache fails all three — it's a second copy of `next/` that must be kept in sync and rots when it isn't. Reading `next/` live is one source, no copy, and cannot drift. (This task is the reason the original "refresh the stale plan" task 227 was retired rather than worked — refreshing the cache only resets the clock on the same failure.)
- **Depends on 229:** once the `sprint` planner is reshaped into `epic`, nothing produces `sprint-plan.md`, so deleting it and repointing `talk` is clean. If 230 is picked up before 229 lands, first confirm no live command still writes the file.
- **Theme derivation** can be as simple as listing the `next/` task titles/IDs (optionally their common feature) — resist rebuilding a stored "theme" field; the point is to *not* cache. Keep it minimal.
- Standard dogfood: edit `docs/`, ship, verify fresh install; git left to the user.

## References

- docs/sprintmd/scripts/talk.sh — line ~135 reads `docs/tmp/sprint-plan.md`; the injection point to repoint at `next/`
- docs/tmp/sprint-plan.md — the cache to delete
- docs/sprintmd/scripts/sprint.sh — historical writer of the cache (reshaped by task 229)
- docs/tasks/next/225-sprint-walk-talk-no-id-resolve-next-blocked-depend.md — related `next/`-as-sprint reasoning

## Questions

**Status: READY**

### Already complete
Nothing is implemented yet — this task is entirely remaining work. Current state confirms the problem is real and unchanged:
- `docs/tmp/sprint-plan.md` still exists (the stale April file, dated Apr 8, describing the finished 143/144/145 installer sprint).
- `docs/sprintmd/scripts/talk.sh:171-172` still reads it into `_SPRINT_LINE`; the surrounding comment (lines 165-172) and the STRESS-TEST prompt line ("fit the current sprint theme (if a sprint plan exists)", ~line 239) also reference it.
- `docs/sprintmd/help/sprint.md:4,25` still points at it.
- `docs/sprintmd/scripts/sprint.sh:8` still writes it (`PLAN_FILE=...`) — but that writer is task 229's territory, not this task's.

### Remaining work
1. Delete `docs/tmp/sprint-plan.md`.
2. Repoint `talk.sh` (currently lines 165-172): replace the `_SPRINT_LINE` block that reads the cache with a live derivation of the sprint theme from `docs/tasks/next/` — minimal, per the Notes: list the `next/` task IDs/titles at read time so it can never go stale. Also update the STRESS-TEST prompt phrasing (~line 239) that mentions "if a sprint plan exists".
3. Remove the `sprint-plan.md` references from `docs/sprintmd/help/sprint.md` (and any surviving manual mention), repointing "sprint plan" language to the live `next/`-derived view.
4. Verify: `grep -r sprint-plan.md` over live code is clean; `./ship.sh --dry-run` clean; a fresh `./setup.sh` install has no `sprint-plan.md` and `talk` still supplies sprint context. Then `./ship.sh` to mirror into `src/`.

Note the ordering guard already in the Notes: this depends on 229 removing the `sprint.sh` writer. If 230 is somehow worked before 229 lands, don't strip the write logic from `sprint.sh` yourself (that's 229's job) — just confirm nothing *live* still emits the file before deleting it.

### Questions for the developer
1. Where should the live `next/`-theme derivation live — inline in `talk.sh` or as a `lib.sh` helper? (Suggestion: inline in `talk.sh` for now. It's a 3-4 line `for`-loop over `docs/tasks/next/*.md` collecting IDs/titles, used in exactly one place; a helper only pays off once a second caller needs it. Keep it minimal per the "resist rebuilding a stored theme" note. Promote to `lib.sh` only if 229's `epic` command ends up wanting the same view.)
2. `help/sprint.md` is also being rewritten by 229 (reshape to `epic`) and 231 (rename `sprint`→`plan`) — should 230 edit it at all, or leave it to those tasks? (Suggestion: have 230 defensively remove the `sprint-plan.md` lines it can see, and rely on the final `grep` in criterion 4 as the backstop — whichever task lands last, the grep proves no live reference survives. This is a known overlap, not a blocker: tasks 231's own notes already flag it.)

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the five-day change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
