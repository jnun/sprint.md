#!/usr/bin/env bash
# learn-sandbox.sh — Trust guard for the `learn` demos.
#
# The demos make a promise: playing one touches NOTHING in your project — no
# files written, no task files moved, no network. This proves it rather than
# asserting it. It plays a demo from a throwaway working directory and checks:
#   1. the throwaway dir is still empty afterward (the demo wrote nothing), and
#   2. the project tree is unchanged (git status + full file inventory match).
#
# Exit 0 = the sandbox promise held. Exit 1 = a demo touched something.
# python3 missing → SKIP (exit 0): nothing to play, nothing to prove.
#
# Meant to be run by the test harness (or by hand) — NOT on every `learn`
# invocation, so playback stays instant. Run from anywhere:
#   bash docs/sprintmd/tests/learn-sandbox.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LEARN="$PROJECT_ROOT/docs/sprintmd/scripts/learn.sh"
LEARN_DIR="$PROJECT_ROOT/docs/sprintmd/learning"

if ! command -v python3 >/dev/null 2>&1; then
    echo "SKIP: python3 not available — no demo to sandbox-check."
    exit 0
fi

# A stable inventory of every file in the project tree (names only, .git
# pruned). Catches any create/delete/move a demo might attempt — even of a
# git-ignored file, which `git status` would not report.
_inventory() {
    ( cd "$PROJECT_ROOT" && find . -path ./.git -prune -o -type f -print ) | LC_ALL=C sort
}

# git's view of the working tree (tracked edits + untracked adds), if this is a
# repo. Complements the inventory by catching content edits to existing files.
_gitstate() {
    if command -v git >/dev/null 2>&1 && git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        git -C "$PROJECT_ROOT" status --porcelain
    fi
}

fail=0

before_inv="$(_inventory)"
before_git="$(_gitstate)"

# Throwaway CWD — anything a demo writes lands here, not in the project.
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

echo "▸ Playing every demo from a throwaway dir and checking for side effects…"
for demo in "$LEARN_DIR"/*.py; do
    [ -e "$demo" ] || continue
    name="$(basename "$demo" .py)"
    # --fast: no real-time delays. Output is theater; discard it.
    ( cd "$SANDBOX" && bash "$LEARN" "$name" --fast --no-color ) >/dev/null 2>&1 || {
        echo "  ✗ demo '$name' exited non-zero"; fail=1; continue
    }
    echo "  · played $name"
done

# 1. The sandbox must still be empty — the demo wrote nothing, anywhere.
leftovers="$(find "$SANDBOX" -mindepth 1 2>/dev/null || true)"
if [ -n "$leftovers" ]; then
    echo "✗ A demo wrote into its working directory:"
    echo "$leftovers" | sed 's/^/    /'
    fail=1
fi

# 2. The project tree must be byte-identical: same files, same git state.
after_inv="$(_inventory)"
after_git="$(_gitstate)"

if [ "$before_inv" != "$after_inv" ]; then
    echo "✗ The project file inventory changed while a demo played:"
    diff <(printf '%s\n' "$before_inv") <(printf '%s\n' "$after_inv") | sed 's/^/    /'
    fail=1
fi
if [ "$before_git" != "$after_git" ]; then
    echo "✗ git working-tree state changed while a demo played:"
    diff <(printf '%s\n' "$before_git") <(printf '%s\n' "$after_git") | sed 's/^/    /'
    fail=1
fi

echo ""
if [ "$fail" -eq 0 ]; then
    echo "✓ Sandbox promise held — the demos touched nothing in your project."
    exit 0
fi
echo "✗ Trust guard FAILED — a demo had a side effect. Investigate above."
exit 1
