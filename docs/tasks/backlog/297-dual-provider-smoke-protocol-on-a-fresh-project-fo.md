# Task 297: Dual-provider smoke protocol on a fresh project for upcoming plans

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 294, 296
**Blocks**: none
**Parent**: none

**Status: READY**

## Problem

Upcoming plans will ship product changes that must work for both Claude Code
and Grok Build users. Ad-hoc dogfood in this repo alone misses install path
issues (setup picker, empty project, no dogfood board). We need a short,
repeatable protocol: fresh install → pick provider → run a tiny spine → switch
model → compare — so every later plan can smoke both hosts without reinventing
the ritual.

## Success criteria

- [ ] Documented protocol (guide under `docs/guides/` or section in
      grok/claude provider guides + pointer from README/GETSTARTED) for:
      1. `mkdir` fresh project + `./setup.sh` choose Claude → smoke spine
      2. same or second fresh tree → setup choose Grok → smoke spine
      3. `./sprint.sh model` (or config) switch / show
      4. one small real task created and run under each provider
- [ ] Protocol names exact commands and pass criteria (not vibes)
- [ ] Uses shipped `src/` via setup (not hand-copy) so install path is tested
- [ ] Leaves no requirement that both CLIs are configured in the *same* project
      unless that is explicitly tested as a bonus
- [ ] Protocol is short enough to run before marking a later plan’s “ship”
      task done (~30–60 minutes, not a multi-day matrix)

## Notes

- This task delivers the **protocol and one dry run**, not perpetual CI of two
  providers (optional stretch: script the non-interactive bits).
- Clean up temp projects when done (`rm -rf /tmp/...`).
- Align with dual-tree rule: ship before setup smoke.

## References

setup.sh
ship.sh
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
GETSTARTED.md
