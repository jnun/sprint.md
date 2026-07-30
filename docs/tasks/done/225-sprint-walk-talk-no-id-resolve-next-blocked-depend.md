# Task 225: Sprint walk (talk, no id): resolve next→blocked dependencies via a two-path choice

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: none
**Blocks**: 226
**Parent**: none

## Problem

When a `next/` task depends on a task sitting in `blocked/`, the executor
(`tasks`) silently *holds* the dependent task — it can never run until the
dependency leaves `blocked/`. The sprint walk (`./sprint.sh talk` with no id)
already detects this and raises the top-severity BLOCKER finding, but it only
*reports* it: the fix text says "unblock N first (`talk N`), or drop the
dependency if it is stale," and the walkthrough chains the user out to a fresh
window without offering to act or framing the real decision.

Two problems with the current framing:
1. It punts. A user walking their sprint gets a homework instruction, not a
   resolution — the walk never closes the loop or re-checks the frontier.
2. It offers the wrong alternative. "Drop the dependency" edits the
   `Depends on:` line, which makes the task *look* runnable while the work it
   needed is still undone (the folder-based-satisfaction trap). The real second
   option is to **pull the dependent task out of the sprint** so `next/` holds
   no work blocked on undefined tasks.


## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] At each `next→blocked` BLOCKER finding, the walk presents the two real paths as an explicit choice: (A) define the blocked dependency, or (B) demote the dependent `next/` task back to `backlog/`.
- [x] Path B is actioned inline: on the user's OK, `git mv` the dependent task from `next/` to `backlog/` (fall back to `mv` if uncommitted). Then **re-scan `next/` for any other tasks that depend on the same blocked id** and surface them — only report "the sprint no longer contains work blocked on that dependency" once none remain; otherwise name the still-blocked siblings and offer to resolve each in turn.
- [x] Path A hands off (does NOT redefine inline) by reusing talk.sh's existing fresh-context chain, mirroring its emit-vs-exec split: when the provider supports it (emit + claude-code) it **spawns a fresh subagent (Task tool)** for the most-upstream undefined dep; otherwise it falls back to printing `./sprint.sh talk <dep-id>` for the user to run in a fresh window. Either way, talk.sh's close-the-loop branch lands the dependency back in `next/` and makes the dependent task runnable.
- [x] Dropping the `Depends on:` line is NOT offered as a way to resolve a real block. It survives only as a metadata correction for a **stale or spurious edge** — the dependency isn't genuine (its work is already done elsewhere, or the edge was wrong to begin with). If the task actually depends on the work, only paths A and B apply; dropping the line would merely hide an unmet dependency (the folder-satisfaction trap).
- [x] Before the drop path is even offered, the walk must **audit the edge on the spot** to establish whether the dependency is still real: read *why* the dependent needed it — what its Problem/Success actually required from the dependency `<dep>` — and check whether that need is already satisfied or has become obsolete. Only an edge that fails this audit (need already met / no longer needed) may be dropped; an edge whose need still stands routes to A or B. No audit, no drop.
- [x] The BLOCKER finding's fix text is updated to name paths A and B (not "drop the dependency").
- [x] The Path A/B resolution (present the two-path choice → demote inline for B → hand off to define for A) is factored into a **shared helper**, not inlined in `talk-sprint.sh`, so task 226's `talk next` folder walk calls the same logic instead of reimplementing it. "Written once" is the deliverable, not just the intent.

## Notes

