#!/usr/bin/env bash

# migrate-to-submodule.sh
# Migrates an existing sprint.md installation to use the submodule distribution

set -euo pipefail

echo "================================================"
echo "  sprint.md - Migration to Submodule"
echo "================================================"
echo ""

# Check if we're in a project with sprint.md installed
if [ ! -f "docs/sprintmd/DOC_STATE.md" ] && [ ! -f "docs/STATE.md" ]; then
    echo "❌ Error: No sprint.md installation found in current directory."
    echo "  Please run this script from your project root."
    exit 1
fi

# Check for existing work content
echo "Checking existing sprint.md content..."
TASK_COUNT=$(find docs/tasks -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
BUG_COUNT=$(find docs/bugs -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
DOC_COUNT=$(find docs -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "Found:"
echo "  - $TASK_COUNT task files"
echo "  - $BUG_COUNT bug files"
echo "  - $DOC_COUNT documentation files"
echo ""

# Backup existing work
echo "Creating backup of existing work..."
BACKUP_DIR="sprint.md-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup docs directory structure
if [ -d "docs/tasks" ]; then
    cp -r docs/tasks "$BACKUP_DIR/"
    echo "  ✓ Backed up docs/tasks/ to $BACKUP_DIR/"
fi

# Backup docs directory
if [ -d "docs" ]; then
    cp -r docs "$BACKUP_DIR/"
    echo "  ✓ Backed up docs/ to $BACKUP_DIR/"
fi

# Backup any custom scripts
if [ -f "sprint.sh" ]; then
    cp sprint.sh "$BACKUP_DIR/"
fi
if [ -f "setup.sh" ]; then
    cp setup.sh "$BACKUP_DIR/"
fi

echo ""
echo "Backup created at: $BACKUP_DIR"
echo ""

# Remove old standalone files
echo "Removing old standalone installation files..."
REMOVED_FILES=0

# Remove old scripts (but not docs/sprintmd/scripts)
if [ -f "sprint.sh" ]; then
    rm -f sprint.sh
    ((REMOVED_FILES++))
    echo "  ✓ Removed sprint.sh"
fi

if [ -f "setup.sh" ]; then
    rm -f setup.sh
    ((REMOVED_FILES++))
    echo "  ✓ Removed setup.sh"
fi

# Remove templates if they exist at root
if [ -d "templates" ]; then
    rm -rf templates
    ((REMOVED_FILES++))
    echo "  ✓ Removed templates/"
fi

if [ "$REMOVED_FILES" -eq 0 ]; then
    echo "  → No standalone files found to remove"
fi

echo ""

# Add submodule
echo "Adding sprint.md as git submodule..."
echo "Enter the sprint.md distribution repository URL:"
echo "(e.g., https://github.com/yourusername/sprint.md.git)"
read -r REPO_URL

# Check if submodule already exists
if [ -d "sprint.md" ] && [ -f ".gitmodules" ] && grep -q "sprint.md" .gitmodules; then
    echo "⚠ Submodule sprint.md already exists. Updating instead..."
    cd sprint.md
    git pull origin main
    cd ..
else
    git submodule add "$REPO_URL" sprint.md
    git submodule update --init --recursive
fi

echo "  ✓ Added sprint.md submodule"
echo ""

# Restore work content
echo "Restoring your project content..."

# Ensure directories exist (setup.sh will handle this safely too)
./sprint.md/setup.sh

# Restore task content
if [ -d "$BACKUP_DIR/tasks" ]; then
    # Copy task files
    for folder in backlog next doing blocked review "done"; do
        if [ -d "$BACKUP_DIR/tasks/$folder" ]; then
            cp -n "$BACKUP_DIR/tasks/$folder"/*.md "docs/tasks/$folder/" 2>/dev/null || true
        fi
    done
    echo "  ✓ Restored task content"
fi

# Copy bug files
if [ -d "$BACKUP_DIR/docs/bugs" ]; then
    find "$BACKUP_DIR/docs/bugs" -name "*.md" -exec cp -n {} docs/bugs/ \; 2>/dev/null || true
    echo "  ✓ Restored bug content"
fi

# Restore DOC_STATE.md (preserving IDs) — handles both old and new layouts
if [ -f "$BACKUP_DIR/docs/sprintmd/DOC_STATE.md" ]; then
    mkdir -p docs/sprintmd
    cp "$BACKUP_DIR/docs/sprintmd/DOC_STATE.md" "docs/sprintmd/DOC_STATE.md"
    echo "  ✓ Restored DOC_STATE.md with existing IDs"
elif [ -f "$BACKUP_DIR/docs/STATE.md" ]; then
    # Pre-2.2.0 backup — restore at old path so setup.sh can migrate it
    cp "$BACKUP_DIR/docs/STATE.md" "docs/STATE.md"
    echo "  ✓ Restored STATE.md (pre-2.2.0 layout, will migrate on next setup)"
fi

# Restore docs content
if [ -d "$BACKUP_DIR/docs" ]; then
    # Copy feature docs
    if [ -d "$BACKUP_DIR/docs/features" ]; then
        cp -n "$BACKUP_DIR/docs/features"/*.md "docs/features/" 2>/dev/null || true
    fi

    # Copy guides
    if [ -d "$BACKUP_DIR/docs/guides" ]; then
        cp -n "$BACKUP_DIR/docs/guides"/*.md "docs/guides/" 2>/dev/null || true
    fi

    echo "  ✓ Restored documentation"
fi

echo ""
echo "================================================"
echo "  Migration Complete!"
echo "================================================"
echo ""
echo "Your project has been migrated to use sprint.md as a submodule."
echo ""
echo "Next steps:"
echo "1. Review the migration:"
echo "   - Check docs/tasks/ for your tasks"
echo "   - Verify docs/sprintmd/DOC_STATE.md has correct IDs"
echo "   - Ensure docs/ has your documentation"
echo ""
echo "2. Commit the changes:"
echo "   git add .gitmodules sprint.md"
echo "   git commit -m \"Migrate to sprint.md submodule\""
echo ""
echo "3. Use sprint.md commands:"
echo "   ./sprint.md/sprint.sh status"
echo "   ./sprint.md/sprint.sh new \"Your task\""
echo ""
echo "Backup preserved at: $BACKUP_DIR"
echo "(You can remove this after verifying the migration)"
echo ""