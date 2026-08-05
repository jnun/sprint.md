#!/usr/bin/env bash
# promote-to-sprint.sh — Gate-review one task file into next/ (or kick it back).
#
# The only agent-callable shell entry that may place a task into next/. Every
# other promote path (plan start, chat-folder [w], polish REOPEN, chat close-loop)
# uses the same gate-lib helper. Raw git mv into next/ is not supported.
#
# Usage (from project root):
#   bash docs/sprintbias/scripts/promote-to-sprint.sh <task-file>
#
# Exit: 0 when the gate ran (including BLOCKED/COMPLETE/NOSTAMP/FAILED routes);
#       1 when the file is missing or usage is wrong.
# Prints a one-line summary and sets no parent-shell variables (subshell).

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

FILE="${1:-}"
if [ -z "$FILE" ] || [ "$FILE" = "-h" ] || [ "$FILE" = "--help" ]; then
  echo "Usage: bash docs/sprintbias/scripts/promote-to-sprint.sh <task-file>"
  echo "  Runs the shared workability gate; READY → next/, BLOCKED → blocked/,"
  echo "  COMPLETE → review/. Never raw-moves into next/."
  exit 1
fi

if ! sprintbias_promote_to_sprint "$FILE" promote; then
  sprintbias_promote_summary "$(basename "$FILE")"
  exit 1
fi
sprintbias_promote_summary "$(basename "$FILE")"
case "${SPRINTBIAS_GATE_VERDICT:-}" in
  READY|BLOCKED|COMPLETE|EMIT) exit 0 ;;
  *) exit 1 ;;
esac
