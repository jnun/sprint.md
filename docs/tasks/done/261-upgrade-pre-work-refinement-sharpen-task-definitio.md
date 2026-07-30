# Task 261: upgrade pre-work refinement — sharpen task definition before tasks executes, track Refined count in header

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: 262
**Blocks**: none
**Parent**: none

## Problem

Refining a task's *definition* (sharpening what the work IS, before `tasks`
executes it) and reworking *finished* work (`polish` judging output at a higher
level) are two different animals — but the system records both the same way, as
a `## Refine (round N)` section, and neither leaves a visible count in the task
header. A developer skimming a task can't see how many times its definition was
sharpened, and the pre-work refinement pass has no home of its own: it borrows
polish's heading and thereby quietly consumes a polish round it never earned
(see task 262 for the downstream cap breakage). This task owns the *pre-work*
half: give definition-refinement its own record and its own header counter.

## Success criteria

- [x] The task template carries a `**Refined**: 0` header field (0–X),
      sitting with the other `**Field**:` lines, and every newly created task
      starts at `Refined: 0`.
- [x] The pre-work refinement flow (`talk <id>` / `define`) increments
      `Refined` by 1 each time it sharpens a task's definition, and writes its
      changes under a heading that is distinct from polish's post-work section
      (so a definition pass and a rework pass are never confused for one
      another).
- [x] Refining a task's definition never touches the `Reworked` counter (task
      262's territory) — the two counts move independently.
- [x] `newtask`, the template, and the refinement scripts agree; a fresh
      `./setup.sh` install produces tasks with the new header field.

## Notes

- Pairs with task 262 (polish rework upgrade). Both add a header counter to the
  SAME template head — coordinate the template edit so the two changes don't
  collide. Natural split: 261 owns `Refined` + the pre-work flow; 262 owns
  `Reworked` + the polish cap.
- Terminology watch: today `## Refine (round N)` is written by *polish* (a
  post-work operation), yet under this model "refine" means the *pre-work*
  definition pass. Resolve the collision deliberately — likely pre-work keeps
  "refine" and polish's section is renamed to "rework" in task 262 — so the two
  words map cleanly to the two counters.
- Live edit under `docs/sprintmd/`; then `./ship.sh` mirrors + bumps. The
  template lives at `docs/tasks/.TEMPLATE-task.md` and ships via `ship.sh`'s
  `TEMPLATE_FILES` copy list.

## References

docs/tasks/.TEMPLATE-task.md
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/create-task.sh
docs/sprintmd/ai/task-creation.md

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

Task 262 had already landed (`**Reworked**: 0` in the template head, polish
writing `## Rework (round N)`, and `polish.sh`'s round cap keying off the
`**Reworked**:` header), which freed the "refine" name for pre-work — so 261's
work slotted in cleanly.

- **Template** (`docs/tasks/.TEMPLATE-task.md`): added `**Refined**: 0` on its
  own header line, placed BEFORE `**Reworked**: 0` (pre-work counter ahead of
  the post-work one). `create-task.sh` copies the template verbatim and `sed`s
  only ID/Description/Date/Feature, so every new task now starts at
  `Refined: 0` with no code change to `create-task.sh` (verified: a fresh
  `newtask` and a fresh `./setup.sh` install both produce `Refined: 0`).
- **Pre-work flow** (`docs/sprintmd/scripts/talk.sh`): added a "RECORD THE
  REFINEMENT" block to the talk prompt, just before the FINISH/CLOSE/CHAIN
  closing section. When a talk session actually sharpens the task's definition
  it now, once per conversation, bumps the `**Refined**:` header by 1 and
  appends a `## Refine (round N)` record (`**Sharpened:**` line) — placed
  before any closing `## Questions` section so the READY stamp stays last. The
  block explicitly forbids touching `## Rework` / `**Reworked**:` (polish's
  post-work territory) and says not to bump on a no-op stress-test or a split's
  retired parent. Symmetric with polish's `## Rework (round N)` stamp; the two
  words now map cleanly to the two counters.

