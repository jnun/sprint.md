# Task 304: Replace the multi-select AI instruction file menu with a simpler offer

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 303
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Cancelled — absorbed into #307 (decided in #306, 2026-07-30)

The Easy Button decided in task 306 collapses the multi-select menu into a
single `Add all AI instructions? [y/N]` behind an opt-in "More options?" gate —
which is exactly this task's intended outcome. Folded into the single implement
task #307. Retained below for reference only.

## Problem

When several AI instruction files are still missing, setup prints a numbered
multi-select:

```
Which AI instruction files would you like to create?

  1) Cursor  (.cursorrules)
  2) Agents.md (multi-agent)  (AGENTS.md)
  3) Windsurf  (.windsurfrules)

  A) All of the above

Enter choices (e.g. 1 3, or A for all, Enter to skip):
```

That is heavy for an installer. Most people use one tool. Parsing "1 3 or A"
is easy to get wrong, and the menu appears before (or without) a clear default
path. After task 303 ties the primary offer to the chosen CLI, any remaining
"also other tools?" path should feel optional and light — not a second product
configuration screen.

## Success criteria

- [ ] The default install path is one yes/no (or Enter-to-accept) for the
      provider-matched instruction file from task 303 — no multi-select required
- [ ] If the user may want extra instruction files for other tools, that path
      is clearly secondary (e.g. "Also set up files for other AI tools?
      [y/N]") and uses simple yes/no or single-pick interaction, not
      space-separated multi-index entry as the main UX
- [ ] Skipping extras is one keystroke (Enter or N) and prints a clear skip line
- [ ] Labels name the product once without stacking redundant parentheticals
      (e.g. "Cursor (.cursorrules)" or just "Cursor", not
      "Agents.md (multi-agent)  (AGENTS.md)")

## Notes

- Prefer positive defaults: offer the matching file with Yes as default; treat
  "all other tools" as opt-in, not the headline.
- If product decision is "only ever offer the matched provider file," deleting
  the residual multi-tool path entirely is an acceptable elegant outcome —
  document that choice in Notes/Completed when done.
- Keep `setup_ai_file` / prepend-never-clobber behavior; this task is
  interaction shape, not install semantics.

## References

setup.sh
