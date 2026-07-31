# Task 302: Add a docs/tests run-all harness and document how to run unit vs emit-smoke vs live dual-provider tiers

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 299, 300
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

There is no single entry point for the platform test suite. Maintainers run
individual `docs/tests/test-*.sh` files by hand, so green confidence is uneven
and tiers (offline unit, emit matrix, live dual-provider) are not named. New
contributors cannot see “what good looks like” without reading every script
header.

## Success criteria

- [ ] `docs/tests/run-all.sh` (or equivalent) runs all offline unit tests by
      default, prints per-script pass/fail, exits non-zero if any fail
- [ ] Flags or env for tiers, e.g. default unit only; `--emit` / `EMIT_SMOKE=1`
      for matrix smoke (#300); `--live` / `LIVE_SMOKE=1` for dual-provider
      (#301) when present
- [ ] Short doc: either `docs/tests/README.md` (dev-only OK) or a section in
      CONTRIBUTING.md describing the three tiers and what each proves
- [ ] Does not ship the harness into user installs as product UI (dev suite
      only; stay under `docs/tests/` which users use for *their* test loops —
      name carefully so it does not collide with `.TEMPLATE-test.md` product)
- [ ] After #299, default unit run is green on clean tree

## Notes

- Product `docs/tests/` holds user test-loop files; the harness should only
  execute `test-*.sh` (or a `suite/` subfolder if we need isolation later).
- Keep run-all free of network unless `--live`.
- Optional: list scripts in explicit order so create → plan → work deps read
  cleanly in logs.

## References

docs/tests/
CONTRIBUTING.md
docs/tasks/backlog/299-fix-test-no-stale-refs-so-setup-migration-comments.md
docs/tasks/backlog/300-add-docs-tests-command-matrix-emit-smoke-covering.md
docs/tasks/backlog/301-add-optional-dual-provider-live-smoke-protocol-run.md
