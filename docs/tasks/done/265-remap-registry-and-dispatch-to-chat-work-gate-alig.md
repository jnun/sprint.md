# Task 265: Remap registry and dispatch to chat/work/gate + six family groups

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: 266, 267, 268, 269, 270, 271, 272, 273, 274
**Parent**: none

## Problem

The live CLI still labels help groups `pipeline | workflow | inspect | sync |
maint` and dispatches `talk`, `tasks`, `define`, `checkfeatures`, `ai-context`,
`audit-deps`. The matrix target is six families (`create · chat · plan · work ·
look · keep`) and the new command names. Until registry, dispatch, help
basenames, and the manual Commands block move together, every later rename
fights a half-broken surface and `validate --commands` stays red by construction.
A flat work-family list without spine language also invites equal use of off-path
commands.

## Success criteria

- [x] `docs/sprintmd/help/_registry` uses **only** groups: `create | chat | plan | work | look | keep` (no `pipeline`, `workflow`, `inspect`, `sync` as a group name, or `maint`)
- [x] **Every** registry row's group matches the matrix catalog (not only the six renames). Target placement:
  - **create** — `newidea`, `newfeature`, `newtask`, `newplan`, `newbug`, `newtest`
  - **chat** — `chat`
  - **plan** — `plan`
  - **work** — `work`, `loop`, `gate`, `split`, `polish`
  - **look** — `status`, `search`, `align`, `context`
  - **keep** — `profile`, `sync`, `validate`, `cleanup`, `deps`
- [x] Registry **command** renames: `talk→chat`, `tasks→work`, `define→gate`, `checkfeatures→align`, `ai-context→context`, `audit-deps→deps`
- [x] **Spine hierarchy in registry one-line summaries** (required language, not optional polish):
  - `work` — happy-path execute (READY tasks next/ → review/; after `plan start`)
  - `loop` — autopilot spine (`plan start` refill + `work` drain)
  - `gate` — off-spine (re-gate next/ or report on other folders; not on happy path)
  - `split` — off-spine (one-shot split; no conversation)
  - `polish` — after work (quality sweep / deep-judge / `--code`)
  - `plan` / `chat` summaries may mention the spine (`chat → plan start → work`) where a one-liner fits
