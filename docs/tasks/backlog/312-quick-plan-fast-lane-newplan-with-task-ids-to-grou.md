# Task 312: quick-plan fast lane: newplan with task ids to group and start work without full authoring ceremony

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 4
**Reworked**: 0

## Problem

When a user already has a set of tasks in hand — most often children just split
out of one task (`**Parent**: N`) — and wants to work them as a group, the
ceremony still pushes `newplan` → `chat plan` → `plan start`. Trailing ids on
`newplan` already bind members, but there is no one-token way to adopt a split
batch, and post-create messaging still steers into AI authoring even when the
member list is already known. Grouping is a bind, not an authoring problem: the
user needs a named plan over a known set, then `plan start`, so grouped work
reaches `next/` quickly with a real plan left in history and the queue taught
rather than hidden.

## Success criteria

- [ ] `newplan "name" 310 311 312` still creates a plan pre-populated with those
      task ids as members (already works — keep + optional cheap regression).
      No `chat plan` required when members are bound this way.
- [ ] `newplan "name" parent:N` binds with **B-with-guard**:
      (1) include task **N** only if it exists in an **open** stage
      (`backlog` / `next` / `doing` / `blocked`);
      (2) include every open-stage task stamped `**Parent**: N`;
      (3) never pull `review/` or `done/` solely because of the parent stamp.
      Example: `parent:335` → open #335 (if any) + open children of 335.
      Token lives on `newplan` only — no `plan start` variant.
- [ ] If `parent:N` is the only member token and the guard yields **zero**
      matches, fail loud with a clear error (no empty silent plan). If parent N
      is absent but children matched, create the plan and note
      “parent retired — children only” (or equivalent).
- [ ] When members are pre-bound (ids and/or `parent:N`), post-create output
      echoes the members bound and points to `plan start` → `work` — not
      “author with `chat plan`” as the default next step.
- [ ] After either bind path, `plan start <id>` gates and commits members to
      `next/` exactly as today — `plan start` argument surface unchanged.
- [ ] The plan is a named file under `docs/plans/` (user-supplied name, normal
      plan id allocation) — not throwaway/auto-named.
- [ ] Help / registry document the fast lane (`newplan` trailing ids +
      `parent:N` / B-with-guard); nothing auto-creates a plan without explicit
      user invoke. Prefer updating split/chat gather hints from the stale
      `plan N "parent:…"` wording to `newplan "…" parent:N` when touching help.

## Notes

**Scope: Minimal — membership fast lane only.**

| Ship | Skip (not this task) |
|------|----------------------|
| `parent:N` on `newplan` (B-with-guard) | Auto-expand **`Depends on`** into membership |
| Fast-lane next-step copy when members pre-bound | Auto-flip plan **Status** to READY |
| Help / registry / cheap split-hint fixups | `plan start <ids…>` ad-hoc form |
| Keep trailing ids / ranges (already ships) | Silent auto-create of plans |
| | Multi-plan / sequential “messy chain” hardening beyond gate + hold |

**Shape:** `newplan "name" <ids…>` (A, already ships) + `newplan "name" parent:N`
(C, build). Rejected: `plan start <ids…>` (surface-creep + throwaway plans).

**`parent:N` = B-with-guard.** Open stages = `SPRINTMD_OPEN_STAGES`. After a
normal `split` the parent file is retired, so the common case is children only.
Implement on `newplan` only — do not revive a `plan` gather verb (stale
`plan N "parent:…"` prompts are leftovers from the retired `sprint` filter).

**Guardrails:** explicit user intent only; named plan in history; surface
`plan start` → `work` to teach the queue; skip only `chat plan` authoring —
never the workability gate.

**Deps vs plans (design, not work):** membership and **Depends on** stay
separate. Runtime hold (`sprintmd_unmet_deps`) serializes cross-plan /
out-of-plan prereqs; multi-plan membership stays allowed (primary = lowest id,
#331). A later task may *report* open prereqs outside the plan at `plan start`.

**Sibling:** task 310 = single-task rush (`work N`); 312 = grouped bind → named
plan → `plan start`. Same reuse principle.

## Think Notes

**Reviewed**: 2026-08-03

- **Risk:** An antique *open* parent still enters the plan under B-with-guard;
  gate handles unworkable; user may rework/retire it. Prefer that over
  resurrecting `done/` parents.
- **Rejected:** children-only (A); bare parent+any-stage (B); auto-`Depends on`
  closure at `newplan`.
- **Assumption:** trailing-id path in `create-plan.sh` remains correct; this
  task extends it, does not rewrite it.

## References

docs/sprintmd/scripts/create-plan.sh   — `newplan`; add `parent:N`; branch next-step copy
docs/sprintmd/scripts/plan-start.sh    — reused unchanged
docs/sprintmd/lib.sh                   — open-stage helpers (`SPRINTMD_OPEN_STAGES`)
docs/sprintmd/help/newplan.md          — document fast lane
docs/sprintmd/help/plan.md             — chat plan skippable when members pre-bound
docs/sprintmd/help/_registry           — surfaces agree (validate --commands)
docs/sprintmd/scripts/split.sh         — stamps **Parent**: N; update gather hint if cheap
docs/tasks/review/310-work-a-task-by-number.md  — sibling rush path

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

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Refine (round 1)

**Sharpened:** Created and fully defined this task (split out of the 310
conversation). Settled the shape — `newplan "name" <ids>` plus a
`newplan "name" parent:N` split shortcut, both reusing `plan start` unchanged;
rejected an ad-hoc `plan start <ids>` form as surface-creep. Fixed the intent:
the fast lane only fires on explicit user intent to group work, keeps a named
plan in history for posterity, and surfaces the queue to teach the process — it
skips only `chat plan` authoring, never the workability gate.

## Refine (round 2)

**Sharpened:** Locked **Minimal** scope — ship `parent:N` on `newplan`,
fast-lane next-step messaging when members are pre-bound, and help/registry;
treat trailing-id binding as already done. Corrected the stale claim that
`plan N "parent:…"` already gathers members. Reframed the Problem around the
real gap (no split-batch token + messaging still steers into `chat plan`) so
the work matches the problem we intend to solve.

## Refine (round 3)

**Sharpened:** Confirmed 312 stays membership-only (no `Depends on` auto-expand).
Locked **`parent:N` = B-with-guard** (open parent N if present + open children;
never pull review/done by stamp alone). Recorded collision policy as design
note / possible follow-up, not this task’s work.

## Refine (round 4)

**Sharpened:** Final polish for implementability — promoted zero-match fail-loud
and “parent retired — children only” into Success criteria; collapsed Notes to
a ship/skip table; aligned headers with the task template; marked
**Status: READY**. No open decisions remain.

## Questions

**Status: READY**
