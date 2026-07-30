# Task 249: Upgrade validate default path to dependency and ID integrity

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: none
**Parent**: 238

## Problem

`./sprint.sh validate` (no flags) only checks template-stamped fields — numeric
filename ID, `# Task N:` title, `**Feature**:`, a Problem-ish section, a Success
criteria-ish section. Every task born from `create-task.sh` passes by
construction, so the default path almost never fails, and nothing in CI or other
scripts invokes it automatically. Meanwhile the fields the runtime actually
parses — `**Depends on**` / `**Blocks**` — and real integrity failures (duplicate
IDs across folders, title ID ≠ filename ID) are never checked. The useful
sub-checkers (`--docs`, `--commands`) stay; the default path must become the
integrity gate that is *not* guaranteed upstream.

## Success criteria

- [x] Default `./sprint.sh validate` **drops** template-redundant presence checks
      (`**Feature**:`, `## Problem`-ish, `## Success criteria`-ish). Those are
      guaranteed by `.TEMPLATE-task.md` via `create-task.sh`; re-checking them
      is not the job.
- [x] Default path **adds** these integrity checks (report-only; no silent
      mutation unless `--fix` can do something safe — see Notes):
      1. **Numeric filename ID** (keep).
      2. **Title ID matches filename**: first line is `# Task N:` and `N` equals
         the filename's numeric ID.
      3. **No duplicate task IDs** across any stage under `docs/tasks/*/` (same
         `N-*.md` in two folders, or two files with the same `N-` prefix).
      4. **`**Depends on**` integrity**: each declared ID either resolves to
         exactly one task file somewhere under `docs/tasks/*/` *or* is treated
         as "archived/gone" only when the token is a bare number and no file
         exists — but **malformed tokens** (non-numeric junk that isn't
         `none`/`n/a`/`-`) are reported. Prefer reusing parse logic from
         `lib.sh:sprintmd_unmet_deps` rather than inventing a second parser.
      5. **`**Blocks**` integrity**: same parse/resolve rules as Depends on
         (field may be missing; `none` is fine).
- [x] **Do not** implement dependency-cycle detection in v1 (optional later) —
      scope stops at ID uniqueness + reference shape/resolution. Document that
      exclusion in Notes of the code or help if useful.
- [x] `--docs` and `--commands` are **unchanged in behavior** (still delegated
      from `validate-tasks.sh` to `check-docs.sh` / `check-commands.sh`). They
      stay under the `validate` command — no rename to `check`. The command
      matrix cell is Maintain / keep.
- [x] `--fix` / `--dry-run`: only retain auto-fix for things that remain
      auto-fixable after the upgrade (e.g. title-line ID mismatch → rewrite
      title to match filename). Do **not** invent fake Depends on / Blocks or
      invent sections. If no remaining fix is safe, drop `--fix` support and
      remove it from registry/help/manual (all four catalog surfaces).
- [x] Catalog surfaces stay consistent: `docs/sprintmd/help/_registry` (still
      three `validate` rows, default description updated), dispatch
      (`sprint.sh` — no change unless flags change), `help/validate.md`,
      `DOCUMENTATION.md` Commands line. README.md one-liner if it still says
      "against template".
- [x] `docs/tests/test-validate-tasks.sh` rewritten for the new checks (fixtures
      for: good file, title/filename ID mismatch, duplicate ID, bad Depends on
      token). Old template-presence tests removed.
- [x] `./sprint.sh validate`, `validate --docs`, `validate --commands` all exit
      cleanly on the live tree after the change (or only report real integrity
      issues that then get fixed in the same task). `./ship.sh --dry-run` clean.

## Notes

### Decisions from audit 238 (committed — do not re-litigate)

| Part | Decision | Rationale |
|------|----------|-----------|
| Default task-file path | **Upgrade** | Shallow checks are redundant; integrity class is what runtime needs |
| `--docs` (`check-docs.sh`) | **Keep as-is** | Catches real help↔script flag drift; used as gate in recent rename work |
| `--commands` (`check-commands.sh`) | **Keep as-is** | Four-surface catalog gate; currently catches real drift (e.g. `newplan` missing help during partial rebrand) |
| Rename to `check` | **No** | Command matrix: `validate` stays Maintain; three modes under one verb |

### Consumers enumerated (complete list — implementer touch map)

| Surface | Path / role |
|---------|-------------|
| Registry | `docs/sprintmd/help/_registry` lines 45–47 (3 rows) |
| Dispatch | `sprint.sh` `cmd_validate` → `validate-tasks.sh` |
| Default + flags | `docs/sprintmd/scripts/validate-tasks.sh` |
| Docs checker | `docs/sprintmd/scripts/check-docs.sh` (via `--docs`) — leave alone |
| Commands checker | `docs/sprintmd/scripts/check-commands.sh` (via `--commands`) — leave alone |
| Help | `docs/sprintmd/help/validate.md` |
| Manual | `DOCUMENTATION.md` §Commands |
| README | `README.md` (dev-facing; not shipped via setup, still update if wording is wrong) |
| Tests | `docs/tests/test-validate-tasks.sh` |
| CI / hooks | **None invoke validate.** `.github/workflows/sync-tasks-reusable.yml` only prints a notice string "structure validated" — not this command. No other script shells to validate. |
| Manual gates | Done tasks (215, 226, 231–233, …) document humans/agents running `--docs` / `--commands` as verification — keep those modes working |

