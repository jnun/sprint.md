Task Splitter — breaks large tasks into small, atomic sub-tasks.

Reads a task file, analyzes it against the codebase, and splits it
into discrete, singular tasks using ./sprint.sh newtask. The original
task is then deleted (replaced by its atomic children).

Rule: every task should be as simple as possible. One file change,
one endpoint, one component. If a task touches more than one area,
it should be multiple tasks.

Usage:
  ./sprint.sh split docs/tasks/backlog/10-enhance-work-order-system.md
  ./sprint.sh split docs/tasks/next/494-audit-service-log-upload.md

After running:
  - New atomic tasks are created in docs/tasks/backlog/
  - Dependency edges are healed automatically: each child's Depends on is
    made reciprocal (the other end lists it back), and the parent is folded
    into its first child so anything that depended on the parent follows it
    instead of a deleted id
  - Original task is deleted
  - Move the new tasks to next/ when ready to work them
