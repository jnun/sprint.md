# sprint.md

Project management in markdown files. Folders and plain text.

## Guiding principles

Every design decision in this system passes through these lenses:

1. **Lean into agent bias.** Shape work around what an AI agent does well —
   read context, reason, converse, decide. Prefer commands and tasks that walk
   with those strengths instead of fighting them.
2. **Minimize context cost.** Every file, command, and help page costs context
   when an agent loads it. Fewer, sharper commands beat many overlapping ones.
   Pruning is a feature.
3. **Name in common language.** Plain words that read the same to people and
   agents (`task`, `chat`, `work`, `plan`, `polish`) beat jargon. Lifecycle
   folders `backlog → next → doing → review` are the affordance. If a term
   needs translating, pick a different term.
4. **Instruct positively.** State the desired path as the rule
   ("Always edit `docs/`, then commit"). Prohibition-shaped rule *lists* hand
   the model a map of forbidden behavior and no map of the work — under
   ambiguity it falls into exactly what was described. Reserve a plain
   "never" for genuine invariants where the wrong action is costly.

When principles conflict: **simple, clean, fast, common language, biased
toward action.**

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
- `docs/plans/` — your plans: named groupings that list task IDs (see below)
- `docs/bugs/` — open bug reports (inbox only; convert or close deletes the file)
- `docs/guides/` — your documentation. Style it per `docs/sprintmd/guides/doc-style.md`; run `docs/sprintmd/scripts/prettydoc.py <file>` to align tables
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
5. Move tasks by changing folders — folder location = status.
   Always: `git mv SRC DEST || mv SRC DEST` (see Moving Tasks)

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

**Plans vs. the folders above — don't conflate them either:**
- The six folders above are **lifecycle status**: a task lives in exactly one, and moving it *is* how status changes.
- A **plan** (`docs/plans/N-name.md`) is a **relational index, not a status.** It is one file that names a clump of related tasks and lists their IDs. The member tasks are **never moved into it** — each stays in its own lifecycle folder and flows through `backlog → next → …` on its own. A plan is never a lifecycle stage and is never counted or moved as a task; it carries a `**Status:** DRAFT | READY | STARTED` for its own life: `DRAFT` while authoring, `READY` once authored and safe for `plan start` / `loop --refill`, and `STARTED` — a one-way switch set by `plan start` — once its members have been committed to `next/`. Retirement is deletion: when every member sits in `docs/tasks/done/`, `./sprint.sh plan done <id>` removes the file. There is no stored `DONE` and no `NEXT` plan status. Two disambiguations: a plan `**Status:**` is **not** a task folder (`next/` is a lifecycle stage; `STARTED` is a plan field), and plan-level `READY` is **not** the task-level `**Status: READY**` the gate stamps on each member. `docs/plans/` is a sibling of `docs/tasks/`, not a stage inside it.
- Member IDs are references only: moving or working a member task needs no edit to the plan file. To commit a plan into the sprint, run `./sprint.sh plan start <id>` (or move its members `backlog/ → next/` with `git mv SRC DEST || mv SRC DEST`); the plan file itself never moves. Create one with `./sprint.sh newplan "<name>" [task-id ...]`; `./sprint.sh status` rolls up each plan by resolving its members' current folders.

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
├── plans/              # Named groupings that LIST task IDs (relational index, not a stage)
├── bugs/               # Open bug reports (inbox; handled reports are deleted)
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
| **Idea** | Rough concept, needs refinement | `./sprint.sh newidea "User notifications"` or `./sprint.sh newidea` (AI Q&A) |
| **Feature** | Defined capability to build | `./sprint.sh newfeature "User auth"` or `./sprint.sh newfeature` (AI Q&A) |
| **Task** | Specific work item | `./sprint.sh newtask "Add login button"` |
| **Plan** | Group related tasks under one goal | `./sprint.sh newplan "Checkout revamp" 12 13 14` |
| **Bug** | Something broken | `./sprint.sh newbug "Login fails on mobile"` |
| **Test** | Validate a deployed thing, then route what you learn into new work | `./sprint.sh newtest "Signup converts visitors"` |

Each command creates a file with inline guidance. Fill in the sections, then commit.

## Commands

Happy path (spine): **`chat → plan start → work → polish`**. `loop` runs that spine on autopilot. `gate` and `split` are off-spine; `polish` is after work. The task *noun* (`docs/tasks/`, `newtask`) stays; the execute *verb* is `work`.

Help groups: **create · chat · plan · work · look · keep**.

> Tired of typing `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell
> rc to use `sprint <command>` from a project root (`sprint -g work`,
> `sprint -c chat 12`). `setup.sh` offers this on install; see
> `docs/sprintmd/guides/sprint_command.md` for details and a subdirectory-aware
> variant. Run `./sprint.sh` or `bash sprint.sh` — do not force `sh`/`zsh` on
> the script (any interactive shell is fine as the launcher).

```bash
# Creating work
./sprint.sh newidea "My rough idea"   # Create idea (quick template)
./sprint.sh newidea                   # Create idea (AI Q&A — eight phases)
./sprint.sh newfeature "Name"         # Create feature (quick)
./sprint.sh newfeature                # Create feature (AI Q&A)
./sprint.sh newtask "Description"     # Create task
./sprint.sh newplan "Name" [ids]      # Create a plan — a named list of task IDs
./sprint.sh newbug "Description"      # Report a bug
./sprint.sh newtest "Name"            # Create a test loop to validate a deployed thing

