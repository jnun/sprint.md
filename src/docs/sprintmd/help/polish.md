Post-work quality pass — three modes, one command.

`polish` is THE post-work quality surface. Three levers stay distinct inside
it; argument shape selects the mode:

  Sweep (bare)     polish [limit] [--rounds N]
                   Judge every finished task in review/. When a second
                   execution pass would close a real gap, rewrite that same
                   task with concrete improvements and reopen it to next/.
                   Protocol: docs/sprintmd/ai/refine.md

  Deep-judge       polish <file|task.md>
                   Judge ONE finished piece against a higher bar than "it
                   runs." Never edits product code — enhancements are filed
                   as backlog tasks via newtask. Protocol:
                   docs/sprintmd/ai/audit-excellence.md

  Code audit       polish --code <file|task.md> [passes]
                   Fixer/verifier loop over a finished task's code diff.
                   May fix issues inline. Answers "is it correct?"

A bare number is a sweep limit; a bare path is the deep judge; the same path
with `--code` is the code audit. `--rounds` / limit numbers stay sweep-only.

── Sweep ──────────────────────────────────────────────────────────────

Where deep-judge files *separate* backlog tasks, the sweep reopens the SAME
task for another pass. Each task is judged in a fresh context so a long
review/ queue never blows one context window.

Verdicts (last line of each task's report):
  PASS     — meets the bar; stays in review/
  REOPEN   — a '## Rework (round N)' section is appended; task moves to next/
             (git mv SRC DEST || mv SRC DEST)
  BLOCKER  — work fails its own goal and needs a human; stays in review/

Round cap: keyed on the '**Reworked**:' header counter, which ONLY polish
increments — one bump per confirmed reopen. Once a task's Reworked count
reaches --rounds (default 1) it is capped and skipped. The cap ignores '##
Refine'/'## Rework' headings in the body (a gate pass or hand edit can write
those), so polish never skips a task it has not actually judged; a missing
counter reads as 0. --force overrides the cap for a one-off deeper pass. The
refine pass NEVER edits product code — it appends the '## Rework' section and
the runner bumps the counter.

── Deep-judge ─────────────────────────────────────────────────────────

Judges engineering quality (effectiveness, efficiency, design fit,
operability, robustness) after correctness is presumed. Verdicts:
  EXCELLENT  — meets the bar, nothing filed            (exit 0)
  FILED      — N enhancement tasks filed to backlog/   (exit 0)
  BLOCKER    — work fails its own task's goal          (exit 1)

A '## Excellence' section (date, verdict, summary) is appended to the task
file for the record.

── Code audit ─────────────────────────────────────────────────────────

Runs an iterative fixer/verifier loop:
  - FIXER: full tools, can read and edit code, fixes issues
  - VERIFIER: read-only tools, confirms fixes are correct

Context modes (how the audit knows what changed):
  1. MANIFEST FILE — work writes a manifest listing changed files
  2. TASK FILE — parses the ## Completed section for changed files
  3. EXPLICIT FILE LIST — pass file paths directly

Exits 0 (clean) or 1 (warnings). A '## Audit' section is appended when a
task file is provided.

Usage:
  ./sprint.sh polish                 # sweep all of review/
  ./sprint.sh polish 3               # sweep at most 3 tasks
  ./sprint.sh polish --rounds 2      # allow up to 2 reopens per task
  ./sprint.sh polish --force         # ignore the round cap this run
  ./sprint.sh polish --max           # no budget cap
  ./sprint.sh polish <task.md>       # deep-judge one finished piece
  ./sprint.sh polish file1.py file2  # deep-judge explicit files
  ./sprint.sh polish --code <task.md> [max-passes]
  ./sprint.sh polish --code f1 f2 -- 3

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g polish              # Grok Build
  ./sprint.sh -c polish --code f.py  # Claude Code

Model selection uses docs/sprintmd/config (MODEL_POLISH / MODEL_EXCELLENCE /
MODEL_CODE_AUDIT, else MODEL_DEFAULT). Override per run with the matching
SPRINTMD_MODEL_* env var.

Full loop:
  ./sprint.sh work                   # execute the sprint → review/
  ./sprint.sh polish                 # raise the bar; reopen what falls short
  ./sprint.sh work                   # re-execute the reopened tasks
