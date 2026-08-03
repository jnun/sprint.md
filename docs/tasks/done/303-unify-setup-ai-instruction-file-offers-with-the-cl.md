# Task 303: Unify setup AI instruction file offers with the CLI picker

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 306
**Blocks**: 304
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Cancelled — absorbed into #307 (decided in #306, 2026-07-30)

The Easy Button decided in task 306 makes the default install path ask **no**
AI-file offers at all — they're silent. There is nothing left to reorder after
the CLI pick. This task's intent is folded into the single implement task #307.
Retained below for reference only.

## Problem

During `setup.sh`, AI instruction files are offered **before** the user picks
their AI CLI. Fresh installs show a multi-select menu (Cursor, Agents.md,
Windsurf, …) while the user still has no reason to choose among tools. Later,
after the CLI picker, setup asks again for the matching provider file if it is
still missing. Installers get two decision points for one concern, and the
first one is uninformed.

Given a fresh or partial install, when setup configures AI support, the user
should choose their CLI once and get a single, relevant instruction-file offer
tied to that choice.

## Success criteria

- [ ] AI instruction-file create prompts run **after** the AI CLI / provider is
      selected (existing files that already reference DOCUMENTATION.md still
      get silent prepend/skip handling without a menu)
- [ ] The primary offer is the instruction file that matches the chosen
      provider (e.g. Claude → `CLAUDE.md`, Cursor → `.cursorrules`; Grok keeps
      the current "no extra invented file" rule and may offer `CLAUDE.md` /
      `AGENTS.md` only if product policy already allows it)
- [ ] Setup does not ask twice for the same missing file (early menu + later
      provider-specific prompt collapse into one path)
- [ ] Fresh install still never overwrites user-owned instruction files
      (prepend-or-create, never clobber)

## Notes

- Today the early menu lives around the `PENDING_PREPEND` / `MENU_ENTRIES`
  block; the second offer is the post-CLI `PROVIDER_AI_FILE` block. Fold them.
- Defer existing-file handling (silent prepend when our marker is missing) can
  stay where it is or move with the create path — either is fine as long as
  interactive **create** waits on CLI choice.
- Task 304 covers how residual multi-tool offers look if we keep any; this
  task is the reorder + single primary offer.

## References

setup.sh
src/CLAUDE.md
src/AGENTS.md
src/.cursorrules
src/.windsurfrules
src/.github/copilot-instructions.md
