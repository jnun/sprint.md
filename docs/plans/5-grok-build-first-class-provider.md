# Plan 5: Grok Build first-class provider

**Created**: 2026-07-29
**Status:** READY

> A plan is a **relational index, not a container.** It groups related tasks by
> listing their IDs. The tasks never move into this file — each stays in its own
> lifecycle folder (`backlog → next → doing → …`) and its progress is tracked
> there. A plan is never itself a task; it only names a clump of work and its
> intent. `**Status:**` is binary — `DRAFT` while authoring, `READY` when safe
> for `plan start` / `loop --refill` to commit members into `next/`. Progress of
> the work itself derives from where member tasks live. To start this plan, run
> `./sprint.sh plan start <id>` (or move members `backlog/ → next/` by hand) —
> this file does not move.

## Prerequisite — run after plan 8

**Do not `plan start 5` until plan 8 (command surface remap) is complete and
shipped.** This plan is written for the target surface in
`docs/guides/command-matrix.md`:

```
chat  →  plan start  →  work  →  polish
```

| Live command (post–plan 8) | Retired name (do not use in new work) |
|----------------------------|----------------------------------------|
| `chat` / `chat <id>` / `chat <folder>` / `chat plan` / `chat bugs` | `talk` |
| `work` | `tasks` (execute verb only — `docs/tasks/` stays) |
| `gate` | `define` |
| `align` / `context` / `deps` | `checkfeatures` / `ai-context` / `audit-deps` |

Config keys after plan 8: prefer `MODEL_CHAT` / `MODEL_WORK` / `MODEL_GATE` (and
matching budget keys) — not the retired `MODEL_TALK` / `MODEL_TASKS` /
`MODEL_DEFINE` names. Implement against the **live** keys once plan 8 lands.

Member task files (#251–#256) may still carry pre-remap prose until refined at
execution; **success criteria and all new edits must use the post–plan 8
names.**

## Goal

Make **Grok Build** a first-class AI provider in sprint.md — same switch users
already have for Claude Code — so that:

- Setup can select Grok (`CLI=grok`, `PROVIDER=grok-build`)
- Interactive commands (`chat`, `profile`, conversational creates) launch a live
  Grok TUI from a plain terminal
- Inside Grok Build, commands **emit** into the current session (`GROK_AGENT`)
- High-throughput paths — `./sprint.sh work`, `gate`, `polish`, chat chaining,
  and `plan think` — use Grok's **fresh-context subagents** for parallel /
  token-efficient work instead of the sequential generic fallback

When this plan ships, a Grok-forward install is not a degraded passthrough: it
is an orchestration peer to Claude Code, with honest capability docs and tests.

Design guides (as-built Claude + target Grok):

- `docs/guides/claude-provider-tier.md` — how the Claude tier works today
- `docs/guides/grok-provider-tier.md` — target design for the Grok peer tier
- `docs/guides/command-matrix.md` — command names and families this plan uses

## Why

Claude-tier sprint.md is fast because it leans into the agent: one subagent per
task, parallel unrelated work, tight tool surfaces, strong models for reasoning
flows. Users already live in Grok Build; the CLI is Claude-shaped (`-p`,
positional interactive prompt, models, turns, JSON, permissions, `spawn_subagent`).
Without a profile and tier, that potential is left on the floor — wrong emit
detection, no interactive chat, sequential-only queues. Shipping a real
`grok-build` tier multiplies speed for Grok users without weakening the Claude
path.

Executing **after** the chat / work / gate remap means the Grok tier wires
once into the names agents already type — no second rename pass of provider
prompts and docs.

## Maximize Grok (design targets)

| Capability | Claude today | Grok target |
|------------|--------------|-------------|
| Setup switch | Claude Code | **Grok Build** option |
| Interactive chat | `cli/claude.sh` REPL | `cli/grok.sh` REPL |
| Emit inside agent | `CLAUDECODE` etc. | **`GROK_AGENT`** |
| `work` emit parallel | Task tool subagents | **`spawn_subagent`** per task |
| `gate` / `polish` multi | parallel subagents | same on grok-build |
| Chat chain / blocked dep | fresh Task subagent | fresh Grok subagent |
| Model defaults | strong model on tier | strong Grok default when unset |
| Tool restriction | Claude tool names | map IDs **or** omit honestly |
| Exec parallel jobs | multi-process CLI | free once profile works |

Out of scope for this plan (follow-ups if needed): Claude stream-json parity,
budget-cap mapping unless Grok exposes it, dedicated shipping AGENTS/Grok
pointer files, Gemini/Mistral profiles.

## Execution order & parallelism

1. **253** — emit detection (`GROK_AGENT`). No profile required; immediate win
   when already inside Grok. ∥ with **251**.
2. **251** — `cli/grok.sh` exec + interactive. Foundation for terminal launch.
   ∥ with **253**.
3. **252** — register `grok-build` in setup, `sprintmd_ai_tier`, config,
   capability matrix. Needs **251** so the picker points at a real profile.
4. **255** — models / tools / permissions mapping on the profile + tier model
   defaults. Needs **251** + **252**. ∥ with **254** after **252** (254 is
   mostly script gates/prompts; 255 is profile/lib mapping).
5. **254** — orchestration-capable gates for `work` / `gate` / `polish` /
   `chat` / `plan think` with Grok subagent language. Needs **251–253**.
6. **256** — docs, tests, ship/setup smoke. Needs **251–255**. Use matrix
   names (`chat`, `work`, `gate`) and post–plan 8 config keys throughout.

Shared touch points: `lib.sh` (tier, mode, maybe helpers), `config` comments,
`provider-capabilities.md`. Serialize conflicting edits; prefer one helper for
"orchestration-capable tier" so Claude and Grok do not diverge.

## Member tasks

<!-- Ordered = preferred execution order. References only. -->

- [ ] #253 — Detect Grok sessions for emit mode (GROK_AGENT)
- [ ] #251 — Add Grok CLI provider profile (exec + interactive)
- [ ] #252 — Register grok-build tier in setup, config, and capability matrix
- [ ] #255 — Map Grok models, tools, and permission flags for full runs
- [ ] #254 — Grok-class parallel orchestration for work, gate, polish, chat
- [ ] #256 — Document and test Grok provider path end-to-end

## How to start

Only after plan 8 is done (live `chat` / `work` / `gate`, six help families):

```bash
./sprint.sh plan start 5
# then work the board:
./sprint.sh chat 253    # refine / close the loop if needed
./sprint.sh work        # execute READY members
# or: ./sprint.sh loop --refill
```
