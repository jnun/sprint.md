# Task 269: Rename checkfeatures / ai-context / audit-deps → align / context / deps

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265
**Blocks**: 271, 272, 274
**Parent**: none

## Problem

Three look/keep commands still use noun-ish or profession-tinged names:
`checkfeatures`, `ai-context`, `audit-deps`. After #265 dispatch labels and
help basenames are already `align`, `context`, `deps`. This task finishes
scripts, help bodies, and every live old-name invocation.

## Success criteria

- [x] Help bodies for `align.md`, `context.md`, `deps.md` (basenames already from #265) use only the new command names (look/keep tools — not on the chat → plan start → work spine)
- [x] **Filename rule:** user-facing command name is the contract. Script basename matches when cheap:
  - `ai-context.sh` → `context.sh` (`git mv`); `cmd_context` → `context.sh`
  - `audit-deps.sh` → `deps.sh` (`git mv`); `cmd_deps` → `deps.sh`
  - `check-alignment.sh` **may stay** as the implementation file for `align` (update `cmd_align` to keep calling it). Optional `git mv` to `align.sh` only if one-line and no blast radius — not required
- [x] **Ownership:** every live `./sprint.sh checkfeatures|ai-context|audit-deps` under `docs/sprintmd/` becomes `./sprint.sh align|context|deps`
- [x] Drop "audit" from user-facing sprint.md command strings; ecosystem tools may still run as `npm audit` / `pip-audit` internally
- [x] `test-ai-context.sh` / `test-check-alignment.sh` updated or left for #272 if they only assert command names — prefer updating command assertions here when the test is about this rename
- [x] Behavior unchanged: `deps` still files one backlog task listing outdated/vulnerable packages

## Notes

- Help basenames were moved in #265; do not re-create old help filenames.
- Do not thrash on basename purity for `check-alignment.sh` — the live command is `align`.

## References

docs/sprintmd/scripts/check-alignment.sh
docs/sprintmd/scripts/ai-context.sh
docs/sprintmd/scripts/audit-deps.sh
docs/sprintmd/help/align.md
docs/sprintmd/help/context.md
docs/sprintmd/help/deps.md
docs/guides/command-matrix.md
sprint.sh

## Questions

**Status: READY**

### Already complete

Nothing in this task's scope is implemented yet — and that is expected, because
this task **depends on #265**, which has not run. The current tree is still fully
in the old world:

- `docs/sprintmd/help/_registry` rows 37–39 and 33 are still `checkfeatures`,
  `ai-context`, `audit-deps`.
- `sprint.sh` dispatch still has `cmd_checkfeatures`/`cmd_ai_context`/
  `cmd_audit_deps` calling `check-alignment.sh`/`ai-context.sh`/`audit-deps.sh`,
  and the `case` arms are still the old names.
- Help pages still carry the old basenames: `help/checkfeatures.md`,
  `help/ai-context.md`, `help/audit-deps.md` (no `align.md`/`context.md`/
  `deps.md` yet).
- Scripts still named `ai-context.sh`, `audit-deps.sh`, `check-alignment.sh`.

One convenient overlap worth noting: `audit-deps.sh` already keys its config off
`DEPS` (`sprintmd_resolve_model DEPS`, `SPRINTMD_BUDGET_DEPS`, `MODEL_DEPS`), and
the help body already documents `MODEL_DEPS=`. #270 renames only chat/work/gate
keys, so the deps config key needs **no** change — the behavior-unchanged
criterion is already satisfied on the config side.

### Remaining work

All of this is clear and executable once #265 lands (basenames + registry +
dispatch labels flipped to `align`/`context`/`deps`):

1. **Rewrite the three help bodies** (which #265 will have renamed to
   `align.md`, `context.md`, `deps.md`) so every `./sprint.sh …` invocation uses
   the new name. Concretely: `Usage: ./sprint.sh ai-context` → `context`,
   `./sprint.sh checkfeatures` → `align`, `./sprint.sh audit-deps` → `deps`, and
   drop "audit" from the command string in `deps` (the "Why these terms" and
   ecosystem tool names — `npm audit`, `pip-audit` — may stay).
2. **Rename scripts:** `git mv ai-context.sh context.sh`,
   `git mv audit-deps.sh deps.sh`; update each script's header comment
   (`# ai-context.sh — … help ai-context`, `See: ./sprint.sh help audit-deps`,
   and `check-alignment.sh`'s `help checkfeatures`). Point the #265-created
   `cmd_context`/`cmd_deps` at the renamed files (`run_script "context.sh"`,
   `run_script "deps.sh"`), and keep `cmd_align` calling `check-alignment.sh`
   (basename may stay — do not thrash on it).
3. **Fix the live invocation inside a help body:** `help/newplan.md:27` says
   "`./sprint.sh status` and `./sprint.sh ai-context` roll up each plan" — this
   is a user-facing invocation and must become `./sprint.sh context`.
4. **Update the two rename-affected tests** so they don't break on the script
   `git mv`: `test-ai-context.sh` (`SCRIPT_UNDER_TEST … /ai-context.sh` and its
   `cp`/`bash` paths) and `test-check-alignment.sh` reference the script
   *filenames*, so at minimum `test-ai-context.sh` must follow `context.sh`.
   (`check-alignment.sh` keeps its name, so `test-check-alignment.sh` may be left
   as-is.) Broader test/validator sweeps are #272's job.
5. Leave `./ship.sh` mirroring, `validate --commands/--docs`, and the manual/
   README/GETSTARTED sweep to their owning tasks (#273, #272, #271); a comment
   mention in `check-docs.sh:76` ("audit-deps ↔ --outdated") is historical, not a
   live invocation — #274's grep sweep can catch it.

### Questions for the developer

None — task is fully defined. The only gating item is sequencing: #265 must
reach review/ or done/ first (already recorded in **Depends on: 265**), after
which the task runner releases this automatically.

## Completed
- Renamed ai-context.sh→context.sh, audit-deps.sh→deps.sh
- cmd_* updated; help bodies use new names
- check-alignment.sh kept for align
