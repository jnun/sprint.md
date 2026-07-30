# Task 267: Rename tasks execute command to work without touching the task noun

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265
**Blocks**: 270, 271, 272, 274
**Parent**: none

## Problem

`./sprint.sh tasks` is the execute-the-queue command but reads like "manage
tasks." After #265 the dispatch label and help basename are already `work`.
This task renames the script, finishes help body, and rewires every live
execute-command invocation — without renaming the task *noun*.

## Success criteria

- [x] `docs/sprintmd/scripts/tasks.sh` → `work.sh` (`git mv`)
- [x] `sprint.sh` `cmd_work` → `run_script "work.sh"` (update temporary `tasks.sh` pointer from #265)
- [x] Help is `help/work.md` (basename already from #265); body describes happy-path `work` (execute READY queue), not the execute command named `tasks`; reinforce task noun vs work verb
- [x] **Ownership:** every live `./sprint.sh tasks` under `docs/sprintmd/` becomes `./sprint.sh work` (loop, plan-start tips, polish, chat handoffs, etc.)
- [x] **`docs/tasks/` directory still exists and is used as before**
- [x] **`newtask` still creates task files under `docs/tasks/backlog/`**
- [x] `validate-tasks.sh` filename stays (validates task *files*); update only user-facing strings that mean the execute command
- [x] Agent prompts that say "run tasks" for execution say `work` or "run `./sprint.sh work`"
- [x] No bulk rewrite of the word "task" inside task templates or lifecycle docs
- [x] Confirm with a quick check: `test -d docs/tasks` and `rg -n 'docs/tasks'` still resolve the tree (no path renames)

## Notes

False-positive checklist — do **not** change these solely because they contain
"tasks":
- Path `docs/tasks/`
- Command `newtask`
- Help text "READY tasks in next/" (noun is fine: "work READY tasks…")
- `validate-tasks.sh` (file integrity)
- Config `BUDGET_TASKS` until #270 renames it deliberately

Help basename was moved in #265; do not re-create `help/tasks.md`.

## References

docs/sprintmd/scripts/tasks.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/help/work.md
docs/guides/command-matrix.md
sprint.sh

## Questions

**Status: READY**

### Already complete

Nothing from this task's scope has landed yet — and that is expected, because
the whole task is gated on #265, which has not run:
- Registry (`docs/sprintmd/help/_registry:25`) still lists the command as
  `tasks`, not `work`.
- Dispatch is still `tasks) → cmd_tasks → run_script "tasks.sh"`
  (`sprint.sh:292-293, 358`).
- Help page is still `help/tasks.md`; there is no `help/work.md` yet.
- `docs/sprintmd/scripts/tasks.sh` has not been renamed.

The task's *preservation* constraints already hold and just need to stay true:
`docs/tasks/` exists, `newtask` still writes to `docs/tasks/backlog/`, and
`validate-tasks.sh` keeps its filename. No path renames are implied.

### Remaining work

All of it — clear and executable once #265 has created the `work` dispatch
label, `help/work.md` basename, and the temporary `tasks.sh` pointer this task
finishes:
1. `git mv docs/sprintmd/scripts/tasks.sh docs/sprintmd/scripts/work.sh`.
2. Point the dispatch at the renamed script: `cmd_work → run_script "work.sh"`
   (replacing the temporary `tasks.sh` pointer left by #265).
3. Fill in the `help/work.md` body: describe the happy-path `work` verb
   (execute the READY queue in next/ → review/), and reinforce the task *noun*
   vs. work *verb* distinction.
4. Rewrite every live execute-command invocation `./sprint.sh tasks` →
   `./sprint.sh work` under `docs/sprintmd/`. Confirmed occurrences today:
   `help/plan.md` (2), `help/define.md` (1), `help/tasks.md` (the usage block,
   ~18 lines — moves to `work.md`), `help/talk.md` (1), `help/polish.md` (2),
   `guides/use_talk.md` (1), `scripts/polish.sh:1045`,
   `scripts/talk-sprint.sh:373`, `scripts/talk.sh:132`,
   `scripts/plan-start.sh:318`, `scripts/tasks.sh:90-91,164`.
5. Update agent-facing "run tasks to execute" prose (e.g. `help/define.md:48`,
   `tasks.sh:164`) to say `work` / "run `./sprint.sh work`".
6. Update the command-matrix guide entry for the execute command.
7. Honor the false-positive checklist: leave `docs/tasks/` path, `newtask`,
   `validate-tasks.sh`, `BUDGET_TASKS` (until #270), and the task *noun* in help
   copy untouched.
8. Verify: `test -d docs/tasks` and `rg -n 'docs/tasks'` still resolve; then
   `./ship.sh` to mirror into `src/`.

### Questions for the developer

None — task is fully defined. It is a mechanical rename gated on #265; the
`**Depends on**: 265` field is already present and correct.

## Completed

Renamed the execute-the-queue command from `tasks` to `work` at the script,
dispatch, help, and every live-invocation level — while leaving the task *noun*
(files, folders, `newtask`, `validate-tasks.sh`) untouched.

- `git mv docs/sprintmd/scripts/tasks.sh docs/sprintmd/scripts/work.sh`.
- `sprint.sh`: `cmd_work` now `run_script "work.sh"` (dropped the #265
  temporary `tasks.sh` pointer and its stale comment).
- `help/work.md`: fixed the happy-path line to `plan start → work`, refreshed
  the re-gate note (`define` → `gate`), and added a "Naming" paragraph
  reinforcing `work` (verb) vs. *task* (noun in `docs/tasks/`).
- Rewrote every live `./sprint.sh tasks` → `./sprint.sh work` under
  `docs/sprintmd/`: `help/plan.md` (x2), `help/polish.md` (x2), `help/gate.md`,
  `help/chat.md`, `guides/use_chat.md`, `scripts/chat-sprint.sh`,
  `scripts/chat.sh`, `scripts/plan-start.sh`, `scripts/polish.sh`, and
  `scripts/work.sh` (usage comments + `--force` tip).
- `loop.sh`: updated the actual executor invocation
  `bash "$SCRIPT_DIR/tasks.sh"` → `work.sh` (this was a live call, not prose),
  plus a comment.
- Updated stale script-name comments that named the executor: `work.sh` header,
  `chat-sprint.sh` gate mirror, `lib.sh` manifest-source strings.

Preservation constraints held: `docs/tasks/` unchanged, `newtask` still writes
to `docs/tasks/backlog/`, `validate-tasks.sh` filename kept, `BUDGET_TASKS`
untouched (deferred to #270). The command-matrix guide already carried the
`work` verb + task noun from #265; no change needed there.

Verified: `bash -n` clean on all touched scripts; `./sprint.sh help work`
renders STEP 3; no remaining `./sprint.sh tasks` or executor `tasks.sh` refs
under `docs/sprintmd/`; `test -d docs/tasks` OK. Ran `./ship.sh` (v0.0.31 →
0.0.32) — src/ verified as a clean mirror, stale `src/.../tasks.sh` and
`help/tasks.md` gone, `work.sh`/`work.md` present.

### Files changed

sprint.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/chat-sprint.sh
docs/sprintmd/lib.sh
docs/sprintmd/help/work.md
docs/sprintmd/help/plan.md
docs/sprintmd/help/polish.md
docs/sprintmd/help/gate.md
docs/sprintmd/help/chat.md
docs/sprintmd/guides/use_chat.md
docs/tasks/doing/267-rename-tasks-execute-command-to-work-without-touch.md
