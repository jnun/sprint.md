Decisive plan verbs — critique, commit, and retire. Authoring is `chat plan`.

**plan think [id]** — automated dual-persona critique of a plan (Platform
Architect + Experience Officer). Annotates each member with ## Plan Think and
writes plan-level analysis to docs/tmp/plan-think.md. Bare `plan think` picks
a plan.

**plan start [id] [--commit-only]** — gate, then commit that plan's members
into `next/` (the sprint). `next/` IS the sprint, so workability is decided
BEFORE a member enters it: each backlog member is run through the shared
workability gate (the same review `./sprint.sh gate` runs) while still in `backlog/`, and
only what grades READY is promoted. Location-aware:

  backlog/  → gate in place, then:
                READY   → stamp + move to next/
                BLOCKED → move to blocked/ (never visits next/)
                DONE    → move to review/
  next/     → leave (idempotent)
  blocked/  → stop; run chat <id>, then re-run plan start
  doing|review|done → skip with a notice
  missing   → hard error (dangling member)

A member already sitting in `blocked/` stops the start with a `chat <id>`
pointer — `blocked/` is human-triage territory, so the start does not silently
re-spend AI budget re-gating work someone already flagged. Resolve it
(`chat <id>`), re-queue it to `backlog/`, then re-run `plan start`.

`--commit-only` skips the gate and does the pure, deterministic `backlog → next`
move — for power users, tests, and non-AI environments. Members are NOT vetted.

Bare `plan start` lists plans (id, name, DRAFT/READY) and asks which to start.
Starting a non-READY plan warns interactively; non-interactive (e.g. loop
--refill) requires **Status:** READY. (Plan-file **Status:** READY is separate
from the task-level READY the gate stamps on each member.)

A successful start latches the plan file to `**Status:** STARTED` — a one-way
switch. STARTED means "members committed to `next/`," not "members currently in
`next/`"; the status does not flip back as members flow on through
`doing/review/done`. A STARTED plan is not re-refilled by `loop --refill`
(refill selects READY plans only).

The run ends with a summary — ready → next/, blocked, done counts — and the next
step is `./sprint.sh work`. Lifecycle moves use `git mv SRC DEST || mv SRC DEST`
(git mv first; plain mv finishes when untracked). The developer owns commits.

**plan done [id]** — retire a finished plan. When every member task is in
`docs/tasks/done/`, deletes the plan file (retirement is deletion, never a
stored DONE status). If any member is still outstanding, it reports what remains
and does nothing. Bare `plan done` picks a plan.

Usage:
  ./sprint.sh plan think [id]
  ./sprint.sh plan start [id] [--commit-only]
  ./sprint.sh plan done  [id]
  ./sprint.sh plan              # prints this usage (no auto-planner)

Provider for this run only (AI subcommands; leading flags; no config rewrite):
  ./sprint.sh -g plan think [id]     # Grok Build
  ./sprint.sh -c plan start [id]     # Claude Code

Family order:
  1. ./sprint.sh newplan "…"
  2. ./sprint.sh chat plan [id]     # author
  3. ./sprint.sh plan think [id]    # optional critique
  4. ./sprint.sh plan start [id]    # gate members, commit READY → next/ (latches STARTED)
  5. ./sprint.sh work · loop
  6. ./sprint.sh plan done [id]      # all members in done/ → delete the plan file

`loop --refill` runs `plan start` on the next READY plan (lowest id) — the gate
runs as part of the start, so the sprint refills with vetted work. Only
human-authored plans refill the queue.
