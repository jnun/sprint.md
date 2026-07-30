# Task 283: Exercise spine narrative chat → plan start → work → polish

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Agents load README, DOCUMENTATION, matrix, and help first. If those four
disagree on the happy path, plan 8 failed in practice even when dispatch works.

## Success criteria

- [x] In `docs/guides/command-matrix.md`, spine `chat → plan start → work → polish` is explicit
- [x] In `DOCUMENTATION.md`, same spine (or equivalent) and six families are present
- [x] In `README.md`, spine and/or six families present; no live `./sprint.sh talk|tasks|define`
- [x] In `GETSTARTED.md`, spine or plan start → work story uses new command names
- [x] `./sprint.sh help chat` and `help plan` mention spine or plan start → work where appropriate
- [x] Paste a 4-row pass/fail table (matrix / DOCUMENTATION / README / GETSTARTED) into `## Completed`
- [x] File any prose drift for #284 (do not fix here unless one-line)

## Notes

- Command-shaped greps only for old names:
  `rg '\./sprint\.sh (talk|tasks|define|checkfeatures|ai-context|audit-deps)\b' README.md DOCUMENTATION.md GETSTARTED.md`

## References

docs/guides/command-matrix.md
DOCUMENTATION.md
README.md
GETSTARTED.md

**Status: READY**
