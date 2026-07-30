#!/usr/bin/env bash
# create-task.sh — Create a task. See: ./sprint.sh help newtask
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Verify DOC_STATE.md exists and is valid
if [ ! -f "docs/sprintmd/DOC_STATE.md" ]; then
    echo -e "${RED}ERROR: docs/sprintmd/DOC_STATE.md not found!${NC}"
    echo "Run ./setup.sh first to initialize the project."
    exit 1
fi

# Get the task description from the command line argument
DESCRIPTION="${1:-}"
if [ -z "$DESCRIPTION" ]; then
  echo "Usage: $0 \"Brief description of the task\" [feature-name]"
  echo ""
  echo "Examples:"
  echo "  $0 \"Fix login bug\""
  echo "  $0 \"Add user authentication\" user-auth"
  exit 1
fi

# Optional feature name
FEATURE="${2:-}"

# Convert to a filename-safe slug; reject descriptions with no slug-able text.
KEBAB_CASE_DESC=$(sprintmd_slug "$DESCRIPTION") || {
    echo -e "${RED}ERROR: Description has no letters or numbers to build a filename from.${NC}"
    echo "Provide a description with at least one alphanumeric character."
    exit 1
}

# Serialize ID allocation so concurrent creates never draw the same ID.
sprintmd_lock

# Read highest task ID and increment with error handling
NEW_ID=$(alloc_id sprint_TASK_ID) || {
    echo -e "${RED}ERROR: Invalid or missing task ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintmd/DOC_STATE.md manually. Expected format: '**sprint_TASK_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$KEBAB_CASE_DESC")

# A file for this fresh ID should never exist. If it does, DOC_STATE.md's
# counter is behind the files on disk — say so honestly rather than blaming
# an imaginary racing process (the lock above rules that out).
if [ -f "docs/tasks/backlog/$FILENAME" ]; then
    echo -e "${RED}ERROR: docs/tasks/backlog/$FILENAME already exists!${NC}"
    echo "DOC_STATE.md's sprint_TASK_ID may be out of sync with the files on disk."
    exit 1
fi

# Read template and substitute placeholders
TEMPLATE_FILE="docs/tasks/.TEMPLATE-task.md"
copy_template "$TEMPLATE_FILE" "docs/tasks/backlog/$FILENAME" || exit 1

if [ -n "$FEATURE" ]; then
    FEATURE_LINE="**Feature**: /docs/features/${FEATURE}.md"
else
    FEATURE_LINE="**Feature**: none"
fi

CREATED_DATE=$(date +%Y-%m-%d)

sed_inplace "s/\[ID\]/$NEW_ID/g" "docs/tasks/backlog/$FILENAME"
sed_inplace "s/\[Brief Description\]/$(sed_escape "$DESCRIPTION")/g" "docs/tasks/backlog/$FILENAME"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "docs/tasks/backlog/$FILENAME"
if [ -n "$FEATURE" ]; then
    sed_inplace "s/\*\*Feature\*\*: none/$(sed_escape "$FEATURE_LINE")/g" "docs/tasks/backlog/$FILENAME"
fi

# Update DOC_STATE.md in place — only touch the fields that changed
LAST_UPDATED=$(date +%F)
bump_doc_state sprint_TASK_ID "$NEW_ID"
bump_doc_state "Last Updated" "$LAST_UPDATED"
sprintmd_unlock
echo -e "${GREEN}✓ DOC_STATE.md updated successfully${NC}"

# Verify task file was created successfully
if [ ! -f "docs/tasks/backlog/$FILENAME" ]; then
    echo -e "${RED}ERROR: Task file was not created${NC}"
    exit 1
fi

# Stage the changes (skip gracefully if not in a git repo)
git add docs/sprintmd/DOC_STATE.md "docs/tasks/backlog/$FILENAME" 2>/dev/null || true

echo -e "${GREEN}Created task: docs/tasks/backlog/$FILENAME${NC}"
echo ""
echo "Next: Edit the file to define the problem and success criteria."
