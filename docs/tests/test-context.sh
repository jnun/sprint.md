#!/usr/bin/env bash
# Test: context.sh
# Tests AI context summary generation

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintmd/scripts" && pwd)/context.sh"
SPRINTMD_SRC="$(cd "$(dirname "$0")/../sprintmd" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # context.sh uses PROJECT_ROOT = three dirs up from SCRIPT_DIR
    mkdir -p "$TMPDIR/docs/sprintmd/scripts"
    mkdir -p "$TMPDIR/docs/tasks/backlog"
    mkdir -p "$TMPDIR/docs/tasks/next"
    mkdir -p "$TMPDIR/docs/tasks/doing"
    # blocked/ is a standard stage folder; the script's Suggested-Action block
    # runs `find docs/tasks/blocked` unguarded under pipefail, so its absence
    # (not its emptiness) would make the script exit non-zero.
    mkdir -p "$TMPDIR/docs/tasks/blocked"
    mkdir -p "$TMPDIR/docs/ideas"
    mkdir -p "$TMPDIR/docs/bugs"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintmd/scripts/context.sh"
    # The script sources lib.sh (which loads a cli/ provider profile), so the
    # temp tree must carry both or the `source` line aborts under set -e.
    cp "$SPRINTMD_SRC/lib.sh" "$TMPDIR/docs/sprintmd/lib.sh"
    cp -R "$SPRINTMD_SRC/cli" "$TMPDIR/docs/sprintmd/cli"

    cat > "$TMPDIR/docs/sprintmd/DOC_STATE.md" << 'EOF'
# SprintBias Documentation State

**Last Updated**: 2026-01-01
**sprint_VERSION**: 2.2.0
**sprint_TASK_ID**: 10
**sprint_BUG_ID**: 1
EOF
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

# --- Tests ---

echo "=== test-context.sh ==="

# Test 1: Shows context summary header
echo "Test 1: Shows context summary header"
setup
output=$(bash "$TMPDIR/docs/sprintmd/scripts/context.sh" 2>&1)
assert_contains "Header present" "$output" "# Project Context Summary"

# Test 2: Shows DOC_STATE.md content
echo "Test 2: Shows DOC_STATE.md content"
assert_contains "DOC_STATE content" "$output" "sprint_TASK_ID"

# Test 3: Shows section headers
echo "Test 3: Shows section headers"
assert_contains "Active Tasks" "$output" "## Active Tasks"
assert_contains "Up Next" "$output" "## Up Next"
assert_contains "Ideas" "$output" "## Ideas"
assert_contains "Recent Bugs" "$output" "## Recent Bugs"
assert_contains "Suggested Action" "$output" "## Suggested Action"

# Test 4: Empty project suggests checking backlog
echo "Test 4: Empty project suggests checking backlog"
assert_contains "Suggests backlog" "$output" "backlog"

# Test 5: Working task changes suggestion
echo "Test 5: Working task focuses on active work"
setup
echo "# Task 1: Test" > "$TMPDIR/docs/tasks/doing/1-test.md"
output=$(bash "$TMPDIR/docs/sprintmd/scripts/context.sh" 2>&1)
assert_contains "Suggests completing active" "$output" "completing the active task"

# Test 6: Next task (no doing) suggests picking from next
echo "Test 6: Next tasks suggest picking from next"
setup
echo "# Task 2: Next" > "$TMPDIR/docs/tasks/next/2-next.md"
output=$(bash "$TMPDIR/docs/sprintmd/scripts/context.sh" 2>&1)
assert_contains "Suggests picking from next" "$output" "Pick a task from"

# Test 7: Missing DOC_STATE.md handled gracefully
echo "Test 7: Missing DOC_STATE.md shows fallback"
setup
rm "$TMPDIR/docs/sprintmd/DOC_STATE.md"
output=$(bash "$TMPDIR/docs/sprintmd/scripts/context.sh" 2>&1)
assert_contains "Shows not found" "$output" "DOC_STATE.md not found"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
