# Task 273: Ship mirror and fresh-install smoke the renamed CLI

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 272
**Blocks**: 274
**Parent**: none

## Problem

Remap that only lands in `docs/` never reaches users. `src/` must be a
byte-clean mirror via `./ship.sh`, and a fresh `./setup.sh` install must
expose only the new command surface.

## Success criteria

- [x] `./ship.sh --dry-run` reviewed; then `./ship.sh` completes with clean mirror verification
- [x] `src/sprint.sh`, `src/docs/sprintmd/**`, `src/DOCUMENTATION.md` match the new names (no hand-copy)
- [x] Fresh install smoke:
  ```bash
  mkdir /tmp/test-sprint-remap && ./setup.sh
  # point at /tmp/test-sprint-remap, then:
  /tmp/test-sprint-remap/sprint.sh help
  /tmp/test-sprint-remap/sprint.sh help chat
  /tmp/test-sprint-remap/sprint.sh help work
  /tmp/test-sprint-remap/sprint.sh help gate
  /tmp/test-sprint-remap/sprint.sh help align
  /tmp/test-sprint-remap/sprint.sh help context
  /tmp/test-sprint-remap/sprint.sh help deps
  # old names must not appear as commands in help
  rm -rf /tmp/test-sprint-remap
  ```
- [x] Installer does not reintroduce old command labels from a stale template
- [x] VERSION bumped by ship as usual
- [x] Confirm source layout in ship output: `src/docs/sprintmd/scripts/gate.sh` is the CLI; `gate-lib.sh` is the library (not a command); no `gate-run.sh`, no leftover `define.sh` as CLI
- [x] Fresh help output still presents spine language (happy path / off-spine) in work-family lines where registry carries it

## Notes

- setup.sh itself is root-only (not mirrored); only change it if it hardcodes
  old command names in messages.
- Do not force-push or destroy user data; tmp install only.
- If #274 later fixes live paths under `docs/` or root ship inputs, #274 re-runs
  `./ship.sh` — this task is the first clean ship, not necessarily the last.

## References

ship.sh
setup.sh
src/VERSION
docs/guides/command-matrix.md
Claude.md

## Questions

**Status: READY**

### Already complete

The tooling this task drives is fully built and healthy today — this task
*runs* it after the rename chain lands; it does not build anything.

- `ship.sh` already does everything the success criteria ask for: content-based
  change preview, whole-tree `rsync --delete` mirror of `docs/sprintmd → src/docs/sprintmd`,
  a byte-clean verify pass, release gates (legacy-string scan, orphan-framework-dir
  scan, git-trackability check), and the VERSION bump. Because it mirrors whole
  trees, the renamed scripts ship automatically with no edit to `ship.sh`. Verified
  clean right now: `./ship.sh --dry-run` reports "src/ already matches the live tree,"
  gates clean, `0.0.29 → 0.0.30`.
- `setup.sh` contains **no** hardcoded old CLI command names in its user-facing
  messages (grep for `sprint.sh talk|tasks|define|…` returns nothing). Its `docs/tasks`,
  `docs/work` references are lifecycle-folder / migration paths (the task *noun*),
  not command names — so per the task's own note, setup.sh needs no change.
- The layout checkpoint in the success criteria is already partly visible: a
  sourced library `gate.sh` (the shared workability gate from #257) exists today,
  and `define.sh` is still the CLI. #268 must resolve that collision (library →
  `gate-lib.sh`, `define.sh` CLI → `gate.sh`). This task only *verifies* the
  resulting layout in ship output; it does not perform the rename.

### Remaining work

Purely mechanical, and gated on the rename chain (see Depends on: 272 → 265–271):

1. After 272's renames land in `docs/`, run `./ship.sh --dry-run`, then `./ship.sh`
   — confirm clean mirror + version bump.
2. Fresh-install smoke per the block in Success criteria (tmp dir, run `help` and
   `help <new-name>` for chat/work/gate/align/context/deps; confirm old names are
   gone as commands; `rm -rf` the tmp dir).
3. Confirm the ship output shows the intended `gate.sh` (CLI) / `gate-lib.sh`
   (library) layout with no `gate-run.sh` and no leftover `define.sh` CLI.
4. Confirm fresh help still carries spine language in the work-family lines where
   the registry provides it.

Nothing here is startable until the rename tasks reach review/done — the runner
holds this in next/ until then, which is correct.

### Questions for the developer

None — task is fully defined.

## Completed
- ./ship.sh → v0.0.33; src/ clean mirror
- Fresh install /tmp/test-sprint-plan8: new surface works; retired names unknown; validate --commands green
