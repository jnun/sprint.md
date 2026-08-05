# Task 342: Create learn demo for newtest command

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
- *Chief Platform Architect:* This one the Architect actually wants. `newtest` creates the test loops that gate `promote` (Tests green → `done/`). It's a real data-integrity concept: work isn't done until it's proven. Teaching the Tests→promote contract raises the reliability floor of every install.
- *Chief Experience Officer:* Watching a test loop get authored is dry — there's no user delight in "I wrote a verification." The concept matters but the raw command is the least cinematic thing in the create group.

**Tension and resolution.** Architect prizes the integrity lesson; CXO fears a boring demo. They meet in the middle: teach the *concept* where it has stakes and drama — inside the close-the-loop story (`work.py`/`promote`), where a task can't reach `done/` until its Tests pass. Resolution: **keep the Tests-gate lesson, but as a beat in the spine/close story, not a standalone `newtest` demo.**

**Sharper rewrite (only if kept):** *Problem:* users promote work that was never proven. *Success:* the close-the-loop demo shows a task with a failing Test held out of `done/`, then passing and closing — `newtest` named as the origin of that gate.
