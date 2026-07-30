# Task 262: upgrade polish rework — reopen completed work by Reworked header count, not by grepping Refine headings

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

The `polish` sweep decides whether a finished task has already used its rework
round by counting `## Refine` headings in the file —
`_refine_round() { grep -c '^## Refine' }` (`polish.sh:778`). That heading is
not polish's alone: a pre-work definition pass, a `talk` walk, or a hand edit
can all write it, and the count is permanent once written. So polish skips
tasks it has *never actually judged* — the round cap fires on a text pattern,
not on a record of polish having run. Observed live this session: tasks 243 and
244 were skipped ("already at the round cap (1)") because each carries a
`## Refine (round 1)` section, whether or not a real polish sweep produced it.
Polish should count its OWN reworks against an explicit header counter that only
polish increments.

## Success criteria

- [x] The task template carries a `**Reworked**: 0` header field (0–X), and the
      polish round cap keys on that counter — not on `grep -c '^## Refine'`.
- [x] A polish REOPEN increments `Reworked` by 1 and stamps its section under a
      heading that reads as *rework* (e.g. `## Rework (round N)`), distinct from
      the pre-work "refine" section owned by task 261, so the two operations
      never share a marker again.
- [x] Re-running `polish` on a task whose `## Refine`/definition sections exist
      but whose `Reworked` is below the cap DOES judge it (no false skip); a
      task at `Reworked: >= MAX_ROUNDS` is correctly capped. Verify against the
      current tasks 243/244 in `review/`.
- [x] `--force` and `--rounds N` still behave as documented, now measured
      against `Reworked`.
- [x] Help (`help/polish.md`) and the refine protocol
      (`ai/refine.md`) describe the counter-based cap accurately.

## Notes

- Pairs with task 261 (pre-work refinement). Both add a header counter to the
  SAME template head — coordinate so the edits don't collide. Split: 261 owns
  `Refined` + the pre-work flow and section; 262 owns `Reworked` + the polish
  cap and section rename.
- Root cause is the heading doing double duty as both polish's *output* and
  polish's *"already ran" marker*. Separating output (a `## Rework` section)
  from state (a `Reworked:` integer) removes the ambiguity.
- Migration: existing review/ tasks carry `## Refine (round 1)` but no
  `Reworked` field. Decide how they seed — treat a missing field as `0` (so
  they become judgeable again) rather than back-counting old headings, which
  reintroduces the exact conflation this task removes.
- Live edit under `docs/sprintmd/`; then `./ship.sh` mirrors + bumps.

## References

docs/sprintmd/scripts/polish.sh
docs/sprintmd/help/polish.md
docs/sprintmd/ai/refine.md
docs/tasks/.TEMPLATE-task.md
docs/tasks/review/243-rename-newepic-to-newplan-and-finish-the-epic-to-p.md
docs/tasks/review/244-build-the-conversational-plan-authoring-command.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

## Completed

Separated polish's **output** (a `## Rework` section) from its **state** (a
`**Reworked**:` integer), so the round cap can no longer fire on a heading that
a define pass, a `talk` walk, or a hand edit might have written.

- **Template** (`.TEMPLATE-task.md`): added `**Reworked**: 0` to the metadata
  head (after `**Parent**:`). `create-task.sh` copies the template verbatim, so
  every new task starts at `Reworked: 0` with no code change there — verified via
  a fresh `./setup.sh` install and `./sprint.sh newtask`.
- **polish.sh**: replaced `_refine_round()` (`grep -c '^## Refine'`) with three
  focused helpers:
  - `_rework_count` reads the `**Reworked**:` header integer (missing ⇒ `0`) —
    this is what the round cap and the round-number now key on.
  - `_rework_sections` (`grep -c '^## Rework'`) is the reopen-confirmation signal
    that the judge actually appended a section.
  - `_bump_reworked` increments the header by 1 on a confirmed reopen — the shell
    owns this state write (deterministic beats trusting the model). A legacy task
    lacking the field gets it seeded at the end of the metadata block.
  The exec loop now confirms a reopen by the new `## Rework` section appearing,
  bumps the counter, then moves the file. Both emit-mode orchestrator prompts
  (claude-code and generic) route on `## Rework (round N)` and are told to bump
  the counter. `--force` / `--rounds N` flag parsing is unchanged; only what the
  cap measures moved to `Reworked`.
- **ai/refine.md** and **help/polish.md**: describe the counter-based cap, the
  `## Rework` section name, and that the judge appends the section while the
  runner owns the `**Reworked**:` counter.

