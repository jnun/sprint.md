Task quality review — **off the plan-commit spine**.

Happy path is `plan start` → `work`: plan start runs the same workability
gate as it promotes members, so a committed sprint is already vetted. `gate`
is the standalone version of that gate, for two jobs it owns:
  - re-gate `next/` on demand (e.g. after editing a task) — `gate --force`
  - read-only quality report on backlog/doing/blocked — `gate <folder>`

Vets task files for quality. Default target is `docs/tasks/next/`, where gate
is the READY-gate. Pass a folder to report quality on backlog, doing, or blocked
without moving anything.

On **next/** (default) gate:
  - Checks which action items are already complete (and verifies quality)
  - Identifies remaining work
  - Asks clarifying questions with suggestions when decisions are needed
  - Writes a ## Questions section into the task file

Verdicts on next/ (workability stamps — **not** lifecycle folders):
  READY    — task stays in next/, ready for execution
  BLOCKED  — task moves to blocked/, needs developer answers first
  COMPLETE — work already present in the codebase; task moves to **review/**
             (not `docs/tasks/done/`; you approve and move to done/ later)

On **backlog/**, **doing/**, or **blocked/** gate reports only (read-only):
  COMPLETE  — work already present in the codebase (not the done/ folder)
  OUTDATED  — references files/patterns that no longer exist
  UNDEFINED — too vague to be actionable
  KEEP      — still relevant, well-defined, not yet completed
No files are written or moved. Use this to scan a folder; act on findings with
`chat`, a lifecycle move (`git mv SRC DEST || mv SRC DEST`), or by editing the task.

Usage:
  ./sprint.sh gate              # READY-gate all tasks in next/
  ./sprint.sh gate 3            # gate at most 3 tasks in next/
  ./sprint.sh gate --force      # re-review tasks already stamped READY
  ./sprint.sh gate backlog      # quality report on backlog/ (no moves)
  ./sprint.sh gate blocked 5    # report at most 5 blocked tasks
  ./sprint.sh gate next 1       # same as: gate 1

Folders: next (default), backlog, doing, blocked.
review/ and done/ are not targets (completed work).

By default gate skips next/ tasks already stamped 'Status: READY' so you don't
re-pay to review the whole queue each run. --force re-reviews all of them.
--force only applies to next/.

After running on next/:
  - READY tasks: run ./sprint.sh work to execute them
  - BLOCKED tasks: answer questions (or `./sprint.sh chat <id>`), then re-enter
    next/ only via the shared gate again — never raw `git mv` into next/
  - COMPLETE tasks: verify in review/, then move to done/ when you approve

**Invariant:** nothing enters `next/` without this workability review. Surfaces
that promote (`plan start`, `chat backlog`/`blocked` `[w]`, `chat` close-loop,
`polish` REOPEN, `loop --retry`) all call the same gate-lib path. Agent helper:
`bash docs/sprintmd/scripts/promote-to-sprint.sh <task-file>`. Escape hatch:
`plan start --commit-only` (explicit, unvetted).

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g gate                # Grok Build
  ./sprint.sh -c gate --force        # Claude Code

Related commands:
  gate    — this command: quality gate on next/, quality report elsewhere (off-spine)
  chat    — interactive refine/split on one task or a folder sweep
  work    — execute READY tasks from next/ (happy path after plan start)
  plan start — commit plan members into next/ (runs this same gate as it promotes)
