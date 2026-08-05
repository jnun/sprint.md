Clear scratch files from docs/tmp/.

Usage:
  ./sprint.sh cleanup              # dry run — show what would be cleaned
  ./sprint.sh cleanup --delete     # delete stale files (with confirmation)
  ./sprint.sh cleanup --force      # delete stale files (no confirmation)
  ./sprint.sh cleanup --all        # delete everything (with confirmation)

--force is --delete without the interactive prompt — for scripts and CI
where no one is at the keyboard to answer y/N.
