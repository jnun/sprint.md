#!/usr/bin/env bash
# sync.sh — Push task changes to GitHub. See: ./sprint.sh help sync

set -euo pipefail

# Resolve project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Exit codes (documented in help/sync.md):
#   0  success, or nothing to sync
#   1  environment not ready (no git repo, wrong branch, no remote, no gh)

# Check we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Not a git repository.${NC} Run: git init"
    exit 1
fi

# Check we're on main
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
    echo -e "${RED}ERROR: Must be on main branch (currently on '$BRANCH').${NC} Switch with: git checkout main"
    exit 1
fi

# Check for a remote
if ! git remote get-url origin >/dev/null 2>&1; then
    echo -e "${RED}ERROR: No 'origin' remote configured.${NC} Add one with: git remote add origin <url>"
    exit 1
fi

# Determine what to sync
FORCE_ALL=false
if [ "${1:-}" = "--all" ]; then
    FORCE_ALL=true
    shift
fi

# Precheck gh for --all BEFORE committing/pushing, so a --all run fails whole
# rather than half — otherwise we'd push, then discover gh is missing and be
# unable to trigger the full resync, leaving the sync half-done.
if [ "$FORCE_ALL" = "true" ] && ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}ERROR: gh CLI is required for --all.${NC} Install from https://cli.github.com"
    exit 1
fi

echo -e "${CYAN}=== sprint.md GitHub Sync ===${NC}"
echo ""

# Stage task files from all pipeline folders
STAGED=0

for folder in "${FIVEDAY_STAGES[@]}"; do
    DIR="docs/tasks/$folder"
    [ -d "$DIR" ] || continue
    if [ -n "$(git status --porcelain "$DIR" 2>/dev/null || true)" ]; then
        git add "$DIR"/*.md 2>/dev/null || true
    fi
    # Count distinct staged task files in this folder (accurate for
    # renames/deletes, which raw porcelain line-counting miscounts).
    COUNT=$(git diff --cached --name-only -- "$DIR" 2>/dev/null | grep -c '\.md$' || true)
    if [ "$COUNT" -gt 0 ]; then
        echo -e "  ${GREEN}+${NC} $folder: $COUNT file(s)"
        STAGED=$((STAGED + COUNT))
    fi
done

# Also stage DOC_STATE.md if changed
if git status --porcelain docs/sprintmd/DOC_STATE.md 2>/dev/null | grep -q .; then
    git add docs/sprintmd/DOC_STATE.md 2>/dev/null || true
    echo -e "  ${GREEN}+${NC} DOC_STATE.md"
    STAGED=$((STAGED + 1))
fi

if [ "$STAGED" -eq 0 ] && [ "$FORCE_ALL" != "true" ]; then
    echo -e "${YELLOW}No task changes to sync.${NC}"
    echo "Use --all to force a full resync of all tasks."
    exit 0
fi

echo ""

# Push any staged changes
if [ "$STAGED" -gt 0 ]; then
    git commit -m "sync: update task files for GitHub issue sync"
    echo -e "${CYAN}Pushing to origin/main...${NC}"
    git push origin main
    echo ""
    echo -e "${GREEN}Synced $STAGED file(s). GitHub Actions will update issues shortly.${NC}"
fi

# If --all, trigger a full resync via workflow_dispatch. gh was already
# verified above, before any commit/push, so we never reach here without it.
if [ "$FORCE_ALL" = "true" ]; then
    echo -e "${YELLOW}Triggering full resync via workflow_dispatch...${NC}"
    gh workflow run sync-tasks-to-issues.yml -f force_sync_all=true
    echo -e "${GREEN}Full resync triggered. All tasks will be synced to GitHub Issues.${NC}"
fi

echo "Check workflow status: gh run list --workflow=sync-tasks-to-issues.yml --limit 1"
