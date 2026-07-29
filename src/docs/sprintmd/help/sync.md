Push task changes to GitHub.

Commits and pushes task file changes to main, which triggers
the GitHub Actions workflow that creates/updates issues.

Usage:
  ./sprint.sh sync            # sync changed task files
  ./sprint.sh sync --all      # sync all task files (needs the gh CLI)

Requirements:
  - A git repository on the main branch
  - An 'origin' remote to push to
  - The gh CLI (github.com/cli/cli) for --all only

--all is checked for gh up front: if gh is missing the run stops before
committing, so it never half-succeeds (push done, resync not triggered).

Exit codes:
  0   success, or nothing to sync
  1   environment not ready — not a git repo, not on main, no 'origin'
      remote, or --all requested without the gh CLI. Each error names
      the command that fixes it.
