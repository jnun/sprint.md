#!/usr/bin/env bash
# create-plan.sh — Create an plan. See: ./sprint.sh help newplan
#
# A plan is a RELATIONAL INDEX over tasks, not a container: one file that names
# a clump of related tasks and lists their IDs. The tasks never move here — each
# stays in its own lifecycle folder and flows through backlog → next → … on its
# own. This script allocates a plan ID (a dedicated DOC_STATE counter, exactly
# like task/bug IDs), writes docs/plans/N-name.md from the template, and fills
# in the member list from task IDs given on the command line or picked from
# backlog/ (the defining period, before work starts). No task file is touched.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Verify DOC_STATE.md exists and is valid
if [ ! -f "docs/sprintmd/DOC_STATE.md" ]; then
    echo -e "${RED}ERROR: docs/sprintmd/DOC_STATE.md not found!${NC}"
    echo "Run ./setup.sh first to initialize the project."
    exit 1
fi

NAME="${1:-}"
if [ -z "$NAME" ]; then
    echo "Usage: $0 \"<plan name>\" [task-id ...]"
    echo ""
    echo "A plan is a named list of task IDs — a relational grouping over tasks"
    echo "that each stay in their own lifecycle folder. Pass member task IDs as"
    echo "extra arguments (numbers and N-M ranges), or omit them to pick from"
    echo "backlog/ interactively."
    echo ""
    echo "Examples:"
    echo "  $0 \"Method accuracy audit\" 213 214 215"
    echo "  $0 \"Method accuracy audit\" 213-220"
    exit 1
fi
shift || true

# Convert to a filename-safe slug; reject names with no slug-able text.
SLUG=$(sprintmd_slug "$NAME") || {
    echo -e "${RED}ERROR: Name has no letters or numbers to build a filename from.${NC}"
    echo "Provide a name with at least one alphanumeric character."
    exit 1
}

# ── Collect member task IDs ──────────────────────────────────────────
# Expand a token list ("213 214" or "213-220") into individual numeric IDs.
# Mirrors sprintmd_unmet_deps' range handling so the two agree on syntax.
expand_ids() {
    local tok lo hi n
    for tok in "$@"; do
        tok="${tok//,/ }"
        for tok in $tok; do
            if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
                [ "$lo" -le "$hi" ] || continue
                for ((n=lo; n<=hi; n++)); do printf '%s\n' "$n"; done
            elif [[ "$tok" =~ ^[0-9]+$ ]]; then
                printf '%s\n' "$tok"
            fi
        done
    done
}

MEMBER_IDS=()
if [ "$#" -gt 0 ]; then
    while IFS= read -r _id; do MEMBER_IDS+=("$_id"); done < <(expand_ids "$@" | awk '!seen[$0]++')
