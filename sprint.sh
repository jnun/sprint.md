#!/usr/bin/env bash
# Guard: requires bash (arrays, [[ ]], BASH_SOURCE, etc.).
# Running with sh/dash/zsh produces cryptic failures; refuse early.
# Place before set -u so an unset BASH_VERSION cannot trip nounset.
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: sprint.sh must be run with bash, not sh/zsh." >&2
    echo "Run it as:  ./sprint.sh  or  bash sprint.sh" >&2
    exit 1
fi

set -euo pipefail

# sprint.md CLI

# Colors — blanked when NO_COLOR is set (matches docs/sprintmd/lib.sh).
if [ -n "${NO_COLOR:-}" ]; then
    RED='' YELLOW='' BLUE='' CYAN='' NC=''
else
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

# Resolve project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/docs/sprintmd/scripts" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
else
    PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
fi

# Count files matching $2 (default *.md) directly under directory $1.
# Robust to empty/missing dirs (returns 0 via nullglob), spaces in the
# directory path (quoted) and in filenames (glob results are not
# word-split), and the caller's CWD (pass an absolute $1). nullglob is
# restored so callers see no global side effect.
count_files() {
    local dir="$1" pat="${2:-*.md}" restore
    local -a files
    restore="$(shopt -p nullglob)"
    shopt -s nullglob
    # shellcheck disable=SC2206  # $pat is an intentional glob, not a split risk
    files=( "$dir"/$pat )
    eval "$restore"
    echo "${#files[@]}"
}

# Utility: run helper script
run_script() {
    local script="$PROJECT_ROOT/docs/sprintmd/scripts/$1"
    shift
    if [ ! -f "$script" ]; then
        echo -e "${RED}ERROR: Script not found: $script${NC}"
        exit 1
    elif [ -x "$script" ]; then
        "$script" "$@"
    else
        # Fallback for filesystems that don't preserve the exec bit
        # (Windows volumes under WSL, Docker mounts, FAT32, some NFS/SMB,
        # git on Windows with core.fileMode=false, etc.). On those hosts
        # setup.sh's chmod +x silently no-ops, so we run via bash directly
        # rather than failing every command.
        bash "$script" "$@"
    fi
}

# Path to the command registry — the single source of truth for the catalog.
REGISTRY="$PROJECT_ROOT/docs/sprintmd/help/_registry"

# Print the registry rows for one group as aligned "  cmd usage   summary"
# lines. Every row is exactly 4 pipe-delimited fields (no field contains a
# pipe — see the registry header), so IFS splitting is safe.
print_command_group() {
    local want="$1"
    [ -f "$REGISTRY" ] || { echo "  (command registry missing: $REGISTRY)"; return; }
    local cmd group usage summary left
    while IFS='|' read -r cmd group usage summary; do
        cmd="${cmd//[[:space:]]/}"
        case "$cmd" in ''|'#'*) continue ;; esac
        group="${group//[[:space:]]/}"
        [ "$group" = "$want" ] || continue
        usage="${usage#"${usage%%[![:space:]]*}"}"; usage="${usage%"${usage##*[![:space:]]}"}"
        summary="${summary#"${summary%%[![:space:]]*}"}"; summary="${summary%"${summary##*[![:space:]]}"}"
        left="$cmd${usage:+ $usage}"
        printf "  %-32s %s\n" "$left" "$summary"
    done < "$REGISTRY"
}

show_help() {
    echo -e "${CYAN}sprint.md CLI${NC}"
    echo ""
    echo "Usage: ./sprint.sh [-c|-g] <command> [options]"
    echo ""
    echo -e "${BLUE}Provider (this run only — does not rewrite config):${NC}"
    echo "  -c, --claude                     Claude Code  (CLI=claude, PROVIDER=claude-code)"
    echo "  -g, --grok                       Grok Build   (CLI=grok, PROVIDER=grok-build)"
    echo "  Default comes from docs/sprintmd/config (or setup.sh). Env SPRINTMD_CLI /"
    echo "  SPRINTMD_PROVIDER also override. Examples: ./sprint.sh -g work"
    echo ""
    echo -e "${BLUE}Create:${NC}"
    print_command_group create
    echo ""
    echo -e "${BLUE}Chat:${NC}  (human in the loop)"
    print_command_group chat
    echo ""
    echo -e "${BLUE}Plan:${NC}  (compose the sprint — next/ IS the sprint)"
    print_command_group plan
    echo ""
    echo -e "${BLUE}Work:${NC}  (autonomous transform — spine: plan start → work)"
    print_command_group work
    echo ""
    echo -e "${BLUE}Look:${NC}  (read-only)"
    print_command_group look
    echo ""
    echo -e "${BLUE}Keep:${NC}  (housekeeping)"
    print_command_group keep
    echo ""
    echo "  help                             Show this message"
    echo "  help <command>                   Show details for a command (e.g. help work)"
    echo ""
}

show_command_help() {
    local cmd="$1"
    local helpfile="$PROJECT_ROOT/docs/sprintmd/help/$cmd.md"
    if [ ! -f "$helpfile" ]; then
        echo -e "${RED}Unknown command: $cmd${NC}"
        echo "Run ./sprint.sh help for a list of commands."
        exit 1
    fi
    echo -e "${CYAN}./sprint.sh $cmd${NC}"
    echo ""
    cat "$helpfile"
}

cmd_newidea() {
    # Optional name — same dual path as newfeature: no name = AI Q&A session.
    run_script "create-idea.sh" "$@"
}

cmd_newtask() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Task description required${NC}"; exit 1; }
    run_script "create-task.sh" "$@"
}