- Decision (2026-07-28): "Offer both, hand off for A." Do B (the `git mv`) inline; for A keep chaining out to define the dependency, since deep define work is heavy and talk.sh already owns close-the-loop.
- Decision (2026-07-28): the drop path is gated by an on-the-spot edge audit. This audit is a bounded, READ-ONLY reasoning step — read the dependent's and the dependency's Problem/Success, decide if the need still stands — NOT a define pass. It stays inline in the walk (unlike Path A's heavy define work, which chains out). A real dependency always routes to A or B; drop is reserved for an edge the audit proves stale.
- Decision (2026-07-28): Path A should reuse talk.sh's existing fresh-context agent chain, not just print "run talk <dep> yourself." talk.sh:117-127 spawns a NEW subagent (Task tool) for the dependency and passes context via a `*Context from talk*` note in the file — so context stays small and the hand-off is durable. talk.sh:232 picks the most-upstream undefined dep first. Point Path A at that chain.
- The promote-back-to-`next/` machinery already exists — do NOT rebuild it. talk.sh:77-89 ("CLOSE THE LOOP") stamps `**Status: READY**` and `git mv`s a defined blocked task into `next/`. Path A just needs to point at it.
- Converges with task 226 (this task now `Blocks: 226`; 226 `Depends on: 225`). 226 generalizes this next→blocked resolution into a dependency-driven folder walk (`talk next`: walk each task in `next/`; if it depends on something in `blocked/`, define that blocked task via Path A). Both entry points — the no-id sprint walk here and 226's folder walk — must call the SAME shared helper for the two-path resolution. Sequence 225 first so the helper exists before 226 consumes it.
- The detection already exists — talk-sprint.sh:240 raises the sev-1 BLOCKER finding (one per unmet next→blocked edge, via `fiveday_unmet_deps`). This task changes the *fix text* and the *walkthrough action menu*, not the detection.
- Path B's re-scan is cheap to satisfy: the preflight already emits a SEPARATE BLOCKER finding for each `(next task, blocked dep)` pair, so sibling dependents on the same blocked id are already in the findings list. The walk just needs to recognize them as related (same dep id) and surface/act on them together, rather than running a fresh board scan.
- Path A's subagent spawn works WITHOUT adding `Task` to talk-sprint.sh's `--tools` line (talk-sprint.sh:450 lists only Read/Edit/Write/Bash/Grep/Glob). In emit mode `fiveday_run_interactive` (lib.sh:543) hands the prompt to the SURROUNDING claude-code agent, which already has `Task`; `--tools` only constrains the exec-mode REPL — the same mode where Path A correctly falls back to printing the command. Do NOT add `Task` to the exec tool grant to "enable" the spawn; the emit/exec split in criterion 3 already handles it, exactly as talk.sh does today.
- Scope is `./sprint.sh talk` with NO id (the sprint walk, talk-sprint.sh). Single-task `talk <id>` is unchanged.
- Keep writes strictly inside the task pipeline, matching the existing walkthrough contract (edit files under docs/tasks/, move between stage folders, prefer `git mv`).
- Standard flow: edit under `docs/sprintmd/scripts/`, test in place, then `./ship.sh`.

## Questions

**Status: READY**

No open questions — fully defined and reviewed (see `## Think Notes`, Reviewed 2026-07-28). Ready to execute.

## References

docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/scripts/talk.sh

## Think Notes

**Reviewed**: 2026-07-28

- **Risks.** (1) Duplicated resolution logic between this task and 226 — mitigated by the shared-helper success criterion and the reciprocal `Blocks/Depends on` edges. (2) Path B's original "sprint no longer blocked" claim was unsound when multiple `next/` tasks share one blocked dep — closed by the re-scan criterion. (3) Path A's mechanism was self-contradictory (print vs. spawn) — closed by aligning criterion 3 with the emit-vs-exec decision. (4) The drop path could re-create the folder-satisfaction trap — closed by gating it behind an on-the-spot edge audit and restricting it to stale/spurious edges.
- **Alternatives weighed.** Path B scoped-to-one-task confirmation vs. full re-scan → chose re-scan for robustness. Leaving the 225↔226 relationship as Notes-only prose vs. declared metadata + shared helper → chose explicit metadata + a checkable criterion. Keeping "drop the dependency" as a co-equal option → rejected; reclassified as a narrow metadata correction only.
- **Assumptions validated.** All cited line references confirmed against the current scripts: BLOCKER finding at `talk-sprint.sh:240` with fix text "unblock $u first ('talk $u'), or drop the dependency if it is stale"; close-the-loop + demote + chain machinery present in `talk.sh` (`_CLOSE_LOOP_INSTR`, `_DEMOTE_INSTR`, `_CONTINUE_INSTR` with its emit/exec branch); per-edge findings emitted via `fiveday_unmet_deps`. Detection stays untouched; this task changes only fix text + action menu.
- **Non-blocking alignment note.** `docs/tmp/sprint-plan.md` is stale relative to this work — it describes the April installer-source-of-truth sprint (tasks 143/144/145), not the talk/triage consolidation these 220s tasks belong to. 225 carries `Feature: none` and is not in that plan. This is a plan-freshness gap, not a defect in 225; flagged for whoever refreshes the sprint plan.

## Completed

**Completed**: 2026-07-28

The two-path resolution was implemented as a **shared prompt-instruction helper**
in `lib.sh` — `fiveday_next_blocked_resolution` — because in this architecture the
"logic" that walks a finding is prompt text handed to the conversational layer, and
prompt text is exactly what both entry points (this sprint walk and task 226's
`talk next` folder walk) need to share. Placing it in `lib.sh` (which both scripts
already source) satisfies "written once": task 226 embeds the same block instead of
reimplementing it.

- **Shared helper** (`lib.sh`, `fiveday_next_blocked_resolution`): emits the block
  that walks ONE `next→blocked` edge — the two-path choice (A define / B demote),
  Path B's inline `git mv` + same-blocked-id sibling re-scan, Path A's hand-off, and
  the drop path gated behind an on-the-spot READ-ONLY edge audit restricted to
  stale/spurious edges. Path A mirrors `talk.sh`'s emit-vs-exec split: an emit-mode
  claude-code session spawns a fresh subagent (Task tool) for the most-upstream
  undefined dep; every other environment prints `./sprint.sh talk <dep-id>` to run
  in a fresh window. Verified both branches render correctly.
- **BLOCKER fix text** (`talk-sprint.sh`): the sev-1 `next→blocked` finding now reads
  "PATH A: define … / PATH B: demote this task to backlog/ …" instead of the old
  "unblock … or drop the dependency if it is stale."
- **Walkthrough prompt** (`talk-sprint.sh`): computes `NEXT_BLOCKED_RESOLUTION` from
  the shared helper, adds a `next→blocked BLOCKER` bullet to the step-3 action menu,
  and embeds the full resolution block as a labeled section. The detection path
  (`fiveday_unmet_deps` → sev-1 finding) is untouched, exactly as scoped.

Tested in place with `FIVEDAY_MODE=emit ./sprint.sh talk` (prompt emits the block
with the claude-code Path A branch) and by exercising the helper's fallback branch
directly. `bash -n` passes on both edited scripts.

**Not shipped to `src/` in this task.** The standard flow ends in `./ship.sh`, but a
`./ship.sh --dry-run` showed the tree currently carries several *unrelated* un-shipped
edits from other in-flight work (help files, `ai-context.sh`, `create-sprint.sh`,
etc.). A full `ship.sh` mirrors whole trees and bumps the shared `VERSION`, which would
bundle that unrelated work into this task — and CLAUDE.md forbids hand-copying single
files to `src/`. Shipping is batched here; run `./ship.sh` at release time to mirror
`lib.sh` + `talk-sprint.sh` (along with the other pending changes).

### Files changed
docs/sprintmd/lib.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/tasks/doing/225-sprint-walk-talk-no-id-resolve-next-blocked-depend.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
