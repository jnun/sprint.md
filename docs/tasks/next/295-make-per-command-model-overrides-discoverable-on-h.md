# Task 295: Make per-command model overrides discoverable on help and common flags

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 294
**Blocks**: 297
**Parent**: none

**Status: READY**

## Problem

Env overrides (`SPRINTMD_MODEL_WORK`, `SPRINTMD_MODEL_CHAT`, …) already win over
config, but help pages barely teach them, and there is no consistent
`--model <id>` on the commands people run most. Users who want “this one work
run on model X” should not need to export env vars from memory.

## Success criteria

- [ ] Document on `model` help + relevant command help (`work`, `chat`, `gate`,
      `polish` at minimum): precedence
      `flag/env → MODEL_<ROLE> → MODEL_DEFAULT → tier default → CLI default`
- [ ] Where cheap and consistent, add optional `--model <id>` to high-traffic
      scripts so a single invocation can pin without editing config
      (implementation may set `SPRINTMD_MODEL_*` for that process)
- [ ] No silent ignore: unknown flag errors; empty model clears only if
      explicitly designed (prefer pin, not accidental clear)
- [ ] README or DOCUMENTATION one-liner points at `./sprint.sh model` and
      per-run override

## Notes

- Do not add `--model` to every obscure script — prioritize the spine.
- Keep flag parsing consistent with existing long-options style.

## References

docs/sprintmd/help/work.md
docs/sprintmd/help/chat.md
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/lib.sh
