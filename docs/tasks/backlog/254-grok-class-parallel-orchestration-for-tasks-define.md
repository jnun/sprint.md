# Task 254: Grok-class parallel orchestration for tasks define polish talk

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: 251, 252, 253
**Blocks**: 256
**Parent**: none

**Status: READY**

## Problem

Claude-tier emit mode is what makes sprint.md fast: `./sprint.sh work` tells
the driver to spawn one fresh subagent per task, run them in parallel, and
route files by result — so unrelated work does not share one bloated context.
`define`, `polish`, and talk's "continue the chain" path do the same. All of
those gates are hard-coded to `claude-code` and speak Claude's "Task tool"
language. Grok Build has real subagents (`spawn_subagent`, types
`general-purpose` / `explore` / `plan`) but today falls into the sequential
"no subagent tool" fallback. Users who switch to Grok lose the product's
parallel / token-saving design.

## Success criteria

- [ ] Emit orchestration for multi-task work treats `grok-build` like an
      orchestration-capable tier (alongside `claude-code`), not generic
- [ ] `./sprint.sh work` (emit, grok-build): prompt instructs one fresh
      subagent per task via Grok's `spawn_subagent` (not Claude "Task tool"),
      parallel dispatch when `--parallel`/`--fast`, file routing unchanged
- [ ] `./sprint.sh gate` multi-task emit path uses parallel subagents on
      grok-build with the same review contract
- [ ] `./sprint.sh polish` multi-task emit path same pattern
- [ ] Talk chain / next→blocked handoff on grok-build emit: spawn a fresh
      subagent for `./sprint.sh chat <next-id>` (Grok wording)
- [ ] Claude paths still say Task tool; Grok paths never claim Claude tools
- [ ] `plan think` works under `CLI=grok` / emit in Grok (uses shared run
      helpers; no silent generic degradation for the dual-persona critique)

## Notes

- Prefer a small helper (e.g. `sprintmd_orchestration_capable` or a
  subagent-instruction snippet per tier) over copy-pasting
  `claude-code|grok-build` everywhere — minimize drift.
- Grok tool names in prompts: `spawn_subagent`, not `Task`. Agent types:
  `general-purpose` for implementation, `explore` for read-only research,
  `plan` for plan-mode work if useful.
- Exec-mode parallel (`tasks --parallel`) already shells out per job via the
  provider profile — once #251 works, exec parallelism is mostly free; this
  task is primarily **emit** orchestration language + tier gates.
- `plan think` is the dual-persona plan critique (`./sprint.sh plan think`);
  ensure it is not left on a generic one-shot path that drops system prompts.

## References

docs/sprintmd/scripts/tasks.sh
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/plan-think.sh
docs/sprintmd/lib.sh
