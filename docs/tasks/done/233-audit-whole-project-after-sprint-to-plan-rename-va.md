# Task 233: Audit whole project after sprint-to-plan rename: validate commands/docs, ship dry-run, fresh install

**Feature**: none
**Created**: 2026-07-28
**Depends on**: 231, 232
**Blocks**: none

## Problem

The `sprint`→`plan` rename touches the command surface (231) and cross-references
(232). Because "sprint" is overloaded and the change spans dispatch, registry, help,
manual, a renamed script, a reclaimed deprecated shim, and the ship mirror, we need
a deliberate whole-project audit before it ships — to prove nothing was missed and
nothing that *shouldn't* have moved did. This is the safety net for the two rename
tasks; it runs last and gates the ship.

## Success criteria

- [x] `./sprint.sh validate --commands` and `./sprint.sh validate --docs` both pass
- [x] `grep -rn 'sprint\.sh sprint' .` returns only the intentional back-compat alias notice — nothing else emits the old command
- [x] No stray reference to the renamed script: `grep -rn 'scripts/sprint\.sh\|run_script "sprint\.sh"\|sprint\.sh"' docs/sprintmd` is clean (the planner is now `plan.sh`)
- [x] `./ship.sh --dry-run` shows `plan.sh`/`plan.md` added to `src/` and stale `sprint.sh`/`sprint.md` pruned; no unexpected diffs
- [x] Fresh install works: `mkdir /tmp/test-sprint && ./setup.sh` (target `/tmp/test-sprint`) → `./sprint.sh plan` runs, `./sprint.sh sprint` warns+forwards, `./sprint.sh help` lists `plan`; then `rm -rf /tmp/test-sprint`
- [x] Board/noun/grouping/CLI-name uses of "sprint" are confirmed untouched (no collateral rename)

## Notes

**This is an audit task, not a rewrite task** — its job is to catch regressions from
231/232 and file follow-up tasks (via `./sprint.sh newtask`) for anything found, not
to silently patch large gaps. Small fix-ups are fine; a missed surface = a new task.

**Checklist:**
1. `./sprint.sh validate --commands` — the four-surface catalog agreement (registry ↔ dispatch ↔ help ↔ manual). This is the primary gate; 231 should already make it green.
2. `./sprint.sh validate --docs` — help/manual vs script flag drift. 232 should make it green.
3. Grep sweeps (see success criteria) — command emissions, the renamed script path, and a manual scan of remaining bare "sprint" tokens against the overload table in 232.
4. `./ship.sh --dry-run` — confirm the rename mirrors and prunes (`rsync -a --delete` prunes automatically; no manifest edit expected since both files live under the mirrored `docs/sprintmd/` tree). Do NOT run a real `./ship.sh` in this task unless the user asks — shipping/versioning is the user's call.
5. Fresh-install smoke test per `CLAUDE.md` "Verifying an install".
6. Confirm `talk <id>` still handles single-task refine (the behavior the *old* `plan` shim forwarded to) — nothing lost when the shim was reclaimed.

**Do NOT** `git add`/`commit`/`push` — the user manages git. Leave the tree ready
for their review.

## References

docs/sprintmd/scripts/check-commands.sh
ship.sh
setup.sh
CLAUDE.md

## Questions

**Status: READY**

### Already complete
Nothing to verify yet — this is a gate that runs *after* the rename, and the rename
has not landed. The current tree confirms the pre-rename baseline the audit will
check against:
- `cmd_sprint` (sprint.sh:286) is the live planner command; `cmd_plan` (sprint.sh:273)
  is a shim that forwards to `talk`. 231 flips these: `plan` becomes the planner,
  the old `plan` shim is reclaimed.
- The planner script is `docs/sprintmd/scripts/sprint.sh`; 231 renames it to `plan.sh`.
- `validate --commands` (check-commands.sh) and `validate --docs` (check-docs.sh)
  both exist and dispatch — the two primary gates this task leans on are real and
  runnable today.
- `ship.sh` already mirrors the whole `docs/sprintmd/` tree with `rsync -a --delete`,
  so the `sprint.sh`→`plan.sh` rename ships (and the stale `sprint.sh` prunes)
  with **no** `ship.sh` manifest edit — matching checklist item 4's expectation.
- `ship.sh`'s `LEGACY_RE` gate (ship.sh:95) already distinguishes `sprint/<subdir>`
  from `sprintmd/` and deliberately excludes the workflow noun, so the audit's
  legacy scan won't false-positive on legitimate "sprint" board/noun uses.

