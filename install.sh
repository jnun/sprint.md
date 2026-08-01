#!/usr/bin/env bash
# install.sh — one-breath bootstrap for sprint.md
#
# From *your* project:
#   curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash
#
# Or pin a ref / target:
#   curl -fsSL .../install.sh | bash -s -- .
#   SPRINT_REF=v0.0.58 curl -fsSL .../install.sh | bash
#   ./install.sh /path/to/project
#
# Fetches the sprint.md source tree, then runs setup.sh into the target.

if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: install.sh must be run with bash." >&2
    echo "  curl -fsSL https://raw.githubusercontent.com/jnun/sprint.md/main/install.sh | bash" >&2
    exit 1
fi

# If stdin is a pipe, rebind to the tty so setup prompts still work.
if [ -p /dev/stdin ]; then
    { exec < /dev/tty; } 2>/dev/null || true
fi

set -euo pipefail

TARGET="${1:-.}"
REPO="${SPRINT_REPO:-jnun/sprint.md}"
REF="${SPRINT_REF:-main}"
BASE="https://github.com/${REPO}"

TMP=
cleanup() {
    if [ -n "${TMP:-}" ] && [ -d "${TMP:-}" ]; then
        rm -rf "$TMP"
    fi
}
trap cleanup EXIT

echo "================================================"
echo "  sprint.md — install"
echo "================================================"
echo "  Ref:    $REF"
echo "  Target: $TARGET"
echo ""

if [ ! -d "$TARGET" ]; then
    echo "Error: target is not a directory: $TARGET" >&2
    echo "Create it first, then re-run." >&2
    exit 1
fi

TMP=$(mktemp -d)
ARCHIVE="$TMP/sprint.md.tgz"

echo "→ Fetching source…"
if ! curl -fsSL "${BASE}/archive/refs/heads/${REF}.tar.gz" -o "$ARCHIVE" 2>/dev/null; then
    if ! curl -fsSL "${BASE}/archive/refs/tags/${REF}.tar.gz" -o "$ARCHIVE"; then
        echo "Error: could not download ${REPO}@${REF}" >&2
        echo "Check the ref, or clone: git clone ${BASE}.git" >&2
        exit 1
    fi
fi

tar -xzf "$ARCHIVE" -C "$TMP"
# GitHub archives unpack to <repo>-<ref> (slashes in tags become -)
SRC=$(find "$TMP" -maxdepth 1 -type d \( -name 'sprint.md-*' -o -name 'sprint.md*' \) ! -path "$TMP" | head -1)
if [ -z "$SRC" ] || [ ! -f "$SRC/setup.sh" ]; then
    echo "Error: archive did not contain setup.sh" >&2
    exit 1
fi

echo "→ Running setup into $(cd "$TARGET" && pwd)…"
echo ""
bash "$SRC/setup.sh" "$TARGET"
