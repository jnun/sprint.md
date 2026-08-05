# Plan 16: 2026-08-03 correct all file drift

**Created**: 2026-08-03
**Status:** DRAFT

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Goal

To facilitate creating work chunks, we plan a group of tasks that may be relational
based on their theme or perhaps even unrelated. The end result is to create a sprint
or a "up next" group of work to be handled in a work cycle. We are agnostic about the
size of that work cycle or its timeline. The goal is simply to ensure the tasks are
well defined, actionable, non conflicting, and dependencies are executed in the order
that works.

## Why

Our core value is to ship code fast! Grouping work that is well defined does that.

## Member tasks

<!-- The tasks in this plan, by ID only — one "- #ID — short title" line each
     (checkboxes optional; [x] means the task is in docs/tasks/done/). These are
     references, not paths: resolve each ID against docs/tasks/*/ for location.
     Moving a member needs no edit here unless syncing checkboxes. -->

- #337 — Audit and correct all Plan reverse-index drift
