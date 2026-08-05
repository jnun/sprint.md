# Task 341: Create learn demo for newplan command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

<!-- The problem as a short user story — who, what they can't do, why it
     matters. Loose Gherkin (Given/When/Then) is welcome, not required.
     2-5 sentences, plain English. -->



## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [ ]
- [ ]
- [ ]

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Plan Think

**Stub status:** empty template. Sharper draft proposed at end.

**Perspective check.**
- *Chief Platform Architect:* Plan authoring is already covered — the registry maps `plan → feature-plan` (S3), which shows fan-out *and* `plan think` *and* `plan start`. `newplan` is the quick-lane variant (#312). A dedicated demo overlaps the spine story and risks teaching a second, competing mental model of the same relational index.
- *Chief Experience Officer:* Grouping tasks into a "what's next" cycle is the payoff moment of planning, but S3 already delivers that emotional beat. A `newplan`-only demo would show the fast path in isolation, without the reasoning that makes it feel safe.

**Tension and resolution.** Agreement on cut. The distinction worth teaching is *quick-lane vs conversational* plan authoring — and that's a one-line beat, not a demo. Resolution: **fold the `newplan` quick-lane into the S3 plan story as an aside; drop the standalone demo.**

**Sharper rewrite (only if kept):** *Problem:* users don't know they can group known task IDs into a plan in one command. *Success:* S3 (or a short coda) shows `newplan <name> <task-id...>` producing a plan file, then hands to `plan think`.
