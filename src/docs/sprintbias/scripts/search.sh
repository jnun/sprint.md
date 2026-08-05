#!/usr/bin/env bash
# search.sh — Search tasks by keyword. See: ./sprint.sh help search
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

if [ -z "${1:-}" ]; then
    echo -e "${RED}ERROR: Search term required${NC}"
    echo "Usage: ./sprint.sh search <keyword>"
    exit 1
fi

QUERY="$1"
TASKS_DIR="$PROJECT_ROOT/docs/tasks"
FOUND=0

for stage in "${SPRINTBIAS_STAGES[@]}"; do
    stage_dir="$TASKS_DIR/$stage"
    [ -d "$stage_dir" ] || continue

    for task_file in "$stage_dir"/*.md; do
        [ -f "$task_file" ] || continue

        basename_file="$(basename "$task_file")"

        if echo "$basename_file" | grep -qi "$QUERY" || grep -qi "$QUERY" "$task_file"; then
            id=$(task_id "$basename_file")
            title=$(task_title "$task_file" || true)
            echo -e "  ${BOLD}${id}${NC}  ${CYAN}${stage}${NC}  ${title}"
            FOUND=$((FOUND + 1))
        fi
    done
done

if [ "$FOUND" -eq 0 ]; then
    echo -e "${YELLOW}No tasks matching \"$QUERY\"${NC}"
else
    echo ""
    echo -e "${GREEN}${FOUND} task(s) found${NC}"
fi
