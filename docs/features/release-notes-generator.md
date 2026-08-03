# Feature: Release Notes Generator

**Status:** BACKLOG
**Created:** 2026-06-22
**Updated:** 2026-06-22

## Overview

A release notes generator that pulls completed sprint tasks into a dated, plain-language release notes file under `docs/releases/`. Partners and end-users can see what was added, changed, or fixed in each release without reading technical details.

## User Stories

- As a developer, I want to generate release notes from my completed sprint tasks so that partners and end-users can see what changed without reading technical details.
- As a developer, I want release notes stored as dated files in `docs/releases/` so I have a historical record of every release.

## Requirements

### Functional Requirements

- [ ] A `./sprint.sh release-notes` command that collects done tasks from the current sprint
- [ ] Groups entries by type: Added, Changed, Fixed
- [ ] Writes a dated file to `docs/releases/` (e.g., `2026-06-22.md`)
- [ ] Uses plain, non-technical language drawn from task descriptions
- [ ] One file per release — previous release files are not modified

### Non-Functional Requirements

- [ ] Output is readable by non-developers (partners, end-users)
- [ ] Follows the existing SprintBias file-based, no-dependencies philosophy

## Technical Design

### Architecture

<!-- High-level approach. Keep it brief until implementation begins. -->



### Dependencies

<!-- Other features, services, or libraries this requires. -->

-

### API/Interface

<!-- Public interfaces this feature exposes, if any. -->



## Implementation Tasks

<!-- Link tasks as they're created. Pattern: Task #ID - Brief description -->

- [ ]

## Testing Strategy

### Test Cases

<!-- Key scenarios to verify. -->

- [ ]

### Acceptance Criteria

- [ ] Running `./sprint.sh release-notes` produces a release notes file in `docs/releases/`
- [ ] The file groups entries under Added / Changed / Fixed headings
- [ ] Language is plain and user-facing, not developer jargon
- [ ] Previous release files are not modified when a new release is generated

## Documentation

<!-- Track documentation needs. -->

- [ ] User-facing docs
- [ ] Technical docs

## Notes

### Future Ideas

- Push/publish integration with an external documentation API or notification channel
- Two-way feedback loop allowing end-users to submit bugs, ideas, and problems back to developers
- AI-assisted analysis of user feedback for direct improvement cycles

<!--
AI: Full feature-writing guidance is in docs/sprintmd/ai/feature-creation.md
-->
