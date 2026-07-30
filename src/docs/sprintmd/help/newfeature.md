Create a new feature document in docs/features/.

Usage:
  ./sprint.sh newfeature                       # AI-guided Q&A
  ./sprint.sh newfeature "User authentication" # quick template
  ./sprint.sh -g newfeature                    # AI Q&A via Grok Build this run
  ./sprint.sh -c newfeature                    # AI Q&A via Claude Code this run

Without a name, starts a live interactive session that asks about users,
requirements, and success criteria, then writes a complete spec (same
interactive contract as chat / newidea). With a name, creates a blank template
you fill in yourself. Leading `-g` / `-c` pick the AI provider for the Q&A path
only (they do not rewrite config).
