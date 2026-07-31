# Task 300: Add docs/tests command-matrix emit smoke covering all matrix commands with -g/-c and provider banner

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 299
**Blocks**: 301, 302
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Unit tests cover scripts in isolation with stubs. There is no checked-in test
that walks **every command in `docs/guides/command-matrix.md`**, proves leading
`-g` / `-c` are accepted, and asserts the provider banner on AI paths under
`SPRINTMD_MODE=emit`. Session dogfood already proved this once; without a
committed test it will rot.

## Success criteria

- [ ] New script under `docs/tests/` (e.g. `test-command-matrix-smoke.sh`) runs
      in a sandbox and needs **no network / no live CLI**
- [ ] Covers every matrix command (create / chat / plan / work / look / keep)
      plus polish modes (`sweep`, `--code`, file deep-judge) where cheap
- [ ] Asserts: `-g`/`-c` never “Unknown option”; AI paths print
      `▸ Provider: … (…-build) · mode: emit`; non-AI paths do **not** print it
- [ ] Intentional short-circuits documented in the test (e.g. healthy `chat`
      with zero findings, `plan start --commit-only`, empty `deps` tree)
- [ ] Fixtures seed templates, READY tasks, a plan for gate path, package.json
      for deps, hash-prefixed Depends on for chat-sprint findings
- [ ] Exit non-zero on any failure; printable summary counts

## Notes

- Reuse the 2026-07-30 session harness as the design (38 cases, sandbox + emit).
- Prefer one file over many; keep under ~2–3 minutes wall time.
- Does **not** replace live dual-provider smoke (#301 / #296 / #297).

## References

docs/guides/command-matrix.md
docs/tests/test-sprint.sh
docs/tests/test-grok-provider.sh
docs/sprintmd/lib.sh
sprint.sh
