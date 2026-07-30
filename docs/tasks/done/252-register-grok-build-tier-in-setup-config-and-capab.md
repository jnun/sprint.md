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

- [ ] `setup.sh` provider picker includes **Grok Build** (binary `grok`, tier
      `grok-build`); writes both `CLI` and `PROVIDER` into config
- [ ] `lib.sh:sprintmd_ai_tier` infers `grok` → `grok-build` when `PROVIDER` is
      unset (mirrors setup exactly)
- [ ] `docs/sprintmd/ai/provider-capabilities.md` gains a `grok-build` column
      with honest capability marks (interactive yes; subagent/parallel yes when
      #254 lands; tool restriction / model / JSON as verified by #251/#255;
      budget no unless verified)
- [ ] Investment priority text places Grok next to Claude as a first-class
      interactive + orchestration tier (not under generic)
- [ ] Config comments list `grok-build` among known tiers
- [ ] Choosing Grok in setup is enough for scripts to load `cli/grok.sh` and
      report tier `grok-build` via `sprintmd_ai_tier`
- [ ] Setup does **not** invent a Grok-only instruction file by default (Grok
      already loads `AGENTS.md` / `CLAUDE.md` when present). If a decision lands
      to offer `AGENTS.md`, wire it like Claude's optional `CLAUDE.md` path —
      never clobber existing files

## Notes

- Tier name: `grok-build` (product name) keeps the pattern of `claude-code`
  (product) rather than bare vendor names.
- Current setup map (edit in place):
  - picker options → `SELECTED_CLI`
  - CLI → `SELECTED_PROVIDER` case
  - optional `PROVIDER_AI_FILE` for instruction-file offer
- Keep Gemini/Mistral as generic unless they gain verified profiles.
- Do not bloat shipping pointer files under `src/` with Grok marketing.

## References

setup.sh
docs/sprintmd/lib.sh
docs/sprintmd/config
docs/sprintmd/ai/provider-capabilities.md
docs/guides/grok-provider-tier.md

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
