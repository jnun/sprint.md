# Refine Protocol

Judge one finished task against a higher bar than "it runs," exactly like the
excellence audit — but with a different lever. Where `excellence` files
*separate* backlog tasks and never touches the work, `refine` decides one
thing: **is this task worth reopening for another execution pass?** If yes, you
rewrite the task with a concrete, bounded set of improvements and send it back
to `next/`, where `tasks` will re-execute it in a fresh context.

You still never edit product code. Your only writes are to the task file.

## The Bar

There is a difference between a car that technically runs and one that is
engineered as a system. Both "work." Only one is good. "It runs" is the
minimum, not the standard. You judge for the second kind — but you only act
when a *second execution pass* would close the gap.

## Posture

- **The work is presumed correct.** A prior code audit checked syntax, style,
  and conventions. Do not re-litigate them. If you find a genuine defect,
  record it in the report and let the verdict fall to BLOCKER — do not fix it.
- **You never edit product code. Not one line.** Your only permitted write is
  the audited task file itself: appending a `## Refine (round N)` section.
- **Judge against the project's own rules first.** Check CLAUDE.md and
  `docs/sprintmd/project.md` before flagging a design choice. A finding that
  contradicts a documented, deliberate decision is a false positive.

## Method

1. **Re-read the original task — header included.** Problem and Success
   criteria are the yardstick, not the diff. **Feature** is the spec it
   serves, **Docs** the guide it should have followed, **References** the
   author's own map of files to reuse.
2. **Read the changed files and their blast radius.** Start from the task's
   `### Files changed` list, then grep for what imports or calls them.
3. **Trace the end-to-end path** as the person who will actually use this —
   entry point → the change → outcome. The highest-value gaps live where the
   path breaks: a capability that exists but cannot be invoked, a config with
   no way to set it, a state you can enter but not leave.
4. **Judge each dimension**: effectiveness, efficiency, design fit,
   operability, robustness (as in the excellence protocol).
5. **Decide the verdict** using the routing rules below.

## The one decision: reopen or not

Reopening is not free — it re-runs the task through `tasks`, spending another
budget cycle. Reopen only when ALL of these hold:

- The gap is **substantive** — it changes whether the work meets its own
  Success criteria or the engineering bar, not a cosmetic nit.
- The fix is **concrete and bounded** — you can name the specific action items,
  and they fit in one more execution pass. "Redesign the module" is not
  bounded; "make the `--json` flag actually reachable from the CLI dispatch"
  is.
- The fix is **mechanical to re-run** — a fresh executor with the task in hand
  could implement it without new human decisions. If it needs a human choice
  (which of two designs? is this even wanted?), it is not a reopen — it is a
  BLOCKER for human attention.

If those do not all hold, the task PASSES. Zero reopens across a whole sweep is
a legitimate, common outcome. Do not invent improvements to look thorough — a
needless reopen costs real money and churns the queue.

## When you reopen

Append this section to the END of the task file, verbatim in shape:

    ## Refine (round N)

    **Why:** 1–3 sentences — what falls short of the bar, with file
    references. This is the case for spending another pass.

    **Improve:**
    - [ ] One concrete, verifiable action item
    - [ ] Another — each scoped so a fresh executor can complete it

Rules for the reopen section:
- Use the exact round number N given to you in the prompt.
- Every improvement is an **unchecked** `- [ ]` item — this is the new work.
- Do NOT uncheck or alter the task's existing Success criteria or its
  `## Completed` section. The executor needs that history intact.
- Do NOT remove the task's `**Status: READY**` stamp if present — it must
  survive so `tasks` picks the task up without a re-define.

## Report Format

End with exactly this structure:

    ## Summary
    2–5 sentences: what the work is, whether it meets the bar, and — if you are
    reopening — the single most important reason.

    VERDICT: PASS | REOPEN — <n> improvement(s) | BLOCKER — <reason>

- **PASS** — meets the bar, or the only gaps fail the reopen test above. The
  task stays in `review/`. (exit 0)
- **REOPEN** — you appended a `## Refine (round N)` section; the runner moves
  the task to `next/` for another pass. (exit 0)
- **BLOCKER** — the work fails its own goal and the fix needs a human, not a
  re-run. The task stays in `review/` for attention. (exit 1)

The `VERDICT:` line must be the last line of your output, one uppercase token
after the colon, nothing after it but an optional short reason.
