#!/usr/bin/env bash
# profile.sh — AI-guided project profile. See: ./sprint.sh help profile
#
# profile        — interactive create/update of docs/sprintbias/project.md
# profile show   — print the current profile (or how to create one); no AI

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROFILE_FILE="$PROJECT_ROOT/docs/sprintbias/project.md"
PROFILE_REL="docs/sprintbias/project.md"

# Shared scan instructions — create and update both auto-detect the stack.
# Update mode diffs that draft against the existing profile and surfaces drift.
SCAN_INSTRUCTION="Start by scanning the project to auto-detect what you can:
- Look at file extensions to determine the primary language
- Read package.json, Cargo.toml, go.mod, pyproject.toml, Gemfile, pom.xml, or similar manifests for framework and dependencies
- Check for .eslintrc, .prettierrc, rustfmt.toml, .editorconfig, or similar for style conventions
- Look for test directories, jest.config, vitest.config, pytest.ini, or similar for test strategy
- Scan a few source files to understand error handling patterns and directory structure"

# ── Arg parsing ──────────────────────────────────────────────────────
# profile [show] | profile --help
# Unknown args print usage and exit 1 so a typo never silently starts AI.
usage() {
  cat <<'EOF'
Usage:
  ./sprint.sh profile           # create or update project profile (interactive AI)
  ./sprint.sh profile show      # print current profile (no AI)

Options:
  --help, -h    Show this help
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "show" ]; then
  if [ -f "$PROFILE_FILE" ]; then
    cat "$PROFILE_FILE"
    exit 0
  fi
  echo "No project profile yet."
  echo "Run:  ./sprint.sh profile"
  echo "to create one at $PROFILE_REL"
  exit 0
fi

if [ -n "${1:-}" ]; then
  echo -e "${RED}Unknown argument: $1${NC}" >&2
  usage >&2
  exit 1
fi

# ── Interactive create / update ──────────────────────────────────────

_MODEL="$(sprintbias_tier_model PROFILE)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

if [ -f "$PROFILE_FILE" ]; then
  echo "▸ Updating existing profile: $PROFILE_REL"
  MODE_INSTRUCTION="An existing project profile is at: $PROFILE_REL — read it first.

Then re-scan the project the same way you would for a first-time create:
$SCAN_INSTRUCTION

Build a draft profile from what you detect NOW. Diff it against the existing
$PROFILE_REL and surface drift proactively — do not only ask \"what changed?\"
Call out concrete signals, e.g.:
- a new or removed framework dependency in a manifest
- a new test config (pytest.ini, vitest.config, …)
- language/structure shifts visible from the tree

Walk fields that still match briefly (\"Language still looks like Go — OK?\").
Spend the conversation on detected drift and gaps you could not auto-fill.
Keep it conversational. Update the file in place when done."
else
  echo "▸ Creating project profile: $PROFILE_REL"
  MODE_INSTRUCTION="No project profile exists yet. You will create one at: $PROFILE_REL

$SCAN_INSTRUCTION

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
2. Present your findings as a draft profile (and, on update, call out drift vs the existing file).
3. Ask the user to confirm, correct, or add. Prefer ONE round of questions over one-at-a-time grilling — but answer any follow-ups they raise.
4. Write the final profile to $PROFILE_REL.

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
- You may only write to $PROFILE_REL. Do not modify any other files.
- After writing the file, tell the user it's done and that all AI commands will now use it."

# profile is a dialogue (confirm fields) — sprintbias_run_interactive keeps the
# CLI attached to the terminal so the user sees live activity and can answer.
# When a live session is not possible, degrade to one-shot and say so (same
# guard and wording pattern as chat.sh).
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live back-and-forth needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single profile pass instead. To wire up the full interactive experience,${NC}"
  echo -e "${YELLOW}see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
fi

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "profile" \
  "Read the project files and start the profile session."
