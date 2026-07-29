STEP 2 of 3 — Task Definition Review

Reviews each task in docs/tasks/next/ against the current codebase.
For each task it:
  - Checks which action items are already done (and verifies quality)
  - Identifies remaining work
  - Asks clarifying questions with suggestions when decisions are needed
  - Writes a ## Questions section into the task file

Verdicts:
  READY   — task stays in next/, ready for execution
  BLOCKED — task moves to blocked/, needs developer answers first
  DONE    — task moves to review/, all work is already complete

Usage:
  ./sprint.sh define          # review all tasks in next/
  ./sprint.sh define 3        # review at most 3 tasks
  ./sprint.sh define 1        # review just the next task
  ./sprint.sh define --force  # re-review tasks already stamped READY

By default define skips tasks already stamped 'Status: READY' so you don't
re-pay to review the whole queue each run. --force re-reviews all of them.

After running:
  - READY tasks: run ./sprint.sh tasks to execute them
  - BLOCKED tasks: answer questions in the file, move back to next/
  - DONE tasks: verify in review/, then move to done/

Related commands (how they differ):
  define  — deep, per-task review of next/ that writes the ## Questions gate
            (Status: READY/BLOCKED/DONE) that ./sprint.sh tasks enforces. Use
            before running a sprint.
  audit   — fast, non-interactive bulk verdict pass over backlog/next/doing/
            blocked to clear out DONE/OUTDATED/UNDEFINED work. Use to keep the
            backlog clean, not to gate a sprint.
  triage  — the interactive form of audit: the AI assesses each task, you
            decide (work/define/kill/skip) one at a time.
