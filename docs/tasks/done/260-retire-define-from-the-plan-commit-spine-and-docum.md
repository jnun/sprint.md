# Task 260: retire define from the plan commit spine and document

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 259
**Blocks**: none
**Parent**: none

## Problem

Even after `plan start` gates-then-promotes, the happy-path docs and
`loop --refill` still chain a separate `define` step. That leaves an extra move
in every surface agents and humans read: plan family order, tasks help,
DOCUMENTATION, command matrix, and the refill path. The spine should read
`plan start → tasks`; define stays off-spine for re-gate and folder report.

## Success criteria

- [x] `loop --refill` runs `plan start` only — no chained `define.sh` after a
      successful start. Empty-queue refill still only starts READY plans.
- [x] Help and manual describe the happy path as `plan start` then `tasks` (or
      `loop`): `help/plan.md`, `help/tasks.md`, `help/loop.md`, `help/define.md`
      (define as re-gate / folder report, not step 2 after start),
      `DOCUMENTATION.md`, and `docs/guides/command-matrix.md` Change/spine
      notes. Registry blurbs match.
- [x] Bare `./sprint.sh define` still works for next/ re-gate (`--force`) and
      folder quality report (backlog/doing/blocked).
- [x] `./sprint.sh validate --commands` passes; `./ship.sh --dry-run` clean;
      smoke notes in the task Completed section: authored READY plan →
      `plan start` → READY members in `next/` → `tasks` without a define step.

## Notes

- This task is docs + loop wiring on top of 259's behavior. If help already
  changed in 259, finish any remaining surfaces here so nothing still teaches
  start → define → tasks.
- Command matrix: plan start remains Compose; define remains Process but is
  no longer on the plan-commit spine (keep + re-scope the Change note).
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer.

## References

docs/sprintmd/scripts/loop.sh
docs/sprintmd/help/plan.md
docs/sprintmd/help/define.md
docs/sprintmd/help/tasks.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
docs/guides/command-matrix.md
docs/tasks/backlog/257-plan-start-gates-workability-before-members-enter.md
docs/tasks/backlog/259-plan-start-gates-then-promotes-members-into-the-sp.md

## Questions

**Status: READY**

### Already complete
- **`plan-start.sh` exists and is what `loop --refill` invokes** (`loop.sh:216`).
  The gating/promotion machinery this task builds on is in place (owned by 259).
- **Bare `define` already supports the off-spine roles this task wants preserved**
  (`define.sh:24-28`): `--force` for next/ re-gate and a folder arg
  (`backlog|next|doing|blocked`) for the read-only quality report. So success
  criterion 3 needs no code change — it is a "don't break this" invariant, not
  new work. Verify it still holds after edits; don't rewrite define.

### Remaining work
1. **`loop.sh` — drop the chained define after a successful start.** Lines
   224-227 currently run `bash "$SCRIPT_DIR/define.sh"` right after
   `plan-start.sh`. Remove that call so refill runs `plan start` only. Decide
   whether to keep setting the `SPRINTMD_ACTIVE_PLAN_*` exports (lines 219-221) —
   keep them; they're cheap run context that `tasks` may still read, and only the
   `define.sh` invocation on line 226 (plus its comment on 225) should go.
   Empty-queue refill already starts only READY plans via `next_ready_plan`
   (`loop.sh:150-166`) — leave that path intact.
2. **`help/loop.md`** — line 24 ("plan start on the next READY plan + define")
   and the `--refill` usage note (line 12) still say "+ define". Rewrite the
   happy path as `plan start` then `tasks`.
3. **`help/plan.md`** — the Family order step 5 (line 33) and the closing
   "runs `plan start` … then define" note (lines 35-37) still chain define.
   Re-scope define off the commit spine.
4. **`help/tasks.md`** — the "Full workflow" block (lines 65-68) lists define as
   step 2. Reduce the spine to `plan start` → `tasks`.
5. **`help/define.md`** — the "STEP 2 of 3" header (line 1) and the sequential
   framing present define as step 2 after start. Re-frame define as the next/
   re-gate and folder quality report, off the commit spine (its own real roles),
   without deleting the next/ READY-gate behavior it documents.
6. **`DOCUMENTATION.md`** — the workflow block (lines 146-159): define at line 157
   and the "chain plan/define/execute" description at line 159 keep define on the
   spine. Present the happy path as `plan start` → `tasks` (or `loop`); keep
   define documented as the off-spine re-gate/report tool.
