#!/usr/bin/env bash
# setup.sh - sprint.md unified installer and updater
# Usage: ./setup.sh
#   Prompts for target project path and sets up/updates sprint.md structure there
#
# This script handles both fresh installations and updates with version migrations.
# Distribution: src/ mirrors the deployed layout — setup.sh walks it recursively.

# Guard: this script requires bash (arrays, [[ ]], (( )), etc.).
# Running it with sh/dash/zsh will produce cryptic failures.
if [ -z "$BASH_VERSION" ]; then
    echo "Error: setup.sh must be run with bash, not sh." >&2
    echo "Run it as:  ./setup.sh  or  bash setup.sh" >&2
    exit 1
fi

# Note: We intentionally omit set -euo pipefail. This is an interactive
# installer that handles errors via msg_error/msg_warning and ERRORS[].
# set -e would abort mid-install on expected failures (missing optional files,
# user declining prompts); -u would break the BASH_VERSION guard above; and
# -o pipefail would kill grep|wc pipelines that legitimately match zero lines.

# If stdin is a pipe (e.g. `curl ... | bash setup.sh`), try to rebind it
# to the controlling tty so interactive prompts still work. If no tty is
# available (backgrounded process, Docker without -t, daemon, etc.) the
# exec silently fails — bash leaves fd 0 intact, we keep reading from
# the pipe, and prompt_yes_no's EOF fallback handles the empty case.
# File redirection (`bash setup.sh < answers.txt`) is untouched: regular
# files don't match `-p`, so scripted installs continue to work.
if [ -p /dev/stdin ]; then
    # Brace group + 2>/dev/null is required: `exec < /dev/tty 2>/dev/null`
    # parses as exec-with-two-redirects, and bash prints the failure of
    # the first redirect to the *original* fd 2 before the second redirect
    # is applied — the error message leaks. Wrapping in `{ ...; } 2>/dev/null`
    # gives the exec a temporary fd 2 pointing at /dev/null for the
    # duration of the group, so the failure (if any) is silenced. The exec
    # only modifies fd 0; the brace group's temporary fd 2 reverts after.
    { exec < /dev/tty; } 2>/dev/null || true
fi

# Get the sprint.md source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPRINTMD_SOURCE_DIR="$SCRIPT_DIR"

# ============================================================================
# MESSAGE SYSTEM - Consistent, color-coded output
# ============================================================================

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Track errors for final summary
ERRORS=()
WARNINGS=()

# Message functions
msg_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

msg_success() {
    echo -e "${GREEN}✓${NC} $1"
}

msg_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS+=("$1")
}

msg_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS+=("$1")
}

msg_step() {
    echo -e "  ${CYAN}→${NC} $1"
}

msg_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
}

# Safe file copy with error handling
# Usage: safe_copy "source" "dest" "description"
safe_copy() {
    local src="$1"
    local dest="$2"
    local desc="${3:-$(basename "$src")}"

    if [ ! -f "$src" ]; then
        msg_warning "Source not found: $desc"
        return 1
    fi

    # Check if destination exists and is writable
    if [ -f "$dest" ] && [ ! -w "$dest" ]; then
        msg_error "Cannot write to $dest (permission denied)"
        msg_step "Fix with: chmod u+w \"$dest\""
        return 1
    fi

    # Check if destination directory is writable
    local dest_dir
    dest_dir="$(dirname "$dest")"
    if [ ! -w "$dest_dir" ]; then
        msg_error "Cannot write to directory $dest_dir (permission denied)"
        return 1
    fi

    if cp -f "$src" "$dest" 2>/dev/null; then
        msg_step "Copied $desc"
        return 0
    else
        msg_error "Failed to copy $desc"
        return 1
    fi
}

# Safe directory creation
# Usage: safe_mkdir "path"
safe_mkdir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        return 0
    fi

    if mkdir -p "$dir" 2>/dev/null; then
        msg_step "Created: $dir"
        return 0
    else
        msg_error "Failed to create directory: $dir"
        return 1
    fi
}

# Read current version from source
if [ -f "$SPRINTMD_SOURCE_DIR/src/VERSION" ]; then
    CURRENT_VERSION=$(cat "$SPRINTMD_SOURCE_DIR/src/VERSION")
else
    echo "Warning: VERSION file not found, defaulting to 1.0.0"
    CURRENT_VERSION="1.0.0"
fi

echo "================================================"
echo "  sprint.md - Project Documentation Setup"
echo "================================================"
echo "  Version: $CURRENT_VERSION"
echo ""

# Ask for target project path
echo "Enter the path to your project where sprint.md should be installed:"
echo "(e.g., /Users/yourname/myproject or ../myproject)"
read -r TARGET_PATH

# Expand tilde and resolve relative paths
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"
if [ -z "$TARGET_PATH" ]; then
    msg_error "No path provided"
    exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
    msg_error "Path does not exist: $TARGET_PATH"
    msg_step "Create the directory first, then run setup again"
    exit 1
fi

TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
    msg_error "Cannot access path: $TARGET_PATH"
    msg_step "Check that you have read permissions for this directory"
    exit 1
}

echo ""
echo "Target directory: $TARGET_PATH"
echo ""

# Change to target directory
cd "$TARGET_PATH" || exit 1

# Self-targeting detection
if [ "$TARGET_PATH" = "$SPRINTMD_SOURCE_DIR" ]; then
    echo "Note: Target is the sprint.md source directory."
    echo "   This will sync src/ to docs/ for development/testing."
    echo ""
fi

# ============================================================================
# DETECT INSTALLATION STATE
# ============================================================================

INSTALLED_VERSION=""
UPDATE_MODE=false

# Check if sprint.md is already installed. Product version lives only in
# docs/sprintmd/DOC_STATE.md (written from src/VERSION). There is no separate
# migration-epoch ladder — layout cleanups below are path-presence only.
if [ -f "docs/sprintmd/DOC_STATE.md" ]; then
    INSTALLED_VERSION=$(grep '^\*\*sprint_VERSION\*\*:' docs/sprintmd/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | head -1)
    [ -n "$INSTALLED_VERSION" ] || INSTALLED_VERSION="unknown"

    UPDATE_MODE=true
    echo "Existing sprint.md installation detected (version $INSTALLED_VERSION)"
    echo "This will update to version $CURRENT_VERSION"
    echo ""
elif [ -f "docs/STATE.md" ]; then
    # Older layout: STATE.md at docs/ root — will be moved to DOC_STATE.md below.
    INSTALLED_VERSION=$(grep '^\*\*sprint_VERSION\*\*:' docs/STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | head -1)
    [ -n "$INSTALLED_VERSION" ] || INSTALLED_VERSION="unknown"

    UPDATE_MODE=true
    echo "Existing sprint.md installation detected (version $INSTALLED_VERSION, older layout)"
    echo "This will update to version $CURRENT_VERSION"
    echo ""
elif [ -d "docs/tasks" ] || [ -d "work/tasks" ] || [ -d "docs/work/tasks" ]; then
    INSTALLED_VERSION="unknown"
    UPDATE_MODE=true
    echo "Existing project docs structure detected"
    echo "This will install/update sprint.md to version $CURRENT_VERSION"
    echo ""
elif [ -f "DOCUMENTATION.md" ]; then
    INSTALLED_VERSION="unknown"
    UPDATE_MODE=true
