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
- [ ] Headless path: `grok -p "…"` (or `--single`) with mapped neutral flags
      (`--model`, `--max-turns`, `--output-format`, `--permissions` →
      `--permission-mode`, `--skip-permissions` → `--always-approve`/`--yolo`,
      `--append-system-prompt` → `--rules`)
- [ ] Unknown / Claude-only flags (`--budget`, unused `--name`) consumed without
      leaking onto the Grok command line
- [ ] With `CLI=grok` and a real TTY, `./sprint.sh chat <id>` opens a live Grok
      session (not the single-pass degraded note)

## Notes

- Mirror structure and comments from `cli/claude.sh` where the contract is
  shared; do not copy Claude-only stream-json filter or resume-on-drop until
  verified against a real `grok` install (can land later in #255).
- Grok headless docs: `-p`/`--single`, `--output-format plain|json|streaming-json`,
  `--tools` is headless-only; interactive tool allowlists are ignored with a
  warning on the Grok side — fine for talk.
- Verify flag names against `grok --help` on the machine under test; prefer
  stable public flags over undocumented aliases.
- Profile is loaded by name: `cli/grok.sh` when `SPRINTMD_CLI=grok`.

## References

docs/sprintmd/cli/claude.sh
docs/sprintmd/cli/default.sh
docs/sprintmd/lib.sh
docs/sprintmd/guides/use_talk.md
