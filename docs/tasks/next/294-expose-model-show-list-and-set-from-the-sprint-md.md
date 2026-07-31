# Task 294: Expose model show list and set from the sprint.md CLI

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: 295, 297
**Parent**: none

**Status: READY**

## Problem

Model selection today is buried: edit `docs/sprintmd/config` (`MODEL_DEFAULT`,
`MODEL_WORK`, `MODEL_CHAT`, …) or set `SPRINTMD_MODEL_*` env vars. There is no
first-class sprint.md command to **see** the effective model for each role,
**list** what the current provider offers, or **set** a default without
hand-editing config. Switching between Claude and Grok models (or pinning
work vs chat) should be a deliberate CLI action, not tribal knowledge.

## Success criteria

- [ ] A user-facing command (recommended name: `./sprint.sh model`) supports at
      least:
      - **show** — effective model per role (WORK, CHAT, GATE, …) after
        env → config → tier default resolution; show active CLI/PROVIDER
      - **list** — models available from the current provider when possible
        (`grok models`; Claude equivalent if cheap/reliable, else honest
        “see provider docs” + config keys)
      - **set** — write `MODEL_DEFAULT` and/or `MODEL_<ROLE>` into
        `docs/sprintmd/config` (never invent keys outside the known set)
- [ ] Help page + registry entry; name is plain language
- [ ] Works for both `claude-code` and `grok-build` installs without requiring
      the other CLI on PATH
- [ ] Does not clobber unrelated config; uses existing `sprintmd_cfg_set` (or
      equivalent)
- [ ] `model show` makes tier defaults visible (e.g. empty config →
      `grok-4.5` / `opus` via `sprintmd_tier_model` where applicable)

## Notes

- Prefer one `model` command with subcommands over scattering flags only.
- Per-invocation flags for work/chat can land in #295; this task is the
  durable show/list/set surface.
- Setup picker remains provider-level; this is model-level within a provider.
- **From #298 burn (KU-24):** `work` / `gate` / `polish` use
  `sprintmd_resolve_model` only, so empty config does **not** apply tier
  defaults (`opus` / `grok-4.5`). Chat uses `sprintmd_tier_model`. In this task
  (or a one-line follow-up in the same PR): either switch those spine scripts
  to `tier_model` where a strong default is intended, or make `model show`
  print the gap honestly (“WORK: (CLI default — not tier-pinned)”). Prefer
  aligning work/gate/polish with tier_model for provider parity.
- **From #298 (KU-21):** `model list` on Claude has no cheap list API here —
  ship known aliases + pointer, not a fake `claude models` scrape.

## References

docs/sprintmd/lib.sh
docs/sprintmd/config
docs/sprintmd/help/_registry
docs/sprintmd/scripts/
DOCUMENTATION.md
