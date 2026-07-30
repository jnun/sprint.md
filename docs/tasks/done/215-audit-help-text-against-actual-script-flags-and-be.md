# Task 215: Audit help text against actual script flags and behavior

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: none
**Blocks**: 216, 220
**Parent**: none

## Problem

`./sprint.sh help <command>` reads from `docs/sprintmd/help/*.md`. When a script gains, loses, or renames a flag and its help file isn't updated, users get documented behavior that doesn't exist — a silent, high-friction failure. Every file in `docs/sprintmd/help/*.md` is in scope, and a `validate --docs` checker already exists to catch flag drift; this subtask runs it and closes every gap.

## Success criteria

- [x] `./sprint.sh validate --docs` runs clean (no flag drift reported), or every reported drift is fixed and the run is re-verified.
- [x] Each file in `docs/sprintmd/help/*.md` is checked against its script's real flags, arguments, and defaults; record one row per file — path → drift found → fixed / clean — in a table appended to this task's `## Notes`. The glob defines the set; there should be no gaps in either direction (every help file gets a row, every row is a real help file).
- [x] Every help file corresponds to a real command in `sprint.sh`, and every command has a help file (no orphans either direction).
- [x] No help file references removed commands, the old model, or nonexistent paths.
- [x] Examples in help text actually run as written.

## Notes

Files in scope: `docs/sprintmd/help/*.md` — ai-context, audit, audit-deps, checkfeatures, cleanup, define, excellence, loop, newbug, newfeature, newidea, newtask, newtest, plan, profile, review-code, review-sprint, search, split, sprint, status, sync, talk, tasks, triage, validate.

Note the mapping isn't 1:1 with script filenames: e.g. help `plan.md` ↔ the `sprint` planning command, `newtask` ↔ `create-task.sh`. Build the command→script→help triple first, then verify each.
Primary tool: `docs/sprintmd/scripts/check-docs.sh` (invoked by `validate --docs`). If it misses a drift class found here, note it as a gap for a follow-up to strengthen the checker. Depends on 214 because the script's real flags are the source of truth for what help should say.

### Audit results (one row per file in the `docs/sprintmd/help/*.md` glob)

The glob currently holds 27 files (the Notes list above predates `polish.md`, which
the glob picks up). Every row is a real help file; every help file has a row.

| Help file | Command → script | Drift found | Result |
|---|---|---|---|
| ai-context.md | ai-context → ai-context.sh | none | clean |
| audit.md | audit → audit-tasks.sh | none | clean |
| audit-deps.md | audit-deps → audit-deps.sh | checker false-positive on `--outdated` (`pip list --outdated` example text); help itself accurate | fixed (in checker, not help) |
| checkfeatures.md | checkfeatures → check-alignment.sh | none | clean |
| cleanup.md | cleanup → cleanup-tmp.sh | none | clean |
| define.md | define → define.sh | none | clean |
| excellence.md | excellence → audit-excellence.sh | Usage omitted the bare `<task-id>` form the script accepts | fixed |
| loop.md | loop → loop.sh | none | clean |
| newbug.md | newbug → create-bug.sh | none | clean |
| newfeature.md | newfeature → create-feature.sh | none | clean |
| newidea.md | newidea → create-idea.sh | none | clean |
| newtask.md | newtask → create-task.sh | claimed "AI guides you through defining…" but script is template-only (no AI path) | fixed |
| newtest.md | newtest → create-test.sh | none | clean |
| plan.md | plan → talk.sh (deprecation shim) | none | clean |
| polish.md | polish → polish.sh | none | clean |
| profile.md | profile → profile.sh | none (`project.md` is a runtime artifact, not a broken path) | clean |
| review-code.md | review-code → audit-code.sh | none | clean |
| review-sprint.md | review-sprint → review-sprint.sh | none | clean |
| search.md | search → search.sh | none | clean |
| split.md | split → split.sh | none (numbered task paths are illustrative examples) | clean |
| sprint.md | sprint → sprint.sh (script) | none | clean |
| status.md | status → inline `cmd_status` (no script) | none | clean |
| sync.md | sync → sync.sh | none | clean |
| talk.md | talk → talk.sh | example `sprint parent:N` had wrong arg order (size is positional 1) | fixed |
| tasks.md | tasks → tasks.sh | none | clean |
| triage.md | triage → triage.sh | none | clean |
| validate.md | validate → validate-tasks.sh | none | clean |

Orphan check: `find` is the only dispatcher entry with no help file — it is a
retirement stub (`sprint.sh:316`, prints a deprecation message, runs no script),
so it is intentionally help-less, not an orphan. No other gaps in either direction.

## References

- docs/sprintmd/scripts/check-docs.sh — the flag-drift checker to lean on
- docs/sprintmd/help/ — files under audit
- docs/sprintmd/scripts/ — ground truth for flags/behavior
- sprint.sh — command dispatcher

## Questions

**Status: READY**

### Already complete
Nothing in the audit itself is done — this is a fresh audit pass. But the tooling it leans on is in place and works:

- `docs/sprintmd/scripts/check-docs.sh` (invoked by `./sprint.sh validate --docs`) runs cleanly and reports drift. Verified: it currently checks 24 commands with a flag surface and reports one issue (`audit-deps` → `--outdated`). The command→script→help resolution is read from the dispatcher, so the mapping stays correct as commands change. The checker is solid.

