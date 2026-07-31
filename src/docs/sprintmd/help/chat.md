Discuss a task with an AI to turn it into a well-defined, workable task.
`chat` is now the single conversational command — it absorbs what the old
`plan` and `find` stress-test flows used to do. It sizes the task up first,
then routes to the right depth:

  - Blank stub → fills in ## Problem, ## Success criteria, and ## Notes
    from scratch, one question at a time.
  - Several jobs bundled together → proposes a breakdown, and on your OK
    creates the sub-tasks with `./sprint.sh newtask` (real IDs, standard
    template, **Parent** linked back so `plan <n> parent:N` still gathers
    them), then chats through each to add real detail. The original is
    retired once its children exist.
  - Genuinely one rough job → refines it in place, one detail at a time:
    ask a question, polish your answer with you, edit the file right then,
    move to the next gap.
  - Already looks defined → stress-tests it across goal fit, scope,
    criteria, assumptions, risk, dependencies, and alternatives, recording
    what it finds in a ## Think Notes block.

It can move between these modes mid-session as facts emerge. Either way the
result is an executive-summary-level brief — clear about what "done" looks
like, with suggested technology choices and references, but no code.

Use this whenever a task you wrote feels off — blank, half-baked, too big,
or deceptively finished — and you want to think it through out loud. To
split a task without the conversation, use `split`.

