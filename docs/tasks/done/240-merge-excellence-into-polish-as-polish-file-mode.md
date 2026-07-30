# Task 240: consolidate excellence and review-code into polish

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

Three commands share one job — judge finished work against a higher bar than
"it runs": `polish` (sweeps `review/`, reopens tasks worth another pass),
`excellence <file>` (deep-judges one finished piece, files enhancement tasks),
and `review-code <file> [passes]` (audits a finished task's code diff, fixes
inline). Three names — and two discipline-baggage words, "excellence" and the
"review-" prefix — for one concept: post-work quality. Per the matrix, both fold
into the surviving name `polish`: bare `polish` keeps its sweep, `polish <file>`
deep-judges one piece, and the code-diff audit becomes a polish mode. The levers
stay distinct inside the one command; only the surface collapses.

## Success criteria

- [x] Bare `polish [limit] [--rounds N]` behavior is unchanged (sweeps
      `review/`, reopens tasks worth another pass).
- [x] `polish <file>` runs the deep single-piece judgment and files enhancement
      tasks to `backlog/` — the old `excellence` behavior. `audit-excellence.sh`
      folds into `polish.sh`; argument shape selects the mode (a bare number is a
      sweep limit, a bare path is the excellence deep judge).
- [x] The `review-code` code-diff audit (`audit-code.sh`: judge a finished
      task's changes and fix inline via its fixer/verifier loop) folds into
      `polish` as a distinct mode selected by `polish --code <file>` (bare path =
      excellence deep-judge; same path with `--code` = code-audit; `--rounds`/
      limit numbers stay sweep-only). `audit-code.sh` folds into `polish.sh`.
- [x] `excellence` and `review-code` are both removed from all four surfaces —
      `_registry`, the dispatch table in `sprint.sh`, help pages, and
      `DOCUMENTATION.md` — and `./sprint.sh validate --commands` passes.
- [x] Both protocols survive with callers repointed: the
      `docs/sprintmd/ai/audit-excellence.md` file drives `polish <file>`, and the
      inline code-audit prompts currently in `audit-code.sh` move into
      `polish.sh` intact behind `--code`. `ai/refine.md`'s prose mention of the
      excellence protocol stays accurate (it is prose, not a path link — nothing
      to re-resolve).
- [x] `./ship.sh --dry-run` clean; on a fresh `./setup.sh` install,
      `polish <file>` works and both `excellence` and `review-code` get the
      unknown-command message.

## Notes

- The three levers stay distinct inside the one command: **sweep** reopens
  (refine protocol), **judge-and-file** files separate enhancement tasks and
  never touches the work (excellence protocol), **code-audit** reviews a task's
  diff and may fix inline (review-code protocol). The merge is surface-level
  naming and dispatch, not a merge of the judgment protocols.
- Two discipline-baggage words leave with them — "excellence" and the "review-"
  prefix (matrix: professions we don't want the agent to adopt). `polish` is the
  plain survivor and THE post-work quality pass.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  user.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/audit-excellence.sh
docs/sprintmd/scripts/audit-code.sh
docs/sprintmd/ai/audit-excellence.md
docs/sprintmd/ai/refine.md
docs/sprintmd/help/excellence.md
docs/sprintmd/help/review-code.md
docs/sprintmd/help/_registry
DOCUMENTATION.md

## Completed

### Files changed
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/audit-excellence.sh
docs/sprintmd/scripts/audit-code.sh
docs/sprintmd/scripts/tasks.sh
docs/sprintmd/ai/audit-excellence.md
docs/sprintmd/help/polish.md
docs/sprintmd/help/excellence.md
docs/sprintmd/help/review-code.md
docs/sprintmd/help/tasks.md
docs/sprintmd/help/audit-deps.md
docs/sprintmd/help/_registry
docs/sprintmd/lib.sh
docs/tests/test-audit-code.sh
docs/tests/test-audit-excellence.sh
sprint.sh
DOCUMENTATION.md
README.md
docs/plans/2-command-matrix-redesign.md
src/VERSION
src/sprint.sh
src/DOCUMENTATION.md
src/docs/sprintmd/scripts/polish.sh
src/docs/sprintmd/scripts/audit-excellence.sh
src/docs/sprintmd/scripts/audit-code.sh
src/docs/sprintmd/scripts/tasks.sh
src/docs/sprintmd/ai/audit-excellence.md
src/docs/sprintmd/help/polish.md
src/docs/sprintmd/help/excellence.md
src/docs/sprintmd/help/review-code.md
src/docs/sprintmd/help/tasks.md
src/docs/sprintmd/help/audit-deps.md
src/docs/sprintmd/help/_registry
src/docs/sprintmd/lib.sh

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
