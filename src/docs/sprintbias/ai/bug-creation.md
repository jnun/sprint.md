# AI Bug Documentation Protocol

## Core Principle

**Describe what's broken in plain English.** Focus on observable behavior — what happens vs. what should happen.

**Plain text, no decoration.** Skip emoji, color, badges, and drawn ASCII art — they add no data and cost the next reader context. A tool's own output line is data; keep it in backticks. Full rule: `docs/sprintbias/guides/doc-style.md`.

Bugs are a **triage inbox**, not the work system. Real work lives as tasks after convert.

## Severity Levels

| Level | Meaning |
|---|---|
| CRITICAL | System down, data loss, security issue |
| HIGH | Major feature broken, blocks users |
| MEDIUM | Feature impaired, workaround exists |
| LOW | Minor issue, cosmetic |

## Bug File Naming

`ID-description.md` (e.g., `3-login-timeout.md`)

## Writing a Good Bug Report

### Problem Section

Describe what is happening and what should happen instead. Be specific about the unexpected behavior.

### Steps to Reproduce

Numbered steps someone can follow to see the bug. Include:
- Starting state (logged in? specific page?)
- Exact actions taken
- What you observe at each step

### Success Criteria

Write observable behaviors that confirm the fix works:
- "User can [do what]"
- "System shows [result]"
- "[Action] no longer causes [problem]"

## After Documenting

When the report is real work, **convert** it — do not keep a parallel bug file:

1. Prefer `./sprint.sh chat bugs` → **[w] work it** — creates a fix task filled
   from this report (Problem, steps, success criteria, origin in Notes) and
   **deletes** the bug file.
2. Or create the task yourself: `./sprint.sh newtask "Fix: [description]"` and
   delete the bug when the hand-off is done.
3. Close without a task ([a] in chat bugs) or kill ([k]) also **delete** the
   report. Open `docs/bugs/` is for unhandled reports only.

If the fix is already obvious, skip the inbox and file a task with `newtask`
directly.
