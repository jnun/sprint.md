# Task 237: Audit and rebrand all fiveday/5day naming to Sprint.md

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

The project was rebranded to Sprint.md, but the old `fiveday`/`5day` naming
survives throughout the codebase as a leftover pre-rebrand identifier prefix.
The shell library and scripts define and call ~28 `fiveday_*` functions (~350
call sites) and read ~40 `FIVEDAY_*` environment/variables, and a "five-day
change manifest" phrase lingers in the shipped task template. This is internal
inconsistency that confuses contributors and leaks the dead brand into
user-visible surfaces (env var names, config, docs). We need a full audit and a
coordinated rename to the Sprint.md brand.

## Success criteria

- [x] No `fiveday`, `5day`, `5-day`, or `five-day` remains in any **shipping or
      dev-tool** file — scripts, `lib.sh`, `cli/`, help, guides, `ai/`, the
      shipped `.TEMPLATE-task.md`, `setup.sh`, `README.md`,
      `DOCUMENTATION.md` — except any deliberately-kept back-compat alias, and
      except `ship.sh`'s `LEGACY_RE` `5day` mirror-guard patterns (they detect
      the old docs directory, not the symbol namespace, and must remain).
- [x] All `fiveday_*` functions are renamed to `sprintmd_*` and all `FIVEDAY_*`
      variables to `SPRINTMD_*`, with definitions and every call site updated
      together so nothing breaks.
- [x] `docs/` is edited and `src/` is updated **only** via `./ship.sh` (byte-clean
      mirror verifies) — `src/` is never hand-edited.
- [x] The full test suite under `docs/tests/` passes, and a fresh
      `./setup.sh` into a throwaway dir installs and runs cleanly.

## Notes

**Footprint (measured, `docs/` tree — `src/` mirrors it 1:1):**
- **`fiveday_*` functions** — ~28 distinct, ~350 call sites. Top: `fiveday_run`
  (50), `fiveday_ai_mode` (26), `fiveday_resolve_model` (22). Pure **internal
  namespace** — safe to rename wholesale as long as each definition and all its
  call sites move together. Not a user interface.
- **`FIVEDAY_*` vars** — ~40 distinct. Split into two classes:
  - *Internal* (`FIVEDAY_OS`, `FIVEDAY_CHANGED_FILES`, `FIVEDAY_MODE_CACHE`,
    `FIVEDAY_TIMEOUT_BIN`, regex holders, …) — rename freely.
  - *Public / user-settable* — documented and overridable by users, so renaming
    them is a **breaking change**: `FIVEDAY_CLI`, `FIVEDAY_MODE`,
    `FIVEDAY_PROVIDER`, `FIVEDAY_STREAM`, `FIVEDAY_RETRIES`, `FIVEDAY_RETRY_WAIT`,
    `FIVEDAY_ATTEMPT_TIMEOUT`, `FIVEDAY_BUDGET_*`, `FIVEDAY_AUDIT_MAX_PASSES`,
    `FIVEDAY_SKIP_DRIFT_CHECK`, `FIVEDAY_STAGES`, `FIVEDAY_MODEL_*`,
    `FIVEDAY_DEPS_*`, `FIVEDAY_CONFIG_FILE`.
- **Prose** — the only live `five-day` is "the five-day change manifest" in
  `docs/tasks/.TEMPLATE-task.md` (which ships). Fix the template source; the
  copies already baked into existing task files are historical.

**Settled decisions (2026-07-29):**
1. **New prefix — `sprintmd_*` for functions and `SPRINTMD_*` for vars.** Chosen
   over `sprint_*`/`SPRINT_*` to avoid the readability overlap with the `sprint`
   command / `sprint.sh`. Apply uniformly.
2. **Back-compat — clean hard rename**, no deprecation shim. These names are
   pre-release and not shipped to real users, so the public `FIVEDAY_*` vars
   (`FIVEDAY_CLI`, `FIVEDAY_MODE`, …) are renamed outright alongside the internal
   ones; there is no old→new alias to maintain.

**Execution constraints (house rules):**
- This is a **symbol rename, not a blind `sed`** — a global text replace across
  mixed definitions/call sites/strings will silently break dispatch. Rename per
  symbol (definition + all references), run tests between passes.
- `setup.sh` (27 matches) is edited **directly** — it is the installer and is not
  mirrored by ship. `ship.sh` has **no `fiveday_` symbols**; its only `5day` hits
  are the 5 `LEGACY_RE` mirror-guard patterns (`docs/5day`, `5day.sh`) that detect
  the **pre-rebrand docs directory** — leave them untouched, they are not the
  brand namespace. Everything under `docs/sprintmd/` follows edit-docs →
  `./ship.sh` → src.
- **Out of scope:** historical work items under `docs/tasks/` (review/ + other
  backlog task files). They record past work, never ship, and rewriting them
  adds noise. Only the shipped `.TEMPLATE-task.md` source is in scope.
