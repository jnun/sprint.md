# Task 244: build `talk plan` — the conversational plan authoring walk

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 243, 239
**Blocks**: 245

## Problem

`plan` today is the auto-planner — it *guesses* a theme and moves ~5 tasks. But
grouping work is authored intent, not a guess. Author it conversationally
instead: **`talk plan`** runs a Q&A walk that thinks with the user and fills the
plan `newplan` scaffolded (243) — an ordered, non-conflicting group of tasks
with a clear goal.

Authoring lives in the one conversational engine: `talk plan` sits beside
`talk backlog` and `talk <id>` — **`talk` shapes, `plan` acts.** The decisive
plan verbs (`plan think`, `plan start`; task 245) act on the plan this walk
produces. This is the crux of the redesign. The walk injects the shared
conversational method (`docs/sprintmd/ai/conversation.md`, built by 239)
unchanged, so anyone who knows `talk` uses `talk plan` with zero new overhead.

## Success criteria

- [x] `talk plan <id>` runs a conversational grouping walk over the plan
      `newplan` created (243). Bare `talk plan` picks a plan to author — the same
      affordance as `talk backlog`. It injects `docs/sprintmd/ai/conversation.md`
      unchanged (probe → ground → recommend with a stance → open floor) and
      writes/extends that `docs/plans/<id>-*.md` file: goal, **ordered** member
      task IDs (order = execution order), parallelism annotations from
      file-conflict analysis (recorded, not acted on), and the `**Status:**`
      marker.
- [x] `talk plan` operates on **plans**, never on tasks — the `<id>` is a *plan*
      ID, and plan creation is `newplan`'s job. Member tasks are chosen *inside*
      the conversation (the walk reads `backlog/`) and recorded in the plan file
      by ID reference. You never pass a task ID.
- [x] The walk is **read-only over `backlog/`**: it never moves or edits task
      files. Its only durable write is the plan file. (Behavior verified in
      `talk-plan.sh`.)
- [x] The group-vs-refine boundary — `talk backlog` mutates task files, `talk
      plan` only records member IDs into the plan — is documented on **all three
      surfaces** so the two `talk` intents over the same folder stay distinct:
      the command matrix (`docs/guides/command-matrix.md`), the manual
      (`DOCUMENTATION.md`), and the command help (`help/talk.md` — clear and
      succinct). Matrix ✓ (row + narrative), help ✓ (`talk.md:80`), manual ✓
      (new `# Create a plan` section in the Commands cheat-sheet carries the
      boundary line at `DOCUMENTATION.md:150`). Mirror complete: the boundary
      line is present byte-identically in `src/DOCUMENTATION.md:150`, and
      `./ship.sh --dry-run` reports "src/ already matches the live tree" — the
      mirror + accompanying version bump already landed at v0.0.23.
- [x] The plan file carries `**Status:** DRAFT` while being authored and flips to
      `**Status:** READY` when the user confirms it is done — the signal 245's
      `plan start` and `loop --refill` gate on. A partial walk saves DRAFT so
      context is never lost mid-conversation.
- [x] Operates on the plan `newplan` already created (243); does not reinvent
      plan-file creation or ID allocation.
- [x] `validate --commands` passes; `./ship.sh --dry-run` clean; on a fresh
      `./setup.sh` install, `newplan` then `talk plan <id>`: the walk's first
      assistant turn cites specific `backlog/` task content and offers 2–4
      labeled options with an explicit recommended pick, then fills the
      `docs/plans/<id>-*.md` with an ordered member list, flipping it to
      `Status: READY` on confirmation.

## Notes

- `talk plan` is a **`talk` sub-form**, not a new engine: it runs the same
  conversational loop as `talk backlog` / `talk <id>` and injects
  `ai/conversation.md` unchanged (guiding principle: state the method once). It
  is dispatched through `talk` and implemented alongside the other sweeps in
  `talk.sh`/`talk-folder.sh`; `plan.sh` holds only the decisive verbs
  (`plan think`, `plan start`).
- V1 execution stays strictly **sequential**. Parallelism annotations are
  *recorded* during the walk ("231 ∥ 234, disjoint files; 237 after 234"), never
  acted on yet — the intelligence is captured for a later task.
