# Task 229: reshape sprint auto-planner into conversational epic grouping walk

**Feature**: none
**Created**: 2026-07-28
**Depends on**: 228
**Blocks**: 230

## Problem

The existing `sprint` command (`docs/sprintmd/scripts/sprint.sh`) is an
auto-planner: it grabs ~5 tasks from `backlog/`, *guesses* a theme, and writes a
plan file. That model doesn't match how work is actually organized here — epics
are assembled deliberately, task by task, by a human who knows the intent. The
planner's guess is low-value and it's the only command that isn't conversational.
Reshape it into **`epic`**: a `talk`-style walk that helps a person *group*
backlog tasks into an epic file (`docs/epics/N-*.md`, from task 228), the same way
`talk` walks tasks to refine them. The theme is set in the conversation and
recorded as the epic's goal — never machine-guessed or cached.

## Success criteria

- [ ] `./sprint.sh epic` (no argument) starts a conversational walk of `backlog/` **oldest-first** (lowest ID = stalest crust), proposing tasks to group into a new epic while surfacing stale ones for grooming.
- [ ] `./sprint.sh epic <task-id>` or `./sprint.sh epic <feature>` seeds the walk from that task/theme and groups related backlog tasks outward from it.
- [ ] The walk produces (or extends) a `docs/epics/N-*.md` file listing member task IDs by number only, with a goal captured from the conversation — reusing the epic template and ID counter from task 228, and the `create-epic` mechanism where it fits (reconcile `epic` vs `newepic`: `newepic` = create a blank epic; `epic` = the conversational build — decide whether `epic` supersedes, wraps, or complements `newepic`, and document the choice).
- [ ] The command no longer writes `docs/tmp/sprint-plan.md` or any cached plan artifact; its durable output is the epic file. (Deleting the leftover cache file and repointing `talk` off it is task 230.)
- [ ] The interaction model matches `talk` closely enough that someone who knows `talk` can use `epic` without new mental overhead (mirrors `talk <id>` vs `talk <folder>`); help page, `_registry`, dispatch, and manual are updated and `validate --commands` passes.
- [ ] `./ship.sh --dry-run` clean; a fresh `./setup.sh` install can run `epic` end-to-end.

## Notes

- **Design (user, 2026-07-28):** `epic` is "`talk` for grouping." Two seed modes mirror `talk`'s own `<id>` vs `<folder>` duality: oldest-first backlog walk, or seed-from-id/feature. One interaction paradigm across the whole CLI is the point — the old auto-planner was the odd one out and the part that rotted.
- **Coherence to resolve deliberately:** `epic`'s oldest-first backlog walk overlaps `talk backlog` folder mode (task 226) — both walk `backlog/` task-by-task. Decide whether they are one walk with two verbs (group vs refine) or cleanly separate commands, so two backlog-walkers don't confuse each other. This is the key design question of the task; settle it before building.
- **Antifragile intent:** the epic is *authored*, not computed; the "theme" is the epic's recorded goal, not a stored label that drifts. No cache is emitted — that is what kills the staleness class (finished off in 230).
- Depends on 228 landing the `epic` naming, `docs/epics/` folder, template, and ID counter. Build in `docs/`, ship, verify fresh install; git left to the user.

## References

- docs/sprintmd/scripts/sprint.sh — the auto-planner being reshaped (the `PROMPT`/plan-writing model to replace)
- docs/sprintmd/scripts/talk.sh — the conversational-walk pattern to mirror
- docs/tasks/next/226-add-talk-folder-mode-talk-blocked-next-backlog-ret.md — `talk <folder>` backlog walk; the overlap to reconcile
- docs/tasks/next/225-sprint-walk-talk-no-id-resolve-next-blocked-depend.md — dependency-driven walk resolution, related interaction model
- docs/tasks/review/222-build-sprints-as-a-first-class-epic-grouping-featu.md — the epic file/folder/template this walk populates
- docs/sprintmd/help/_registry, DOCUMENTATION.md

## BLOCKED

