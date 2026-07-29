Create an epic in docs/epics/.

Usage:
  ./sprint.sh newepic "Method accuracy audit"
  ./sprint.sh newepic "Method accuracy audit" 213 214 215
  ./sprint.sh newepic "Method accuracy audit" 213-220

An epic is a **relational index, not a container.** It is one file —
`docs/epics/N-name.md` — that names a clump of related tasks and lists their
IDs. The tasks are never moved into it: each stays in its own lifecycle folder
(`backlog → next → doing → …`) and its progress is tracked there. An epic has
no status and is never counted or moved as a task; `docs/epics/` is a sibling
of `docs/tasks/`, not a lifecycle stage.

The epic gets an auto-assigned ID from a dedicated `sprint_EPIC_ID` counter
in `docs/sprintmd/DOC_STATE.md` (bumped on creation, exactly like task and bug
IDs). Pass member task IDs as extra arguments — plain numbers and `N-M` ranges
both work. Omit them to pick interactively from `backlog/`: an epic is the
*defining period*, where you choose the tasks you want before work starts.

Member IDs are references only. Moving or working a member task needs no edit to
the epic file. To "push an epic to next", move its member tasks
`backlog/ → next/` with `git mv`; the epic file itself never moves.

`./sprint.sh status` and `./sprint.sh ai-context` roll up each epic by
resolving its member IDs to their current folders — a live view of the clump's
progress without ever treating the epic file as a task.
