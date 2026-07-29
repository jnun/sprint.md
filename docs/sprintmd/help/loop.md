Continuous task runner — executes tasks from next/ in a resilient loop.

Wraps tasks to run one task at a time, each in a fresh CLI context.
Failures don't halt the run — blocked tasks are skipped and the loop
continues to the next task.

Usage:
  ./sprint.sh loop                       # drain next/
  ./sprint.sh loop --hours 2             # stop after 2 hours
  ./sprint.sh loop --max 10              # stop after 10 tasks
  ./sprint.sh loop --cooldown 30         # 30s pause between tasks
  ./sprint.sh loop --refill              # auto-sprint when next/ empties
  ./sprint.sh loop --refill 3            # refill with 3 tasks at a time
  ./sprint.sh loop --retry               # retry newly-blocked tasks once
  ./sprint.sh loop --refill --retry      # full autopilot

Other flags (--audit, --drift, --fast, etc.) are forwarded to tasks.

How it improves on tasks:
  - Fresh context window per task (no context pollution)
  - Failures don't stop the run
  - Recovers orphaned tasks from doing/ (interrupted runs)
  - Smart retry: re-queues tasks blocked during THIS run (once)
  - Auto-refill: plan + define from backlog when queue empties
  - Time-boxed execution with --hours
  - Cooldown between tasks to pace API usage

Composable with Claude Code's /loop for crash recovery:
  /loop ./sprint.sh loop --hours 2
