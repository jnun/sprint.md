# Task 231: Rename sprint command to plan: dispatch, registry, help page, planner script, reclaim deprecated plan shim

**Feature**: none
**Created**: 2026-07-28
**Depends on**: none
**Blocks**: 232, 233

## Problem

`./sprint.sh sprint` (the pipeline Plan step — pulls tasks from `backlog/` into
`next/`) stutters against the CLI's own name. We want `./sprint.sh plan`. This is
the **command-surface half** of the rename: dispatch, registry, help page, and the
planner script. It is NOT a simple add — **`plan` is already a live command name**:
it is currently a *deprecated shim* that forwards to `talk` (`cmd_plan` in
`sprint.sh`, `help/plan.md` = "plan has been folded into talk", listed in
`check-commands.sh`'s `HIDDEN` set). So this task must **reclaim** `plan` for the
planner and demote `sprint` to the hidden back-compat alias in its place.

Scope is deliberately narrow: only the *command word* changes. The noun "sprint"
(the board = `next/`), the CLI name `sprint.sh`, and the grouping (`newsprint` /
`docs/sprints/`, separately being renamed to "plan" in 228/229/230) are OUT of
scope and must not be touched.

## Success criteria

- [x] `./sprint.sh plan [count] [focus]` runs the planner (current `sprint` behavior)
- [x] `./sprint.sh sprint …` still works as a **hidden deprecated alias**, printing a one-line deprecation notice then running `plan` (mirrors the existing `find`/`triage` shim pattern)
- [x] The old `plan → talk` shim is gone; `plan` no longer routes to `talk` (verify `talk <id>` is still the documented path for single-task refine)
- [x] `./sprint.sh help` lists `plan` under the pipeline group (not `sprint`); `./sprint.sh help plan` shows the planner page
- [x] `./sprint.sh validate --commands` passes (all four surfaces agree)

## Notes

**The four surfaces that must move together** (per the command-catalog rule —
`validate --commands` enforces registry ↔ dispatch ↔ help ↔ manual):

1. `docs/sprintmd/help/_registry` line 27 — `sprint | pipeline | …` → `plan | pipeline | …`
2. `sprint.sh` (root dispatcher):
   - Rename `cmd_sprint()` → `cmd_plan()` (its body is `run_script "sprint.sh"` / `plan.sh` — see #4).
   - **Delete the existing deprecated `cmd_plan()` talk-shim** and repurpose the name.
   - Dispatch: `plan)` arm now routes to the real planner; add a hidden `sprint)` arm that warns + forwards to `cmd_plan` (back-compat).
3. `docs/sprintmd/help/sprint.md` → `docs/sprintmd/help/plan.md` — `git mv` and rewrite. **The current `plan.md` (deprecation note) is overwritten by this.** Update the usage examples inside (`./sprint.sh sprint …` → `./sprint.sh plan …`).
4. `docs/sprintmd/scripts/sprint.sh` (the planner script) → `git mv` to `plan.sh`; update `cmd_plan`'s `run_script` target and the script's own header comment (`# sprint.sh — Plan a sprint…`). Renaming also ends the confusing two-files-named-`sprint.sh` situation (root CLI vs planner). NOTE: `loop.sh` invokes this script by path (`bash "$SCRIPT_DIR/sprint.sh"`) — that call site is handled in **232**, so 232 depends on this rename landing.
5. `check-commands.sh` `HIDDEN=" plan find triage help "` → remove `plan`, add `sprint`; update the "deprecated cmd_plan is caught" comment to reference `cmd_sprint`/the new shim.

**Manual** (`DOCUMENTATION.md`) and all other cross-references are handled in **232**
to keep this task focused on the command surface. This task should leave
`validate --commands` green; **232** makes `validate --docs` green.

**Overlap watch:** task 230 retires the `docs/tmp/sprint-plan.md` cache the planner
writes. Don't retire it here — just don't rename the cache file as part of this
(leave `PLAN_FILE` alone; 230 owns it). Cross-link 230.

**Ship note (informational):** `ship.sh` uses `rsync -a --delete`, so the renamed
`plan.sh`/`plan.md` mirror and the stale `sprint.sh`/`sprint.md` prune from `src/`
automatically — no `ship.sh` manifest edit needed. Verified in **233**.

## References

sprint.sh
docs/sprintmd/help/_registry
docs/sprintmd/help/sprint.md
docs/sprintmd/help/plan.md
docs/sprintmd/scripts/sprint.sh
docs/sprintmd/scripts/check-commands.sh

## Questions

**Status: READY**

### Already complete
Nothing yet — none of the five surfaces have moved. Verified current state:
- `sprint.sh` still has `cmd_sprint()` (line 286, `run_script "sprint.sh"`) and the deprecated `cmd_plan()` talk-shim (lines 272–277); dispatch still has `plan) … cmd_plan` (385) and `sprint) … cmd_sprint` (387).
- `docs/sprintmd/help/_registry` line 27 still reads `sprint | pipeline | …`; no `plan` pipeline row.
- `docs/sprintmd/help/sprint.md` is the planner page; `docs/sprintmd/help/plan.md` is the "folded into talk" deprecation note.
- `docs/sprintmd/scripts/sprint.sh` is still the planner script (header `# sprint.sh — Plan a sprint…`); no `plan.sh` exists.
- `check-commands.sh` line 26 still `HIDDEN=" plan find triage help "`.

The task's description of the current code is accurate on every point.

### Remaining work
Execute all five surface moves exactly as written in the Notes:
1. Registry: swap the `sprint` pipeline row → `plan`.
2. `sprint.sh`: delete the talk-shim `cmd_plan()`; rename `cmd_sprint()` → `cmd_plan()` (retarget `run_script` to `plan.sh`); make `plan)` route to the planner; add a hidden `sprint)` arm that warns + forwards to `cmd_plan` (find/triage shim pattern).
3. `git mv` help/sprint.md → help/plan.md and rewrite its `./sprint.sh sprint …` examples to `plan` (overwrites the old plan.md deprecation note).
4. `git mv` scripts/sprint.sh → scripts/plan.sh; fix its header comment. (loop.sh's `bash "$SCRIPT_DIR/sprint.sh"` call site at line 187 is 232's job — 232 depends on this.)
5. `check-commands.sh`: `HIDDEN` → remove `plan`, add `sprint`; update the `cmd_plan`-caught comment to reference the new `cmd_sprint`/shim.

**One item the Notes under-specify — do it here, not in 232:** to leave `validate --commands` green (a stated success criterion), the §Commands line in `DOCUMENTATION.md` (line 130, `./sprint.sh sprint [count] [focus]`) must change to `./sprint.sh plan …`. `check-commands.sh` Check 4 greps the manual for every *registered* command (`grep "sprint\.sh plan"`), so the moment the registry lists `plan`, that line must already say `plan` or the validator fails. The manual is the fourth of "the four surfaces that must move together." Everything else in the manual (prose, other cross-refs) stays with 232.

### Questions for the developer
1. The Notes say "Manual … handled in 232," but `validate --commands` (a success criterion here) checks the manual §Commands listing. Should this task update the single §Commands line in `DOCUMENTATION.md` (line 130) and leave all other manual prose to 232? (Suggestion: yes — update only line 130 (`sprint` → `plan`) here, because Check 4 of check-commands.sh greps the manual for the registered `plan` command; deferring it entirely to 232 would leave `validate --commands` red the moment this task lands, breaking your own success criterion. Note the split in this task's audit trail so 232 doesn't re-touch line 130 and collide.)

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

## Completed

Reclaimed `plan` for the planner and demoted `sprint` to a hidden deprecated
alias across all four command surfaces + the manual §Commands line.

- **Registry** (`_registry` line 27): `sprint | pipeline …` → `plan | pipeline …`.
- **Dispatch** (`sprint.sh`): deleted the deprecated `cmd_plan()` talk-shim;
  renamed `cmd_sprint()` → `cmd_plan()` and retargeted its `run_script` to
  `plan.sh`; added a new hidden `cmd_sprint()` shim that warns
  (`sprint is now plan — running plan`) then forwards to `cmd_plan`. The
  `plan)` and `sprint)` case arms already pointed at those function names, so
  no dispatch-arm edit was needed.
- **Help page**: moved `help/sprint.md` → `help/plan.md` (overwriting the old
  "folded into talk" deprecation note); rewrote the four usage examples from
  `./sprint.sh sprint …` to `./sprint.sh plan …`.
- **Planner script**: moved `scripts/sprint.sh` → `scripts/plan.sh`; updated
  the header comment (`# plan.sh — Plan a sprint… See: ./sprint.sh help plan`).
  `PLAN_FILE` cache left untouched (owned by 230). loop.sh's
  `bash "$SCRIPT_DIR/sprint.sh"` call site left for 232.
- **check-commands.sh**: `HIDDEN` swapped `plan` → `sprint`; updated the
  "deprecated cmd_plan is caught" comment to reference `cmd_sprint`.
- **Manual** (`DOCUMENTATION.md` line 130): §Commands line `./sprint.sh sprint
  [count] [focus]` → `./sprint.sh plan …` (the one manual line Check 4 of
  check-commands.sh greps for the registered command; **232 owns all other
  manual prose/cross-refs and should not re-touch line 130**).

Files were untracked, so plain `mv` was used instead of `git mv`. `./sprint.sh
validate --commands` passes (26 commands, all four surfaces agree); `help`
lists `plan` under the pipeline group; `help plan` renders the planner page.
`talk` remains the documented single-task refine path. No `ship.sh` run (dev
verification only; ship/`validate --docs` handled downstream per 232/233).

### Files changed
docs/sprintmd/help/_registry
sprint.sh
docs/sprintmd/help/plan.md
docs/sprintmd/scripts/plan.sh
docs/sprintmd/scripts/check-commands.sh
DOCUMENTATION.md
docs/tasks/doing/231-rename-sprint-command-to-plan-dispatch-registry-he.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
