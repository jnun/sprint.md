# sprint.md

Project management in markdown files. Folders and plain text.

## Task documents

Task files live in `docs/tasks/*/` and describe outcomes in plain language:
- Explain WHAT should happen so anyone can understand the goal
- Keep implementation details in `docs/guides/` and link to them when needed

## Boundaries

**Framework files (do not edit):**
- `DOCUMENTATION.md`
- `sprint.sh`
- `docs/sprintmd/` (framework scripts, AI instructions) — except `DOC_STATE.md`, your own ID/state file

**Your content (create and edit freely):**
- `docs/ideas/` — rough ideas being refined
- `docs/features/` — fully defined feature specs
- `docs/tasks/` — your tasks
- `docs/epics/` — your epics: named groupings that list task IDs (see below)
- `docs/bugs/` — your bug reports (archive old ones in `docs/bugs/archived/`)
- `docs/guides/` — your documentation
- `docs/tests/` — your test plans
- `docs/designs/` — design system, files, and references for the project
- `docs/examples/` — code standards and worked examples to follow or mimic
- `docs/data/` — data to manage, store, or build (e.g. scaffolding to preload a database)
- `docs/sprintmd/DOC_STATE.md` — your ID and state tracking (the one file you own inside the framework folder)

## AI Agents

This file governs `docs/`. Read it before modifying any task, bug, or feature.

**Rules:**
1. `docs/` is the active project management system — not source code, not stale
2. Tasks in `review/` and `done/` are completed work — old dates mean done, not abandoned
3. Always read `docs/sprintmd/DOC_STATE.md` before creating tasks (get next ID)
4. Use `./sprint.sh` commands when available — don't create task files manually
5. Move tasks by changing folders — folder location = status

**Folder meanings:**
| Folder | Status |
|--------|--------|
| `backlog/` | Planned, not started |
| `next/` | Queued for current sprint |
| `doing/` | Actively being worked on |
| `blocked/` | Not fully defined — can't be worked until its own problem, scope, or success criteria are resolved |
| `review/` | Done, awaiting approval |
| `done/` | Shipped/complete |

**Blocked vs. dependent — don't conflate them:**
- **Blocked = a definition failure.** The task can't be worked because *it itself* is unclear: open questions, fuzzy scope, an unresolved decision. Fix by defining, not by waiting. Lives in `blocked/`.
- **Dependent = a sequencing fact.** The task is fully defined and workable; it just needs another task done first. A task waiting its turn behind another in the same plan is **not blocked** — it stays in `next/`, and the order is expressed by its `**Depends on**:` / `**Blocks**:` fields. A whole chain of dependent tasks has *zero* blocked tasks even when only one can start right now.

**Epics vs. the folders above — don't conflate them either:**
- The six folders above are **lifecycle status**: a task lives in exactly one, and moving it *is* how status changes.
- An **epic** (`docs/epics/N-name.md`) is a **relational index, not a status.** It is one file that names a clump of related tasks and lists their IDs. The member tasks are **never moved into it** — each stays in its own lifecycle folder and flows through `backlog → next → …` on its own. An epic has no status, is never a lifecycle stage, and is never counted or moved as a task. `docs/epics/` is a sibling of `docs/tasks/`, not a stage inside it.
- Member IDs are references only: moving or working a member task needs no edit to the epic file. To "push an epic to `next/`", move its member tasks `backlog/ → next/`; the epic file itself never moves. Create one with `./sprint.sh newepic "<name>" [task-id ...]`; `./sprint.sh status` rolls up each epic by resolving its members' current folders.

**Do not assume** old file dates mean abandoned. A task from months ago in `done/` is completed history.

---

## Structure

```
docs/
├── sprintmd/             # FRAMEWORK (do not edit)
│   ├── scripts/        # sprint.sh, create-task.sh, etc.
│   ├── ai/             # AI instructions
│   └── DOC_STATE.md    # Project state (ID tracking)
├── ideas/              # Rough ideas being refined
├── features/           # Fully defined feature specs
├── tasks/              # Your work items
│   ├── backlog/        # Planned
│   ├── next/           # Sprint queue
│   ├── doing/          # In progress
│   ├── blocked/        # Not fully defined (not merely waiting on another task)
│   ├── review/         # Awaiting approval
│   └── done/           # Complete
├── epics/              # Named groupings that LIST task IDs (relational index, not a stage)
├── bugs/               # Your bug reports
│   └── archived/       # Retired bugs
├── guides/             # Your documentation
├── tests/              # Your test plans
├── designs/            # Design system, files, references
├── examples/           # Code standards & worked examples to mimic
├── data/               # Data to manage, store, or preload
└── tmp/                # Scratch workspace (gitignored)
```

## Creating Work

| What | When | Command |
|------|------|---------|
| **Idea** | Rough concept, needs refinement | `./sprint.sh newidea "User notifications"` |
| **Feature** | Defined capability to build | `./sprint.sh newfeature "User auth"` or `./sprint.sh newfeature` (AI Q&A) |
| **Task** | Specific work item | `./sprint.sh newtask "Add login button"` |
| **Epic** | Group related tasks under one goal | `./sprint.sh newepic "Checkout revamp" 12 13 14` |
| **Bug** | Something broken | `./sprint.sh newbug "Login fails on mobile"` |
| **Test** | Validate a deployed thing, then route what you learn into new work | `./sprint.sh newtest "Signup converts visitors"` |

Each command creates a file with inline guidance. Fill in the sections, then commit.

