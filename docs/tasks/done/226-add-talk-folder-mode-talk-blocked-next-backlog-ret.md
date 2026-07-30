# Task 226: Add 'talk <folder>' mode (talk blocked/next/backlog); retire triage as an alias

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: 225
**Blocks**: none
**Parent**: none

## Problem

`talk` already routes by target: `talk` (no arg) walks the sprint, `talk <id>`
talks through one task. The missing third case is a stage queue: a user who
wants to walk everything in `blocked/` (or `next/`, `backlog/`) one task at a
time has to reach for a separate command, `triage`. But `triage` is largely a
thin assess-then-dispatch loop whose `[d]` action literally shells out to
`talk.sh` — it duplicates talk's "size up, then route to the right depth"
identity under a second verb the user has to memorize.

Add `talk <folder>` as the natural third case, completing the grammar
`talk [target]`:
- nothing → walk `next/`, the default sprint queue;
- id → one task;
- a stage name → an **express, one-at-a-time sweep of that whole folder**
  (`talk blocked` walks `blocked/`, `talk backlog` walks `backlog/`).

The argument only decides **which files** get opened. **Dependency resolution is
intrinsic to `talk` itself and runs on every file it analyzes, regardless of entry
point:** whenever a task's `Depends on` points into `blocked/`, talk lifts and
defines that dependency so it can get unblocked — otherwise the dependent task can
never be worked and talking it through is useless. This is task 225's behavior,
shared by all three entry points.

And retire `triage` as a thin alias so muscle memory survives (the way `find` and
`plan` were retired).


## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `./sprint.sh talk blocked` walks every task in `blocked/` one at a time; `talk next` and `talk backlog` do the same for those folders.
- [x] `talk` dispatch (talk.sh) distinguishes three arg shapes: empty → sprint walk, numeric id → single task, stage name (`blocked`/`next`/`backlog`) → folder walk. An unknown non-numeric arg errors with guidance.
- [x] Per task in a folder walk, talk gives a fast verdict first (why it's blocked / its status) and only goes deep on demand — preserving triage's rip-through-the-queue tempo rather than forcing a full conversation on every file.
- [x] The verdict-first pass is TWO-TIER by model: the per-task assessment runs on the cheap `TRIAGE`-tier model (`fiveday_resolve_model TRIAGE`, single-shot, capped turns — as triage.sh does today), and only escalating a specific task to "go deep / define" hands it to the strongest `TALK`-tier model (`fiveday_tier_model TALK`). This is what keeps the fold from becoming "slow triage": fast cheap sort by default, full depth only where the user asks for it.
- [x] The folder walk keeps triage's actions (promote/start, define-conversationally, kill-with-confirm, skip, quit) and stays inside the task pipeline (git mv between stages, prefer `git mv`, fall back to `mv`).
- [x] Dependency resolution runs on every file the folder sweep analyzes, identical to `talk [id]` and the no-arg walk: whenever a swept task's **Depends on** points into `blocked/`, the walk lifts and defines that dependency via task 225's shared helper (the fresh-context chain at talk.sh:117-127, most-upstream dep first at talk.sh:232) so it can get unblocked. The folder argument chooses WHICH files are swept; what talk does to each file — including dep resolution — is the same across all three entry points. A folder sweep that skipped this would leave dependent tasks unworkable.
- [x] `triage` is retired down to a thin deprecation shim that prints a note (like `plan` at sprint.sh:210-215) and forwards to the **no-arg `talk`** walk (`cmd_talk` with no args). triage's old numeric `[limit]` arg is guarded: a numeric arg is ignored with the deprecation note, never passed through to `talk` (where it would be read as a task id). `help/triage.md` and its `_registry` row are dropped so no orphaned help file lingers (the `plan.md` mistake), and `validate --commands` stays green.
- [x] All four command surfaces stay consistent: `./sprint.sh validate --commands` passes after the change (registry ↔ dispatch ↔ help ↔ manual).

## Notes

- Decision (2026-07-28): file in this sprint; consolidate rather than add a parallel command. `talk <folder>` is the preferred shape because it extends talk's existing `talk [target]` grammar and removes a verb to memorize.
- Decision (2026-07-28): FOLD triage into talk — the "automatic timesaver" role is already `audit`'s (non-interactive: assesses AND acts, no prompts). triage is only an interactive guided sort (auto-assess, you decide per task via w/d/k/s/q), which `talk <folder>` with verdict-first fully absorbs. So retire triage as a thin alias; do not keep it as a parallel command.
- Decision (2026-07-28): dependency resolution is INTRINSIC to talk, applied to every file it analyzes regardless of entry point (no-arg, id, or folder sweep). Whenever an analyzed task depends on something in `blocked/`, talk lifts/defines that dependency (spawn a fresh subagent for the most-upstream undefined dep via talk.sh:117-127, pass context via a `*Context from talk*` note, most-upstream first at talk.sh:232) — otherwise the dependent task can never be worked. The `<folder>` argument only selects WHICH files get walked; dep resolution is the same everywhere. This is the same shared behavior task 225 factors out.
- Reuse, don't rebuild: triage.sh already has the assess loop (STATUS/SUMMARY/RECOMMENDATION), the action menu (w/d/k/s/q), and the git-mv plumbing; its `[d]` already launches talk.sh. The folder walk is largely triage's loop moved under talk's dispatcher, plus the dependency-chain entry above.
- TEMPO delta to preserve during define: talk's instinct is to converse, so the folder walk needs an explicit verdict-first / go-deep-on-demand mode to keep triage's fast-sort speed — otherwise it loses the "rip through 20 tasks in two minutes" value that justified folding rather than differentiating.
- Decision (2026-07-28): the tempo is enforced by a TWO-TIER model split, not just prompt wording. The per-task verdict runs on the cheap `TRIAGE` model (as triage.sh does now); escalating one task to deep define hands it to the `TALK` model. Reuse triage.sh's existing single-shot STATUS/SUMMARY/RECOMMENDATION assessment (triage.sh:113-152) for the verdict pass verbatim — model included — rather than inventing a new one.
- Alias-vs-remove: match how `find` (removed, shim message) and `plan` (deprecated shim → talk) were handled. `plan` still has an orphan help/plan.md; avoid repeating that — when triage is retired, drop help/triage.md AND its `_registry` row too, or the command-surface validator / help drift check will flag it.
- Relationship to task 225 (`Depends on: 225`): these CONVERGE on one shared helper. 225 factors the dependency-resolution logic (lift/define a blocked dep) out of the no-arg walk into a helper; this task's folder sweep and the single-id path call that SAME helper rather than reimplementing it. "Written once" is the deliverable. Sequence 225 first so the helper exists before this task consumes it — the `Depends on: 225` edge is real and stays.
- Both source scripts branch on `fiveday_ai_mode` (emit vs exec) — triage.sh:63-88 hands the whole list to the surrounding agent in emit mode; talk.sh:123-127 spawns a subagent for the dep chain only in emit+claude-code. The folder walk must handle both modes coherently (interactive loop in exec; agent-driven in emit) rather than assuming one. Don't ship a folder walk that only works in exec.
- Standard flow: edit under `docs/sprintmd/scripts/`, update help/_registry + help/<cmd>.md + DOCUMENTATION.md, test in place, `./ship.sh`. Run `validate --commands` and `validate --docs` before shipping.

## Questions

**Status: READY**

No open questions — fully defined and reviewed (see `## Think Notes`, Reviewed 2026-07-28). Waits on 225 (shared dependency-resolution helper), then ready to execute.

## References

docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/scripts/triage.sh
docs/sprintmd/help/_registry
docs/sprintmd/help/talk.md
docs/sprintmd/help/triage.md
sprint.sh

## Think Notes

**Reviewed**: 2026-07-28

- **Biggest correction.** The task originally framed dependency resolution as `talk next`'s special behavior (old SC5) and, mid-review, I briefly over-corrected it to "folder sweep ignores deps." Both were wrong. The settled model: **dependency resolution is intrinsic to `talk` itself** — every file talk opens, via any entry point, gets its blocked deps lifted/defined, because otherwise the dependent task can never be worked. The `<folder>` argument only selects WHICH files are walked; what talk does to each is identical. This is the load-bearing decision of the whole task.
- **Risks.** (1) Losing triage's speed by running the strongest model on every verdict — closed by the two-tier model split (cheap `TRIAGE` verdict, escalate to `TALK` only on deep). (2) The `triage` alias can't 1:1-map (it swept three folders combined with a numeric `[limit]`); its old numeric arg would misroute to `talk <id>` — closed by forwarding bare `triage` to no-arg `talk` and guarding/ignoring numeric args. (3) Orphaned `help/triage.md` tripping the command-surface validator — closed by dropping the help file + `_registry` row (the `plan.md` mistake). (4) Emit-vs-exec: a folder walk that only works in exec mode — flagged in Notes.
- **Alternatives weighed.** `talk next` as a distinct dependency-driven command vs. dependency resolution as a universal talk property → chose universal (simpler, correct, "every single time"). Alias as guide-only shim (like `find`) vs. forward to no-arg `talk` (like `plan`) → chose forward, for muscle-memory continuity. Single-tier vs. two-tier model → chose two-tier.
- **Assumptions validated.** Line references confirmed against current scripts: talk.sh's fresh-context dep chain at 117-127, most-upstream dep picker at 232, close-the-loop at 75-93; triage.sh's assess loop / action menu / git-mv plumbing (its `[d]` shells to talk.sh at 199); the `plan` shim pattern at sprint.sh:210-215 and `find` retirement at 316. `Depends on: 225` is real — 226 consumes the shared dependency-resolution helper 225 factors out; the edge stays.
- **Sprint-plan freshness (non-blocking).** `docs/tmp/sprint-plan.md` is stale — it describes the April installer-source-of-truth sprint (143/144/145), not the talk/triage consolidation these 220s tasks belong to. Same gap 225 flagged; for whoever refreshes the plan, not a defect in this task.

## Completed

Added `talk <folder>` as the third case of `talk [target]`, and retired `triage`
into a thin deprecation shim — folding its per-folder assess-then-act loop under
talk's dispatcher.

- **New `talk-folder.sh`** — an express one-at-a-time sweep of a single stage
  folder (blocked/next/backlog). Verdict-first tempo: a fast STATUS/SUMMARY/
  RECOMMENDATION pass on the cheap `TRIAGE` model (single-shot, capped turns,
  reused verbatim from the old triage), then the w/d/k/s/q action menu. `[d]`
  escalates to `talk.sh <id>` (strongest `TALK` model) — the two-tier split that
  keeps the fast sort from becoming "slow triage". Handles both AI modes: emit
  hands the whole sweep to the surrounding agent; exec runs the interactive loop.
  Dependency resolution is woven in via the shared `fiveday_next_blocked_resolution`
  helper (task 225) and, in exec, a `⚠ depends on N (in blocked/)` warning line;
  `[d]` → talk.sh carries the intrinsic fresh-context dep chain. Stays in the task
  pipeline (prefers `git mv`/`git rm`, falls back to `mv`/`rm`).
- **talk.sh dispatch** now branches on arg SHAPE: empty → sprint walk (unchanged),
  stage name → `talk-folder.sh` (checked before the numeric path), numeric id →
  single task (unchanged). An unknown non-numeric arg errors with three-line usage
  guidance instead of a silent failed task lookup.
- **triage retired**: `cmd_triage` in sprint.sh is now a shim that prints a
  deprecation note and forwards to the no-arg `cmd_talk` (sprint walk); its old
  numeric `[limit]` is guarded — never forwarded, so bare `talk N` can't misread
  it as a task id. `triage.sh` and `help/triage.md` deleted; the `_registry` row
  and the DOCUMENTATION.md line removed; `triage` added to check-commands.sh's
  HIDDEN list (like `plan`/`find`). No orphan help file — the `plan.md` trap avoided.
- **Docs/surfaces**: help/talk.md documents the folder sweep + triage alias; the
  `talk` registry row and manual line updated to `[target]`. `validate --commands`
  and `validate --docs` both pass (26 commands surfaced, no flag drift).

Verified in place (emit mode): `talk foobar` errors with guidance; `talk blocked`
(empty) reports and exits; `talk backlog` emits the sweep prompt with the
dependency-resolution block; `talk 220` still routes to single-task; `triage 5`
prints the deprecation note and runs the sprint walk (does not treat `5` as an id).

**Not shipped** — `./ship.sh` was deliberately NOT run. A dry-run showed `src/` is
behind by several *other* tasks' unshipped work (225's lib.sh/talk-sprint.sh, plus
excellence/newtask/create-sprint/etc.). Mirroring now would bundle unrelated
in-flight changes and bump the version — a batched release the user should trigger.
All of this task's changes are complete and validated in the live `docs/` tree;
run `./ship.sh` when ready to cut a release.

### Files changed
docs/sprintmd/scripts/talk-folder.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/help/talk.md
docs/sprintmd/help/_registry
sprint.sh
DOCUMENTATION.md
docs/sprintmd/scripts/triage.sh
docs/sprintmd/help/triage.md
docs/tasks/doing/226-add-talk-folder-mode-talk-blocked-next-backlog-ret.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the five-day change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
