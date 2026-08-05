#!/usr/bin/env bash
set -euo pipefail

# create-test.sh — Create a test loop. See: ./sprint.sh help newtest

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

NAME="${1:-}"
if [ -z "$NAME" ]; then
    echo "Usage: $0 \"What you're testing\""
    echo ""
    echo "Examples:"
    echo "  $0 \"Signup converts cold visitors\""
    echo "  $0 \"Users finish onboarding unaided\""
    exit 1
fi

# Convert to a filename-safe slug; reject names with no slug-able text.
KEBAB=$(sprintbias_slug "$NAME") || {
    echo -e "${RED}ERROR: Name has no letters or numbers to build a filename from.${NC}"
    exit 1
}

TEST_FILE="docs/tests/${KEBAB}.md"

# Honest collision: name the resulting slug. If the name was truncated
# (sprintbias_slug printed a note above), the user sees the two together —
# two long names can collapse to the same 50-char slug.
if [ -f "$TEST_FILE" ]; then
    echo -e "${YELLOW}WARNING: Test '$KEBAB' already exists at $TEST_FILE${NC}"
    exit 1
fi

TEMPLATE_FILE="docs/tests/.TEMPLATE-test.md"
copy_template "$TEMPLATE_FILE" "$TEST_FILE" || exit 1

CREATED_DATE=$(date +%Y-%m-%d)

sed_inplace "s/\[TEST-NAME\]/$(sed_escape "$NAME")/g" "$TEST_FILE"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "$TEST_FILE"

# Stage the change (skip gracefully if not in a git repo)
git add "$TEST_FILE" 2>/dev/null || true

echo -e "${GREEN}Created test: $TEST_FILE${NC}"
echo ""
echo "Next: Sharpen what you're testing, run it your way, then file follow-ups with newfeature or newtask."
