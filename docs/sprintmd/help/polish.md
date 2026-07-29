Serialized excellence pass over review/ — reopens work worth improving.

Where `excellence` audits ONE task and files *separate* backlog tasks, `polish`
sweeps every finished task in review/, judges each in its OWN fresh context,
and — when a second execution pass would close a real, bounded gap — rewrites
that same task with concrete improvements and moves it back to next/. Running
./sprint.sh tasks then re-executes it.

This is the excellence bar wired into a redo loop, the same way `tasks` is the
execute step wired into a queue runner.

Each task is judged in a fresh context (a new subagent inside an AI session, or
a nested CLI call in a plain terminal) so a long review/ queue never blows one
context window — the same isolation `tasks` gives execution.

Verdicts (last line of each task's report):
  PASS     — meets the bar (or the gap fails the reopen test); stays in review/
  REOPEN   — a '## Refine (round N)' section is appended; task moves to next/
  BLOCKER  — work fails its own goal and needs a human; stays in review/

Round cap: a task carries one '## Refine (round N)' section per reopen. Once it
has been reopened --rounds times (default 1) it is capped and skipped, so a
task can never bounce between review/ and next/ forever. --force overrides the
cap for a one-off deeper pass.

Reopened tasks re-enter the normal pipeline: they keep their '**Status: READY**'
stamp, so `tasks` picks them up without a re-define. The reopen section's
improvements are unchecked '- [ ]' items — the new work for the next pass.

The refine pass NEVER edits product code. Its only write is the task file.
Protocol: docs/sprintmd/ai/refine.md

Usage:
  ./sprint.sh polish                 # judge all of review/, reopen what qualifies
  ./sprint.sh polish 3               # judge at most 3 tasks
  ./sprint.sh polish --rounds 2      # allow up to 2 reopens per task
  ./sprint.sh polish --force         # ignore the round cap this run
  ./sprint.sh polish --max           # no budget cap

Model selection uses docs/sprintmd/config (MODEL_POLISH, else MODEL_DEFAULT).
Set FIVEDAY_MODEL_POLISH in your environment to override per run.

Full loop:
  ./sprint.sh tasks                  # execute the sprint → review/
  ./sprint.sh polish                 # raise the bar; reopen what falls short
  ./sprint.sh tasks                  # re-execute the reopened tasks
