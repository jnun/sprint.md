<div align="center">

<img src="https://github.com/jnun/sprint.md/releases/download/demo-assets/sprint-md-logo.gif" alt="sprint.md" width="720">

# Agent task lists die with the chat.
### Put the board in the repo.

**Folders = status. Markdown = work. Git = history.**  
No database. No SaaS. No login.

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.0.58-blue.svg)](https://github.com/jnun/sprint.md/releases)
![AI: Claude · Grok](https://img.shields.io/badge/AI-Claude%20%C2%B7%20Grok-8A2BE2.svg)

</div>

## Install (into *your* project)

```bash
curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash
```

That drops `./sprint.sh`, the folder board, templates, and docs into the **current directory**. Prefer a path?

```bash
curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash -s -- /path/to/your/project
```

Already cloned this repo?

```bash
./setup.sh .                 # install into cwd
./setup.sh ~/code/my-app     # or any project path
```

---

<div align="center">
<img src="https://github.com/jnun/sprint.md/releases/download/demo-assets/sprint_demo_min.gif" alt="sprint.md in action" width="820">
</div>

---

## Why this sticks

| Session agent todos | **sprint.md** |
|---------------------|---------------|
| Die when the chat ends | **Survive every session** |
| Invisible to the next agent | **Same board for every agent & human** |
| Trapped in one tool | **Plain files in your repo** |
| Vendor lock-in | **Delete the tool — work stays in git** |

- **Folder = status** — `git mv docs/tasks/doing/… docs/tasks/review/` *is* the state change  
- **Agents already speak this** — markdown + paths, no API, no login  
- **Zero lock-in** — remove `sprint.sh` and the work is still there  

> Session tools are useful *inside* a work session. **sprint.md is how the work persists between them.**

---

## 60-second start

```bash
./sprint.sh profile                         # teach the AI your stack (once)
./sprint.sh newtask "Reject empty password on login"
./sprint.sh status                          # see the board
./sprint.sh work                            # execute next ready task
```

Happy path for a plan:

```text
chat  →  plan start  →  work  →  polish
```

```bash
./sprint.sh newplan "Auth" 12 13
./sprint.sh plan start <id>
./sprint.sh work
# or unattended:
./sprint.sh loop --refill --retry
```

**Providers:** Claude Code (`-c`) and Grok Build (`-g`) are first-class.

```bash
./sprint.sh -g work
./sprint.sh -c chat 12
```

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

## Proof, not pitch

This repository **is managed with sprint.md**. Browse [`docs/tasks/`](docs/tasks/) for a live board.

Full manual: **[DOCUMENTATION.md](DOCUMENTATION.md)** · New here: **[GETSTARTED.md](GETSTARTED.md)**

---

## For AI agents

Read **[DOCUMENTATION.md](DOCUMENTATION.md)**. Create work with `./sprint.sh`, never by hand. Folder = status. Don’t edit `docs/sprintmd/`.

---

## Contributing

Issues and PRs welcome — **[CONTRIBUTING.md](CONTRIBUTING.md)**. If this saves you a session of lost context, a ⭐ helps the next developer find it.

<div align="center">

*Plain folders and markdown. Start with an idea, end with a test.*

MIT © [Jason Nunnelley](https://github.com/jnun)

</div>
