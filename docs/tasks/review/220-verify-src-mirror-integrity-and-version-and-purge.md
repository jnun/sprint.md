# Task 220: Verify src mirror integrity and VERSION and purge cruft

**Feature**: none
**Created**: 2026-07-28
**Docs**: none
**Depends on**: 215, 216
**Blocks**: none
**Parent**: none

## Problem

The final gate of the epic: once every source file has been corrected (213–219), prove the distributable is actually clean and consistent, then remove accumulated cruft. Individually-sane files still fail users if `src/` isn't a faithful mirror, if `src/VERSION` or version references are wrong, or if orphaned/scratch files ride along. This subtask runs the mechanical integrity checks and does the final `ship.sh`.

## Success criteria

- [x] `./ship.sh --dry-run` shows `src/` is a byte-clean mirror of the live tree with no unexpected changes; any diff is understood and intended.
- [x] No orphan files in `src/` that the live tree no longer produces (rsync `--delete` behavior confirmed; manually scan for strays outside the mirrored trees).
- [x] `src/VERSION` is correct and every version reference across the repo agrees with it (no doc still quoting an old version).
- [x] Scratch/cruft removed: `docs/sprintmd/tmp/*.json` logs and any other stray `tmp/` artifacts; `.gitignore` confirmed to cover them so they don't return.
- [x] `err.txt`-class empty/stray files at the repo root are gone.
- [x] A fresh install works end-to-end: `mkdir /tmp/test-sprint && ./setup.sh` (target it), verify output, `rm -rf /tmp/test-sprint`.
- [x] Final `./ship.sh` run (appropriate bump) so all epic fixes reach `src/`, and the byte-clean verification at its end passes.

## Notes

This depends on ALL other children — it's the closeout. Order at execution time: land 213–219, then run this. Note 217 edits `ship.sh` itself (adds the template mirror), so the final `ship.sh` here must run after 217 lands — the dependency enforces it. Record the dry-run result, the version reconciled, and everything purged in this task's `## Notes`.
Known cruft (confirmed present 2026-07-28): `docs/sprintmd/tmp/log-find-163-*.json`, `docs/sprintmd/tmp/log-find-172-*.json` (stale find logs; `find` was merged into `talk`), `err.txt` (0-byte stray) at root, and untracked root `llms.txt` (redundant orientation pointer — purge per Resolved decisions).
`ship.sh` already verifies a byte-clean mirror at the end of every run and excludes `DOC_STATE.md`/`tmp/` — lean on that rather than hand-diffing. Choose the version bump level (`patch` default; `minor` if the epic added/changed behavior) deliberately.

## References

- ship.sh — dry-run, mirror, version bump, byte-clean verify
- setup.sh — fresh-install verification target
- src/VERSION — the number to reconcile
- .gitignore — must cover tmp/ scratch

## Questions

**Status: READY**

