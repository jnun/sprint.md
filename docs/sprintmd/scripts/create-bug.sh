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
KEBAB_CASE_DESC=$(sprintmd_slug "$DESCRIPTION") || {
    echo -e "${RED}ERROR: Description has no letters or numbers to build a filename from.${NC}"
    echo "Provide a description with at least one alphanumeric character."
    exit 1
}

# Serialize ID allocation so concurrent creates never draw the same ID.
sprintmd_lock

# Read highest bug ID and increment with error handling
NEW_ID=$(alloc_id sprint_BUG_ID 'docs/bugs/[0-9]*-*.md') || {
    echo -e "${RED}ERROR: Invalid or missing bug ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintmd/DOC_STATE.md manually. Expected format: '**sprint_BUG_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$KEBAB_CASE_DESC")

# No bug file may already own this ID, whatever its slug. alloc_id reconciles
# the counter with disk, so this should never fire — if it does, DOC_STATE.md
# is corrupt or two files share a numeric prefix by hand.
# Glob-loop (not `ls | head`) so an unmatched pattern can't trip pipefail.
DUP=""
for existing in docs/bugs/"${NEW_ID}"-*.md; do
    [ -e "$existing" ] && { DUP="$existing"; break; }
done
if [ -n "$DUP" ]; then
    echo -e "${RED}ERROR: bug ID ${NEW_ID} already exists: ${DUP}${NC}"
    echo "DOC_STATE.md's sprint_BUG_ID is out of sync with the files on disk."
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
sprintmd_unlock
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
