# AI Feature Documentation Protocol

## Core Principle

**Write in plain English throughout. Focus on what users experience.** Technical details can wait until implementation begins.

## Status Values

`BACKLOG` → `DOING` → `DONE`

## Writing a Good Feature Document

### Overview

2-3 sentences explaining what this feature is and why it matters. Write for someone unfamiliar with the project.

### User Stories

Capture real user needs using the pattern:
- "As a [who], I want [what], so that [why]"

### Requirements

Each functional requirement should be testable. Non-functional requirements cover performance, security, accessibility, etc.

### Acceptance Criteria

Write observable behaviors that confirm the feature works:
- "User can export data as CSV"
- "Dashboard loads within 2 seconds"
- "Error message appears when form is invalid"

## Implementation Tasks

Link tasks as they're created using: `Task #ID - Brief description`

Create tasks with `./sprint.sh newtask "Description"` and reference this feature in the task's Notes section.
