#!/usr/bin/env bash
# check-docs.sh — Detect drift between the flags a command's script parses
# and the flags its help/*.md documents. Run via: ./sprint.sh validate --docs
#
# Why this exists: help files drift out of sync with scripts every time a flag
# is added or renamed (this repo has churned tasks' flags through several
# variants). This gives a repeatable, zero-config check so drift is caught the
# next time it happens instead of shipping stale docs to users.
#
# How it works, and its limits:
#   - The command→script map is read from the dispatcher (sprint.sh), so it stays
#     correct as commands are added/renamed — no table to maintain here.
#   - A "flag" is a long option the script recognizes, detected from the two
#     idioms this codebase uses: case branches (`--foo)`) and literal argument
#     comparisons (`= "--foo"`). Flags passed through to an external CLI
#     (e.g. `--tools`, `--permissions`) are written as bare args, never as
#     case branches or `= "--foo"` comparisons, so they are correctly ignored.
#   - Inline commands with no helper script (e.g. status) have no flag surface
#     and are skipped. DOCUMENTATION.md is a curated quick-reference, not a
#     per-command doc, so it is intentionally out of scope here.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/docs/sprintmd/scripts" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
else
    PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
fi

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

DISPATCH="$PROJECT_ROOT/sprint.sh"
HELP_DIR="$PROJECT_ROOT/docs/sprintmd/help"
SCRIPTS_DIR="$PROJECT_ROOT/docs/sprintmd/scripts"

if [ ! -f "$DISPATCH" ] || [ ! -d "$HELP_DIR" ]; then
    echo -e "${RED}ERROR: Cannot find dispatcher (sprint.sh) or help/ dir.${NC}"
    echo "Run this from a SprintBias project root."
    exit 1
fi

# Resolve a command name to the helper script it dispatches to (empty for
# inline commands like `status` that call no run_script).
script_for_cmd() {
    local cmd="$1" fn
    fn=$(grep -oE "^[[:space:]]+${cmd}\)[[:space:]].*cmd_[a-z_]+" "$DISPATCH" 2>/dev/null \
         | grep -oE 'cmd_[a-z_]+' | head -1) || true
    [ -z "$fn" ] && return 0
    awk -v fn="$fn" '
        $0 ~ "^"fn"\\(\\)" { inside=1 }
        inside && /run_script "/ {
            match($0, /run_script "[^"]+"/); s=substr($0,RSTART,RLENGTH)
            sub(/run_script "/,"",s); sub(/"$/,"",s); print s; exit
        }
        inside && /^}/ { exit }
    ' "$DISPATCH"
}

# Long flags a script actually recognizes (case branches + `= "--foo"` compares).
# --help/-h and --demo are handled globally by the dispatcher (never parsed by a
# subcommand script), so ignore them.
script_flags() {
    local script="$1"
    [ -f "$script" ] || return 0
    {
        grep -oE '^[[:space:]]*--[a-z][a-z-]*(\|--[a-z][a-z-]*)*\)' "$script" 2>/dev/null || true
        grep -oE '= "?--[a-z][a-z-]*"?' "$script" 2>/dev/null || true
    } | grep -oE '\-\-[a-z][a-z-]*' | grep -vxE -- '--help|--demo' | sort -u || true
}

# Long flags a help file documents for THIS command.
#
# Help text legitimately illustrates third-party invocations — "pip list
# --outdated", "composer outdated", "cargo outdated" — whose flags are NOT flags
# of this sprint command. Greping every "--foo" token blind counted those and
# produced false "stale" drift reports (audit-deps ↔ --outdated was the first).
#
# So flags inside an EXAMPLE COMMAND for some other tool are skipped: on a line
# that does not name the sprint command, a flag preceded by an external command
# invocation (two bare command words in a row, e.g. "pip list --outdated") is an
# example and dropped. A line that names the sprint command documents this
# command's own usage, so its flags are always kept; prose keeps its flags too.
# Real parsed flags are always shown on a "./sprint.sh <cmd> --flag" usage line,
# so this never drops a flag the script actually recognizes.
help_flags() {
    awk '
        {
            line = $0
            if (line !~ /sprint/) {
                # Blank out "<cmd> <arg> --flag" external-command examples so the
                # trailing flag is not mistaken for one of this command'"'"'s flags.
                gsub(/[a-z][a-z0-9._\/-]* +[a-z][a-z0-9._\/-]* +--[a-z][a-z-]*/, " ", line)
            }
            while (match(line, /--[a-z][a-z-]*/)) {
                print substr(line, RSTART, RLENGTH)
                line = substr(line, RSTART + RLENGTH)
            }
        }
    ' "$1" 2>/dev/null | grep -vxE -- '--help|--demo' | sort -u || true
}

# Union of every flag any script in the suite parses. A flag a help file
# documents that this command's script doesn't parse is only genuinely stale
# if NO script parses it — otherwise it is a flag forwarded to a downstream
# command (e.g. `loop` forwards --audit/--fast to tasks), which is legitimate.
ALL_FLAGS=$(
    for s in "$SCRIPTS_DIR"/*.sh; do
        [ -f "$s" ] && script_flags "$s"
    done | sort -u
)

echo -e "${CYAN}=== Doc drift check (help/*.md vs script flags) ===${NC}"
echo ""

DRIFT=0
CHECKED=0

for helpfile in "$HELP_DIR"/*.md; do
    [ -f "$helpfile" ] || continue
    cmd=$(basename "$helpfile" .md)

    script_name=$(script_for_cmd "$cmd")
    [ -z "$script_name" ] && continue          # inline command: no flag surface
    script_path="$SCRIPTS_DIR/$script_name"
    [ -f "$script_path" ] || continue

    CHECKED=$((CHECKED + 1))
    sflags=$(script_flags "$script_path")
    hflags=$(help_flags "$helpfile")

    undoc=$(comm -23 <(printf '%s\n' "$sflags" | grep -v '^$' | sort) \
                     <(printf '%s\n' "$hflags" | grep -v '^$' | sort) || true)
    # Stale = documented here but parsed by NO script anywhere (forwarded
    # flags parsed by a downstream script are filtered out, not reported).
    stale=$(comm -13 <(printf '%s\n' "$ALL_FLAGS" | grep -v '^$' | sort) \
                     <(printf '%s\n' "$hflags" | grep -v '^$' | sort) || true)

    if [ -n "$undoc" ] || [ -n "$stale" ]; then
        DRIFT=1
        echo -e "${YELLOW}⚠ $cmd${NC}  (help/$cmd.md ↔ scripts/$script_name)"
        while IFS= read -r f; do
            [ -n "$f" ] && echo -e "    ${RED}undocumented${NC} $f — parsed by the script, absent from help"
        done <<< "$undoc"
        while IFS= read -r f; do
            [ -n "$f" ] && echo -e "    ${RED}stale${NC}        $f — in help, but the script no longer parses it"
        done <<< "$stale"
        echo ""
    fi
done

echo -e "${BLUE}Checked $CHECKED command(s) with a flag surface.${NC}"
if [ "$DRIFT" -eq 0 ]; then
    echo -e "${GREEN}✓ No flag drift between scripts and help docs.${NC}"
    exit 0
else
    echo -e "${RED}⚠ Flag drift found — update the help file or the script above.${NC}"
    exit 1
fi
