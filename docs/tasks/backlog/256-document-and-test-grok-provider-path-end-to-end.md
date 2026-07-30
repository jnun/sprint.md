# Task 256: Document and test Grok provider path end-to-end

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: 251, 252, 253, 254, 255
**Blocks**: none
**Parent**: none

**Status: READY**

## Problem

A Grok switch that only lives in code will be rediscovered poorly: setup help,
`use_talk.md`, README, and the capability matrix must teach "pick Grok, run
talk/tasks/polish like Claude." Without tests, the next Claude-only gate
reintroduces silent sequential fallback. Ship needs verification that
`./ship.sh` mirrors the new profile and that unit-level detection/tier/profile
loading cannot regress.

## Success criteria

- [ ] `docs/sprintmd/guides/use_talk.md` documents Grok interactive exec and
      emit-inside-Grok (`GROK_AGENT` / auto emit)
- [ ] `provider-capabilities.md` matrix + priority text match shipped behavior
- [ ] README (and/or `DOCUMENTATION.md` AI section) mentions `CLI=grok` /
      setup Grok option alongside Claude — no claim of support that is untrue
- [ ] Automated tests cover: tier inference for `grok`, emit detection when
      `GROK_AGENT` is set, profile load defines interactive + exec functions
- [ ] Manual smoke checklist in Notes (or test script comments): setup →
      `CLI=grok` → `talk` interactive; inside Grok → emit; `tasks` emit
      orchestration wording
- [ ] `./ship.sh` (or dry-run) confirms `src/docs/sprintmd/cli/grok.sh` ships;
      fresh `./setup.sh` install can select Grok

## Notes

- Follow dual-tree: edit `docs/`, then `./ship.sh` — never hand-copy to `src/`.
- Prefer extending existing tests (`test-no-stale-refs`, setup detection,
  profile tests if any) over a giant new suite.
- Do not bloat root `CLAUDE.md` / shipping pointer files with Grok marketing.

## References

docs/guides/claude-provider-tier.md
docs/guides/grok-provider-tier.md
docs/sprintmd/guides/use_talk.md
docs/sprintmd/ai/provider-capabilities.md
README.md
DOCUMENTATION.md
docs/tests/
ship.sh
setup.sh
