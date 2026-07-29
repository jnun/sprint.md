#!/usr/bin/env bash
# Test: validate-tasks.sh
# Tests task file validation and auto-fix

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintmd/scripts" && pwd)/validate-tasks.sh"
SPRINTMD_SRC="$(cd "$(dirname "$0")/../sprintmd" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # validate-tasks.sh uses SCRIPT_DIR/../../.. as PROJECT_ROOT
    mkdir -p "$TMPDIR/docs/sprintmd/scripts"
    mkdir -p "$TMPDIR/docs/tasks/backlog"
    mkdir -p "$TMPDIR/docs/tasks/next"
    mkdir -p "$TMPDIR/docs/tasks/doing"
    mkdir -p "$TMPDIR/docs/tasks/review"
    mkdir -p "$TMPDIR/docs/tasks/done"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh"
    # The script sources lib.sh (task_id/task_title/move_file live there, and
    # lib.sh loads a cli/ provider profile), so the temp tree must carry both
    # or the `source` line aborts under set -e.
    cp "$SPRINTMD_SRC/lib.sh" "$TMPDIR/docs/sprintmd/lib.sh"
    cp -R "$SPRINTMD_SRC/cli" "$TMPDIR/docs/sprintmd/cli"
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

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Tests ---

echo "=== test-validate-tasks.sh ==="

# Test 1: No task files — exits 0
echo "Test 1: No tasks exits 0"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "All valid" "$output" "All task files are valid"

# Test 2: Valid task file — exits 0
echo "Test 2: Valid task exits 0"
setup
cat > "$TMPDIR/docs/tasks/backlog/1-test-task.md" << 'EOF'
# Task 1: Test task

**Feature**: none
**Created**: 2026-01-01

## Problem

Something needs fixing.

## Success criteria

- [ ] It works
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Valid exits 0" "0" "$rc"

# Test 3: Missing title format — exits 1
echo "Test 3: Bad title exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/2-bad-title.md" << 'EOF'
# Bad title

**Feature**: none

## Problem

Stuff.

## Success criteria

- [ ] Done
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Bad title exits 1" "1" "$rc"
assert_contains "Reports title issue" "$output" "Title must start with"

# Test 4: Missing Feature field — exits 1
echo "Test 4: Missing Feature field exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/3-no-feature.md" << 'EOF'
# Task 3: No feature

## Problem

Missing feature field.

## Success criteria

- [ ] Done
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Missing feature exits 1" "1" "$rc"
assert_contains "Reports missing Feature" "$output" "Missing required field"

# Test 5: Missing Problem section — exits 1
echo "Test 5: Missing Problem exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/4-no-problem.md" << 'EOF'
# Task 4: No problem

**Feature**: none

## Success criteria

- [ ] Done
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Missing Problem exits 1" "1" "$rc"
assert_contains "Reports missing Problem" "$output" "Missing required section: ## Problem"

# Test 6: Missing Success criteria — exits 1
echo "Test 6: Missing Success criteria exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/5-no-criteria.md" << 'EOF'
# Task 5: No criteria

**Feature**: none

## Problem

Something.
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Missing criteria exits 1" "1" "$rc"
assert_contains "Reports missing Success" "$output" "Missing required section: ## Success criteria"

# Test 7: --fix repairs a bad file
echo "Test 7: --fix repairs bad file"
setup
cat > "$TMPDIR/docs/tasks/backlog/6-fixable.md" << 'EOF'
# Fixable task

## Description

Needs fixing.

## Desired Outcome

- [ ] Fixed
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" --fix 2>&1) || rc=$?
# After fix, file should have proper title
content=$(cat "$TMPDIR/docs/tasks/backlog/6-fixable.md")
assert_contains "Title fixed" "$content" "# Task 6:"
assert_contains "Problem section renamed" "$content" "## Problem"
assert_contains "Success criteria renamed" "$content" "## Success criteria"

# Test 8: --help exits 0
echo "Test 8: --help exits 0"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" --help 2>&1) || rc=$?
assert_exit_code "Help exits 0" "0" "$rc"
assert_contains "Shows usage" "$output" "Usage:"

# Test 9: TEMPLATE files are skipped
echo "Test 9: TEMPLATE files skipped"
setup
cat > "$TMPDIR/docs/tasks/backlog/.TEMPLATE-task.md" << 'EOF'
# Template — not a real task
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Skips template exits 0" "0" "$rc"

# Test 10: Non-numeric ID in filename — exits 1
echo "Test 10: Non-numeric ID exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/abc-bad-id.md" << 'EOF'
# Task abc: Bad ID
**Feature**: none
## Problem
Bad.
## Success criteria
- [ ] Fix
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Non-numeric ID exits 1" "1" "$rc"
assert_contains "Reports invalid ID" "$output" "Invalid task ID"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
