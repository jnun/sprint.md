# Task 251: Add Grok CLI provider profile (exec + interactive)

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: 252, 254, 255
**Parent**: none

**Status: READY**

## Problem

Users who prefer Grok Build cannot get Claude-class launch behavior from
`./sprint.sh chat`, `profile`, `newfeature`, and other interactive commands.
`SPRINTMD_CLI=grok` falls through `cli/default.sh`: one-shot `-p` only, no live
REPL, and richer flags dropped. Given `grok` is installed and its CLI is
Claude-shaped (`-p`/`--single`, positional interactive prompt, model, turns,
JSON, permissions), sprint.md should host a dedicated profile so exec mode
launches Grok correctly — interactive for dialogue, headless for jobs.

## Success criteria

- [ ] `docs/sprintmd/cli/grok.sh` defines `sprintmd_provider_exec` and
      `sprintmd_provider_interactive`, with `SPRINTMD_PROVIDER_INTERACTIVE=1`
- [ ] Interactive path: no `-p`, opening message as positional, inherits TTY
      (same contract as `cli/claude.sh`)
- [ ] Headless path: `grok -p "…"` (or `--single`) with mapped neutral flags:
      - `--model` → `-m` / `--model`
      - `--max-turns` → `--max-turns`
      - `--output-format` → `--output-format` (`plain|json|streaming-json`)
      - `--permissions` → `--permission-mode`
      - `--skip-permissions` → `--always-approve` (alias `--yolo` also fine)
      - `--append-system-prompt` → `--rules`
      - `--tools` → **`--tools` only** (internal tool IDs). Never map to
        Grok's `--allowedTools` (that is a permission-rule alias for `--allow`)
- [ ] Unknown / Claude-only flags (`--budget`, unused `--name`) consumed without
      leaking onto the Grok command line (one-line drop warning when a valued
      flag was ignored, same spirit as `default.sh`)
- [ ] With `CLI=grok` and a real TTY, `./sprint.sh chat <id>` opens a live Grok
      session (not the single-pass degraded note)

## Notes

- Mirror structure and comments from `cli/claude.sh` where the contract is
  shared. **Do not** copy Claude-only stream-json filter, transient resume loop,
  or wall-clock timeout into this task — Grok `streaming-json` event types
  differ (`text`/`thought`/`end`, `sessionId` camelCase). Optional recovery can
  land later as a stretch in #255 or a follow-up.
- Grok headless: `--tools` / `--disallowed-tools` / `--max-turns` are
  headless-only; interactive TUI ignores them with a warning — fine for chat.
- Verify flag names against `grok --help` on the machine under test; prefer
  stable public flags over undocumented aliases. Confirmed 2026-07-30 on a
  live install: `--always-approve`, `--yolo` (docs), `--permission-mode`,
  `--rules`, `--tools`, `-p`/`--single`.
- Profile is loaded by name: `cli/grok.sh` when `SPRINTMD_CLI=grok`.
- Dual-tree: edit under `docs/sprintmd/cli/`; `./ship.sh` mirrors automatically.

## References

docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/default.sh
docs/sprintmd/lib.sh
docs/sprintmd/guides/use_chat.md
docs/guides/grok-provider-tier.md

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
