# Feature: Sprint Planning

## Feature Status: DONE

Sprint planning capabilities through folder-based workflow management.

## Sprint Queue Management
**Status**: DONE
The `docs/tasks/next/` folder serves as the sprint queue:
- Tasks moved from backlog to next for sprint planning
- Clear visibility of sprint scope
- Prioritized work for current/upcoming sprint

## Work-in-Progress Limiting
**Status**: DONE
The `docs/tasks/doing/` folder enforces WIP limits:
- Keep minimal tasks in doing (ideally one per developer)
- Prevents context switching
- Forces completion before starting new work

## Backlog Grooming
**Status**: DONE
The `docs/tasks/backlog/` folder for unprioritized work:
- All new tasks start here
- Regular review for prioritization
- Move to next/ when ready for sprint

## Sprint Review Process
**Status**: DONE
The `docs/tasks/review/` folder enables sprint reviews:
- Completed work awaiting approval
- Quality gate before production
- Feedback incorporation point

## Sprint Completion
**Status**: DONE
The `docs/tasks/done/` folder marks sprint deliverables:
- Successfully delivered features
- Production-ready code
- Sprint goals achieved

## Git-Based Planning
**Status**: DONE
All sprint planning tracked through git:
- `git mv` for moving tasks between sprints
- Complete history of sprint decisions
- Reversible sprint planning changes