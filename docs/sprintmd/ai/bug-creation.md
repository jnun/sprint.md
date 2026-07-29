# AI Bug Documentation Protocol

## Core Principle

**Describe what's broken in plain English.** Focus on observable behavior — what happens vs. what should happen.

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

1. Create a task to fix it (`./sprint.sh newtask "Fix: [bug description]"`)
2. Reference this bug file in the task's Notes section
3. Move this file to `docs/bugs/archived/` when fixed
