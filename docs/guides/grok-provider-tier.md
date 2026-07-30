# Grok Provider Tier (target design)

How sprint.md **should** run when the AI provider is **Grok Build** — a peer to
the Claude tier, not a generic passthrough. This is the design guide for plan 5.
It is not as-built until the member tasks ship.

**Language:** target command surface from `docs/guides/command-matrix.md`
(`chat` / `work` / `gate` / …). Plan 5 executes **after** plan 8 lands that
surface — do not implement against retired names (`talk`, `tasks` as the
execute verb, `define`).

As-built Claude reference: `docs/guides/claude-provider-tier.md`.
Work plan: `docs/plans/5-grok-build-first-class-provider.md` (tasks #251–#256).
Command names: `docs/guides/command-matrix.md`.

## Identity (target)

Field				Value
Tier name			grok-build
CLI binary			grok
Profile				docs/sprintmd/cli/grok.sh (new)
Config				CLI=grok and PROVIDER=grok-build
Setup pick			Grok Build (new option in setup.sh)
Session detect		GROK_AGENT=1 → emit mode
Default model today	grok-4.5 (verify with grok models at implement time)

## Goal

User outcome	Meaning
One switch		Pick Grok at setup the same way you pick Claude
Live chat		./sprint.sh chat opens a Grok TUI from a plain terminal
Emit in-session	Inside Grok Build, prompts land here — no nested CLI
Parallel cycles	work / gate / polish use fresh subagents, not one fat session
Honest maps		Flags and tool names match real grok --help, or are dropped with a warning

## Two modes (same product rule as Claude)

Mode	When												What happens
emit	Inside Grok Build (GROK_AGENT set, or MODE=emit)	Print the prompt into this session. Driver uses spawn_subagent for parallel work.
exec	Plain terminal, CI, loops							Spawn grok via cli/grok.sh. Interactive or -p headless.

Today GROK_AGENT is not in sprintmd_ai_mode. Until #253 lands, force MODE=emit
when already inside Grok.

## Neutral interface (unchanged)

Scripts keep calling sprintmd_run / sprintmd_run_interactive. Only the profile
and tier gates change. No script should hardcode grok flags.

## Flag map (neutral → Grok)

Neutral flag			Grok flag						Notes
-p PROMPT				-p / --single PROMPT			Headless; prints and exits
positional prompt		positional						Interactive TUI open message (same idea as Claude)
--model					-m / --model					e.g. grok-4.5
--max-turns				--max-turns						Headless-oriented; cap long jobs
--tools					--tools							Grok internal tool IDs — not Claude names (see below)
--permissions			--permission-mode				default, acceptEdits, auto, dontAsk, bypassPermissions, plan
--skip-permissions		--always-approve (alias --yolo)	Unattended batch / loop
--output-format			--output-format					plain, json, streaming-json
--budget				(drop or map if exposed)		No verified USD budget flag today — do not invent
--name					(drop)							No direct equivalent required
--append-system-prompt	--rules							Append rules to system prompt (prefer over full override)

## Tool names (do not copy Claude strings)

Claude allowlists fail on Grok if passed through blindly. Map or omit.

Claude-style	Grok tool ID (headless)
Read			read_file
Edit / Write	search_replace / write
Bash			run_terminal_command
Grep			grep
Glob			list_dir (and search tools as needed)
Task (subagent)	spawn_subagent (prompt language, not a --tools entry)

Rule: wrong allowlist that empties the toolset is worse than no allowlist.
Interactive TUI may ignore --tools; restriction is for headless jobs.

## Subagents (Grok native)

Grok does not use Claude’s “Task tool” wording. Emit prompts must say Grok.

Concept				Grok
Spawn child			spawn_subagent
Default worker		general-purpose
Read-only research	explore
Planning only		plan
Disable all			GROK_SUBAGENTS=0 or config; or --no-subagents / deny Agent

## Orchestration targets (match Claude outcomes)

Command			Emit on grok-build (target)														Exec on grok-build (target)
work			One spawn_subagent per task; parallel when --fast/--parallel; same file routing	One grok -p (or process) per task via profile
gate (many)		One subagent per file in parallel												Profile one-shot per file
polish (many)	One judge subagent per file														Profile one-shot per file
chat			Interactive grok REPL; chain via fresh subagent for next id						sprintmd_provider_interactive
plan think		Full dual-persona prompt through profile / emit									Same
loop			Refill + work using Grok exec without permission hangs							always-approve / permission-mode auto

Prefer one helper (e.g. orchestration-capable tier) so claude-code and
grok-build share structure and only the subagent **wording** differs.

## Models

Source				Target behavior
MODEL_* config		Honored via --model
Empty + tier model	Strong default on grok-build (today: grok-4.5 unless models menu changes)
Per-script pins		Post–plan 8 keys: MODEL_CHAT / MODEL_WORK / MODEL_GATE / … (same roles as Claude installs)

## Setup and config (target)

Step	Action
1		Install Grok Build so grok is on PATH
2		./setup.sh → choose Grok Build → writes CLI=grok PROVIDER=grok-build
3		Optional: set MODEL_DEFAULT=grok-4.5 (or leave empty for tier default)
4		Inside Grok: ./sprint.sh chat / work / polish → emit
5		Terminal: same commands → exec launches grok
6		Parallel: ./sprint.sh work --fast

## Capability matrix row (target)

Capability			grok-build target
Exec JSON output	yes (json / streaming-json)
Subagent / parallel	yes (emit spawn_subagent + exec multi-process)
Tool restriction	yes when IDs mapped; else omit honestly
Budget caps			no unless verified
Model selection		yes
Emit-mode detection	yes (GROK_AGENT)
Interactive chat	yes (profile)
CLI binary			grok
Profile				cli/grok.sh

Update docs/sprintmd/ai/provider-capabilities.md when this ships so the matrix
stays the single source of truth.

## Implementation map (plan 5)

Task	Delivers
#253	GROK_AGENT → emit in lib.sh
#251	cli/grok.sh exec + interactive
#252	setup picker, tier inference, matrix column, config comments
#255	model defaults, tool/permission mapping
#254	work / gate / polish / chat / plan think orchestration gates
#256	use_chat + README/manual notes, tests, ship smoke

Out of scope for plan 5: Claude stream-json filter parity, invented budget caps,
new shipping pointer files for Grok, Gemini/Mistral profiles.

## Gaps today (before the plan lands)

Gap							Workaround
No cli/grok.sh				SPRINTMD_CLI=grok uses default.sh — one-shot only, flags dropped
No grok-build tier			Scripts treat Grok as generic sequential
GROK_AGENT ignored			MODE=emit inside Grok Build
Emit prompts say Task tool	Only correct under PROVIDER=claude-code
Chat degraded note			Mentions claude only for full interactive

## Related

Path											Role
docs/guides/claude-provider-tier.md				As-built peer tier
docs/guides/command-matrix.md					Target command names (plan 8)
docs/plans/5-grok-build-first-class-provider.md	READY plan + member tasks (after plan 8)
docs/plans/8-command-surface-remap-to-chat-work-gate-and-six-fa.md	Prerequisite remap
docs/sprintmd/ai/provider-capabilities.md		Shipped matrix (update on land)
docs/sprintmd/cli/claude.sh						Template for grok.sh shape
docs/sprintmd/cli/default.sh					Current fallback when no profile
docs/sprintmd/guides/use_chat.md				chat modes today (rename → use_chat in plan 8; extend in #256)
