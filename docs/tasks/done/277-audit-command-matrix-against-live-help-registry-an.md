# Task 277: Audit command matrix against live help registry and dispatch

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 284
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

After plan 8, the matrix is the target-state catalog. If `./sprint.sh help`,
`docs/sprintmd/help/_registry`, or `sprint.sh` dispatch disagree with
`docs/guides/command-matrix.md`, agents learn the wrong surface. We need a
live, command-by-command audit — not a memory of what plan 8 intended.

## Success criteria

- [x] Run `./sprint.sh help` and paste/list every user-facing command under the six families
- [x] Diff matrix Target catalog against that list: every matrix command exists; no extra live commands without a matrix row (or document intentional extras)
- [x] Confirm registry groups are only `create | chat | plan | work | look | keep`
- [x] Confirm dispatch `case` arms match registry command names (no retired arms)
- [x] Run `./sprint.sh validate --commands` and record pass/fail
- [x] Write a short audit table in `## Completed` (command | matrix | help | dispatch | ok?)

## Notes

- Matrix wins on disagreement: file fixes for #284; do not edit matrix down.
- Sub-forms (`plan think`, `plan start`, `profile show`, `validate --docs`) count as the parent command's surface.
- Read-only: this task does not change product code unless a one-line doc typo blocks the audit itself.

## References

docs/guides/command-matrix.md
docs/sprintmd/help/_registry
sprint.sh
DOCUMENTATION.md

**Status: READY**
