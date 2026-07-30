# Task 221: Make setup.sh already-installed detection robust and non-destructive

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

As someone re-running `setup.sh` on a project that already has sprint.md
installed, I need the installer to correctly recognize the prior install and
update it cleanly — without duplicating entries, clobbering my own additions,
or wrongly deciding it's "already done" and skipping real work. Today the
detection is a fragile substring match, and installer safety is only as good
as the weakest such heuristic. Because `setup.sh` writes into other people's
projects, a wrong guess here silently corrupts a user's files — the highest-
stakes failure mode this project has.

The `.gitignore` step is the concrete example that surfaced this: at
setup.sh:1213 the installer decides a user's `.gitignore` already contains
our entries with `grep -q "sprint.md" .gitignore`. Any incidental mention of
the string `sprint.md` (a path, a comment, an unrelated tool) makes setup
believe it's already installed and skip adding the recommended entries.

Note that the merge path *below* that guard is already sound: it filters
per-line with `grep -qxF` (no duplicate blocks) and prepends atomically via a
temp file + `mv`. So the `.gitignore` fix is narrow — remove the fragile
`grep -q "sprint.md"` early-out so the existing merge logic always runs; the
idempotency and non-destructiveness it already provides just need to stop
being short-circuited. The real breadth of this task is elsewhere: this is a
detection problem, not just a `.gitignore` problem — audit every "is this
already installed / already modified?" decision in setup.sh for the same
substring fragility (README and the AI-pointer files gate on
`grep -q "DOCUMENTATION.md"` at setup.sh:833 and setup.sh:947 — same class).

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `.gitignore` install/update keys off an unambiguous sprint.md marker
      (e.g. the `# === sprint.md Recommended Entries ===` header it already
      writes), not a bare `sprint.md` substring, so incidental mentions no
      longer cause a false "already installed" skip.
