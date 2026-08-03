# Task 305: Polish setup prompt wording for GETSTARTED and AI instruction labels

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 306
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Cancelled — absorbed into #307 (decided in #306, 2026-07-30)

The Easy Button decided in task 306 makes GETSTARTED silent (no prompt to
polish) and introduces new copy ("More options?", "Add all AI instructions?",
the batch `✓ …` success lines) that #307 writes directly. The wording intent is
folded into the single implement task #307. Retained below for reference only.

## Problem

Several setup prompts read like internal filenames rather than human offers.
Examples from a real install:

- `Place the GETSTARTED.md in the project to help me get started? (yes/no)` —
  self-referential, uses the script's "me," and leads with a filename
- AI labels such as `Agents.md (multi-agent)` plus a second `(AGENTS.md)` in
  the menu line stack jargon
- Headers like `Setting up AI instruction files...` are fine, but the create
  questions should name the benefit in plain language (so the agent and the
  human both know what they are accepting)

Copy polish only — no change to which files ship or to prepend/create rules.

## Success criteria

- [ ] GETSTARTED offer reads as a short human question about a quickstart
      guide (filename may appear in parentheses or the success line, not as
      the main clause), with a clear yes/no default
- [ ] Every AI instruction create/skip line uses `_ai_label` (or equivalent)
      so product names stay consistent and free of double parentheticals
- [ ] Skip and success lines stay short and scannable (`Skipped …` /
      `Created …` / `already references DOCUMENTATION.md`)
- [ ] Wording matches project voice: plain language, positive instruction,
      no installer persona ("help me")

## Notes

- Safe to land independently of 303/304; if those reshape the menu, re-apply
  the same label rules there.
- Touch only user-visible strings in `setup.sh` (and any help/manual line that
  quotes the old GETSTARTED prompt if one exists).
- Example direction (not mandatory copy):
  - GETSTARTED: `Add a GETSTARTED.md quickstart at the project root? [y/N]`
  - Matched AI file: `Create a Cursor instruction file (.cursorrules) that
    points at DOCUMENTATION.md? [Y/n]`

## References

setup.sh
DOCUMENTATION.md
