# Task 232: Update all cross-references from sprint.sh sprint to plan across scripts, help pages, and manual

**Feature**: none
**Created**: 2026-07-28
**Depends on**: 231
**Blocks**: 233

## Problem

After 231 reclaims `plan` as the real command, every place in the codebase that
tells a user (or another script) to run `./sprint.sh sprint` is now pointing at a
deprecated alias. This task updates all those cross-references to `plan` — prose,
help pages, the manual, and the one real call site in `loop.sh` — so the surviving
`sprint` alias exists only for muscle memory, not because anything still emits it.

**The central risk is over-renaming.** The word "sprint" is overloaded four ways;
only ONE meaning changes:

| Meaning | Example | Rename? |
|---|---|---|
| the Plan **command** | `./sprint.sh sprint 5` | **YES → `plan`** |
| the CLI **name** | `sprint.sh`, `sprint <command>` rc alias | no |
| the **board** (`next/`) | "walk the sprint's health", "queue a sprint" | no |
| the **grouping** | `newsprint`, `docs/sprints/` (→ "epic" in 228/229/230) | no (not here) |

Every edit must be checked against this table. When "sprint" is the board/noun,
leave it.

## Success criteria

- [x] No file emits `./sprint.sh sprint` as a *command to run* except the intentional back-compat alias notice
- [x] `./sprint.sh validate --docs` passes (help/manual match scripts, no flag/command drift)
- [x] `loop.sh` autopilot still refills correctly (invokes the renamed planner script by its new path)
- [x] Board/noun uses of "sprint" (health-walk, "queue a sprint") are left intact — spot-check `talk.md`, `talk-sprint.sh`

## Notes

**Real call site (must change — functional, not prose):**
- `docs/sprintmd/scripts/loop.sh:187` — `bash "$SCRIPT_DIR/sprint.sh" "$REFILL_SIZE" …` → `plan.sh` (path renamed in 231). Also the comment `# Refill: sprint + define` (line ~181) and echo `Refill: sprint …` (line ~139) — prose, update for clarity.