- `docs/tests/test-no-stale-refs.sh` already guards against stale references —
  extend it to assert no `fiveday`/`5day` survives, so this can't regress.

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->
docs/sprintmd/lib.sh
docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/default.sh
docs/sprintmd/config
docs/tasks/.TEMPLATE-task.md
docs/tests/test-no-stale-refs.sh
setup.sh
ship.sh
README.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the five-day change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

## Questions

**Status: READY**

### Already complete
Nothing is implemented yet — the rename has not started. Verified against current
code: the old namespace is still fully live. `docs/sprintmd/lib.sh` holds 155
refs including the three highest-traffic definitions (`fiveday_resolve_model`
:174, `fiveday_ai_mode` :493, `fiveday_run` :541); `setup.sh` has 27; `README.md`
has 2 user-facing `FIVEDAY_CLI` refs; `.TEMPLATE-task.md` still carries the
"five-day change manifest" prose; `docs/sprintmd/config` has a `fiveday_ai_tier`
comment ref. The measured footprint in the Notes is accurate.

The out-of-scope carve-outs are correct as written: `ship.sh`'s 5 hits are all
`LEGACY_RE` / comment guards for the pre-rebrand `docs/5day` directory (not the
symbol namespace) and must stay; historical task files under `docs/tasks/` are
noise and are excluded.

### Remaining work
The whole task. It is a clean, well-scoped mechanical rename with both design
decisions settled (prefix `SPRINTMD_` for vars / `sprintmd_` for functions; hard
rename, no back-compat shim):
1. Per-symbol rename (definition + every call site together, tests between
   passes) of ~28 `fiveday_*` functions and ~40 `FIVEDAY_*` vars across
   `docs/sprintmd/` (lib.sh, scripts, cli/, help, guides, ai/, config), the
   shipped `.TEMPLATE-task.md`, and `README.md`.
2. Fix the "five-day change manifest" prose in `.TEMPLATE-task.md`.
3. Edit `setup.sh` directly (27 refs) — not mirrored by ship.
4. Extend `docs/tests/test-no-stale-refs.sh` to assert no `fiveday`/`FIVEDAY`
   symbol survives, and update its line-89 comment ("FIVEDAY_ env vars are
   intentionally retained") which is now false — that carve-out is being removed,
   while keeping the `docs/5day`/`5day.sh` path guards intact.
5. Run `./ship.sh` to mirror to `src/` (byte-clean), run `docs/tests/`, and do a
   throwaway `./setup.sh` install.

### Questions for the developer
1. This rename touches nearly every script, several of which sibling tasks
   rename, merge, or delete (240 merges excellence→polish, 241 removes dispatch
   aliases, 246 retires audit, 247 renames review-sprint). Should 237 be
   sequenced *after* those to avoid renaming symbols in files that are about to
   move or disappear? (Suggestion: yes — schedule 237 late in the sprint. It has
   no functional dependency on them (a developer could execute it today), so this
   stays READY with no `Depends on`, but running it last minimizes churn and
   avoids re-doing renames in consolidated files. Not a blocker either way, since
   the new stale-refs guard catches any regression the other tasks introduce.)

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Completed

### Files changed
README.md
setup.sh
docs/tasks/.TEMPLATE-task.md
docs/sprintmd/lib.sh
docs/sprintmd/config
docs/sprintmd/ai/provider-capabilities.md
docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/default.sh
docs/sprintmd/guides/use_talk.md
docs/sprintmd/help/audit-deps.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/polish.md
docs/sprintmd/help/tasks.md
docs/sprintmd/scripts/ai-context.sh
docs/sprintmd/scripts/audit-deps.sh
docs/sprintmd/scripts/check-alignment.sh
docs/sprintmd/scripts/create-bug.sh
docs/sprintmd/scripts/create-feature.sh
docs/sprintmd/scripts/create-idea.sh
docs/sprintmd/scripts/create-plan.sh
docs/sprintmd/scripts/create-task.sh
docs/sprintmd/scripts/create-test.sh
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/plan-think.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/profile.sh
docs/sprintmd/scripts/search.sh
docs/sprintmd/scripts/split.sh
docs/sprintmd/scripts/sync.sh
docs/sprintmd/scripts/talk-bugs.sh
docs/sprintmd/scripts/talk-folder.sh
docs/sprintmd/scripts/talk-plan.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/tasks.sh
docs/sprintmd/scripts/validate-tasks.sh
docs/tests/test-audit-code.sh
docs/tests/test-audit-excellence.sh
docs/tests/test-check-alignment.sh
docs/tests/test-create-feature.sh
docs/tests/test-create-idea.sh
docs/tests/test-no-stale-refs.sh
docs/tests/test-tasks-excellence.sh
src/VERSION
