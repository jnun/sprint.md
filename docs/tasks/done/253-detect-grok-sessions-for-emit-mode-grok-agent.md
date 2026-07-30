# Task 253: Detect Grok sessions for emit mode (GROK_AGENT)

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: 254, 256
**Parent**: none

**Status: READY**

## Problem

When the user is already inside Grok Build and runs `./sprint.sh chat` (or
`work` / `gate` / `polish`), auto mode should **emit** the prompt into the
current session — not nest another CLI. Claude and Cursor set env vars that
`sprintmd_ai_mode` recognizes; Grok sets `GROK_AGENT=1`, which is ignored
today. That forces exec of the configured CLI (often `claude`) from inside
Grok, which is wrong and wastes context.

## Success criteria

- [ ] With `GROK_AGENT` set (and `MODE` empty), `sprintmd_ai_mode` returns `emit`
- [ ] Other Grok session markers, if stable and documented, are included only
      after verifying they appear in real Grok Build shells (today: `GROK_AGENT=1`
      is confirmed; do not invent extras)
- [ ] Outside Grok, with no agent env and `claude`/`grok` on PATH, mode remains
      `exec` as before
- [ ] Explicit `MODE=exec` / `MODE=emit` still override auto-detect
- [ ] Mode cache still works (`_SPRINTMD_MODE_CACHE`); detection is part of the
      same auto-detect branch as `CLAUDECODE` / `CURSOR_TRACE_ID`

## Notes

- Confirmed in a live Grok Build shell (2026-07-30): `GROK_AGENT=1` is present.
- Keep the detection list minimal — only vars that actually mean "we are inside
  an agent session."
- Independent of the profile (#251); can land first and immediately improves
  "run sprint.md inside Grok" for any CLI config.
- Docs touch for emit-inside-Grok lives primarily in #256 (`use_chat.md`); this
  task may leave a one-line code comment only.

## References

docs/sprintmd/lib.sh
docs/sprintmd/guides/use_chat.md

## Completed

Implemented as part of plan 5 (Grok Build first-class provider).
