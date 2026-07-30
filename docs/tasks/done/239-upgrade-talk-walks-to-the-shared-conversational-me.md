# Task 239: upgrade talk walks to the shared conversational method

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/tmp/plan-command-redesign-notes.md
**Depends on**: none
**Blocks**: 244
**Parent**: none

## Problem

`talk` is THE conversational engine, but the method that demonstrably worked
in the 2026-07-29 design session — probe first, ground in conventions,
recommend with a stance, open the floor — exists only as fragments scattered
through its inline prompts (talk.sh's REFINE step 1 and its "lead with the
best practice" / OPEN DECISION rules are proto-versions) and as prose in
docs/tmp/plan-command-redesign-notes.md, a scratch file `cleanup` deletes.
Extract the method to `docs/sprintmd/ai/conversation.md` as the single durable
statement, inject it into every *interactive* talk prompt at runtime, and
reconcile the fragments so it is stated once. `talk plan` (task 244) then
injects the identical file — every talk sub-form converses the same way by
construction.

## Success criteria

- [x] `docs/sprintmd/ai/conversation.md` exists and states the four moves,
      positive-first: (1) **probe** — read the relevant artifacts before
      conversing, draw out what the user is after, restate the emerging shape;
      (2) **ground** — weigh the project's own philosophy and prior decisions
      plus industry conventions, naming trade-offs honestly including where a
      familiar convention brings baggage; (3) **recommend** — 2–4 concrete
      options with the data-backed pick first and reasoning attached, always a
      stance, never a bare menu; (4) **open floor** — the user picks, pushes
      back, or freestyles their intent; loop on new information until settled;
      decisions land in the durable artifact (task file, plan file), never
      only in the chat. Walk-agnostic: no talk- or task-specific wording, so
      `talk plan` (244) injects it unchanged.
- [x] A `lib.sh` helper loads the file at runtime (loud error if missing) and
      each interactive prompt injects its contents: `talk.sh`'s
      `APPEND_PROMPT` (~line 204), `talk-bugs.sh`'s `_define_prompt` in the
      [d] "define it" path (~line 271), and `talk-sprint.sh`'s `APPEND_PROMPT`
      (~line 404). `talk-folder.sh` needs no injection of its own — its
      conversational depth is the shell-out to `talk.sh` (~line 248); verify
      that inheritance and leave its sweep loop alone.
- [x] The scattered fragments are reconciled, not duplicated: talk.sh's REFINE
      step 1 ("lay out the realistic choices… which you would lean toward"),
      the "Lead with the best practice" rule, and the OPEN DECISION
      escape-hatch rule restate pieces of the method — after injection each
      idea lives in exactly one place. Net interactive prompt size stays at or
      below the pre-change byte count of each edited prompt (record `wc -c`
      before and after per prompt); the method file earns its lines by deleting
      the restatements.
- [x] One-shot prompts stay lean: the folder-sweep verdict prompt
      (`talk-folder.sh` `_verdict_prompt`, ~line 152) and talk-bugs' triage
      pass keep their fast-verdict contract with no method injected — the
      method governs dialogues, not verdicts.
- [x] `./ship.sh --dry-run` clean (a new `ai/` file and the `lib.sh` change
      ship via the tree mirror); on a fresh `./setup.sh` install the file is
      present and a `talk <id>` session's first assistant turn cites content
      from the task file/artifacts and offers 2–4 labeled options with an
      explicit recommended pick — not a bare question.

## Notes

> **Context from talk (task 229):** 229 was retired; its work is the plan family —
> **243** (`newplan` rename + epic→plan rebrand), **244** (`talk plan`
> conversational author), **245** (`plan start` + auto-planner retirement). Your
> consumer is now **244**, not 229. Keep `conversation.md` strictly
> walk-agnostic: 244 injects it *unchanged* to author plan files exactly as
> `talk <id>` injects it to refine tasks — so no task- or plan-specific wording,
> and the open-floor "decisions land in the durable artifact" line must read for
> both a task file and a plan file. One term now settled you may reference
> generically: plans carry a binary `**Status:** DRAFT → READY` marker (same
> `READY` word tasks use), flipped when the author confirms the artifact is done.

- Source text: the "conversational method" section of
  docs/tmp/plan-command-redesign-notes.md. This task moves it out of `tmp/`;
  the shipped `ai/` file becomes canonical.
- **Blocks 244**: `talk plan`'s authoring walk consumes `ai/conversation.md` as
  its prompt spec — land this first.
- The OPEN DECISION escape hatch ("want me to pick the sensible default?") is
  method-level behavior — it belongs in the open-floor move of
  `conversation.md`, preserved verbatim in spirit when the talk.sh restatement
  is removed.
- Keep the file short. It is injected into every conversational session, so
  every line costs context (guiding principle 2). Four moves, a few sentences
  each — a protocol, not an essay.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  user.

### Implementation notes (2026-07-29)

- Helper: `fiveday_conversation_method` in `lib.sh` — cats
  `$_FIVEDAY_LIB_DIR/ai/conversation.md`, loud stderr + return 1 if missing.
- Injection points: `talk.sh` APPEND_PROMPT, `talk-sprint.sh` APPEND_PROMPT,
  `talk-bugs.sh` [d] `_define_prompt` only.
- `talk-folder.sh` line ~248 still `bash …/talk.sh "$task_id"` — inherits method.
- One-shots: `_verdict_prompt` in talk-folder and talk-bugs triage path untouched.
- Fragments removed from talk.sh: REFINE open-decision clause, "Lead with the
  best practice" rule, full OPEN DECISION escape-hatch rule. From talk-sprint:
  walk step "On an OPEN DECISION…". Method is the sole home of those ideas.

**Runtime prompt sizes** (string body with `$_METHOD` expanded; bytes):

| Prompt | Before | After | Δ |
|--------|--------|-------|---|
| talk.sh APPEND_PROMPT | 10403 | 7394 | -3009 |
| talk-sprint.sh APPEND_PROMPT | 4440 | 3487 | -953 |
| talk-bugs.sh [d] _define_prompt | 1709 | 1694 | -15 |

Method file: 987 bytes. All three interactive prompts ≤ pre-change size.

## References

docs/tmp/plan-command-redesign-notes.md
docs/sprintmd/lib.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/talk-folder.sh
docs/sprintmd/scripts/talk-bugs.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/ai/feynman-method.md
docs/sprintmd/ai/conversation.md
CLAUDE.md

## Completed

### Files changed
docs/sprintmd/ai/conversation.md
docs/sprintmd/lib.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/scripts/talk-bugs.sh
src/docs/sprintmd/ai/conversation.md
src/docs/sprintmd/lib.sh
src/docs/sprintmd/scripts/talk.sh
src/docs/sprintmd/scripts/talk-sprint.sh
src/docs/sprintmd/scripts/talk-bugs.sh
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
