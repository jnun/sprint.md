# Task 274: Grep former terms + universal product-doc audit

**Feature**: none
**Created**: 2026-07-30
**Docs**: /docs/guides/command-matrix.md
**Depends on**: 273
**Blocks**: none
**Parent**: none

## Problem

A large command remap leaves stragglers: one help cross-link, one agent
prompt, one test assertion, one provider guide. Without a deliberate former-
term sweep, those become permanent dual-language debt and agents keep typing
dead commands. Separately, the three public product docs — README,
DOCUMENTATION, and the command matrix — can drift from each other or from the
live CLI even when scripts are clean. This task is audit + fix only:
regression tests for stale commands were owned by #272; content prep by #271.

## Success criteria

### A. Former-term grep (live surface)

- [x] Run a documented grep pass for **command-shaped** former terms (not bare English), at least:

  ```bash
  # User-facing invocations
  rg -n '\./sprint\.sh (talk|tasks|define|checkfeatures|ai-context|audit-deps)\b' \
    --glob '!docs/tasks/done/**' --glob '!docs/tasks/review/**' \
    --glob '!docs/plans/2-command-matrix-redesign.md' \
    --glob '!.git/**'

  # Dispatch arms
  rg -n '^\s+(talk|tasks|define|checkfeatures|ai-context|audit-deps)\)' \
    sprint.sh src/sprint.sh docs/sprintmd/ src/docs/sprintmd/

  # Old cmd_* names
  rg -n '\b(cmd_talk|cmd_tasks|cmd_define|cmd_checkfeatures|cmd_ai_context|cmd_audit_deps)\b' \
    sprint.sh src/sprint.sh docs/sprintmd/ src/docs/sprintmd/

  # Help / script basenames that should be gone (expect "No such file")
  ls docs/sprintmd/help/talk.md docs/sprintmd/help/tasks.md \
     docs/sprintmd/help/define.md docs/sprintmd/help/checkfeatures.md \
     docs/sprintmd/help/ai-context.md docs/sprintmd/help/audit-deps.md 2>&1

  ls docs/sprintmd/scripts/talk*.sh docs/sprintmd/scripts/tasks.sh \
     docs/sprintmd/scripts/define.sh docs/sprintmd/scripts/ai-context.sh \
     docs/sprintmd/scripts/audit-deps.sh 2>&1

  # Config keys this plan renamed
  rg -n 'MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS' \
    docs/sprintmd/config src/docs/sprintmd/config docs/sprintmd/lib.sh \
    src/docs/sprintmd/lib.sh docs/sprintmd/scripts src/docs/sprintmd/scripts

  # Old registry groups
  rg -n '\|(pipeline|workflow|inspect|maint)\|' \
    docs/sprintmd/help/_registry src/docs/sprintmd/help/_registry

  rg -n 'print_command_group (pipeline|workflow|inspect|maint)\b' \
    sprint.sh src/sprint.sh
  ```

- [x] Every hit is either **fixed** or listed in an allowlist section in this task's `## Completed

### A. Former-term grep summary

| Check | Result |
|-------|--------|
| `./sprint.sh talk\|tasks\|define\|…` on live surface | **0** (README, DOCUMENTATION, GETSTARTED, docs/sprintmd, src/) |
| Dispatch arms / cmd_* | **0** |
| Old help/script basenames | **gone** (expect No such file) |
| MODEL_TALK/DEFINE/TASKS, BUDGET_TASKS | **0** in config/lib/scripts (only tripwire patterns in `test-no-stale-refs.sh`) |
| Old registry groups | **0** |

**Allowlist (intentional leftovers):**
- `docs/plans/8-…` and plan archaeology — document the remap itself
- `docs/guides/command-matrix.md` retired-names table — history
- `docs/tests/test-no-stale-refs.sh` — tripwire patterns
- `validate-tasks.sh` filename — validates task *files* (invariant)
- English “workflow”, “defined”, task noun paths under `docs/tasks/`
- Plan 5 backlog tasks **updated** to new names (were teaching old surface)

**Re-ship:** ran `./ship.sh` after README family line + backlog fixes (v0.0.33 or next patch).

### B. Universal product-doc audit

| # | Checklist | Result |
|---|-----------|--------|
| 1 | Six families | **PASS** — DOCUMENTATION + matrix + README help-groups line; live `./sprint.sh help` |
| 2 | Six renames live | **PASS** — chat/work/gate/align/context/deps dispatch; trio greps clean |
| 3 | Spine hierarchy | **PASS** — all three files + help registry teach chat → plan start → work → polish |
| 4 | Task noun | **PASS** — docs/tasks/, newtask, validate-tasks.sh; execute verb work |
| 5 | Matrix not regressed | **PASS** — family map + retired table intact |
| 6 | Cross-file agreement | **PASS** |
| 7 | Live CLI agreement | **PASS** — create/chat/plan/work/look/keep |
| 8 | Command-shaped greps on trio | **PASS** — zero hits on README/DOCUMENTATION; matrix only retired table |

### C. False friends
- docs/tasks/ exists; newtask works; gate.sh CLI; gate-lib.sh source-only

