# Dependency glitch matrix fixture

Synthetic task board that exercises **every dependency / work-completion
failure mode** we care about for Plan 15 (dependency integrity).

| File | Role |
|------|------|
| [MATRIX.md](./MATRIX.md) | Full case catalog + expected behavior |
| [seed.sh](./seed.sh) | Materializes `board/` (safe to re-run) |
| [check-inventory.sh](./check-inventory.sh) | Classifies canaries with current `lib.sh` |
| [board/](./board/) | Committed snapshot (regenerate with seed) |

IDs are **9000–9099** so this never collides with real product tasks.

## Quick start

```bash
# From repo root:
bash docs/tests/fixtures/dep-glitch-matrix/seed.sh
bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh

# Or into a disposable project tree:
bash docs/tests/fixtures/dep-glitch-matrix/seed.sh /tmp/dep-glitch
bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh /tmp/dep-glitch
```

## What “robust” covers

- Depends on met / unmet across **all lifecycle stages**
- **doing/** orphans: ## Completed, incomplete, hard-fail, crash
- **backlog/** never lifted and **pushed back** with dependents still in next/
- **blocked/** decision vs incomplete Outcome stamps
- **Fold / replace / chat-remove** (tombstone + pure missing)
- **Split** with parent deleted; children in next + backlog
- One-way edges, **cycles**, self-deps, malformed tokens, hash ids, ranges
- Mixed multi-deps, chains, diamonds
- **Plan** field drift (listed vs field vs missing plan)
- Umbrella canary **#9080** depending on many classes at once

## Not for

- Running `./sprint.sh work` against the **live** repo using these IDs
  (they only exist under `board/` unless you seed elsewhere).
- Claiming current product code already implements every MATRIX Expected cell.

## Plan 15 link

This fixture is the reference dataset for tasks **#328–#332**. When helpers
and `work` grow, add hard asserts in `docs/tests/test-dep-glitch-matrix.sh`
(not required for the fixture itself).
