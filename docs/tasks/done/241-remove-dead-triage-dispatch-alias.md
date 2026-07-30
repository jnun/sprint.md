# Task 241: remove the dead dispatch aliases (triage, sprint, find)

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

The dispatch table in `sprint.sh` still lists three legacy aliases — `triage`,
`sprint`, and `find` — left over from earlier renames. `triage` forwards to the
no-arg `talk` walk, `sprint` prints "sprint is now plan" and forwards to `plan`,
and `find` prints a retirement notice. None has a `_registry` row, script, or
help page — they are invisible commands that sidestep the four-surface agreement
`validate --commands` exists to enforce, and they are whitelisted in
`check-commands.sh`'s HIDDEN list to hide that fact. Per the matrix's **Retired
Names** (delete outright, no runtime redirect), remove all three from dispatch
and from the HIDDEN list so the dispatch table and the registry describe the
same command surface.

## Success criteria

- [x] `sprint.sh` has no `triage`, `sprint`, or `find` dispatch case; running
      `./sprint.sh triage`, `./sprint.sh sprint`, or `./sprint.sh find` gets the
      standard unknown-command response pointing at help.
- [x] The HIDDEN list in `docs/sprintmd/scripts/check-commands.sh` (currently
      ` sprint find triage help `) drops all three retired aliases, keeping only
      `help`.
- [x] A grep for the three alias dispatch cases across `sprint.sh`,
      `docs/sprintmd/`, and `DOCUMENTATION.md` finds no live command references —
      the concept word "sprint" in prose stays untouched; only the dispatch case
      and its shim function go.
- [x] `./sprint.sh validate --commands` passes; `./ship.sh --dry-run` clean
      (root `sprint.sh` is part of the mirror).

## Notes

- Successors, per the matrix Retired Names: `talk <folder>` (triage), `plan`
  (sprint), `talk <id>` / `tasks` (find). All three are dead code with nothing
  to migrate — a fresh install never knew these names, so no redirect is owed.
- Also delete the shim *functions* they call (`cmd_sprint`, `cmd_triage`, and
  the inline `find` notice), not only the case arms.
- Coordinate with **245**: 245 no longer keeps a `sprint` warning shim, so this
  task owns removing the `sprint` case outright.
- Standard dogfood: edit in place, `./ship.sh`; git left to the user.

## References

sprint.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/help/_registry
docs/guides/command-matrix.md

## Completed

### Files changed
sprint.sh
docs/sprintmd/scripts/check-commands.sh
src/sprint.sh
src/docs/sprintmd/scripts/check-commands.sh
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
