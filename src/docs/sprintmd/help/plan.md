STEP 1 of 3 — Sprint Planning

Scans docs/tasks/backlog/, reads the codebase to check
what's still relevant, and writes a sprint plan to docs/tmp/sprint-plan.md.

The plan includes:
  - Grouped tasks that form a coherent sprint
  - Tasks flagged as already done (move straight to review/)
  - Deferred tasks with reasons
  - Copy-paste shell commands to queue the sprint

Does NOT move any files. You review the plan first.

Usage:
  ./sprint.sh plan                  # plan ~5 tasks (default)
  ./sprint.sh plan 10               # plan ~10 tasks
  ./sprint.sh plan 5 "security"     # plan ~5 tasks focused on security
  ./sprint.sh plan 19 "parent:425"  # plan all children of task 425

The focus arg can be:
  - A keyword:    "security", "UI", "reports"
  - A parent ref: "parent:425" — finds all sub-tasks split from task 425

After running:
  1. Review docs/tmp/sprint-plan.md
  2. Approve the move when prompted (or run commands from the plan manually)
  3. Run ./sprint.sh define to review the queued tasks
