Validate task files against the template format.

Usage:
  ./sprint.sh validate              # check all tasks, report issues
  ./sprint.sh validate --fix        # check and auto-fix tasks
  ./sprint.sh validate --fix --dry-run  # show what would be fixed
  ./sprint.sh validate --docs       # check help/*.md for flag drift vs scripts
  ./sprint.sh validate --commands   # check every command is fully surfaced

--docs compares the flags each command's script parses against the flags
its help/*.md documents, and reports either direction of drift. Run it after
touching any command's flags so the docs never fall out of sync. Exit 1 if
drift is found, 0 if clean.

--commands checks that every user-facing command is present across all four
catalog surfaces: the registry (docs/sprintmd/help/_registry, the source of
truth), the sprint.sh dispatch table, its help/<cmd>.md page, and the
DOCUMENTATION.md command list. It fails if a command is registered but not
dispatched (or vice versa), missing a help page, or absent from the manual —
so a new command can never be silently undiscoverable. The ./sprint.sh help
index is generated from the registry, so it never needs hand-syncing. Exit 1
on drift, 0 if clean.
