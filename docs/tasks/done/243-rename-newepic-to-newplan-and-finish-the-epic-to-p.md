# Task 243: rename newepic to newplan and finish the epic to plan rebrand

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/tmp/plan-command-redesign-notes.md
**Depends on**: none
**Blocks**: 244, 247

## Problem

Tasks 228/231 half-landed the epic→plan rebrand: `docs/epics/` already moved to
`docs/plans/`, but the scaffolding command and its machinery still say "epic" —
`newepic`, `create-epic.sh`, the `sprint_EPIC_ID` counter, and the
`# Epic [ID]:` heading in `docs/plans/TEMPLATE-plan.md`. Per the target-state
spec (`docs/guides/command-matrix.md`), `newepic` is **renamed** to `newplan`
and kept as a Create-family scaffold (it is *not* absorbed into `plan`). This is
the foundation the conversational `plan` author (244) and `plan start` (245)
build on: it fixes the plan-file shape and the ID/file-allocation machinery they
both reuse. "Epic" language retires from the whole app.

## Success criteria

- [x] `newepic` is renamed to `newplan` across the command surface (dispatch in
      `sprint.sh`, `_registry`, help page, manual); `create-epic.sh` becomes
      `create-plan.sh` and the `sprint_EPIC_ID` counter rebrands to plan naming.
      `newplan` still mints an empty scaffold `docs/plans/N-*.md` (Create
      primitive) — behavior unchanged, only the name.
- [x] `docs/plans/TEMPLATE-plan.md` heading changes `# Epic [ID]: [Epic Name]` →
      `# Plan [ID]: [Plan Name]` (rename both tokens so the no-stray-`epic` sweep
      finds nothing) and gains a `**Status:** DRAFT` line under the metadata (the binary
      DRAFT→READY marker 244/245 read and flip). The template's "a plan is a
      relational index, not a container" blockquote otherwise stands.
- [x] No stray `epic`/`Epic`/`EPIC` strings remain in shipped code, help,
      templates, or the manual (a repo-wide sweep confirms; note that task 237
      also sweeps naming and should catch any survivors).
- [x] `validate --commands` passes; `./ship.sh --dry-run` is clean (the renamed
      script ships via the tree mirror); a fresh `./setup.sh` install exposes
      `newplan` and creates a `docs/plans/N-*.md` scaffold with `Status: DRAFT`.
- [x] The blind spot that let the stale `src/docs/epics/` mirror ship is closed
      by a **brand-agnostic orphan-subtree guard**: `find_orphan_frameworks`
      (`ship.sh:125`) is generalized so it also flags any `src/docs/*/` subtree
      that has no live `docs/` counterpart — not just dirs containing
      `lib.sh`/`scripts/`. The guard **fails noisy** (non-zero exit, named dir)
      on that incongruence, so `./ship.sh` cannot mirror a renamed-away subtree
      forward again. (The `src/docs/epics/` remnant itself is already deleted and
      the `src/` sweep is clean — this criterion is only the guard.)

## Notes