## Commands

> Tired of typing `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell
> rc to use `sprint <command>` from a project root. `setup.sh` offers this on
> install; see `docs/sprintmd/guides/sprint_command.md` for details and a
> subdirectory-aware variant.

```bash
# Creating work
./sprint.sh newidea "My rough idea"   # Create idea to refine
./sprint.sh newfeature "Name"         # Create feature (quick)
./sprint.sh newfeature                # Create feature (AI Q&A)
./sprint.sh newtask "Description"     # Create task
./sprint.sh newepic "Name" [ids]      # Create an epic — a named list of task IDs
./sprint.sh newbug "Description"      # Report a bug
./sprint.sh newtest "Name"            # Create a test loop to validate a deployed thing
./sprint.sh status                    # View project status
./sprint.sh checkfeatures             # Analyze feature alignment
./sprint.sh ai-context                # Generate AI context summary

# Workflow (AI-powered — runs in your AI agent session, or via any configured CLI)
./sprint.sh profile                   # Create or update project profile
./sprint.sh search <keyword>          # Search tasks by keyword
./sprint.sh talk [target]             # id: define/refine/split a task · folder (blocked/next/backlog): sweep it · bugs: sweep inbox into fix tasks · nothing: walk the sprint's health
./sprint.sh plan [count] [focus]      # Plan a sprint from backlog
./sprint.sh define [limit]            # Review and refine tasks in next/ (stamps Status: READY)
./sprint.sh tasks [limit] [--fast]    # Execute READY tasks from next/ (--force to skip the gate; --audit --excellence to chain quality audits)
./sprint.sh loop [--refill] [--retry] # Autopilot — chain plan/define/execute, drain the queue
./sprint.sh split <path>              # Split a large task into subtasks
./sprint.sh review-sprint             # Review sprint via dual-persona analysis
./sprint.sh review-code <file> [passes]  # Run code audit on a task's changes
./sprint.sh excellence <file>         # Judge finished work against a higher bar; file enhancements
./sprint.sh polish [limit] [--rounds N]  # Sweep review/: judge each task, reopen ones worth improving to next/
./sprint.sh audit [folder] [limit]    # Audit tasks in next/ (or specified folder)
./sprint.sh audit-deps                # File a backlog task auditing outdated/vulnerable deps

# Sync
./sprint.sh sync [--all]              # Push task changes to GitHub

# Maintenance
./sprint.sh validate [--fix] [--dry-run]  # Validate task files (--docs: help/ flag drift; --commands: catalog completeness)
./sprint.sh cleanup [--delete|--force|--all]  # Clean stale files from docs/tmp/
./sprint.sh help                      # Show all commands
```

## Moving Tasks

Tasks move through folders. Use `git mv` or `mv` (then commit):

```bash
git mv docs/tasks/backlog/ID-name.md docs/tasks/next/      # Queue
git mv docs/tasks/next/ID-name.md docs/tasks/doing/      # Start
git mv docs/tasks/doing/ID-name.md docs/tasks/blocked/   # Under-defined — needs clarifying, not just waiting
git mv docs/tasks/blocked/ID-name.md docs/tasks/next/      # Now defined, re-queue
git mv docs/tasks/doing/ID-name.md docs/tasks/review/    # Submit
git mv docs/tasks/review/ID-name.md docs/tasks/done/       # Complete
```

If `git mv` fails, use `mv` and commit the change.

## Naming

| Type | Format | Example |
|------|--------|---------|
| Task | `ID-description.md` | `12-fix-auth-error.md` |
| Bug | `ID-description.md` | `3-login-fails.md` |
| Feature/Idea | `name.md` | `user-authentication.md` |

IDs come from `docs/sprintmd/DOC_STATE.md` (sprint_TASK_ID for tasks, sprint_BUG_ID for bugs).

## Key Concepts

**Ideas** = Rough concepts being refined. Start here when unclear.
**Features** = Fully defined specs. What capabilities exist.
**Tasks** = Work items. Move through folders as status changes.
**Epics** = Named groupings that list task IDs. A relational index over tasks, not a status or container — the tasks stay in their own folders.
**DOC_STATE.md** = Source of truth for IDs (`docs/sprintmd/DOC_STATE.md`: `sprint_TASK_ID`, `sprint_BUG_ID`, `sprint_EPIC_ID`).

## Ideas Workflow

When you have a rough idea but haven't thought it through:

```bash
./sprint.sh newidea "User notifications"
```

This creates `docs/ideas/user-notifications.md` with a guided refinement process:
1. **Phase 1:** Define the problem (who has it, why it matters)
2. **Phase 2:** Write in plain English (no jargon)
3. **Phase 3:** List what it does (concrete capabilities)
4. **Phase 4:** Surface open questions

Work through it manually, or ask an AI agent to guide you.

## Templates

Use templates in each folder:
- `docs/ideas/.TEMPLATE-idea.md`
- `docs/tasks/.TEMPLATE-task.md`
- `docs/epics/.TEMPLATE-epic.md`
- `docs/features/.TEMPLATE-feature.md`
- `docs/bugs/.TEMPLATE-bug.md`
- `docs/tests/.TEMPLATE-test.md`

## Updating sprint.md

To update to a newer version, re-run setup from the sprint.md repo:

```bash
cd /path/to/sprint.md
git pull
./setup.sh
# Enter your project path when prompted
```

Your DOC_STATE.md values (task IDs, bug IDs) are preserved during updates.

---

*Plain folders and markdown. That's it.*
