#!/usr/bin/env bash
# profile.sh — AI-guided project profile. See: ./sprint.sh help profile

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROFILE_FILE="$PROJECT_ROOT/docs/sprintmd/project.md"

_MODEL="$(fiveday_resolve_model PROFILE)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

# ── Build prompt based on whether profile exists ─────────────────────

if [ -f "$PROFILE_FILE" ]; then
  echo "▸ Updating existing profile: docs/sprintmd/project.md"
  MODE_INSTRUCTION="An existing project profile is at: docs/sprintmd/project.md — read it first.
Then ask the user what has changed. Walk through each field briefly:
- Is this still accurate? Anything to add or update?
Keep it conversational — skip fields the user confirms are fine.
Update the file in place when done."
else
  echo "▸ Creating project profile: docs/sprintmd/project.md"
  MODE_INSTRUCTION="No project profile exists yet. You will create one at: docs/sprintmd/project.md

Start by scanning the project to auto-detect what you can:
- Look at file extensions to determine the primary language
- Read package.json, Cargo.toml, go.mod, pyproject.toml, Gemfile, pom.xml, or similar manifests for framework and dependencies
- Check for .eslintrc, .prettierrc, rustfmt.toml, .editorconfig, or similar for style conventions
- Look for test directories, jest.config, vitest.config, pytest.ini, or similar for test strategy
- Scan a few source files to understand error handling patterns and directory structure

Then present what you found and ask the user to confirm or correct each item.
Only ask about things you could not detect. Most projects need 2-3 confirmations, not 8 questions."
fi

APPEND_PROMPT="You are helping a developer create a project profile that will be injected into every AI-powered task session.

$MODE_INSTRUCTION

THE PROFILE COVERS THESE FIELDS (detect what you can, ask about the rest):
- **Language:** Primary language(s)
- **Framework:** Framework or stack
- **Tests:** Test runner, where tests live, unit vs integration patterns
- **Style:** Linting and formatting tools, enforcement method
- **Error handling:** How errors are handled (Result types, exceptions, error codes, etc.)
- **Structure:** Key directories and what lives where
- **Patterns:** Important architectural patterns or conventions

HOW TO CONDUCT THE SESSION:
1. Read the project files to auto-detect as much as possible.
2. Present your findings as a draft profile.
3. Ask the user to confirm, correct, or add to each field. Ask ONE round of questions, not one-at-a-time.
4. Write the final profile to docs/sprintmd/project.md.

OUTPUT FORMAT — flat, one screen, no nested sections:
\`\`\`
# Project Profile
**Language:** ...
**Framework:** ...
**Tests:** ...
**Style:** ...
**Error handling:** ...
**Structure:** ...
**Patterns:** ...
\`\`\`

RULES:
- Keep it concise. Each field should be 1-2 lines.
- The profile describes the project, not individual preferences.
- You may only write to docs/sprintmd/project.md. Do not modify any other files.
- After writing the file, tell the user it's done and that all AI commands will now use it."

fiveday_run \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --name "profile" \
  "Read the project files and start the profile session."
