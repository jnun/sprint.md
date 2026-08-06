Create a new task in docs/tasks/backlog/.

Usage:
  ./sprint.sh newtask "Add login endpoint"
  ./sprint.sh newtask "Add login endpoint" user-auth

Pass an optional feature name as the second argument to set the task's
**Feature** field to /docs/features/<name>.md.

Tasks get an auto-assigned ID and are built from a battle-tested
template. The file is created ready to edit — fill in **Problem** (high-level
what is wrong) and **Success criteria** (what done looks like) yourself, or
run `./sprint.sh chat <id>` to develop them conversationally. Notes and
References are optional hints and paths; how to implement is the developer's
call.

The header stamps **Plan** (which `docs/plans/N-…` this belongs to),
**Depends on** (prerequisite task IDs), **Dependents** (the reverse edge —
task IDs that wait on this one), and **Tests** (suite scripts that prove the
success criteria for `promote`), all defaulting to `none`.

**Dependents** is the reverse of **Depends on**, not the `blocked/` folder.
**Docs** is what you read while building; **Tests** is what `promote` runs to
close (`docs/tests/*.sh` only — not product `newtest` loops).

Legacy aliases (read only): **Blocks** → **Dependents**, **Proven by** → **Tests**.