Decisions, per the READY questions: only `talk` increments `Refined` (`define`
is a READY-gate/read-only report, it does not sharpen definitions); the record
is a prompt-level instruction, not shell code, because talk runs interactively
through emitted prompts and the attached CLI (there is no post-run shell wrapper
to own the counter, unlike polish). `define.sh`, `create-task.sh`, and
`ai/task-creation.md` needed no edits.

`./ship.sh` mirrored both live files to `src/` and bumped the version to
0.0.28.

### Files changed
docs/tasks/.TEMPLATE-task.md
docs/sprintmd/scripts/talk.sh
src/docs/tasks/.TEMPLATE-task.md
src/docs/sprintmd/scripts/talk.sh
src/VERSION

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet. Verified current state:
- `docs/tasks/.TEMPLATE-task.md` — header carries Feature/Created/Docs/Depends
  on/Blocks/Parent only. No `**Refined**:` field.
- `docs/sprintmd/scripts/create-task.sh` — copies the template verbatim
  (`copy_template`) and `sed`s only ID/Description/Date/Feature. A new
  `**Refined**: 0` line in the template would carry through to every new task
  automatically; no code change needed there beyond the template edit.
- `docs/sprintmd/scripts/talk.sh` — sharpens definitions via inline edits to
  Problem/Success/Notes/Think Notes/Questions. Writes no counter and no
  dedicated "refine" section.
- `docs/sprintmd/scripts/define.sh` — next/ mode is a READY-gate that stamps
  `## Questions`; backlog/doing/blocked mode is a read-only report. It reviews;
  it does not sharpen definition content or bump a counter.
- `## Refine (round N)` is today written by **polish** (post-work) via
  `ai/refine.md`, and `polish.sh:778` reads the round cap with
  `grep -c '^## Refine'`. This is the exact heading collision task 262 removes.

### Remaining work

1. Add `**Refined**: 0` to the template header, beside the other `**Field**:`
   lines. Coordinate the single header edit with task 262's `**Reworked**: 0`
   so the two additions don't clobber each other.
2. Make the pre-work refinement flow bump `Refined` by 1 each time it sharpens
   a definition, recording its changes under a heading distinct from polish's
   post-work section. Because talk/define run through emitted prompts (emit
   mode) and the attached CLI (exec mode), the increment is prompt-level
   instruction text, not shell code — mirror how polish instructs the round
   stamp in `polish.sh`.
3. Ensure the pre-work flow only ever moves `Refined`, never `Reworked` (task
   262's counter).
4. `./ship.sh` to mirror + bump, then verify a fresh `./setup.sh` install
   produces tasks starting at `Refined: 0` (per CLAUDE.md's install-verify
   step).

### Questions for the developer

1. Should this task record a dependency on 262 (now set as **Depends on: 262**)?
   (Suggestion: yes — keep it. Until 262 stops polish from grepping
   `^## Refine` and renames polish's section to `## Rework`, any `## Refine`
   heading 261 writes would be counted by polish's round cap, reintroducing the
   very conflation 262 fixes. Landing 262 first (or the two together) frees the
   "refine" name for pre-work. The task runner holds 261 in next/ until 262
   reaches review/done, so no manual sequencing is needed.)

2. Which command(s) increment `Refined` — only `talk`, or `define` too?
   (Suggestion: only `talk`. `talk` is the conversation that actually sharpens
   the Problem/Success/Notes. `define`'s next/ mode is a READY-*gate* that
   classifies and stamps `## Questions` without editing definition content, and
   its other-folder mode is read-only — neither "sharpens a definition," so
   neither should move the counter. Keeping the increment in `talk` alone keeps
   the counter meaning clean: "how many times a human-supervised pass sharpened
   this task.")

3. Does the pre-work flow keep talk's inline-edit model and merely bump the
   counter, or also append a visible `## Refine (round N)` block the way polish
   appends its section? (Suggestion: keep inline editing AND append a short
   `## Refine (round N)` note summarizing what was sharpened, so a developer
   skimming the file sees both the header count and a per-round record —
   symmetric with polish's `## Rework (round N)`, and it satisfies criterion 2's
   "writes its changes under a heading" literally. Use `## Refine` for pre-work,
   leaving `## Rework` to 262/polish, so the two words map cleanly to the two
   counters.)

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
