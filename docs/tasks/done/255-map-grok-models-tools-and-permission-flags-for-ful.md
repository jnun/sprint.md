# Task 255: Map Grok models tools and permission flags for full runs

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: 251, 252
**Blocks**: 256
**Parent**: none

**Status: READY**

## Problem

Claude-tier runs maximize speed and safety with model picks (`sprintmd_tier_model`
→ strongest for reasoning flows), tool allowlists (`Read,Edit,Write,Bash,…`),
permission modes, budgets, and stream progress. On Grok those neutral flags
either do nothing useful (wrong tool IDs) or never get a strong default model.
Without mapping, `work` / `polish` / `plan think` under Grok are under-specified:
wrong tools, weak models, or permission hangs when Claude would skip prompts.

## Success criteria

- [ ] `sprintmd_tier_model` (or equivalent) chooses a strong default on
      `grok-build` when config models are empty — **pin the id advertised by
      `grok models`** (confirmed 2026-07-30: `grok-4.5` is default / only
      advertised; re-check at implement time)
- [ ] Config comments document `MODEL_*` usage for Grok the same as Claude
      (post–plan 8 keys: `MODEL_CHAT`, `MODEL_WORK`, `MODEL_GATE`, …)
- [ ] Tool allowlists from scripts are handled honestly:
      - Map known Claude-style names → Grok internal IDs for headless `--tools`,
        **or** omit with a one-line rationale in the profile
      - **Never** pass Claude names through blindly
      - **Never** map neutral `--tools` onto Grok `--allowedTools` (permission
        rules, not allowlist)
      - Suggested core map (verify exact shell id on install — docs have used
        both `run_terminal_cmd` and live sessions expose `run_terminal_command`):
        `Read`→`read_file`, `Edit`/`Write`→`search_replace`/`write`,
        `Bash`→shell tool id, `Grep`→`grep`, `Glob`→`list_dir`
      - Prefer fail-open: if a script requests unmapped tools, drop allowlist
        rather than ship a broken empty toolset
- [ ] Permission / always-approve mapping verified for automated exec jobs
      (`work`, `loop`, polish batch) so they do not hang on tool prompts
      (`--always-approve` or `--permission-mode bypassPermissions`)
- [ ] Budget: drop with honest warning unless a real Grok budget flag is
      verified (do not invent)
- [ ] Optional stretch only if verified cheaply: stream/progress narration or
      resume-on-transient using Grok `sessionId` + `--resume` (do not block the
      task if unproven; Claude stream filter is **not** portable)

## Notes

- Grok headless: `--tools` is allowlist of **internal** tool IDs; MCP
  meta-tools stay available unless denied. Interactive TUI ignores `--tools`.
- Permission rules (`--allow` / `--deny`, Claude-compat `Bash(...)` prefixes)
  are a separate surface from tool allowlists — only map if a script needs them.
- Prefer correctness over cleverness: wrong allowlist that strips all tools is
  worse than no allowlist.
- Dual-tree: edit `docs/sprintmd/`, then ship via #256 / `./ship.sh`.

## References

docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/grok.sh
docs/sprintmd/lib.sh
docs/sprintmd/config
docs/guides/grok-provider-tier.md

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