cmd_newfeature() {
    run_script "create-feature.sh" "$@"
}

cmd_newplan() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Plan name required${NC}"; echo "Usage: ./sprint.sh newplan \"<name>\" [task-id ...]"; exit 1; }
    run_script "create-plan.sh" "$@"
}

cmd_status() {
    local root="$PROJECT_ROOT"
    local tasks="$root/docs/tasks"

    echo -e "${CYAN}=== Project Status ===${NC}"
    echo ""

    echo -e "${BLUE}Tasks:${NC}"
    echo "  Backlog:  $(count_files "$tasks/backlog")"
    echo "  Next:     $(count_files "$tasks/next")"
    echo "  Doing:    $(count_files "$tasks/doing")"
    echo "  Blocked:  $(count_files "$tasks/blocked")"
    echo "  Review:   $(count_files "$tasks/review")"
    echo "  Done:     $(count_files "$tasks/done")"

    local blocked_count doing_count
    blocked_count=$(count_files "$tasks/blocked")
    if [ "$blocked_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}Blocked (needs attention to unblock sprint):${NC}"
        for task in "$tasks"/blocked/*.md; do
            [ -f "$task" ] && echo "  $(basename "$task" .md)"
        done
    fi

    doing_count=$(count_files "$tasks/doing")
    if [ "$doing_count" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}In progress:${NC}"
        for task in "$tasks"/doing/*.md; do
            [ -f "$task" ] && echo "  $(basename "$task" .md)"
        done
    fi

    local ideas_count bugs_count features_count
    ideas_count=$(count_files "$root/docs/ideas")
    if [ "$ideas_count" -gt 0 ]; then
        echo ""
        echo -e "${BLUE}Ideas:${NC}  $ideas_count"
    fi

    bugs_count=$(count_files "$root/docs/bugs" "[0-9]*.md")
    if [ "$bugs_count" -gt 0 ]; then
        echo ""
        echo -e "${BLUE}Bugs:${NC}   $bugs_count open"
    fi

    features_count=$(count_files "$root/docs/features")
    if [ "$features_count" -gt 0 ]; then
        echo ""
        echo -e "${BLUE}Features:${NC}"
        echo "  Backlog:  $(grep -l "Status:.*BACKLOG" "$root"/docs/features/*.md 2>/dev/null | wc -l | tr -d ' ')"
        echo "  Doing:    $(grep -l "Status:.*DOING" "$root"/docs/features/*.md 2>/dev/null | wc -l | tr -d ' ')"
        echo "  Done:     $(grep -l "Status:.*DONE" "$root"/docs/features/*.md 2>/dev/null | wc -l | tr -d ' ')"
    fi

    status_plans "$root"
}

# Resolve a member task ID to its current lifecycle folder name, or "" if no
# task file exists anywhere (member completed-and-archived, or a bare reference).
_task_folder() {
    local id="$1" root="$2" stage
    for stage in backlog next doing blocked review done; do
        if compgen -G "$root/docs/tasks/$stage/${id}-*.md" >/dev/null 2>&1; then
            printf '%s' "$stage"; return 0
        fi
    done
    return 1
}

# Roll up docs/plans/*.md as GROUPINGS, never as tasks: for each plan file,
# resolve its "- #ID" member lines to their current folders and report progress
# (review+done counted complete). The plan file is a relational index — it is
# listed here and never added to the task tallies above.
status_plans() {
    local root="$1"
    local sdir="$root/docs/plans"
    [ -d "$sdir" ] || return 0

    local printed=0 sf
    for sf in "$sdir"/*.md; do
        [ -f "$sf" ] || continue
        case "$(basename "$sf")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac

        if [ "$printed" -eq 0 ]; then
            echo ""
            echo -e "${BLUE}Plans:${NC}  (relational groupings — not a lifecycle stage)"
            printed=1
        fi

        local title id folder total=0 done=0 ids
        title="$(grep -m1 '^# ' "$sf" | sed 's/^# *//; s/^Plan [0-9]*: *//')"
        echo -e "  ${CYAN}$(basename "$sf" .md)${NC}  ${title}"

        ids=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$sf" 2>/dev/null | grep -oE '[0-9]+')
        for id in $ids; do
            total=$((total + 1))
            if folder=$(_task_folder "$id" "$root"); then
                case "$folder" in review|done) done=$((done + 1)) ;; esac
                echo "      #$id  $folder/"
            else
                done=$((done + 1))   # no file left = completed/archived
                echo "      #$id  (done or archived)"
            fi
        done
        if [ "$total" -eq 0 ]; then
            echo "      (no members yet)"
        else
            echo "      → $done/$total complete"
        fi
    done
}

