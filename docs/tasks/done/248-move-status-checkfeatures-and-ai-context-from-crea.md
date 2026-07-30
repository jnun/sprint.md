# Task 248: move status checkfeatures and ai-context from Create to Inspect

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: none
**Blocks**: none
**Parent**: none

## Problem

`status`, `checkfeatures`, and `ai-context` are read-only commands — they
surface state and mutate nothing — but they are filed in the `create` group in
`_registry` (and dispatched among the creators). The matrix's target is a
`create` group that is exactly the `new*` scaffolds, with these three relocated
to an **Inspect** grouping alongside `search`. Relocate them so the registry
group reflects what they actually do.

## Success criteria

- [x] `status`, `checkfeatures`, and `ai-context` are removed from the `create`
      group in `_registry` so `create` is exactly the `new*` scaffolds, and are
      placed in a new `inspect` registry group. The `search` row moves there too
      (from `workflow`), so Inspect = {status, checkfeatures, ai-context, search}.
- [x] The help index renders the new group: `cmd_help` in `sprint.sh` builds the
      index from a **hardcoded** group list (`print_command_group create /
      pipeline / workflow / sync / maint`, ~lines 88–100) — add a
      `print_command_group inspect` call with an "Inspect:" header, or the three
      commands silently vanish from `./sprint.sh help` while `validate --commands`
      still passes (it checks command rows, not group rendering). Confirm
      `./sprint.sh help` lists all four under Inspect.
- [x] The `_registry` allowed-groups header comment (line 11, "group is one of:
      create | pipeline | workflow | sync | maint") gains `inspect`, so the
      registry does not document a group its own header forbids.
- [x] Their dispatch and behavior are unchanged — this is a classification/
      registry move, not a rewrite; `./sprint.sh status`, `checkfeatures`, and
      `ai-context` still work exactly as before.
- [x] `./sprint.sh validate --commands` passes (all four surfaces still agree);
      `./ship.sh --dry-run` clean; a fresh `./setup.sh` install shows the three
      under Inspect in the help index.

## Notes

- Read-only, no mutation → Inspect (matrix Placement Rules). `search` is already
  Inspect-natured; group the four together.
- The **verb-rename** for these three (they read as nouns — matrix Open
  Questions) is deliberately **out of scope**: names aren't chosen yet, so this
  task only relocates the group. Renaming is a separate decision/task.
- If `_registry` has no `inspect` group today, add one — groups are display
  buckets and the four-surface validator keys off the command rows, not the
  group name. Reconciling *all* registry groups to the five matrix families
  (Converse/Compose/Process/Inspect/Maintain) is a broader follow-up, not this
  task.
- Standard dogfood: edit `docs/`, test in place, `./ship.sh`; git left to the
  user.

## References

docs/guides/command-matrix.md
docs/sprintmd/help/_registry
sprint.sh
docs/sprintmd/scripts/check-commands.sh
docs/sprintmd/help/status.md
docs/sprintmd/help/checkfeatures.md
docs/sprintmd/help/ai-context.md
DOCUMENTATION.md

## Completed

Relocated `status`, `checkfeatures`, `ai-context`, and `search` into a new
`inspect` registry group. Create is now exactly the `new*` scaffolds. Help
index and DOCUMENTATION.md Commands block gained an Inspect section. Behavior
unchanged; validated with `validate --commands`, fresh setup install, and
shipped as v0.0.18.

### Files changed
docs/sprintmd/help/_registry
sprint.sh
DOCUMENTATION.md
src/docs/sprintmd/help/_registry
src/sprint.sh
src/DOCUMENTATION.md
src/VERSION
docs/plans/2-command-matrix-redesign.md

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
