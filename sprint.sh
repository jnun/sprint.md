#!/usr/bin/env bash
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
    echo "Usage: ./sprint.sh <command> [options]"
    echo ""
    echo -e "${BLUE}Commands:${NC}"
    print_command_group create
    echo ""
    echo -e "${BLUE}Sprint pipeline:${NC}  (a sprint = the tasks currently in docs/tasks/next/)"
    print_command_group pipeline
    echo ""
    echo -e "${BLUE}Workflow:${NC}"
    print_command_group workflow
    echo ""
    echo -e "${BLUE}Sync:${NC}"
    print_command_group sync
    echo ""
    echo -e "${BLUE}Maintenance:${NC}"
    print_command_group maint
    echo ""
    echo "  help                             Show this message"
    echo "  help <command>                   Show details for a command (e.g. help tasks)"
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
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Idea name required${NC}"; exit 1; }
    run_script "create-idea.sh" "$1"
}

cmd_newtask() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Task description required${NC}"; exit 1; }
    run_script "create-task.sh" "$@"
}

cmd_newfeature() {
    run_script "create-feature.sh" "$@"
}

cmd_newepic() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Epic name required${NC}"; echo "Usage: ./sprint.sh newepic \"<name>\" [task-id ...]"; exit 1; }
    run_script "create-epic.sh" "$@"
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

    status_epics "$root"
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

# Roll up docs/epics/*.md as GROUPINGS, never as tasks: for each epic file,
# resolve its "- #ID" member lines to their current folders and report progress
# (review+done counted complete). The epic file is a relational index — it is
# listed here and never added to the task tallies above.
status_epics() {
    local root="$1"
    local sdir="$root/docs/epics"
    [ -d "$sdir" ] || return 0

    local printed=0 sf
    for sf in "$sdir"/*.md; do
        [ -f "$sf" ] || continue
        case "$(basename "$sf")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac

        if [ "$printed" -eq 0 ]; then
            echo ""
            echo -e "${BLUE}Epics:${NC}  (relational groupings — not a lifecycle stage)"
            printed=1
        fi

        local title id folder total=0 done=0 ids
        title="$(grep -m1 '^# ' "$sf" | sed 's/^# *//; s/^Epic [0-9]*: *//')"
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

# With a task id: talk that one task through (talk.sh). With NO id: walk the
# whole sprint — talk.sh routes the empty arg to the sprint walkthrough. An empty
# arg is valid here, so there is no required-arg guard.
cmd_talk() {
    run_script "talk.sh" "$@"
}

cmd_plan() {
    run_script "plan.sh" "$@"
}

# Deprecated: the Plan step is now `plan` (the CLI's own name made `sprint` stutter).
# Thin shim keeps muscle memory working — warns, then forwards to cmd_plan.
cmd_sprint() {
    echo -e "${YELLOW}sprint is now plan — running plan${NC}"
    cmd_plan "$@"
}

cmd_define() {
    run_script "define.sh" "$@"
}

cmd_tasks() {
    run_script "tasks.sh" "$@"
}

cmd_loop() {
    run_script "loop.sh" "$@"
}

cmd_split() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: Task file path required${NC}"; echo "Usage: ./sprint.sh split <path/to/task.md>"; exit 1; }
    run_script "split.sh" "$@"
}

cmd_review_sprint() {
    run_script "review-sprint.sh" "$@"
}

# Deprecated: triage folded into talk. `talk <folder>` (blocked/next/backlog) is
# the per-folder sweep; bare `talk` walks the whole sprint. This shim forwards to
# the no-arg sprint walk so muscle memory survives. triage's old numeric [limit]
# arg is GUARDED — never forwarded, or bare `talk N` would read it as a task id.
cmd_triage() {
    echo -e "${YELLOW}triage is now part of talk — running the sprint walk. Use 'talk <folder>' (blocked/next/backlog) to sweep one folder, or 'talk <id>' for one task.${NC}"
    cmd_talk
}

cmd_audit() {
    run_script "audit-tasks.sh" "$@"
}

cmd_audit_deps() {
    run_script "audit-deps.sh" "$@"
}

cmd_review_code() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: File path(s) required${NC}"; echo "Usage: ./sprint.sh review-code <task.md> [max-passes]"; echo "       ./sprint.sh review-code <file1> <file2> ... [-- max-passes]"; exit 1; }
    run_script "audit-code.sh" "$@"
}

cmd_excellence() {
    [ -z "${1:-}" ] && { echo -e "${RED}ERROR: File path(s) required${NC}"; echo "Usage: ./sprint.sh excellence <task.md>"; echo "       ./sprint.sh excellence <file1> <file2> ..."; exit 1; }
    run_script "audit-excellence.sh" "$@"
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

cmd_checkfeatures() {
    run_script "check-alignment.sh"
}

cmd_ai_context() {
    run_script "ai-context.sh"
}

# Intercept --help/-h on any command: ./sprint.sh tasks --help → help tasks
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
    newepic)       shift; cmd_newepic "$@" ;;
    newbug)        shift; cmd_newbug "$@" ;;
    newtest)       shift; cmd_newtest "$@" ;;
    status)        cmd_status ;;
    profile)       shift; cmd_profile "$@" ;;
    search)        shift; cmd_search "$@" ;;
    find)          echo -e "${YELLOW}find has been retired — use 'talk <id>' to refine a task or 'tasks' to execute the sprint.${NC}" ;;
    plan)          shift; cmd_plan "$@" ;;
    talk)          shift; cmd_talk "$@" ;;
    sprint)        shift; cmd_sprint "$@" ;;
    define)        shift; cmd_define "$@" ;;
    tasks)         shift; cmd_tasks "$@" ;;
    loop)          shift; cmd_loop "$@" ;;
    split)         shift; cmd_split "$@" ;;
    review-sprint) shift; cmd_review_sprint "$@" ;;
    triage)        shift; cmd_triage "$@" ;;
    audit)         shift; cmd_audit "$@" ;;
    audit-deps)    shift; cmd_audit_deps "$@" ;;
    review-code)   shift; cmd_review_code "$@" ;;
    excellence)    shift; cmd_excellence "$@" ;;
    polish)        shift; cmd_polish "$@" ;;
    sync)          shift; cmd_sync "$@" ;;
    validate)      shift; cmd_validate "$@" ;;
    cleanup)       shift; cmd_cleanup "$@" ;;
    checkfeatures) cmd_checkfeatures ;;
    ai-context)    cmd_ai_context ;;
    help|--help|-h) shift; if [ -n "${1:-}" ]; then show_command_help "$1"; else show_help; fi ;;
    "") show_help ;;
    *)
        echo -e "${RED}Unknown command: $CMD${NC}"
        show_help
        exit 1
        ;;
esac