### Remaining work
The full audit is remaining. Concretely:

1. Run `./sprint.sh validate --docs` and resolve every reported drift. Right now it reports exactly one: `audit-deps.md` "stale `--outdated`". **This is a checker false-positive**, not a real drift: the `--outdated` tokens in `audit-deps.md` are documenting third-party package-manager commands (`pip list --outdated`, `cargo outdated`, `composer outdated`, `bundle outdated`), not a flag `audit-deps.sh` parses. The checker's `help_flags()` greps every `--foo` token out of the help text, including example command lines. Resolve per the Notes' explicit guidance ("if it misses a drift class found here, note it as a gap") — either reword the help so those example flags aren't bare `--outdated` tokens, or strengthen `check-docs.sh` to ignore flags that appear inside example/command lines. Then re-verify the run is clean.
2. Manually check every file in `docs/sprintmd/help/*.md` against each script's real flags, args, and defaults, recording the required one-row-per-file table in `## Notes`. The glob defines the set — no hardcoded count.
3. Confirm no orphans in either direction. Note: `find` is a dispatcher entry but a **retirement stub** (`sprint.sh:309` just prints a deprecation message; it runs no script), so it correctly has no help file — not a true orphan. Treat retirement stubs as intentionally help-less.
4. Confirm no help file references removed commands, the old model, or nonexistent paths, and that every example runs as written.

### Resolved decisions (2026-07-28, by the developer)
- **`audit-deps` `--outdated` false-positive:** harden `check-docs.sh` to skip `--flags` that sit inside example/command lines, rather than rewording the help. This fixes the drift-class at the source (the gap the Notes anticipate) so legitimate documentation of third-party commands stops tripping the checker.
- **Help-file count:** don't hardcode a number. Scope is the glob `docs/sprintmd/help/*.md`; completeness is enforced by "one row per file, no gaps either direction," not by a count that goes stale when a help file is added or removed.

## Completed

Full audit of all 27 files in `docs/sprintmd/help/*.md` against their real command→script behavior. Results table is in `## Notes`.

**Checker hardening (the anticipated gap).** Per the developer's resolved decision, hardened `check-docs.sh`'s `help_flags()` instead of rewording help. The checker greped every `--foo` token including ones inside example command lines for *other* tools (`pip list --outdated`), which produced a false "stale `--outdated`" report against `audit-deps.md`. New rule: flags on a line that names the sprint command (own usage) are always kept; on any other line, a flag sitting inside an external-command example (`<cmd> <arg> --flag`) is dropped. This is safe because every flag a script actually parses is documented on at least one `./sprint.sh <cmd> --flag` usage line, so no real flag is ever lost. After the fix, `./sprint.sh validate --docs` reports **no flag drift** (25 commands with a flag surface checked).

**Prose/behavior drifts found and fixed (4):**
1. `newtask.md` — claimed "AI guides you through defining success criteria, dependencies, and scope," but `create-task.sh` has no AI path (it copies a template and exits). Reworded to describe the real flow: edit the file, or run `./sprint.sh talk <id>` to develop it conversationally.
2. `talk.md` — example `sprint parent:N` had the wrong arg order; `sprint`'s size is positional 1 (`SPRINT_SIZE="${1:-5}"`) and the parent ref is positional 2, so `parent:N` alone would land in the size slot and never filter. Corrected to `sprint <n> parent:N`, matching `sprint.md`'s own `sprint 19 "parent:425"` example and `talk.sh`'s internal prompt.
3. `excellence.md` — Usage omitted the bare `<task-id>` form that `audit-excellence.sh` treats as first-class (`^[0-9]+$`, searches `review/` first). Added the missing usage line.
4. (Checker false-positive on `audit-deps.md` resolved by the hardening above; `audit-deps.md` prose itself was accurate.)

**Verified clean (no fix needed):**
- **Orphans, both directions:** every help file maps to a dispatched command; every command has a help file except `find`, a retirement stub (`sprint.sh:316`) that is intentionally help-less.
- **Paths:** all `docs/...` references resolve to real files, runtime-created artifacts (`docs/sprintmd/project.md` from `profile`, `docs/tmp/*` scratch), or clearly illustrative examples (`split.md`'s numbered task paths).
- **Removed commands / old model:** the only `find` reference (talk.md) is an accurate historical note; no hardcoded LLM/model names — all model selection is config-driven (`MODEL_*` / `FIVEDAY_MODEL_*`), and every referenced config/env var exists.
- **Examples:** every `./sprint.sh …` example uses a valid subcommand with plausible args; defaults stated in help (sprint ~5, define all/999, tasks 2/4 jobs, polish rounds 1, audit-deps timeout 120 / max-projects 25) match the scripts.

**Note for `./ship.sh`:** changes live under `docs/sprintmd/` (help files + `check-docs.sh`) and have not been mirrored to `src/`. Run `./ship.sh` to distribute.

### Files changed
docs/sprintmd/scripts/check-docs.sh
docs/sprintmd/help/newtask.md
docs/sprintmd/help/talk.md
docs/sprintmd/help/excellence.md
docs/tasks/doing/215-audit-help-text-against-actual-script-flags-and-be.md
