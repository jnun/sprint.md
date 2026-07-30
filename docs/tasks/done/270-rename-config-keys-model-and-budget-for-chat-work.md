# Task 270: Rename config MODEL/BUDGET keys for chat, work, gate

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 266, 267, 268
**Blocks**: 271, 272, 274
**Parent**: none

## Problem

`docs/sprintmd/config` still exposes `MODEL_TALK`, `MODEL_DEFINE`,
`MODEL_TASKS`, `BUDGET_TASKS`, and related env overrides. After command renames,
agents will set `MODEL_CHAT` / `BUDGET_WORK` mentally; stale keys break that
mapping and teach the old surface.

## Success criteria

- [x] Config keys renamed (hard cut, no permanent dual-read): `MODEL_TALK→MODEL_CHAT`, `MODEL_DEFINE→MODEL_GATE`, `MODEL_TASKS→MODEL_WORK`, `BUDGET_TASKS→BUDGET_WORK`
- [x] `lib.sh` / script readers use the new keys (and `SPRINTMD_` env overrides if any)
- [x] Dead `MODEL_TALK` / `MODEL_DEFINE` / `MODEL_TASKS` / `BUDGET_TASKS` removed from shipped config template and readers
- [x] `MODEL_TRIAGE` / `MODEL_REVIEW_SPRINT`: remove if nothing reads them; otherwise mark clearly legacy-only with **no new writers**
- [x] Help/profile text that mentions **these** config key names uses the new ones
- [x] Existing dogfood `docs/sprintmd/config` in this repo updated so local runs work

## Notes

### Decision lock — keys in scope vs out of scope

**In this task (must rename/clean):**

| Old | New |
|-----|-----|
| `MODEL_TALK` | `MODEL_CHAT` |
| `MODEL_DEFINE` | `MODEL_GATE` |
| `MODEL_TASKS` | `MODEL_WORK` |
| `BUDGET_TASKS` | `BUDGET_WORK` |
| `MODEL_TRIAGE` | remove or legacy-only, no writers |
| `MODEL_REVIEW_SPRINT` | remove or legacy-only (plan-think already has `MODEL_PLAN_THINK`) |

**Out of scope for plan 8** (leave as-is; polish-mode / other hygiene later):

- `MODEL_POLISH`, `MODEL_SPLIT`, `MODEL_PROFILE`, `MODEL_FEATURE`, `MODEL_IDEA`, `MODEL_DEPS`, `MODEL_PLAN_THINK`, `MODEL_DEFAULT`, `MODEL_DRIFT`
- `MODEL_AUDIT`, `MODEL_EXCELLENCE`, `MODEL_CODE_AUDIT`, `MODEL_SPRINT` — profession-tinged names but they are polish/internal mode keys, not retired top-level commands. Do not rename them in this plan; do not invent dual-language aliases.

- `MODEL_DEPS` already pairs with `deps` — keep.
- Prefer hard cut (invariant 5). No permanent dual-read of `MODEL_TASKS` etc.

### Implementation files after prior tasks

Readers live under the **new** script basenames: `chat.sh`, `work.sh`,
`gate.sh` (CLI), plus library `gate-lib.sh` if it reads model keys. Do not
assume the CLI is still named `define.sh` or that the library is still `gate.sh`.

## References

docs/sprintmd/config
docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/gate-lib.sh
docs/guides/command-matrix.md

## Questions

**Status: READY**

### Already complete

Nothing is done yet. Verified against current code: `docs/sprintmd/config`
still declares the old keys (`MODEL_TALK`, `MODEL_DEFINE`, `MODEL_TASKS`,
`BUDGET_TASKS`, `MODEL_TRIAGE`, `MODEL_REVIEW_SPRINT`), and no `MODEL_CHAT` /
`MODEL_GATE` / `MODEL_WORK` / `BUDGET_WORK` appears anywhere except the plan-8
task files.

### Remaining work

The mechanism is a suffix-based resolver: `sprintmd_resolve_model SFX` /
`sprintmd_tier_model SFX` (lib.sh:187, 220) read `MODEL_<SFX>`, and budget is
read as `SPRINTMD_BUDGET_TASKS` in lib.sh:779–780. So renaming a config key
means renaming both the config declaration **and** the suffix passed at each
call site.

Concrete edits:

1. **`docs/sprintmd/config`** — rename the four keys (lines 33/34/37/51):
   `MODEL_TALK→MODEL_CHAT`, `MODEL_DEFINE→MODEL_GATE`, `MODEL_TASKS→MODEL_WORK`,
   `BUDGET_TASKS→BUDGET_WORK`.
2. **Model-resolver call sites (suffix change):**
   - `TALK→CHAT`: `talk.sh:85`, `talk-plan.sh:92`, `talk-sprint.sh:387`,
     `talk-bugs.sh:45` (these files become `chat*.sh` via task 266).
   - `DEFINE→GATE`: `gate.sh:80` (`sprintmd_resolve_model DEFINE`), plus the
     `define.sh:59` fallback (define.sh is removed/folded by task 268).
   - `TASKS→WORK`: `tasks.sh:93` (becomes `work.sh` via task 267).
3. **Budget rename:** `lib.sh:779–780` (`SPRINTMD_BUDGET_TASKS`/`BUDGET_TASKS`),
   and the `tasks.sh` call sites at lines 103 and 228 (`SPRINTMD_BUDGET_TASKS`).
4. **`MODEL_TRIAGE`** — still has live readers (`talk-folder.sh:51`,
   `talk-bugs.sh:41`), so it cannot be deleted; keep it and mark it legacy-only
   in the config comment (no new writers), per the decision lock.
5. **`MODEL_REVIEW_SPRINT`** — already a legacy fallback read only by
   `plan-think.sh:20` when `MODEL_PLAN_THINK` is empty, and config lines 46–47
   already label it as such. Leave it legacy-only; no rename.
6. **Help/guide text mentioning these key names:** `help/tasks.md:31`
   (`BUDGET_TASKS`), `help/tasks.md:65` (`SPRINTMD_MODEL_TASKS`),
   `guides/use_talk.md:104` (`MODEL_TALK` / `SPRINTMD_MODEL_TALK`). Update to the
   new key names (these files also get swept by task 271, but the key-name fix
   is this task's per success-criterion 5).
7. **Dogfood config** — `docs/sprintmd/config` in this repo is the live config,
   so editing it (step 1) already covers the local-runs criterion; `./ship.sh`
   mirrors it to `src/`.

`MODEL_DEPS` correctly stays (already pairs with `deps`). Out-of-scope keys in
the decision lock (`MODEL_POLISH`, `MODEL_SPLIT`, `MODEL_PROFILE`, etc.) are
left untouched — confirmed they are read under their own suffixes and are not
part of this rename.

**Dependency note:** the `TALK`/`TASKS`/`DEFINE` call sites live in scripts that
tasks 266/267/268 rename (`talk*→chat*`, `tasks→work`, `define→gate`). Those
renames change the *file* names; this task changes the *config suffix*. There is
no conflict — the runner holds 270 in `next/` until 266/267/268 reach review.
`**Depends on**: 266, 267, 268` is already recorded at the top of the file.

### Questions for the developer

None — task is fully defined.

## Completed
- MODEL_TALK→CHAT, DEFINE→GATE, TASKS→WORK, BUDGET_TASKS→BUDGET_WORK
- Readers in lib/work/gate/chat* + setup migration + help/guides
- MODEL_TRIAGE kept (chat-folder/chat-bugs readers); MODEL_REVIEW_SPRINT legacy-only