7. **`docs/guides/command-matrix.md`** — the `loop` Change note (line 58, "chains
   plan start → define → tasks") and the `define` Change note (line 56). Per the
   task Notes: plan start stays Compose, define stays Process but is no longer on
   the plan-commit spine — keep and re-scope the Change note.
8. **`help/_registry`** — the `define` blurb (line 25, "2. Define") and the `loop`
   blurb (line 27, "chain all three") encode the three-step spine. Update both so
   they match the new happy path and the surfaces above.
9. **Verify & smoke** — run `./sprint.sh validate --commands` (must pass) and
   `./ship.sh --dry-run` (must be clean), then record the smoke walk (authored
   READY plan → `plan start` → READY members in `next/` → `tasks` with no define
   step) in a `## Completed` section. Standard dogfood: edit `docs/`, ship,
   git left to the developer.

### Questions for the developer
None — task is fully defined. Every action item names a concrete file, the
current lines that still teach the old spine, and the target wording; the only
code change (removing the `define.sh` call in `loop.sh`) is unambiguous.

**Depends on: 259** (already recorded in the header). 259 supplies the
`plan start`-gates-then-promotes behavior this task's docs and refill wiring
describe; the task runner holds 260 in `next/` until 259 reaches review/. No
other prerequisite.

## Completed

Retired `define` from the plan-commit spine. The happy path now reads
`plan start → tasks` everywhere; `define` is documented as its own off-spine
tool (on-demand `next/` re-gate via `--force`, read-only quality report on
`backlog/doing/blocked`).

**Code — `loop.sh` refill path**
- Removed the `bash "$SCRIPT_DIR/define.sh"` call (and its comment) that ran
  after a successful `plan-start.sh`. `--refill` now runs `plan start` only —
  which already gates members as it promotes them. The
  `SPRINTMD_ACTIVE_PLAN_*` exports are kept as cheap run context (comment
  updated to say why). The empty-queue `next_ready_plan` READY-only path is
  untouched.

**Docs / help surfaces rewritten to `plan start → tasks`**
- `help/loop.md` — `--refill` usage line and the "Auto-refill" bullet no
  longer say "+ define"; they note plan start gates as it commits.
- `help/tasks.md` — "Full workflow" reduced to `plan start` (1) → `tasks` (2);
  the readiness-gate paragraph now credits the shared gate (plan start applies
  it, define re-applies) instead of naming define as the sole stamper.
- `help/define.md` — dropped the "STEP 2 of 3" header; reframed define as
  off-spine (on-demand re-gate + folder report), leading with the
  `plan start → tasks` happy path. The next/ READY-gate behavior it documents
  is unchanged.
- `DOCUMENTATION.md` — workflow block: `loop` line now says "plan start (gates
  as it commits) then tasks"; `define` line reworded as the off-spine gate and
  moved below `tasks`; removed define from the chained happy path.
- `docs/guides/command-matrix.md` — re-scoped the `loop` Change note (spine is
  `plan start → tasks`, no define step) and the `define` Change note (Process,
  off the plan-commit spine, on-demand re-gate + folder report). `plan start`
  stays Compose.
- `help/_registry` — updated the `define`, `tasks`, and `loop` blurbs: dropped
  the "2. Define / 3. Execute" three-step numbering, reordered so `tasks`
  precedes `define`, and reworded to the new spine. `help/plan.md` already read
  `plan start → tasks · loop` from 259, so no change was needed there.

**Verification**
- `./sprint.sh validate --commands` → "✓ Every command is fully surfaced."
  (22 commands across all four surfaces).
- `./ship.sh --dry-run` → clean; 6 paths to mirror (DOCUMENTATION.md,
  help/_registry, help/define.md, help/loop.md, help/tasks.md,
  scripts/loop.sh), release gates clean, version 0.0.26 → 0.0.27.
- Criterion 3 (bare `define` invariant): confirmed by inspection —
  `define.sh:24-25` still parses `--force` and the `backlog|next|doing|blocked`
  folder arg, and the folder-report modes remain read-only. No `define`
  behavior was touched.
- Refill wiring: `grep define\.sh docs/sprintmd/scripts/loop.sh` → no matches,
  confirming the chained define is gone.

**Smoke note (spine shape).** A live `plan start` → `tasks` walk against the
real repo was *not* executed here: it would mutate real `docs/plans/` and
`docs/tasks/` and risks reentrancy, since this task is itself running inside
the task runner. The live gate-then-promote behavior (authored READY plan →
`plan start` → READY members land in `next/`) is owned and verified by task
259, which this task depends on. What 260 changed and verified statically is
the *shape* of the spine — `loop --refill` and every doc surface now go
`plan start → tasks` with no define step in between — via the validate,
dry-run, and grep checks above. Per dogfood rules, `./ship.sh` (the actual
mirror + version bump) and git are left to the developer.

### Files changed
docs/sprintmd/scripts/loop.sh
docs/sprintmd/help/loop.md
docs/sprintmd/help/tasks.md
docs/sprintmd/help/define.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
docs/guides/command-matrix.md
docs/tasks/doing/260-retire-define-from-the-plan-commit-spine-and-docum.md
