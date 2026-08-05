# Plan 18: Per-command learn demos

**Created**: 2026-08-03
**Status:** DRAFT

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Goal

Complete the learning catalog into a **real-world example set covering every
command**. Each member ships one short, scripted vignette — safe theater — of
what a user would actually *do* with that command, so someone cold on `chat`,
`polish`, or `deps` can watch a 40-second scenario and get it. Ordered along the
lifecycle spine, the set also reads as one continuous get-started journey
(newfeature → chat → newtask → newplan → check workable → start → work → polish
→ test → close → ship). This layers per-command coverage on top of the learning
engine that already ships (S0–S8 demos on disk; #313–#317/#324/#325 in review).

## Why

Our core value is to ship code fast — and adoption is what makes that value
land. A newcomer who can *watch* what any command does, then watch the whole
spine flow, gets productive without reading docs. Complete example coverage is
the on-ramp.

## Notes

- **Direction (owner override of `plan think`).** The `plan think` pass argued
  for shrinking to ~1–3 curated story slots, citing the `learning/README.md`
  rule "stories, not a feature tour." The owner chose the opposite: full
  per-command coverage, because the mandate is a complete example of *every*
  feature. The tension resolves via framing — each demo is a real-world
  *scenario* (safe theater), not a flag tour, so it satisfies "person in a
  situation" while still covering the command. No members cut on trust-contract
  grounds: `sync`/`cleanup`/`deps`/`profile` demos write nothing and make no
  network calls because they are scripted, never live runs.
- **Upstream prerequisite (not a member): #314** — the `<cmd> --demo` intercept
  + `--help` pointer. It is in `review/`, not `done/`. Every member is reached
  through it; it must land first. Track it, do not add it to this plan.
- **House-rule alignment.** This supersedes `learning/README.md`'s "8 curated
  stories, not one per command" curriculum rule. The README must be rewritten to
  match, or every member fails review against the documented house guide. This
  is member #357, ordered first — the demos are written against the corrected
  rule, not the shipped "8 curated stories" one.
- **Member readiness.** All 19 members are currently empty template stubs
  (`**Plan**: none`, no Problem/Success). They will fail the `plan start`
  workability gate until refined. Refine each via `chat backlog <id>` (task
  work, outside this plan) before `plan start 18`.
- **Parallelism / conflicts.** The 19 demos are independent in their own
  `learning/<name>.py` file, so they are mutually parallel there. But each also
  adds the 5th field on its own row in the single shared file
  `docs/sprintbias/help/_registry` — different rows, mergeable, but not truly
  disjoint. V1 executes sequentially; the intelligence is recorded, not
  scheduled.

## Execution order

Order walks the get-started spine (create → converse → plan → execute → refine →
close), then introspection/utility commands, then the meta `learn` catalog demo
last. The order is mostly narrative: the demos are independent files (see the
Parallelism note), so this is the recommended watch/build sequence, not a hard
dependency chain.

- **#357 first** — rewrite the curriculum rule; prerequisite for every demo below.
- **Spine (the get-started journey):** #338 → #339 → #343 → #340 → #345 → #342 →
  #341 → #347 → #344 → #346.
- **Introspection & utility:** #348 → #350 → #351 → #354 → #356 → #352 → #353 →
  #355.
- **Meta (the catalog itself, last):** #349.

## Per-member build recipe (shared definition of done)

Every member below follows the same four steps — this is the shape each task
should be refined to before `plan start`:

1. **Write the story.** A person-in-a-situation scenario for that command —
   what a real user is trying to do, not a flag tour.
2. **Storyboard it the way the app actually looks.** Match real command output
   and the shared output vocabulary (`type_out`, `spinner`, `beat`, `moved`,
   `claude`/`you`, `ok`/`note`/`held`) so it reads as the same tool talking.
3. **Build the demo file** `docs/sprintbias/learning/<cmd>.py` — self-contained,
   honors the trust contract (writes nothing, no network, stdlib only) and the
   standard flags (`--fast`, `--no-color`, `-h`, clean Ctrl-C).
4. **Wire the help pointer.** Add the 5th field on the command's row in
   `docs/sprintbias/help/_registry` (`<cmd> → <demo-name>`), so `--help` shows
   "type `sprint <cmd> --demo` to see it in real life" and `<cmd> --demo` plays
   it. (Intercept mechanism owned by #314 — the upstream prerequisite above.)

Execution approach (recorded for `plan start`/`work` time, not run from here):
each member can be handled by its own agent, fanning out to a sub-agent per
step, with progress written back to that member's own task file. The guided
**learning program** that walks a newcomer through the tool end-to-end is a
*later, separate* effort — not a member of this plan.

## Plan Think

Dual-persona critique (Chief Platform Architect + Chief Experience Officer).
Full analysis: `docs/tmp/plan-think.md`. All 19 members annotated in place.

Top 3 findings:

1. **The plan contradicts the shipped demo design.** The `learn` catalog is
   curated *stories* ("a person in a situation, not a feature tour" —
   `docs/sprintbias/learning/README.md`), not one demo per command. This
   19-command matrix is the exact feature-tour pattern the README exists to
   prevent; it causes catalog rot and choice overload. Reframe to "fill
   curriculum gaps" — shrinks 19 members to ~1–3.
2. **All 19 members are empty stubs with `**Plan**: none`, and can't start.**
   No Problem/Success on any file, so every member fails the `plan start`
   workability gate; the missing reverse index is fresh drift (see #337). The
   `--demo` mechanism (#314) is still in `review/`, an unrecorded dependency.
3. **~7 targets violate the demos' no-write/no-network trust contract**
   (`sync`, `cleanup`, `deps`, `profile`), and `learn` (#349) is a demo of the
   demo player. Cut these; keep at most `validate` (#354), story-framed. Also
   resolve the duplicate plan `docs/plans/17-338-356.md`.

## Member tasks

<!-- The tasks in this plan, by ID only — one "- #ID — short title" line each
     (checkboxes optional; [x] means the task is in docs/tasks/done/). These are
     references, not paths: resolve each ID against docs/tasks/*/ for location.
     Moving a member needs no edit here unless syncing checkboxes. -->

- #357 — Rewrite learning/README.md curriculum rule to per-command coverage
- #338 — Create learn demo for newidea command
- #339 — Create learn demo for newfeature command
- #343 — Create learn demo for chat command
- #340 — Create learn demo for newtask command
- #345 — Create learn demo for split command
- #342 — Create learn demo for newtest command
- #341 — Create learn demo for newplan command
- #347 — Create learn demo for promote command
- #344 — Create learn demo for loop command
- #346 — Create learn demo for polish command
- #348 — Create learn demo for search command
- #350 — Create learn demo for align command
- #351 — Create learn demo for context command
- #354 — Create learn demo for validate command
- #356 — Create learn demo for deps command
- #352 — Create learn demo for profile command
- #353 — Create learn demo for sync command
- #355 — Create learn demo for cleanup command
- #349 — Create learn demo for learn command

