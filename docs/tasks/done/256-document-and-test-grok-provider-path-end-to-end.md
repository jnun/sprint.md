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
`use_chat.md`, README, and the capability matrix must teach "pick Grok, run
`chat` / `work` / `polish` like Claude." Without tests, the next Claude-only
gate reintroduces silent sequential fallback. Ship needs verification that
`./ship.sh` mirrors the new profile and that unit-level detection/tier/profile
loading cannot regress.

## Success criteria

- [ ] `docs/sprintmd/guides/use_chat.md` documents Grok interactive exec and
      emit-inside-Grok (`GROK_AGENT` / auto emit) — not Claude-only wording
- [ ] `provider-capabilities.md` matrix + priority text match shipped behavior
      (grok-build column next to claude-code)
- [ ] README and/or `DOCUMENTATION.md` AI section mentions `CLI=grok` / setup
      Grok option alongside Claude — no claim of support that is untrue
- [ ] Design guides stay accurate: `docs/guides/grok-provider-tier.md` marked
      as-built (or "shipped") once behavior matches; Claude guide cross-links
- [ ] Automated tests cover at least:
      - tier inference for `CLI=grok` → `grok-build`
      - emit detection when `GROK_AGENT` is set
      - profile load defines interactive + exec functions
      - optional: orchestration helper returns true for both claude-code and
        grok-build
- [ ] Manual smoke checklist in Notes (or test script comments):
      1. setup → choose Grok Build → `CLI=grok` `PROVIDER=grok-build`
      2. plain TTY → `./sprint.sh chat <id>` opens live Grok
      3. inside Grok (`GROK_AGENT=1`) → emit (no nested CLI)
      4. emit `work` / `gate` / `plan start` multi → spawn_subagent wording
      5. `./ship.sh --dry-run` shows `cli/grok.sh`; full ship + fresh setup can
         select Grok
- [ ] `./ship.sh` confirms `src/docs/sprintmd/cli/grok.sh` ships

## Notes

- Follow dual-tree: edit `docs/`, then `./ship.sh` — never hand-copy to `src/`.
- Prefer extending existing tests (`test-no-stale-refs`, setup detection,
  `test-profile.sh` patterns) over a giant new suite.
- Do not bloat root `CLAUDE.md` / shipping pointer files with Grok marketing.
## References

docs/guides/claude-provider-tier.md
docs/guides/grok-provider-tier.md
docs/sprintmd/guides/use_chat.md
docs/sprintmd/ai/provider-capabilities.md
README.md
DOCUMENTATION.md
docs/tests/
ship.sh
setup.sh

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
