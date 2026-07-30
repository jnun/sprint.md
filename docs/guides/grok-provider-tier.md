# Grok Provider Tier (as built)

How sprint.md runs when the AI provider is **Grok Build** — a peer to the
Claude tier, not a generic passthrough. Capability matrix:
`docs/sprintmd/ai/provider-capabilities.md`. Claude peer:
`docs/guides/claude-provider-tier.md`.

Ship truth for flags and gates lives in code; this guide is the human/agent map.

**Language:** live command surface (`chat` / `work` / `gate` / …).

## Identity

| Field | Value |
|-------|-------|
| Tier name | `grok-build` |
| CLI binary | `grok` |
| Profile | `docs/sprintmd/cli/grok.sh` |
| Config | `CLI=grok` and `PROVIDER=grok-build` |
| Setup pick | Grok Build (option 2 in `setup.sh`) |
| Session detect | `GROK_AGENT=1` → emit mode |
| Default model (tier) | `grok-4.5` when `MODEL_*` empty (`sprintmd_tier_model`) |

## Goal

| User outcome | Meaning |
|--------------|---------|
| One switch | Pick Grok at setup the same way you pick Claude |
| Live chat | `./sprint.sh chat` opens a Grok TUI from a plain terminal |
| Emit in-session | Inside Grok Build, prompts land here — no nested CLI |
| Parallel cycles | `work` / `gate` / `polish` / `plan start` use fresh subagents |
| Honest maps | Flags and tool names match real `grok --help`, or are dropped with a warning |

## Two modes (same product rule as Claude)

| Mode | When | What happens |
|------|------|--------------|
| emit | Inside Grok Build (`GROK_AGENT` set, or `MODE=emit`) | Print the prompt into this session. Driver uses `spawn_subagent` for parallel work. |
| exec | Plain terminal, CI, loops | Spawn `grok` via `cli/grok.sh`. Interactive or `-p` headless. |

## Neutral interface (unchanged)

Scripts keep calling `sprintmd_run` / `sprintmd_run_interactive`. Only the
profile and tier gates change. No script should hardcode `grok` flags.

## Flag map (neutral → Grok)

| Neutral flag | Grok flag | Notes |
|--------------|-----------|-------|
| `-p PROMPT` | `-p` / `--single PROMPT` | Headless; prints and exits |
| positional prompt | positional | Interactive TUI open message |
| `--model` | `-m` / `--model` | e.g. `grok-4.5` |
| `--max-turns` | `--max-turns` | Headless-oriented; cap long jobs |
| `--tools` | **`--tools`** | Grok **internal** tool IDs. **Not** `--allowedTools` |
| `--permissions` | `--permission-mode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `--skip-permissions` | `--always-approve` | Unattended batch / loop |
| `--output-format` | `--output-format` | `plain`, `json`, `streaming-json` |
| `--budget` | (drop) | No verified USD budget flag — warn once |
| `--name` | (drop) | No direct equivalent — warn once |
| `--append-system-prompt` | `--rules` | Append rules to system prompt |

**JSON resume field:** headless result uses `sessionId` (camelCase). Resume with
`grok --resume <id>`. Claude's stream-json filter is **not** ported (Grok
events: `text` / `thought` / `end`).

## Tool names

Claude allowlists are mapped in `cli/grok.sh` for headless `--tools`. Unmapped
names fail open (omit allowlist).

| Claude-style | Grok tool ID |
|--------------|--------------|
| Read | `read_file` |
| Edit / Write | `search_replace` / `write` |
| Bash | `run_terminal_command` |
| Grep | `grep` |
| Glob | `list_dir` |
| Task / Agent (subagent) | prompt language `spawn_subagent` (not a `--tools` entry) |

## Subagents (Grok native)

| Concept | Grok |
|---------|------|
| Spawn child | `spawn_subagent` |
| Default worker | `general-purpose` |
| Read-only research | `explore` |
| Planning only | `plan` |
| Nesting | depth one — children cannot spawn children |

Emit prompts get wording from `sprintmd_subagent_*` helpers in `lib.sh` so Claude
says "Task tool" and Grok says `spawn_subagent`.

## Orchestration

Shared helper: `sprintmd_orchestration_capable` is true for `claude-code` and
`grok-build`. Used by:

- `work.sh` emit multi-task
- `gate.sh` / `gate-lib.sh` / `plan-start.sh` multi-member
- `polish.sh` multi-task judge
- `chat.sh` continue-the-chain
- `lib.sh` `sprintmd_next_blocked_resolution` Path A

## Models

| Source | Behavior |
|--------|----------|
| `MODEL_*` config | Honored via `--model` |
| Empty + tier model | `grok-4.5` on grok-build |
| Per-script pins | `MODEL_CHAT` / `MODEL_WORK` / `MODEL_GATE` / … |

## Setup

1. Install Grok Build so `grok` is on PATH
2. `./setup.sh` → choose **Grok Build** → writes `CLI=grok` `PROVIDER=grok-build`
   (or edit `docs/sprintmd/config` the same way; no reinstall needed to switch)
3. Optional: pin `MODEL_DEFAULT=grok-4.5` (or leave empty for tier default)
4. Inside Grok: `./sprint.sh chat` / `work` / `polish` → emit
5. Terminal: same commands → exec launches `grok`
6. Parallel: `./sprint.sh work --fast`
7. Per-run override (does not rewrite config): `./sprint.sh -g work` or
   `./sprint.sh --grok chat 12` (peer: `-c` / `--claude`)

Grok auto-loads `AGENTS.md` / `CLAUDE.md` when present — no mandatory extra
shipping pointer file.

## Capability matrix row

See `docs/sprintmd/ai/provider-capabilities.md` (single source of truth).

## Out of scope (follow-ups)

Claude stream-json filter parity, invented budget caps, Grok `workflow` as
orchestrator (prefer `spawn_subagent` for Claude parity), Gemini/Mistral
profiles.

## Related

| Path | Role |
|------|------|
| `docs/guides/claude-provider-tier.md` | As-built peer tier |
| `docs/guides/command-matrix.md` | Live command names |
| `docs/plans/5-grok-build-first-class-provider.md` | Plan + member tasks |
| `docs/sprintmd/cli/grok.sh` | Profile |
| `docs/sprintmd/guides/use_chat.md` | chat modes |