- **Naming authority**: `docs/guides/command-matrix.md` is the target-state spec
  and wins where it disagrees with older notes. It settles this: `newplan` is a
  *rename* of `newepic`, kept as a Create-family scaffold — not absorbed into
  `plan`. (Task 229's original "absorb newepic" wording is superseded.)
- The `**Status:**` marker is deliberately **binary** — `DRAFT` (rough, still
  being authored) → `READY` (authored, safe for `plan start`/`loop --refill` to
  commit). It reuses the same `READY` word tasks already use so "READY = safe
  for autonomous pickup" is one concept system-wide. No active/done stored on the
  plan — those derive from where member tasks live.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  developer (move/rename files on the filesystem; do not stage or commit).

### Implementation notes (2026-07-29)

- Renamed `create-epic.sh` → `create-plan.sh`, `help/newepic.md` → `help/newplan.md`.
- Counter: `sprint_EPIC_ID` → `sprint_PLAN_ID`. `setup.sh` upgrade path still
  reads legacy `sprint_EPIC_ID` once if `sprint_PLAN_ID` is absent.
- Template: `docs/plans/.TEMPLATE-plan.md` with `# Plan [ID]: [Plan Name]` and
  `**Status:** DRAFT`.
- Manual, status label, ai-context heading, and error strings rebranded.
- Intentional remaining "epic" mentions: command-matrix Retired Names /
  Change history; plan 2's own redesign prose; `setup.sh` migration fallback
  comment. No shipped user-facing command or template still says epic.
- Verified: `./sprint.sh newplan "smoke…"` → `docs/plans/N-*.md` with Status
  DRAFT; `validate --commands` green; shipped v0.0.10.

## References

docs/guides/command-matrix.md
docs/plans/.TEMPLATE-plan.md
docs/sprintmd/scripts/create-plan.sh
docs/sprintmd/help/_registry
docs/sprintmd/scripts/plan.sh
DOCUMENTATION.md
docs/tasks/done/228-rename-shipped-sprint-grouping-concept-to-epic-acr.md
docs/tasks/done/231-rename-sprint-command-to-plan-dispatch-registry-he.md

## Completed

### Files changed
docs/sprintmd/scripts/create-plan.sh
docs/sprintmd/help/newplan.md
docs/sprintmd/help/_registry
docs/plans/.TEMPLATE-plan.md
docs/sprintmd/DOC_STATE.md
docs/sprintmd/scripts/ai-context.sh
sprint.sh
setup.sh
DOCUMENTATION.md
docs/guides/command-matrix.md
docs/plans/1-audit-the-distributable-source.md
docs/tests/test-no-stale-refs.sh
src/sprint.sh
src/DOCUMENTATION.md
src/docs/plans/.TEMPLATE-plan.md
src/docs/sprintmd/help/newplan.md
src/docs/sprintmd/scripts/create-plan.sh
src/docs/sprintmd/scripts/ai-context.sh
src/docs/sprintmd/help/_registry
src/VERSION

## Refine (round 1)

**Why:** The rebrand is incomplete in the distribution package, so Success
criteria #3 (no stray `epic` in shipped templates) and #4 (a clean fresh
install) do not actually hold. `src/docs/epics/.TEMPLATE-epic.md` still exists
and still reads `# Epic [ID]: [Epic Name]`. The live rename moved
`docs/epics/` → `docs/plans/`, but `docs/epics/` is a top-level sibling of
`docs/sprintmd/`, so `ship.sh`'s tree mirror never covered it and the old file
under `src/` was never pruned (the plan template ships via a file-level copy
list that only adds). The "repo-wide sweep" reported green because
`docs/tests/test-no-stale-refs.sh:33` deliberately excludes the whole `src/`
mirror — so it structurally cannot catch a stale file there. Meanwhile
`setup.sh`'s install walk is `find "$SRC_DIR" -type f` (setup.sh:1093), which
copies *every* file in `src/`: a fresh install therefore still creates
`docs/epics/.TEMPLATE-epic.md` with Epic language, defeating the rename's stated
goal that "Epic language retires from the whole app."

**Improve:**
- [x] Remove the stale `src/docs/epics/` directory (and its
      `.TEMPLATE-epic.md`) from the distribution package so it no longer ships.
      *(Done — directory deleted; `src/` sweep for `epic` returns zero hits.)*
- [x] Confirm a repo-wide sweep for `epic`/`Epic`/`EPIC` that **includes** `src/`
      returns only the intentionally-retained mentions listed in the task's
      Implementation notes (command-matrix history, plan 2's prose, setup.sh
      migration fallback comment) — no shipped template or script.
- [x] Run `./ship.sh --dry-run` and confirm it is clean with the stale dir gone,
      then re-run `./ship.sh` so `src/` is a byte-clean mirror without any
      `docs/epics/` remnant.
- [x] Do a fresh `./setup.sh` into a scratch dir and verify it creates
      `docs/plans/` (with the `Status: DRAFT` plan template) and does **not**
      create a `docs/epics/` directory.
