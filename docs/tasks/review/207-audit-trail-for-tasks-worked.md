# Task 207: audit trail for tasks worked

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

When a task is worked, the list of files it touched isn't reliably recorded in
the task file — so excellence audits and reviews have to reconstruct it from git
history and diffs. The AI task runner already stamps a `### Files changed` list
under a `## Completed` section, and `fiveday_change_manifest` (lib.sh) already
consumes it, but that convention lives only inside a prompt string in tasks.sh.
A task worked by a human — or any worker not going through `./sprint.sh tasks` —
has nothing in the template prompting them to record it. The fix is to surface
the convention in the task template itself, so every finished task carries its
own audit trail regardless of who worked it.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify.
     The template edit (criteria 1–4 of the original scope) is DONE and
     verified — only the release mirror remains. -->

- [x] Run `./ship.sh` (user-invoked release step) so
      `src/docs/tasks/.TEMPLATE-task.md` becomes a byte-clean mirror of the live
      `docs/tasks/.TEMPLATE-task.md` and `src/VERSION` is bumped — this is the
      only thing standing between the change and users.

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

- **The `## Completed` heading is a control signal.** tasks.sh:406 uses
  `grep -q '^## Completed'` to decide a task is done and route it to `review/`.
  If the template ships a live `## Completed` heading, every new task would look
  finished. Keep the guidance as an HTML comment block so it never matches a
  start-of-line `^## Completed`.
- **Match the existing consumer's strings.** lib.sh:586-597 keys off the exact
  headings `## Completed` and `### Files changed`; the "prefer the author's own
  list" logic (lib.sh:589-597) only fires when the subsection heading matches.
  Reuse that wording verbatim in the guidance — don't invent a new label.
- **This is documentation of an existing convention, not new plumbing.** The
  capture (tasks.sh:234-236) and consumption (lib.sh:569-611) already exist and
  should not change. Scope is the template only.
- **Style:** `<!-- ... -->` guidance blocks are the established convention across
  ALL templates (task, bug, feature, idea, test) — every section teaches itself
  with one. Follow that style for the new guidance; it's both idiomatic and the
  only inert form (a live `## Completed` heading would trip tasks.sh:406).
- **Edit-live-then-ship:** edit `docs/tasks/.TEMPLATE-task.md` (the live copy
  `create-task.sh:57` reads), test with `./sprint.sh newtask`, then `./ship.sh`
  mirrors to `src/` and bumps the version. Do not hand-copy into `src/`.
- Optional, only if trivial: a one-line mention in `DOCUMENTATION.md` that a
  finished task should end with a `### Files changed` list. Leave out if it
  bloats scope — the template guidance is the core deliverable.

## Questions

**Status: READY**

No open questions — the task is fully defined. The template edit (original criteria 1–4) is done and verified; the only remaining work is the mechanical `./ship.sh` release step in the success criteria above.

## References

- docs/tasks/.TEMPLATE-task.md — the live template to edit (source of truth).
- src/docs/tasks/.TEMPLATE-task.md — distribution mirror; updated by ./ship.sh.
- docs/sprintmd/scripts/create-task.sh:57 — reads the live template on `newtask`.
- docs/sprintmd/scripts/tasks.sh:234-236 — runner prompt that already stamps the
  `### Files changed` list (wording to mirror).
- docs/sprintmd/scripts/tasks.sh:406 — `grep -q '^## Completed'` done-detector the
  template must not trip.
- docs/sprintmd/lib.sh:569-611 — `fiveday_change_manifest`, the consumer of the
  `### Files changed` list.

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Completed

Ran the release step (`./ship.sh`). The live `docs/tasks/.TEMPLATE-task.md`
(which already carried the `### Files changed` audit-trail guidance from the
earlier template edit) is now a byte-clean mirror at
`src/docs/tasks/.TEMPLATE-task.md`, verified with `diff`. `src/VERSION` bumped
0.0.3 → 0.0.4. ship.sh also swept three unrelated in-flight changes into `src/`
(`DOCUMENTATION.md`, `GETSTARTED.md`, and a new `docs/sprintmd/guides/sprint_command.md`
guide) — expected, since ship.sh mirrors whole trees and cannot ship a single
file. No source files were edited by this task; the template content was already
done and verified in a prior session.

### Files changed
docs/tasks/doing/207-audit-trail-for-tasks-worked.md
src/docs/tasks/.TEMPLATE-task.md
src/DOCUMENTATION.md
src/GETSTARTED.md
src/docs/sprintmd/guides/sprint_command.md
src/VERSION
src/sprint.sh
