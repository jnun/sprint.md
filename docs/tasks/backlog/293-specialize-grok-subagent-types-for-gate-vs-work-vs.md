# Task 293: Specialize Grok subagent types for gate vs work vs polish

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 292
**Blocks**: 296
**Parent**: none

**Status: READY**

## Problem

All Grok orchestration prompts currently say `subagent_type: general-purpose`.
Grok also has `explore` (read/search/shell, no edits) and `plan`, plus
`capability_mode` (`read-only` | `read-write` | `execute` | `all`). Gate and
read-heavy paths do not need full write/implement tools; using the full agent
for every fan-out is slower, riskier, and ignores a free host capability.

## Success criteria

- [ ] Shared helper(s) choose worker type (and optional capability_mode) by
      role, e.g.:
      - **work / implement** → `general-purpose`
      - **gate / definition review** → `explore` or `general-purpose` +
        `capability_mode: read-write` limited to task files — pick one policy
        and document it
      - **polish judge** → `general-purpose` (must edit task files only; prompt
        already forbids product code edits)
- [ ] All emit fan-out sites use the helper — no ad-hoc type strings
- [ ] Claude wording unchanged (still Task tool; no fake Grok types on Claude)
- [ ] Brief note in grok-provider-tier guide on which role maps to which type

## Notes

- Gate must still be allowed to Edit/Write the **task file** and move files if
  the emit contract requires it — pure `explore` may be too strict if it cannot
  edit. If so, prefer `general-purpose` + prompt contract, or verify
  `capability_mode: read-write` behavior before locking.
- Nesting depth remains one: workers never orchestrate.
- **From #298 burn (KU-12/13):** gate-lib emit contract **requires** Edit/Write
  on the task file and `git mv` (shell). Pure `explore` (no file edits) is
  **insufficient** for the current gate path. Default recommendation: keep
  gate on `general-purpose` unless a verified capability_mode preserves
  edit + shell for moves.

## References

docs/sprintmd/lib.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/polish.sh
~/.grok/docs/user-guide/16-subagents.md
