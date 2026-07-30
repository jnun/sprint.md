# Task 254: Grok-class parallel orchestration for work gate polish chat plan-start

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
`gate`, `polish`, chat's "continue the chain" path, **`plan start` multi-member
gating**, and next→blocked Path A do the same. All of those gates are
hard-coded to `claude-code` and speak Claude's "Task tool" language. Grok Build
has real subagents (`spawn_subagent`, types `general-purpose` / `explore` /
`plan`) but today falls into the sequential "no subagent tool" fallback. Users
who switch to Grok lose the product's parallel / token-saving design.

## Success criteria

- [ ] Shared helper in `lib.sh` (e.g. `sprintmd_orchestration_capable` and/or a
      subagent-instruction snippet) treats `claude-code` **and** `grok-build` as
      orchestration-capable — no six independent `claude-code|grok-build` forks
- [ ] Emit orchestration for multi-task **work** treats `grok-build` like
      Claude: one fresh subagent per task via **`spawn_subagent`** (not "Task
      tool"), parallel when `--parallel`/`--fast`, file routing unchanged
- [ ] **`gate`** multi-task emit path (and **`gate-lib.sh:sprintmd_gate_parallel`**
      prompt wording) uses parallel subagents on grok-build with the same
      review contract — gate-lib must not hardcode "Task tool" for Grok
- [ ] **`plan start`** multi-member emit path (uses `sprintmd_gate_parallel`)
      works under grok-build emit — same helper as gate
- [ ] **`polish`** multi-task emit path same pattern
- [ ] Chat chain / next→blocked handoff on grok-build emit: spawn a fresh
      subagent for `./sprint.sh chat <next-id>` (Grok wording in `chat.sh` and
      `lib.sh:sprintmd_next_blocked_resolution`)
- [ ] Claude paths still say Task tool; Grok paths never claim Claude tools
- [ ] `plan think` works under `CLI=grok` / emit in Grok (uses shared run
      helpers; no silent generic degradation for the dual-persona critique)

## Notes

- **Complete inventory of `claude-code` hard gates to open (as of 2026-07-30):**
  - `scripts/work.sh` — emit multi-task orchestration prompt
  - `scripts/gate.sh` — multi-file emit parallel branch
  - `scripts/gate-lib.sh` — `sprintmd_gate_parallel` "Task tool" wording
  - `scripts/plan-start.sh` — multi-member gate via `sprintmd_gate_parallel`
  - `scripts/polish.sh` — multi-task judge orchestration
  - `scripts/chat.sh` — continue-the-chain subagent instruction
  - `lib.sh:sprintmd_next_blocked_resolution` — Path A subagent wording
  - `lib.sh:sprintmd_tier_model` — model default is **#255**, not this task
- Grok tool names in prompts: `spawn_subagent`, not `Task`. Agent types:
  `general-purpose` for implementation, `explore` for read-only research,
  `plan` for plan-mode work if useful. Nesting depth is one — orchestrator
  spawns workers; workers do not re-orchestrate.
- Prefer **not** introducing Grok's `workflow` tool as the driver for this
  plan — `spawn_subagent` matches Claude's one-subagent-per-unit model and
  keeps emit prompts portable.
- Exec-mode parallel (`work --parallel`) already shells out per job via the
  provider profile — once #251 works, exec parallelism is mostly free; this
  task is primarily **emit** orchestration language + tier gates.
## References

docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/plan-think.sh
docs/sprintmd/lib.sh
docs/guides/grok-provider-tier.md

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
