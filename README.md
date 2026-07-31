# sprint.md

No database, no SaaS, no login!

The issue tracker your coding agents already know how to use.

Project management that lives in your repo as folders and markdown files. No databases, no apps, no syncing — just `git` and a text editor. Humans and AI agents work from the same files, so nothing falls out of sync when you switch tools, add teammates, or hand work to an agent. A task's status is which folder it's in:

```
docs/tasks/backlog/   Planned, not started
docs/tasks/next/      Queued for current sprint
docs/tasks/doing/     In progress
docs/tasks/blocked/   Not fully defined yet
docs/tasks/review/    Done, awaiting approval
docs/tasks/done/      Shipped
```

## Why files?

AI coding tools have their own task tracking — `/goal`, `/plan`, task lists, loops. These are session-scoped: they exist inside one conversation and vanish when it ends. That works for staying focused within a session, but it's not project management. Rename a variable across three files and the context is gone. Come back tomorrow and there's no trail.

Files in your repo survive sessions, tools, and people. A task in `docs/tasks/doing/` is visible to every AI agent, every IDE, every teammate, and every `git log` — without anyone needing to be in the right conversation at the right time. More importantly, it's in the source code. If project state lives in someone's session or loop, the rest of the team can't see it — they can't participate in planning, can't pick up where someone left off, and can't review what's in flight. Agentic loops have the same problem: a loop can poll, retry, and iterate, but it's still anchored to a single session. When the loop ends, the work it tracked disappears unless something was written down.

Files checked into the repo are the one communication layer that every tool, every person, and every agent already knows how to read. As distributed agents become more common, file-based project state becomes a shared coordination surface — multiple agents working on the same codebase can read the board, claim tasks, and leave progress behind without needing to share a session.

Session tools and loops are useful *within* a work session. Files are how the work persists *between* them. sprint.md is the second part.

## Getting Started

### 1. Install

```bash
cd sprint.md
./setup.sh
# enter your project path when prompted
```

This creates the folder structure, CLI, templates, and docs in your project. You now have `./sprint.sh` and a `docs/` folder ready to go.

### 2. Profile your project

```bash
./sprint.sh profile
./sprint.sh -g profile    # optional: Grok Build for this run (-c = Claude Code)
```

An AI-guided interview about your stack, conventions, and goals. The answers are saved to `docs/sprintmd/project.md` so every command that follows already knows what you're building and how. Default AI provider comes from setup / `docs/sprintmd/config`; leading `-g` / `-c` override for one run.

### 3. Define your features

```bash
./sprint.sh newfeature                       # AI-guided Q&A — builds a complete spec through conversation
./sprint.sh newfeature "User authentication" # quick mode — creates a template you fill in yourself
```

Without a name, `newfeature` starts an interactive session that asks about users, requirements, and success criteria, then writes a complete feature spec to `docs/features/`. With a name, it creates a blank template for you to fill in manually. Features describe *what the system does* — they're the big picture that tasks break down into.

### 4. Create tasks

```bash
./sprint.sh newtask "Add login endpoint"
./sprint.sh newtask "Set up Stripe integration"
./sprint.sh newtask "Write auth middleware"
```

Tasks land in `docs/tasks/backlog/` with an auto-assigned ID, each built from a battle-tested template with prompts for success criteria, dependencies, and scope. Also: `./sprint.sh newbug "description"` and `./sprint.sh newidea "description"`.

Bug reports live in `docs/bugs/` as a triage inbox. `./sprint.sh chat bugs` sorts them: **[w] work it** converts a report into a filled fix task and deletes the bug file; close/kill also remove the report. Prefer `newtask` when the fix is already clear work.

### 5. Work the board

Move tasks through folders as you work. The folder a task is in *is* its status.
Always: `git mv SRC DEST || mv SRC DEST` — try `git mv` first; when it fails
(usual for new tasks not yet committed), finish with plain `mv` and continue.

