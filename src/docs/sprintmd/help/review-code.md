Fixer/verifier code quality audit for completed tasks.

Runs an iterative audit loop with two modes:
  - FIXER: full tools, can read and edit code, fixes issues
  - VERIFIER: read-only tools, confirms fixes are correct

The fixer/verifier pattern prevents self-grading bias — the code
that fixes issues is never the same context that judges them.

Context modes (how the audit knows what changed):
  1. MANIFEST FILE — tasks writes a manifest listing changed files
  2. TASK FILE — parses the ## Completed section for changed files
  3. EXPLICIT FILE LIST — pass file paths directly

The auditor also traces the impact graph — what other code imports,
calls, or references the changed files — to check for regressions.

Usage:
  ./sprint.sh review-code <task-file> [max-passes]
  ./sprint.sh review-code <file1> <file2> ... [-- max-passes]

The audit never blocks task promotion — it fixes what it can,
documents what it cannot, and exits 0 (clean) or 1 (warnings).

review-code answers "is it correct?" For "is it well-engineered and does
it fully solve the problem?", run the excellence pass after it passes:
  ./sprint.sh excellence <task-file>     (see: help excellence)
