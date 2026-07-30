# Task 238: Audit all uses of validate to decide what to remove or upgrade

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: 249
**Parent**: none

## Problem

`./sprint.sh validate` is really three checkers behind one command, and a quick
look suggests they don't all earn their keep. The default **task-file**
validation looks fast because it is shallow — it only checks presence of things
(`# Task N:`, `**Feature**`, `## Problem`, `## Success criteria`) that the task
template already guarantees for any file born from `create-task.sh`, and nothing
in the system gates on it running. The `--docs` and `--commands` sub-checkers,
by contrast, appear to catch real, recurring drift. Before touching anything we
need a careful audit of every use of `validate` to decide, per part, whether to
**remove it, keep it, or upgrade it** — rather than assuming.

## Success criteria

Done = **a task, or a group of tasks, that perfectly solves the problem** —
created via `./sprint.sh` and defined well enough to execute without re-deciding
anything. The audit is the means; the follow-up task(s) are the deliverable.

- [x] The audit output is one or more tasks created via `./sprint.sh` living in
      `docs/tasks/backlog/` (not just notes in this file) that, taken together,
      fully resolve the `validate` question — each with its own clear Problem,
      Success criteria, and scope.
- [x] Those task(s) collectively cover every part of `validate`: for each of the
      three checkers a decision is committed to and turned into work — **remove**,
      **keep as-is**, or **upgrade** — leaving no part unaddressed.
- [x] Nothing is left ambiguous for the implementer: any remove/rename task
      accounts for all 4 catalog surfaces (registry, dispatch, help, manual) and
      any upgrade task names the exact checks to add (the dependency/ID-integrity
      class that is NOT guaranteed upstream) vs. drop (template-redundant ones).
- [x] Every consumer of `validate` has been enumerated first so the task(s) are
      complete: the three registry rows, the dispatch table, `validate-tasks.sh`
      and its `--docs`/`--commands` delegations, `test-validate-tasks.sh`, and any
      CI/hook/script that invokes it (or a recorded finding that nothing does).
- [x] This task itself stays an audit — it decides and writes the follow-up
      task(s); it does not remove or rewrite `validate` code inline.

## Notes

**This task is an audit/decision, not an implementation.** Its output is a
verdict per part plus follow-up task(s); do not rip out or rewrite code here.

### Verdict (2026-07-29)

| Part | Decision | Follow-up |
|------|----------|-----------|
| Default task-file path (`validate-tasks.sh` lines 102–121) | **Upgrade** | **#249** — drop template-redundant checks; add title/filename ID match, duplicate-ID detection, Depends on / Blocks integrity |
| `--docs` → `check-docs.sh` | **Keep as-is** | Covered in #249 scope as "do not change" (no separate task) |
| `--commands` → `check-commands.sh` | **Keep as-is** | Covered in #249 scope as "do not change" |
| Rename to `check` | **No** | Command matrix keeps `validate` in Maintain; three modes stay under one verb |

**Why upgrade not remove the default path:** removing it would leave the command
as a thin flag router only. The integrity class (deps, duplicate IDs) is real
runtime risk that nothing else gates; upgrading the default path makes `validate`
earn its Keep cell in the matrix.

**Live verification of the keep decisions:**
- `./sprint.sh validate --docs` → clean (24 flag surfaces, no drift).
- `./sprint.sh validate --commands` → currently fails on a real partial-rebrand
  gap (`newplan` registered, help page missing) — proves the checker catches
  drift that ships without it. (Fixed by task 243, not here.)
- Default `./sprint.sh validate` → 26/26 "valid" with zero integrity insight.

### Consumers enumerated

| Consumer | Finding |
|----------|---------|
| `_registry` rows 45–47 | Three `validate` rows (default / --docs / --commands) |
| `sprint.sh` | `cmd_validate` → `run_script validate-tasks.sh` |
| `validate-tasks.sh` | Default path + `--fix`/`--dry-run` + exec to check-docs/check-commands |
| `check-docs.sh` / `check-commands.sh` | Delegates only; not called elsewhere |
| `help/validate.md` + `DOCUMENTATION.md` + `README.md` | User-facing docs |
| `docs/tests/test-validate-tasks.sh` | Unit tests for default path only |
| CI / hooks / other scripts | **None invoke validate.** `.github/workflows/sync-tasks-reusable.yml` prints a notice string only. No script shells to validate. |
| Human/agent gates | Done tasks use `--docs`/`--commands` as verification steps |

### Deliverable

- `docs/tasks/backlog/249-upgrade-validate-default-path-to-dependency-and-id.md`
  (**Status: READY**) — single implementation task covering upgrade of default
  path + explicit keep of the two sub-checkers + full catalog/test update map.

## References

docs/sprintmd/scripts/validate-tasks.sh
docs/sprintmd/scripts/check-docs.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/help/validate.md
docs/sprintmd/help/_registry
docs/tests/test-validate-tasks.sh
docs/tasks/.TEMPLATE-task.md
docs/sprintmd/lib.sh
docs/tasks/backlog/249-upgrade-validate-default-path-to-dependency-and-id.md
docs/guides/command-matrix.md

## Completed

### Files changed
docs/tasks/backlog/249-upgrade-validate-default-path-to-dependency-and-id.md
docs/sprintmd/DOC_STATE.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
