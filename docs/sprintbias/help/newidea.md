Create a new idea and refine it through eight phases.

Usage:
  ./sprint.sh newidea "Dark mode support"   # Create from template (fast)
  ./sprint.sh newidea                       # AI-assisted refinement session
  ./sprint.sh -g newidea                    # AI Q&A via Grok Build this run
  ./sprint.sh -c newidea                    # AI Q&A via Claude Code this run

With a name: creates the idea file from template immediately.
Without a name: starts an interactive AI session that guides you
through all eight phases (Spark → Problem → Landscape → Brainstorm →
Bet → Stress Test → Scope → Handoff) and creates the file at the end.
Leading `-g` / `-c` pick the AI provider for the Q&A path only (they do not
rewrite config).
