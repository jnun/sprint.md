# Plan 13: autolearning

**Created**: 2026-07-31
**Status:** STARTED

## Plan Think

Two-role review (Chief Platform Architect × Chief Experience Officer) —
full critique in **docs/tmp/plan-think.md**. Decisions locked in scoping
chat (2026-07-31):

1. **Full curriculum** — ship the story set (S0–S6), not a minimal catalog.
2. **Flat home** — `docs/sprintmd/learning/*.py` + `README.md` (no nested
   `scripts/` until a second runtime exists).
3. **317 = S2 bug→task**; **325 = S6 speed run** (strict distinctiveness bar).
4. **D2 — plan think is an act inside S3 (324)**, not its own demo. Critique
   before `plan start` lives in the feature→plan story.
5. **313** still carries the latent ship bug + trust-guard acceptance (relocate
   demo, fresh install, no-writes verification).
6. **On-ramp UX:** `--help` explains; **`--demo` shows**; help points at
   `<cmd> --demo` (not a printed pointer to `learn`). `learn` remains catalog +
   play-by-name for demos without a host command.

<!-- READY basis: Goal is carried by framework (313) + on-ramp (314) + guide/S1
     (315) + story demos (317, 324, 316, 325). Fill empty members and set
     Depends on: 313 before `plan start`. -->


> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Goal

Ship **autolearning**: a small tutorial framework inside SprintBias that teaches
**a few new concepts to a brand-new user** by letting them *watch* real sessions
— no setup, no risk to their project.

Two layers:

1. **Framework** — `learn` catalog/play, shippable flat home under
   `docs/sprintmd/learning/`, trust contract (writes nothing / no network),
   and a per-command **`--demo`** flag: **`--help` explains, `--demo` shows**,
   help points at `<cmd> --demo` (not at a separate learn invocation).
   Python3 + stdlib first; other runtimes are optional later.
2. **Story curriculum** — short cinematic demos, each a person in a situation.
   Stories grow into each other (capture → convert → plan → automate). Plan
   critique (`plan think`) is **not** its own demo; it is a beat inside the
   feature→plan story (S3).

### Curriculum (flat files)

```text
docs/sprintmd/learning/
  README.md           # curriculum map + authoring rules (315)
  session.py          # S0 — single-session flow (313; from docs/learning/)
  gate.py             # S1 — gate holds, then chat sharpens (315)
  bug.py              # S2 — bug becomes a task (317)
  feature-plan.py     # S3 — feature → tasks → plan think → plan start (324)
  parallel.py         # S5 — honest independent parallelism (316)
  speedrun.py         # S6 — full spine < ~60s, momentum only (325)
```

| Story | Lesson | Task |
|---|---|---|
| S0 session | One problem end to end | #313 |
| S1 gate | Held on purpose, then sharpened | #315 |
| S2 bug → task | A report becomes real work | #317 |
| S3 feature → plan | Many tasks → plan; **plan think** then start | #324 |
| S5 parallel | Independence makes concurrency safe | #316 |
| S6 speed run | Momentum of the whole spine | #325 |
| `--demo` | Help explains · demo shows | #314 |

### Seams

- **313 — engine + home + S0.** `learn` / `learn <name>`, relocate demo into
  `docs/sprintmd/learning/`, no-writes guard, fresh `./setup.sh` install gate.
  Play path must be reusable by `--demo`.
- **314 — on-ramp.** Data-driven `<cmd> --demo` (intercept like `--help`); help
  text says `… --demo` to see how it works. *Depends on 313.* Catalog-only
  demos stay on `learn`.
- **315 — guide + S1.** README = curriculum + authoring rules; gate demo proves
  the pattern; register `gate` → demo when present. *Depends on 313.* Soft-prefer
  before other story demos.
- **317 / 324 / 316 / 325 — story demos.** Each a new `*.py`, auto-registered.
  Host-command stories also set registry demo field for `--demo`.
  *Hard depend 313; soft-after 315 for house style.*
- **326 — command matrix.** Target-state catalog + flag rules for `learn` and
  `--demo`. *Depends on 313 + 314.*

**Dependency order:** **313 first**, then **314 ∥ 315 ∥ story demos**, then
**326** after 313+314.

**Preferred work queue (even when deps allow parallel):**  
**313 → 315 → story demos (S1 already in 315, then S2→S3→S5→S6) → 314 population
pass if needed → 326.**  
314’s *mechanism* may land right after 313 in parallel with 315; do **not**
author later story scripts before 315’s README so house style stays one source.
Soft story order in the catalog: S1 → S2 → S3 → S5 → S6.

**Parallelism:** 314 and 315 both touch `sprint.sh` / `_registry` with 313 —
keep **313 → 314** hard. Story `.py` files are disjoint. V1 may stay sequential.

## Why

SprintBias's bet is that people and agents learn fastest by watching the flow
run. Autolearning turns that into on-demand theater: safe, stdlib-only, listed
from `learn`, and one flag away from any command that has a demo (`--help` vs
`--demo`). A small set of stories covers the concepts a new user actually needs.

## Member tasks

<!-- The tasks in this plan, by ID only — one "- #ID — short title" line each
     (checkboxes optional; [x] means the task is in docs/tasks/done/). These are
     references, not paths: resolve each ID against docs/tasks/*/ for location.
     Moving a member needs no edit here unless syncing checkboxes. -->

- #313 — Framework: learn engine, flat learning home, trust guard, S0 session demo
- #314 — Per-command --demo flag (help explains, --demo shows)
- #315 — Authoring guide (README) + S1 gate demo
- #317 — S2 learn demo: bug becomes a task
- #324 — S3 learn demo: feature → plan (includes plan-think act, then plan start)
- #316 — S5 learn demo: honest parallelism (independent tasks)
- #325 — S6 learn demo: full-spine speed run (< ~60s, momentum only)
- #326 — Update command-matrix.md for learn + per-command --demo

**Member 326** documents the target surface in `docs/guides/command-matrix.md`
after 313+314 exist (*Depends on: 313, 314*). Soft guidance for story demos:
work **after 315** so they conform to the README.