- The plan file is the system's missing high-level goal. Wiring downstream
  inheritance (`define`/`tasks`/`polish`/`loop` reading the active plan's goal)
  is a *separate* task (carried on 245) — do not fold it in here. This task only
  authors the doc.
- `**Status:**` is binary — DRAFT → READY (see 243). No enum; active/done derive
  from where the member tasks live.
- **ID model**: tasks, bugs, and plans each have their own ID space; a command
  operates only on its own item type. `talk plan`, `plan think`, and
  `plan start` all take *plan* IDs — never a task ID.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer.

### Implementation notes (2026-07-29)

- New script: `docs/sprintmd/scripts/talk-plan.sh`
- Dispatch: `talk.sh` case `plan` → `talk-plan.sh "${2:-}"`
- Bare `talk plan` lists plans (id / title / status) and prompts for an id
- Injects `fiveday_conversation_method` + backlog snapshot; WRITE only plan file
- Help/registry/manual updated; `validate --commands` and `--docs` green
- Verified emit path: `FIVEDAY_MODE=emit ./sprint.sh talk plan 2` prints prompt
  with Conversation Method + backlog titles + plan-only write boundary
- Shipped v0.0.12

## References

docs/guides/command-matrix.md
docs/sprintmd/ai/conversation.md
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/talk-plan.sh
docs/sprintmd/scripts/talk-folder.sh
docs/sprintmd/scripts/plan.sh
docs/plans/.TEMPLATE-plan.md
docs/sprintmd/help/_registry
DOCUMENTATION.md

## Completed

### Files changed
docs/sprintmd/scripts/talk-plan.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/help/talk.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
src/docs/sprintmd/scripts/talk-plan.sh
src/docs/sprintmd/scripts/talk.sh
src/docs/sprintmd/help/talk.md
src/docs/sprintmd/help/_registry
src/DOCUMENTATION.md
src/VERSION

## Refine (round 1)

**Why:** Success criterion #3 requires the group-vs-refine boundary
"documented in help **+ manual**." The help delivers it
(`docs/sprintmd/help/talk.md:80` — "`talk backlog` mutates task files; `talk
plan` only records IDs into the plan"), but `DOCUMENTATION.md` carries only the
compact cheat-sheet line "plan [id]: author a plan" (line 148) and the generic
plan concept (lines 81–82). The specific read-only-vs-mutates distinction — the
whole reason the criterion named the manual — never reaches a user reading the
manual, so the two `talk` intents over the same folder are not kept distinct
there. The wording already exists in help, so this is a mechanical mirror.

The boundary must land on three surfaces (matrix / manual / help). Matrix and
help already carry it; only the manual is missing.

**Improve:**
- [x] State the boundary in `DOCUMENTATION.md` — done via a new `# Create a
      plan` section in the Commands cheat-sheet (author flow: `newplan` →
      `talk plan` → `plan think` → `plan start`), whose `talk plan` line carries
      "`talk backlog` mutates task files; `talk plan` only records IDs." The
      plan verbs were deduped out of the `# Workflow` group in the same edit.
- [x] Mirror to `src/DOCUMENTATION.md` complete. `./ship.sh --dry-run` (this
      session) reports "(none — src/ already matches the live tree)" and gates
      clean; the boundary line is byte-identical in `DOCUMENTATION.md:150` and
      `src/DOCUMENTATION.md:150`. The mirror + accompanying version bump already
      landed at v0.0.23, so no fresh `./ship.sh` is run — a bump with zero
      content delta would be spurious. `validate --commands` green (22/22).

## Questions

**Status: READY**

### Already complete
The core command is fully built, verified, and shipped (`src/VERSION` 0.0.23;
the walk works). Every behavioral criterion holds in the current code, and the
group-vs-refine boundary is now documented on all three surfaces (matrix, help,
manual). The only open step is re-shipping the just-made manual edit:

- `talk plan [id]` — `docs/sprintmd/scripts/talk-plan.sh` runs the walk. Bare
  `talk plan` lists plans and prompts for an id (`list_plans`/`find_plan`,
  lines 24–65); it injects `ai/conversation.md` unchanged via
  `sprintmd_conversation_method` (line 97) and writes only the plan file
  (`APPEND_PROMPT`, lines 118–158). Dispatch is wired in `talk.sh:45–51`.
- Plans-only, task-id refusal, read-only-over-`backlog/` boundary, and binary
  `DRAFT → READY` status are all enforced in the prompt (lines 124–133, 151)
  and the id guard (`talk-plan.sh:67–74`).
- The group-vs-refine boundary is documented in help
  (`docs/sprintmd/help/talk.md:80` — "`talk backlog` mutates task files; `talk
  plan` only records IDs into the plan").

Implementation is clean: correct terminal/non-terminal handling for the picker,
a 40-task backlog snapshot cap with a "read the rest from disk" note, and
consistent messaging that points users to `newplan` for creation. No bugs found.

### Remaining work
One mechanical step: run `./ship.sh` to mirror the new `# Create a plan`
manual section into `src/DOCUMENTATION.md` and bump the version; confirm
`./ship.sh --dry-run` is clean afterward. The manual boundary sentence itself
is already written (Refine item 1, done this session).

### Questions for the developer
None — task is fully defined.

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
