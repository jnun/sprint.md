STEP 3 of 3 — Task Execution

Picks up READY tasks from docs/tasks/next/ in order (by leading number)
and works each one in a fresh AI context window.

Readiness gate: only tasks stamped 'Status: READY' are executed. The
stamp comes from the workability gate — every path into next/ (plan start,
chat folder commit, chat close-loop, polish REOPEN, loop --retry) runs that
gate; standalone `gate` re-applies it on demand. A headless run can't ask
clarifying questions, so unvetted tasks are skipped (left in next/) rather
than run half-understood. Override with --force.

Dependency-aware: a task's '**Depends on**:' prerequisites are honored
within a single run. A task waiting on another queued in the same pass
is held only until its prerequisite lands in review/, then released
automatically — so a chain (A→B→C) drains in one invocation instead of
needing one run per link. With --fast, independent tasks overlap while
dependents still wait their turn. A task whose dependency never lands
this pass (e.g. it sits in blocked/) stays in next/ and is reported.

For each ready task it:
  - Moves the task file to doing/ (`git mv SRC DEST || mv SRC DEST`)
  - Reads the task, reads CLAUDE.md, makes all code changes
  - Streams progress live (one line per step); full event log in docs/tmp/
  - Checks off completed items, adds a ## Completed summary
  - Moves the task file to review/ (or blocked/ if it stopped short)
  - Stops on failure so you can inspect

Lifecycle moves always try `git mv` first, then plain `mv` when the file is
not yet tracked. There is no turn limit — the per-run budget cap
(BUDGET_WORK in docs/sprintmd/config, default $5) is the only guardrail.

Does NOT commit. You review the changes and commit yourself.

Usage:
  ./sprint.sh work                  # run all ready tasks in next/
  ./sprint.sh work 3                # run at most 3 tasks
  ./sprint.sh work 1                # run just the next task
  ./sprint.sh work --force          # skip the readiness gate
  ./sprint.sh work --drift          # enable pre-task drift check
  ./sprint.sh work --audit          # enable post-task code audit (polish --code)
  ./sprint.sh work --excellence     # enable post-task deep-judge (polish <file>, after --audit)
  ./sprint.sh work --parallel       # run all tasks concurrently (2 jobs)
  ./sprint.sh work --fast           # shorthand for --parallel with 4 jobs
  ./sprint.sh work --jobs N         # run parallel with N concurrent jobs
  ./sprint.sh work --max            # no budget cap
  ./sprint.sh work --fast --max     # parallel (4 jobs), no budget cap
  ./sprint.sh work --assist         # interactive mode picker
  ./sprint.sh work --verbose        # stream full per-task event detail

Quality chain: --audit runs polish --code (correctness) on each task that
lands in review/; --excellence then runs polish <file> (deep-judge) after it
(deep-judge presumes correctness, so order matters). A deep-judge BLOCKER
verdict does NOT halt the queue — the task still routes to review/ with the
blocker recorded in its '## Excellence' section, and the end-of-run summary
counts how many blockers were found.

Inside an AI session (Claude Code, Grok Build, Cursor, …) tasks are dispatched
to fresh subagents in the current session. In a plain terminal they run via the
CLI in docs/sprintmd/config. Override the provider for one run with a leading
flag (does not rewrite config):
  ./sprint.sh -g work                   # Grok Build for this run
  ./sprint.sh -c work                   # Claude Code for this run
Or env prefixes:
  SPRINTMD_CLI=codex ./sprint.sh work   # exec a specific CLI standalone
  SPRINTMD_MODE=emit ./sprint.sh work   # force prompt emit for any agent

Model selection is handled by docs/sprintmd/config — scripts no longer
hardcode model names. Set SPRINTMD_MODEL_WORK in your environment or
config to override.

Full workflow:
  ./sprint.sh plan start <id> # 1. gate + commit a READY plan into next/
  ./sprint.sh work           # 2. execute the sprint (or ./sprint.sh loop)

plan start gates members as it promotes them, so the happy path is
plan start → work. Run gate only to re-gate next/ (--force) or to
get a read-only quality report on backlog/doing/blocked.

Naming: `work` is the verb — it executes the queue. A *task* is the noun —
a work item that lives in docs/tasks/ and moves through the lifecycle
folders (backlog → next → doing → review). You still create tasks with
`newtask`; `work` is what runs them.
