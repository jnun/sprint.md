Excellence audit — judges finished work against a higher bar than "it runs."

Where review-code checks correctness (does it work, is it safe, does it
follow conventions), excellence checks engineering quality:

  - EFFECTIVENESS  Does it fully solve the stated problem, end to end?
  - EFFICIENCY     Wasted work, patterns fighting the access pattern
  - DESIGN FIT     Extends the architecture, or bolts onto it?
  - OPERABILITY    Can it be observed, debugged, administered?
  - ROBUSTNESS     Realistic edges: empty input, concurrency, retry

The auditor traces the end-to-end usage path — the highest-value findings
are capabilities that exist but cannot actually be invoked.

The excellence pass NEVER edits code. Improvements are filed as backlog
tasks (via newtask) with rationale, so bar-raising flows through the task
pipeline instead of becoming mid-audit scope creep. Protocol:
docs/sprintmd/ai/audit-excellence.md

Run it after review-code passes, on a task in review/ or done/.

Usage:
  ./sprint.sh excellence <task-file>          # audit a task's changed files
  ./sprint.sh excellence <task-id>            # same, found by task ID (searches review/ first)
  ./sprint.sh excellence <file1> <file2> ...  # audit explicit files

Verdicts (last line of the report):
  EXCELLENT  — meets the bar, nothing filed            (exit 0)
  FILED      — N enhancement tasks filed to backlog/   (exit 0)
  BLOCKER    — work fails its own task's goal          (exit 1)

A '## Excellence' section (date, verdict, summary) is appended to the
task file for the record.
