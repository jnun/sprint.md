# Getting Started with sprint.md

sprint.md carries an idea all the way to shipped, tested work in five short steps. Run `./sprint.sh help` any time to see every command.

## The loop

```
idea  →  feature  →  task  →  done  →  test
 ▲                                       │
 └───────────  new idea / feature  ◄─────┘
```

You have an idea. You sharpen it into features. You break features into tasks.

You move tasks to done. You test the result and feed what you learn back in.

DOCUMENTATION.md outlines the entire ruleset for docs.

## Step 1 — Capture the idea

Start here when you have a rough concept.

```bash
./sprint.sh newidea "Let people share playlists"
```

This creates `docs/ideas/let-people-share-playlists.md` with a guided thinking
framework. Work through it to move from a rough spark to a clear bet: who has
the problem, what you'll build, and the smallest version worth testing.

**Do this:** Fill in the phases. End with a short list of features that serve
the idea.

## Step 2 — Define the features

Turn each feature from your idea into a defined capability.

```bash
./sprint.sh newfeature "Playlist sharing"
```

This creates `docs/features/playlist-sharing.md`. Describe what the feature does
in plain language — what someone can do once it exists.

**Do this:** Write the feature so anyone can understand the goal without reading
code. Want help thinking it through? Run `./sprint.sh newfeature` with no name for
a guided Q&A.

## Step 3 — Break it into tasks

Split each feature into specific, buildable work items.

```bash
./sprint.sh newtask "Add a Share button to the playlist page"
```

This creates a numbered task in `docs/tasks/backlog/`. Each task describes one
concrete piece of work.

**Do this:** Write one task per piece of work. Keep each small enough to finish
and check.

**Task still rough?** Discuss it with an AI to turn it into a well-defined,
workable task:

```bash
./sprint.sh talk 12          # use the task's number
```

`talk` reads the task, then asks one focused question at a time — sharpening the
problem, the success criteria, and the technical notes until any developer could
pick it up. It edits the file as you answer, so progress shows up right in the
task. And if the task turns out to be several jobs in a trench coat, it splits
them into small, ordered sub-tasks for you.

## Step 4 — Move tasks to done

Tasks live in folders, and the folder is the status. Move a task by moving its
file.

| Folder | Meaning |
|--------|---------|
| `backlog/` | Planned |
| `next/` | Queued to work now |
| `doing/` | In progress |
| `review/` | Done, awaiting a check |
| `done/` | Complete |

```bash
git mv docs/tasks/backlog/12-add-share-button.md docs/tasks/next/
git mv docs/tasks/next/12-add-share-button.md docs/tasks/doing/
git mv docs/tasks/doing/12-add-share-button.md docs/tasks/review/
git mv docs/tasks/review/12-add-share-button.md docs/tasks/done/
```

**Do this:** Pull a task into `next/`, build it, then move it toward `done/`.
Check progress any time with `./sprint.sh status`.

## Step 5 — Test the thing

Once the feature is built and deployed, validate it. You decide how to test —
real users, a demo, a metric you watch.

```bash
./sprint.sh newtest "Playlist sharing gets used"
```

This creates `docs/tests/playlist-sharing-gets-used.md`. Write the claim you're
testing, run your test your way, and record what happened.

**Do this:** Turn each learning into the next piece of work — `./sprint.sh
newfeature` for a new capability, `./sprint.sh newtask` for a specific change. That
closes the loop and starts the next one.

---

## Running a sprint

A **sprint is just the group of tasks sitting in `docs/tasks/next/`.** There's no
special file, label, or ID — whatever is in `next/` right now *is* the sprint.

Three separate commands take a sprint from backlog to finished. They're separate on
purpose: each one stops so you can fix whatever it reveals before moving on.

| Step | Command | What it does | You stop to… |
|------|---------|--------------|--------------|
| **1. Plan** | `./sprint.sh plan [count]` | picks tasks from `backlog/` into `next/` | review the plan before files move |
| **2. Define** | `./sprint.sh define` | vets each task in `next/`, marks it `READY` | answer questions, fix blocked tasks |
| **3. Execute** | `./sprint.sh tasks` | works the `READY` tasks, each in a fresh AI context → `review/` | review the diffs before you commit |

`plan` **plans** a sprint; `tasks` **executes** the one already in `next/`. Keeping
them apart lets you catch problems each step surfaces instead of running blind.

Want it unattended? `./sprint.sh loop --refill --retry` chains all three and drains the
backlog on its own — you trade the stop-points for hands-off.

---

## What's in the package

Five ways to create work. Each command writes a file with inline guidance — fill
in the sections, then commit.

| Type | Command | What to do |
|------|---------|-----------|
| **Idea** | `newidea "..."` | Refine a rough concept into a clear bet and a list of features |
| **Feature** | `newfeature "..."` | Describe a capability in plain language |
| **Task** | `newtask "..."` | Write one specific, buildable work item |
| **Bug** | `newbug "..."` | Report something that needs fixing |
| **Test** | `newtest "..."` | Validate a deployed thing, then route learnings into new work |

**Folders you own** — create and edit freely:

- `docs/ideas/` — rough concepts being refined
- `docs/features/` — defined capabilities
- `docs/tasks/` — work items, organized by status folder
- `docs/bugs/` — bug reports
- `docs/tests/` — your test loops
- `docs/guides/` — your documentation

**Handy commands:**

- `./sprint.sh talk <task-id>` — discuss a task with an AI to make it well-defined and workable
- `./sprint.sh status` — see counts and what's in progress
- `./sprint.sh help` — list every command
- `./sprint.sh help <command>` — details for one command

For the full reference, read `DOCUMENTATION.md`.

---

*Plain folders and markdown. Start with an idea, end with a test.*
