# Task 245: build plan start commit and retire the auto-planner

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/tmp/plan-command-redesign-notes.md
**Depends on**: 244
**Blocks**: 230

## Problem

Once a plan is authored (244), committing it must be instant, predictable, and
human-triggered — the deterministic checkpoint the AI authoring builds toward.
`plan start <id>` moves that plan's member tasks into `next/`, creating the
sprint. It is location-aware, not a blind move: members may already be in `next/`,
stuck in `blocked/`, or long past — so it acts per-location and surfaces anything
needing a human instead of failing or clobbering. Meanwhile the old auto-planner
(theme-guessing + auto-moving the first ~5 tasks + the `sprint-plan.md` cache) is
fully retired: autonomy survives only as executing human-authored intent.

## Success criteria

- [x] `plan start <id>` is **deterministic (no AI)** and location-aware. For each
      member task it resolves the ID against `docs/tasks/*/` and acts by where the
      task lives: in `backlog/` → move to `next/`; already in `next/` → leave it
      (idempotent, re-running is safe); in `blocked/` → stop with a notice to run
      `talk <id>` and re-run; in `doing/`/`review/`/`done/` → skip with a notice
      (already past `next/`); ID resolves to nothing → hard error (dangling
      member). Moves are filesystem `mv` — git is left to the developer.
- [x] Bare `plan start` shows a **picker**: a list of plans (ID + name, DRAFT/READY
      shown) so a human can choose which to start. Starting a `DRAFT` plan warns it
      is not marked `READY` before proceeding.
- [x] `loop --refill` calls `plan start` on the next `READY` plan instead of the
      auto-planner — autonomy now executes only human-authored plans.
- [x] The auto-planner is fully retired: no theme guessing, no auto-move of the
      first ~N tasks, and nothing writes `docs/tmp/sprint-plan.md` (task 230
      deletes the reader). All references to the old planner behavior are removed
      app-wide. (The deprecated `sprint` command is deleted outright by 241, per
      the matrix's Retired Names — not kept as a warning shim.)
- [x] The active plan is the system's missing high-level goal: wire the *cheap*
      part now — the active plan's goal is available to `loop` as run context.
      Deeper inheritance (`define`/`tasks`/`polish` reading the plan goal) stays a
      separate follow-up task, not folded in here. (Migrated from retired 229.)
- [x] Help page, `_registry`, dispatch, and manual updated; `validate --commands`
      passes; `./ship.sh --dry-run` clean; a fresh `./setup.sh` install runs
      `newplan` → `talk plan <id>` → `plan start <id>` end-to-end and moves the
      member tasks into `next/`.

## Notes

- **Location-aware, not blind**: the plan template already says members are
  resolved by ID wherever they live, so `plan start` reads current locations and
  routes rather than assuming `backlog/`. It never silently drops or overwrites a
  member — it reports which ones need a human and points to `talk <id>`.
- **Filesystem, not git**: moves use `mv`; the tool does not stage or commit. The
  developer owns all git operations.
- Coordinates with **task 230** (deletes the `sprint-plan.md` reader and derives
  the theme from `next/`). This task removes the *writer*; 230 removes the reader —
  keep them consistent. `next/` IS the sprint; nothing is cached.
- `READY` is the same marker tasks use — a plan is startable-by-autonomy only when
  `READY`. Interactive `plan start` can still start a `DRAFT` plan after warning.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer.

### Implementation notes (2026-07-29)

- New `plan-start.sh`: preflight all members (dangling=hard error, blocked=stop
  with no moves), then plain `mv` backlog→next.
- `plan.sh` is now a thin dispatcher (think/start/help); auto-planner body gone.
- `loop --refill` → lowest-id READY plan via `plan-start.sh`, then define;
  exports `FIVEDAY_ACTIVE_PLAN_{ID,FILE,GOAL}` for run context.
- Help/registry/manual/GETSTARTED/README/tasks.md updated.
- Smoke: `newplan` + READY + `plan start` moved task 249 backlog→next (restored).
- Reader of `docs/tmp/sprint-plan.md` remains in talk.sh until task 230.
- Shipped v0.0.14.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/plan.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/help/_registry
docs/plans/.TEMPLATE-plan.md
DOCUMENTATION.md

## Completed

### Files changed
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/plan.sh
docs/sprintmd/scripts/loop.sh
sprint.sh
docs/sprintmd/help/plan.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/tasks.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
GETSTARTED.md
README.md
docs/guides/command-matrix.md
src/sprint.sh
src/DOCUMENTATION.md
src/GETSTARTED.md
src/docs/sprintmd/scripts/plan-start.sh
src/docs/sprintmd/scripts/plan.sh
src/docs/sprintmd/scripts/loop.sh
src/docs/sprintmd/help/plan.md
src/docs/sprintmd/help/loop.md
src/docs/sprintmd/help/tasks.md
src/docs/sprintmd/help/_registry
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
