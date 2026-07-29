# Feature: Folder-Based Project Management

## Feature Status: DONE

The folder-based project management system is fully implemented and operational.

## Core Workflow
**Status**: DONE
Tasks and features are managed through a folder-based system where the location of a file determines its current state. This creates a visual, intuitive workflow that requires no database or external tools.

## Five-State Task Pipeline
**Status**: DONE
Tasks move through exactly five states, each represented by a folder:
- `backlog/` = **BACKLOG** - Identified tasks not ready for sprint
- `next/` = **NEXT** - Defined work for upcoming sprint
- `doing/` = **DOING** - Task being actively developed
- `review/` = **REVIEW** - Complete, needs approval
- `done/` = **DONE** - Approved and ready for production

## State-Status Alignment
**Status**: DONE
Folder names and feature statuses use identical terminology for consistency:
- Folder location = Feature status
- No translation needed between systems
- Universal across documentation and GitHub

## Git-Based History
**Status**: DONE
All task movements are tracked through git commits:
- `git mv` preserves complete task history
- Changes are atomic and reversible
- Audit trail maintained automatically

## Plain Text Storage
**Status**: DONE
All project management data stored as markdown files:
- No database required
- Works offline
- Version controlled
- Searchable with standard tools
- Portable across systems

## Automated ID Management
**Status**: DONE
Sequential task IDs managed through `docs/sprintmd/DOC_STATE.md`:
- Automatic ID assignment
- No ID collisions
- Simple integer sequence
- Central tracking file

## Sprint Planning
**Status**: DONE
Sprint planning through folder movements:
- Move tasks from `backlog/` to `next/` for sprint queue
- Limit tasks in `doing/` for WIP management
- Clear visibility of sprint scope

## Review Gate
**Status**: DONE
Mandatory review stage before production:
- All tasks must pass through `review/`
- Approval required to move to `done/`
- Quality control checkpoint
- Prevents direct backlog-to-done jumps