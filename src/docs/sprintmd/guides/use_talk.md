# Using `talk` — the conversational task refiner

`./sprint.sh talk <task-id>` is the one sprint.md command that is a *dialogue*
rather than a one-shot job. It reads a rough task, sizes it up, then works
through it with you one detail at a time — asking a question, polishing your
answer, editing the task file right then, and moving to the next gap. The
result is an executive-summary-level brief: what "done" looks like, sensible
technology suggestions with reasons, and references — but no code.

Because it is a back-and-forth, `talk` needs somewhere to *have* the
conversation. This guide explains the three ways it can run and how to get the
full experience.

## The three ways `talk` runs

Which one you get is decided automatically from your environment (the `MODE`
setting in `docs/sprintmd/config`, your `CLI`, and whether you are at a real
terminal).

### 1. Inside an AI agent session — "emit" mode

If you are already working inside a coding agent (Claude Code, Cursor, etc.),
`talk` prints its instructions into that session and your agent conducts the
conversation directly. You just keep chatting in the tool you are already in —
answer each question, and the agent edits the task file as you go. This is the
default whenever sprint.md detects it is running inside an agent.

### 2. A plain terminal with the `claude` CLI — "exec" mode (full experience)

If you run `./sprint.sh talk <id>` from an ordinary terminal and the `claude`
CLI is installed, `talk` launches a **live, interactive Claude session** on the
task. It asks its first question and then hands you the prompt — you type your
answer, it edits the file, asks the next question, and so on. This is the full
back-and-forth the command was designed for.

To end it, close the session the normal way (`Ctrl-D`, or `/exit`). Your edits
are saved to the task file as the conversation happens, so there is nothing to
"commit" at the end — when you exit, the refined task is already on disk.

### 3. Anything else — a single refinement pass (degraded)

If `talk` is running in exec mode but there is **no interactive terminal**
(you piped it, or it is in CI or a loop) or your provider has **no interactive
profile** (any CLI other than `claude`), a live REPL would just hang waiting on
input. So instead `talk` does one useful pass — it reads the task, sizes it up,
and writes an improved version — then exits. You will see a note on screen
saying this happened and pointing back to this guide.

That single pass is genuinely useful, but it is not the conversation. To get
the real thing, use option 1 or 2 below.

## Getting the full back-and-forth

Pick whichever fits how you work:

- **Run it inside your agent.** Open your task in Claude Code (or another
  coding agent) and run `./sprint.sh talk <id>` there. The agent runs the
  conversation itself (emit mode). Nothing to install.

- **Install the `claude` CLI and use a real terminal.** With `claude` on your
  `PATH`, run `./sprint.sh talk <id>` from an interactive shell (not piped, not
  CI). You get the live session in option 2.

If you keep landing in the single-pass fallback when you did not expect it,
check:

- **Are you at a real terminal?** Piping the command, or running it from a
  script/CI job, removes the TTY that an interactive session needs.
- **Is `CLI=claude` in `docs/sprintmd/config`?** Interactive sessions are only
  wired up for the `claude` provider today. Other CLIs fall back to the single
  pass.
- **Is `MODE` forcing something?** In `docs/sprintmd/config`, `MODE=emit` always
  prints the prompt for a surrounding agent; `MODE=exec` always spawns the CLI;
  empty auto-detects. If you set it, make sure it matches how you actually run.

## What happens when the task is defined

`talk` doesn't just refine and leave you to clean up — it closes the loop and,
when there's more to define, keeps the chain moving without ballooning context.

- **A blocked task goes straight back into the sprint.** When you talk through
  a task that `define` had parked in `blocked/` and the conversation genuinely
  resolves it, `talk` stamps it `**Status: READY**`, removes the stale
  `## BLOCKED` section, and moves it back to `next/`. It's immediately runnable
  with `./sprint.sh tasks` — no manual `git mv`, no second `define` pass. If a
  real open question remains, `talk` does none of this: the task stays in
  `blocked/` and it tells you what still needs deciding.

- **The next dependency is picked up in a fresh context.** Defining one task
  often reveals it depends on another task that isn't defined yet. Rather than
  keep talking in the same session — where the whole conversation stays in
  context and burns tokens — `talk` writes a short **Context from talk** note
  into that next task's file (just the decisions that flow downstream), then
  starts fresh on it: inside an agent it spins up a *new* agent for the next
  task; in a plain terminal it prints the `./sprint.sh talk <id>` for you to run
  in a new window. Either way the next session begins with a clean context and
  reads what it needs from the file. When nothing downstream is left undefined,
  `talk` says the chain is complete and stops.

## Choosing the model

Left unset on the `claude` provider, `talk` uses the strongest model — it is an
interactive, reasoning-heavy flow and worth it. To pin a specific model, set
`MODEL_TALK` in `docs/sprintmd/config` (or the `FIVEDAY_MODEL_TALK` environment
variable); it falls back to `MODEL_DEFAULT` when empty.

## When to reach for something else

- To **split** a task into atomic sub-tasks without the conversation, use
  `./sprint.sh split <file>`.

`talk` handles every conversational case itself — a blank stub, a rough draft, a
task that's really several jobs, or one that already looks done and needs
stress-testing. It sizes the task up and routes to the right depth, so reach for
it whenever a task feels off and you want to think it through out loud.
