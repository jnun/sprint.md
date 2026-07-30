# Feature: Bug Tracking

## Feature Status: DONE

The bug tracking system captures open reports in a flat inbox and hands real
work off to the task pipeline.

## Bug Report Creation
**Status**: DONE
Bug reports can be created in `docs/bugs/` with sequential IDs and severity levels.

## Severity Classification
**Status**: DONE
Four severity levels for prioritization:
- CRITICAL: System down, data loss, security breach
- HIGH: Major feature broken, blocking users
- MEDIUM: Feature partially broken, has workaround
- LOW: Minor issue, cosmetic

## Bug-to-Task Conversion
**Status**: DONE
`./sprint.sh chat bugs` **[w] work it** converts a report into a fix task:
- Fills the task from the report (Problem, steps, success criteria, origin)
- Deletes the bug file (inbox holds open reports only)
- Fix tracks through the standard task workflow

## Bug State Management
**Status**: DONE
Automatic ID management through `docs/sprintmd/DOC_STATE.md`:
- Bug IDs tracked in unified state file
- Sequential integer IDs
- Prevents ID collisions

## Inbox (no archive)
**Status**: DONE
Handled reports leave the workspace:
- Convert → task + delete report
- Close / kill → delete report
- Open `docs/bugs/` is untriaged only

## Bug Report Format
**Status**: DONE
Standardized markdown template for consistency:
- Severity level
- Description and expected behavior
- Reproduction steps
- Success criteria
