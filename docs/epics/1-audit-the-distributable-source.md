# Epic 1: Audit the distributable source

**Created**: 2026-07-28

> An epic is a **relational index, not a container.** It groups related tasks by
> listing their IDs. The tasks never move into this file — each stays in its own
> lifecycle folder (`backlog → next → doing → …`) and its progress is tracked
> there. An epic has no status and is never itself a task; it only names a clump
> of work and its intent. To "push this epic to next", move its member tasks
> `backlog/ → next/` — this file does not move.

## Goal

Prove that what sprint.md actually ships — the `src/` distribution and the
`setup.sh` installer — is correct, current, and matches the live development
tree, so a user's first install is never broken or out of date.

## Why

`src/` and `setup.sh` are the only things a user ever sees, yet they are the
easiest to let drift: help text, AI guidance, the mirror, and the installer's
own logic all diverge silently. Grouping these audits as one epic keeps that
whole surface honest as a unit.

## Member tasks

<!-- The tasks in this epic, by ID only — one "- #ID — short title" line each
     (checkboxes optional). These are references, not paths or statuses: resolve
     each ID against docs/tasks/*/ to see where the task currently lives. Moving
     or working a member task needs no edit here. -->

- #215 — Audit help text against actual script flags and behavior
- #216 — Audit AI guidance files for current pipeline and method
- #220 — Verify src mirror integrity and VERSION and purge cruft
- #221 — Make setup.sh already-installed detection robust and non-destructive
