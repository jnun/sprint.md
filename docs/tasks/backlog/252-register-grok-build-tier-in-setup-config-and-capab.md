# Task 252: Register grok-build tier in setup, config, and capability matrix

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: 251
**Blocks**: 254, 255, 256
**Parent**: none

**Status: READY**

## Problem

Provider choice is Claude / Cursor / OpenAI / Gemini / Mistral / Other. There is
no first-class "Grok Build" option, and `sprintmd_ai_tier` never returns a
Grok tier — so even with a working `cli/grok.sh`, scripts still treat Grok as
`generic` (no parallel orchestration, no tier model defaults). Users need a
setup switch that sets `CLI=grok` and `PROVIDER=grok-build` the same way Claude
sets `claude-code`.

## Success criteria

- [ ] `setup.sh` provider picker includes Grok Build (binary `grok`, tier
      `grok-build`); writes both `CLI` and `PROVIDER` into config
- [ ] `lib.sh:sprintmd_ai_tier` infers `grok` → `grok-build` when `PROVIDER` is
      unset (mirrors setup exactly)
- [ ] `docs/sprintmd/ai/provider-capabilities.md` gains a `grok-build` column
      with honest capability marks (interactive yes; subagent/parallel yes when
      emit orchestration lands; tool restriction / model / JSON as verified)
- [ ] Config comments list `grok-build` among known tiers
- [ ] Choosing Grok in setup is enough for scripts to load `cli/grok.sh` and
      report tier `grok-build` via `sprintmd_ai_tier`

## Notes

- Tier name: `grok-build` (product name) keeps the pattern of `claude-code`
  (product) rather than bare vendor names.
- Investment priority in the matrix should place Grok next to Claude as a
  first-class interactive + orchestration tier, not under generic.
- Do not invent a Grok instruction file unless setup already has a clear
  pattern and a minimal pointer exists under `src/` — prefer no new user-file
  until we know what Grok loads (project rules / AGENTS.md already work).
- Keep Gemini/Mistral as generic unless they gain verified profiles.

## References

setup.sh
docs/sprintmd/lib.sh
docs/sprintmd/config
docs/sprintmd/ai/provider-capabilities.md
