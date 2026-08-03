# Task 9080: Umbrella canary: every glitch class

**Feature**: none
**Created**: 2026-08-01
**Docs**: none
**Depends on**: 9001, 9002, 9003, 9004, 9005, 9006, 9007, 9008, 9009, 9010, 9011, 9013, 9030, 9069
**Blocks**: none
**Parent**: none
**Plan**: 90
**Refined**: 0
**Reworked**: 0

## Problem

Synthetic fixture case for the dependency glitch matrix (Plan 15 / #332).
Title is the case name; do not implement product behavior from this file.

## Success criteria

- [ ] Fixture only — no product work

## Notes

Case id: 9080. Stage at seed time: next.
See docs/tests/fixtures/dep-glitch-matrix/MATRIX.md.

## Questions

**Status: READY**

## Notes
Single work prepass stress object. Expect a multi-line stage-aware hold
report after Plan 15 — not a single 'needs: 9001 9002 …' blob.
