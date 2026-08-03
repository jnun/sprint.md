#!/usr/bin/env bash
# Test: profile.sh
# Non-AI paths: show, --help, unknown arg. (Interactive create/update needs a TTY + provider.)

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintmd/scripts" && pwd)/profile.sh"
SPRINTMD_SRC="$(cd "$(dirname "$0")/../sprintmd" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # profile.sh: SCRIPT_DIR/../../.. is PROJECT_ROOT
    mkdir -p "$TMPDIR/docs/sprintmd/scripts"
    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintmd/scripts/profile.sh"
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

echo "=== test-profile.sh ==="

# Test 1: show with no profile — exits 0, helpful message
echo "Test 1: show with no profile"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/profile.sh" show 2>&1) || rc=$?
assert_exit_code "show no-profile exits 0" "0" "$rc"
assert_contains "Says no profile yet" "$output" "No project profile yet"
assert_contains "Hints at create command" "$output" "./sprint.sh profile"

# Test 2: show with profile — prints file contents
echo "Test 2: show with profile"
setup
cat > "$TMPDIR/docs/sprintmd/project.md" << 'EOF'
# Project Profile
**Language:** Bash
**Framework:** SprintBias
**Tests:** docs/tests
**Style:** shellcheck
**Error handling:** set -euo pipefail
**Structure:** docs/ + src/
**Patterns:** dual tree
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/profile.sh" show 2>&1) || rc=$?
assert_exit_code "show with profile exits 0" "0" "$rc"
assert_contains "Prints Language" "$output" "**Language:** Bash"
assert_contains "Prints Patterns" "$output" "**Patterns:** dual tree"

# Test 3: --help exits 0
echo "Test 3: --help"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/profile.sh" --help 2>&1) || rc=$?
assert_exit_code "help exits 0" "0" "$rc"
assert_contains "Usage mentions show" "$output" "profile show"

# Test 4: unknown arg exits 1
echo "Test 4: unknown arg"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintmd/scripts/profile.sh" foobar 2>&1) || rc=$?
assert_exit_code "unknown exits 1" "1" "$rc"
assert_contains "Reports unknown" "$output" "Unknown argument"

# Test 5: consumers use sprintmd_profile_line (no inlined pointer left)
echo "Test 5: create-idea / create-feature use shared helper"
idea="$SPRINTMD_SRC/scripts/create-idea.sh"
feat="$SPRINTMD_SRC/scripts/create-feature.sh"
if grep -q 'sprintmd_profile_line' "$idea" && ! grep -q 'Also read docs/sprintmd/project.md' "$idea"; then
    echo "  PASS: create-idea uses helper"
    PASS=$((PASS + 1))
else
    echo "  FAIL: create-idea still inlines or missing helper"
    FAIL=$((FAIL + 1))
fi
if grep -q 'sprintmd_profile_line' "$feat" && ! grep -q 'Also read docs/sprintmd/project.md' "$feat"; then
    echo "  PASS: create-feature uses helper"
    PASS=$((PASS + 1))
else
    echo "  FAIL: create-feature still inlines or missing helper"
    FAIL=$((FAIL + 1))
fi

# Test 6: update-mode prompt re-scans (source check)
echo "Test 6: update mode re-scans and surfaces drift"
if grep -q 'surface drift proactively' "$SCRIPT_UNDER_TEST" \
    && grep -q 'sprintmd_run_interactive' "$SCRIPT_UNDER_TEST"; then
    echo "  PASS: update re-scan + interactive path present"
    PASS=$((PASS + 1))
else
    echo "  FAIL: profile.sh missing re-scan or interactive path"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
