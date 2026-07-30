# Task 216: Audit AI guidance files for current pipeline and method

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: 215
**Blocks**: 220
**Parent**: none

## Problem

The `docs/sprintmd/ai/*.md` files are the prompts/guidance injected into the AI providers that run `define`, `tasks`, `sprint`, and the create/audit commands. If they describe an outdated pipeline, folder layout, or command name, the model is actively steered wrong on every run — the most load-bearing docs to keep current. This subtask verifies each against the real pipeline and method.

## Success criteria

- [x] Each AI guidance file is read; record one row per file — path → stale items → fixed / clean — in a table appended to this task's `## Notes`.
- [x] Pipeline described matches reality: `sprint` (plan: backlog → next) → `define` (vet → READY) → `tasks` (execute → review) and the `loop` autopilot; folder names (`backlog/`, `next/`, `review/`, `done/`) are correct.
- [x] No guidance references any command absent from the current `./sprint.sh` dispatcher — verify against it; standalone `find`/`think`/`plan` are gone (folded into `talk`/`sprint`; cross-ref 203/204) — nor the old distribution model, nor nonexistent paths.
- [x] Guidance is consistent with the matching help text (215) and script behavior (214) — no contradictions.
- [x] Terminology consistent: "sprint.md", `docs/sprintmd/`, current command names.

## Notes

Files in scope:
- `docs/sprintmd/ai/audit-excellence.md`
- `docs/sprintmd/ai/bug-creation.md`
- `docs/sprintmd/ai/feature-creation.md`
- `docs/sprintmd/ai/feynman-method.md`
- `docs/sprintmd/ai/provider-capabilities.md`
- `docs/sprintmd/ai/task-creation.md`
- `docs/sprintmd/guides/use_talk.md` (framework guide shipped under docs/sprintmd/)

Cross-check each against the script that consumes it (e.g. task-creation.md ↔ create-task.sh / define.sh). Edit in `docs/`; do not touch `src/` directly.

### Audit results (one row per file)

