# Task 222: Build docs/sprints/ as a relational plan-grouping feature

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

There's no place to organize a clump of related tasks as a unit. An "plan" like task 212 (goal + children 213–220) currently floats in `backlog/` with the grouping expressed only through each child's `Parent:` field — there's no single artifact that shows the clump, its goal, and its overall progress. Make sprints a real, shipped concept with the most minimal mechanism that works.

**Design (decided 2026-07-28): a sprint is a relational index, not a container.**
- Lives at **`docs/sprints/`** — top-level, a sibling of `tasks/`/`features/`, NOT `docs/tasks/sprints/` (that stray empty folder is deleted).
- One file per sprint: **`N-name-of-sprint.md`** (e.g. `1-method-accuracy-audit.md`), holding a goal + a **list of member task numbers** (213, 214, …).
- **Tasks are never moved into the sprint.** They stay in their own lifecycle folder and flow through `backlog → next → …` independently. The sprint file only *references* them by number. "Pushing a sprint to `next/`" means moving its member tasks from `backlog/` → `next/` — the sprint file itself never moves and has no status.

This makes a sprint purely an organizer: the tasks are the reality, the sprint file is a stable pointer over them. It must **not** be a lifecycle stage — not in `FIVEDAY_STAGES`, never counted or moved as a task.

## Success criteria

- [x] `docs/sprints/` is a documented, shipped folder: `setup.sh` creates it empty in a fresh install, and it appears in `DOCUMENTATION.md`'s folder table and structure tree — described as a relational grouping, explicitly distinguished from the lifecycle status folders (reuse the "blocked vs dependent"-style clarity).
- [x] The stray empty `docs/tasks/sprints/` is removed.
- [x] A `.TEMPLATE-sprint.md` exists — goal, why, and a member-task list of `#ID — short title` lines (checkboxes optional) — and ships via `ship.sh`'s `TEMPLATE_FILES` mirror (coordinate with task 217).
- [x] A sprint file references tasks by **number only**; nothing about the design requires editing a task when it changes folder. Moving/working a member task needs no change to the sprint file (its list is IDs, not paths/status).
- [x] `sprints/` is NOT added to `FIVEDAY_STAGES`; lifecycle consumers (`status`, `search`, `triage`, `validate`, `check-alignment`, `ai-context`) never treat a sprint file as a task, and none breaks whether the folder is present, empty, or absent.
- [x] `./sprint.sh status` (and `ai-context`) can surface sprints as groupings — list each sprint and roll up its member tasks' current folders/progress by resolving the ID list — without miscounting the sprint file as a task.
- [x] `./sprint.sh validate` validates sprint files against the sprint template (or cleanly ignores the folder); it never flags them as malformed tasks.
- [x] `./sprint.sh newsprint "<name>"` is built as part of v1 (parallel to `newtask`):
      it creates `docs/sprints/N-name.md` from the template and lets the author pick
      which task IDs go into the sprint — typically from `backlog/`, since a sprint is
      the *defining period* where you organize the tasks you want before work starts
      (`next/blocked/doing/review/done` are all post-start). The sprint ID `N` comes
      from a dedicated counter in `DOC_STATE.md`, incremented on creation exactly like
      task and bug IDs.
- [x] The first sprint file `docs/sprints/1-<name>.md` is created, listing member task
      IDs by number only (e.g. 213–220). **No task file is moved, rewritten, or
      retired** — the sprint file only *references* tasks by ID, and each task's own
      folder location is how its progress is tracked. Task 212 is NOT converted or
      deleted by this work; a sprint lists tasks, it does not replace them. (212's
      lifecycle is handled normally and separately.)
- [x] Everything is edited in `docs/` and mirrored via `./ship.sh`; a fresh `./setup.sh` install shows the folder + template working end-to-end.

## Notes

Scope (locked 2026-07-28): build the FULL feature now — docs, template, `newsprint`
command, `setup.sh` wiring, `status`/`validate`/lifecycle awareness — then create
sprint 1 listing its member task IDs (no task moved or retired), then ship.

