#!/usr/bin/env bash
set -euo pipefail

# create-bug.sh — Report a bug. See: ./sprint.sh help newbug

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Verify DOC_STATE.md exists and is valid
if [ ! -f "docs/sprintmd/DOC_STATE.md" ]; then
    echo -e "${RED}ERROR: docs/sprintmd/DOC_STATE.md not found!${NC}"
    echo "Run ./setup.sh first to initialize the project."
    exit 1
fi

# Get the bug description from the command line argument
DESCRIPTION="${1:-}"
if [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 \"Brief description of the bug\""
    echo ""
    echo "Examples:"
    echo "  $0 \"Login button unresponsive on mobile\""
    echo "  $0 \"Dashboard shows wrong date format\""
    exit 1
fi

# Convert to a filename-safe slug; reject descriptions with no slug-able text.
KEBAB_CASE_DESC=$(fiveday_slug "$DESCRIPTION") || {
    echo -e "${RED}ERROR: Description has no letters or numbers to build a filename from.${NC}"
    echo "Provide a description with at least one alphanumeric character."
    exit 1
}

# Serialize ID allocation so concurrent creates never draw the same ID.
fiveday_lock

# Read highest bug ID and increment with error handling
NEW_ID=$(alloc_id sprint_BUG_ID) || {
    echo -e "${RED}ERROR: Invalid or missing bug ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintmd/DOC_STATE.md manually. Expected format: '**sprint_BUG_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$KEBAB_CASE_DESC")

# A file for this fresh ID should never exist. If it does, DOC_STATE.md's
# counter is behind the files on disk — say so honestly rather than blaming
# an imaginary racing process (the lock above rules that out).
if [ -f "docs/bugs/$FILENAME" ]; then
    echo -e "${RED}ERROR: docs/bugs/$FILENAME already exists!${NC}"
    echo "DOC_STATE.md's sprint_BUG_ID may be out of sync with the files on disk."
    exit 1
fi

# Read template and substitute placeholders
TEMPLATE_FILE="docs/bugs/.TEMPLATE-bug.md"
copy_template "$TEMPLATE_FILE" "docs/bugs/$FILENAME" || exit 1

CREATED_DATE=$(date +%Y-%m-%d)

sed_inplace "s/\[ID\]/$NEW_ID/g" "docs/bugs/$FILENAME"
sed_inplace "s/\[Brief Description\]/$(sed_escape "$DESCRIPTION")/g" "docs/bugs/$FILENAME"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "docs/bugs/$FILENAME"

# Update DOC_STATE.md in place — only touch the fields that changed
LAST_UPDATED=$(date +%F)
bump_doc_state sprint_BUG_ID "$NEW_ID"
bump_doc_state "Last Updated" "$LAST_UPDATED"
fiveday_unlock
echo -e "${GREEN}✓ DOC_STATE.md updated successfully${NC}"

# Verify bug file was created successfully
if [ ! -f "docs/bugs/$FILENAME" ]; then
    echo -e "${RED}ERROR: Bug file was not created${NC}"
    exit 1
fi

# Stage the changes (skip gracefully if not in a git repo)
git add docs/sprintmd/DOC_STATE.md "docs/bugs/$FILENAME" 2>/dev/null || true

echo -e "${GREEN}Created bug: docs/bugs/$FILENAME${NC}"
echo ""
echo "Next: Fill in the severity, problem description, and steps to reproduce."