**Scope correction:** the scope snapshot above (and the reviewer's "Already
complete" note) was stale. The live `ai/` directory holds **seven** files, not
six — `refine.md` was added and is a load-bearing AI guidance file (the `refine`
verdict prompt). And `guides/` holds **two** files, not one — `sprint_command.md`
sits alongside `use_talk.md`. Both extras are current AI/guide files shipped
under `docs/sprintmd/`, so both were audited and are included below.

| File | Stale items found | Result |
|---|---|---|
| `ai/audit-excellence.md` | None. `review-code`, `newtask` resolve to real dispatcher commands; paths `docs/tasks/backlog/`, `docs/features/`, `docs/guides/` exist; `docs/sprintmd/project.md` is a conditional user-profile reference (created by `./sprint.sh profile`, guarded by `[ -f ]` in lib.sh) — correct, not stale. | clean |
| `ai/bug-creation.md` | None. `newtask` valid; `docs/bugs/archived/` exists. No pipeline claims to drift. | clean |
| `ai/feature-creation.md` | None. `newtask` valid; `BACKLOG → DOING → DONE` matches the `**Status:** BACKLOG` line in `.TEMPLATE-feature.md`. | clean |
| `ai/feynman-method.md` | None. `newidea` valid; workflow `docs/ideas/` → `docs/features/` → `docs/tasks/*/*` all exist and match the real graduation flow. | clean |
| `ai/provider-capabilities.md` | None. `fiveday_run`, `fiveday_ai_tier`, `fiveday_ai_mode` all verified defined in `lib.sh`; `PROVIDER=`/`MODE=` in `docs/sprintmd/config` correct. `fiveday_*`/`FIVEDAY_*` names are intentional internal plumbing (backlog 210) — deliberately left as-is. | clean |
| `ai/task-creation.md` | None. `newtask` valid; header fields (Feature/Created/Docs/Depends on/Blocks/Parent) match `.TEMPLATE-task.md` exactly; content-location table (`docs/tasks/`, `docs/guides/`, `docs/examples/`, `docs/features/`) all point at real folders. | clean |
| `ai/refine.md` (not in original scope) | None. `review/` → `next/` re-execution via `tasks`, `## Refine (round N)` append flow, `**Status: READY**` preservation all match the `loop`/`tasks` runner behaviour; `project.md` reference conditional as above. | clean |
| `guides/use_talk.md` | None. Three-mode `talk` (emit / exec / degraded), blocked→`next/` re-routing, and the `split` fallback all match the `talk` dispatcher and `talk.sh`. | clean |
| `guides/sprint_command.md` (not in original scope) | None. Pure alias/shortcut guide — documents `alias sprint='./sprint.sh'`; makes no pipeline, folder, or command-name claims to drift. | clean |

**Pipeline & folders:** no file describes the pipeline wrong. `use_talk.md` and
`refine.md` reference `blocked/`, `next/`, `review/` consistently with the real
`sprint → define → tasks` + `loop` flow; all of `backlog/ next/ review/ done/`
(plus `blocked/ doing/`) exist under `docs/tasks/`. No file references the
retired `find`/`think`; the `plan` dispatcher case is a deprecation stub that
forwards to `talk`, and no AI file advertises `plan` as a live command.

**Net: zero edits to any guidance file — all nine are current.** The only
correction this audit produced is the scope-snapshot fix recorded above.

## References

- docs/sprintmd/ai/ — files under audit
- docs/sprintmd/guides/use_talk.md — shipped talk guide
- docs/sprintmd/scripts/ — consumers of these prompts
- docs/tasks/done/203-merge-plan-and-find-think-into-talk-as-a-state-rou.md — command consolidation context

## Questions

**Status: READY**

### Already complete

Nothing is complete yet — this is a verification task and no `## Notes` table
has been appended. But the reviewer's spot-check found the AI files are in good
shape, which narrows the scope:

- All command references in `docs/sprintmd/ai/*.md` resolve to real dispatcher
  commands: `newidea`, `newtask`, `review-code` (verified against `sprint.sh`
  lines 300–335). No file references the retired `find`/`think` or the
  deprecated standalone `plan` as active commands.
- All seven in-scope files exist and the scope list is complete: the `ai/`
  directory holds exactly the six files named (audit-excellence, bug-creation,
  feature-creation, feynman-method, provider-capabilities, task-creation) and
  `guides/` holds exactly `use_talk.md`. Nothing in scope is missing; nothing
  out of scope was omitted.
- `use_talk.md` already reflects the current three-mode (emit/exec/degraded)
  `talk` behavior and the blocked→next re-routing.

### Remaining work

Execute the audit as the success criteria describe:

1. Read each of the seven files and produce the one-row-per-file table
   (path → stale items → fixed/clean) appended to `## Notes`. This artifact does
   not exist yet — criterion 1 is entirely outstanding.
2. Verify the pipeline description (`sprint` → `define` → `tasks` + `loop`
   autopilot) and folder names (`backlog/`, `next/`, `review/`, `done/`) in each
   file against reality. Note: `task-creation.md` and `feature-creation.md`
   describe Feature→Task→Audit flow and content-location tables rather than the
   sprint pipeline directly — check those tables (`docs/tasks/`, `docs/guides/`,
   `docs/examples/`, `docs/features/`) still point at real folders.
3. Confirm terminology is uniformly "sprint.md" / `docs/sprintmd/` / current
   command names. Watch `provider-capabilities.md`, which still uses the
   `fiveday_*` / `FIVEDAY_*` internal names — those are intentional plumbing
   (see backlog 210) and are NOT stale; do not "fix" them here.
4. Reconcile against the settled help text (215) and script behavior (214) so
   the audit checks the AI guidance against the corrected state, not the current
   one — this is why those two are recorded as dependencies below.

### Questions for the developer

None — task is fully defined.

The only substantive reviewer change was adding **214** and **215** to
**Depends on** (previously just 213). Criterion 4 requires the AI guidance to be
"consistent with the matching help text (215) and script behavior (214) — no
contradictions." If this audit runs before those two settle, it would reconcile
the AI files against help/scripts that 214/215 are about to change, forcing a
re-audit. Sequencing 216 after them makes the consistency check meaningful. This
keeps the task READY: the runner holds it in `next/` until 213–215 reach
review/done, then runs it automatically.

## Completed

Audited all AI guidance / framework-guide files shipped under
`docs/sprintmd/` against the real dispatcher, scripts, templates, and folder
layout. Full one-row-per-file results are in the **Audit results** table under
`## Notes`.

Outcome: **all nine files are current — zero edits to any guidance file.**
Every command reference (`newidea`, `newtask`, `newfeature`, `newbug`,
`review-code`, `split`, `talk`) resolves to a live `./sprint.sh` case; no file
advertises the retired `find`/`think` or the deprecated standalone `plan`
(dispatcher `plan` is a stub that forwards to `talk`). Pipeline and folder
names (`backlog/ next/ review/ done/`, plus `blocked/ doing/`) match reality.
`fiveday_*` plumbing names in `provider-capabilities.md` left intact per the
backlog-210 note.

The one correction produced: the task's **scope snapshot was stale**. The live
`ai/` directory has seven files (adds `refine.md`), and `guides/` has two (adds
`sprint_command.md`). Both extras were audited and are clean; both are recorded
in the Notes table so the scope list is now accurate.

No guidance file was modified, so there is nothing to `./ship.sh`; only this
task file changed.

### Files changed
docs/tasks/doing/216-audit-ai-guidance-files-for-current-pipeline-and-m.md
