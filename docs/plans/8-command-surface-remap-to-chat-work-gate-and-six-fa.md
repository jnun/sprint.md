# Plan 8: Command surface remap to chat work gate and six families

**Created**: 2026-07-30
**Status:** DONE

> A plan is a **relational index, not a container.** It groups related tasks by
> listing their IDs. The tasks never move into this file — each stays in its own
> lifecycle folder (`backlog → next → doing → …`) and its progress is tracked
> there. A plan is never itself a task; it only names a clump of work and its
> intent. `**Status:**` is binary — `DRAFT` while authoring, `READY` when safe
> for `plan start` / `loop --refill` to commit members into `next/`. Progress of
> the work itself derives from where member tasks live. To start this plan, run
> `./sprint.sh plan start <id>` (or move members `backlog/ → next/` by hand) —
> this file does not move.

## Goal

Land the target command surface in `docs/guides/command-matrix.md` as the live
CLI: rename `talk→chat`, `tasks→work` (execute verb only), `define→gate`,
`checkfeatures→align`, `ai-context→context`, `audit-deps→deps`; remap registry
help groups to `create · chat · plan · work · look · keep`; teach the **spine
hierarchy** (happy path vs off-spine) in help and registry; update config keys,
manual, AI guidance, tests; ship via `./ship.sh`; finish with a former-term
grep **and a universal product-doc audit** of `README.md`, `DOCUMENTATION.md`,
and `docs/guides/command-matrix.md` that proves public docs and the live CLI
tell the same story.

When this plan is done, a user (and an agent) types the loop out loud:

```
./sprint.sh chat … → plan start → work → polish
```

…and `./sprint.sh help` shows only the six family labels, with the work family
summaries ranked so the happy path is obvious. Retired command names fall
through to generic help (no runtime redirects).

## Why

The matrix is the target-state spec for how the product injects human decision
(`chat`) and runs automation (`work`). Living on `talk`/`tasks`/`define` and
parallel taxonomies (`pipeline`/`workflow`) forces every agent to translate.
One coherent remap — not drip renames — keeps dispatch, help, manual, and
validators aligned so we never ship a half-named surface.

## Invariants (do not break)

These are hard stops. Any task that would violate one is wrong, not partial.

1. **Task noun stays.** `docs/tasks/`, `newtask`, lifecycle folders
   (`backlog→next→doing→blocked→review→done`), and "task" as the unit of work
   are **not** renamed. Only the *execute command* becomes `work`.
2. **`validate-tasks.sh` keeps its name** unless a later plan renames it for
   other reasons — it validates task *files*, not the execute command.
3. **No runtime aliases** for retired commands (`talk`, `tasks`, `define`,
   `checkfeatures`, `ai-context`, `audit-deps`). Deleted dispatch labels only.
4. **Edit `docs/` then `./ship.sh`.** Never hand-copy into `src/`. Root
   `sprint.sh` and `DOCUMENTATION.md` are edited live and mirrored by ship.
5. **Config dual-read only if needed for one ship.** Prefer rename keys and
   update all readers in the same plan; do not leave permanent `MODEL_TASKS`
   aliases. If a one-release dual-read is required, document it and remove it
   in #274 or a follow-up — not forever.
6. **Historical archives are not the product.** Files under `docs/tasks/done/`,
   completed plan bodies, and old task prose may still say `talk`/`tasks` as
   history. #274 allowlists those paths; live surface paths must be clean.
7. **Profession words stay retired** as command names: no resurrecting
   `audit`, `excellence`, or `review-*` as top-level commands.
8. **`sync` command stays** — family label becomes `keep`, but the command
   name `sync` does not change. Do not conflate registry group rename with
   command rename.
9. **Source uniformity for gate:** CLI file is `gate.sh` (user command
   `./sprint.sh gate`). Shared workability library is `gate-lib.sh` (sourced
   only — never a registry row, never `run_script`). `plan start` sources
   `gate-lib.sh`. Never merge CLI and library into one file.
10. **Spine hierarchy is first-class.** Happy path is always taught as
    `chat → plan start → work → polish`. In the work family, `work` and `loop`
    are spine; `gate`, `split`, and `polish` are labeled off-spine or
    post-work — never presented as five peer "next steps" with equal weight.

