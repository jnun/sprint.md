# Task 318: Decide and, if worthwhile, build a GitHub Pages landing site for SprintBias

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 14
**Depends on**: none
**Blocks**: none
**Parent**: none
**Refined**: 1
**Reworked**: 0

## Problem

SprintBias already has a live self-hosted website (sprintbias.com, linked from the README). Visibility work still reopens "should we also do GitHub Pages?" without a recorded answer. This task is a decide-only write-up that sets **no GitHub Pages** as the standing default: primary marketing/landing stays on the self-hosted site; the repo README remains the in-GitHub face. **No Pages site is built.** The deliverable is a short, durable decision (with reopen triggers) so Plan 14 and later readers stop reopening the question without a material change.

## Success criteria

- [ ] Task file gains a `## Decision` section that states **no GitHub Pages** as the **standing default** for SprintBias landing/marketing.
- [ ] Decision includes a short rationale (2–5 sentences): self-hosted site is live at sprintbias.com; README is the in-repo face; a Pages site would duplicate both without a clear extra job.
- [ ] Decision lists **reopen triggers** (material change only), e.g. self-hosting is retired or unaffordable, or we need a free static surface the live site cannot cover — not “we felt like a second homepage.”
- [ ] Decision names what owns the landing job today: **sprintbias.com** (public landing) + **README** (GitHub-facing pitch/install).
- [ ] No Pages scaffold, GitHub Actions Pages workflow, or `gh-pages` content is added under this task.
- [ ] Notes (or Decision) state that Plan 14 visibility continues via #319–#322 and the live site — not a new Pages project.

## Notes

- **Known:** Self-hosted website is already live (sprintbias.com). README links to it.
- **Scope:** Decide-only write-up. Intended outcome: **close the door on GitHub Pages** as standing default (not a multi-option research menu of mirror/redirect/docs host). No build under this task ID.
- **Firmness:** Standing default until something material changes. Reopen only on those triggers; do not re-litigate during normal Plan 14 execution.
- **Out of scope:** Building, scaffolding, or enabling GitHub Pages; changing sprintbias.com; rewriting the README (repo presentation may live in #322).
- Plan 14 siblings: #319 (copy), #320 (positioning), #321 (demos), #322 (GitHub repo hygiene). Those own findability and presentation; this task only settles the Pages question.
- Title still says “and if worthwhile, build…” for history/search; **work is decide-only** — ignore the build half.

## References

- README.md (links to sprintbias.com; current in-repo landing pitch)
- docs/plans/14-sprint-md-visibility.md (Plan 14 member set)
- https://sprintbias.com (live self-hosted site)

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

## Refine (round 1)

**Sharpened:** Scope is decide-only (no build): self-hosted sprintbias.com is already live, so GitHub Pages is a standing-default **no** with reopen triggers, not a multi-option research or scaffold task. Success criteria require a `## Decision` section in this file and explicitly forbid Pages workflows/content.

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