### Implementation guidance

- Edit live under `docs/sprintmd/scripts/`, test with `./sprint.sh validate*`, then
  `./ship.sh`. Do not hand-copy into `src/`.
- Prefer extracting a small shared parse helper in `lib.sh` only if both
  `fiveday_unmet_deps` and validate need the same token list; otherwise call or
  mirror carefully to avoid two diverging parsers.
- `docs/plans/` is not a task stage — never treat plan files as task files.
- Exit non-zero when any integrity issue is found (same contract as today).

### Out of scope

- Rewriting `--docs` or `--commands` logic
- Wiring validate into CI (separate product decision)
- Cycle detection among Depends on edges
- Content quality of Problem/Success (that is `define` / `talk`, not validate)

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/validate-tasks.sh
docs/sprintmd/scripts/check-docs.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/lib.sh
docs/sprintmd/help/validate.md
docs/sprintmd/help/_registry
docs/tests/test-validate-tasks.sh
docs/tasks/.TEMPLATE-task.md
docs/tasks/doing/238-audit-all-uses-of-validate-to-decide-what-to-remov.md

## Questions

**Status: READY**

### Audit verdict summary (from 238)
- Default path: upgrade to ID + dependency integrity (this task).
- `--docs` / `--commands`: keep under `validate`, no behavior change.
- Packaging: stay named `validate` (Maintain family); do not invent `check`.

## Completed

### Files changed
docs/sprintmd/scripts/validate-tasks.sh
docs/sprintmd/lib.sh
docs/sprintmd/help/validate.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
README.md
docs/tests/test-validate-tasks.sh
src/docs/sprintmd/scripts/validate-tasks.sh
src/docs/sprintmd/lib.sh
src/docs/sprintmd/help/validate.md
src/docs/sprintmd/help/_registry
src/DOCUMENTATION.md
src/VERSION

## Refine (round 1)

**Why:** `validate --fix` breaks its own "exit non-zero when any integrity
issue is found" contract for a file that carries *both* a fixable title
mismatch and an unfixable issue. `validate-tasks.sh:287` decides the exit code
with `FIXED_FILES < INVALID_FILES`, but both counters are per-file: fixing the
title increments `FIXED_FILES` to equal `INVALID_FILES`, so the guard misses
the file, execution falls through to `validate-tasks.sh:297`, and the tool
prints "✅ All task files are valid!" and exits 0 while a malformed
`**Depends on**` token (or duplicate ID) still sits in the file. Reproduced: a
single `backlog/5-a.md` with title `# Task 99:` and `**Depends on**:
junk-token` → `--fix` fixes the title, reports all valid, exits 0. The default
(no-`--fix`) path is correct; only the `--fix` mixed-issue case is wrong.

**Improve:**
- [x] Fix the `--fix` exit/summary logic so validate returns non-zero and does
      **not** print "✅ All task files are valid!" whenever any integrity issue
      remains after fixes are applied. Track files that are still invalid after
      the fix attempt distinctly (e.g. re-derive a "remaining invalid" count or
      set a per-file "fully repaired" flag) rather than comparing
      `FIXED_FILES < INVALID_FILES`.
- [x] Add a regression test to `docs/tests/test-validate-tasks.sh`: a single
      task file with a fixable title-ID mismatch AND an unfixable issue
      (malformed `**Depends on**` token, or a duplicate ID), run with `--fix`;
      assert exit 1 and that the output does NOT contain "All task files are
      valid".
- [x] `./ship.sh` after the fix so `src/docs/sprintmd/scripts/validate-tasks.sh`
      mirrors the corrected logic; confirm `./ship.sh --dry-run` is clean and
      the full test suite still passes.

## Completed (Refine round 1)

Introduced a dedicated `REMAINING_INVALID` counter as the single source of
truth for the exit code, replacing the buggy `FIXED_FILES < INVALID_FILES`
comparison. In `validate_task`, a file is only "fully repaired" when the title
mismatch was its *sole* issue (`${#issues[@]} -eq 1`) and the fix succeeded;
any other coexisting issue (duplicate ID, malformed dependency token) keeps the
file counted in `REMAINING_INVALID`. The early-return paths (non-numeric
filename ID, missing file) now also increment `REMAINING_INVALID`. The final
exit block keys off `REMAINING_INVALID > 0` for both the non-zero exit and the
suppression of "✅ All task files are valid!".

Added Test 15 (mixed fixable title + malformed `**Depends on**` under `--fix`):
asserts exit 1, output does NOT contain "All task files are valid", and still
reports the malformed token. Full suite: 30 passed, 0 failed. `validate` clean
on the live tree; `./ship.sh` ran clean (v0.0.22 → 0.0.23), src/ verified a
byte-clean mirror.

### Files changed
docs/sprintmd/scripts/validate-tasks.sh
docs/tests/test-validate-tasks.sh
src/docs/sprintmd/scripts/validate-tasks.sh
src/VERSION
