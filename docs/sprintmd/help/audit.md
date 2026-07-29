Audit tasks for quality.

Usage:
  ./sprint.sh audit                    # audit tasks in next/
  ./sprint.sh audit backlog            # audit backlog tasks
  ./sprint.sh audit backlog 5          # audit at most 5
  ./sprint.sh audit backlog 5 10       # start at offset 10

Folders: next (default), backlog, doing, blocked.
Review and done are not auditable (completed work).

Verdicts and actions (non-interactive):
  DONE      → moved to review/
  OUTDATED  → deleted
  UNDEFINED → marked and moved to blocked/
  KEEP      → left in place

Related commands (how they differ):
  audit   — this command: fast, non-interactive bulk cleanup of stale work.
  triage  — the interactive form: same DONE/BLOCKED/UNDEFINED/READY/STALE
            assessment, but you decide per task (work/define/kill/skip).
  define  — a deeper, per-task pre-sprint review of next/ that writes the
            ## Questions readiness gate ./sprint.sh tasks enforces. Run define
            (not audit) before executing a sprint.
