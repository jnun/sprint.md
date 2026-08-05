#!/usr/bin/env bash
# chat-menu.sh — the front door for bare `chat`. See: ./sprint.sh help chat
#
# `chat` with no argument, on a real terminal, opens this picker. Its entries are
# the ones the command matrix names for the menu (docs/guides/command-matrix.md,
# the `chat` row): the two conversational creators plus the three sweeps. It only
# ROUTES — each choice exec's into the grammar word that already owns that work,
# so the menu stays a thin front door and every path keeps a single owner:
#
#   1) New task      → chat newtask     (create, then define it)      (chat.sh)
#   2) New plan      → chat newplan      (create, then author it)     (chat.sh → chat-plan.sh)
#   3) Sweep a folder→ chat <folder>     (verdict-first sort)          (chat-folder.sh)
#   4) Author a plan → chat plan         (bare = pick one)             (chat-plan.sh)
#   5) Bug inbox     → chat bugs         (oldest → newest)             (chat-bugs.sh)
#
# Reached ONLY from chat.sh's no-arg branch, and ONLY when a real interactive
# terminal is present. In emit mode or on a pipe (agent-driven, CI) chat.sh
# skips the menu and goes straight to the sprint walk — a blocking read would
# just wait on input that never arrives. Two more front doors stay direct words
# rather than menu rows: `chat <id>` (define one known task) and `chat sprint`
# (whole-sprint structural walk).

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exec into a sibling chat script, honouring the dropped-exec-bit fallback the
# rest of the chat grammar uses (WSL/Docker/FAT32 strip the +x bit).
_route() {
  local s="$SCRIPTS/$1"; shift
  if [ -x "$s" ]; then exec "$s" "$@"; else exec bash "$s" "$@"; fi
}

# ── Menu ─────────────────────────────────────────────────────────────
echo "▸ chat — what do you want to talk through?"
echo ""
echo "  1) New task        create one, then define it together"
echo "  2) New plan        create one, then outline it together"
echo "  3) Sweep a folder  fast verdict-first sort of backlog / next / blocked"
echo "  4) Author a plan   pick a plan and shape it"
echo "  5) Bug inbox       work reports oldest → newest into tasks"
echo ""

CHOICE=""
while :; do
  printf "Choose 1–5 (or blank to cancel): "
  read -r CHOICE 2>/dev/null </dev/tty || CHOICE=""
  [ -n "$CHOICE" ] || { echo "Cancelled."; exit 0; }
  case "$CHOICE" in 1|2|3|4|5) break ;; *) echo "  Not a choice — enter 1, 2, 3, 4, or 5." ;; esac
done
echo ""

case "$CHOICE" in
  1)  _route chat.sh newtask ;;   # chat.sh's newtask word prompts for a name, creates, and dives in.
  2)  _route chat.sh newplan ;;   # chat.sh's newplan word prompts for a name, creates, and authors.
  3)  # Sweep a folder → pick which, hand the folder name to chat.sh's sweep.
    FOLDER=""
    while :; do
      printf "Which folder? (backlog / next / blocked, or blank to cancel): "
      read -r FOLDER 2>/dev/null </dev/tty || FOLDER=""
      [ -n "$FOLDER" ] || { echo "Cancelled."; exit 0; }
      case "$FOLDER" in backlog|next|blocked) break ;; *) echo "  Not a folder — enter backlog, next, or blocked." ;; esac
    done
    echo ""
    _route chat.sh "$FOLDER"
    ;;
  4)  _route chat-plan.sh ;;      # Author a plan → chat-plan.sh's own picker (bare = pick one).
  5)  _route chat-bugs.sh ;;      # Bug inbox → chat-bugs.sh sweep.
esac
