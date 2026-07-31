# Task 296: Smoke-test Claude-proven spine under Grok Build

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 291, 292, 293
**Blocks**: 297
**Parent**: none

**Status: READY**

## Problem

Plan 5 shipped Grok as a peer tier with unit tests, but we have not re-run the
spine that already works under Claude Code (`chat` / `plan start` / `work` /
`gate` / `polish` / emit vs exec) under Grok. Without a systematic smoke,
later plans will inherit silent Grok regressions.

## Success criteria

- [ ] Written smoke checklist (and optional small script under `docs/tests/` or
      `docs/tmp` protocol) covering at least:
      1. Config/doctor: tier `grok-build`, mode exec outside agent / emit with
         `GROK_AGENT`
      2. Exec: interactive `chat` opens Grok TUI (or documented skip if no TTY)
      3. Exec: one-shot `work` headless with mapped tools / always-approve
      4. Emit: multi-task orchestration wording + observed spawn behavior
      5. `gate` or `plan start` multi-member path under Grok
      6. `model show` / set if #294 already landed; otherwise config pin
- [ ] Checklist run once on this machine; results recorded (pass/fail notes)
- [ ] Bugs found become tasks or in-plan fixes before marking this done
- [ ] Does not require a second git remote — local dogfood is enough

## Notes

- Prefer reusing disposable tasks / `--commit-only` where gating would hang.
- This is Grok-only confidence for known paths; dual fresh-project is #297.

## References

docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tests/test-grok-provider.sh
docs/sprintmd/guides/use_chat.md