cmd_newbug() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Bug description required${NC}"; exit 1; }
    run_script "create-bug.sh" "$1"
}

cmd_newtest() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Test name required${NC}"; exit 1; }
    run_script "create-test.sh" "$1"
}

cmd_search() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Search term required${NC}"; echo "Usage: ./sprint.sh search <keyword>"; exit 1; }
    run_script "search.sh" "$@"
}

cmd_profile() {
    run_script "profile.sh" "$@"
}

# With a task id: chat that one task through (chat.sh). With NO id: walk the
# whole sprint — chat.sh routes the empty arg to the sprint walkthrough. An empty
# arg is valid here, so there is no required-arg guard.
cmd_chat() {
    run_script "chat.sh" "$@"
}

# plan is a namespace for decisive plan verbs (think, start). Authoring is
# chat plan. plan.sh dispatches subcommands; the old auto-planner is retired.
cmd_plan() {
    run_script "plan.sh" "$@"
}

# gate: standalone READY-gate / folder quality report (off-spine).
cmd_gate() {
    run_script "gate.sh" "$@"
}

# work: execute the READY queue.
cmd_work() {
    run_script "work.sh" "$@"
}

cmd_loop() {
    run_script "loop.sh" "$@"
}

cmd_split() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Task file path required${NC}"; echo "Usage: ./sprint.sh split <path/to/task.md>"; exit 1; }
    run_script "split.sh" "$@"
}

# deps: dependency scan (keep family).
cmd_deps() {
    run_script "deps.sh" "$@"
}

cmd_polish() {
    run_script "polish.sh" "$@"
}

cmd_validate() {
    run_script "validate-tasks.sh" "$@"
}

cmd_cleanup() {
    run_script "cleanup-tmp.sh" "$@"
}

cmd_sync() {
    run_script "sync.sh" "$@"
}

# align: feature↔task alignment (impl file may stay check-alignment.sh).
cmd_align() {
    run_script "check-alignment.sh"
}

# context: AI context summary.
cmd_context() {
    run_script "context.sh"
}

# Global provider flags (leading only). This-run env override — does not rewrite
# docs/sprintmd/config. lib.sh prefers SPRINTMD_CLI / SPRINTMD_PROVIDER over config.
#   ./sprint.sh -g work          # Grok Build for this run
#   ./sprint.sh --claude chat 12 # Claude Code for this run
while [ $# -gt 0 ]; do
    case "$1" in
        -c|--claude)
            export SPRINTMD_CLI=claude
            export SPRINTMD_PROVIDER=claude-code
            shift
            ;;
        -g|--grok)
            export SPRINTMD_CLI=grok
            export SPRINTMD_PROVIDER=grok-build
            shift
            ;;
        -h|--help)
            # Leave for the main dispatcher (help with or without a command).
            break
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            echo "Global provider flags: -c/--claude, -g/--grok" >&2
            echo "Run ./sprint.sh help for commands." >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Intercept --help/-h on any command: ./sprint.sh work --help → help work
CMD="${1:-}"
if [ -n "$CMD" ] && [ "$CMD" != "help" ] && [ "$CMD" != "--help" ] && [ "$CMD" != "-h" ]; then
    for arg in "$@"; do
        if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
            show_command_help "$CMD"
            exit 0
        fi
    done
fi

# Main
case "$CMD" in
    newidea)       shift; cmd_newidea "$@" ;;
    newtask)       shift; cmd_newtask "$@" ;;
    newfeature)    shift; cmd_newfeature "$@" ;;
    newplan)       shift; cmd_newplan "$@" ;;
    newbug)        shift; cmd_newbug "$@" ;;
    newtest)       shift; cmd_newtest "$@" ;;
    status)        cmd_status ;;
    profile)       shift; cmd_profile "$@" ;;
    search)        shift; cmd_search "$@" ;;
    chat)          shift; cmd_chat "$@" ;;
    plan)          shift; cmd_plan "$@" ;;
    gate)          shift; cmd_gate "$@" ;;
    work)          shift; cmd_work "$@" ;;
    loop)          shift; cmd_loop "$@" ;;
    split)         shift; cmd_split "$@" ;;
    deps)          shift; cmd_deps "$@" ;;
    polish)        shift; cmd_polish "$@" ;;
    sync)          shift; cmd_sync "$@" ;;
    validate)      shift; cmd_validate "$@" ;;
    cleanup)       shift; cmd_cleanup "$@" ;;
    align)         cmd_align ;;
    context)       cmd_context ;;
    help|--help|-h) shift; if [ -n "${1:-}" ]; then show_command_help "$1"; else show_help; fi ;;
    "") show_help ;;
    *)
        echo -e "${RED}Unknown command: $CMD${NC}"
        show_help
        exit 1
        ;;
esac
