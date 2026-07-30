# Task 234: Improve ./sprint.sh profile behavior

**Feature**: none
**Created**: 2026-07-29
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

`./sprint.sh profile` works, but it could be better. It generates and updates
`docs/sprintmd/project.md` — the profile that ~8 AI commands inject into every
session — so any weakness here quietly degrades every downstream task. Today the
update path leans on the user's memory instead of re-detecting the stack, there's
no cheap way to just view a profile without launching an AI session, and two
consumer scripts hand-inline the profile pointer instead of using the shared
helper (latent drift). None of these break it; they keep it from being as
functional, robust, and fast as the rest of the CLI.

## Success criteria

<!-- Done = functional (does more, correctly), robust (survives odd input and
     drift), and faster (no AI session for cheap reads). -->

- [x] **Not silent / can converse** — running `./sprint.sh profile` in a real
      terminal (exec mode) shows live activity as it works AND lets the user
      answer the confirmation questions. It must never sit with zero output
      looking crashed.
- [x] **Functional** — update mode re-scans the project and diffs against the
      existing `project.md`, surfacing detected drift instead of only asking the
      user what changed.
- [x] **Faster** — a non-AI read path (`./sprint.sh profile show` or equivalent)
      prints the current profile, or a clear "no profile yet" message, without
      spawning an interactive AI session.
- [x] **Robust** — every script that reads the profile goes through
      `sprintmd_profile_line()`; no inlined copies of the pointer string remain,
      so wording/path changes can't silently drift.

## Notes

Checklist of what to fix and why (ranked by value):

0. **It looks locked up and can't actually converse (most fundamental)** —
   observed live: `./sprint.sh profile` prints `▸ Creating project profile…`
   then sits with zero output, looking crashed. It is not crashed; it is
   running silently. Two layered causes:
   - `profile.sh:78-83` calls `fiveday_run` with **no `--output-format json`**,
     so the live tool-call narrator in `claude.sh:40-73` (which prints
     `  . Read: <file>` lines to stderr) never activates — `stream=0`.
   - Even the buffered path redirects BOTH stdout and stderr to temp files
     (`claude.sh:239`) and only `cat`s them after the run returns
     (`claude.sh:272-273`), so the screen is dead mid-run regardless.

   Deeper: profile's prompt says "ask the user to confirm each field" — a
   dialogue — but it uses the one-shot `fiveday_run` path, not
   `fiveday_run_interactive`. In exec mode that path sees a non-TTY, does one
   silent pass, writes the file, and exits — so the user can't even answer.
   **Fix:** route profile through `fiveday_run_interactive` (as `talk.sh` does)
   so the CLI inherits the real terminal — live activity AND turn-by-turn
   replies. Minimum stopgap (if kept one-shot) is adding `--output-format json`
   to surface the narrator, but that leaves it unable to converse, so it's only
   half the fix. This is the item that makes the command feel broken today.

