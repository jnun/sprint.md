Create a new task in docs/tasks/backlog/.

Usage:
  ./sprint.sh newtask "Add login endpoint"
  ./sprint.sh newtask "Add login endpoint" user-auth

Pass an optional feature name as the second argument to set the task's
**Feature** field to /docs/features/<name>.md.

Tasks get an auto-assigned ID and are built from a battle-tested
template. The file is created ready to edit — fill in the problem and
success criteria yourself, or run `./sprint.sh chat <id>` to develop the
scope, criteria, and dependencies conversationally.