fi

if $UPDATE_MODE; then
    # Remember for the final summary only — never used as a migration gate.
    ORIGINAL_VERSION="$INSTALLED_VERSION"
    echo "Do you want to continue with the update? (y/n)"
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Ensure task pipeline folders exist
ensure_task_folders() {
    safe_mkdir "docs/tasks/backlog"
    safe_mkdir "docs/tasks/next"
    safe_mkdir "docs/tasks/doing"
    safe_mkdir "docs/tasks/blocked"
    safe_mkdir "docs/tasks/review"
    safe_mkdir "docs/tasks/done"
}

# merge_config "$src_config" "$user_config"
# Appends missing KEY=VALUE lines from source to user config.
# Returns 0 if changes were made, 1 if already up to date.
merge_config() {
    local src="$1"
    local dest="$2"
    local changed=false

    while IFS='=' read -r key value; do
        # Skip comments, blank lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # Append key if missing
        if ! grep -q "^${key}=" "$dest" 2>/dev/null; then
            echo "${key}=${value}" >> "$dest"
            changed=true
        fi
    done < "$src"

    $changed && return 0 || return 1
}

# ============================================================================
# PLATFORM CONFIGURATION
# ============================================================================

# Determine current platform (used as default during updates)
CURRENT_PLATFORM=""
if $UPDATE_MODE && [ -f "docs/.platform-config" ]; then
    CURRENT_PLATFORM=$(grep '^PLATFORM=' docs/.platform-config | cut -d'"' -f2)
fi

if $UPDATE_MODE; then
    echo "Select your platform configuration:"
    echo "  Current: ${CURRENT_PLATFORM:-github-issues (default)}"
else
    echo "Select your platform configuration:"
fi
echo "1) GitHub Issues (default)"
echo "2) No sync — opt out of GitHub issue tracking"
echo ""
if $UPDATE_MODE; then
    echo "Enter your choice (1-2, or press Enter to keep current):"
else
    echo "Enter your choice (1-2, or press Enter for default):"
fi
read -r PLATFORM_CHOICE

case "$PLATFORM_CHOICE" in
    1)
        PLATFORM="github-issues"
        echo "Selected: GitHub Issues"
        ;;
    2)
        PLATFORM="none"
        echo "Selected: No sync — opting out of issue tracker integration"
        ;;
    "")
        if $UPDATE_MODE && [ -n "$CURRENT_PLATFORM" ]; then
            PLATFORM="$CURRENT_PLATFORM"
            echo "Keeping current: $PLATFORM"
        else
            PLATFORM="github-issues"
            echo "Selected: GitHub Issues"
        fi
        ;;
    *)
        PLATFORM="github-issues"
        echo "Selected: GitHub Issues"
        ;;
esac
echo ""

# ============================================================================
# CREATE DIRECTORY STRUCTURE
# ============================================================================

msg_header "Creating directory structure..."

# Task pipeline
ensure_task_folders

# Plans — a relational grouping over tasks (docs/plans/N-name.md lists task
# IDs). A sibling of docs/tasks/, NOT a lifecycle stage. Created empty here; the
# .TEMPLATE-plan.md lands via the src/ walk below.
safe_mkdir "docs/plans"

# Other directories
safe_mkdir "docs/ideas"
safe_mkdir "docs/bugs"
safe_mkdir "docs/designs"
safe_mkdir "docs/examples"
safe_mkdir "docs/data"
safe_mkdir "docs/sprintmd/scripts"
safe_mkdir "docs/sprintmd/ai"
safe_mkdir "docs/features"
safe_mkdir "docs/guides"
safe_mkdir "docs/tests"
safe_mkdir "docs/tmp"

# Platform-specific directories
if [ "$PLATFORM" != "none" ]; then
    safe_mkdir ".github/workflows"
    safe_mkdir ".github/ISSUE_TEMPLATE"
fi

# Add .gitkeep files to preserve empty directories
find docs -type d -empty -exec touch {}/.gitkeep \; 2>/dev/null || true
msg_step "Added .gitkeep files to empty directories"

# ============================================================================
# STATE.MD MANAGEMENT
# ============================================================================

msg_header "Managing state tracking..."

safe_mkdir "docs/sprintmd"

if [ ! -f "docs/sprintmd/DOC_STATE.md" ]; then
    # Create new DOC_STATE.md
    if cat > docs/sprintmd/DOC_STATE.md << STATE_EOF
# sprint.md Documentation State

