# AI Task Creation Protocol

## Core Principle

**Write tasks in plain English, describing what users see and do.** Tasks define WHAT needs to happen. The implementer chooses HOW.

Work flows **Feature → Task → Audit**: a task usually builds toward a feature, and it will later be audited against the problem and success criteria you write here. Write both so a future auditor can judge "done" without asking you.

## Instruct positively

**State the desired path as the rule.** Success criteria and notes say what
should be true when the work is done — not a checklist of things to avoid.

- Prefer: "User can log in with email and password"
- Prefer: "Always edit `docs/`, then commit"
- A lone, concrete "never" is fine when it anchors a genuine invariant
  ("Never create task files by hand — run `./sprint.sh newtask`") where
  the wrong action is costly.
- Do **not** write prohibition-shaped rule *lists* ("Don't X. Don't Y. Avoid
  Z."). Those hand the implementer (and any agent) a map of forbidden
  behavior and no map of the work — under ambiguity they fall into exactly
  what was described.

Check before saving: success criteria state the desired path. If a criterion
is phrased only as "don't do X", rewrite it as the positive outcome.

## Where Content Belongs

| Content Type | Location |
|---|---|
| Problems and outcomes | `docs/tasks/` |
| How to implement | `docs/guides/` |
| Code samples and patterns | `docs/examples/` |
| System specifications | `docs/features/` |

The task links out to these — it does not inline them. The task says WHAT; guides, examples, and features say HOW.

## Moving tasks (lifecycle)

Folder location **is** status. When you move a task between `backlog/`,
`next/`, `doing/`, `blocked/`, `review/`, and `done/`, always run:

```bash
git mv SRC DEST || mv SRC DEST
```

`git mv` first (preserves history when tracked). When it fails — usual for
new tasks not yet committed — finish that same move with plain `mv`, then
continue. Leave commits to the developer unless they asked you to commit.
Full table: `DOCUMENTATION.md` → Moving Tasks.

## The Q&A Process

Before creating any task, work through these questions with the user:

### 1. Understand the Problem

Ask:
- "What's happening now?"
- "What should happen instead?"
- "When does this occur? (Always? Sometimes? Under specific conditions?)"

Wait for answers. Build understanding together.

### 2. Clarify the Scope

Ask:
- "Is this about [specific thing] or something broader?"
- "Are there related issues we should address together or separately?"
- "What's the boundary of this task?"

### 3. Map the Dependencies and Reuse

Ask:
- "Does anything need to be done first?" (→ **Depends on**)
- "Will this hold up other work until it's finished?" (→ **Blocks**)
- "What existing files or code does this touch?" (→ **References** — reuse, don't reinvent)
- "Is there a guide or feature spec this follows?" (→ **Docs** / **Feature**)

### 4. Define Success Behaviorally

Ask:
- "When this is done, what will a user be able to do?"
- "How would you test that it works?"
- "What would you check to verify it's complete?"

The answers become the success criteria.

### 5. Confirm Understanding

Before writing anything, summarize back:
- "So the problem is [X], and we'll know it's fixed when [Y]. Is that right?"

Proceed after confirmation.

## Task Structure

### Header Fields

The header carries the task's place in the larger body of work. Set what applies; leave the rest as `none`.

- **Feature** — the feature this builds toward, e.g. `/docs/features/user-auth.md`. `none` if no feature applies.
- **Created** — date the task was created (`YYYY-MM-DD`). Set automatically by `./sprint.sh newtask`; used for time audits.
- **Docs** — a guide the implementer should follow, e.g. `docs/guides/script-template-sync.md`. `none` if there is none.
- **Depends on** — task IDs that must be finished before this one can start.
- **Blocks** — task IDs that cannot proceed until this one is done.
- **Parent** — a task that groups this one with related work.

### Problem Section

Write the problem as a short user story — who is affected, what they can't do today, and why it matters. Loose Gherkin (Given/When/Then) is welcome but not required. 2-5 sentences, plain English, as you'd explain it to a colleague unfamiliar with this area.

### Success Criteria Section

Write observable behaviors that anyone can verify. This is the yardstick the audit measures against, so make "done" unambiguous. Phrase each criterion as the desired path (see **Instruct positively** above) — what a user can do or what the system does — not a list of things to avoid.

Patterns that work:
- "User can [do what]"
- "App shows [result]"
- "[Action] completes within [time]"

Example:
```markdown
## Success criteria
- [ ] User can log in with email and password
- [ ] Error message appears when password is wrong
- [ ] Session persists across browser refresh
```

### Notes Section

Every relevant detail that helps build the solution fast and knowingly: decisions already made, constraints, edge cases, gotchas. Leave empty if there is nothing to add.

### References Section

Direct files that help build this — existing code to **reuse rather than reinvent**, plus specs and examples. One path per line. This is also what an audit checks for design fit, so name the files you already know are involved.

Example:
```markdown
## References
docs/sprintmd/lib.sh — sed helpers, reuse for placeholder substitution
docs/sprintmd/scripts/create-task.sh — existing pattern to follow
docs/features/task-automation.md — spec this serves
```

## Verify Before Saving

1. Someone unfamiliar with the codebase can understand the problem
2. Success criteria describe observable behaviors an auditor could check
3. Success criteria and notes state the desired path — no prohibition-shaped rule list
4. Header fields set what applies (Feature, Docs, Depends on, Blocks)
5. References name existing files to reuse; technical HOW lives in `docs/guides/`, `docs/examples/`, or `docs/features/`, not inlined here
