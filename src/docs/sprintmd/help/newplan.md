Create a plan in docs/plans/.

Usage:
  ./sprint.sh newplan "Method accuracy audit"
  ./sprint.sh newplan "Method accuracy audit" 213 214 215
  ./sprint.sh newplan "Method accuracy audit" 213-220

A plan is a **relational index, not a container.** It is one file —
`docs/plans/N-name.md` — that names a clump of related tasks and lists their
IDs. The tasks are never moved into it: each stays in its own lifecycle folder
(`backlog → next → doing → …`) and its progress is tracked there. A plan is
never counted or moved as a task; `docs/plans/` is a sibling of `docs/tasks/`,
not a lifecycle stage. New plans start with `**Status:** DRAFT`; flip to
`READY` when the plan is authored and safe for `plan start` / `loop --refill`.

The plan gets an auto-assigned ID from a dedicated `sprint_PLAN_ID` counter
in `docs/sprintmd/DOC_STATE.md` (bumped on creation, exactly like task and bug
IDs). Pass member task IDs as extra arguments — plain numbers and `N-M` ranges
both work. Omit them to pick interactively from `backlog/`: a plan is the
*defining period*, where you choose the tasks you want before work starts.

Member IDs are references only. Moving or working a member task needs no edit to
the plan file. To commit a plan into the sprint, run `./sprint.sh plan start <id>`
(or move its members `backlog/ → next/` with `git mv SRC DEST || mv SRC DEST`);
the plan file itself never moves.

`./sprint.sh status` and `./sprint.sh context` roll up each plan by
resolving its member IDs to their current folders — a live view of the clump's
progress without ever treating the plan file as a task.
