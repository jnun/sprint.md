# Task 292: Prove Grok emit subagent handoff and harden orchestration prompts

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 291
**Blocks**: 293, 296
**Parent**: none

**Status: READY**

## Problem

Plan 5 taught emit prompts to say `spawn_subagent` on `grok-build`, but that is
unit-tested wording only. We have not proven that a real Grok session (with
`GROK_AGENT=1`) fans out multi-task `work` / multi-file `gate` / multi
`polish` the way Claude’s Task tool path does. If the driver ignores the
orchestration plan and works sequentially — or fails to spawn — Grok users
lose the product’s parallel design without a clear signal.

## Success criteria

- [ ] Manual dogfood inside Grok Build documents results for:
      1. multi-task emit `work` (spawn per task, file routing)
      2. multi-file emit `gate` (or `plan start` multi-member path)
      3. multi-file emit `polish` if practical
- [ ] Failures become concrete fixes: prompt wording, helper text, or docs —
      not “works in theory”
- [ ] Emit prompts state that the **orchestrator** spawns workers and workers
      **must not** re-call `spawn_subagent` (Grok nesting depth is one)
- [ ] Claude paths still say Task tool; Grok paths never claim Claude tools
- [ ] Short dogfood note (task Completed section or `docs/tmp/` log) records
      what was run and what was observed

## Notes

- Use disposable READY tasks or a throwaway fixture so dogfood does not trash
  the real board.
- Exec multi-process parallel is out of scope here — that path does not use
  host subagents.
- Prefer fixing `sprintmd_subagent_*` helpers over copy-pasting six scripts.

## References

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/polish.sh
docs/guides/grok-provider-tier.md
~/.grok/docs/user-guide/16-subagents.md
