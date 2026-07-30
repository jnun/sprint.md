# Task 291: Verify and lock Grok tool ID map for headless allowlists

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: 292, 296
**Parent**: none

**Status: READY**

## Problem

Headless Grok tool restriction is only as good as the internal ID map in
`cli/grok.sh`. Product docs have used both `run_terminal_cmd` and
`run_terminal_command` for the shell tool; if we map the wrong id, allowlists
fail open or strip shell. Until the live binary’s tool IDs are verified and
pinned with a test, every exec `work` / `gate` / `polish` run under Grok is
guesswork.

## Success criteria

- [ ] Against a live `grok` install, record the real internal IDs needed for
      sprint.md’s core surface (at least: read, edit/write, shell, grep, list/dir)
- [ ] `cli/grok.sh` map matches live IDs; Bash maps to the verified shell id
- [ ] Fail-open on unmapped names remains; Agent/Task still skipped (not in
      `--tools` allowlist)
- [ ] Automated test asserts the core Claude-name → Grok-id map (and fails if
      the shell id mapping regresses)
- [ ] One-line note in `docs/guides/grok-provider-tier.md` (or capability matrix)
      states verified shell id + re-check date

## Notes

- Prefer probing the running product over stale docs when they conflict.
- Do not invent tool IDs. If an id cannot be verified, leave unmapped and fail
  open with a warning — do not ship a broken empty allowlist.
- `--allowedTools` on Grok is a permission-rule alias; never use it for tool
  allowlists.
- **From #298 burn (KU-01):** live Grok 0.2.114 accepts **both**
  `run_terminal_command` and `run_terminal_cmd` as shell-only `--tools`.
  Prefer emitting `run_terminal_command` (getting-started/hooks/skills); accept
  either as map input. Headless guide still documents `run_terminal_cmd` only
  (doc drift on Grok’s side).
- **From #298 (KU-06):** `--tools not_a_real_tool_xyz` still allowed shell —
  Grok soft-fails bad allowlists. Our fail-open remains correct; do not assume
  strict empty toolset on garbage IDs.
- **From #298 (KU-03):** optional probe — MCP meta-tools under allowlist.

## References

docs/sprintmd/cli/grok.sh
docs/guides/grok-provider-tier.md
docs/tests/test-grok-provider.sh
~/.grok/docs/user-guide/14-headless-mode.md
