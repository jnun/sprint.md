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
Without mapping, `tasks`/`polish`/`think` under Grok are under-specified:
wrong tools, weak models, or unrestricted when Claude would restrict.

## Success criteria

- [ ] `sprintmd_tier_model` (or equivalent) can choose a strong default on
      `grok-build` when config models are empty (document the alias, e.g.
      product default / `grok-4` / whatever `grok models` advertises as best)
- [ ] Config comments document `MODEL_*` usage for Grok the same as Claude
- [ ] Tool allowlists from scripts either map Claude-style names → Grok tool
      IDs (`Read`→`read_file`, `Edit`/`Write`→`search_replace`/`write`,
      `Bash`→`run_terminal_command`, `Grep`→`grep`, `Glob`→`list_dir`/search)
      **or** are intentionally omitted on Grok with a one-line rationale in the
      profile (no silent wrong allowlist)
- [ ] Permission / always-approve mapping verified for automated exec jobs
      (`tasks`, `loop`, polish batch) so they do not hang on tool prompts
- [ ] Optional stretch only if verified cheaply: stream/progress narration or
      retry on transient API errors (do not block the task if unproven)

## Notes

- Grok headless: `--tools` is allowlist of **internal** tool IDs; MCP meta-tools
  stay available unless denied. Interactive TUI ignores `--tools` with a
  warning — interactive talk can skip tool restriction.
- Prefer correctness over cleverness: wrong allowlist that strips all tools is
  worse than no allowlist.
- Budget caps: only map if Grok exposes a real equivalent; otherwise drop with
  the same honest warning pattern as `default.sh`.
- Verify models with `grok models` at implementation time — do not hardcode
  stale IDs from memory.

## References

docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/grok.sh
docs/sprintmd/lib.sh
docs/sprintmd/config
