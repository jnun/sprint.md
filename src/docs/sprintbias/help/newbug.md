Report a new bug in docs/bugs/ (open inbox).

Usage:
  ./sprint.sh newbug "Login fails on Safari"

Fill severity, problem, steps, and success criteria. When ready to schedule
the fix, run `./sprint.sh chat bugs` and choose **[w] work it** — that converts
the report into a filled fix task and deletes the bug file. Clear fixes can
skip the inbox: `./sprint.sh newtask "Fix: …"`.