This task cannot be built until its two flagged design decisions are made — the
author's own Notes call them "the key design question of the task" and say to
"settle it before building." First: how does the new conversational `epic`
command coexist with `newepic` (the blank-epic creator from task 228) — does it
supersede, wrap, or complement it? Second: `epic`'s oldest-first backlog walk
overlaps the already-shipped `talk backlog` folder sweep (task 226,
`talk-folder.sh`) — are these one walk with two verbs or two separate commands,
and how do we keep two backlog-walkers from confusing users? Neither decision is
resolvable by another queued task (the epic infrastructure from 228 is a clean
dependency, not the blocker); both are command-grammar choices a human must make
before the dispatch, `_registry`, help page, and walk behavior can be written.
Strong recommended defaults are in the Questions below. Run
`./sprint.sh talk 229` to resolve these questions.

## Questions

**Status: BLOCKED**

### Already complete
Nothing. Verified the task is entirely unstarted: no `epic`/`newepic` command
exists anywhere (`grep -rniE '\bepic\b'` over `docs/sprintmd/`, `sprint.sh`,
`setup.sh` returns only unrelated prose); the current `sprint` command
(`docs/sprintmd/scripts/sprint.sh`) is still the auto-planner that writes
`docs/tmp/sprint-plan.md`; `docs/epics/` does not exist. The `Depends on: 228`
field is present and correct — 228 (which creates `docs/epics/`, the epic
template, the epic ID counter, `create-epic.sh`, and `newepic`) is still in
`next/`, unstarted. Note the overlapping walker this task must reconcile against
already exists and is DONE: `docs/sprintmd/scripts/talk-folder.sh` implements the
`talk backlog` one-at-a-time sweep (tasks 225 and 226 are in `review/`).

### Remaining work
All of it, blocked on the two decisions below. Once settled, the scope is: replace
the auto-planner in `sprint.sh` (or a new `epic.sh`) with a `talk`-style
conversational walk that (1) with no argument walks `backlog/` oldest-first
proposing tasks to group; (2) with a `<task-id>`/`<feature>` argument seeds from
that task/theme; (3) produces or extends a `docs/epics/N-*.md` file (member IDs by
number, goal captured from the conversation) reusing 228's template, ID counter,
and `create-epic` mechanism; (4) writes no cache artifact; (5) wires up help page,
`_registry`, dispatch, and manual so `validate --commands` passes; (6) ships clean
and runs end-to-end on a fresh install. Mirror `talk.sh`'s interaction contract so
there is no new mental overhead.

### Questions for the developer
1. How should the conversational `epic` coexist with `newepic` (the blank-epic
   creator task 228 adds)? (Suggestion: make `epic` **complement** `newepic`,
   mirroring the existing `newtask` → `talk` pair exactly — `newepic` stamps out a
   blank epic file for someone who just wants the shell, while `epic` runs the
   guided build, calling `create-epic.sh` under the hood to allocate the ID/file
   and then populating members + goal through the walk (and extending an existing
   epic when given its ID). This adds zero new mental model, reuses 228's ID/file
   machinery instead of duplicating counter logic, and keeps a fast non-AI path
   available.)
2. Are `epic`'s backlog walk and the existing `talk backlog` sweep one walk with
   two verbs, or two separate commands — and how do we prevent two backlog-walkers
   from confusing users? (Suggestion: keep them **separate commands with distinct
   intents over the same folder**. `talk backlog` sharpens *one task at a time*
   (verdict → promote/define/kill/skip, editing task files); `epic` *assembles many
   tasks into a grouping* (writes only the epic file). To guarantee they can't step
   on each other, make `epic`'s walk **read-only over `backlog/`** — it never
   mutates task files, its sole durable write is `docs/epics/N-*.md`. Document this
   boundary in the `epic` help page and DOCUMENTATION.md so the "group vs refine"
   split is explicit.)
3. Minor, non-blocking: how does seed mode distinguish a `<task-id>` from a
   `<feature>` argument? (Suggestion: dispatch on argument shape as `talk` does —
   an all-numeric argument is a task ID (seed from that task and group outward);
   anything else is treated as a feature/theme string. Resolve this once decisions
   1–2 are settled; it needs no separate decision.)

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
