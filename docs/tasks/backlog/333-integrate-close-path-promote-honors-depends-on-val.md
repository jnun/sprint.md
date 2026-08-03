# Task 333: Integrate the close path — promote honors Depends on, validate checks Tests, suite proves promote

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 328, 330
**Dependents**: 332
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

`promote` shipped as the test-gated `review/ → done/` hop, but it stands apart
from the graph the rest of plan 15 hardens. Three seams are open:

1. **`promote` ignores `Depends on`.** It closes a `review/` task on its
   **Tests** alone. A dependent can land in `done/` while its prerequisite is
   still open in `review/` — the exact "false green / disappeared prereq"
   reading plan 15 exists to kill, reappearing on the close side.
2. **`validate` never checks `Tests`.** It reciprocity-checks `Depends on` /
   `Dependents`, but a **Tests** path that is a typo, missing, or points outside
   `docs/tests/` is silent — the task simply never promotes, with no diagnosis.
   A hopeful path strands a task in `review/` forever (antifragile rule 6).
3. **`promote` has no suite test.** The one command that closes work is itself
   unproven by the suite it runs. It should dogfood: prove its own behavior in
   `docs/tests/`, then carry its own **Tests** path.

The completion path must read as **two gates, one lifecycle**:

- **`Depends on` gates `work`** — a task does not *run* until its prerequisites
  reach `review/` or `done/`.
- **`Tests` gates `promote`** — a task does not *close* until its suite scripts
  pass **and** its prerequisites are already closed.

## Success criteria

- [ ] `promote` closes in dependency order: a `review/` task whose **Depends
      on** prereq is not yet in `review/`/`done/` is held (not moved), with a
      reason line naming the open prereq and its stage — `Depends on` gates the
      close the same way it gates the run. Uses the #328 classify helper; a
      missing/folded prereq id is classified, never treated as satisfied.
- [ ] `validate` gains a **Tests**-field integrity pass (alongside the edge
      check): every non-`none` **Tests** path exists, lives under `docs/tests/`,
      and is a runnable script. Typo / missing / out-of-tree / non-executable
      each reported with the task id and the offending path. Report-only is
      fine; reads **Proven by** as legacy alias.
- [ ] `docs/tests/test-promote.sh` proves `promote` end-to-end with throwaway
      fixtures under a temp board: **Tests** green → `done/`; a failing test →
      stays in `review/`, run exits 1; `none`/missing → skipped, does not fail
      the run; out-of-tree path → held with guardrail message; **Proven by**
      alias still read; a task held by an open **Depends on** prereq → not
      moved; plan-retire hint fires when a plan's members all reach `done/`.
      Discovered by `run-all.sh`; no live AI.
- [ ] Once `test-promote.sh` is green, set this task's **Tests** to
      `docs/tests/test-promote.sh` — the close path closes itself.
- [ ] `promote` help, `validate` help, DOCUMENTATION.md, and
      `docs/guides/command-matrix.md` describe the two-gate completion path
      (Depends on → work, Tests → promote) in one consistent framing.
- [ ] `bash docs/tests/run-all.sh` and `./sprint.sh validate --commands` /
      `--docs` green after the changes.

## Notes

- Dependency-order close: iterate `review/` tasks; skip any whose open
  **Depends on** prereq still sits in `backlog/next/doing/blocked`. Re-runnable
  — a second pass closes newly-eligible dependents. Keep it a single pass with a
  clear held report; a chain closes over successive `promote` runs (a `--drain`
  loop is out of scope here).
- Reuse, don't reinvent: `promote.sh` already caches suite results and guards
  the `docs/tests/` prefix. The Depends-on gate should call the shared
  classify/stage helper from #328 / #330, not grow a private graph walk.
- `validate` Tests-integrity is pure shell, no AI — mirror the existing edge
  check's shape and output.
- Dogfood boundary: `test-promote.sh` builds its own fixtures and cleans them;
  it must not touch real `docs/tasks/`. Follow the temp-board pattern in
  `dep-glitch-matrix`.
- Antifragile: this closes rule 6 (proof or human) on the *tooling* side — a
  broken **Tests** path is now loud (validate), not a silent never-promote.

## References

docs/sprintmd/scripts/promote.sh
docs/sprintmd/help/promote.md
docs/sprintmd/scripts/validate-tasks.sh
docs/sprintmd/help/validate.md
docs/tests/run-all.sh
docs/tests/fixtures/dep-glitch-matrix/
docs/guides/command-matrix.md
docs/guides/running-tests.md
DOCUMENTATION.md
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Questions

**Status: READY**

### Remaining work

1. Add the Depends-on gate to `promote.sh` (dependency-order close via #328/#330
   helper).
2. Add the **Tests**-integrity pass to `validate-tasks.sh` + help.
3. Write `docs/tests/test-promote.sh`; discover via `run-all.sh`; set this
   task's **Tests** to it once green.
4. Land the two-gate framing in promote/validate help, DOCUMENTATION, and
   command-matrix.

### Questions for the developer

None — scope follows the plan 15 language contract and antifragile rules.