Migration: a legacy `review/` task with `## Refine (round 1)` but no `Reworked`
field reads as `0` (judgeable again) rather than back-counting old headings —
verified against the live tasks 243 and 244, which now report `Reworked: 0`.

Shipped via `./ship.sh` (v0.0.26 → 0.0.27); `src/` verified a clean mirror.

Left `_refine_prompt`'s internal function name unchanged (it builds the exec
prompt) to keep the diff minimal — it now emits the `## Rework` section name.

### Files changed
docs/tasks/.TEMPLATE-task.md
docs/sprintmd/scripts/polish.sh
docs/sprintmd/ai/refine.md
docs/sprintmd/help/polish.md

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet. Verified current state against the code:

- `docs/sprintmd/scripts/polish.sh:778` — the round cap is exactly
  `_refine_round() { grep -c '^## Refine' "$1"; }`, keyed on the heading, not on
  a polish-owned counter. This is the bug the task describes.
- The sweep's reopen detection (`polish.sh:939`, `958`, `962`) also runs through
  `_refine_round`: it confirms a reopen by comparing the `## Refine` count
  before/after the AI pass. That detection path must move to `Reworked` too, not
  just the cap.
- The reopen prompt (`polish.sh:832`, `855`, and the emit-mode `_RULES` at
  `polish.sh:873`) instructs the AI to append `## Refine (round N)`. `ai/refine.md`
  (lines 68–86, 99) documents that same `## Refine (round N)` section.
- `docs/tasks/.TEMPLATE-task.md` header carries Feature/Created/Docs/Depends
  on/Blocks/Parent only — no `**Reworked**:` field.
- `docs/sprintmd/scripts/create-task.sh:58,68-72` copies the template verbatim
  (`copy_template`) and `sed`s only ID/Description/Date/Feature, so a new
  `**Reworked**: 0` line in the template carries through to every new task with
  no code change in create-task.sh.
- Live confirmation of the false skip: `review/243…md:111` and
  `review/244…md:126` each carry a `## Refine (round 1)` heading, so today's cap
  skips both regardless of whether polish ever judged them.

### Remaining work

1. Add `**Reworked**: 0` to the template header, beside the other `**Field**:`
   lines. Coordinate the single header edit with task 261's `**Refined**: 0` so
   the two additions don't clobber each other (261 depends on 262, so 262 lands
   the header change first).
2. Replace `_refine_round`'s `grep -c '^## Refine'` with a reader of the
   `**Reworked**:` header integer (missing field ⇒ `0`), and key both the round
   cap (`polish.sh:783`) and the reopen-confirmation compare (`polish.sh:939/958/962`)
   on that value.
3. Rename polish's appended section to `## Rework (round N)` in the exec prompt
   (`polish.sh:832,855`), the emit `_RULES` (`polish.sh:873`), and `ai/refine.md`,
   and have a confirmed REOPEN bump `**Reworked**:` by 1 — leaving `## Refine`
   free for task 261's pre-work pass.
4. Confirm `--force` (bypass cap) and `--rounds N` (cap value) now measure
   against `Reworked`; the flag parsing itself is unchanged, only what
   `_refine_round` returns.
5. Update `help/polish.md` (the "Round cap" paragraph, lines 36–39) to describe
   the counter-based cap and the `## Rework` section name.
6. `./ship.sh` to mirror + bump, then verify a fresh `./setup.sh` install
   produces tasks starting at `Reworked: 0`, and re-run `polish` against 243/244
   to confirm they are judged again (Migration: missing field ⇒ 0, per Notes).

### Questions for the developer

1. Should the `Reworked` increment be done by the shell on a confirmed reopen,
   or by the AI subagent (the way it writes the `## Rework` section)? (Suggestion:
   have the shell own the increment. The AI appends the `## Rework (round N)`
   section; the shell detects the reopen — by the new section appearing or the
   verdict being REOPEN — and does `sed`-style bump of `**Reworked**:` itself.
   A header integer that gates the cap is state, and deterministic shell state is
   more reliable than trusting the model to edit a header field exactly. This
   also keeps the reopen-confirmation check meaningful: shell writes the number
   it just verified, rather than reading back what the model claims.)

2. When both counters are absent from an old task file, is `Reworked` still `0`
   even if the file has a legacy `## Refine (round 1)` from a past polish run?
   (Suggestion: yes — treat missing as `0` unconditionally, exactly as the Notes
   say. Back-counting legacy `## Refine` headings into `Reworked` would
   reintroduce the conflation this task removes and re-cap the very tasks
   (243/244) that motivated it. Old headings become inert history; only the
   integer gates the cap going forward.)

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
