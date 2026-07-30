# Task 266: Rename talk scripts and callers to chat

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 265
**Blocks**: 271, 272, 274
**Parent**: none

## Problem

The conversational engine lives under `talk` script filenames and agent
prompts (`talk.sh`, `talk-*.sh`, guides, lib strings). After #265 the
dispatch label and help basename are already `chat`; this task finishes
script renames, full help/guide content, and every live `talk` invocation.

## Success criteria

- [x] Scripts renamed: `talk.sh` → `chat.sh`, `talk-bugs.sh` → `chat-bugs.sh`, `talk-folder.sh` → `chat-folder.sh`, `talk-plan.sh` → `chat-plan.sh`, `talk-sprint.sh` → `chat-sprint.sh` (`git mv`)
- [x] `sprint.sh` `cmd_chat` → `run_script` the new `chat*.sh` entrypoints (update temporary `talk.sh` pointer from #265)
- [x] Help is `help/chat.md` (basename already from #265); full content uses `chat` as the command (not `talk`)
- [x] `guides/use_talk.md` → `guides/use_chat.md` and all inbound links updated
- [x] **Ownership:** every live `./sprint.sh talk` under `docs/sprintmd/` (scripts, help, ai, guides) becomes `./sprint.sh chat` — including tips in plan-start, loop, polish, gate CLI/library, etc.
- [x] No live script under `docs/sprintmd/scripts/talk*.sh` remains
- [x] Script-local model defaults prefer `MODEL_CHAT` when those lines are touched; full config key cut is #270 — no `sprintmd_tier_model TALK` line was touched, so the tier key stays `TALK` for #270 (per Notes/Questions)

## Notes

- Do not rename the English verb "talk" inside historical `docs/tasks/done/**`.
- Conversation Method already says "chat" — align CLI with that.
- Subcommands/targets unchanged: `chat plan`, `chat bugs`, `chat backlog`, bare `chat`.
- Help basename was moved in #265; do not re-create `help/talk.md`.

## References

docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/talk-bugs.sh
docs/sprintmd/scripts/talk-folder.sh
docs/sprintmd/scripts/talk-plan.sh
docs/sprintmd/scripts/talk-sprint.sh
docs/sprintmd/help/chat.md
docs/sprintmd/guides/use_talk.md
docs/guides/command-matrix.md
sprint.sh

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet — this task builds directly on #265, which has not
run. The live tree still has `talk.sh`, `talk-bugs.sh`, `talk-folder.sh`,
`talk-plan.sh`, `talk-sprint.sh`; `help/talk.md` (not `chat.md`);
`guides/use_talk.md`; `sprint.sh` still dispatches `talk) → cmd_talk →
run_script "talk.sh"`; and `help/_registry` line 31 still keys `talk`. That is
expected — the registry/dispatch/basename groundwork is #265's job (recorded
dependency), and the runner holds this task in `next/` until #265 reaches
review/done.

### Remaining work

Verified against the current tree, the scope is:

1. **`git mv` the five scripts** `talk*.sh → chat*.sh` under
   `docs/sprintmd/scripts/`.
2. **Fix inter-script path references.** `talk.sh` resolves its siblings by
   filename (`_TALK_FOLDER=…/talk-folder.sh`, `talk-bugs.sh`, `talk-plan.sh`,
   `talk-sprint.sh`), and `talk-folder.sh:248` shells back to
   `…/talk.sh`. Every `dirname .../talk-*.sh` path must move to `chat-*.sh` or
   dispatch breaks. This is beyond the "`./sprint.sh talk`" grep and is the
   easiest thing to miss.
3. **`sprint.sh`**: point `cmd_chat`/`run_script` at `chat.sh` (updating the
   temporary `talk.sh` pointer #265 leaves).
4. **Help content**: fill `help/chat.md` (basename moved by #265) so the body
   says `chat`, not `talk`.
5. **Guide rename**: `guides/use_talk.md → guides/use_chat.md` and update the
   four inbound links (`talk.sh`, `talk-plan.sh`, `talk-sprint.sh`,
   `profile.sh`).
6. **Live invocations**: convert every `./sprint.sh talk …` under
   `docs/sprintmd/` to `chat`. Confirmed callers include `plan-start.sh`,
   `plan-think.sh`, `plan.sh`, `loop.sh`, `polish.sh`, `gate.sh`, `define.sh`,
   `ai-context.sh`, `lib.sh` (chain-out prompts), `ai/bug-creation.md`,
   `help/define.md`, `help/newbug.md`, `help/newtask.md`, `help/plan.md`,
   `help/profile.md`, `cli/claude.sh`, `cli/default.sh`,
   `guides/sprint_command.md`.
7. **Leave the config tier key alone**: scripts call
   `sprintmd_tier_model TALK` (reads `MODEL_TALK`). Per the Notes, the config
   key cut is #270 — do not switch these to `CHAT` here or the model lookup
   resolves to an empty `MODEL_CHAT`.
8. `./ship.sh` to mirror renames into `src/`.

Out of scope by design (owned by blocked tasks): `DOCUMENTATION.md`,
`GETSTARTED.md`, `README.md` (#271); tests + `validate --commands` (#272);
`help/_registry` + dispatch label (#265); config keys (#270). Historical
`docs/tasks/done/**` and the English verb "talk" stay untouched.

### Questions for the developer

None — task is fully defined.

The one nuance ("Script-local model defaults prefer `MODEL_CHAT` when those
lines are touched") is resolved by the Notes and by criterion scope: renaming
files does not touch the `sprintmd_tier_model TALK` lines, so they stay as-is
and the config key rename lands cleanly in #270.

## Completed

Full command rename from `talk` to `chat` across the live `docs/sprintmd/`
tree, plus the `sprint.sh` dispatcher pointer.

- `git mv`'d the five scripts (`talk*.sh → chat*.sh`) and the guide
  (`use_talk.md → use_chat.md`).
- Applied a case-sensitive lowercase `talk → chat` replacement across every
  affected file. This deliberately preserves uppercase `TALK`, so the config
  tier stays intact: `MODEL_TALK` / `SPRINTMD_MODEL_TALK` in `config`,
  `sprintmd_tier_model TALK` lookups, and the "TALK model" tier prose are all
  untouched — the config key cut is #270's job.
- Inter-script sibling resolution now points at the new filenames: `chat.sh`
  resolves `chat-sprint.sh`/`chat-folder.sh`/`chat-bugs.sh`/`chat-plan.sh`,
  and `chat-folder.sh` shells back to `chat.sh`. The `_TALK_*` local var
  *names* remain (uppercase, functionally irrelevant); their values point at
  the renamed files.
- `sprint.sh` `cmd_chat` now `run_script "chat.sh"` (dropped the temporary
  `talk.sh` pointer + the `#266` comment).
- `bash -n` passes on all five renamed scripts and `sprint.sh`;
  `./sprint.sh help chat` resolves; sibling dispatch targets all exist.
- `./ship.sh` mirrored the renames into `src/` (new `chat*.sh` ship, stale
  `talk*.sh` pruned, guide renamed), release gates clean, version 0.0.30 →
  0.0.31. No lowercase `talk` remains in `docs/sprintmd/` or
  `src/docs/sprintmd/`.

Out of scope (owned elsewhere, untouched): config tier key (#270); tests +
`validate --commands` (#272); `DOCUMENTATION.md`/`GETSTARTED.md`/`README.md`
(#271); `help/_registry` + dispatch label (already done by #265). Historical
`docs/tasks/done/**` left alone.

### Files changed
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/chat-bugs.sh
docs/sprintmd/scripts/chat-folder.sh
docs/sprintmd/scripts/chat-plan.sh
docs/sprintmd/scripts/chat-sprint.sh
docs/sprintmd/guides/use_chat.md
docs/sprintmd/guides/sprint_command.md
docs/sprintmd/help/chat.md
docs/sprintmd/help/gate.md
docs/sprintmd/help/plan.md
docs/sprintmd/help/newbug.md
docs/sprintmd/help/newtask.md
docs/sprintmd/help/profile.md
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/plan-think.sh
docs/sprintmd/scripts/plan.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/scripts/profile.sh
docs/sprintmd/scripts/ai-context.sh
docs/sprintmd/lib.sh
docs/sprintmd/ai/bug-creation.md
docs/sprintmd/cli/default.sh
docs/sprintmd/cli/claude.sh
sprint.sh
docs/tasks/doing/266-rename-talk-scripts-and-callers-to-chat.md
src/docs/sprintmd/scripts/chat.sh
src/docs/sprintmd/scripts/chat-bugs.sh
src/docs/sprintmd/scripts/chat-folder.sh
src/docs/sprintmd/scripts/chat-plan.sh
src/docs/sprintmd/scripts/chat-sprint.sh
src/docs/sprintmd/guides/use_chat.md
src/docs/sprintmd/guides/sprint_command.md
src/docs/sprintmd/help/chat.md
src/docs/sprintmd/help/gate.md
src/docs/sprintmd/help/plan.md
src/docs/sprintmd/help/newbug.md
src/docs/sprintmd/help/newtask.md
src/docs/sprintmd/help/profile.md
src/docs/sprintmd/scripts/define.sh
src/docs/sprintmd/scripts/plan-start.sh
src/docs/sprintmd/scripts/plan-think.sh
src/docs/sprintmd/scripts/plan.sh
src/docs/sprintmd/scripts/gate.sh
src/docs/sprintmd/scripts/polish.sh
src/docs/sprintmd/scripts/loop.sh
src/docs/sprintmd/scripts/profile.sh
src/docs/sprintmd/scripts/ai-context.sh
src/docs/sprintmd/lib.sh
src/docs/sprintmd/ai/bug-creation.md
src/docs/sprintmd/cli/default.sh
src/docs/sprintmd/cli/claude.sh
src/sprint.sh
src/VERSION
