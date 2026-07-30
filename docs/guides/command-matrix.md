# Command Matrix

How every sprint.md command earns its name.

A command that won't sit in one cell is the wrong command — fix the command,
not the matrix. This file is the **target-state spec**. When live behavior and
this document disagree, this document wins: file a backlog task, don't edit
the target back down.

---

## The loop this surface exists to run

```
chat  →  plan start  →  work  →  polish
 │            │            │         │
 human      commit      automate   quality
 decides    to next/    the queue  after
```

Human judgment injects at **chat**. Logic and automation carry **plan**,
**work**, and **polish**. `loop` is the same spine on autopilot
(`plan start` refill + `work` drain). Everything else is mint, look, or keep.

---

## Two primitives

Prefix		Primitive	Meaning				Output
new*		Create		Mint a scaffold.	A new file, unfilled.
bare verb	Act			Run a process.		Work moved, or read.

`new` is a reserved namespace. Only creators wear it. Everything else is a
verb that does something. Family names **are** the archetype commands —
no abstract layer to translate.

---

## Five act families

Family	Interaction				Touches
chat	Human in the loop, Q&A	One item, one folder, or the board
plan	Decisive compose		The sprint (`next/` is the sprint)
work	Autonomous transform	Tasks in motion
look	Read-only				Surfaces state, no mutation
keep	Housekeeping			Integrity, config, sync, deps

**`chat` shapes. `plan` acts. `work` does.**

- A plan is scaffolded by `newplan`, authored by **`chat plan`**, then acted on
  by decisive plan verbs: `plan think` (automated dual-persona critique),
  `plan start` (commit members into `next/`, gating as it promotes).
- There is no bare conversational `plan`. Authoring lives in `chat` so one
  engine owns every human-in-the-loop walk.
- The unit of work stays a **task** (file under `docs/tasks/`, created by
  `newtask`). `work` is the *verb* that executes READY tasks — not a rename of
  the noun.

---

## Target catalog

Only target names. No archaeology in this table.

### Create — `new*`

Command		Mints
newidea		Idea to refine
newfeature	Feature spec
newtask		Task (the unit of work)
newplan		Plan (named list of task IDs)
newbug		Bug report (inbox)
newtest		Test loop for a deployed thing

### chat — shape with a human

Command		Does
chat \<id\>		Define / refine / split one task in conversation
chat \<folder\>	Sweep backlog / next / blocked — verdict-first sort
chat plan [id]	Author or refine a plan (plan id; bare = pick one)
chat bugs		Sweep bug inbox → convert or kill
chat			Walk sprint structural health (next/ + blocked/)

One conversational engine. Target chooses depth; the method is always
Probe → Ground → Recommend → Open the floor. Decisions land in the durable
artifact, never only in the chat.

### plan — compose the sprint

Command		Does
plan think [id]	Automated dual-persona critique of a plan
plan start [id]	Gate members and commit them into `next/`

`next/` **is** the sprint. A plan file never moves; only member tasks do.

### work — autonomous transform

Command		Does
work [limit]	Execute READY tasks in next/ → review/
loop			Autopilot: plan start refill + work drain
gate [folder]	READY-gate next/ (default), or quality report on another folder
split \<path\>	One-shot: one large task → atomic children (no conversation)
polish …		Post-work quality: sweep review/, deep-judge a file, or --code

Happy path: `plan start` → `work`. `plan start` already gates on commit, so
`gate` is off-spine — re-gate after edits, or report on backlog/doing/blocked.
`loop --refill` starts the next READY plan when next/ empties; no separate
gate step on that spine.

`polish` is the one post-work quality surface (sweep / deep-judge / code fix).
Argument shape selects the mode; do not re-split it into sibling commands.

### look — read, don't mutate

Command		Does
status			Board counts, blocked, in-progress, features, bugs
search \<kw\>		Find tasks by keyword
align			Feature ↔ task alignment
context			Project summary for an AI session

`status` stays a noun on purpose — universal CLI habit (`git status`), zero
translation cost. The other three are short verbs or plain nouns that read as
actions when typed.

### keep — housekeep

Command		Does
profile			Create or update project conventions (interactive)
profile show	Print profile, no AI
sync			Push task changes to GitHub
validate		Integrity: IDs, edges, help/docs/commands surface
cleanup			Clear stale scratch files
deps			Scan package ecosystems; file one backlog task on upgrades/advisories

---

## Placement rules

If the command...				Then it is...
mints a scaffold file			new* — nothing else wears new
puts a human in the loop		chat (or a chat target)
assembles or commits next/		plan (think or start)
runs or transforms tasks alone	work family
reads without mutating			look
touches integrity/config/sync	keep
overlaps a sibling's job		roll into the sibling — don't add a command
needs two families				split into two commands
fits no family					it's a flag, not a command
carries a profession word		retire the word (`audit`, `excellence`, `review-` as command names)

Registry groups, help sections, and this matrix use the **same six labels**:
`create · chat · plan · work · look · keep`. No parallel taxonomy
(pipeline / workflow / maint / …).

---

## Retired names

Dispatch labels below are **deleted outright** — no runtime redirect. Typing a
retired name falls through to generic help. Listed so none return, and so each
behavior's home stays findable.

Old name		Successor				Why it's gone
talk			chat					chat is mutual; talk is one-way / TTS-adjacent
tasks			work					work is the execute verb; task stays the noun
define			gate					honest name for the READY-gate; matches "plan start gates"
checkfeatures	align					verb; feature↔task alignment
ai-context		context					plain word, same job
audit-deps		deps					drop the auditor persona; still files one dep task
sprint (cmd)	plan					"sprint" is a concept — next/ IS the sprint
triage			chat · chat \<folder\>	folded into the conversational engine
find			chat \<id\> · work		stress-test absorbed by chat
review-sprint	plan think				plain plan sub-form
newepic			newplan					"epic" jargon → plan grouping
audit			gate					task-quality is the gate
excellence		polish					post-work quality unifies in polish
review-code		polish --code			code-diff mode of polish

A retired name never returns as a command.

---

## What this is not

- **Not a rename of the task noun.** Files stay under `docs/tasks/`. Creators
  stay `newtask`. Lifecycle folders stay `backlog → next → doing → review →
  done` (+ `blocked`). Only the *execute command* is `work`.
- **Not a second conversational surface.** If it needs a human turn-by-turn,
  it is `chat` or it is wrong.
- **Not a profession kit.** No command teaches the agent to "be an auditor,"
  "run excellence," or "do a code review." Quality verbs are `gate` and
  `polish`; dependency scanning is `deps`.

---

## Live surface lag

When `./sprint.sh help` still shows old labels, the matrix is ahead on purpose.
Close the gap with backlog work driven by the retired-names table — one rename
pass per row if needed, registry + dispatch + help + manual + AI guidance
together so the validator stays green.
