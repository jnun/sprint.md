<div align="center">

<img src="https://github.com/jnun/sprint.md/releases/download/demo-assets/sprint-md-logo.gif" alt="sprint.md" width="720">

# Plans live in git.

### Folders are status. Markdown is the work. History is free.

**One board your agents and your team can both see.**  
No database. No SaaS. No login.

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.0.58-blue.svg)](https://github.com/jnun/sprint.md/releases)
![AI: Claude · Grok](https://img.shields.io/badge/AI-Claude%20%C2%B7%20Grok-8A2BE2.svg)

</div>

## Install into your project

```bash
curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash
```

That adds `./sprint.sh`, the folder board, templates, and docs to the **current directory**. Prefer a path?

```bash
curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash -s -- /path/to/your/project
```

Already cloned this repo?

```bash
./setup.sh .                 # install into cwd
./setup.sh ~/code/my-app     # or any project path
```

---

## Try it

```bash
./sprint.sh profile                         # once — teach the AI your stack
./sprint.sh newtask "Reject empty password on login"
./sprint.sh status                          # see the board
./sprint.sh work                            # do the next ready task
```

That’s the whole loop: capture work, see it, ship it.

Group related tasks when you’re ready:

```bash
./sprint.sh newplan "Auth" 12 13
./sprint.sh plan start <id>
./sprint.sh work
# or keep going:
./sprint.sh loop --refill --retry
```

**Claude Code** (`-c`) and **Grok Build** (`-g`) are first-class:

```bash
./sprint.sh -g work
./sprint.sh -c chat 12
```

---

## Why it feels light

| What you get | How |
|--------------|-----|
| Work that lasts past one chat | Plain files in the repo |
| One board for agents and humans | Same folders, same markdown |
| Status you can see in `git status` | Move a file = change state |
| Easy exit | Remove the tool — the work stays in git |

- **Folder = status** — `git mv docs/tasks/doing/… docs/tasks/review/` *is* the state change  
- **Agents already speak this** — markdown and paths, no API, no login  
- **Yours to keep** — delete `sprint.sh` anytime; tasks, plans, and history remain  

> Session tools help *inside* a chat. **sprint.md is how the work stays when the chat ends.**

---

## The board (the whole model)

```text
docs/tasks/backlog/   Planned, not started
docs/tasks/next/      Queued for the current sprint
docs/tasks/doing/     In progress
docs/tasks/blocked/   Needs a decision
docs/tasks/review/    Done, awaiting approval
docs/tasks/done/      Shipped
```

The sprint is whatever sits in `next/` right now. No special file — the folder *is* the sprint.

---

## Live here

This repository **runs on sprint.md**. Browse [`docs/tasks/`](docs/tasks/) for a real board.

**[GETSTARTED.md](GETSTARTED.md)** · full manual: **[DOCUMENTATION.md](DOCUMENTATION.md)**

---

## For AI agents

Read **[DOCUMENTATION.md](DOCUMENTATION.md)**. Create work with `./sprint.sh`, not by hand. Folder = status. Don’t edit `docs/sprintmd/`.

---

## Contributing

Issues and PRs welcome — **[CONTRIBUTING.md](CONTRIBUTING.md)**. If this helps your next session start where the last left off, a ⭐ helps someone else find it.

<div align="center">

*Plain folders and markdown. Start with an idea, end with a test.*

MIT © [Jason Nunnelley](https://github.com/jnun)

</div>
