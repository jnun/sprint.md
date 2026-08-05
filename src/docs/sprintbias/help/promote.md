Test-gated close — the one automated way a task leaves `review/` for `done/`.

`work` finishes a task and moves it `doing/ → review/`. From there `done/` is a
human sign-off (`git mv review/… done/`). `promote` automates that last hop for
work that can prove itself: a task whose **Tests** field names suite scripts
that all run green closes itself; everything else waits for a human.

## The contract

Each task in `docs/tasks/review/` may name the suite scripts that prove it:

    **Tests**: docs/tests/test-plan-lifecycle.sh

- One path, or several (comma- or space-separated) — **all** must pass.
- Paths must live under `docs/tests/`. A path elsewhere is treated as a
  mis-authored field and the task stays put — promote never runs an arbitrary
  script.
- Product test *loops* (`./sprint.sh newtest` markdown) are not **Tests**.
- `none` (the template default) or no field → not automatable. The task stays
  in `review/` for human sign-off. Automation never guesses a task is done.
- Write **Tests**. Readers still accept legacy **Proven by** for one window.

**Docs** vs **Tests**: **Docs** is what you read while building; **Tests** is
what promote runs to close.

## What it does

For each task in `review/` (or just `[id]`):

1. Read **Tests** (or legacy **Proven by**). `none`/missing → skip (report it,
   leave in `review/`).
2. Run each named test (once per run, even if two tasks share it).
3. Every test green → `git mv review/… done/` (`|| mv`). Messaging may say
   “proven green”; the field name is still **Tests**.
   Any test failing, missing, or out-of-tree → stay in `review/`, report why.

After promoting, it names any plan whose every member now sits in `done/` so you
can retire it. Retirement stays explicit — promote never deletes a plan:

    ./sprint.sh plan done <id>

## Usage

    ./sprint.sh promote              # gate every review/ task with **Tests**
    ./sprint.sh promote 293          # only task #293
    ./sprint.sh promote --dry-run    # run the tests, report verdicts, move nothing

Exit 0 when nothing failed its test; 1 when a named test failed (those tasks
stay in `review/`). Tasks skipped for having no **Tests** do not fail the run.

## Related commands

    work    — execute READY tasks from next/ → review/ (produces promote's input)
    polish  — quality sweep of review/; reopen a task worth another pass
    plan done — retire a plan once every member reached done/ (promote points here)
    gate    — workability gate on next/ (a different gate, before work, not after)

See also: `docs/guides/running-tests.md` (platform suite ladder).
