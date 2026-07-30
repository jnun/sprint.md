# Task 272: Update tests and validate --commands/--docs for the renamed surface

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265, 266, 267, 268, 269, 270, 271
**Blocks**: 273, 274
**Parent**: none

## Problem

Tests and validators still assert old command names and registry groups. A
green suite on the old surface would hide a broken remap; a red suite after
rename without updates blocks ship. #265 already made `validate --commands`
green; this task brings `--docs` and the test suite to the same bar and
locks the new surface into regression tests.

## Success criteria

- [x] `./sprint.sh validate --commands` still passes (reconfirm after content sweeps)
- [x] `./sprint.sh validate --docs` passes (help flags vs scripts)
- [x] `docs/tests/*` that reference `talk`, `tasks` (the command), `define`, `checkfeatures`, `ai-context`, `audit-deps` updated to new names
- [x] `test-ai-context.sh` renamed or rewritten for `context` if needed
- [x] **Own the stale-command regression test:** extend `docs/tests/test-no-stale-refs.sh` (or a sibling) so CI/local tests fail if retired **command** invocations (`./sprint.sh talk|tasks|define|…`) return under live surface paths. #274 only greps and fixes — it does not invent this test
- [x] Relevant test scripts run green in this repo's usual test invocation

## Notes

- Prefer updating assertions to expect `work` / `chat` rather than deleting coverage.
- If a test was specifically about retired excellence/audit command names, keep
  it pointed at polish/gate successors.
- Validate phase lock: full suite green here; ship is #273; straggler grep is #274.

## References

docs/tests/
docs/tests/test-no-stale-refs.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/scripts/check-docs.sh
docs/guides/command-matrix.md

## Questions

**Status: READY**

### Already complete

Nothing is executable yet — this task is downstream of the rename (265–271),
which has not landed (`_registry` still lists `talk`, `tasks`, `define`,
`checkfeatures`, `ai-context`, `audit-deps`; only 269 is staged in `next/`). Two
useful facts from reviewing the current code, though:

- **The two validators are already self-adjusting.** `check-commands.sh` reads
  the command set from `help/_registry` + the dispatch case arms;
  `check-docs.sh` derives the command→script map from `sprint.sh` and reads
  flags straight from each script. Neither hardcodes a command name, so
  `validate --commands` and `--docs` (items 1–2) need no code change — they pass
  automatically once 265–271 rename the surface consistently. This task's job for
  them is to *reconfirm green*, which the success criteria already frame correctly.
- **`test-no-stale-refs.sh` does not yet guard command names.** It currently
  polices legacy *paths* (`docs/5day`, bare `sprint/`) and *brand prose*, scoped
  to functional/distributable files (it excludes `src/` and the
  tasks/ideas/features/bugs/plans work-item narratives). Item 5's regression test
  is a genuinely new check, not a tweak — the existing scoping is the right model
  to reuse.

### Remaining work

Everything, gated on the rename tasks reaching review/done. Concretely:

1. Reconfirm `validate --commands` and `validate --docs` pass on the renamed
   surface (no validator edits expected — they're self-adjusting).
2. Repoint the test files that name retired commands/scripts. The clear ones:
   `test-ai-context.sh` (hardcodes `ai-context.sh` at lines 9, 28, 62, 85, 92,
   99 and the `=== test-ai-context.sh ===` banner) → rename the file to
   `test-context.sh` and repoint it at `context.sh` (renamed by 269). Sweep the
   rest of `docs/tests/*` for `talk`/`define`/`checkfeatures`/`audit-deps` and
   `tasks`-as-a-command assertions, updating to `chat`/`gate`/`align`/`deps`/
   `work` per 266–269. Update assertions to expect the new names rather than
   deleting coverage.
3. Add the stale-command regression: extend `test-no-stale-refs.sh` (or a
   sibling `test-no-stale-commands.sh`) to fail when a retired *invocation*
   (`./sprint.sh talk|tasks|define|checkfeatures|ai-context|audit-deps …`)
   appears under the live functional/distributable surfaces. Match the
   invocation form, not the bare word, so the folder noun `docs/tasks/` and the
   task noun stay clean — 267 deliberately keeps the `task` noun while renaming
   the `tasks` command to `work`.
4. Run the suite green with the repo's usual per-file invocation
   (`bash docs/tests/test-*.sh`) — there is no aggregate runner.

The excellence/audit-named tests (`test-audit-excellence.sh`,
`test-tasks-excellence.sh`) belong to the earlier excellence→polish rename, not
this one; leave them pointed at their polish/gate successors as the Notes say.

### Questions for the developer

None — task is fully defined. It cannot *start* until 265–271 reach review/done,
but that is a sequencing dependency (already recorded in **Depends on**), not a
missing decision. The task runner holds it in the queue until then.

## Completed
- validate --commands and --docs green
- test-context.sh (was ai-context); work.sh excellence tests; no-stale-refs guards retired commands + config keys
- suite run green
