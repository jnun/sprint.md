# Typing `sprint` instead of `./sprint.sh`

Every command in this guide runs the project's CLI as `./sprint.sh <command>`.
That leading `./` gets old fast. This guide shows how to type just
`sprint <command>` instead.

## The one-line fix: an alias

Add this line to your shell's startup file:

```bash
alias sprint='./sprint.sh'
```

- **zsh** (the macOS default) → `~/.zshrc`
- **bash** → `~/.bashrc` (or `~/.bash_profile`)

Then reload your shell:

```bash
source ~/.zshrc     # or: source ~/.bashrc
```

Now, from a project root, `sprint chat 214` runs `./sprint.sh chat 214`.

`setup.sh` offers to add this alias for you at the end of a fresh install — this
guide is here if you skipped it, want to do it by hand, or need to understand
what it does.

## Why the alias is *relative* on purpose

The alias points at `./sprint.sh`, not an absolute path. That is deliberate and
important:

**sprint.md is a file-based tool, not a system app.** Each project carries its
own copy of `sprint.sh` at its own version. A relative alias always runs the
`sprint.sh` of whichever project you are standing in — so one alias works
correctly across every project you have, and never runs a stale or mismatched
version. There is nothing global to keep in sync.

The trade-off: because it is relative, the alias only works from a project's
**root directory** (where `sprint.sh` lives). `cd` into the project first, then
use `sprint`.

## Bonus: make it work from any subdirectory

If you often work deep inside a project and want `sprint` to work from
subfolders too, use a small shell **function** instead of the alias. It walks up
from your current directory to find the nearest `sprint.sh` and runs that one:

```bash
# add to ~/.zshrc or ~/.bashrc instead of the alias
sprint() {
  local d="$PWD"
  while [ "$d" != / ]; do
    if [ -x "$d/sprint.sh" ]; then
      ( cd "$d" && ./sprint.sh "$@" )
      return
    fi
    d="$(dirname "$d")"
  done
  echo "sprint.md not found from $PWD" >&2
  return 1
}
```

This keeps the same file-based, version-safe behavior — it just finds the
project root for you, so `sprint help` works whether you are in the root or five
folders deep.

## Prefer not to touch your shell config?

Then keep typing `./sprint.sh`. Nothing about sprint.md requires the shortcut —
it is pure convenience, and sprint.md never installs anything outside the
project folder unless you ask it to.
