# Task 228: rename shipped sprint grouping concept to epic across codebase

**Feature**: none
**Created**: 2026-07-28
**Depends on**: 222
**Blocks**: 229

## Problem

Task 222 just shipped a persistent, named task-grouping concept under the name
**sprint** (`docs/sprints/`, `newsprint`, `.TEMPLATE-sprint.md`, a DOC_STATE
counter, help + docs). But the CLI itself is now `./sprint.sh` — "sprint" is the
name of the *tool*. That collision makes the word mean two things at once: the
product, and a grouping inside it. Rename the grouping to **epic** while it lives
only in `docs/` and has not yet been distributed to any user install — the rename
is cheap now and turns into a migration the moment `./ship.sh` + a user `setup.sh`
puts `docs/sprints/` in someone's project.

## Success criteria

- [x] Folder `docs/sprints/` → `docs/epics/`; `setup.sh` creates `docs/epics/` empty on a fresh install; `DOCUMENTATION.md` (folder table, structure tree, Key Concepts, the "vs. the folders above" clarification) says *epic*.
- [x] `docs/sprints/.TEMPLATE-sprint.md` → `docs/epics/.TEMPLATE-epic.md`, and its `ship.sh` `TEMPLATE_FILES` mirror entry is repointed.
- [x] `newsprint` command → `newepic`: `create-sprint.sh` → `create-epic.sh`, and the help page, `_registry`, dispatch, and manual all say `newepic`. `./sprint.sh validate --commands` passes with all four command surfaces agreeing.
- [x] The DOC_STATE.md `sprint_SPRINT_ID` counter is renamed to an epic counter (`sprint_EPIC_ID`) with its current value (`1`) preserved (no ID reuse).
- [x] The existing `docs/sprints/1-audit-the-distributable-source.md` becomes `docs/epics/1-*.md`; `status` and `ai-context` roll it up labeled as an *epic*, still without counting the file as a task.
- [x] Across shipped docs/help/scripts, "sprint" no longer names the *grouping*; remaining uses of "sprint" refer only to the CLI or the `next/` active queue (the old `sprint` planner command is handled separately in task 229 — leave it for now).
- [x] `./ship.sh --dry-run` is clean and a fresh `./setup.sh` install shows `docs/epics/` + the epic template working end-to-end.

## Notes

- **Terminology decision (user, 2026-07-28):** `./sprint.sh` owns the word "sprint"; the persistent named grouping that 222 built is renamed **epic**. Do it now — it is pre-distribution, so it is a pure `docs/` rename, not a user-data migration.
- **Scope boundary — rename only.** This task does NOT change behavior. The old `sprint` *auto-planner* subcommand (grab-5-from-backlog) is a different thing; it is reshaped into the conversational `epic` command in **task 229**. After this rename there will be `newepic` (create a blank epic file); 229 adds the conversational `epic` walk that *builds* one — 229 reconciles how the two coexist. Don't touch the planner here.
- **Watch the collision.** Most occurrences of "sprint" in the codebase mean the CLI or the `next/` queue, NOT the grouping. Grep every hit and read it in context before renaming; only grouping references change.
- Standard dogfood loop: edit `docs/`, run `./ship.sh --dry-run`, verify a fresh `./setup.sh`. Git is left to the user.

## References

- docs/tasks/review/222-build-sprints-as-a-first-class-epic-grouping-featu.md — the completed feature this renames; its `## Completed` block lists every file that was built
- docs/sprints/.TEMPLATE-sprint.md
- docs/sprints/1-audit-the-distributable-source.md
- docs/sprintmd/scripts/create-sprint.sh
- docs/sprintmd/help/newsprint.md
- docs/sprintmd/help/_registry
- docs/sprintmd/DOC_STATE.md
- docs/sprintmd/scripts/ai-context.sh, docs/sprintmd/scripts/status.sh
- setup.sh, ship.sh, DOCUMENTATION.md

## Questions

**Status: READY**

### Already complete
Nothing yet — the rename is entirely unstarted. Verified: `docs/sprints/` still holds `.TEMPLATE-sprint.md` and `1-audit-the-distributable-source.md`; `docs/epics/` does not exist; `create-sprint.sh` and `help/newsprint.md` are unchanged; DOC_STATE.md still has `sprint_SPRINT_ID: 1`; `_registry` line 20 and `sprint.sh` dispatch (`cmd_newsprint`, line 378) still say `newsprint`; `setup.sh` still creates `docs/sprints` and writes the `sprint_SPRINT_ID` field; `ship.sh` `TEMPLATE_FILES` still lists `docs/sprints/.TEMPLATE-sprint.md`; `ai-context.sh` and `sprint.sh`'s roll-up still read `$DOCS_DIR/sprints`; DOCUMENTATION.md still describes the grouping as *sprint*. The `Depends on: 222` field is present and correct — 222 (the feature this renames) is in `review/`.