elif [ -t 0 ] && [ -t 1 ]; then
    # Interactive: a plan is the defining period, so offer backlog/ — the tasks
    # you choose before work starts. (next/blocked/doing/review/done are all
    # post-start; you can still type any ID by hand.)
    echo -e "${CYAN}Tasks in backlog/ (the pool you plan from):${NC}"
    _any=0
    for f in docs/tasks/backlog/*.md; do
        [ -f "$f" ] || continue
        _any=1
        printf "  ${BOLD}%s${NC}  %s\n" "$(task_id "$(basename "$f")")" "$(task_title "$f")"
    done
    [ "$_any" -eq 0 ] && echo "  (backlog is empty — you can still enter any task ID)"
    echo ""
    printf "Enter member task IDs (space/comma separated, N-M ranges ok; blank for none): "
    read -r _line </dev/tty 2>/dev/null || _line=""
    while IFS= read -r _id; do MEMBER_IDS+=("$_id"); done < <(expand_ids $_line | awk '!seen[$0]++')
fi

# ── Allocate the plan ID (serialized, like newtask/newbug) ───────────
sprintmd_lock

NEW_ID=$(alloc_id sprint_PLAN_ID 'docs/plans/[0-9]*-*.md') || {
    echo -e "${RED}ERROR: Invalid or missing plan ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintmd/DOC_STATE.md manually. Expected: '**sprint_PLAN_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$SLUG")
DEST="docs/plans/$FILENAME"

# No plan file may already own this ID, whatever its slug. alloc_id reconciles
# the counter with disk, so this should never fire — if it does, DOC_STATE.md
# is corrupt or two files share a numeric prefix by hand.
# Glob-loop (not `ls | head`) so an unmatched pattern can't trip pipefail.
DUP=""
for existing in docs/plans/"${NEW_ID}"-*.md; do
    [ -e "$existing" ] && { DUP="$existing"; break; }
done
if [ -n "$DUP" ]; then
    echo -e "${RED}ERROR: plan ID ${NEW_ID} already exists: ${DUP}${NC}"
    echo "DOC_STATE.md's sprint_PLAN_ID is out of sync with the files on disk."
    exit 1
fi

copy_template "docs/plans/.TEMPLATE-plan.md" "$DEST" || exit 1

CREATED_DATE=$(date +%Y-%m-%d)
sed_inplace "s/\[ID\]/$NEW_ID/g" "$DEST"
sed_inplace "s/\[Plan Name\]/$(sed_escape "$NAME")/g" "$DEST"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "$DEST"

# ── Write the member list ────────────────────────────────────────────
# Replace the template's single "- #ID — short title" placeholder with one
# resolved line per member. Each ID is looked up across every lifecycle folder
# (a plan references tasks wherever they currently sit); an ID that resolves
# to no file is kept as a reference — a plan lists IDs, not paths, and a
# member that was completed and archived is still a member.
sed_inplace '/^- #ID — short title$/d' "$DEST"

{
    for id in ${MEMBER_IDS[@]+"${MEMBER_IDS[@]}"}; do
        if hit=$(sprintmd_find_task "$id" \
                    docs/tasks/backlog docs/tasks/next docs/tasks/doing \
                    docs/tasks/blocked docs/tasks/review docs/tasks/done); then
            fpath="${hit%%$'\t'*}"
            printf -- '- #%s — %s\n' "$id" "$(task_title "$fpath")"
        else
            printf -- '- #%s — (no task file found — completed or archived)\n' "$id"
        fi
    done
} >> "$DEST"

# ── Refresh each member's **Plan** reverse index ─────────────────────
# The plan file (now written) is the membership authority; mirror it onto each
# member task's **Plan** field so single-file readers see the plan. Migrate on
# touch: reconcile derives the primary (lowest) plan from all plan files, so a
# member already in a lower-numbered plan keeps that id. done/ is left alone.
for id in ${MEMBER_IDS[@]+"${MEMBER_IDS[@]}"}; do
    sprintmd_reconcile_task_plan "$id" >/dev/null || true
done

# Update DOC_STATE.md — only the fields that changed.
bump_doc_state sprint_PLAN_ID "$NEW_ID"
bump_doc_state "Last Updated" "$(date +%F)"
sprintmd_unlock
echo -e "${GREEN}✓ DOC_STATE.md updated (sprint_PLAN_ID=$NEW_ID)${NC}"

# Stage the changes (skip gracefully if not in a git repo)
git add docs/sprintmd/DOC_STATE.md "$DEST" 2>/dev/null || true

echo -e "${GREEN}Created plan: $DEST${NC}"
if [ "${#MEMBER_IDS[@]}" -gt 0 ]; then
    echo "  Members: ${MEMBER_IDS[*]}"
else
    echo "  No members yet — edit the file to add '- #ID — title' lines."
fi
echo ""
echo "Next: author with ./sprint.sh chat plan <id>, optionally critique with"
echo "./sprint.sh plan think <id>, then commit with ./sprint.sh plan start <id>"
echo "(or commit one member via: bash docs/sprintmd/scripts/promote-to-sprint.sh <task-file>)."
echo "The plan file itself never moves."