**Prose / user-facing command hints (change `sprint`→`plan`):**
- `DOCUMENTATION.md:130` — `./sprint.sh sprint [count] [focus]  # Plan a sprint from backlog` (and the `loop` line's "chain plan/define/execute" already says "plan" — leave it).
- `docs/sprintmd/help/tasks.md:58` — `./sprint.sh sprint 5  # 1. plan sprint from backlog`
- `docs/sprintmd/help/loop.md:24` — "Auto-refill: sprint + define …"
- `docs/sprintmd/help/profile.md:13` — "talk, define, sprint, and tasks pick it up"
- `docs/sprintmd/scripts/split.sh:85` — `'./sprint.sh sprint N "parent:…"'` (parent-gather hint)
- `docs/sprintmd/scripts/talk.sh:216` — same parent-gather hint
- `docs/sprintmd/scripts/review-sprint.sh:40` — "queue a sprint first (`./sprint.sh sprint`)" → the *parenthetical command* becomes `./sprint.sh plan`; the words "a sprint" (the board) stay.
- `docs/sprintmd/scripts/talk-sprint.sh:36` — "Queue one first: `./sprint.sh sprint`" → `plan`.

**Do NOT touch (board/noun/CLI-name — verified traps):**
- `talk.md` lines 28/30/50/52/73 — "the whole sprint", "sprint size", "no-arg sprint walk" = the board.
- `DOCUMENTATION.md:46/54/58/109` — sprint-as-index and the `sprint <command>` rc alias (CLI name).
- Any `newsprint`, `review-sprint`, `talk-sprint`, `create-sprint`, `docs/sprints/`.

**Method:** don't blind sed. Grep `sprint\.sh sprint` and `\.sh/sprint\.sh` for the
command/call sites, then review each remaining bare "sprint" against the table above
by hand. Finish by running `./sprint.sh validate --docs`.

## References

DOCUMENTATION.md
docs/sprintmd/scripts/loop.sh
docs/sprintmd/scripts/split.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/review-sprint.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/help/tasks.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/profile.md
docs/sprintmd/help/talk.md

## Questions

**Status: READY**

### Already complete
Nothing yet. This task is gated on 231, which has not run: the planner script is
still `docs/sprintmd/scripts/sprint.sh` (no `plan.sh` exists), the dispatched
command is still `sprint`, and `help/plan.md` still describes `plan` as a
deprecated shim that forwards to `talk`. All cross-references this task targets
therefore still read `sprint`, as expected. Nothing is prematurely done.

### Remaining work
Every listed call/reference still exists and still says `sprint`. After 231 lands:

- **Functional (the one real call site):** `loop.sh` refill invokes
  `bash "$SCRIPT_DIR/sprint.sh" "$REFILL_SIZE"` (currently line ~185) → point at
  the renamed `plan.sh`. Prose alongside it — the `Refill: sprint …` echo (line
  139) and `# Refill: sprint + define` comment (line 181) — update for clarity.
- **Prose / command hints (`sprint`→`plan`):** `DOCUMENTATION.md:130`;
  `help/tasks.md:58`; `help/loop.md:24` ("Auto-refill: sprint + define");
  `help/profile.md:13` ("talk, define, sprint, and tasks pick it up");
  `split.sh:85` and `talk.sh:224` (parent-gather hint — note: task text says
  talk.sh:216, but the line has drifted to 224); `review-sprint.sh:40` and
  `talk-sprint.sh:36` (parenthetical command becomes `./sprint.sh plan`; the
  board-noun "a sprint"/"no sprint to walk" stays).
- **Verify:** `./sprint.sh validate --docs` (backed by `check-docs.sh`) passes,
  and board/noun uses in `talk.md`/`talk-sprint.sh` are left intact.

The do-NOT-touch traps in the Notes are accurate against current code: `talk.md`
lines 28/30/50/52/73 and the `talk-sprint.sh:36` "no sprint to walk" text are all
board-noun, and the `newsprint`/`review-sprint`/`talk-sprint`/`docs/sprints/`
family is the grouping (228/229/230's concern), not this rename.

### Questions for the developer
1. `help/talk.md:10` says "…so `sprint <n> parent:N` still gathers the children" —
   this is the planner *command* expressed through the rc alias, and it is NOT in
   the task's do-NOT-touch list (which only enumerates talk.md 28/30/50/52/73).
   Should it be renamed too? (Suggestion: yes — rename to `plan <n> parent:N`. It
   is the parent-gather command, the same one being renamed at `split.sh:85` and
   `talk.sh:224`; leaving it would make the alias the last thing still emitting
   `sprint` as a command, contradicting success criterion #1. Sweep talk.md for
   bare `sprint <…>` command forms while you're in the file.)

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

## Completed

231 had already landed: `plan.sh` exists, no `sprint.sh` remains in
`docs/sprintmd/scripts/`, and root `DOCUMENTATION.md:130` already reads
`./sprint.sh plan`. This task swept the remaining cross-references.

- **Functional call site:** `loop.sh:187` invoked `bash "$SCRIPT_DIR/sprint.sh"`
  — a now-nonexistent script — repointed to `plan.sh`. Its neighboring prose
  (banner echo line 139, section comment line 181, and the confirmation-prompt
  comment line 186) updated `sprint`→`plan` for clarity.
- **Prose / command hints (`sprint`→`plan`):** `help/tasks.md:58`,
  `help/loop.md:24`, `help/profile.md:13`, `split.sh:85`, `talk.sh:224`,
  `review-sprint.sh:40` (parenthetical command only — board-noun "queue a sprint
  first" left intact), `talk-sprint.sh:36` (command only — "no sprint to walk"
  board-noun left intact), and `help/talk.md:10` (parent-gather command
  `sprint <n> parent:N` → `plan <n> parent:N`, per the developer question, which
  is answered yes).
- **Board/noun/CLI-name traps left untouched** as specified: `talk.md`
  28/30/50/52/73/102, `DOCUMENTATION.md` rc-alias/index lines, and the
  `newsprint`/`review-sprint`/`talk-sprint`/`docs/sprints/` grouping family.
- **Verified:** `./sprint.sh validate --docs` passes (no flag/command drift); a
  grep of the live `docs/sprintmd` tree shows zero remaining `sprint` command
  emissions.

`src/` is the distribution mirror and is intentionally not hand-edited — it is
updated by `./ship.sh` (not run here; committing/shipping is left to the
pipeline). Task 233's whole-project audit covers the fresh-install verification.

### Files changed
docs/sprintmd/scripts/loop.sh
docs/sprintmd/scripts/split.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/review-sprint.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/help/tasks.md
docs/sprintmd/help/loop.md
docs/sprintmd/help/profile.md
docs/sprintmd/help/talk.md
docs/tasks/doing/232-update-all-cross-references-from-sprint-sh-sprint.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