With NO task id, `chat` widens the lens from one task to the whole sprint —
a fast structural-health stand-up over `next/` and `blocked/`. A shell
preflight (no AI, so cost scales with problems found, not sprint size)
checks dependency integrity, stage correctness, and stale markers, then the
conversation walks what it found one finding at a time, most-blocking first:

  - broken dependency edges (a Depends on / Blocks id with no task on disk;
    a one-way edge where A depends on B but B's Blocks omits A)
  - dependency-stage violations (a `next/` task depending on something still
    in `backlog/` — an ordering gap — or in `blocked/` — a hard block)
  - blocked-limbo (a `blocked/` task with no `**Status: BLOCKED**` and no
    `## Questions` — almost always mis-filed; the default fix is to move it
    back to `backlog/` to reconsider)
  - stale-ready (a `next/` task with no `**Status: READY**` stamp)
  - outstanding questions (an unanswered item that leaves a task not truly
    READY despite its marker) — each surfaced verbatim and, once you answer
    or decide, written back into the task file as a resolved decision
  - orphaned parents and dependency cycles

It opens with a ≤3-line summary (queued count, runnable frontier, findings
count) and offers to act on each finding — fix an edge, move a mis-parked
file, stamp a marker — or chain into `chat <id>` for anything that needs
real definition work. This is a health pass ("is the sprint internally
consistent and unblocked?"), distinct from `plan think`, which is a dual-persona
planning critique of a *plan* ("is this the right grouping?"). A clean board or
an empty `next/` reports and exits without spending a token.

With a STAGE FOLDER name (`blocked`, `next`, or `backlog`), `chat` sweeps that
whole folder one task at a time — an express, verdict-first sort that absorbed
the old `triage` command. For each task it gives a fast verdict (status, a
one-line summary, a recommendation) on a cheap model, then lets you decide.
Verdict **BLOCKED** / **UNDEFINED** means unworkable as written (needs define) —
not “has an open Depends on.” Ordinary deps are pipeline ordering; `work` holds
until they finish. A dep that sits in the `blocked/` *folder* is different
(undefined limbo) and is called out separately.

  - [w] work it   — from `next/`: start it (`doing/`). From `blocked/` or
                    `backlog/`: **commit to sprint via the shared workability
                    gate** (READY → `next/`, BLOCKED → `blocked/` with a reason,
                    COMPLETE → `review/`). Never a raw promote into `next/`.
  - [d] define it — go deep: hand the task to the full `chat <id>` conversation
                    (the strongest model), the only step that escalates past the
                    fast verdict — this two-tier split keeps the rip-through tempo
  - [k] kill it   — delete after confirming
  - [s] skip / [q] quit

Dependency resolution is intrinsic to `chat` and runs on every task the sweep
opens, exactly as it does for `chat <id>` and the no-arg walk: when a swept
task's **Depends on** points into `blocked/`, the sweep lifts and defines that
dependency (via the same fresh-context chain) so the dependent task can actually
be worked. The folder argument only chooses WHICH files are opened.

With `plan` (or `plan <id>`), `chat` authors a plan file in `docs/plans/` —
conversational grouping, not task refinement. Bare `chat plan` picks a plan
(like bare `chat backlog`); `chat plan <id>` uses a *plan* id (never a task
id). Create the scaffold first with `newplan`. The walk injects the shared
Conversation Method and writes only the plan file: Goal, ordered member task
IDs (from `backlog/`, read-only — no task moves or edits), parallelism notes
(recorded, not acted on), and `**Status:** DRAFT → READY` when you confirm.
`chat backlog` mutates task files; `chat plan` only records IDs into the plan.
After authoring: optional `./sprint.sh plan think <id>` (dual-persona critique),
then `./sprint.sh plan start <id>` to commit members into the sprint — not here.

With `bugs`, `chat` sweeps the bug inbox (`docs/bugs/`) — the same verdict-first
tempo, but bug-shaped. A bug report is not a task: it lives flat, has no
dependency or status metadata. Handled reports leave the workspace (delete) —
the inbox holds open reports only. For each report the sweep gives a fast
verdict (REPRODUCIBLE / FIXED / UNDEFINED / DUPLICATE / STALE on a cheap model),
then lets you decide:

  - [w] work it   — **convert**: create a fix task filled from the report
                    (Problem, Steps→Problem, Success criteria, origin in Notes),
                    then **delete** the bug file. The task owns the work from
                    here; refine later with `chat <task-id>` if needed.
  - [d] define it — go deep on the *report itself* (the strongest model):
                    sharpen `## Problem`, `## Steps to reproduce`, the severity,
                    and `## Success criteria` until anyone could reproduce and
                    verify the fix. The only step that escalates past the verdict.
  - [a] close     — already fixed or obsolete, no task → **delete** the report
  - [k] kill it   — not a real bug: delete after confirming
  - [s] skip / [q] quit

Unlike the task-folder sweep, this runs no dependency resolution — bugs have no
dependencies. File a bug first with `./sprint.sh newbug "…"`. Prefer filing a
clear fix as `newtask` when you already know it is real work; use the bug inbox
when reports still need triage.

Usage:
  ./sprint.sh chat <task-id>    # chat one task through
  ./sprint.sh chat <folder>     # sweep one folder: blocked, next, or backlog
  ./sprint.sh chat plan [id]    # author a plan (plan id; bare = pick one)
  ./sprint.sh chat bugs         # sweep the bug inbox → fix tasks
  ./sprint.sh chat              # walk the whole sprint's structural health

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g chat <id>      # Grok Build
  ./sprint.sh -c chat <id>      # Claude Code
Default comes from docs/sprintmd/config (CLI / PROVIDER) or setup.sh.

What it does:
  - Sizes the task up first, then splits or refines accordingly
  - Asks one focused question at a time, targeting the biggest gap
  - Lays out open technical decisions with a recommended default and its
    rationale, flagging security and performance trade-offs
  - Polishes each answer, then edits immediately (atomic edits, not one
    rewrite at the end)
  - Fills ## Problem, ## Success criteria, and ## Notes at a summary
    altitude — technologies and reasons, plus references to repo files and
    external docs; never code snippets
  - Closes the loop on a blocked task: when the conversation genuinely
    resolves one that `gate` parked in blocked/, it re-enters the sprint
    only through the shared workability gate (same review as `plan start`
    / folder `[w]`) — READY → next/, or kick back BLOCKED with a reason.
    Never a raw move into next/. If a real question still remains, it
    leaves the task in blocked/ and says so.
  - Chains to the next undefined dependency in a *fresh* context so a long
    definition session doesn't pile up tokens: it seeds the next task's
    file with a short "Context from chat" note (the decisions that flow
    downstream), then — inside an agent — spins up a new agent for it, or
    in a plain terminal prints the `./sprint.sh chat <id>` to run next.

Searches: blocked/, backlog/, next/, doing/