- [x] **Help basenames renamed with the registry** (so `help <cmd>` cannot 404): `talk.md→chat.md`, `tasks.md→work.md`, `define.md→gate.md`, `checkfeatures.md→align.md`, `ai-context.md→context.md`, `audit-deps.md→deps.md`. Minimal content edit is enough here (title + usage lines use the new command name); full prose rewrites belong to #266–#269
- [x] Root `sprint.sh` help sections print the six family labels only (replace "Sprint pipeline" / "Workflow" / "Inspect" / "Sync" / "Maintenance" titles)
- [x] `sprint.sh` dispatch `case` arms use the **new** command names only (no old arms, no redirects)
- [x] `cmd_*` names match (`cmd_chat`, `cmd_work`, `cmd_gate`, `cmd_align`, `cmd_context`, `cmd_deps`) and `run_script` still targets **existing script basenames** until #266–#269 rename files (e.g. `cmd_chat` → `talk.sh`, `cmd_work` → `tasks.sh`, `cmd_gate` → `define.sh`, `cmd_align` → `check-alignment.sh`, `cmd_context` → `ai-context.sh`, `cmd_deps` → `audit-deps.sh`)
- [x] `DOCUMENTATION.md` Commands block contains `sprint.sh <newcmd>` for every registered command (token swap only — full prose is #271). Required so `validate --commands` check 4 can pass
- [x] `check-commands.sh` (and any hardcoded group allowlist) accepts the six groups and rejects the old ones
- [x] `./sprint.sh help` lists every target command under the correct family
- [x] **`./sprint.sh validate --commands` passes** after this task (registry ↔ dispatch ↔ help pages ↔ manual Commands). Full suite / `--docs` may stay red until #272

## Notes

### Decision lock — what this task owns (atomic surface cut)

This task is the **only** place that changes registry labels, dispatch arms,
help **basenames**, help group printer titles, manual Commands **tokens**, and
**spine language in registry summaries**. Script *bodies* and deep help prose
wait for #266–#269 / #271.

Temporary script basenames are intentional and allowed. Temporary
command/help mismatch is **not** — that breaks `validate --commands` and
`help <cmd>`.

Do **not** invent a second strategy mid-flight ("labels only" vs "rename
everything"). Follow the success criteria above.

### Decision lock — validate phases

| After task | Expectation |
|------------|-------------|
| #265 | `validate --commands` **green**; spine language in registry |
| #266–#271 | Surface works; tests/docs may still assert old names |
| #272 | `validate --commands` + `--docs` + relevant tests **green** |
| #273 | ship + fresh install smoke |
| #274 | former-term grep zero on live paths; re-ship if fixes |

### Other

- Do not rename the `sync` **command**; only its group becomes `keep`.
- Do not rename script files in this task (that is #266–#269). Library/CLI
  gate file renames are #268 (`gate-lib.sh` + `gate.sh`).
- Matrix: `docs/guides/command-matrix.md`

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet — this task is entirely unstarted. Verified current state:

- `docs/sprintmd/help/_registry` still uses the old groups (`pipeline | workflow | inspect | sync | maint`, per its header line 11 and every row) and the old command names (`talk`, `tasks`, `define`, `audit-deps`, `checkfeatures`, `ai-context`). No spine language in summaries.
- `sprint.sh` still prints the old five section titles (`Sprint pipeline` / `Workflow` / `Inspect` / `Sync` / `Maintenance`, lines 90–102), still has old dispatch arms (`talk`, `tasks`, `define`, `audit-deps`, `checkfeatures`, `ai-context`, lines 356–367), and old `cmd_*` names (`cmd_talk`, `cmd_tasks`, `cmd_define`, `cmd_audit_deps`, `cmd_checkfeatures`, `cmd_ai_context`).
- Help pages: `talk.md`, `tasks.md`, `define.md`, `checkfeatures.md`, `ai-context.md`, `audit-deps.md` exist; the six new basenames (`chat.md`, `work.md`, `gate.md`, `align.md`, `context.md`, `deps.md`) do **not**.
- `DOCUMENTATION.md` Commands block (lines 156–169) still lists `talk`, `tasks`, `define`, `audit-deps`, `checkfeatures`, `ai-context`.
- `check-commands.sh` has **no** group allowlist at all — it checks command presence across the four surfaces but never validates the group field.

Good news confirming the task is buildable now: all six `run_script` targets the new `cmd_*` functions must point at already exist (`talk.sh`, `tasks.sh`, `define.sh`, `check-alignment.sh`, `ai-context.sh`, `audit-deps.sh`). So the "temporary basename" strategy in the success criteria works as written — no file renames needed here.

### Remaining work

All of it — this is the full scope:

1. Rewrite `_registry`: header comment + all rows to the six groups (`create | chat | plan | work | look | keep`), the six command renames, the target group placement listed in the criteria, and spine-hierarchy language in the `work`/`loop`/`gate`/`split`/`polish` summaries.
2. `sprint.sh`: replace the five `print_command_group` section titles/calls with the six family labels; rename dispatch arms to the new command names (no old arms, no redirects); rename the six `cmd_*` functions while keeping their `run_script` targets on the existing script basenames.
3. Rename the six help basenames (`git mv` to keep history) with a minimal title/usage token swap; leave deep prose for #266–#269.
4. `DOCUMENTATION.md`: token-swap the six command names in the Commands block (and adjust the section-comment labels for coherence); full prose is #271.
5. Add a group-allowlist check to `check-commands.sh` that accepts the six groups and rejects any other (including the old five).
6. Verify: `./sprint.sh help` lists every command under the right family and `./sprint.sh validate --commands` passes.

### Questions for the developer

1. `check-commands.sh` has no group validation today — the criterion "accepts the six groups and rejects the old ones" therefore means *adding* a new check, not updating an existing allowlist. Add it here? (Suggestion: yes — add a small check that reads each registry row's group field and fails if any value is outside `create|chat|plan|work|look|keep`. It's the only place that mechanically guards the "no parallel taxonomy" rule the matrix demands, and it belongs in the same surface-completeness script that `validate --commands` already runs.)

## References

docs/guides/command-matrix.md
docs/sprintmd/help/_registry
docs/sprintmd/help/talk.md
docs/sprintmd/help/tasks.md
docs/sprintmd/help/define.md
docs/sprintmd/help/checkfeatures.md
docs/sprintmd/help/ai-context.md
docs/sprintmd/help/audit-deps.md
sprint.sh
DOCUMENTATION.md
docs/sprintmd/scripts/check-commands.sh

## Completed

Atomic surface cut landed. Registry, dispatch, help basenames, manual Commands
tokens, and the group-allowlist check all moved together; `validate --commands`
is green.

**What was done**

1. **`_registry`** — header comment now lists the six groups; every row's group
   set to `create | chat | plan | work | look | keep` per the target placement.
   Six command renames applied (`talk→chat`, `tasks→work`, `define→gate`,
   `checkfeatures→align`, `ai-context→context`, `audit-deps→deps`). Spine
   language added to the `work` (happy path), `loop` (autopilot spine), `gate`
   (off-spine), `split` (off-spine one-shot), and `polish` (after work)
   summaries; `chat`/`plan` one-liners mention the `chat → plan start → work`
   spine.
2. **`sprint.sh`** — `show_help` prints six family labels only (Create · Chat ·
   Plan · Work · Look · Keep); dispatch `case` arms use the new names with no old
   arms or redirects (old names now fall through to unknown, verified); the six
   `cmd_*` functions renamed (`cmd_chat`, `cmd_work`, `cmd_gate`, `cmd_align`,
   `cmd_context`, `cmd_deps`) while their `run_script` targets stay on the
   existing script basenames (`talk.sh`, `tasks.sh`, `define.sh`,
   `check-alignment.sh`, `ai-context.sh`, `audit-deps.sh`) until #266–#269.
3. **Help basenames** — `git mv` renamed all six (`talk.md→chat.md`,
   `tasks.md→work.md`, `define.md→gate.md`, `checkfeatures.md→align.md`,
   `ai-context.md→context.md`, `audit-deps.md→deps.md`) with a minimal
   self-invocation token swap in the usage lines; deep prose left for #266–#269.
4. **`DOCUMENTATION.md`** — Commands block token-swapped to the six new names
   (and the loop comment's "tasks"→"work"); the old `# Workflow / # Inspect /
   # Sync / # Maintenance` section labels relabeled to Chat & Work / Look / Keep
   for coherence. Full prose reorg is #271.
5. **`check-commands.sh`** — added Check 5: a group allowlist that fails any
   registry row whose group is outside `create|chat|plan|work|look|keep`.
   Verified it rejects a planted `pipeline` group (exit 1) and passes when clean.

**Verification**

- `./sprint.sh help` lists every command under the correct family.
- `./sprint.sh validate --commands` → `✓ Every command is fully surfaced` (exit 0),
  22 commands across all four surfaces.
- Old names (`talk`, `tasks`) fall through to `Unknown command` — no redirects.
- `./sprint.sh help chat` resolves (no 404); `./sprint.sh context` routes.
- Group check rejects an out-of-family group and passes once restored.

Per the decision lock, `ship.sh` (#273) and full-suite / `--docs` greenness
(#272) are out of scope here and were not run.

Note: the `plan` and `polish` help rows show a truncated usage-suffix because
those suffixes contain a literal `|` that `print_command_group` splits on — a
**pre-existing** display quirk (both rows carried a pipe before this task), not
introduced here and outside this task's scope.

### Files changed

docs/sprintmd/help/_registry
sprint.sh
DOCUMENTATION.md
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/help/chat.md
docs/sprintmd/help/work.md
docs/sprintmd/help/gate.md
docs/sprintmd/help/align.md
docs/sprintmd/help/context.md
docs/sprintmd/help/deps.md
docs/tasks/doing/265-remap-registry-and-dispatch-to-chat-work-gate-alig.md
