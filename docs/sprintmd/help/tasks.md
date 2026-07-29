STEP 3 of 3 — Task Execution

Picks up READY tasks from docs/tasks/next/ in order (by leading number)
and works each one in a fresh AI context window.

Readiness gate: only tasks that ./sprint.sh define has stamped with
'Status: READY' are executed. A headless run can't ask clarifying
questions, so unvetted tasks are skipped (left in next/) rather than
run half-understood. Override with --force.

Dependency-aware: a task's '**Depends on**:' prerequisites are honored
within a single run. A task waiting on another queued in the same pass
is held only until its prerequisite lands in review/, then released
automatically — so a chain (A→B→C) drains in one invocation instead of
needing one run per link. With --fast, independent tasks overlap while
dependents still wait their turn. A task whose dependency never lands
this pass (e.g. it sits in blocked/) stays in next/ and is reported.

For each ready task it:
  - Moves the task file to doing/
  - Reads the task, reads CLAUDE.md, makes all code changes
  - Streams progress live (one line per step); full event log in docs/tmp/
  - Checks off completed items, adds a ## Completed summary
  - Moves the task file to review/ (or blocked/ if it stopped short)
  - Stops on failure so you can inspect

There is no turn limit — the per-run budget cap (BUDGET_TASKS in
docs/sprintmd/config, default $5) is the only guardrail.

Does NOT commit. You review the changes and commit yourself.

Usage:
  ./sprint.sh tasks                  # run all ready tasks in next/
  ./sprint.sh tasks 3                # run at most 3 tasks
  ./sprint.sh tasks 1                # run just the next task
  ./sprint.sh tasks --force          # skip the readiness gate
  ./sprint.sh tasks --drift          # enable pre-task drift check
  ./sprint.sh tasks --audit          # enable post-task code audit
  ./sprint.sh tasks --excellence     # enable post-task excellence audit (after --audit)
  ./sprint.sh tasks --parallel       # run all tasks concurrently (2 jobs)
  ./sprint.sh tasks --fast           # shorthand for --parallel with 4 jobs
  ./sprint.sh tasks --jobs N         # run parallel with N concurrent jobs
  ./sprint.sh tasks --max            # no budget cap
  ./sprint.sh tasks --fast --max     # parallel (4 jobs), no budget cap
  ./sprint.sh tasks --assist         # interactive mode picker
  ./sprint.sh tasks --verbose        # stream full per-task event detail

Quality chain: --audit runs the correctness audit (review-code) on each task
that lands in review/; --excellence then runs the excellence audit after it
(excellence presumes correctness, so order matters). An excellence BLOCKER
verdict does NOT halt the queue — the task still routes to review/ with the
blocker recorded in its '## Excellence' section, and the end-of-run summary
counts how many blockers were found.

Inside an AI session (Claude Code, Cursor, …) tasks are dispatched to fresh
subagents in the current session. In a plain terminal they run via the CLI in
docs/sprintmd/config. Override per-run with an env prefix:
  FIVEDAY_CLI=codex ./sprint.sh tasks   # exec a specific CLI standalone
  FIVEDAY_MODE=emit ./sprint.sh tasks   # force prompt emit for any agent

Model selection is handled by docs/sprintmd/config — scripts no longer
hardcode model names. Set FIVEDAY_MODEL_TASKS in your environment or
config to override.

Full workflow:
  ./sprint.sh plan 5          # 1. plan sprint from backlog
  ./sprint.sh define          # 2. review & triage queued tasks
  ./sprint.sh tasks           # 3. execute the sprint