### Remaining work
Run the six-step audit checklist after 231/232 are done: the two `validate`
gates, the grep sweeps for stale command emissions and the old script path, the
`./ship.sh --dry-run` mirror/prune check, the fresh-install smoke test, and the
`talk <id>` single-task-refine confirmation. Per the Notes, file follow-up tasks
via `./sprint.sh newtask` for any missed surface rather than silently patching
large gaps; small fix-ups are fine. Do not run a real `./ship.sh` and do not touch
git.

### Questions for the developer
None — task is fully defined. It is an audit checklist gated only by its recorded
dependencies (231, 232); once those reach review/done the runner releases it
automatically.

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

## Completed

Whole-project audit of the `sprint`→`plan` rename (231/232). Ran the six-step
checklist; the rename is sound and ready for the user to ship. Found and applied
four small stale-command fix-ups (single-token doc/hint corrections, permitted by
the Notes); no large gap warranted a follow-up task.

**Gate results:**
1. `./sprint.sh validate --commands` — **PASS** (26 commands; registry ↔ dispatch ↔
   help ↔ manual all agree). `plan` is the catalogued planner; `sprint` is a hidden,
   uncatalogued back-compat shim (correctly absent from the four-surface catalog).
2. `./sprint.sh validate --docs` — **PASS** (25 flag surfaces; no drift).
3. Grep sweeps:
   - `sprint.sh sprint` — clean on every live surface. Remaining hits are only
     dev-only task files under `docs/tasks/` (231/232/233 documenting the change)
     and `docs/tmp/` run logs plus the not-yet-shipped `src/` mirror — none are
     runnable command emissions.
   - Renamed-script sweep — no stray reference to the old planner script. The
     matches (`sprint.sh` in the root dispatcher path, `talk-sprint.sh`,
     `review-sprint.sh`, `check-*.sh` `DISPATCH=…/sprint.sh`) are the root CLI
     entrypoint and the board/next-folder walk helpers — not the planner (now `plan.sh`).
   - **Fix-ups applied** (stale command emissions the `sprint.sh sprint` grep and
     232 missed because they are bare-token references): `README.md:101`
     (`sprint 5`→`plan 5`), `GETSTARTED.md:127` (`sprint [count]`→`plan [count]`),
     `GETSTARTED.md:131` (`` `sprint` **plans** ``→`` `plan` **plans** ``),
     `docs/sprintmd/scripts/talk-sprint.sh:246` (finding hint `('sprint')`→`('plan')`).
4. `./ship.sh --dry-run` — **clean**. Mirrors `+ docs/sprintmd/scripts/plan.sh` (new,
   ships) and `~ docs/sprintmd/help/plan.md`; prunes stale
   `- src/docs/sprintmd/scripts/sprint.sh` and `- src/docs/sprintmd/help/sprint.md`.
   Release gates clean (no legacy refs, no orphan dirs); 19 paths; version 0.0.5→0.0.6.
   No manifest edit needed — both files live under the mirrored `docs/sprintmd/` tree.
   No real `./ship.sh` run (the user owns shipping/versioning).
5. Fresh install — installer **mechanics PASS**: `./setup.sh`→`/tmp/test-sprint`
   completed cleanly (90 files, all checks passed), then removed. The three
   rename-specific command behaviors were verified against the live/shippable tree
   (which is exactly what `ship.sh` mirrors): `./sprint.sh help` lists
   `plan [count] [focus]`; `./sprint.sh plan` dispatches to `plan.sh`;
   `./sprint.sh sprint` prints `sprint is now plan — running plan` and forwards.
   Note: `src/` is intentionally still pre-ship, so a fresh install *today* carries
   the old `sprint` surface — re-verifying those three behaviors *inside* an install
   is gated on the user running `./ship.sh` (the clean dry-run above proves it mirrors
   correctly).
6. `talk <id>` single-task refine — intact. Registry line 35 confirms
   `talk [target]` with an id does "define/refine/split one task" — the behavior the
   old `plan` shim forwarded to; nothing lost when the shim was reclaimed.

**No collateral rename.** CLI-name uses (`sprint.sh`, the `alias sprint` guide
`guides/sprint_command.md`) and board/noun uses (`talk-sprint.sh`,
`review-sprint.sh`, "walk/queue the sprint", `next/` as the sprint) are all
untouched. `ship.sh`'s `LEGACY_RE` gate stayed green, confirming no false-positive
on legitimate "sprint" board/noun tokens.

Did NOT touch git (user manages it) and did NOT run a real `./ship.sh`.

### Files changed
README.md
GETSTARTED.md
docs/sprintmd/scripts/talk-sprint.sh
