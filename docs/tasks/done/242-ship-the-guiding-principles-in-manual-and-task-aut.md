# Task 242: ship the guiding principles in manual and task authoring

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/tmp/plan-command-redesign-notes.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

The guiding principles (lean into agent bias, minimize context cost, common
language, positive-first instruction) live in the root `CLAUDE.md` — dev-only,
never ships. But the principles are product: the goal is to change how people
think about building with agents, and positive instruction as an AI powertool
is still not universally practiced — people and agents write prohibition-style
rule lists that prime LLMs into the very behavior they forbid. Ship the
principles through the two channels the framework owns: teach them in
`DOCUMENTATION.md`, and wire `docs/sprintmd/ai/task-creation.md` so every task
the tool authors is written positive-first — the principle becomes product
behavior, not just advice.

## Success criteria

- [x] `DOCUMENTATION.md` gains a short (≤ ~25 lines) "Guiding principles"
      section — the four lenses plus the tie-breaker (simple, clean, fast, common
      language, biased toward action) — written for users of the framework,
      adapted from the root `CLAUDE.md` wording.
- [x] `docs/sprintmd/ai/task-creation.md` instructs positive-first authoring:
      state the desired path as the rule; reserve a plain "never" for genuine
      invariants where the wrong action is costly. Checkable outcome: a task
      freshly authored via `./sprint.sh define` (or `talk`/`newtask`) contains no
      prohibition-style rule *list* — its Success criteria state the desired path.
- [x] Influence stays framework-shaped: no changes to the `src/CLAUDE.md` /
      `src/AGENTS.md` minimal pointers or to the installer's respect for
      user-owned instruction files.
- [x] `./ship.sh --dry-run` clean; a fresh `./setup.sh` install's manual shows
      the section.

## Notes

- Preserve the nuance (philosophy-home settlement, 2026-07-29 in the notes
  doc): **positive-first, not negation-banned**. Prohibition-shaped rule
  *lists* are the misfire; a lone, concrete "never" anchored to a genuine
  invariant works fine.
- Root `CLAUDE.md` stays canonical for developing sprint.md;
  `DOCUMENTATION.md` is the user-facing rendering. Keep it brief — context
  cost applies to the manual too.
- Standard dogfood: edit `DOCUMENTATION.md` and `docs/sprintmd/ai/`, test in
  place, `./ship.sh`; git left to the user.

## References

docs/tmp/plan-command-redesign-notes.md
CLAUDE.md
DOCUMENTATION.md
docs/sprintmd/ai/task-creation.md

## Completed

### Files changed
DOCUMENTATION.md
docs/sprintmd/ai/task-creation.md
src/DOCUMENTATION.md
src/docs/sprintmd/ai/task-creation.md
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
