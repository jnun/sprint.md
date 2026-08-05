# Task 336: Audit entire codebase for residual sprint.md, sprintmd, and Sprint.md and confirm correct replacement with sprintbias across branding, instructions, and folder names

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

We rebranded the framework directory and symbol namespace from `sprintmd` to
`sprintbias` and the product brand from `sprint.md` to SprintBias. A large
mechanical sweep did the bulk of it, but a rename this wide can leave stragglers
in forms a first pass misses — prose casing (`Sprint.md`), the dotted brand
(`sprint.md`), relative or bare path forms, and generated/gitignored files. A
maintainer or a fresh installer must never hit a stale name that misbrands the
product or points at a folder that no longer exists.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [ ] Every occurrence of `sprintmd`, `sprint.md`, and `Sprint.md` in the repo is
      audited and classified as one of: correctly replaced with `sprintbias`/
      SprintBias, intentionally retained (documented back-compat), or a stray to
      fix — with the strays fixed.
- [ ] Branding reads SprintBias everywhere user-facing (README, manual,
      GETSTARTED, help text, CLI output, AI pointer files, `.github/` templates).
- [ ] Folder/path references resolve to `docs/sprintbias/` (and `src/docs/
      sprintbias/`) — no reference to the retired `docs/sprintmd/` on any live or
      distributable surface.
- [ ] Instructions/guidance (DOCUMENTATION.md, `ai/`, guides, CLAUDE.md/AGENTS.md
      pointers) name the current dir and brand.
- [ ] `docs/tests/test-no-stale-refs.sh` and `./ship.sh --dry-run` both pass; a
      fresh `setup.sh` install produces `docs/sprintbias/` with zero `sprintmd`
      leftovers.

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

- **Three distinct strings, different treatment**:
  - `sprintmd` (framework dir + `sprintmd_` function namespace) → `sprintbias` /
    `sprintbias_`. Should be fully gone from live surfaces.
  - `SPRINTMD_*` shell/env vars → `SPRINTBIAS_*`. **Deliberate exception**:
    `SPRINTMD_CLI` and `SPRINTMD_PROVIDER` are kept as documented back-compat
    fallbacks in `docs/sprintbias/lib.sh` (and named in the config comment) — do
    NOT flag those as strays.
  - `sprint.md` / `Sprint.md` (pre-rebrand product brand) → SprintBias, EXCEPT
    the intentional legacy-compat markers in `setup.sh`/`install.sh` (README
    pointer, gitignore header, version-stamp alternation, GitHub `sprint.md-*`
    issue tags) that must keep naming the old brand to upgrade existing installs.
- **Scan blind spots** the sweep already had to special-case: gitignored-but-
  shipped files (`src/CLAUDE.md`, `src/.cursorrules`, `src/.windsurfrules`,
  `src/AGENTS.md`, `src/.github/copilot-instructions.md`); relative/bare path
  forms (`../sprint/…`, tree-diagram `sprintmd/`); and case variants.
- **Historical narratives were intentionally left as-is** in `docs/tasks/`,
  `docs/ideas/`, `docs/features/`, `docs/bugs/`, `docs/plans/` (dev-internal
  record of past work, never shipped). Confirm this is still the desired policy;
  the audit should treat a hit there as expected, not a defect, unless it is a
  `.TEMPLATE-*` file (templates ship and must be current).
- **Known pre-existing, out-of-scope-for-the-rename items** surfaced while
  renaming (fix or spin out separately, don't conflate): `setup.sh` line ~810
  version-stamp `sed` uses `|` as both delimiter and alternation in
  `(SprintBias|sprint\.md)` and errors on BSD/macOS sed; and two WIP test
  failures (`test-command-matrix-smoke.sh`, `test-validate-tasks.sh`).
- Run the sweep case-insensitively to catch `Sprintmd`/`SPRINTMD` prose too, then
  classify. `docs/guides/command-matrix.md` is allowlisted in the stale-refs test
  for the retired-command table — verify it separately.

## References

docs/tests/test-no-stale-refs.sh
ship.sh
setup.sh
docs/sprintbias/lib.sh

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
-->