## Decision locks (read before executing)

These close every fork an agent would otherwise invent mid-flight.

### A. Atomic surface cut (#265)

#265 owns **together**:

- full registry: six groups on **every** row (not only the six renames)
- dispatch `case` + `cmd_*` names
- help **basenames** (`talk.md→chat.md`, …) with minimal usage-line edits
- `sprint.sh` help section titles
- `DOCUMENTATION.md` Commands block **tokens** only (`sprint.sh <newcmd>`)
- `check-commands` group allowlist
- **spine hierarchy in registry one-line summaries** for the work family (and
  plan/chat tips that name the happy path)

#265 does **not** rename script bodies. Temporary `run_script` targets to old
basenames are required and fine.

### B. Full family map (matrix)

| Family | Commands |
|--------|----------|
| create | newidea, newfeature, newtask, newplan, newbug, newtest |
| chat | chat |
| plan | plan |
| work | work, loop, gate, split, polish |
| look | status, search, align, context |
| keep | profile, sync, validate, cleanup, deps |

### C. define → gate layout (#268) — source uniformity

| File | Role |
|------|------|
| `gate-lib.sh` | Sourced library only (`sprintmd_gate_*`) — `git mv` from today's `gate.sh` |
| `gate.sh` | CLI for `./sprint.sh gate` — `git mv` from today's `define.sh` |
| `help/gate.md` | User help (basename from #265) |

**Rename order (collision-safe):**

1. `git mv gate.sh gate-lib.sh`
2. Update every `source …/gate.sh` → `source …/gate-lib.sh` (`plan-start.sh`, CLI body, any other sourcers)
3. `git mv define.sh gate.sh`
4. `cmd_gate` → `run_script "gate.sh"`

No merge of CLI into the library. No `gate-run.sh`. No other design options.

### D. Spine hierarchy (efficient usefulness)

Taught everywhere agents look first (registry summaries, `help`, manual happy
path, AI guidance):

```
chat  →  plan start  →  work  →  polish
 │            │            │         │
 shape     commit       execute   quality
 (human)   (+ gates)    queue     after
```

| Command | Role in hierarchy |
|---------|-------------------|
| `chat` | Before the sprint — shape tasks / plans / bugs with a human |
| `plan start` | Commit members into `next/` (gates as it promotes) |
| `work` | **Happy-path execute** — READY tasks in next/ → review/ |
| `loop` | **Spine on autopilot** — plan start refill + work drain |
| `gate` | **Off-spine** — re-gate next/ after edits, or report on other folders |
| `split` | **Off-spine** — one-shot atomic split (no conversation) |
| `polish` | **After work** — quality sweep / deep-judge / `--code` |

Registry one-liners and help pages must use this language (e.g. "Happy path",
"Off-spine", "After work") so a flat work-family list does not invite equal
weight for `gate` and `split`. Owned primarily by #265 (summaries) and #271
(prose); help bodies for individual commands reinforce in #266–#269.

### E. Invocation ownership (#266–#269)

Each rename task owns **every** live `./sprint.sh <oldname>` under
`docs/sprintmd/` for its old name(s), not only its primary script:

| Task | Owns old name(s) | Primary file work |
|------|------------------|-------------------|
| #266 | `talk` | talk* → chat* scripts; use_talk → use_chat |
| #267 | `tasks` (command) | tasks.sh → work.sh |
| #268 | `define` | library → gate-lib.sh; define.sh → gate.sh |
| #269 | `checkfeatures`, `ai-context`, `audit-deps` | scripts + help bodies |

#271 owns manuals, AI, features, provider guides, cli commentary, and full
spine-hierarchy prose.

### F. Config keys (#270)

**Rename hard-cut:** `MODEL_TALK→MODEL_CHAT`, `MODEL_DEFINE→MODEL_GATE`,
`MODEL_TASKS→MODEL_WORK`, `BUDGET_TASKS→BUDGET_WORK`; clean
`MODEL_TRIAGE` / `MODEL_REVIEW_SPRINT`.

**Out of scope this plan:** `MODEL_AUDIT`, `MODEL_EXCELLENCE`,
`MODEL_CODE_AUDIT`, `MODEL_SPRINT`, and other polish/internal keys.

### G. Validate / test / ship phases

| After | Expectation |
|-------|-------------|
| #265 | `validate --commands` **green**; spine language in registry summaries |
| #266–#271 | Surface usable; tests may still assert old names |
| #271 | Content ready for the universal product-doc audit (README, DOCUMENTATION, matrix) |
| #272 | `validate --commands` + `--docs` + tests **green**; **owns** stale-command regression test extension |
| #273 | `./ship.sh` + fresh `./setup.sh` smoke |
| #274 | Former-term grep zero; **universal product-doc audit** passes; re-ship if fixes |

### H. Universal product-doc audit (README · DOCUMENTATION · matrix)

Plan 8 is not done until these three files are checked **against each other and
against the live CLI**. They are the public story of the product; grepping
scripts alone is not enough.

| File | Role in the audit |
|------|-------------------|
| `docs/guides/command-matrix.md` | Target-state catalog + spine + six families + retired table |
| `DOCUMENTATION.md` | User/agent manual — must teach the same surface and spine |
| `README.md` | Front door — must not teach old commands or old groups |

**Audit checklist** (run at end of #274; #271 prepares the content):

1. **Six families** — all three present `create · chat · plan · work · look · keep` (or equivalent clear listing); none teach `pipeline` / `workflow` / `inspect` / `maint` as live help groups.
2. **Six renames live** — `chat`, `work`, `gate`, `align`, `context`, `deps` appear as commands where the file teaches the CLI; retired names appear only as history (matrix retired table is allowlisted).
3. **Spine hierarchy** — happy path `chat → plan start → work → polish` (or `plan start → work` where abbreviated) is explicit; `gate` / `split` not presented as the default next step after plan start.
4. **Task noun** — `docs/tasks/`, `newtask`, and “task” as the unit of work are preserved; execute verb is `work`.
5. **Matrix not regressed** — `command-matrix.md` still matches the plan’s family map and retired table; do not edit the target down to match a half-finished CLI.
6. **Cross-file agreement** — no contradiction between README, DOCUMENTATION, and matrix on command names, groups, or happy path.
7. **Live CLI agreement** — `./sprint.sh help` families and command list match what those three files teach (spot-check: help index vs each file’s command story).
8. **Command-shaped greps on the three files** — zero unexplained `./sprint.sh talk|tasks|define|checkfeatures|ai-context|audit-deps` in README or DOCUMENTATION; matrix only in retired-names / history sections.

Paste a short audit result (pass/fail per checklist row) into #274 `## Completed`.

### I. Parallelism

Default remains **strict sequential** (#265 → … → #274). Do not parallelize
#266–#269 unless a human deliberately accepts a half-updated dogfood tree.

## Execution order

1. **#265** — Atomic surface cut (registry, dispatch, help basenames, manual tokens, six families, spine summaries).
2. **#266** — talk* scripts → chat*; all live `./sprint.sh talk` strings.
3. **#267** — tasks.sh → work.sh; all live `./sprint.sh tasks` (execute command only).
4. **#268** — library `gate.sh` → `gate-lib.sh`; CLI `define.sh` → `gate.sh`; all live `./sprint.sh define`.
5. **#269** — align / context / deps scripts + bodies; all live old three names.
6. **#270** — Config MODEL/BUDGET renames (in-scope keys only).
7. **#271** — Manual, GETSTARTED, README, AI, guides; prepare README + DOCUMENTATION + matrix for the universal audit.
8. **#272** — Tests + validate --docs; stale-command regression test.
9. **#273** — `./ship.sh` + fresh install smoke.
10. **#274** — Grep former terms; **universal product-doc audit** (README · DOCUMENTATION · matrix); fix; re-ship if needed.

## Break-risk audit (pre-start)

| Risk | Mitigation |
|------|------------|
| Renaming `docs/tasks/` or `newtask` by accident | #267 success criteria + #274 greps with path allowlist |
| `loop` still calls `tasks` internally | #267 owns every live `./sprint.sh tasks` |
| `plan start` / library / CLI tangle | Invariant 9 + #268: rename library first (`gate-lib.sh`), then CLI to `gate.sh` |
| Help/registry/dispatch drift | #265 makes `--commands` green; #272 reconfirms + `--docs` |
| Flat work family invites equal use of gate/split | Decision lock D + #265 summaries + #271 prose |
| `src/` only half-mirrored | #273 mandatory; #274 re-ships after late fixes |
| Config still exports `MODEL_TASKS` while scripts read `MODEL_WORK` | #270 hard cut both sides |
| Agents in flight still type `talk`/`tasks` | Expected; no redirects; matrix retired table is the map |
| Test names `test-tasks-excellence.sh` etc. | Rename only if they assert the *command* name; file names can lag if content asserts `work` |
| `BUDGET_TASKS` / env docs in README | #270 + #271 |
| Provider / feature / cli guides still say talk/tasks/define | #271 |
| README / DOCUMENTATION / matrix disagree or lag live CLI | Decision lock H + #271 prepare + #274 universal audit |
| `check-commands.sh` hardcodes old groups | #265 |
| Grep noise from English "talk" / "define" | #274 uses command-shaped patterns only |
| Half-cut after #265 without help pages | Forbidden — help basenames move in #265 |
| Accidentally `run_script "gate-lib.sh"` | #268: library is source-only; only `gate.sh` is the CLI |
| Matrix edited down to match a broken CLI | #271/#274: matrix is target-state; fix the CLI or docs up, never the matrix down |

### Out of scope (explicit)

- Renaming the task noun, `docs/tasks/`, or lifecycle folders
- Rewriting all `docs/tasks/done/*` history to new verbs
- Re-opening plan 2's already-landed matrix work except as dependency context
- Changing polish modes, plan think/start behavior, or chat conversation method (names only unless a string forces a path rename)
- Renaming polish-mode config keys (`MODEL_EXCELLENCE`, `MODEL_CODE_AUDIT`, `MODEL_AUDIT`, `MODEL_SPRINT`, …)
- **Plan 5 (Grok Build first-class provider)** — held until this plan ships so
  Grok work lands only on `chat` / `work` / `gate` names (see plan 5
  prerequisite). Do not start plan 5 while plan 8 is open.

## Member tasks

<!-- Ordered = execution order (see above). References only — resolve each ID
     against docs/tasks/*/ for its current location. -->

- [x] #265 — Remap registry and dispatch to chat/work/gate/align/context/deps + six family groups
- [x] #266 — Rename talk scripts and callers to chat
- [x] #267 — Rename tasks execute command to work without touching the task noun
- [x] #268 — Rename define command to gate
- [x] #269 — Rename checkfeatures / ai-context / audit-deps → align / context / deps
- [x] #270 — Rename config MODEL/BUDGET keys for chat, work, gate
- [x] #271 — Sweep manual, GETSTARTED, README, AI, and guides for the new surface
- [x] #272 — Update tests and validate --commands/--docs for the renamed surface
- [x] #273 — Ship mirror and fresh-install smoke the renamed CLI
- [x] #274 — Grep former terms + universal product-doc audit (README · DOCUMENTATION · matrix)

## Done when

- [x] `./sprint.sh help` lists groups `create · chat · plan · work · look · keep` only
- [x] `./sprint.sh chat`, `work`, `gate`, `align`, `context`, `deps` dispatch
- [x] `./sprint.sh talk|tasks|define|checkfeatures|ai-context|audit-deps` do **not** dispatch
- [x] `docs/tasks/` still exists; `newtask` still works
- [x] CLI is `docs/sprintmd/scripts/gate.sh`; library is `gate-lib.sh` sourced by plan-start and the gate CLI (not a command)
- [x] **Spine hierarchy visible:** registry work-family one-liners (and manual/help happy path) present `plan start → work` as happy path; `gate` / `split` labeled off-spine; `polish` after work; `loop` as autopilot spine
- [x] **Universal product-doc audit passes** on `README.md`, `DOCUMENTATION.md`, and `docs/guides/command-matrix.md` (Decision lock H — all eight checklist rows)
- [x] `validate --commands` and `--docs` pass; relevant tests pass (including stale-command regression from #272)
- [x] `./ship.sh` mirror clean; fresh setup install exercises new names
- [x] #274 grep report: zero unexplained hits on live surface paths (`docs/` and `src/`)
