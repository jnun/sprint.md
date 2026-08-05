#!/usr/bin/env bash
# check-alignment.sh — Feature/task alignment. See: ./sprint.sh help align

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

echo -e "${BOLD}================================================"
echo "  Feature-Task Alignment Analysis"
echo -e "================================================${NC}\n"

# Track if we found any issues
ISSUES_FOUND=0

# Function to check feature status validity
is_valid_status() {
    case "$1" in
        BACKLOG|NEXT|DOING|BLOCKED|REVIEW|DONE) return 0 ;;
        *) return 1 ;;
    esac
}

# Analyze each feature
echo -e "${CYAN}${BOLD}Analyzing Features:${NC}\n"

for feature_file in docs/features/*.md; do
    # Skip if glob didn't match, is template, or is INDEX
    [ -f "$feature_file" ] || continue
    case "$(basename "$feature_file")" in
        TEMPLATE*|INDEX.md) continue ;;
    esac

    feature_name=$(basename "$feature_file" .md)
    echo -e "${BLUE}${BOLD}Feature: ${NC}$feature_name"

    # Get feature status (look for overall status first). Accept both the
    # shipped template's "**Status:** X" (colon inside the bold) and this
    # repo's older "## Feature Status: X" heading / "**Status**: X" forms, so
    # a fresh user's first template-generated feature isn't reported as having
    # no status. head -1 takes whichever appears first (the overall status).
    # `|| true` keeps grep's no-match exit (1) from tripping set -e/pipefail so a
    # feature file with no status line falls through to the "No status" branch.
    feature_status=$(grep -E "^(## (Feature |Overall )?Status:|\*\*Status:?\*\*:?)" "$feature_file" 2>/dev/null | head -1 | sed -E 's/.*Status//; s/^[*:[:space:]]+//' | cut -d' ' -f1 | tr -d '[:space:]' || true)

    if [ -z "$feature_status" ]; then
        echo -e "  ${RED}⚠ No status found in feature file${NC}"
        ISSUES_FOUND=1
    elif ! is_valid_status "$feature_status"; then
        echo -e "  ${RED}⚠ Invalid status: $feature_status${NC}"
        ISSUES_FOUND=1
    else
        echo -e "  Status: ${BOLD}$feature_status${NC}"
    fi

    # Find all capability statuses in the feature
    echo -e "  ${CYAN}Capabilities:${NC}"
    capability_count=0

    # Read file and track capabilities properly
    prev_heading=""
    while IFS= read -r line; do
        # Track section headings
        if echo "$line" | grep -q "^## "; then
            # Skip "Feature Status" heading
            if ! echo "$line" | grep -qE "^## (Feature |Overall )?Status:"; then
                prev_heading=$(echo "$line" | sed 's/^## *//')
            fi
        # Check for capability status (both "**Status**: X" and "**Status:** X")
        elif echo "$line" | grep -qE '\*\*Status:?\*\*:?'; then
            cap_status=$(echo "$line" | sed -E 's/.*Status//; s/^[*:[:space:]]+//' | cut -d' ' -f1)
            if [ -n "$prev_heading" ] && [ -n "$cap_status" ]; then
                capability_count=$((capability_count + 1))
                echo -e "    - $prev_heading: $cap_status"
                # Clear heading to avoid duplicate output
                prev_heading=""
            fi
        fi
    done < "$feature_file"

    if [ "$capability_count" -eq 0 ]; then
        echo -e "    ${YELLOW}(No individual capabilities tracked)${NC}"
    fi

    # Find related tasks
    echo -e "  ${CYAN}Related Tasks:${NC}"
    task_found=0

    # Search for tasks that reference this feature
    for stage in "${SPRINTBIAS_STAGES[@]}"; do
        task_dir="docs/tasks/$stage"
        if [ -d "$task_dir" ]; then
            for task_file in "$task_dir"/*.md; do
                if [ -f "$task_file" ] && [[ ! "$task_file" == *"TEMPLATE"* ]]; then
                    # Check if task references this feature
                    if grep -q "/docs/features/$feature_name.md" "$task_file" 2>/dev/null; then
                        task_found=1
                        task_id=$(task_id "$task_file")
                        task_title=$(task_title "$task_file")
                        folder=$(basename "$task_dir")

                        echo -e "    ${GREEN}✓ Task $task_id in $folder/${NC}"
                        echo -e "      $task_title"
                    fi
                fi
            done
        fi
    done

    if [ "$task_found" -eq 0 ]; then
        echo -e "    ${YELLOW}(No tasks currently reference this feature)${NC}"
    fi

    echo ""
done

# Check for broken feature references (tasks pointing to non-existent feature files)
echo -e "${CYAN}${BOLD}Checking for Broken Feature References:${NC}\n"

broken_found=0
for stage in "${SPRINTBIAS_STAGES[@]}"; do
    task_dir="docs/tasks/$stage"
    if [ -d "$task_dir" ]; then
        for task_file in "$task_dir"/*.md; do
            if [ -f "$task_file" ] && [[ ! "$task_file" == *"TEMPLATE"* ]]; then
                task_id=$(task_id "$task_file")
                # Extract only the first **Feature**: line, ignoring template comments
                feature_ref=$(task_feature "$task_file")

                # Skip tasks with no feature field, "none", or "multiple" — feature is optional
                if [ -z "$feature_ref" ] || [ "$feature_ref" = "none" ] || [ "$feature_ref" = "multiple" ]; then
                    continue
                fi

                # Check if the feature reference points to a file that exists
                if [[ "$feature_ref" == *"/docs/features/"* ]]; then
                    feature_basename=$(echo "$feature_ref" | sed 's/.*\/docs\/features\///' | sed 's/\.md$//')
                    if [ ! -f "docs/features/${feature_basename}.md" ]; then
                        broken_found=1
                        folder=$(basename "$task_dir")
                        echo -e "  ${RED}⚠ Task $task_id in $folder/ references non-existent feature: $feature_ref${NC}"
                        ISSUES_FOUND=1
                    fi
                fi
            fi
        done
    fi
done

if [ "$broken_found" -eq 0 ]; then
    echo -e "  ${GREEN}✓ All feature references point to existing files${NC}\n"
fi

# Summary and recommendations
echo -e "${BOLD}================================================"
echo "  Summary & Recommendations"
echo -e "================================================${NC}\n"

if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✓ No alignment issues found!${NC}\n"
else
    echo -e "${RED}⚠ Issues found that need attention — see warnings above.${NC}\n"
fi

echo -e "${CYAN}Best Practices:${NC}"
echo "• Feature Status = highest completed capability state"
echo "• Tasks are temporary work items, features are permanent"
echo "• A DONE feature can still have backlog tasks for enhancements"
echo "• The Feature field on tasks is optional — not every task belongs to a feature"

# Exit with error only when real issues exist (broken links, invalid statuses)
exit "$ISSUES_FOUND"