```bash
# Queue a task for your current sprint
git mv docs/tasks/backlog/1-add-login-endpoint.md docs/tasks/next/ \
  || mv docs/tasks/backlog/1-add-login-endpoint.md docs/tasks/next/

# Start working on it
git mv docs/tasks/next/1-add-login-endpoint.md docs/tasks/doing/ \
  || mv docs/tasks/next/1-add-login-endpoint.md docs/tasks/doing/

# Finished — send to review
git mv docs/tasks/doing/1-add-login-endpoint.md docs/tasks/review/ \
  || mv docs/tasks/doing/1-add-login-endpoint.md docs/tasks/review/

# Approved — done
git mv docs/tasks/review/1-add-login-endpoint.md docs/tasks/done/ \
  || mv docs/tasks/review/1-add-login-endpoint.md docs/tasks/done/
```

Check where things stand at any time:

```bash
./sprint.sh status
```

For the full workflow reference — task format, feature specs, bug reports, and conventions — see [`DOCUMENTATION.md`](DOCUMENTATION.md).

---

## AI-Assisted Workflow

Once you have tasks in your backlog, AI can help plan, validate, and execute them.

Happy path (spine): `chat → plan start → work → polish`. `loop` is that spine on autopilot; `gate` / `split` are off-spine. Help groups: **create · chat · plan · work · look · keep** (`./sprint.sh help`).

```bash
# Author a plan, optionally critique it, then commit members into next/
./sprint.sh newplan "Theme" 12 13
./sprint.sh chat plan <id>       # author / mark READY
./sprint.sh plan think <id>      # optional dual-persona critique
./sprint.sh plan start <id>      # members → next/ (plan latches STARTED)
./sprint.sh plan done <id>       # all members in done/ → delete the plan

# Validate — catch done, underspecified, or blocked tasks before execution
./sprint.sh gate

# Execute — one fresh AI context per task
./sprint.sh work
```

### Task runner

`./sprint.sh work` runs everything in `next/`. Start with `--assist` to choose a mode interactively, or pick your own:

```bash
./sprint.sh work --assist               # interactive mode picker
./sprint.sh work --fast                 # 4 concurrent jobs
./sprint.sh work --parallel --jobs N    # set concurrency explicitly
./sprint.sh work --max                  # remove per-task turn/budget limits
./sprint.sh work --audit                # code audit after each task
./sprint.sh work --drift                # skip done tasks, fix stale ones
```

First-class AI providers (setup picker or `CLI=` / `PROVIDER=` in
`docs/sprintmd/config`): **Claude Code** (`claude` / `claude-code`) and
**Grok Build** (`grok` / `grok-build`). Both support interactive `chat`, emit
inside the agent session, and parallel subagent orchestration. Other binaries
fall back to a generic prompt passthrough.

Per-run provider (leading flags; does **not** rewrite config):

```bash
./sprint.sh -g work                 # Grok Build this run
./sprint.sh -c chat 12              # Claude Code this run
./sprint.sh --grok loop --refill    # long form
SPRINTMD_CLI=codex ./sprint.sh work # generic env override
```

Work flags combine: `./sprint.sh work --max --audit --fast`

### Loop runner

Run tasks continuously with crash recovery. Each task gets a fresh context.

```bash
./sprint.sh loop                         # drain next/
./sprint.sh loop --hours 2 --refill      # run for 2h, refill from backlog when empty
./sprint.sh loop --refill --retry        # full autopilot
```

### Useful commands

```bash
./sprint.sh chat <task-id>               # define, refine, split, or stress-test a task (auto-detects state)
./sprint.sh split <path>                 # break a large task into subtasks
./sprint.sh gate [folder] [limit]      # vet task quality (next/: READY-gate; other folders: report)
./sprint.sh polish --code <file>         # code audit on changed files
./sprint.sh polish <file>                # deep-judge finished work; file enhancements
./sprint.sh plan think [id]              # dual-persona plan critique
./sprint.sh validate [--fix]             # integrity-check task IDs and dependency refs
./sprint.sh sync [--all]                 # push task changes to GitHub
```

## For AI Agents

Start with [`DOCUMENTATION.md`](DOCUMENTATION.md) — it's the complete reference. Use `./sprint.sh` commands to create work items, never create files manually, and don't edit anything under `docs/sprintmd/`. Folder = status.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