Part of the sprint.md documentation system, not source code for the host project.
Managed by scripts in \`docs/sprintmd/scripts/\` and by \`setup.sh\`. Safe to edit by hand
if you need to fix a counter — the field lines below are what scripts parse.

Fields:
- \`sprint_VERSION\`   — installed product version (from \`src/VERSION\` via setup/ship)
- \`sprint_TASK_ID\`   — highest task ID used; next task = this + 1
- \`sprint_BUG_ID\`    — highest bug ID used; next bug = this + 1
- \`sprint_PLAN_ID\`   — highest plan ID used; next plan = this + 1
- \`Last Updated\`   — ISO date; bump when you change a field

---

**Last Updated**: $(date +%Y-%m-%d)
**sprint_VERSION**: $CURRENT_VERSION
**sprint_TASK_ID**: 0
**sprint_BUG_ID**: 0
**sprint_PLAN_ID**: 0
STATE_EOF
    then
        msg_step "Created docs/sprintmd/DOC_STATE.md"
    else
        msg_error "Failed to create docs/sprintmd/DOC_STATE.md"
    fi
else
    # Reconcile DOC_STATE.md - preserve user data, update product version
    EXISTING_TASK_ID=$(grep '^\*\*sprint_TASK_ID\*\*:' docs/sprintmd/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    EXISTING_BUG_ID=$(grep '^\*\*sprint_BUG_ID\*\*:' docs/sprintmd/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    EXISTING_PLAN_ID=$(grep '^\*\*sprint_PLAN_ID\*\*:' docs/sprintmd/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    # One-shot read of pre-rebrand counter if PLAN_ID never written.
    if [ -z "$EXISTING_PLAN_ID" ]; then
        EXISTING_PLAN_ID=$(grep '^\*\*sprint_EPIC_ID\*\*:' docs/sprintmd/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    fi

    # Validate and set defaults
    [[ "$EXISTING_TASK_ID" =~ ^[0-9]+$ ]] || EXISTING_TASK_ID=0
    [[ "$EXISTING_BUG_ID" =~ ^[0-9]+$ ]] || EXISTING_BUG_ID=0
    [[ "$EXISTING_PLAN_ID" =~ ^[0-9]+$ ]] || EXISTING_PLAN_ID=0

    if cat > docs/sprintmd/DOC_STATE.md << STATE_EOF
# sprint.md Documentation State

Part of the sprint.md documentation system, not source code for the host project.
Managed by scripts in \`docs/sprintmd/scripts/\` and by \`setup.sh\`. Safe to edit by hand
if you need to fix a counter — the field lines below are what scripts parse.

Fields:
- \`sprint_VERSION\`   — installed product version (from \`src/VERSION\` via setup/ship)
- \`sprint_TASK_ID\`   — highest task ID used; next task = this + 1
- \`sprint_BUG_ID\`    — highest bug ID used; next bug = this + 1
- \`sprint_PLAN_ID\`   — highest plan ID used; next plan = this + 1
- \`Last Updated\`   — ISO date; bump when you change a field

---

**Last Updated**: $(date +%Y-%m-%d)
**sprint_VERSION**: $CURRENT_VERSION
**sprint_TASK_ID**: $EXISTING_TASK_ID
**sprint_BUG_ID**: $EXISTING_BUG_ID
**sprint_PLAN_ID**: $EXISTING_PLAN_ID
STATE_EOF
    then
        msg_step "Updated docs/sprintmd/DOC_STATE.md (preserved IDs: task=$EXISTING_TASK_ID, bug=$EXISTING_BUG_ID, plan=$EXISTING_PLAN_ID)"
    else
        msg_error "Failed to update docs/sprintmd/DOC_STATE.md"
    fi
fi

# Store platform configuration
cat > docs/.platform-config << CONFIG_EOF
# sprint.md Platform Configuration
# Generated: $(date +%Y-%m-%d)
PLATFORM="$PLATFORM"
CONFIG_EOF

# ============================================================================
# README SETUP
# ============================================================================

msg_header "Setting up documentation files..."

# Track counters
FILES_COPIED=0

# README.md — we don't ship one (the user owns theirs). If a README exists,
# prepend a pointer to DOCUMENTATION.md so readers know where the project
# docs live. Same pattern as the AI instruction files below.
README_POINTER='> **Project documentation** → see [`DOCUMENTATION.md`](DOCUMENTATION.md) (managed by [sprint.md](https://github.com/jnun/sprint.md))'

# ----------------------------------------------------------------------------
# Detection markers + pure decision helpers
# ----------------------------------------------------------------------------
#
# setup.sh writes into other people's projects, so "did WE already install
# this?" must never be answered by an incidental substring (a stray path, a
# comment, an unrelated tool that happens to mention "sprint.md" or
# "DOCUMENTATION.md"). A wrong "yes" silently skips real work; a wrong "no"
# risks duplicating content. Each update path therefore matches a distinctive
# fragment of the exact text we write — an unambiguous "this is ours" marker —
# not a bare filename.
#
# These markers are substrings of the pointers/headers written elsewhere in
# this file. If you change a pointer's wording, keep its marker a substring of
# the new text.
#
# The block between the SENTINEL lines below is pure (no file I/O, no state) and
# is extracted verbatim by docs/tests/test-setup-detection.sh so the helpers can
# be unit-tested without running the installer. Keep it self-contained.
# >>> sprint.md detection helpers (unit-tested) >>>
SPRINT_README_MARKER='managed by [sprint.md]'                               # in README_POINTER
SPRINT_AI_MARKER='single source of truth for how this project is organized' # in every AI pointer + AI_FALLBACK
SPRINT_GITIGNORE_MARKER='# === sprint.md Recommended Entries ==='            # header written into .gitignore

# already_ours MARKER CONTENT
# True (0) when CONTENT contains the fixed-string MARKER — i.e. text we wrote
# on a prior install. Pure: decides on the string passed in, does no file I/O,
# and uses a glob (not a regex) so marker characters are matched literally.
already_ours() {
    local marker="$1" content="$2"
    case "$content" in
        *"$marker"*) return 0 ;;
        *)           return 1 ;;
    esac
}

# gitignore_merge RECOMMENDED EXISTING
# Emit (stdout) the subset of the RECOMMENDED block whose entry lines are not
# already present in EXISTING, grouped into their original blank-line-delimited
# sections. A section whose entries are all duplicates is dropped along with
# its comment/header lines, so no orphaned headers appear. Empty output means
# "nothing new to add" — the idempotent case. Pure: a function of its two
# string arguments only, no file I/O, so it is unit-testable in isolation and
# separable from the interactive prompt flow that consumes its result.
gitignore_merge() {
    local recommended="$1" existing="$2"
    local filtered="" section_lines="" section_has_new=false line

    _flush_section() {
        if [ "$section_has_new" = true ] && [ -n "$section_lines" ]; then
            if [ -n "$filtered" ]; then
                filtered="${filtered}"$'\n'
            fi
            filtered="${filtered}${section_lines}"
        fi
        section_lines=""
        section_has_new=false
    }

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*$ ]]; then
            # Blank line = section boundary
            _flush_section
        elif [[ "$line" =~ ^# ]]; then
            # Comment/header — keep in section, decide when we flush
            section_lines="${section_lines}${line}"$'\n'
        elif ! grep -qxF -- "$line" <<< "$existing" 2>/dev/null; then
            # New entry — this section will be emitted
            section_lines="${section_lines}${line}"$'\n'
            section_has_new=true
        fi
        # Duplicate entries are silently dropped
    done <<< "$recommended"
    _flush_section

    printf '%s' "$filtered"
}
# <<< sprint.md detection helpers <<<

# Strict yes/no prompt — loops until the user gives an unambiguous answer.
# Sets the variable named in $1 to "yes" or "no". $2 is the prompt text.
# On EOF (closed stdin, e.g. piped/CI install) defaults to "no" so we never
# mutate user files without an explicit yes, and never hang.
prompt_yes_no() {
    local __varname="$1"
    local __prompt="$2"
    local __answer
    while true; do
        echo "$__prompt (yes/no)"
        if ! read -r __answer; then
            echo "  (no input — defaulting to no)"
            printf -v "$__varname" "no"
            return 0
        fi
        case "$__answer" in
            [Yy]|[Yy][Ee][Ss])  printf -v "$__varname" "yes"; return 0 ;;
            [Nn]|[Nn][Oo])      printf -v "$__varname" "no";  return 0 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

if [ ! -f "README.md" ]; then
    echo ""
    prompt_yes_no README_CHOICE "No README.md found. Create one with a sprint.md documentation pointer?"

    if [ "$README_CHOICE" = "yes" ]; then
        if printf '%s\n' "$README_POINTER" > "README.md" 2>/dev/null; then
            msg_success "Created README.md with documentation pointer"
            ((FILES_COPIED++))
        else
            msg_error "Failed to create README.md"
        fi
    else
        msg_step "Skipped README.md creation"
    fi
else
    if already_ours "$SPRINT_README_MARKER" "$(cat "README.md" 2>/dev/null)"; then
        msg_step "README.md already references DOCUMENTATION.md"
    else
        echo ""
        prompt_yes_no README_PREPEND_CHOICE "README.md exists but does not reference DOCUMENTATION.md. Prepend a sprint.md documentation pointer to it?"

        if [ "$README_PREPEND_CHOICE" = "yes" ]; then
            tmpfile=""
            tmpfile="$(mktemp "README.md.XXXXXX")" || tmpfile=""
            if [ -z "$tmpfile" ]; then
                msg_error "Failed to create temp file for README.md"
            else
                # Make sure a stray temp file never survives an interrupt
                # or a failed cat/mv. Cleared on successful mv below.
                trap 'rm -f "$tmpfile"' EXIT INT TERM
                if { printf '%s\n\n' "$README_POINTER"; cat "README.md"; } > "$tmpfile" 2>/dev/null \
                   && mv -f "$tmpfile" "README.md"; then
                    tmpfile=""
                    trap - EXIT INT TERM
                    msg_success "Prepended sprint.md documentation pointer to README.md"
                else
                    rm -f "$tmpfile"
                    tmpfile=""
                    trap - EXIT INT TERM
                    msg_error "Failed to prepend to README.md"
                fi
            fi
        else
            msg_step "Preserved README.md (no pointer added)"
        fi
    fi
fi

# ============================================================================
# COPY DISTRIBUTION FILES — single recursive walk of src/
# ============================================================================
#
# src/ mirrors the deployed layout: every file's relative path under src/
# matches its destination in the target project. The walk below copies each
# file, with behavior determined by list membership, not per-file routing.
#
# Behavior lists (relative paths under src/):
#   SKIP_FILES       — metadata, never copied (VERSION, .gitignore.template)
#   PREPEND_FILES    — AI instruction files: prepend-or-create, never overwrite
#   USER_TERRITORY   — copy only on fresh install; skip if file already exists
#   .github/**       — only copied when platform is github-based
#   Everything else  — standard overwrite via safe_copy

msg_header "Installing distribution files..."

SKIP_FILES=(
    "VERSION"
    ".gitignore.template"
    "GETSTARTED.md"
)

PREPEND_FILES=(
    "CLAUDE.md"
    "AGENTS.md"
    ".cursorrules"
    ".windsurfrules"
    ".github/copilot-instructions.md"
)

USER_TERRITORY=(
    "docs/sprintmd/config"
)

# Helper: check if a value is in an array
_in_list() {
    local needle="$1"; shift
    for item in "$@"; do
        [[ "$item" = "$needle" ]] && return 0
    done
    return 1
}

# Fallback content if source AI templates not found
AI_FALLBACK='Read `DOCUMENTATION.md` before making any changes. It is the single source of truth for how this project is organized, how tasks are managed, and how to use the sprint.md system.'

# setup_ai_file "source_template" "target_path" "display_name" [create]
# - If target doesn't exist and create=yes, create it (no prompt)
# - If target doesn't exist and create is unset, skip
# - If target exists without DOCUMENTATION.md reference, prepend automatically
# - If target already references DOCUMENTATION.md, skip
setup_ai_file() {
    local src="$1"
    local target="$2"
    local name="$3"
    local create="${4:-}"

    local content
    if [ -f "$src" ]; then
        content=$(cat "$src")
    else
        content="$AI_FALLBACK"
    fi

    if [ ! -f "$target" ]; then
        if [ "$create" = "yes" ]; then
            local target_dir
            target_dir="$(dirname "$target")"
            if [ "$target_dir" != "." ]; then
                safe_mkdir "$target_dir"
            fi

            if printf '%s\n' "$content" > "$target" 2>/dev/null; then
                msg_success "Created $name"
                ((FILES_COPIED++))
            else
                msg_error "Failed to create $name"
            fi
        fi
    else
        if already_ours "$SPRINT_AI_MARKER" "$(cat "$target" 2>/dev/null)"; then
            msg_step "$name already references DOCUMENTATION.md"
        else
            local tmpfile
            tmpfile="$(mktemp "${target}.XXXXXX")" || {
                msg_error "Failed to create temp file for $name"
                return 1
            }

            if { printf '%s\n' "$content"; echo ""; cat "$target"; } > "$tmpfile" 2>/dev/null; then
                mv -f "$tmpfile" "$target"
                msg_success "Prepended sprint.md reference to $name"
            else
                rm -f "$tmpfile"
                msg_error "Failed to prepend to $name"
            fi
        fi
    fi
}

# Human-friendly label for each AI instruction file path
_ai_label() {
    case "$1" in
        CLAUDE.md)                       echo "Claude Code / Claude" ;;
        .cursorrules)                    echo "Cursor" ;;
        .github/copilot-instructions.md) echo "GitHub Copilot" ;;
        AGENTS.md)                       echo "Agents.md (multi-agent)" ;;
        .windsurfrules)                  echo "Windsurf" ;;
        *)                               echo "$1" ;;
    esac
}

# --- Platform=none cleanup: remove sync workflows from prior installs ---
if [ "$PLATFORM" = "none" ]; then
    for wf in ".github/workflows/sync-tasks-to-issues.yml" ".github/workflows/sync-status-to-label.yml"; do
        if [ -f "$wf" ]; then
            if rm -f "$wf" 2>/dev/null; then
                msg_step "Removed $wf (opted out of sync)"
            else
                msg_warning "Could not remove $wf"
            fi
        fi
    done
fi

# --- Walk src/ and install each file by its relative path ---
# Uses a FIFO on fd 3 for find output so stdin stays available for interactive
# prompts inside setup_ai_file. (A plain pipe would steal stdin.)
PENDING_PREPEND=()
SRC_DIR="$SPRINTMD_SOURCE_DIR/src"
_find_fifo="$(mktemp -d)/find_fifo"
mkfifo "$_find_fifo"
find "$SRC_DIR" -type f -print0 > "$_find_fifo" &
exec 3< "$_find_fifo"
while IFS= read -r -d '' src_file <&3; do
    rel_path="${src_file#"$SRC_DIR"/}"

    # Skip metadata files
    if _in_list "$rel_path" "${SKIP_FILES[@]}"; then continue; fi

    # Platform filter: .github/** only for github-based platforms
    if [[ "$rel_path" == .github/* ]]; then
        if [ "$PLATFORM" = "none" ]; then
            continue
        fi
    fi

    # Prepend files (AI instruction files) — defer to after the walk so
    # interactive prompts are grouped together, not scattered among copies.
    if _in_list "$rel_path" "${PREPEND_FILES[@]}"; then
        PENDING_PREPEND+=("$src_file|$rel_path")
        continue
    fi

    # User territory — preserve existing file on update, merge new config keys
    if _in_list "$rel_path" "${USER_TERRITORY[@]}"; then
        if [ -f "$rel_path" ]; then
            if [ "$rel_path" = "docs/sprintmd/config" ]; then
                if merge_config "$SPRINTMD_SOURCE_DIR/src/docs/sprintmd/config" "docs/sprintmd/config"; then
                    msg_success "Updated docs/sprintmd/config (added new configuration options)"
                else
                    msg_step "Preserved docs/sprintmd/config (up to date)"
                fi
            else
                msg_step "Preserved $rel_path (user-territory)"
            fi
            continue
        fi
    fi

    # Standard copy
    safe_mkdir "$(dirname "$rel_path")"
    if safe_copy "$src_file" "$rel_path" "$rel_path"; then
        if [[ "$rel_path" == *.sh || "$rel_path" == *.py ]]; then
            chmod +x "$rel_path" 2>/dev/null || msg_warning "Could not make $rel_path executable"
        fi
        ((FILES_COPIED++))
    fi
done
exec 3<&-
rm -f "$_find_fifo" && rmdir "$(dirname "$_find_fifo")" 2>/dev/null

# --- Optional: GETSTARTED.md quickstart at the project root ---
# Skipped in the walk above (SKIP_FILES); placed only when the user opts in.
if [ -f "$SRC_DIR/GETSTARTED.md" ]; then
    echo ""
    prompt_yes_no GETSTARTED_CHOICE "Place the GETSTARTED.md in the project to help me get started?"
    if [ "$GETSTARTED_CHOICE" = "yes" ]; then
        if safe_copy "$SRC_DIR/GETSTARTED.md" "GETSTARTED.md" "GETSTARTED.md"; then
            ((FILES_COPIED++))
        fi
    else
        msg_step "Skipped GETSTARTED.md"
    fi
fi

# --- AI instruction files (deferred from the walk above) ---
# Grouped here so interactive create/prepend prompts appear together rather
# than scattered between file-copy messages.
if [ ${#PENDING_PREPEND[@]} -gt 0 ]; then
    msg_header "Setting up AI instruction files..."

    # Separate into files that already exist (handle silently) vs need creating
    NEED_CREATE=()
    for entry in "${PENDING_PREPEND[@]}"; do
        src_file="${entry%%|*}"
        rel_path="${entry#*|}"
        if [ -f "$rel_path" ]; then
            setup_ai_file "$src_file" "$rel_path" "$rel_path"
        else
            NEED_CREATE+=("$entry")
        fi
    done

    # Popularity-ordered list for the menu
    AI_ORDER=("CLAUDE.md" ".cursorrules" ".github/copilot-instructions.md" "AGENTS.md" ".windsurfrules")

    # Build ordered menu from files that need creating
    MENU_ENTRIES=()
    for ordered_path in "${AI_ORDER[@]}"; do
        for entry in "${NEED_CREATE[@]}"; do
            rel_path="${entry#*|}"
            if [ "$rel_path" = "$ordered_path" ]; then
                MENU_ENTRIES+=("$entry")
                break
            fi
        done
    done
    # Catch any entries not in AI_ORDER
    for entry in "${NEED_CREATE[@]}"; do
        rel_path="${entry#*|}"
        _found=false
        for ordered_path in "${AI_ORDER[@]}"; do
            if [ "$rel_path" = "$ordered_path" ]; then _found=true; break; fi
        done
        if ! $_found; then MENU_ENTRIES+=("$entry"); fi
    done

    if [ ${#MENU_ENTRIES[@]} -gt 0 ]; then
        echo ""
        echo "Which AI instruction files would you like to create?"
        echo ""
        for i in "${!MENU_ENTRIES[@]}"; do
            entry="${MENU_ENTRIES[$i]}"
            rel_path="${entry#*|}"
            label=$(_ai_label "$rel_path")
            printf "  %d) %s  (%s)\n" $((i + 1)) "$label" "$rel_path"
        done
        echo ""
        printf "  A) All of the above\n"
        echo ""
        echo "Enter choices (e.g. 1 3, or A for all, Enter to skip):"
        read -r AI_MENU_CHOICE

        # Parse selection
        SELECTED=()
        if [[ "$AI_MENU_CHOICE" =~ ^[Aa]$ ]]; then
            for i in "${!MENU_ENTRIES[@]}"; do
                SELECTED+=("$i")
            done
        else
            for token in $AI_MENU_CHOICE; do
                if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le ${#MENU_ENTRIES[@]} ]; then
                    SELECTED+=("$((token - 1))")
                fi
            done
        fi

        if [ ${#SELECTED[@]} -eq 0 ]; then
            msg_step "Skipped AI instruction files"
        else
            for idx in "${SELECTED[@]}"; do
                entry="${MENU_ENTRIES[$idx]}"
                src_file="${entry%%|*}"
                rel_path="${entry#*|}"
                setup_ai_file "$src_file" "$rel_path" "$rel_path" "yes"
            done
        fi
    fi
fi

# ============================================================================
# HANDLE .GITIGNORE
# ============================================================================

msg_header "Checking .gitignore..."

# Load gitignore content from template or use inline fallback
GITIGNORE_TEMPLATE="$SPRINTMD_SOURCE_DIR/src/.gitignore.template"
if [ -f "$GITIGNORE_TEMPLATE" ]; then
    GITIGNORE_CONTENT=$(cat "$GITIGNORE_TEMPLATE")
else
    # Fallback if template not found
    GITIGNORE_CONTENT="# OS Files
.DS_Store
Thumbs.db
desktop.ini

# Editor Files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary Files
*.tmp
*.temp
*.bak
*.log

# Environment and secrets
.env
.env.*
*.pem
*.key
secrets/

# Local data
docs/data/*.csv
docs/data/*.json
docs/data/*.db

# Design files (large binaries)
docs/designs/*.psd
docs/designs/*.sketch
docs/designs/*.fig"
fi

if [ ! -f ".gitignore" ]; then
    # No .gitignore exists
    echo ""
    echo "No .gitignore found. Would you like to create one with sprint.md recommended entries? (y/n)"
    read -r GITIGNORE_CHOICE

    if [[ "$GITIGNORE_CHOICE" =~ ^[Yy]$ ]]; then
        if echo "$GITIGNORE_CONTENT" > .gitignore 2>/dev/null; then
            msg_success "Created .gitignore"
        else
            msg_error "Failed to create .gitignore"
        fi
    else
        msg_step "Skipped .gitignore creation"
    fi
else
    # .gitignore exists. We deliberately do NOT gate on an incidental
    # "sprint.md" substring here — a stray path or comment mentioning it would
    # falsely skip the merge. Instead, gitignore_merge does authoritative
    # per-line dedup: it returns only the entries this file lacks (empty when
    # everything is already present), which is both the "already installed"
    # signal and idempotent on re-run.
    FILTERED_CONTENT="$(gitignore_merge "$GITIGNORE_CONTENT" "$(cat .gitignore 2>/dev/null)")"

    if [ -z "$FILTERED_CONTENT" ]; then
        msg_step ".gitignore already contains all recommended entries"
    else
        echo ""
        echo "Existing .gitignore found. Would you like to add sprint.md recommended entries?"
        echo "1) Prepend (add at the beginning)"
        echo "2) Append (add at the end)"
        echo "3) Skip"
        echo ""
        echo "Enter your choice (1-3):"
        read -r GITIGNORE_CHOICE

        case "$GITIGNORE_CHOICE" in
            1)
                # Prepend — atomic write via temp file so a partial
                # failure cannot truncate the original .gitignore
                EXISTING_CONTENT=$(cat .gitignore)
                TMPFILE=$(mktemp ".gitignore.tmp.XXXXXX" 2>/dev/null)
                if [ -z "$TMPFILE" ]; then
                    msg_error "Failed to create temp file for .gitignore"
                elif { echo "$SPRINT_GITIGNORE_MARKER"; printf '%s\n' "$FILTERED_CONTENT"; echo "# === Project-Specific Entries ==="; printf '%s\n' "$EXISTING_CONTENT"; } > "$TMPFILE" 2>/dev/null && mv -f "$TMPFILE" .gitignore 2>/dev/null; then
                    msg_success "Prepended sprint.md entries to .gitignore"
                else
                    msg_error "Failed to prepend to .gitignore"
                    rm -f "$TMPFILE" 2>/dev/null
                fi
                ;;
            2)
                # Append
                if { echo ""; echo "$SPRINT_GITIGNORE_MARKER"; printf '%s\n' "$FILTERED_CONTENT"; } >> .gitignore 2>/dev/null; then
                    msg_success "Appended sprint.md entries to .gitignore"
                else
                    msg_error "Failed to append to .gitignore"
                fi
                ;;
            *)
                msg_step "Skipped .gitignore modification"
                ;;
        esac
    fi
fi

# ============================================================================
# LAYOUT CLEANUP (path-presence only — no version ladder)
# ============================================================================
# setup.sh never deletes what is no longer in the distribution. Renames and
# consolidations leave behind folders/files that block a clean tree. Every
# check below is gated only on "does this path exist?" — not on product version.
# User work (task bodies, plan files) is moved; framework-owned files are removed.

# ── STATE.md → docs/sprintmd/DOC_STATE.md ────────────────────────────
if [ -f "docs/STATE.md" ] && [ ! -f "docs/sprintmd/DOC_STATE.md" ]; then
    safe_mkdir "docs/sprintmd"
    if mv docs/STATE.md docs/sprintmd/DOC_STATE.md 2>/dev/null; then
        msg_step "Moved docs/STATE.md → docs/sprintmd/DOC_STATE.md"
    fi
fi

# ── config.sh → flat docs/sprintmd/config (current keys only) ────────
# Hard cut: no dual-read of retired MODEL_TALK / MODEL_TASKS / etc. The
# shipped template is the source of truth; merge_config fills missing keys.
if [ -f "docs/sprintmd/config.sh" ] && [ ! -f "docs/sprintmd/config" ]; then
    echo ""
    echo "Replacing docs/sprintmd/config.sh with flat config (current keys)..."
    if safe_copy "$SPRINTMD_SOURCE_DIR/src/docs/sprintmd/config" "docs/sprintmd/config" "docs/sprintmd/config"; then
        mv "docs/sprintmd/config.sh" "docs/sprintmd/config.sh.bak" 2>/dev/null || true
        msg_success "Installed flat config (old config.sh backed up as config.sh.bak)"
        msg_step "Re-set CLI/models in docs/sprintmd/config if you had custom pins"
    fi
fi
# Drop a stale config.sh when the flat file already exists.
if [ -f "docs/sprintmd/config.sh" ] && [ -f "docs/sprintmd/config" ]; then
    mv "docs/sprintmd/config.sh" "docs/sprintmd/config.sh.bak" 2>/dev/null \
        && msg_step "Backed up obsolete docs/sprintmd/config.sh → config.sh.bak" || true
fi

# ── docs/tasks/live/ → done/ ─────────────────────────────────────────
if [ -d "docs/tasks/live" ]; then
    STALE_LIVE_COUNT=$(find "docs/tasks/live" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STALE_LIVE_COUNT" -gt 0 ]; then
        msg_header "Stale docs/tasks/live/ folder detected"
        echo "The lifecycle folder is done/ (not live/). Your live/ folder still has"
        echo "$STALE_LIVE_COUNT task file(s)."
        echo ""
        echo "Move files from live/ to done/? [Y]es/No"
        read -r LIVE_CLEANUP_CHOICE
        if [[ -z "$LIVE_CLEANUP_CHOICE" ]] || [[ "$LIVE_CLEANUP_CHOICE" =~ ^[Yy] ]]; then
            safe_mkdir "docs/tasks/done"
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                for f in docs/tasks/live/*.md; do
                    [ -f "$f" ] || continue
                    git mv "$f" "docs/tasks/done/" 2>/dev/null || mv "$f" "docs/tasks/done/"
                done
            else
                mv docs/tasks/live/*.md "docs/tasks/done/" 2>/dev/null || true
            fi
            rmdir "docs/tasks/live" 2>/dev/null || true
            msg_success "Moved task files from live/ to done/"
        fi
    else
        rmdir "docs/tasks/live" 2>/dev/null || true
    fi
fi

# ── docs/tasks/working/ → doing/ ─────────────────────────────────────
if [ -d "docs/tasks/working" ]; then
    STALE_WORKING_COUNT=$(find "docs/tasks/working" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STALE_WORKING_COUNT" -gt 0 ]; then
        msg_header "Stale docs/tasks/working/ folder detected"
        echo "The lifecycle folder is doing/ (not working/). Your working/ folder still has"
        echo "$STALE_WORKING_COUNT task file(s)."
        echo ""
        echo "Move files from working/ to doing/? [Y]es/No"
        read -r WORKING_CLEANUP_CHOICE
        if [[ -z "$WORKING_CLEANUP_CHOICE" ]] || [[ "$WORKING_CLEANUP_CHOICE" =~ ^[Yy] ]]; then
            safe_mkdir "docs/tasks/doing"
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                for f in docs/tasks/working/*.md; do
                    [ -f "$f" ] || continue
                    git mv "$f" "docs/tasks/doing/" 2>/dev/null || mv "$f" "docs/tasks/doing/"
                done
            else
                mv docs/tasks/working/*.md "docs/tasks/doing/" 2>/dev/null || true
            fi
            rmdir "docs/tasks/working" 2>/dev/null || true
            msg_success "Moved task files from working/ to doing/"
        fi
    else
        rmdir "docs/tasks/working" 2>/dev/null || true
    fi
fi

# ── docs/epics/ → docs/plans/ ────────────────────────────────────────
if [ -d "docs/epics" ]; then
    msg_header "Moving docs/epics/ → docs/plans/"
    safe_mkdir "docs/plans"
    for f in docs/epics/* docs/epics/.[!.]* docs/epics/..?*; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"
        case "$base" in
            .|..|.TEMPLATE-epic.md|.gitkeep) continue ;;
        esac
        if [ -e "docs/plans/$base" ]; then
            msg_warning "docs/plans/$base already exists — left docs/epics/$base in place"
            continue
        fi
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
           && git mv "$f" "docs/plans/$base" 2>/dev/null; then
            msg_step "git mv docs/epics/$base → docs/plans/$base"
        elif mv "$f" "docs/plans/$base" 2>/dev/null; then
            msg_step "mv docs/epics/$base → docs/plans/$base"
        else
            msg_warning "Could not move docs/epics/$base"
        fi
    done
    rm -f docs/epics/.TEMPLATE-epic.md docs/epics/.gitkeep 2>/dev/null || true
    if rmdir "docs/epics" 2>/dev/null; then
        msg_success "Removed empty docs/epics/"
    elif [ -d "docs/epics" ]; then
        msg_warning "docs/epics/ still has files — review and remove manually"
    fi
fi

# ── Retired framework files (safe to delete) ─────────────────────────
RETIRED_FRAMEWORK_FILES=(
    # talk → chat
    "docs/sprintmd/scripts/talk.sh"
    "docs/sprintmd/scripts/talk-bugs.sh"
    "docs/sprintmd/scripts/talk-folder.sh"
    "docs/sprintmd/scripts/talk-sprint.sh"
    "docs/sprintmd/help/talk.md"
    "docs/sprintmd/guides/use_talk.md"
    # define → gate
    "docs/sprintmd/scripts/define.sh"
    "docs/sprintmd/help/define.md"
    # tasks (execute) → work
    "docs/sprintmd/scripts/tasks.sh"
    "docs/sprintmd/help/tasks.md"
    # newepic → newplan
    "docs/sprintmd/scripts/create-epic.sh"
    "docs/sprintmd/help/newepic.md"
    "docs/epics/.TEMPLATE-epic.md"
    # look-family renames
    "docs/sprintmd/scripts/ai-context.sh"
    "docs/sprintmd/help/ai-context.md"
    "docs/sprintmd/help/checkfeatures.md"
    # keep-family / retired profession commands
    "docs/sprintmd/scripts/audit-deps.sh"
    "docs/sprintmd/help/audit-deps.md"
    "docs/sprintmd/scripts/audit-code.sh"
    "docs/sprintmd/scripts/audit-excellence.sh"
    "docs/sprintmd/scripts/audit-tasks.sh"
    "docs/sprintmd/help/audit.md"
    "docs/sprintmd/help/excellence.md"
    "docs/sprintmd/help/review-code.md"
    "docs/sprintmd/scripts/review-sprint.sh"
    "docs/sprintmd/help/review-sprint.md"
    # consolidated / removed guidance
    "docs/sprintmd/ai/task-writing-rules.md"
    "docs/sprintmd/ai/sprint-review.md"
    "docs/sprintmd/ai/.gitkeep"
    "docs/sprintmd/theory/feynman-method.md"
    # obsolete INDEX.md orientation pages
    "docs/INDEX.md"
    "docs/tasks/INDEX.md"
    "docs/bugs/INDEX.md"
    "docs/features/INDEX.md"
    "docs/designs/INDEX.md"
    "docs/examples/INDEX.md"
    "docs/data/INDEX.md"
    "docs/guides/INDEX.md"
    "docs/sprintmd/scripts/INDEX.md"
)

_retired_removed=0
for f in "${RETIRED_FRAMEWORK_FILES[@]}"; do
    if [ -f "$f" ]; then
        if git rm -f "$f" >/dev/null 2>&1 || rm -f "$f" 2>/dev/null; then
            msg_step "Removed retired $f"
            _retired_removed=$((_retired_removed + 1))
        else
            msg_warning "Could not remove retired $f"
        fi
    fi
done
if [ "$_retired_removed" -gt 0 ]; then
    msg_success "Pruned $_retired_removed retired framework file(s)"
fi
rmdir "docs/sprintmd/theory" 2>/dev/null || true

# ── Strip dead config keys (hard cut — no value carry to new names) ──
# Runtime only reads the current key set. Old pins (MODEL_TALK, BUDGET_TASKS,
# MODEL_REVIEW_SPRINT, …) are removed so they cannot confuse editors; re-set
# under the current names in docs/sprintmd/config if you still need them.
if [ -f "docs/sprintmd/config" ]; then
    _dead_keys=(
        MODEL_TALK MODEL_DEFINE MODEL_TASKS BUDGET_TASKS
        MODEL_REVIEW_SPRINT
        MODEL_PLAN
    )
    _cfg_tmp="$(mktemp "docs/sprintmd/config.XXXXXX")" || _cfg_tmp=""
    if [ -n "$_cfg_tmp" ]; then
        _dead_re='^(MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS|MODEL_REVIEW_SPRINT|MODEL_PLAN)='
        if grep -qE "$_dead_re" docs/sprintmd/config 2>/dev/null; then
            if grep -vE "$_dead_re" docs/sprintmd/config > "$_cfg_tmp" 2>/dev/null \
               && mv -f "$_cfg_tmp" docs/sprintmd/config; then
                msg_step "Removed retired model/budget keys from docs/sprintmd/config"
            else
                rm -f "$_cfg_tmp" 2>/dev/null
            fi
        else
            rm -f "$_cfg_tmp" 2>/dev/null
        fi
    fi
    unset _dead_keys _cfg_tmp _dead_re
fi

# ============================================================================
# AI CLI PICKER
# ============================================================================

msg_header "AI CLI configuration..."

CONFIG_FILE="docs/sprintmd/config"

# Source lib.sh if available (provides sprintmd_cfg / sprintmd_cfg_set)
_LIB_FILE="docs/sprintmd/lib.sh"
if [ -f "$_LIB_FILE" ]; then
    # shellcheck source=/dev/null
    source "$_LIB_FILE"
fi

# Detect current CLI on upgrade
CURRENT_CLI=""
if $UPDATE_MODE && [ -f "$CONFIG_FILE" ]; then
    if declare -F sprintmd_cfg >/dev/null 2>&1; then
        CURRENT_CLI=$(sprintmd_cfg CLI)
    else
        CURRENT_CLI=$(awk -F= '/^CLI=/ { print $2 }' "$CONFIG_FILE" | tail -1)
    fi
fi

echo ""
echo "Which AI CLI do you use?"
if $UPDATE_MODE && [ -n "$CURRENT_CLI" ]; then
    echo "  Current: $CURRENT_CLI"
fi
echo "  1) Claude"
echo "  2) Grok Build"
echo "  3) Cursor"
echo "  4) OpenAI / Codex"
echo "  5) Gemini"
echo "  6) Mistral"
echo "  7) Other"
echo ""
if $UPDATE_MODE && [ -n "$CURRENT_CLI" ]; then
    echo "Enter your choice (1-7, or press Enter to keep current):"
else
    echo "Enter your choice (1-7, or press Enter for Claude):"
fi
read -r CLI_CHOICE

case "$CLI_CHOICE" in
    1)  SELECTED_CLI="claude"       ;;
    2)  SELECTED_CLI="grok"         ;;
    3)  SELECTED_CLI="cursor-agent" ;;
    4)  SELECTED_CLI="codex"        ;;
    5)  SELECTED_CLI="gemini"       ;;
    6)  SELECTED_CLI="mistral"      ;;
    7)
        echo "Enter the CLI binary name:"
        read -r CUSTOM_CLI
        if [ -z "$CUSTOM_CLI" ]; then
            msg_warning "No binary name entered, defaulting to claude"
            SELECTED_CLI="claude"
        else
            SELECTED_CLI="$CUSTOM_CLI"
        fi
        ;;
    "")
        if $UPDATE_MODE && [ -n "$CURRENT_CLI" ]; then
            SELECTED_CLI="$CURRENT_CLI"
            echo "Keeping current: $SELECTED_CLI"
        else
            SELECTED_CLI="claude"
        fi
        ;;
    *)
        msg_warning "Invalid choice, defaulting to claude"
        SELECTED_CLI="claude"
        ;;
esac

# Derive the capability tier from the chosen CLI binary. This mirrors the
# inference in lib.sh:sprintmd_ai_tier exactly, so config and library agree.
case "$SELECTED_CLI" in
    claude)              SELECTED_PROVIDER="claude-code" ;;
    grok)                SELECTED_PROVIDER="grok-build"  ;;
    cursor-agent|cursor) SELECTED_PROVIDER="cursor"      ;;
    codex)               SELECTED_PROVIDER="openai"      ;;
    *)                   SELECTED_PROVIDER="generic"     ;;
esac

# Write CLI and provider tier into the config file
if [ -f "$CONFIG_FILE" ]; then
    if declare -F sprintmd_cfg_set >/dev/null 2>&1; then
        sprintmd_cfg_set CLI "$SELECTED_CLI"
        sprintmd_cfg_set PROVIDER "$SELECTED_PROVIDER"
    else
        for _kv in "CLI=${SELECTED_CLI}" "PROVIDER=${SELECTED_PROVIDER}"; do
            _k="${_kv%%=*}"
            if grep -q "^${_k}=" "$CONFIG_FILE"; then
                sed -i '' "s|^${_k}=.*|${_kv}|" "$CONFIG_FILE"
            else
                echo "$_kv" >> "$CONFIG_FILE"
            fi
        done
    fi
    msg_success "AI CLI set to: $SELECTED_CLI (provider tier: $SELECTED_PROVIDER)"
else
    msg_warning "Config file not found: $CONFIG_FILE"
fi

# Provider-specific instruction file. When Claude Code or Cursor is the tier,
# offer to create the matching AI instruction file if it doesn't exist yet.
# Grok Build auto-loads AGENTS.md / CLAUDE.md when present — no extra file
# invented here (plan 5 v1: none extra). Reuses prepend-never-clobber.
case "$SELECTED_PROVIDER" in
    claude-code) PROVIDER_AI_FILE="CLAUDE.md"    ;;
    cursor)      PROVIDER_AI_FILE=".cursorrules" ;;
    *)           PROVIDER_AI_FILE=""             ;;
esac
if [ -n "$PROVIDER_AI_FILE" ] && [ ! -f "$PROVIDER_AI_FILE" ] \
   && declare -F setup_ai_file >/dev/null 2>&1; then
    echo ""
    echo "Create the $(_ai_label "$PROVIDER_AI_FILE") instruction file (${PROVIDER_AI_FILE}) for your provider? [Y]es/No"
    read -r PROVIDER_FILE_CHOICE
    if [[ -z "$PROVIDER_FILE_CHOICE" ]] || [[ "$PROVIDER_FILE_CHOICE" =~ ^[Yy] ]]; then
        setup_ai_file "$SRC_DIR/$PROVIDER_AI_FILE" "$PROVIDER_AI_FILE" "$PROVIDER_AI_FILE" "yes"
    fi
fi

echo ""

# ============================================================================
# VALIDATION
# ============================================================================

msg_header "Running validation checks..."
VALIDATION_PASSED=true

# Check required directories
for dir in docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked docs/tasks/review docs/tasks/done docs/bugs docs/plans docs/sprintmd/scripts docs/features docs/guides; do
    if [ ! -d "$dir" ]; then
        VALIDATION_PASSED=false
        msg_error "Missing directory: $dir"
    fi
done

# Check required files
for file in docs/sprintmd/DOC_STATE.md DOCUMENTATION.md; do
    if [ ! -f "$file" ]; then
        VALIDATION_PASSED=false
        msg_error "Missing file: $file"
    fi
done

# Check script executability
for script in docs/sprintmd/scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script" 2>/dev/null || msg_warning "Could not make $script executable"
    fi
done

if [ -f "./sprint.sh" ] && [ ! -x "./sprint.sh" ]; then
    chmod +x ./sprint.sh 2>/dev/null || msg_warning "Could not make ./sprint.sh executable"
fi

# ============================================================================
# OPTIONAL: `sprint` shell shortcut
# ============================================================================
# Offer to add `alias sprint='./sprint.sh'` so the user can type `sprint <cmd>`
# from a project root instead of `./sprint.sh <cmd>`. The alias is relative on
# purpose: it always runs the sprint.sh of whatever project you are standing in,
# so it stays correct across multiple installs and versions. Strictly opt-in,
# fresh installs only, and writes only to the user's own shell rc — nothing
# global, nothing outside the project unless the user says yes. Full details
# (including a subdirectory-aware variant) live in
# docs/sprintmd/guides/sprint_command.md.

if ! $UPDATE_MODE; then
    case "$(basename "${SHELL:-}")" in
        zsh)  SPRINT_SHELL_RC="$HOME/.zshrc" ;;
        bash) SPRINT_SHELL_RC="$HOME/.bashrc" ;;
        *)    SPRINT_SHELL_RC="" ;;
    esac

    SPRINT_ALIAS_LINE="alias sprint='./sprint.sh'"

    if [ -z "$SPRINT_SHELL_RC" ]; then
        msg_step "To type 'sprint' instead of './sprint.sh', see docs/sprintmd/guides/sprint_command.md"
    elif [ -f "$SPRINT_SHELL_RC" ] && grep -qF "$SPRINT_ALIAS_LINE" "$SPRINT_SHELL_RC" 2>/dev/null; then
        msg_step "'sprint' shortcut already present in $SPRINT_SHELL_RC"
    else
        echo ""
        prompt_yes_no SPRINT_ALIAS_CHOICE "Add a 'sprint' shortcut so you can type 'sprint <cmd>' instead of './sprint.sh <cmd>'? (adds an alias to $SPRINT_SHELL_RC)"
        if [ "$SPRINT_ALIAS_CHOICE" = "yes" ]; then
            if printf '\n# sprint.md shortcut — runs ./sprint.sh from a project root (see docs/sprintmd/guides/sprint_command.md)\n%s\n' "$SPRINT_ALIAS_LINE" >> "$SPRINT_SHELL_RC" 2>/dev/null; then
                msg_success "Added 'sprint' shortcut to $SPRINT_SHELL_RC"
                msg_step "Run 'source $SPRINT_SHELL_RC' (or open a new terminal), then use 'sprint help'"
            else
                msg_warning "Could not write to $SPRINT_SHELL_RC — see docs/sprintmd/guides/sprint_command.md to add it manually"
            fi
        else
            msg_step "Skipped 'sprint' shortcut — see docs/sprintmd/guides/sprint_command.md to add it later"
        fi
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "================================================"
if [ "$VALIDATION_PASSED" = true ] && [ ${#ERRORS[@]} -eq 0 ]; then
    echo -e "  ${GREEN}Setup Complete - All Checks Passed!${NC}"
elif [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "  ${RED}Setup Complete - With Errors${NC}"
else
    echo -e "  ${YELLOW}Setup Complete - With Warnings${NC}"
fi
echo "================================================"

# Show error summary if any
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Errors (${#ERRORS[@]}):${NC}"
    for err in "${ERRORS[@]}"; do
        echo "  • $err"
    done
fi

# Show warning summary if any
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Warnings (${#WARNINGS[@]}):${NC}"
    for warn in "${WARNINGS[@]}"; do
        echo "  • $warn"
    done
fi

echo ""

if $UPDATE_MODE; then
    msg_success "sprint.md updated to version $CURRENT_VERSION"
    echo ""
    if [ -n "${ORIGINAL_VERSION:-}" ] && [ "$ORIGINAL_VERSION" != "$CURRENT_VERSION" ]; then
        echo "  Version:       $ORIGINAL_VERSION → $CURRENT_VERSION"
    else
        echo "  Version:       $CURRENT_VERSION (no change — files re-synced)"
    fi
    echo "  Files synced:  $FILES_COPIED"
    echo "  Scripts synced from src/ and DOC_STATE.md reconciled"
else
    msg_success "sprint.md installed to: $TARGET_PATH"
    echo "Platform: $PLATFORM"
    echo "Files installed: $FILES_COPIED"
    echo ""
    echo "Directory structure created in docs/"
    echo "Scripts available at docs/sprintmd/scripts/"
    echo "Documentation at DOCUMENTATION.md"
    echo "AI CLI/model config at docs/sprintmd/config (edit to change CLI or models)"
    echo ""
    echo "Get started:"
    echo "  ./sprint.sh profile                          # Prepare this system for your stack and design choices"
    echo "  ./sprint.sh newtask 'short task descriptor'  # Create a new task"
    echo "  ./sprint.sh newidea 'concept name'           # Outline a new concept"
    echo "  ./sprint.sh newfeature                       # Explain a feature you'd like to build or explain"
    echo ""
    echo "  ./sprint.sh help                             # Show all commands"
    echo ""
    echo "  Tip: type 'sprint' instead of './sprint.sh' — see docs/sprintmd/guides/sprint_command.md"
fi

echo ""

# Exit with error code if there were errors
if [ ${#ERRORS[@]} -gt 0 ]; then
    exit 1
fi
