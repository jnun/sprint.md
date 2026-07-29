# Contributing to sprint.md

## Quick start

```bash
git clone <repo-url> && cd sprint.md
```

No build step. The project is shell scripts and markdown.

## Development workflow

1. **Edit in `docs/`** — this is the live environment. Changes take effect immediately.
2. **Test your changes** — run `./sprint.sh` commands to verify behavior.
3. **Mirror to `src/`** — run `./ship.sh` (preview first with `./ship.sh --dry-run`). It rsyncs the live tree into `src/` and bumps the version. Never hand-copy files into `src/`.
4. **Verify install** — run `./setup.sh` against a temp directory (see below).
5. **Commit.**

### The two trees

- **`docs/`** is where you develop. Scripts run from here. Edit here first.
- **`src/`** is the distribution package — what `setup.sh` installs into user projects. Never edit here first; `./ship.sh` mirrors `docs/` → `src/` after testing.

See [LIFECYCLE.md](LIFECYCLE.md) for the full file flow.

### Verify a fresh install

```bash
mkdir /tmp/test-sprint && ./setup.sh
# enter /tmp/test-sprint when prompted, verify output, then:
rm -rf /tmp/test-sprint
```

If this breaks, it's a release blocker.

## What goes where

| I want to change... | Edit here | Reaches `src/` via |
|---|---|---|
| A script | `docs/sprintmd/scripts/` | `./ship.sh` |
| AI guidance | `docs/sprintmd/ai/` | `./ship.sh` |
| CLI help text / command guides | `docs/sprintmd/{help,cli,guides}/` | `./ship.sh` |
| The user manual | `DOCUMENTATION.md` (root) | `./ship.sh` |
| A template | `docs/{tasks,bugs,features,ideas,tests}/.TEMPLATE-*` | `./ship.sh` (its `TEMPLATE_FILES` list mirrors each to `src/docs/…`) |
| The installer | `setup.sh` (root) | — (only one copy, not mirrored) |
| The ship tool | `ship.sh` (root) | — (dev-only, never ships) |
| GitHub issue/PR templates, workflows | `src/.github/` | — (edit `src/` directly; no `docs/` copy) |
| AI pointer files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, …) | `src/CLAUDE.md`, `src/AGENTS.md`, … | — (edit `src/` directly; no `docs/` copy) |

Anything under `docs/sprintmd/` is mirrored wholesale, so a brand-new script, help, or guide file ships automatically — no `ship.sh` edit needed.

The `src/` AI pointer files are deliberately minimal (a few lines pointing at `DOCUMENTATION.md`). The installer prepends them to a user's existing AI instruction file, so keep them short — don't enrich or templatize them.

## Tracking work

This repo uses sprint.md to manage itself. Use `./sprint.sh` commands to create tasks, bugs, and ideas — never create those files manually.

## Questions

Read `DOCUMENTATION.md` for how the system works end-to-end.
