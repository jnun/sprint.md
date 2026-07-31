# Plan 11: Grok firm-up, model CLI, and dual-provider smoke

**Created**: 2026-07-30
**Updated**: 2026-07-30
**Status:** STARTED

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. STARTED is a **one-way switch** set
> by `plan start`; it does not change while members move through
> `next/doing/review/done`. When every member is in `docs/tasks/done/`,
> `./sprint.sh plan done <id>` deletes this file. Progress of work is where
> members live, not this Status field.

## Prerequisite

Plan 5 (Grok Build first-class provider) has shipped: `cli/grok.sh`,
`grok-build` tier, `GROK_AGENT` emit, shared orchestration helpers, unit tests.
This plan does **not** re-build that foundation. It **firms fuzzy edges**,
**exposes model control on the CLI**, and **establishes smoke rituals** so
later plans can trust both Claude and Grok.

## Goal

Four outcomes, in product language:

1. **Inventory reality** — one living list of **known knowns** and **known
   unknowns** (tools, subagents, models, spine, install), burned down human +
   AI, so later real-project work does not re-derive the same fog. Unknown
   unknowns stay a watchlist + append log, not a fake catalog.
2. **Firm the fuzzy** — tools and subagent handoff on Grok are verified on a
   live install (IDs, emit spawn behavior, worker types), not only unit-tested
   wording and a best-effort map.
3. **Expose model choice** — a user can show / list / set models from
   `./sprint.sh` without hand-editing config or memorizing env vars; per-run
   overrides are discoverable on the spine commands.
4. **Smoke both hosts** — Claude-proven spine re-run under Grok; then a short
   dual-provider protocol on a **fresh project** so upcoming plans have a
   repeatable “ship confidence” checklist.

When this plan ships, Grok is not merely registered — it is **exercised** — and
model switching is a first-class sprint.md action.

## Why

Plan 5 closed the capability gap. Remaining risk is **trust**:

| Risk | If we skip it |
|------|----------------|
| Wrong shell tool id | Headless allowlists fail open or break shell |
| Emit spawn unproven | Parallel `work`/`gate` is theater on Grok |
| One worker type for all | Gate runs overweight agents; slower, riskier |
| Models only in config | Users cannot switch models deliberately mid-sprint |
| No dual smoke protocol | Next plans ship Claude-only confidence again |

## Themes (map to members)

### 0 — Shared inventory (human-heavy)

| Task | Delivers |
|------|----------|
| **#298** | Laundry list of known knowns + known unknowns; burn-down log; UU watchlist. **Start here** with human + AI; outcomes feed the rest. |

### A — Firm tools & subagents (fuzzy → known)

| Task | Delivers |
|------|----------|
| **#291** | Live-verify Grok internal tool IDs; lock `cli/grok.sh` map + test |
| **#292** | Dogfood emit `spawn_subagent` handoff; harden depth-1 / orchestrator-only prompts |
| **#293** | Role → subagent type (and capability_mode if safe): gate vs work vs polish |

### B — Model choice on the CLI

| Task | Delivers |
|------|----------|
| **#294** | `./sprint.sh model` show / list / set (config + effective resolution) |
| **#295** | Help + optional `--model` on spine commands; teach precedence |

### C — Smoke testing for this and later plans

| Task | Delivers |
|------|----------|
| **#296** | Grok smoke of Claude-proven spine (checklist + one real run) |
| **#297** | Dual-provider fresh-project protocol for upcoming plan ship gates |

## Execution order & parallelism

```
298 (inventory burn-down — human + AI; parallel with early build)
 │
 ├──► 291 ──► 292 ──► 293 ──► 296 ──► 297
 │                     ▲                ▲
 └──► 294 ──► 295 ─────┴────────────────┘
```

1. **#298** first or continuous — walk KK/KU with human + AI; stamp outcomes;
   spawn/amend tasks only where needed. Does not block starting #291/#294 once
   those rows are clearly COVERED by those tasks.
2. **#291** — tool map is foundation for honest exec smoke.
3. **#292** after #291 — emit handoff dogfood.
4. **#293** after #292 — specialize types once handoff is proven.
5. **#294** parallel with #291–#293 — model CLI is independent of Grok tool fuzz.
6. **#295** after #294 — discoverability and flags build on `model` command.
7. **#296** after #291–#293 — Grok spine smoke needs firm tools/subagents;
   append Surfaced unknowns to #298 as UU appear.
8. **#297** after #294 + #296 — protocol uses model CLI and assumes Grok spine
   already green once.

## Member tasks

- [ ] #298 — Inventory known knowns and known unknowns for dual-provider tools models and smoke
- [ ] #291 — Verify and lock Grok tool ID map for headless allowlists
- [ ] #292 — Prove Grok emit subagent handoff and harden orchestration prompts
- [ ] #293 — Specialize Grok subagent types for gate vs work vs polish
- [ ] #294 — Expose model show list and set from the sprint.md CLI
- [ ] #295 — Make per-command model overrides discoverable on help and common flags
- [ ] #296 — Smoke-test Claude-proven spine under Grok Build
- [ ] #297 — Dual-provider smoke protocol on a fresh project for upcoming plans

## How to start

```bash
# When READY (after any chat refinement):
./sprint.sh plan start 11
# Prefer --commit-only if members are already stamped READY and you want
# the board without re-gating:
# ./sprint.sh plan start 11 --commit-only

# Human + AI inventory first (or in parallel with 291/294):
./sprint.sh chat 298

./sprint.sh work          # or: chat 291 / chat 294 to refine first
```

## Open decisions (resolve during #293 / #294)

1. **Gate worker type** — pure `explore` cannot edit task files; if gate emit
   requires Edit/Write on the task file, use `general-purpose` + strict prompt
   contract, or verify `capability_mode: read-write` allows task-file edits
   only via permissions. Decision lands in #293 success criteria.
2. **`model list` for Claude** — if there is no cheap reliable `claude models`
   equivalent, `list` is Grok-complete and Claude returns known aliases +
   “see provider” rather than inventing an API.
3. **Command name** — recommendation: `model` (not `config model` nested).
   Rename only if registry collision appears at implement time.
4. **Smoke automation level** — checklist + optional script for non-interactive
   bits; full TUI chat remains manual.

## Out of scope

- Third provider profiles (Cursor/Codex/Gemini)
- Claude stream-json parity / Grok resume loop (follow-up reliability plan)
- Invented budget caps on Grok
- Per-provider product instruction file trees
- Making this repo’s default CLI Grok permanently (dogfood switch is fine;
  not a member of this plan unless desired mid-flight)

## Related

| Path | Role |
|------|------|
| `docs/guides/grok-provider-tier.md` | As-built Grok tier |
| `docs/guides/claude-provider-tier.md` | Claude peer |
| `docs/sprintmd/cli/grok.sh` | Tool map |
| `docs/sprintmd/lib.sh` | Tier model + subagent helpers |
| `docs/tests/test-grok-provider.sh` | Unit coverage from plan 5 |