1. **Update mode should re-scan, not just ask** — `profile.sh:21-25`. Create mode
   auto-detects the stack from manifests and presents a draft; update mode only
   says "ask the user what has changed," leaning on their memory. It should reuse
   the create-mode detection, diff against the existing `project.md`, and surface
   drift proactively ("`go.mod` gained a framework; `pytest.ini` is new — update
   Tests?"). This is the real upgrade — it makes update mode pull its weight.

2. **Add a cheap, non-AI read path** — today every invocation spawns an
   interactive AI session. There's no way to just *see* the profile or check
   whether one exists. A `profile show` subcommand (plain `cat`, or "no profile
   yet — run `./sprint.sh profile` to create one") costs nothing at runtime and
   is a common need.

3. **Consolidate two consumers that inline the pointer string** —
   `create-idea.sh:68` and `create-feature.sh:64` hand-inline the
   "Also read docs/sprintmd/project.md…" string instead of calling
   `fiveday_profile_line()` (`lib.sh:220`), which every other consumer uses. They
   match today, so it's not a live bug — but it's exactly what drifts the next
   time the path or wording changes (the path has moved before). One-line fix each.

Edge-case behavior is already solid (verified): `newtask` slug-building strips
path separators (`../../etc/passwd` → `etc-passwd`, no traversal), strips symbols,
and errors cleanly on empty / symbol-only input. No sanitization work needed.

Considered and rejected as over-engineering for this system: staleness
timestamps / SHA-stamping the profile, and making the 7 profile fields
configurable (the fixed flat set is intentional).

Standard flow applies: edit under `docs/sprintmd/`, test in place, then
`./ship.sh` to mirror into `src/` and bump the version.

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->
docs/sprintmd/scripts/profile.sh
docs/sprintmd/lib.sh
docs/sprintmd/cli/claude.sh
docs/sprintmd/scripts/talk.sh
docs/sprintmd/scripts/create-idea.sh
docs/sprintmd/scripts/create-feature.sh
docs/sprintmd/help/profile.md

## Questions

**Status: READY**

### Already complete
Nothing is implemented yet — all four items are still open. The scaffolding they
build on is in place and verified:
- `fiveday_run_interactive` / `fiveday_interactive_ok` (`lib.sh:579`, `:564`) and
  the interactive provider (`claude.sh:312`) exist and are proven by `talk.sh`.
- `fiveday_profile_line()` (`lib.sh:220`) exists and is the shared helper every
  other consumer already uses.
- Create-mode auto-detection (`profile.sh:28-38`) already does the manifest scan
  that item 1's update mode needs to reuse.
The Notes also record two things verified as already-solid and explicitly out of
scope: `newtask` slug sanitization (no traversal) and the rejected
staleness-stamping / configurable-fields ideas. No action needed on those.

### Remaining work
1. **Item 0 — route through `fiveday_run_interactive`.** Replace the one-shot
   `fiveday_run` call at `profile.sh:78` with `fiveday_run_interactive`, mirroring
   `talk.sh:289` (add `--permissions "auto"`). This makes the exec path inherit
   the terminal so it shows live activity and lets the user answer confirmations,
   instead of sitting silent and one-shot. Emit mode is unaffected (both route
   identically in emit).
2. **Item 1 — update mode re-scans.** Rewrite the update-branch `MODE_INSTRUCTION`
   (`profile.sh:21-25`) to reuse the create-mode detection, diff against the
   existing `project.md`, and surface detected drift proactively rather than only
   asking what changed. Prompt-content change only.
3. **Item 2 — `profile show` read path.** Add arg parsing to `profile.sh` so
   `show` (and no-arg keeps current behavior) `cat`s `project.md` or prints a
   "no profile yet — run `./sprint.sh profile`" message, with no AI session.
4. **Item 3 — consolidate consumers.** Replace the inlined pointer blocks at
   `create-idea.sh:67-69` and `create-feature.sh:63-65` with
   `_PROFILE_LINE="$(fiveday_profile_line)"`.
Standard flow: edit under `docs/sprintmd/`, test in place, then `./ship.sh`.

### Questions for the developer
1. Should the new `profile show` subcommand be wired into the command catalog
   (`help/_registry`, help index) so `validate --commands` still finds all four
   surfaces in agreement? (Suggestion: yes — add it to `_registry` and refresh
   `help/profile.md`'s Usage block. A new user-visible subcommand that skips the
   registry is exactly the drift `validate --commands` exists to catch, so treat
   the registry entry and the help update as part of item 2, not an afterthought.)
2. When item 0's interactive path can't run live (non-TTY / non-interactive
   provider) and degrades to the one-shot exec path, should `profile` print the
   same "doing a single pass instead" warning `talk.sh:282-287` shows?
   (Suggestion: yes — reuse the identical `fiveday_interactive_ok` guard and
   message so a user on a pipe or in CI isn't surprised by a silent one-shot run.
   It's a copy of an existing, proven block, and keeping the two commands'
   degrade behavior identical costs nothing.)

## Completed

### Files changed
docs/sprintmd/scripts/profile.sh
docs/sprintmd/scripts/create-idea.sh
docs/sprintmd/scripts/create-feature.sh
docs/sprintmd/help/profile.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
docs/tests/test-profile.sh
src/docs/sprintmd/scripts/profile.sh
src/docs/sprintmd/scripts/create-idea.sh
src/docs/sprintmd/scripts/create-feature.sh
src/docs/sprintmd/help/profile.md
src/docs/sprintmd/help/_registry
src/DOCUMENTATION.md
src/VERSION
