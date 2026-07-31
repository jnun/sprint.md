# Task 301: Add optional dual-provider live smoke protocol runner for Claude Code and Grok Build exec paths

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 300, 296, 297
**Blocks**: 302
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Unit tests and emit-matrix smoke never call a real AI CLI. Regressions in Grok
headless flags, Claude stream/JSON, auth, and true exec interactivity only show
up in manual dogfood. Plan 11 already tracks spine smoke (#296) and dual fresh
project (#297); we still need a **runnable optional harness** maintainers can
invoke when both CLIs are installed.

## Success criteria

- [ ] Protocol + runner (script under `docs/tests/` or `docs/guides/`) that can
      execute (or skip with clear reason) live checks for **both**
      `claude-code` and `grok-build`
- [ ] Covers at least: provider banner under real exec; one headless one-shot
      (e.g. polish or work with stub task); optional interactive chat skip if
      no TTY; emit detection notes when `GROK_AGENT` / `CLAUDECODE` set
- [ ] Default is **opt-in** (`LIVE_SMOKE=1` or `--live`) so CI/unit suite stays
      offline by default
- [ ] Records pass/fail/skip per step to stdout (and optional log under
      `docs/tmp/`)
- [ ] Aligns with checklists in #296 / #297 rather than inventing a third
      competing protocol
- [ ] Document how to run it in the test harness task (#302) or a short guide
      note

## Notes

- Prefer disposable sandbox project or throwaway tasks; never mutate
  production task state without a flag.
- Network and auth required; failures should say “auth/network” vs “product
  bug”.
- Depends on #296/#297 for the checklist content; this task is the **automation
  wrapper + opt-in runner**.

## References

docs/tasks/backlog/296-smoke-test-claude-proven-spine-under-grok-build.md
docs/tasks/backlog/297-dual-provider-smoke-protocol-on-a-fresh-project-fo.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tests/test-grok-provider.sh