- [x] **Close the blind spot (the only remaining work).** Generalize
      `find_orphan_frameworks` (`ship.sh:125`) so it flags any `src/docs/*/`
      subtree with no live `docs/` counterpart — today it only fires on dirs
      containing `lib.sh`/`scripts/` (`ship.sh:134`), so a template-only dir like
      `src/docs/epics/` slips past. The guard fails noisy (non-zero exit, prints
      the offending dir) so a renamed-away subtree can never be mirrored forward
      again. Chosen over adding an `epic` token to `LEGACY_RE`: the structural
      check is brand-agnostic and catches the whole *class* of "renamed live dir,
      stale `src/` sibling," whereas a per-term regex patches one word and rots
      on the next rename.

## Questions

**Status: READY**

### Already complete
The whole original scope (Success criteria #1–#4) is implemented and verified in
the current tree:
- `newplan` replaces `newepic` across the surface; `create-plan.sh`,
  `help/newplan.md`, and the `_registry` entry exist; the counter is
  `sprint_PLAN_ID` (DOC_STATE.md, value 5) with a `setup.sh` legacy-read
  fallback.
- `docs/plans/.TEMPLATE-plan.md` reads `# Plan [ID]: [Plan Name]` and carries a
  `**Status:** DRAFT` line.
- The **shipped source** (`docs/sprintmd/`) is clean of `epic` — the only stray
  hit in the whole distributable surface is the stale mirror file called out in
  Refine below. Remaining `epic` mentions are all in non-shipped territory
  (task files, `docs/tmp/` notes) or intentional (command-matrix history).

Implementation looks correct and clean. No quality concerns with the live
rename itself.

### Remaining work
Refine items 1–4 are **done and verified on disk** (2026-07-29): the
`src/docs/epics/` directory is deleted, the `src/` sweep for `epic` returns zero
hits, `docs/epics/` no longer exists, and `docs/plans/` ships with the
`Status: DRAFT` template. The **only** remaining work is Refine item 5 — the
blind-spot guard — now a checkbox in Success criteria.

### Resolved: which guard (was a question for the developer)
**Decision (2026-07-29): generalize `find_orphan_frameworks` in `ship.sh`; fail
noisy on clear incongruence.** The guard flags any `src/docs/*/` subtree that
has no live `docs/` counterpart (not just dirs with `lib.sh`/`scripts/`, its
current over-narrow trigger at `ship.sh:134`) and exits non-zero, naming the
offending dir. Chosen over adding an `epic` token to `LEGACY_RE`: the structural
check is brand-agnostic and catches the whole *class* of "renamed live dir,
stale `src/` sibling," which is exactly how `src/docs/epics/` slipped past —
`test-no-stale-refs.sh:33` excludes all of `src/`, and `LEGACY_RE` had no `epic`
token. A per-term regex would patch one word and rot on the next rename.

## Completed (round 2 — blind-spot guard)

Implemented the brand-agnostic orphan-subtree guard, closing the last open
Success criterion and Refine item 5.

- Generalized `find_orphan_frameworks` (`ship.sh`): it no longer keys on the
  `lib.sh`/`scripts/` heuristic. It now walks each mirror target's `src/` parent
  (`src/docs`) and flags any `src/docs/<name>/` whose live counterpart
  `docs/<name>/` does not exist — a purely structural "renamed live dir, stale
  `src/` sibling" check. Output is `sort -u`'d for stable, deduped naming.
- The guard **fails noisy**: `./ship.sh` prints the offending dir(s) and exits
  non-zero, so a renamed-away subtree can never be mirrored forward again.
- Verified end-to-end:
  - Clean tree: `./ship.sh --dry-run` → "Release gates: clean (no legacy refs,
    no orphan framework dirs)", exit 0.
  - Simulated orphan (`mkdir src/docs/epics`): dry-run shows "Release gates
    would BLOCK this ship: orphan framework dirs: src/docs/epics"; real run
    prints "Orphan framework dir(s) no manifest entry produces: src/docs/epics"
    and exits **1**. Removed the scratch dir; re-confirmed clean.
  - `./sprint.sh validate --commands` passes (22 commands, all four surfaces).

### Files changed
ship.sh

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