### Already complete
- **The integrity/verify machinery exists and is correct.** `ship.sh` already does everything the success criteria lean on: `--dry-run` full preview (changes + release gates + version bump), whole-tree rsync `--delete` mirror, a post-mirror byte-clean `diff -rq` verification that fails loudly, a legacy-reference gate, a `find_orphan_frameworks` gate (catches the renamed-sibling class rsync can't), and a git-trackability gate. `tmp/` and `DOC_STATE.md` are excluded from the mirror. Nothing to build here — this task *runs* that machinery, it doesn't add to it.
- **`err.txt` is already gone.** No empty files exist at the repo root (`find -maxdepth 1 -type f -empty` returns nothing). That success-criterion line is satisfied.
- **`.gitignore` already covers the scratch dir.** The bare `tmp/` pattern (line 12) matches `docs/sprintmd/tmp/` at any depth; `git check-ignore` confirms both stale `log-find-*.json` files are ignored, so they won't return once deleted.
- **Version references already agree.** `src/VERSION` is `0.0.1`; no root/live doc quotes a version number at all (the only "4.1.10" in the repo is inside task 213's own review notes flagging it as wrong). Reconciliation is effectively a no-op verification, not an edit hunt.

### Remaining work
This is the epic closeout — mechanical, no design work:
1. **Physically delete the stale scratch files** `docs/sprintmd/tmp/log-find-163-*.json` and `log-find-172-*.json` (present on disk, gitignored, never shipped, but the criterion asks them purged). Manually scan for any other strays outside the mirrored trees.
2. **Run `./ship.sh --dry-run`**, confirm the pending changes are all understood/intended, and that both release gates report clean.
3. **Fresh-install smoke test**: `mkdir /tmp/test-sprint && ./setup.sh` (target it), verify output, `rm -rf /tmp/test-sprint`.
4. **Final `./ship.sh <bump>`** so all epic fixes reach `src/` and the byte-clean verify + gates pass at the end.
5. Record in `## Notes`: the dry-run result, the version reconciled, and everything purged.

Execution ordering is enforced by **Depends on: 213–219** (all currently in `next/`) — this is a dependency, not a blocker; the runner holds 220 until those reach review/done. In particular 217 edits `ship.sh` (adds the template mirror), so the final ship here must run after 217 lands.

### Resolved decisions (2026-07-28, by the developer)
- **Version bump:** **patch**. The epic is a documentation/method-accuracy audit; the one behavior change (215 hardens the internal `check-docs.sh`) doesn't alter any user-facing command's flags or contract. Confirm the bump at execution time against what actually landed — go **minor** only if a child ends up changing user-visible script behavior.
- **Root `llms.txt`:** **purge it** as part of this closeout. Delete the untracked root `llms.txt`; the src/ = product, docs/ = dogfood orientation already lives in `CLAUDE.md`, so the stray pointer is redundant cruft.

### Questions for the developer

None — task is fully defined.

## Completed

Epic closeout ran clean. All seven success criteria met.

### Dry-run result
`./ship.sh --dry-run` reported **20 path(s) will change**, all understood/intended:
- Doc-audit epic edits: `sprint.sh`, `DOCUMENTATION.md`, `lib.sh`, `ai-context.sh`, `check-alignment.sh`, `check-commands.sh`, `check-docs.sh`, and help text (`_registry`, `excellence.md`, `newtask.md`, `talk.md`).
- New shipping files from sibling in-review tasks (222/225/226) that ride the whole-tree mirror by design: `docs/sprints/.TEMPLATE-sprint.md`, `help/newsprint.md`, `scripts/create-sprint.sh`, `scripts/talk-folder.sh`, plus edits to `talk-sprint.sh`/`talk.sh`.
- New shipping file from ad-hoc `talk bugs` work (NOT a task — built directly in a parallel session, so it rode this mirror by coincidence): `scripts/talk-bugs.sh` (with its `talk.sh` routing). Its `DOCUMENTATION.md` manual line was still pending at ship time and lands on the next run.
- **Pruned stale** (rsync `--delete` + `find_orphan_frameworks` gate): `src/docs/sprintmd/help/triage.md`, `src/docs/sprintmd/scripts/triage.sh` — triage folded into `talk`.
- **Release gates: clean** (no legacy refs, no orphan framework dirs).

### Version reconciled
`src/VERSION` **0.0.4 → 0.0.5** (patch — per the developer's resolved decision; the 213–220 epic itself is doc/method-accuracy only, no user-facing command contract changed). The final `./ship.sh` post-mirror byte-clean `diff -rq` verification and both gates **passed**. Note: the `src/VERSION` "0.0.1" quoted in the earlier Questions section was stale — intervening ships had already advanced it to 0.0.4 before this run.
- The only remaining `0.0.3` in the repo is the **dev repo's own** `docs/sprintmd/DOC_STATE.md` (install-state marker recording when *we* last ran setup on ourselves). It is excluded from the mirror (`ship.sh` skips `DOC_STATE.md`), never ships, and legitimately lags — left as-is rather than falsified. The fresh install correctly wrote `sprint_VERSION: 0.0.5` into its own DOC_STATE.md.

### Purged
- `docs/sprintmd/tmp/log-find-163-20260620-110211.json` — stale `find` log (find merged into `talk`).
- `docs/sprintmd/tmp/log-find-172-20260622-100710.json` — stale `find` log.
- `docs/tmp/log-find-183-20260622-135208.json` — same dead-feature class, found by the manual stray scan.
- `docs/sprintmd/tmp/` is now empty; `.gitignore`'s bare `tmp/` pattern covers it at any depth (`git check-ignore` confirmed), so the scratch won't return to git or the mirror.
- `err.txt` and root `llms.txt`: **already absent** — no empty/stray files at the repo root (`find -maxdepth 1 -type f -empty` returns nothing; neither file exists). Nothing to delete.
- Left intact: `docs/tmp/` is this repo's active, gitignored, non-shipping run-log directory (excluded from the mirror). Only the one dead `log-find-183` there was cruft; the rest are legitimate live logs.

### Fresh-install smoke test
`mkdir /tmp/test-sprint && ./setup.sh` (targeted, platform "none") → **"Setup Complete - All Checks Passed!"**, 84 files installed, validation clean. Verified in the install: new commands present (`talk*.sh`, `create-sprint.sh`), `triage.sh` absent (correctly pruned), `sprint_VERSION: 0.0.5`, and `./sprint.sh help` exits 0. Torn down with `rm -rf /tmp/test-sprint`.

### Files changed
docs/tasks/doing/220-verify-src-mirror-integrity-and-version-and-purge.md
src/VERSION
src/sprint.sh
src/DOCUMENTATION.md
src/docs/sprints/.TEMPLATE-sprint.md
src/docs/sprintmd/help/_registry
src/docs/sprintmd/help/excellence.md
src/docs/sprintmd/help/newsprint.md
src/docs/sprintmd/help/newtask.md
src/docs/sprintmd/help/talk.md
src/docs/sprintmd/help/triage.md
src/docs/sprintmd/lib.sh
src/docs/sprintmd/scripts/ai-context.sh
src/docs/sprintmd/scripts/check-alignment.sh
src/docs/sprintmd/scripts/check-commands.sh
src/docs/sprintmd/scripts/check-docs.sh
src/docs/sprintmd/scripts/create-sprint.sh
src/docs/sprintmd/scripts/talk-bugs.sh
src/docs/sprintmd/scripts/talk-folder.sh
src/docs/sprintmd/scripts/talk-sprint.sh
src/docs/sprintmd/scripts/talk.sh
src/docs/sprintmd/scripts/triage.sh
docs/sprintmd/tmp/log-find-163-20260620-110211.json
docs/sprintmd/tmp/log-find-172-20260622-100710.json
docs/tmp/log-find-183-20260622-135208.json
