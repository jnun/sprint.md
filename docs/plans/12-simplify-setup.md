# Plan 12: Simplify setup

**Created**: 2026-07-30
**Status:** STARTED

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Plan Think

Critique in `docs/tmp/plan-think.md` (2 members annotated in their task files).
Top 3 findings:

1. **Strong plan, no restructuring needed.** Two members, correctly ordered
   (decide → implement), clean dependency. The ownership marker makes backend
   reliability and user trust the *same* mechanism, not competing ones.
2. **#306 needs a resync, then advance (still in `backlog/`).** It was
   decision-complete, but finding #4 re-scoped its Install-shape to the binary
   overwrite-or-prepend model — so resync #306 via `chat backlog` first, then
   check its boxes and move it to `next/`. The plan's live work is #307.
3. **#307 needs two added criteria:** make the silent batch's outcomes visible
   (one line per action, halt loudly on error — "silent" = no questions, not no
   output), and treat idempotent re-run as the must-pass acceptance test.
4. **Conflict handling simplified to a binary prompt (supersedes the three-way
   override).** When a file exists but isn't provably ours, setup asks
   **overwrite or prepend** (Enter = prepend) on *any* path — not a three-way
   Replace/Leave-alone/Prepend behind More options. The marker's only job is the
   ours-vs-theirs call that routes a file to silent-upgrade vs the prompt; it no
   longer needs block-scoped overwrite authority. `More options?` now carries
   only GitHub Issues sync + Add all AI instructions. **This re-scopes #306's
   locked Install-shape spec and #307's criteria** — both must be resynced via
   `chat backlog` (recorded intelligence; the task edits are not made here).

## Goal

Collapse SprintBias's install into an **Easy Button**: two doors (`[Enter]` Claude,
`[g]` Grok) running one identical scaffold batch that asks nothing for files that are
missing or provably ours — creating or upgrading them without a prompt — and asks a
single **overwrite-or-prepend** question (Enter = prepend) only when a file exists
that it can't prove is ours. GitHub Issues sync and extra AI dotfiles stay behind a
`More options?` gate. This kills a first-run experience that today asks too many
AI-file questions in the wrong order — a cleaner front door that respects the user's
own files (upgrade ours, ask before touching theirs, never blind-clobber).

## Why

The installer is the first thing every user touches; a noisy, over-asking first run
is where adoption leaks. #306 locks the decision record; #307 rewires `setup.sh`.

## Member tasks

<!-- The tasks in this plan, by ID only — one "- #ID — short title" line each
     (checkboxes optional; [x] means the task is in docs/tasks/done/). These are
     references, not paths: resolve each ID against docs/tasks/*/ for location.
     Moving a member needs no edit here unless syncing checkboxes. -->

- #306 — Decide setup install AI defaults: Claude/Grok only, silent CLAUDE.md, no extra AI dotfiles
- #307 — Rewire setup.sh into the two-door Easy Button install (Claude/Grok, silent scaffold batch, more-options gate)