- [x] Re-running setup.sh on an already-installed project stays idempotent:
      it adds nothing already present and never duplicates a block. (The
      `.gitignore` merge path already guarantees this once the early-out is
      removed — verify it is not regressed, don't rebuild it.)
- [x] Every other "already present / already modified" decision in setup.sh
      (AI pointer files, docs scaffolding, config) is audited and uses a
      marker robust to incidental substring collisions; findings fixed or
      recorded.
- [x] setup.sh never truncates or overwrites a user's existing file content
      on the update path — prepend/append only, existing content preserved
      verbatim. The temp-file + `mv` guard at setup.sh:1272 is the pattern;
      confirm every other write path that touches a pre-existing user file
      (README, AI pointers) follows it.
- [x] The detection/merge decision logic is extracted into small pure
      shell functions (e.g. a `gitignore_merge` / `already_ours` helper)
      that take content as arguments and return a decision — separable from
      the interactive `read -r` prompt flow.
- [x] Unit tests in `docs/tests/` (following the existing `test-*.sh`
      pattern) exercise those helpers directly and cover: fresh install,
      re-run (idempotent), an existing `.gitignore` that incidentally
      contains "sprint.md", and an existing file with our entries phrased
      differently. The interactive shell wrapper is left untested by design.

## Notes

- Root cause is a substring heuristic standing in for "did WE install this?".
  The durable fix is an explicit, unique marker written on install and matched
  on update — the same discipline ship.sh uses for legacy-brand gating.
- Scope is the whole installer's detection logic, not only the `.gitignore`
  branch — that branch is the exemplar, not the boundary.
- Respect the repo's dual-tree rules: setup.sh lives only at the repo root and
  is not mirrored by ship.sh; there is one copy to edit.
- Keep user-territory files minimal per CLAUDE.md — do not enrich the AI
  pointer stubs while touching this.
- Testing approach (decided): extract the detection/merge decisions into small
  pure shell helpers and unit-test *those* directly, rather than driving the
  interactive installer through piped stdin. Cleaner tests, and the extraction
  is itself the durable fix — the substring bugs live in decision logic, so
  isolating that logic is where the value is. Accept the trade-off that it
  edits install flow on the highest-stakes file; that file is what we're
  hardening anyway.
- Confirmed audit targets (already verified against current setup.sh):
  README at setup.sh:833 and the AI-pointer copy at setup.sh:947 both gate on
  `grep -q "DOCUMENTATION.md"` — the same incidental-substring class as the
  `.gitignore` guard. Install-detection at setup.sh:207/219/238 keys off file
  existence (robust), and config writes at setup.sh:280/1503 use anchored
  `^key=` matches (robust) — those are fine, not part of the fix.

## References

setup.sh
docs/sprintmd/scripts/create-task.sh
setup.sh:1213 — the fragile `.gitignore` early-out (the core bug)
setup.sh:1272 — the temp-file + `mv` atomic-write pattern to follow
setup.sh:833, setup.sh:947 — the sibling `DOCUMENTATION.md` substring gates
docs/tests/test-create-task.sh — existing `test-*.sh` pattern for the new tests

## Think Notes

**Reviewed**: 2026-07-28

- **Key finding (scope narrowed):** the `.gitignore` merge logic below the
  buggy guard already does per-line dedup and atomic writes. The real fix is
  to delete the `grep -q "sprint.md"` early-out, not to rebuild idempotency or
  safety. Problem and criteria #2/#4 were reframed from "build" to "don't
  regress" accordingly.
- **Real breadth is the audit, not the exemplar.** Confirmed two genuine
  sibling offenders (setup.sh:833, :947) and confirmed the install-detection
  and config-write paths are already robust — so the audit has a bounded,
  concrete target list rather than an open-ended sweep.
- **Alternative weighed for testing:** piping canned answers into the live
  interactive installer (matches nothing existing, brittle) vs. extracting
  pure helpers and testing those. Chose extraction — it doubles as the fix.
- **Assumption validated:** no existing `setup.sh` test harness — all 14
  `docs/tests/test-*.sh` files exercise CLI scripts only, so criterion #5 is
  net-new infrastructure and was priced in as its own criterion.
- **Risk:** setup.sh writes into other people's projects; the extraction
  refactor touches install flow on the highest-stakes file. Mitigation is the
  new helper-level tests plus the preserved temp-file + `mv` guard.

## Questions

**Status: READY**

### Already complete

- **Atomic-write safety (criterion #4) is already in place on every pre-existing-file
  write path.** Verified in current setup.sh: README prepend (lines ~852–860),
  `setup_ai_file` prepend (lines ~962–968), and the `.gitignore` prepend
  (lines ~1284–1287) all build a `mktemp` temp file and `mv -f` it into place, so
  a partial failure cannot truncate the user's file. The README-create branch only
  fires when no README exists (`[ ! -f README.md ]`), so it never overwrites. This
  criterion is therefore a *verify-don't-regress* item, not new construction — keep
  the temp-file+`mv` pattern intact when refactoring.
- **The `.gitignore` merge logic below the buggy guard is already correct.** The
  per-line `grep -qxF` dedup and section-flush logic (lines ~1231–1305) does exactly
  what criterion #2 asks. Nothing to rebuild — just stop short-circuiting it.
- **The install-state detection and config-write paths are already robust** (confirmed
  in the task's audit notes): file-existence checks at ~207/219/238 and anchored
  `^key=` matches at ~280/~1514. Correctly excluded from scope.

### Remaining work

None of the six criteria's *fixes* are implemented yet — this task is essentially
all remaining. Scope for the sprint:

1. **Remove the fragile `.gitignore` early-out** (criterion #1). Current line ~1224,
   `if grep -q "sprint.md" .gitignore`, must key off an unambiguous marker (the
   `# === sprint.md Recommended Entries ===` header it already writes) or be deleted
   so the sound merge logic below always runs.
2. **Fix the two sibling `DOCUMENTATION.md` substring gates** (criterion #3): README
   at line ~844 and `setup_ai_file` at line ~958, both `grep -q "DOCUMENTATION.md"`.
   Match a unique marker from the pointer we actually write, not a bare filename
   mention. (See Q1.)
3. **Extract detection/merge decisions into small pure shell helpers** (criterion #5) —
   e.g. an `already_ours`/`gitignore_merge` that take content as arguments and return
   a decision, separable from the interactive `read -r` flow. No such helper exists
   today (`merge_config` is config-only and unrelated).
4. **Add unit tests under `docs/tests/`** following the `test-*.sh` pattern
   (criterion #6) — no `test-setup*.sh` exists. Cover: fresh install, idempotent
   re-run, a `.gitignore` that incidentally contains "sprint.md", and a file with our
   entries phrased differently. Test the helpers directly; leave the interactive
   wrapper untested by design.
5. **Verify criteria #2 and #4 are not regressed** by the refactor.

Note: the line numbers cited in Problem/References/Notes have drifted (1213→1224,
1272→1284, 833→844, 947→958). Grep for the patterns rather than trusting the numbers.

### Questions for the developer

1. What marker should the README/AI-pointer gates match instead of the bare
   `DOCUMENTATION.md` substring? (Suggestion: match a distinctive fragment of the
   exact pointer we write — for README, `managed by [sprint.md]`; for AI files, gate
   on whether the file already contains our full first line rather than just the
   string `DOCUMENTATION.md`. This is the "did WE install this?" discipline the task
   calls for, and both fragments are unique enough that no incidental host-project
   mention collides. It's an execution detail, not a blocker — either fragment works.)

## Completed

**Completed**: 2026-07-28

Root cause was a set of substring heuristics standing in for "did WE install
this?". Replaced them with explicit, unique markers written on install and
matched on update, and extracted the detection/merge decisions into pure,
unit-tested helpers.

**What changed in `setup.sh`:**

- Added a fenced block of pure decision helpers (between
  `# >>> sprint.md detection helpers` / `# <<< sprint.md detection helpers`
  sentinels) plus three marker constants that are substrings of the exact
  text we write:
  - `SPRINT_README_MARKER='managed by [sprint.md]'`
  - `SPRINT_AI_MARKER='single source of truth for how this project is organized'`
  - `SPRINT_GITIGNORE_MARKER='# === sprint.md Recommended Entries ==='`
  - `already_ours MARKER CONTENT` — fixed-string (glob, not regex) membership
    test; pure, no file I/O.
  - `gitignore_merge RECOMMENDED EXISTING` — the section-flush per-line dedup
    logic, now a pure function of two string args (was inline, reading the
    file directly). Empty output = nothing new. Separable from the `read -r`
    prompt flow.
- **`.gitignore` (criterion #1/#2):** deleted the fragile
  `grep -q "sprint.md"` early-out. The else-branch now calls `gitignore_merge`
  and keys "already installed" off its empty result — so an incidental
  `sprint.md` mention no longer causes a false skip, and re-runs stay
  idempotent. The prepend branch's temp-file + `mv` atomic write and the
  header text are preserved (header now emitted via `SPRINT_GITIGNORE_MARKER`).
- **README gate (criterion #3):** `grep -q "DOCUMENTATION.md"` →
  `already_ours "$SPRINT_README_MARKER" ...`.
- **AI-pointer gate (criterion #3):** `grep -q "DOCUMENTATION.md"` →
  `already_ours "$SPRINT_AI_MARKER" ...` in `setup_ai_file`.

**Audit result (criterion #3):** the two `DOCUMENTATION.md` substring gates
were the only remaining offenders. Install-state detection (file-existence
checks) and config writes (anchored `^key=` matches) were re-confirmed robust
and left unchanged. `grep -c 'grep -q "DOCUMENTATION.md"|grep -q "sprint.md"'`
now returns zero.

**Non-destructiveness (criterion #4):** verified every pre-existing-file write
path (README prepend, `setup_ai_file` prepend, `.gitignore` prepend) still
builds a `mktemp` temp file and `mv -f`s it into place — prepend/append only,
existing content preserved verbatim. Not regressed by the refactor.

**Tests (criterion #6):** new `docs/tests/test-setup-detection.sh` extracts the
fenced helper block from `setup.sh` verbatim and sources it, so it exercises
the shipped logic without running the interactive installer. 16 assertions
cover: our markers match / incidental `sprint.md` and `DOCUMENTATION.md`
mentions do NOT match (the old false-positive), literal-glob-char safety, fresh
install, idempotent re-run, an existing `.gitignore` that incidentally contains
`sprint.md`, partial overlap with orphan-header suppression, and
differently-phrased (non-deduped) entries. All pass.

**Verification:** `bash -n setup.sh` and `shellcheck -S warning` both clean;
new test suite green; an end-to-end smoke test of the `.gitignore` merge path
confirmed entries are added despite an incidental `sprint.md` line, existing
content is preserved below the marker, and a second run adds nothing.

Note: line numbers cited in the task body had drifted; changes were located by
grepping the patterns as advised.

### Files changed

setup.sh
docs/tests/test-setup-detection.sh

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