# Create a plan (author intent — group related tasks under one goal)
./sprint.sh newplan "Name" [ids]      # 1. Scaffold the plan file (Status: DRAFT)
./sprint.sh chat plan [id]            # 2. Author it in conversation — reads backlog/ read-only,
                                      #    records member IDs + goal, flips DRAFT → READY on confirm.
                                      #    (chat backlog mutates task files; chat plan only records IDs.)
./sprint.sh plan think [id]           # 3. Optional dual-persona critique of the grouping
./sprint.sh plan start [id]           # 4. Commit the plan's members into next/ — latches Status: STARTED
./sprint.sh plan done [id]            # 5. Retire: when every member is in done/, delete the plan file

# Chat & Work (AI-powered — emit inside Claude/Grok/Cursor sessions, or exec via CLI)
# Per-run provider (leading flags; does not rewrite docs/sprintmd/config):
./sprint.sh -g work                   # This run: Grok Build  (-c / --claude for Claude Code)
./sprint.sh --claude chat 12          # This run: Claude Code (same as -c)
./sprint.sh profile [show]            # Create/update project profile (show: print only, no AI)
./sprint.sh chat [target]             # id: task · folder: sweep · plan [id]: author a plan · bugs: inbox · nothing: sprint health
./sprint.sh work [limit] [--fast]     # Execute READY tasks from next/ (--force to skip the gate; --audit --excellence to chain quality audits)
./sprint.sh loop [--refill] [--retry] # Autopilot — plan start (gates as it commits) then work, drain the queue
./sprint.sh gate [folder] [limit]     # Off-spine quality gate: re-gate next/ (--force) or report on backlog/doing/blocked
./sprint.sh split <path>              # Split a large task into subtasks
./sprint.sh polish [limit] [--rounds N]  # Sweep review/: reopen tasks worth another pass
./sprint.sh polish <file>             # Deep-judge one finished piece; file enhancements to backlog/
./sprint.sh polish --code <file>      # Code-diff audit (fixer/verifier); may fix issues inline
./sprint.sh deps                      # File a backlog task auditing outdated/vulnerable deps

# Look (read-only — surface state, no mutation)
./sprint.sh status                    # View project status
./sprint.sh align                     # Analyze feature alignment
./sprint.sh context                   # Generate AI context summary
./sprint.sh search <keyword>          # Search tasks by keyword

# Keep — sync
./sprint.sh sync [--all]              # Push task changes to GitHub

# Keep — maintenance
./sprint.sh validate [--fix] [--dry-run]  # Integrity-check task IDs + deps (--docs: help/ flag drift; --commands: catalog completeness)
./sprint.sh cleanup [--delete|--force|--all]  # Clean stale files from docs/tmp/
./sprint.sh help                      # Show all commands
```

## Moving Tasks

Folder location **is** status. Change status by moving the file between
lifecycle folders — not by editing a status field on the task.

**Always move with this exact pattern (agents and humans):**

```bash
git mv SRC DEST || mv SRC DEST
```

1. Run `git mv` first — preserves history when the file is already tracked.
2. When `git mv` fails — usual for new tasks not yet committed — finish that
   **same** move with plain `mv` in the same step, then continue the workflow.
3. Leave `git add` / `git commit` to the developer unless they asked you to
   commit. Completing the move is enough to update status.

Lifecycle path:

```bash
git mv docs/tasks/backlog/ID-name.md docs/tasks/next/    || mv docs/tasks/backlog/ID-name.md docs/tasks/next/     # Queue
git mv docs/tasks/next/ID-name.md docs/tasks/doing/      || mv docs/tasks/next/ID-name.md docs/tasks/doing/       # Start
git mv docs/tasks/doing/ID-name.md docs/tasks/blocked/   || mv docs/tasks/doing/ID-name.md docs/tasks/blocked/    # Under-defined
git mv docs/tasks/blocked/ID-name.md docs/tasks/next/    || mv docs/tasks/blocked/ID-name.md docs/tasks/next/     # Re-queue
git mv docs/tasks/doing/ID-name.md docs/tasks/review/    || mv docs/tasks/doing/ID-name.md docs/tasks/review/     # Submit
git mv docs/tasks/review/ID-name.md docs/tasks/done/     || mv docs/tasks/review/ID-name.md docs/tasks/done/      # Complete
```

Scripts use the same rule via `move_file` in `docs/sprintmd/lib.sh`.

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
**Plans** = Named groupings that list task IDs. A relational index over tasks, not a status or container — the tasks stay in their own folders.
**DOC_STATE.md** = Source of truth for IDs (`docs/sprintmd/DOC_STATE.md`: `sprint_TASK_ID`, `sprint_BUG_ID`, `sprint_PLAN_ID`).

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
- `docs/plans/.TEMPLATE-plan.md`
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
