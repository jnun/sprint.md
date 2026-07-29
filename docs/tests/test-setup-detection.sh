#!/usr/bin/env bash
# Test: setup.sh detection/merge helpers
#
# setup.sh writes into other people's projects, so its "did WE already install
# this?" decisions are the highest-stakes logic in the repo. Those decisions
# live in two pure helpers — already_ours and gitignore_merge — fenced between
# `# >>> sprint.md detection helpers` / `# <<< sprint.md detection helpers`
# sentinels in setup.sh. We extract that fenced block verbatim and source it, so
# these tests exercise the exact shipped logic without running the interactive
# installer.

set -euo pipefail

PASS=0
FAIL=0
SETUP_SH="$(cd "$(dirname "$0")/../.." && pwd)/setup.sh"

# --- Extract the pure helper block from setup.sh and source it ---
HELPERS="$(mktemp)"
trap 'rm -f "$HELPERS"' EXIT
awk '/# >>> sprint.md detection helpers/{f=1;next} /# <<< sprint.md detection helpers/{f=0} f' \
    "$SETUP_SH" > "$HELPERS"

if [ ! -s "$HELPERS" ]; then
    echo "FAIL: could not extract detection helpers from $SETUP_SH (sentinels missing?)"
    exit 1
fi
# shellcheck disable=SC1090
source "$HELPERS"

assert_true() {
    local desc="$1"; shift
    if "$@"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected success, got exit $?)"
        FAIL=$((FAIL + 1))
    fi
}

assert_false() {
    local desc="$1"; shift
    if "$@"; then
        echo "  FAIL: $desc (expected failure, got success)"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        printf '    expected: %q\n' "$expected"
        printf '    actual:   %q\n' "$actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  FAIL: $desc (unexpectedly contained '$needle')"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

echo "=== test-setup-detection.sh ==="

# ---------------------------------------------------------------------------
# already_ours: matches OUR marker, ignores incidental substrings
# ---------------------------------------------------------------------------

echo "Test 1: already_ours matches a file we wrote (marker present)"
OURS='> **Project documentation** → see DOCUMENTATION.md (managed by [sprint.md](https://github.com/jnun/sprint.md))'
assert_true "our README pointer is recognized" \
    already_ours "$SPRINT_README_MARKER" "$OURS"

echo "Test 2: already_ours does NOT fire on an incidental 'sprint.md' mention"
# A host project that merely references the tool by name must not be mistaken
# for one we've already modified.
INCIDENTAL='# My project\nWe use sprint.md to plan work. See setup notes.'
assert_false "bare 'sprint.md' mention is not treated as ours" \
    already_ours "$SPRINT_README_MARKER" "$INCIDENTAL"

echo "Test 3: already_ours does NOT fire on an incidental 'DOCUMENTATION.md' mention"
# The old gate keyed off this filename; an unrelated mention must not match.
DOC_MENTION='See DOCUMENTATION.md for our internal API docs.'
assert_false "bare 'DOCUMENTATION.md' mention is not treated as ours" \
    already_ours "$SPRINT_AI_MARKER" "$DOC_MENTION"

echo "Test 4: already_ours recognizes an AI pointer we wrote"
AI_OURS='Read `DOCUMENTATION.md` before making any changes. It is the single source of truth for how this project is organized, how tasks are managed, and how to use the sprint.md system.'
assert_true "our AI pointer is recognized" \
    already_ours "$SPRINT_AI_MARKER" "$AI_OURS"

echo "Test 5: already_ours matches the marker literally (glob chars are safe)"
# The gitignore marker contains '===' — ensure it's matched as text, not a glob.
GI='# === sprint.md Recommended Entries ===\n.tmp/'
assert_true "gitignore header marker matched literally" \
    already_ours "$SPRINT_GITIGNORE_MARKER" "$(printf '%b' "$GI")"

# ---------------------------------------------------------------------------
# gitignore_merge: fresh install, idempotent re-run, phrased-differently
# ---------------------------------------------------------------------------

RECOMMENDED='# sprint.md temp
.sprint-tmp/
node_modules/

# Editor
.vscode/'

echo "Test 6: fresh install returns all recommended entries"
merged="$(gitignore_merge "$RECOMMENDED" "")"
assert_contains "includes .sprint-tmp/" "$merged" ".sprint-tmp/"
assert_contains "includes node_modules/" "$merged" "node_modules/"
assert_contains "includes .vscode/" "$merged" ".vscode/"

echo "Test 7: idempotent re-run returns nothing (all entries already present)"
existing="$RECOMMENDED"
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_eq "empty output when nothing new" "" "$merged"

echo "Test 8: existing .gitignore that incidentally contains 'sprint.md'"
# A comment mentioning sprint.md must NOT suppress the real merge — the entries
# it lacks still come through (this is the exact false-positive the old
# grep -q 'sprint.md' early-out caused).
existing='# we track work with sprint.md
build/'
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_contains "still adds .sprint-tmp/ despite the sprint.md comment" "$merged" ".sprint-tmp/"
assert_contains "still adds node_modules/" "$merged" "node_modules/"

echo "Test 9: partial overlap — only missing entries returned, no orphan headers"
existing='.sprint-tmp/
node_modules/'
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_not_contains "does not re-add node_modules/" "$merged" "node_modules/"
assert_contains "adds .vscode/" "$merged" ".vscode/"
# The 'sprint.md temp' section is fully covered, so its header must be dropped;
# only the Editor section (which has a new entry) survives.
assert_not_contains "orphan 'sprint.md temp' header dropped" "$merged" "sprint.md temp"
assert_contains "Editor header kept (its section has a new entry)" "$merged" "# Editor"

echo "Test 10: entries phrased differently are NOT deduped (exact-line match)"
# gitignore_merge dedups by exact line. An equivalent-but-differently-written
# entry is intentionally treated as new (we never guess semantic equivalence).
existing='node_modules'          # no trailing slash -> different line
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_contains "differently-phrased entry still added" "$merged" "node_modules/"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
