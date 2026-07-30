# Task 268: Rename define command to gate

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265
**Blocks**: 270, 271, 272, 274
**Parent**: none

## Problem

User-facing `define` is the READY-gate / folder quality report, off the
plan-commit spine. After #265 the dispatch label and help basename are already
`gate`. Source layout must match: CLI file = `gate.sh`, shared library =
`gate-lib.sh`, so agents reading the tree see the same word as users type.

## Success criteria

- [x] **Collision-safe renames in this order:**
  1. `git mv docs/sprintmd/scripts/gate.sh` → `docs/sprintmd/scripts/gate-lib.sh`
  2. Every `source …/gate.sh` becomes `source …/gate-lib.sh` (`plan-start.sh`, the CLI body, any other sourcers)
  3. `git mv docs/sprintmd/scripts/define.sh` → `docs/sprintmd/scripts/gate.sh`
  4. `sprint.sh` `cmd_gate` → `run_script "gate.sh"` (replace temporary `define.sh` pointer from #265)
- [x] **`gate-lib.sh` is library only** — sourced, no shebang CLI entry assumed by dispatch, no registry row, never `run_script "gate-lib.sh"`
- [x] **`gate.sh` is the CLI** for `./sprint.sh gate` (former `define.sh` body; still sources `gate-lib.sh` for next/ READY mode)
- [x] Help is `help/gate.md` (basename already from #265); rewrite usage/body for `gate`, `gate --force`, `gate backlog`, … — label **off-spine** (happy path is `plan start → work`)
- [x] Every live `./sprint.sh define` under `docs/sprintmd/` becomes `./sprint.sh gate` — this task owns that old name
- [x] `plan start` still runs the workability gate and promotes members (sources `gate-lib.sh`)
- [x] `loop` / agent tips no longer place `define` on the happy path

## Notes

### Decision lock — source uniformity

| File | Role after this task |
|------|----------------------|
| `gate-lib.sh` | Sourced library (`sprintmd_gate_*`) — renamed from today's `gate.sh` |
| `gate.sh` | CLI entry for `./sprint.sh gate` — renamed from today's `define.sh` |
| `help/gate.md` | User help |

Do **not** invent `gate-run.sh`. Do **not** merge CLI into the library.
Do **not** leave the library named `gate.sh` while the CLI is something else.

English "define" in prose ("define the task") is fine; command references are not.

## References

docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/help/gate.md
docs/guides/command-matrix.md
sprint.sh

## Questions

**Status: READY**

### Already complete

Nothing in this task is implemented yet — every item is remaining. The current
tree confirms both the starting layout and the unmet #265 prerequisite:

- `docs/sprintmd/scripts/gate.sh` exists today as the **library** (`sprintmd_gate_*`
  functions, no shebang, header explicitly says "NOT a CLI command"). This is the
  file step 1 renames to `gate-lib.sh`. Verified correct and clean.
- `docs/sprintmd/scripts/define.sh` is the **CLI** (shebang, `set -euo pipefail`,
  arg parsing, two modes). This is the file step 3 renames to `gate.sh`.
- Both `define.sh:42` and `plan-start.sh:22` `source …/gate.sh` — these are the two
  sourcers step 2 must repoint to `gate-lib.sh` (grep confirms no others).
- #265 has **not** landed yet: `sprint.sh` still has `cmd_define` → `run_script
  "define.sh"` (line 288) and dispatch arm `define)` (357); help is still
  `define.md`; the registry row is still `define`. So there is nothing to undo —
  this task runs after 265 supplies the `gate` label, `help/gate.md` basename, and
  the temporary `define.sh` pointer that step 4 replaces.

### Remaining work

All success criteria are remaining, and all are clear to execute once 265 lands:

1. The four ordered, collision-safe renames as written (git mv gate.sh→gate-lib.sh;
   repoint the two sourcers; git mv define.sh→gate.sh; flip `sprint.sh` cmd to
   `run_script "gate.sh"`).
2. Fix `plan-start.sh:22` and the new `gate.sh` (ex-`define.sh`) source line to
   `gate-lib.sh`.
3. Repoint the live `./sprint.sh define` command strings this task owns:
   `loop.sh:277`, `tasks.sh:163`, and the usage/retry lines inside the renamed CLI
   (`define.sh:15`, `:438`). Also the CLI header comment `See: ./sprint.sh help
   define` (line 3).
4. Rewrite `help/gate.md` usage/body from `define …` to `gate …`, framed off-spine
   (happy path is `plan start → work`).
5. Update the user-visible surface text that names the command: the "Blocked by
   define review" string synthesized in `gate-lib.sh`
   (`_sprintmd_gate_ensure_blocked_section`, ~line 278) → "gate review".

Prose comments that say "define" for the *concept* (e.g. gate-lib.sh header,
task-creation/refine AI files) are fine to leave; the broad manual/AGENTS/guides
sweep is owned by 271 and the final grep-for-former-terms audit by 274.

**Depends on**: 265 (already recorded). This is a pure sequencing constraint — the
work is fully defined; it just can't start until 265 supplies the `gate` dispatch
label, `help/gate.md` basename, and temporary `define.sh` pointer. Blocks 270–272,
274 (recorded).

### Questions for the developer

1. Should the internal identifiers `SPRINTMD_GATE_KIND` default `"define"` (the log-file
   kind, passed as `sprintmd_gate_init define` in the CLI) and the model key
   `sprintmd_resolve_model DEFINE` be renamed here? (Suggestion: rename the cosmetic
   log-file KIND string to `"gate"` for tree consistency since it names the surface,
   but **leave `DEFINE`/`resolve_model` config keys alone** — task 270 owns the
   config MODEL/BUDGET key rename for chat/work/gate, and touching them here would
   collide with 270's scope and split that change across two tasks.)

## Completed

- [x] gate.sh (library) → gate-lib.sh; define.sh → gate.sh; sources repointed
- [x] cmd_gate → run_script "gate.sh"
- [x] help/gate.md rewritten off-spine
- [x] live ./sprint.sh define → gate under docs/sprintmd/
- [x] plan-start sources gate-lib.sh; gate CLI works; define unknown; validate --commands green