Minimalism is the whole point (user's framing): a sprint file is just a named list of task numbers. Resist adding status, dates, or moving parts to it. The tasks carry all state; the sprint carries only membership + intent.

Relationship to the existing `sprint` command: today "a sprint = whatever is in `next/`" (per `sprint.sh` help; the `sprint`/`review-sprint` commands operate on `next/`). This feature adds a PERSISTENT, named grouping that can *feed* that flow — "push sprint N to next" = move its listed tasks `backlog/` → `next/`. Make the docs consistent: `docs/sprints/*.md` names/tracks a clump; `next/` is still the active sprint queue. Consider (not required for v1) wiring the `sprint` command to accept a sprint file and pull exactly its listed tasks into `next/`.

Member back-pointer: decide whether children keep `Parent: N` pointing at the sprint number, or drop `Parent:` entirely and let the sprint file's list be the sole grouping record. Recommendation: make the sprint file the single source of the grouping; a `Parent:`/`Sprint:` back-reference on each task is optional convenience, not required — keep it minimal.

The three questions that were open here are now answered — see `## Questions`.

## References

- docs/tasks/backlog/212-audit-the-entire-distributable-source-in-src-and-i.md — becomes sprint 1; its body models the template
- docs/sprintmd/lib.sh — `FIVEDAY_STAGES` (line ~251) and shared stage iteration; the invariant to protect
- docs/sprintmd/DOC_STATE.md — where a sprint-ID counter would live
- setup.sh — folder + template creation for a fresh install
- ship.sh — `TEMPLATE_FILES` mirror mechanism (introduced by task 217)
- docs/sprintmd/scripts/status.sh, ai-context.sh, validate-tasks.sh, triage.sh, sprint.sh — consumers to make sprint-aware
- DOCUMENTATION.md — folder table + structure tree + concept docs to update
- docs/tasks/next/217-audit-templates-and-reconcile-docs-vs-src-template.md — template mirror mechanism this depends on

## Questions

**Status: READY**

### Resolved decisions (2026-07-28, by the developer)

1. **Sprint numbering** — a sprint ID is drawn from a dedicated counter in
   `DOC_STATE.md` and ticked up on creation, exactly the same mechanism as task and
   bug IDs. First sprint = `1`.
2. **212's identity / what a sprint is** — a sprint **lists** task IDs; it does NOT
   replace, move, or retire the task files or their content. We keep using each task
   file (including its folder location) to watch sprint members walk from concept →
   defined → ready → worked. The earlier plan to "convert 212's content into the
   sprint file and retire task 212" is overruled and has been removed from the
   criteria.
3. **`newsprint` command** — build it now, in v1 (not a fast-follow). The full flow
   is: create the sprint file, then select which task IDs belong to it — typically
   pulled from `backlog/`, because a sprint is the *defining/planning period* where
   you choose the work before it starts moving through the lifecycle.

### Remaining work

Build the full feature per the Success criteria: `docs/sprints/` folder + `setup.sh`
wiring, `.TEMPLATE-sprint.md` shipped via 217's `TEMPLATE_FILES` mirror, `newsprint`
command with backlog member-selection, `status`/`validate`/lifecycle awareness that
never treats a sprint file as a task, and create sprint 1 listing its members. Then
`./ship.sh`. Blocked only by task 217 landing the template-mirror mechanism.

## Completed

Built the full `docs/sprints/` feature as a **relational index over tasks**, not
a lifecycle stage or container.

- **Folder + docs**: `docs/sprints/` is documented in DOCUMENTATION.md's boundaries,
  structure tree, Creating-Work table, Commands block, Key Concepts, template
  list, and a new "Sprints vs. the folders above" clarification block (mirrors
  the blocked-vs-dependent framing). `setup.sh` creates `docs/sprints/` empty on
  a fresh install.
- **Stray folder removed**: `docs/tasks/sprints/` deleted from the working tree.
  (It was still git-staged as an add — run `git rm --cached docs/tasks/sprints/.gitkeep`
  to unstage it, since git is left to you.)
- **Template**: `docs/sprints/.TEMPLATE-sprint.md` (goal / why / member `#ID — title`
  list) added to `ship.sh`'s `TEMPLATE_FILES` mirror (task 217's mechanism).
- **`newsprint` command**: `create-sprint.sh` allocates a `sprint_SPRINT_ID` from
  DOC_STATE.md (new dedicated counter, same lock/alloc/bump path as task/bug IDs),
  writes `docs/sprints/N-name.md` from the template, and fills the member list
  from IDs given as args (numbers + `N-M` ranges) or picked interactively from
  `backlog/`. Wired through the registry, dispatch, a help page, and the manual —
  `validate --commands` confirms all four surfaces agree (27 commands).
- **Lifecycle safety**: `sprints/` is NOT in `FIVEDAY_STAGES`. Every lifecycle
  consumer (status, search, triage, validate, check-alignment, sync, ai-context)
  scopes to `docs/tasks/$stage`, so a sprint file is never seen as a task —
  verified `validate` does not flag `docs/sprints/1-*.md`.
- **Rollups**: `status` and `ai-context` list each sprint and resolve its member
  IDs to their current folders (review+done = complete) without counting the
  sprint file as a task. Verified: sprint 1 shows `1/4 complete`.
- **Sprint 1 created** by dogfooding `newsprint`: `docs/sprints/1-audit-the-distributable-source.md`
  lists members #215 #216 #220 #221 by number only. No task file was moved,
  rewritten, or retired; task 212 was not converted or deleted.
- **Ship**: left to the user as the release step. `./ship.sh --dry-run` is clean —
  gates pass (no legacy refs / orphan dirs), and the new template + script + help
  page are queued to mirror into `src/`. Run `./ship.sh` to mirror and bump, then
  a fresh `./setup.sh` install will show the folder + template end-to-end.

### Files changed
docs/sprints/.TEMPLATE-sprint.md
docs/sprints/1-audit-the-distributable-source.md
docs/sprintmd/scripts/create-sprint.sh
docs/sprintmd/help/newsprint.md
docs/sprintmd/help/_registry
docs/sprintmd/DOC_STATE.md
docs/sprintmd/scripts/ai-context.sh
sprint.sh
setup.sh
ship.sh
DOCUMENTATION.md