### Remaining work
Straight mechanical rename of the *grouping* concept, `docs/`-only (pre-distribution, so no user migration). Concrete sites confirmed:
1. `git mv docs/sprints/ docs/epics/`; move `.TEMPLATE-sprint.md` → `.TEMPLATE-epic.md` and `1-audit-the-distributable-source.md` into it.
2. `create-sprint.sh` → `create-epic.sh` — rename file and its internal prose, `docs/sprints/` path, template path, and the counter references (`alloc_id`/`bump_doc_state` calls, error strings).
3. Command surfaces must all agree (`validate --commands` enforces this): `_registry` line 20, `sprint.sh` `cmd_newsprint`/dispatch case (line 378) and the run_script target, `help/newsprint.md` → `help/newepic.md`, and DOCUMENTATION.md (folder table line 22, Key Concepts lines 58–59, quick-ref lines 100/119, references line 205).
4. `DOC_STATE.md`: rename `sprint_SPRINT_ID` → epic counter, preserving value `1`. Same rename in `setup.sh` (fresh-write block ~line 738, upgrade-preserve block ~lines 749–779, and the field-doc comment lines 729/767) — but note `setup.sh` also creates `docs/sprints` at line 683, which must become `docs/epics`.
5. `ship.sh` `TEMPLATE_FILES` line 65 → `docs/epics/.TEMPLATE-epic.md`.
6. Roll-up code: `ai-context.sh` (`$DOCS_DIR/sprints`, lines 67–89) and `sprint.sh`'s grouping roll-up (lines 210–216, `$root/docs/sprints`) → `docs/epics`, labeled *epic*.
7. `./ship.sh --dry-run` clean, then fresh `./setup.sh` into a tmp dir shows `docs/epics/` + the epic template working.

Two accuracy notes for the implementer (not blockers):
- The References section lists `docs/sprintmd/scripts/status.sh`, which **does not exist**. The `status` roll-up lives in `sprint.sh` (`cmd_status`, roll-up at lines 210–216), not a standalone script — edit there.
- Collision watch (as the task warns): most `SPRINT`/`sprint` hits are the **CLI**, not the grouping, and must NOT change — e.g. `setup.sh`'s `SPRINT_*` shell vars and the `alias sprint='./sprint.sh'` block (lines 826–828, 1636–1655), and the `sprint` planner command + `talk-sprint.sh` (owned by tasks 229/231). Only rename the counter field `sprint_SPRINT_ID`, the `docs/sprints/` path, `newsprint`, and grouping prose.

### Questions for the developer
None — task is fully defined. Recommended counter name: `sprint_EPIC_ID` (keeps the tool's `sprint_` field namespace, matching `sprint_TASK_ID`/`sprint_BUG_ID`, while renaming only the concept). Nothing here needs a decision the developer must personally make.

## Completed

Renamed the persistent task-*grouping* concept from **sprint** to **epic**,
`docs/`-only (pre-distribution, so a pure rename with no user migration). The
CLI keeps the word "sprint" — every remaining `sprint`/`SPRINT` hit that stayed
untouched refers to the tool or the `next/` active queue, not the grouping. The
old `sprint` planner subcommand and `talk`'s sprint-walk are deliberately left
for tasks 229/231.

- **Folder + files**: `docs/sprints/` → `docs/epics/`; `.TEMPLATE-sprint.md` →
  `.TEMPLATE-epic.md`; `1-audit-the-distributable-source.md` moved and its prose
  relabeled (`# Epic 1:` + the relational-index blockquote).
- **Command**: `create-sprint.sh` → `create-epic.sh` (prose, `docs/epics/` path,
  template path, `[Epic Name]` fill, `sprint_EPIC_ID` alloc/bump/error strings);
  `newsprint` → `newepic` across all four surfaces — `_registry`, `sprint.sh`
  dispatch (`cmd_newepic` + `newepic)` case), `help/newepic.md`, and
  `DOCUMENTATION.md`. `validate --commands` passes (26 commands, all surfaces
  agree), verified on both the dev tree and a fresh install.
- **Counter**: DOC_STATE.md `sprint_SPRINT_ID` → `sprint_EPIC_ID`, value `1`
  preserved (keeps the tool's `sprint_` field namespace). `setup.sh` fresh-write
  block, upgrade-preserve block (`EXISTING_EPIC_ID`), field-doc comments, and the
  preserved-IDs message all renamed; `setup.sh` now creates `docs/epics/`.
- **Roll-ups**: `sprint.sh` `status_epics` and `ai-context.sh` read `docs/epics/`,
  strip the `Epic N:` title prefix, and print under an **Epics** heading — still
  never counting the epic file as a task (verified epic 1 shows `4/4 complete`).
- **Ship wiring**: `ship.sh` `TEMPLATE_FILES` repointed to
  `docs/epics/.TEMPLATE-epic.md`. Removed the orphan `src/docs/sprints/`
  (left by task 222's earlier ship) — the `TEMPLATE_FILES` copy list can't prune
  it, so a fresh install would otherwise have shipped the dead grouping template.
- **Verification**: `./ship.sh --dry-run` gates clean (create-epic.sh + newepic.md
  ship new; create-sprint.sh + newsprint.md pruned). Mirrored to `src/` with
  `./ship.sh --no-bump` (version bump left as the user's release step, like 222),
  then a fresh `./setup.sh` into a tmp dir created `docs/epics/` +
  `.TEMPLATE-epic.md`, `newepic "…"` allocated ID 1 and rolled up as an Epic, and
  `validate --commands` passed. **Left to the user**: run `./ship.sh` to bump the
  version and commit the release.

### Files changed
docs/epics/.TEMPLATE-epic.md
docs/epics/1-audit-the-distributable-source.md
docs/sprintmd/scripts/create-epic.sh
docs/sprintmd/scripts/ai-context.sh
docs/sprintmd/help/newepic.md
docs/sprintmd/help/_registry
docs/sprintmd/DOC_STATE.md
sprint.sh
setup.sh
ship.sh
DOCUMENTATION.md
docs/sprintmd/scripts/create-sprint.sh
docs/sprintmd/help/newsprint.md
docs/sprints/.TEMPLATE-sprint.md
docs/sprints/1-audit-the-distributable-source.md
src/

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
