# Plan 9: Command matrix live audit and dogfood

**Created**: 2026-07-30
**Status:** DONE

> A plan is a **relational index, not a container.** It groups related tasks by
> listing their IDs. The tasks never move into this file — each stays in its own
> lifecycle folder (`backlog → next → doing → …`) and its progress is tracked
> there. A plan is never itself a task; it only names a clump of work and its
> intent. `**Status:**` is binary — `DRAFT` while authoring, `READY` when safe
> for `plan start` / `loop --refill` to commit members into `next/`. Progress of
> the work itself derives from where member tasks live. To start this plan, run
> `./sprint.sh plan start <id>` (or move members `backlog/ → next/` by hand) —
> this file does not move.

## Goal

Prove the post–plan 8 command surface against `docs/guides/command-matrix.md`
**by using the live tool**, not by grepping alone. Run catalog audits, negative
tests for retired names, family-by-family smokes, spine-narrative checks, fix
any drift, and close with one throwaway create→chat→gate dogfood path.

When this plan is done, an agent can trust that matrix, `./sprint.sh help`,
registry, dispatch, and manuals tell the same story — and that the new verbs
actually run.

## Why

Plan 8 remapped talk/tasks/define/… in one cut. Self-hosting risk remains:
docs and CLI can drift silently. This sprint is the deliberate live proof that
closes that gap before plan 5 (Grok) or other product work trusts the surface.

## Invariants

1. **Matrix wins** when live disagrees — fix the CLI/docs up, never edit the
   matrix *down* unless the matrix itself is wrong (then file a separate task).
2. **Task noun stays** — `docs/tasks/`, `newtask`, lifecycle folders untouched.
3. **No runtime aliases** for retired commands.
4. **Edit `docs/` then `./ship.sh`** only if a fix is ship-worthy; pure audit
   findings without code change need no ship.
5. **Throwaway dogfood artifacts** created in #285 must be cleaned up
   (delete or mark done) so the board is not littered.

## Execution order

1. **#277** — Catalog audit (matrix ↔ help ↔ registry ↔ dispatch)
2. **#278** — Retired names negative tests
3. **#279** — Create-family smoke
4. **#280** — Look-family smoke
5. **#281** — Keep-family smoke
6. **#282** — Work-family help / off-spine labels
7. **#283** — Spine narrative across docs + help
8. **#284** — Fix drift + re-validate (depends on 277–283 findings)
9. **#285** — Live throwaway create→chat→gate dogfood

Prefer sequential. #279–#282 can run in parallel after #277 if no catalog
blockers. #284 waits for findings. #285 last (needs stable surface).

## Member tasks

- [x] #277 — Audit command matrix against live help registry and dispatch
- [x] #278 — Prove retired command names do not dispatch
- [x] #279 — Smoke create-family commands and confirm task noun paths
- [x] #280 — Smoke look-family status search align context
- [x] #281 — Smoke keep-family validate profile-show cleanup
- [x] #282 — Smoke work-family gate/work/loop help and off-spine labels
- [x] #283 — Exercise spine narrative chat → plan start → work → polish
- [x] #284 — Fix any matrix or surface drift found and re-validate
- [x] #285 — Live end-to-end dogfood one create-chat-gate path on a throwaway task

## Done when

- [x] Every matrix command is live (or documented intentional lag)
- [x] Every retired name fails dispatch with "Unknown command"
- [x] Family smokes green; validate --commands and --docs green
- [x] Spine language consistent; drift fixed or explicitly deferred
- [x] Throwaway dogfood path exercised and cleaned up
