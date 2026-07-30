# Task 271: Sweep manual GETSTARTED README AI and guides for the new surface

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265, 266, 267, 268, 269, 270
**Blocks**: 272, 274
**Parent**: none

## Problem

Even with dispatch correct, agents load DOCUMENTATION.md, GETSTARTED,
README, AI guidance, and provider guides first. #265 only swapped Commands
block tokens; prose, happy-path examples, and provider guides still teach
`talk` / `tasks` / `define` and old group names — so the remap fails in
practice until this sweep. Plan 8 also requires a **universal product-doc
audit** of README, DOCUMENTATION, and the command matrix; this task prepares
those three files so #274 can pass that audit.

## Success criteria

- [x] Root `DOCUMENTATION.md` full prose uses `chat`, `work`, `gate`, `align`, `context`, `deps` for commands; guiding-principles examples list the new verbs (Commands tokens already updated in #265 — finish the rest)
- [x] **Spine hierarchy is first-class in prose** (not buried): happy path is `chat → plan start → work → polish`; `loop` is that spine on autopilot; `gate` and `split` are off-spine; `polish` is after work. Task noun vs execute verb (`task` / `work`) stated clearly where agents learn the loop
- [x] `GETSTARTED.md` and `README.md` match the same spine and new command names
- [x] **Universal product-doc trio prepared** (content ready for #274 audit — Decision lock H in plan 8):
  - `README.md` — front door teaches six families (or clear command story), new names, spine; no live `talk`/`tasks`/`define` as commands
  - `DOCUMENTATION.md` — manual agrees with README and matrix on names, groups, spine, task noun
  - `docs/guides/command-matrix.md` — still target-state (family map, catalog, retired table, spine); **do not regress** the matrix to match a lagging CLI; only fix typos/clarity that keep the target
- [x] `docs/sprintmd/ai/*` guidance that names commands updated (task-creation, bug-creation, refine, provider-capabilities, etc.)
- [x] `docs/guides/claude-provider-tier.md` and `docs/guides/grok-provider-tier.md` updated
- [x] `docs/sprintmd/guides/*` updated (`use_chat`, `sprint_command`, …)
- [x] `docs/sprintmd/cli/*` comments that teach `./sprint.sh talk|tasks|define` updated
- [x] Live product docs under `docs/features/*` that instruct old command names updated (not `docs/tasks/done/` history)
- [x] No claim that `pipeline` / `workflow` / `inspect` / `maint` are the help groups

## Notes

- Leave `docs/tasks/done/**` and finished plan archaeology alone unless a file
  is still linked as current procedure.
- Matrix file is already target-state — do not regress it.
- Script-body invocation strings for the six renames were owned by #266–#269;
  registry spine one-liners were owned by #265; this task owns manuals, AI,
  guides, features, cli commentary, full spine prose, and **preparing** the
  README · DOCUMENTATION · matrix trio. #274 runs the formal universal audit.

## References

DOCUMENTATION.md
GETSTARTED.md
README.md
docs/sprintmd/ai/
docs/sprintmd/cli/
docs/sprintmd/guides/
docs/features/
docs/guides/command-matrix.md
docs/guides/claude-provider-tier.md
docs/guides/grok-provider-tier.md
docs/plans/8-command-surface-remap-to-chat-work-gate-and-six-fa.md

## Questions

**Status: READY**

### Already complete

- **`docs/guides/command-matrix.md` is already target-state.** It teaches the
  spine (`chat → plan start → work → polish`), names `loop` as the autopilot
  spine, and lays out the family map. Per the task and plan 8 (invariant "matrix
  is target-state"), this file must **not be regressed** — the sweep only touches
  it for typo/clarity fixes that keep the target. Verified: zero
  `sprint.sh talk|tasks|define|…` command-shaped hits in the matrix prose.

Everything else is still pre-sweep, as expected — the rename tasks (#265–#270)
this depends on have not run yet.

### Remaining work

The full sweep of everything *except* the matrix. Verified against the current
tree — command-shaped old-name hits remain in:
- `DOCUMENTATION.md` (7), `README.md` (15), `GETSTARTED.md` (5)
- `docs/sprintmd/ai/bug-creation.md` (1) — plus refine/task-creation/
  provider-capabilities prose to check for verb names
- `docs/sprintmd/guides/use_talk.md` (6, renamed to `use_chat` by #266),
  `sprint_command.md` (1)
- `docs/features/bug-tracking.md` (1) and other live feature docs
- `docs/guides/claude-provider-tier.md` (3); grok-provider-tier.md to confirm

None of the new tokens (`sprint.sh chat|work|gate|align|context|deps`) appear in
DOCUMENTATION/README/GETSTARTED yet, so this is a from-scratch prose pass, not a
patch-up.

Scope for the sprint:
1. Rewrite full prose (not just Commands-block tokens — #265 owns those) in
   `DOCUMENTATION.md`, `README.md`, `GETSTARTED.md` to `chat`/`work`/`gate`/
   `align`/`context`/`deps` and the six families.
2. Make the **spine hierarchy first-class prose**: happy path
   `chat → plan start → work → polish`; `loop` = spine on autopilot; `gate`/
   `split` off-spine; `polish` after work; task noun vs `work` execute verb
   stated where agents learn the loop.
3. Sweep `docs/sprintmd/ai/*`, `docs/sprintmd/guides/*`, `docs/sprintmd/cli/*`
   comments, live `docs/features/*`, and the two provider-tier guides.
4. Prepare the README · DOCUMENTATION · matrix trio so #274's universal audit
   (Decision lock H) passes — cross-file agreement on names, groups, spine, task
   noun; no `pipeline`/`workflow`/`inspect`/`maint` as help groups.
5. Leave `docs/tasks/done/**` and finished plan archaeology alone.

**Dependency note:** this is a documentation sweep that trails the actual renames.
It cannot be *finished* until #265–#270 land the new command names/basenames (e.g.
`use_talk.md → use_chat.md` is #266's rename), but it is fully *defined* now — all
prerequisites are recorded in `**Depends on**: 265, 266, 267, 268, 269, 270`. The
task runner holds it in `next/` until those reach review/done. Sequencing
constraint, not a definition blocker.

### Questions for the developer

None — task is fully defined.

## Completed
- README, GETSTARTED, DOCUMENTATION: new commands + spine hierarchy
- AI refine, use_chat, features, provider guides updated
- Product-doc trio prepared for #274 audit
