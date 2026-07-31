# shellcheck shell=bash
# docs/sprintmd/lib.sh — shared helper library for sprint.md scripts
# Sourced (not executed) — no shebang or set -euo pipefail; the caller provides those.
#
# Source this once at the top of any script that needs config or AI access:
#
#     source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
#
# Provides:
#   Colours: RED GREEN YELLOW BLUE CYAN DIM BOLD NC
#   sed_escape STRING          — escape special chars for sed replacement
#   sed_inplace ARGS...        — portable in-place sed (macOS + Linux)
#   move_file SRC DEST         — git mv SRC DEST || mv SRC DEST (lifecycle rule)
#   sprintmd_move_rule         — one-line move rule for AI prompts (same behavior)
#   run_with_timeout SECS CMD… — portable timeout (coreutils, gtimeout, or shell)
#   run_with_timeout_dots SECS CMD… — same, with progress dots on the TTY while waiting
#   kebab_case STRING          — lowercase, hyphenated slug
#   sprintmd_slug NAME [MAX]    — kebab_case + length cap + empty guard (returns 1)
#   sprintmd_cfg KEY            — read a value from docs/sprintmd/config
#   sprintmd_cfg_set KEY VALUE  — update or append a value in config
#   sprintmd_resolve_model SFX  — model resolution: env > config > default
#   sprintmd_tier_model SFX     — sprintmd_resolve_model; strong default on
#       claude-code (opus) and grok-build (grok-4.5) when config is empty
#   sprintmd_profile_line       — one-line pointer to project.md (empty if absent)
#   sprintmd_conversation_method — contents of ai/conversation.md (loud fail if missing)
#   sprintmd_next_blocked_resolution — prompt block: walk one next→blocked BLOCKER
#       (two-path choice, demote inline for B, hand off to chat for A). Shared
#       by chat-sprint.sh and the chat-next folder walk so the logic is written once.
#   sprintmd_find_task ID [dirs…] — resolve a task file by numeric ID
#   sprintmd_review_verdict FILE — READY/BLOCKED/COMPLETE stamp from a gate review
#   sprintmd_log_path KIND NAME — timestamped log path under docs/tmp
#   sprintmd_load_profile [cli] — source the provider profile (sprintmd_provider_exec)
#   sprintmd_ai_tier            — capability tier: claude-code|grok-build|cursor|openai|generic
#   sprintmd_ai_mode            — "emit" or "exec" for the current environment
#   sprintmd_orchestration_capable — true for tiers with emit subagent fan-out
#       (claude-code, grok-build)
#   sprintmd_subagent_tool_name — "Task tool" | "spawn_subagent" for prompt wording
#   sprintmd_subagent_spawn_phrase [purpose] — "Launch a NEW subagent …" fragment
#   sprintmd_subagent_own_fresh — "its OWN fresh subagent (…)" fragment
#   sprintmd_subagent_parallel_dispatch — parallel fan-out instruction line
#   sprintmd_emitted            — true if the last sprintmd_run only emitted a prompt
#   sprintmd_announce_provider  — once per process: ▸ Provider: cli (tier) · mode: …
#   sprintmd_run ARGS…          — run AI: emit prompt to stdout, or exec the CLI
#   sprintmd_interactive_ok     — true if a live session is possible (exec mode,
#       interactive-capable provider, real TTY) — one source of truth
#   sprintmd_run_interactive A… — like sprintmd_run, but the exec path is a live
#       back-and-forth session (inherits the terminal) instead of one-shot
#   sprintmd_change_manifest TASK_FILE [FILE…] — build audit change manifest;
#       sets SPRINTMD_CHANGED_FILES and SPRINTMD_CONTEXT_SOURCE
#   sprintmd_parse_verdict TOKENS — (stdin) last VERDICT token, case/format tolerant
#   sprintmd_extract_summary JSON — print the summary text from a CLI JSON log

_SPRINTMD_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────
# Honour NO_COLOR by blanking the codes. Consumed by sourcing scripts.
# shellcheck disable=SC2034
if [ -n "${NO_COLOR:-}" ]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' DIM='' BOLD='' NC=''
else
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; DIM=$'\033[2m'
    BOLD=$'\033[1m';   NC=$'\033[0m'
fi

# ── Shell utilities ──────────────────────────────────────────────────

sed_escape() {
    printf '%s' "$1" | sed 's;[&/\\];\\&;g'
}

# Detect GNU vs BSD sed once per invocation — `sed --version` is a subprocess
# and sed_inplace runs in hot loops (config writes, task rewrites).
_SPRINTMD_SED_GNU=""
sed_inplace() {
    if [ -z "$_SPRINTMD_SED_GNU" ]; then
        if sed --version 2>/dev/null | grep -q GNU; then
            _SPRINTMD_SED_GNU=1
        else
            _SPRINTMD_SED_GNU=0
        fi
    fi
    if [ "$_SPRINTMD_SED_GNU" = 1 ]; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# Lifecycle move rule (agents + shell share this):
#   git mv SRC DEST || mv SRC DEST
# Always try git mv first (preserves history when tracked). When it fails —
# usual for new tasks not yet committed — finish the same move with plain mv.
move_file() {
    git mv "$1" "$2" 2>/dev/null || mv "$1" "$2"
}

# One-line rule for AI system prompts that tell a model to move task files.
# Same behavior as move_file. Include this string once; show concrete
# `git mv … || mv …` lines for each destination.
sprintmd_move_rule() {
    printf '%s' "Always move task files with: git mv SRC DEST || mv SRC DEST. Run git mv first (preserves history when tracked). When git mv fails — usual for new tasks not yet committed — finish that same move with plain mv, then continue. Leave git commit to the developer unless they asked you to commit."
}

# Portable timeout: run_with_timeout SECONDS CMD [ARGS…]
# For external programs, prefer GNU coreutils `timeout` (or `gtimeout` on
# macOS). Neither can exec a *shell function* — they only run programs on
# PATH — so when the target is a function (e.g. sprintmd_run) we always take
# the shell-watchdog path, which backgrounds the function and kills it on
# expiry. This keeps the timeout guarantee everywhere without export -f /
# bash -c gymnastics. Returns the command's exit code.
run_with_timeout() {
    local secs="$1"; shift
    if [ "$(type -t "${1:-}")" != "function" ]; then
        if command -v timeout >/dev/null 2>&1; then
            timeout "${secs}s" "$@"; return $?
        elif command -v gtimeout >/dev/null 2>&1; then
            gtimeout "${secs}s" "$@"; return $?
        fi
    fi
    # Shell watchdog: handles shell functions and hosts without coreutils.
    # disown the watcher so bash doesn't print a "Terminated" job-control
    # notice when we kill it after the command finishes ahead of the timeout.
    "$@" &
    local pid=$!
    { sleep "$secs" && kill "$pid" 2>/dev/null; } &
    local watcher=$!
    disown "$watcher" 2>/dev/null
    wait "$pid" 2>/dev/null
    local ret=$?
    kill "$watcher" 2>/dev/null
    pkill -P "$watcher" 2>/dev/null
    return $ret
}

# run_with_timeout_dots SECONDS CMD [ARGS…]
# Same timeout contract as run_with_timeout, plus a simple progress ticker so
# long headless AI calls (chat backlog verdicts, etc.) do not look hung.
# Dots go to /dev/tty (or stderr) so they stay visible under
#   out=$(run_with_timeout_dots …)
# Command stdout is captured and replayed on this function's stdout when the
# command finishes — callers still parse the real result. Command stderr is
# discarded during the wait (triage callers already silenced it); banners that
# write /dev/tty (sprintmd_announce_provider) still show.
run_with_timeout_dots() {
    local secs="$1"; shift
    local tmp pid ret n=0 out

    tmp=$(mktemp "${TMPDIR:-/tmp}/sprintmd-wait.XXXXXX") || return 1

    run_with_timeout "$secs" "$@" >"$tmp" 2>/dev/null &
    pid=$!

    out=/dev/tty
    if ! { true >"$out"; } 2>/dev/null; then
        out=/dev/stderr
    fi

    while kill -0 "$pid" 2>/dev/null; do
        # Plain dots, wrapping so they "cross" the terminal over long waits.
        printf '.' >"$out" 2>/dev/null || true
        n=$((n + 1))
        if [ $((n % 48)) -eq 0 ]; then
            printf '\n' >"$out" 2>/dev/null || true
        fi
        sleep 1
    done
    wait "$pid" 2>/dev/null
    ret=$?

    if [ "$n" -gt 0 ]; then
        printf '\n' >"$out" 2>/dev/null || true
    fi

    cat "$tmp"
    rm -f "$tmp"
    return "$ret"
}

# kebab_case "Some Title!" -> "some-title"
kebab_case() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-zA-Z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# sprintmd_slug NAME [MAXLEN] -> a filename-safe slug for NAME.
# kebab-cases NAME, caps it to MAXLEN chars (default 50) and trims any trailing
# hyphen the cut leaves behind. Prints the slug on stdout; a truncation note
# goes to stderr so it never pollutes command-substitution capture. Returns 1
# with empty output when NAME has no slug-able characters (all symbols/unicode)
# so callers reject it instead of writing "NNN-.md" or a hidden ".md".
sprintmd_slug() {
    local name="$1" max="${2:-50}" slug
    slug="$(kebab_case "$name")"
    if [ "${#slug}" -gt "$max" ]; then
        slug="${slug:0:$max}"
        slug="${slug%-}"
        echo -e "${YELLOW}Note: Filename truncated to $max characters${NC}" >&2
    fi
    [ -n "$slug" ] || return 1
    printf '%s' "$slug"
}

SPRINTMD_CONFIG_FILE="${SPRINTMD_CONFIG_FILE:-${_SPRINTMD_LIB_DIR}/config}"

# ── Config reader ────────────────────────────────────────────────────
# Reads KEY from the flat config file. Returns empty string if the key
# is absent or the file doesn't exist.
sprintmd_cfg() {
    local key="$1"
    [ -f "$SPRINTMD_CONFIG_FILE" ] || return 0
    awk -F= -v k="$key" '!/^[[:space:]]*#/ && $1 == k { print substr($0, length(k)+2) }' "$SPRINTMD_CONFIG_FILE" | tail -1
}

# ── Config writer ────────────────────────────────────────────────────
# Updates a key in-place, or appends it if not present.
sprintmd_cfg_set() {
    local key="$1" value="$2"
    if [ ! -f "$SPRINTMD_CONFIG_FILE" ]; then
        echo "${key}=${value}" > "$SPRINTMD_CONFIG_FILE"
        return
    fi
    if grep -q "^${key}=" "$SPRINTMD_CONFIG_FILE"; then
        # Escape the replacement for a |-delimited sed s-command: a literal
        # |, &, or \ in the value would otherwise corrupt the substitution.
        local esc_value
        esc_value=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
        sed_inplace "s|^${key}=.*|${key}=${esc_value}|" "$SPRINTMD_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$SPRINTMD_CONFIG_FILE"
    fi
}

# ── Model resolver ───────────────────────────────────────────────────
# Usage: model=$(sprintmd_resolve_model WORK)
#
# Precedence: env SPRINTMD_MODEL_<SUFFIX> > config MODEL_<SUFFIX>
#             > config MODEL_DEFAULT > empty (CLI picks its own)
sprintmd_resolve_model() {
    local suffix="$1"
    local env_var="SPRINTMD_MODEL_${suffix}"

    # Environment variable wins
    if [ "${!env_var+set}" = "set" ]; then
        printf '%s' "${!env_var}"
        return
    fi

    # Config per-script model
    local val
    val=$(sprintmd_cfg "MODEL_${suffix}")
    if [ -n "$val" ]; then
        printf '%s' "$val"
        return
    fi

    # Config global default
    val=$(sprintmd_cfg "MODEL_DEFAULT")
    printf '%s' "$val"
}

# ── Tier-aware model resolver ────────────────────────────────────────
# Usage: model=$(sprintmd_tier_model FEATURE)
#
# Like sprintmd_resolve_model, but when nothing is configured (env/config both
# empty) and the provider tier supports model selection, fall back to a strong
# default instead of letting the CLI pick a cheaper one. For interactive,
# reasoning-heavy flows — feature Q&A, idea Feynman, chat — the best model is
# worth it unless the user has pinned one.
#   claude-code → opus
#   grok-build  → grok-4.5 (re-verify with `grok models` if the product renames)
# Other tiers return empty (their default.sh passthrough would only warn).
sprintmd_tier_model() {
    local suffix="$1" model
    model="$(sprintmd_resolve_model "$suffix")"
    if [ -z "$model" ]; then
        case "$(sprintmd_ai_tier)" in
            claude-code) model="opus" ;;
            grok-build)  model="grok-4.5" ;;
        esac
    fi
    printf '%s' "$model"
}

# ── Task helpers ─────────────────────────────────────────────────────

# Emit a "read project.md" line if a profile exists (else nothing).
# Always returns 0 so it is safe in `var=$(sprintmd_profile_line)` under set -e.
sprintmd_profile_line() {
    [ -f "docs/sprintmd/project.md" ] || return 0
    printf '%s' "
Also read docs/sprintmd/project.md for project-specific stack and conventions."
}

# Load the shared Conversation Method (docs/sprintmd/ai/conversation.md) for
# injection into interactive chat prompts. Prints the file body on stdout.
# Loud-fails (message on stderr, return 1) if the file is missing — callers that
# need the method must not continue without it. Walk-agnostic: same text for
# chat <id>, chat bugs [d], chat-sprint, and (later) chat plan.
sprintmd_conversation_method() {
    local f="$_SPRINTMD_LIB_DIR/ai/conversation.md"
    if [ ! -f "$f" ]; then
        echo -e "${RED}ERROR: Conversation Method missing: $f${NC}" >&2
        echo "Expected docs/sprintmd/ai/conversation.md (shipped with sprint.md)." >&2
        return 1
    fi
    cat "$f"
}

# ── Shared walkthrough instruction: resolving a next→blocked BLOCKER ──
# A next/ task that depends on a task still parked in blocked/ can never run —
# the executor silently HOLDS it until the dependency leaves blocked/. Both the
# no-id sprint walk (chat-sprint.sh) and the folder walk (chat next) surface this
# edge, and BOTH must resolve it the same way. Written once here so neither
# reimplements — and drifts from — the other.
#
# Emits the prompt block that tells the conversational layer how to walk ONE such
# edge: present the two real paths as a choice, action Path B (demote) inline,
# hand Path A (define the dependency) off to chat's fresh-context chain, and gate
# the drop path behind an on-the-spot edge audit. Path A's hand-off mirrors
# chat.sh's own emit-vs-exec split: an emit-mode orchestration-capable session
# (claude-code / grok-build) can spawn a fresh subagent; every other environment
# prints the command to run in a fresh window. Always returns 0 so it is safe
# in `x=$(sprintmd_next_blocked_resolution)`.
sprintmd_next_blocked_resolution() {
    local path_a
    if [ "$(sprintmd_ai_mode)" = "emit" ] && sprintmd_orchestration_capable; then
        path_a="Hand this off to a FRESH context — do NOT redefine the dependency inline here. $(sprintmd_subagent_spawn_phrase "the blocked dependency"), aimed at the MOST-UPSTREAM undefined one first (the dependency whose own '**Depends on**' has no undefined deps left; break ties by lowest id). Its entire instruction: 'Run ./sprint.sh chat <dep-id> and carry that task as far toward READY as you can on your own — read any *Context from chat* note in its file, refine it, and if a question genuinely needs the human, leave it in the file's ## Questions section and report it back.' Tell the user you spun up a fresh agent for <dep-id> and say in one line what it is picking up."
    else
        path_a="Hand this off — do NOT redefine the dependency inline here. Tell the user the exact command to run in a FRESH window:  ./sprint.sh chat <dep-id>  (for the most-upstream undefined dependency). Keeping each session's context small is the point of chaining out."
    fi
    printf '%s' "─── RESOLVING A next→blocked BLOCKER (dependent task <D> in next/ depends on task <B> in blocked/) ───
A next/ task that depends on a task still sitting in blocked/ can NEVER run: the executor ('work') silently HOLDS it until the dependency leaves blocked/. Do not merely report this — close the loop. Present the TWO REAL paths as an explicit choice and act on the one the user picks. Do NOT frame 'drop the Depends on line' as a way out of a genuine block — that only makes <D> LOOK runnable while the work it needs is still undone (the folder-satisfaction trap).

PATH A — DEFINE THE BLOCKED DEPENDENCY <B> (choose when the dependency is real and still needed):
${path_a}
Either way, chat's own close-the-loop branch re-enters the sprint only through the shared gate (bash docs/sprintmd/scripts/promote-to-sprint.sh <B-file>) — READY → next/, BLOCKED stays with a reason — which makes <D> runnable when gate grades READY. You do not rebuild that machinery here; you point at chat <B>.

PATH B — DEMOTE THE DEPENDENT TASK <D> BACK TO backlog/ (choose to pull it out of the sprint):
On the user's OK, action this INLINE: move <D> out of the sprint so next/ holds no work blocked on an undefined task —  git mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file> || mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file>. THEN RE-SCAN next/ for any OTHER task that also depends on <B>: the preflight already emitted a SEPARATE BLOCKER finding for each (next task, blocked dep) pair, so <B>'s other dependents are already in the findings list — recognize them by the same blocked id <B>, do not run a fresh board scan. Only when NONE remain may you say 'the sprint no longer contains work blocked on <B>.' If siblings remain, name them and offer to resolve each in turn (A or B).

THE DROP PATH — a metadata correction for a STALE or SPURIOUS edge ONLY, and only after an on-the-spot audit:
Dropping the '**Depends on**:' line is NOT one of the two resolution paths above. It is reserved for an edge that is not a genuine dependency. Before you may even offer it, AUDIT THE EDGE on the spot — a bounded, READ-ONLY reasoning step, NOT a gate pass: read WHY <D> needed <B> (what <D>'s Problem/Success actually required from <B>) and check whether that need is already satisfied elsewhere or has become obsolete. ONLY an edge that FAILS this audit (need already met / no longer needed) may be dropped from <D>'s Depends on line. An edge whose need still stands IS a real dependency: route to A or B, never drop. No audit, no drop."
}

# Resolve a task file by numeric ID. Prints "path<TAB>stage-dir" on success.
# Default search order matches the task lifecycle.
sprintmd_find_task() {
    local id="$1"; shift
    local dirs=("$@")
    if [ ${#dirs[@]} -eq 0 ]; then
        dirs=(docs/tasks/blocked docs/tasks/backlog docs/tasks/next docs/tasks/doing)
    fi
    local dir match
    for dir in "${dirs[@]}"; do
        match=$(find "$dir" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
        if [ -n "$match" ]; then
            printf '%s\t%s' "$match" "$dir"
            return 0
        fi
    done
    return 1
}

# Timestamped log path: sprintmd_log_path gate 42-fix-thing.md
sprintmd_log_path() {
    local kind="$1" name="$2"
    printf 'docs/tmp/log-%s-%s-%s.json' "$kind" "${name%.md}" "$(date +%Y%m%d-%H%M%S)"
}

# The task lifecycle folders, in order. One source of truth for every script
# that iterates stages (search, validate, check-alignment, sync, chat-sprint…).
# shellcheck disable=SC2034
SPRINTMD_STAGES=(backlog next doing blocked review "done")

# task_id "12-fix-auth.md" (or a full path) -> "12"
task_id() {
    local b="${1##*/}"
    printf '%s' "${b%%-*}"
}

# task_title FILE -> first "# " heading, without "# " or a "Task N: " prefix.
# Guards grep so a heading-less file yields empty (not a pipefail non-zero
# that would trip set -e in `x=$(task_title f)`).
task_title() {
    { grep -m1 '^# ' "$1" 2>/dev/null || true; } | sed 's/^# *//; s/^Task [0-9]*: *//'
}

# task_feature FILE -> value of the **Feature**: field (empty if absent).
# Same pipefail/set -e guard as task_title.
task_feature() {
    { grep -m1 '\*\*Feature\*\*:' "$1" 2>/dev/null || true; } | sed 's/.*\*\*Feature\*\*: *//'
}

# sprintmd_review_verdict FILE -> READY | BLOCKED | COMPLETE | "" (no verdict).
# Reads only the LAST "## Questions" section and requires the line-anchored
# bold stamp gate's review writes. A loose grep for "Status: BLOCKED"
# anywhere in the file once mis-routed a READY task to blocked/ because its
# body *quoted* the verdict vocabulary — this helper exists so no script
# ever parses the stamp loosely again.
# COMPLETE = work already in the codebase (moves to review/). Not the done/
# lifecycle folder. Legacy **Status: DONE** stamps normalize to COMPLETE.
sprintmd_review_verdict() {
    local v
    v=$(awk '/^## Questions[[:space:]]*$/{s=""; f=1} f{s=s $0 "\n"} END{printf "%s", s}' "$1" 2>/dev/null \
        | { grep -m1 -oE '^\*\*Status: (READY|BLOCKED|COMPLETE|DONE)\*\*' || true; } \
        | sed 's/\*//g; s/Status: //')
    [ "$v" = "DONE" ] && v="COMPLETE"
    printf '%s' "$v"
}

# sprintmd_meta_value FILE FIELD -> value of '**FIELD**:' (empty if absent).
# FIELD is the label without asterisks, e.g. "Depends on" or "Blocks".
# Guards so a missing field never trips set -e under command substitution.
sprintmd_meta_value() {
    local file="$1" field="$2"
    { grep -m1 -iE "^[[:space:]]*\*\*${field}\*\*[[:space:]]*:" "$file" 2>/dev/null || true; } \
        | sed -E 's/^[^:]*:[[:space:]]*//'
}

# sprintmd_iter_id_list VALUE
# Parse a Depends-on / Blocks style value (comma/space list, N-M ranges).
# Emits one line per token:
#   id <N>     — a numeric task ID (ranges expand to one line each)
#   bad <tok>  — a non-numeric token that is not none/n/a/-
# Empty value, missing field, or whole-value 'none' / 'n/a' / '-' emits nothing.
# Shared by sprintmd_unmet_deps (queue gating) and validate-tasks.sh (integrity).
# Cycle detection among Depends-on edges is intentionally out of scope.
sprintmd_iter_id_list() {
    local raw="$1" tok lo hi n
    [ -z "$raw" ] && return 0
    case "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" in
        none*|n/a*|-*|'') return 0 ;;
    esac
    # Word-split is intentional: commas become spaces, then each token is
    # classified. Double commas / stray spaces yield empty tokens that skip.
    # Leading '#' is stripped so both "291" and "#291" (plan/chat prose style)
    # parse as the same task id.
    # shellcheck disable=SC2086
    for tok in $(printf '%s' "$raw" | tr ',' ' '); do
        [ -z "$tok" ] && continue
        tok="${tok#\#}"
        if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
            if [ "$lo" -gt "$hi" ]; then
                printf 'bad %s\n' "$tok"
                continue
            fi
            for ((n=lo; n<=hi; n++)); do
                printf 'id %s\n' "$n"
            done
        elif [[ "$tok" =~ ^[0-9]+$ ]]; then
            printf 'id %s\n' "$tok"
        else
            printf 'bad %s\n' "$tok"
        fi
    done
    return 0
}

# sprintmd_unmet_deps FILE -> prints the space-separated dependency task IDs that
# are NOT yet complete: those still sitting in backlog/, next/, doing/, or
# blocked/. Empty output means every declared dependency is complete (has reached
# review/ or done/) or none were declared — so the task is clear to run.
#
# Reads the '**Depends on**:' metadata field via sprintmd_iter_id_list. 'none',
# an empty value, or a missing field all mean no dependencies. An ID that
# resolves to no task file anywhere is treated as complete (the task finished
# and was archived), so a stale reference can never wedge a queue. Malformed
# tokens are ignored here (queue gating); validate-tasks.sh reports them.
# This is what makes a dependency wait self-clearing: as each dependency lands
# in review/, the dependent task becomes runnable on the next pass with no
# human action.
sprintmd_unmet_deps() {
    local file="$1" raw id unmet=""
    raw=$(sprintmd_meta_value "$file" "Depends on")
    [ -z "$raw" ] && return 0
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        id="$tok"
        if find docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked \
              -maxdepth 1 -name "${id}-*.md" 2>/dev/null | grep -q .; then
            unmet="$unmet $id"
        fi
    done <<EOF
$(sprintmd_iter_id_list "$raw")
EOF
    [ -n "$unmet" ] && printf '%s' "$unmet" | tr ' ' '\n' \
        | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    return 0
}

# ── DOC_STATE (ID allocation) and templates ──────────────────────────

SPRINTMD_DOC_STATE="${SPRINTMD_DOC_STATE:-docs/sprintmd/DOC_STATE.md}"

# alloc_id KEY [STATE] -> prints HIGHEST+1 for "**KEY**: N"; returns 1 if the
# file or a valid current value is missing (caller prints the error).
alloc_id() {
    local key="$1" state="${2:-$SPRINTMD_DOC_STATE}" highest
    [ -f "$state" ] || return 1
    highest=$(grep "^\*\*${key}\*\*:" "$state" | sed 's/.*: *//' | tr -d '[:space:]')
    [[ "$highest" =~ ^[0-9]+$ ]] || return 1
    printf '%s' "$((highest + 1))"
}

# bump_doc_state KEY VALUE [STATE] -> set "**KEY**: VALUE" (append if missing).
bump_doc_state() {
    local key="$1" value="$2" state="${3:-$SPRINTMD_DOC_STATE}"
    if grep -q "^\*\*${key}\*\*:" "$state" 2>/dev/null; then
        sed_inplace "s|^\*\*${key}\*\*:.*|**${key}**: ${value}|" "$state"
    else
        printf '**%s**: %s\n' "$key" "$value" >> "$state"
    fi
}

# copy_template SRC DEST -> validate SRC exists, mkdir DEST's dir, copy.
# Prints a precise error to stderr and returns 1 on any failure, distinguishing
# a missing template from an unwritable destination (read-only tree, permission
# denied) — callers only need `|| exit 1`, no error message of their own.
copy_template() {
    local src="$1" dest="$2"
    if [ ! -f "$src" ]; then
        echo -e "${RED}ERROR: Template file not found: $src${NC}" >&2
        return 1
    fi
    if ! mkdir -p "$(dirname "$dest")" 2>/dev/null; then
        echo -e "${RED}ERROR: Cannot create $(dirname "$dest") — read-only tree or permission denied${NC}" >&2
        return 1
    fi
    if ! cp "$src" "$dest" 2>/dev/null; then
        echo -e "${RED}ERROR: Cannot write $dest — read-only tree or permission denied${NC}" >&2
        return 1
    fi
}

# ── ID-allocation lock ───────────────────────────────────────────────
# Portable advisory mutex via mkdir (an atomic create-or-fail on every POSIX
# filesystem). Serializes the alloc_id → create-file → bump_doc_state sequence
# so two concurrent `newtask`/`newbug` runs never draw the same ID. Best-effort
# by design: a lock we cannot create (read-only tree) or one held too long (a
# crashed run) never hangs the command — we proceed unlocked rather than block
# forever. Auto-released via an EXIT trap. sprintmd_unlock is idempotent.
SPRINTMD_LOCK_DIR=""
sprintmd_lock() {
    local lockdir tries=0 stole=0
    lockdir="$(dirname "$SPRINTMD_DOC_STATE")/.sprint-alloc.lock"
    while ! mkdir "$lockdir" 2>/dev/null; do
        # A failed mkdir means "already held" only if the dir now exists;
        # otherwise the tree is unwritable — give up and proceed unlocked.
        [ -d "$lockdir" ] || return 0
        tries=$((tries + 1))
        if [ "$tries" -ge 50 ]; then           # ~5s held: assume a stale lock
            [ "$stole" = 1 ] && return 0        # already stole once — proceed
            rmdir "$lockdir" 2>/dev/null
            stole=1; tries=0
            continue
        fi
        sleep 0.1
    done
    SPRINTMD_LOCK_DIR="$lockdir"
    trap 'sprintmd_unlock' EXIT
    return 0
}

sprintmd_unlock() {
    [ -n "$SPRINTMD_LOCK_DIR" ] && rmdir "$SPRINTMD_LOCK_DIR" 2>/dev/null
    SPRINTMD_LOCK_DIR=""
}

# ── Provider profile loader ──────────────────────────────────────────
# Sources the provider profile that defines sprintmd_provider_exec().
# Profiles live in docs/sprintmd/cli/<provider>.sh.
sprintmd_load_profile() {
    local cli="${1:-$SPRINTMD_CLI}"
    SPRINTMD_CLI="$cli"

    local cli_dir="${_SPRINTMD_LIB_DIR}/cli"
    local profile="${cli_dir}/${cli}.sh"
    if [ -f "$profile" ]; then
        # shellcheck source=/dev/null
        source "$profile"
    else
        # shellcheck source=/dev/null
        source "${cli_dir}/default.sh"
    fi
}

# ── AI capability tier ───────────────────────────────────────────────
# Prints the provider capability tier this install runs at:
#   claude-code | grok-build | cursor | openai | generic
# Precedence: config/env PROVIDER (written by setup.sh) > inference from
# the CLI binary name. The inference mirrors setup.sh's picker so an install
# that upgrades without re-running the picker still resolves a sane tier.
# Later scripts branch on this: full orchestration (subagents, JSON output)
# on claude-code and grok-build; graceful degradation elsewhere. See the
# capability matrix in docs/sprintmd/ai/provider-capabilities.md.
sprintmd_ai_tier() {
    if [ -n "${SPRINTMD_PROVIDER:-}" ]; then
        printf '%s' "$SPRINTMD_PROVIDER"
        return
    fi
    case "$SPRINTMD_CLI" in
        claude)              printf 'claude-code' ;;
        grok)                printf 'grok-build' ;;
        cursor-agent|cursor) printf 'cursor' ;;
        codex)               printf 'openai' ;;
        *)                   printf 'generic' ;;
    esac
}

# ── Orchestration-capable tiers ──────────────────────────────────────
# True when emit mode can fan out via native subagents (one fresh worker per
# task). Claude Code uses the Task tool; Grok Build uses spawn_subagent.
# Every multi-task emit gate (work, gate, polish, chat chain, plan start,
# next→blocked) should call this instead of hard-coding a single tier name.
sprintmd_orchestration_capable() {
    case "$(sprintmd_ai_tier)" in
        claude-code|grok-build) return 0 ;;
        *) return 1 ;;
    esac
}

# Short name of the subagent mechanism for prompt wording only.
sprintmd_subagent_tool_name() {
    case "$(sprintmd_ai_tier)" in
        grok-build) printf 'spawn_subagent' ;;
        *)          printf 'Task tool' ;;
    esac
}

# "Launch a NEW subagent …" fragment. Optional $1 = purpose phrase
# (e.g. "the blocked dependency", "<next-id>").
sprintmd_subagent_spawn_phrase() {
    local purpose="${1:-}"
    case "$(sprintmd_ai_tier)" in
        grok-build)
            if [ -n "$purpose" ]; then
                printf 'Launch a NEW subagent via spawn_subagent (subagent_type: general-purpose) for %s' "$purpose"
            else
                printf 'Launch a NEW subagent via spawn_subagent (subagent_type: general-purpose)'
            fi
            ;;
        *)
            if [ -n "$purpose" ]; then
                printf 'Launch a NEW subagent (Task tool) for %s' "$purpose"
            else
                printf 'Launch a NEW subagent (Task tool)'
            fi
            ;;
    esac
}

# "its OWN fresh subagent (…)" — used by work / polish multi-task prompts.
sprintmd_subagent_own_fresh() {
    case "$(sprintmd_ai_tier)" in
        grok-build)
            printf 'its OWN fresh subagent (spawn_subagent, subagent_type: general-purpose)'
            ;;
        *)
            printf 'its OWN fresh subagent (Task tool)'
            ;;
    esac
}

# One-line parallel dispatch instruction for gate-lib and similar fan-outs.
sprintmd_subagent_parallel_dispatch() {
    case "$(sprintmd_ai_tier)" in
        grok-build)
            printf 'Dispatch ONE subagent per task file below, ALL IN PARALLEL (issue every spawn_subagent call in a single message; subagent_type: general-purpose).'
            ;;
        *)
            printf 'Dispatch ONE subagent per task file below, ALL IN PARALLEL (issue every Task tool call in a single message).'
            ;;
    esac
}

# ── AI execution mode ────────────────────────────────────────────────
# emit — print the prompt to stdout for the surrounding agent to execute
#        (used when already inside an AI session, or no CLI is installed).
# exec — spawn the configured CLI binary (standalone terminal, loops, CI).
#
# Precedence: SPRINTMD_MODE env > config MODE > auto-detect.
# Auto-detect: a coding-agent session → emit; else exec if the CLI exists,
# otherwise emit as a last resort (better to show the prompt than to fail).
# Resolved once and cached: nothing this depends on (env, config, CLI
# presence) changes within a single invocation, and sprintmd_run calls this on
# every AI request — the uncached path spawns awk+tail (via sprintmd_cfg) each
# time, which is hot in the audit/triage/work loops.
_SPRINTMD_MODE_CACHE=""
sprintmd_ai_mode() {
    [ -n "$_SPRINTMD_MODE_CACHE" ] && { printf '%s' "$_SPRINTMD_MODE_CACHE"; return; }

    local m="${SPRINTMD_MODE:-$(sprintmd_cfg MODE)}"
    if [ -z "$m" ]; then
        # Agent-session env vars: Claude Code, Cursor, Grok Build (GROK_AGENT=1).
        # Only vars confirmed in real sessions — do not invent markers.
        if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] \
           || [ -n "${CURSOR_TRACE_ID:-}" ] || [ -n "${CURSOR_SESSION_ID:-}" ] \
           || [ -n "${GROK_AGENT:-}" ] \
           || [ -n "${AI_AGENT:-}" ] || [ -n "${SPRINTMD_IN_AGENT:-}" ]; then
            m="emit"
        elif command -v "$SPRINTMD_CLI" >/dev/null 2>&1; then
            m="exec"
        else
            m="emit"
        fi
    fi
    _SPRINTMD_MODE_CACHE="$m"
    printf '%s' "$m"
}

SPRINTMD_LAST_MODE=""
sprintmd_emitted() { [ "$SPRINTMD_LAST_MODE" = "emit" ]; }

# Print the prompt (system prompt + user prompt + trailing positionals) for
# the surrounding agent to act on. Provider-only flags are consumed/ignored.
sprintmd_emit_prompt() {
    local prompt="" system_prompt=""
    local -a rest=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -p)                     prompt="$2";        shift 2 ;;
            --append-system-prompt) system_prompt="$2"; shift 2 ;;
            --model|--max-turns|--tools|--permissions|--output-format|--budget|--name)
                                    shift 2 ;;
            --skip-permissions)     shift ;;
            --)                     shift; rest+=("$@"); break ;;
            *)                      rest+=("$1"); shift ;;
        esac
    done

    printf '%s\n' "── sprint.md: run the following in this session ──────────────"
    [ -n "$system_prompt" ] && printf '%s\n\n' "$system_prompt"
    [ -n "$prompt" ] && printf '%s\n' "$prompt"
    [ ${#rest[@]} -gt 0 ] && printf '%s\n' "${rest[*]}"
    printf '%s\n' "─────────────────────────────────────────────────────────────"
}

# sprintmd_announce_provider — one-line banner so a leading -g/-c, env override,
# or config default is obvious before a long silent headless CLI run.
# Prints once per process (multi-task work/polish only announce on the first
# AI call). Always writes stderr; if stderr is not a TTY (common when callers
# do `sprintmd_run … 2>/dev/null | tee log`), also writes /dev/tty so the
# human still sees the line without double-printing on a normal terminal.
sprintmd_announce_provider() {
    [ -n "${_SPRINTMD_PROVIDER_ANNOUNCED:-}" ] && return 0
    _SPRINTMD_PROVIDER_ANNOUNCED=1
    local cli tier mode line
    cli="${SPRINTMD_CLI:-?}"
    tier="$(sprintmd_ai_tier)"
    mode="$(sprintmd_ai_mode)"
    line=$(printf '▸ Provider: %s (%s) · mode: %s' "$cli" "$tier" "$mode")
    printf '%s\n' "$line" >&2
    if [ ! -t 2 ] && { true >/dev/tty; } 2>/dev/null; then
        printf '%s\n' "$line" >/dev/tty 2>/dev/null || true
    fi
}

# sprintmd_run — route an AI request to emit or exec based on the mode.
# Same argument surface as the provider profiles.
sprintmd_run() {
    sprintmd_announce_provider
    SPRINTMD_LAST_MODE="$(sprintmd_ai_mode)"
    if [ "$SPRINTMD_LAST_MODE" = "emit" ]; then
        sprintmd_emit_prompt "$@"
        return 0
    fi
    sprintmd_provider_exec "$@"
}

# sprintmd_interactive_ok — true when a live back-and-forth session is actually
# possible right now. The single source of truth for that decision, consulted
# both by sprintmd_run_interactive (to route the run) and by callers like
# chat.sh (to decide whether to warn about a degraded single pass) — so the
# warning and the behaviour can never drift apart. All three conditions must
# hold:
#   1. exec mode        — in emit mode the surrounding agent is the session.
#   2. provider opt-in  — the loaded profile sets SPRINTMD_PROVIDER_INTERACTIVE=1
#                         and defines sprintmd_provider_interactive (claude does;
#                         others don't, so they degrade to one-shot).
#   3. a real terminal  — both stdin and stdout are TTYs; a REPL on a pipe or in
#                         CI would just block on input that never arrives.
# Adding interactive support to another provider is one line in its profile —
# no edits here or in callers.
sprintmd_interactive_ok() {
    [ "$(sprintmd_ai_mode)" = "exec" ]                        || return 1
    [ "${SPRINTMD_PROVIDER_INTERACTIVE:-0}" = 1 ]             || return 1
    declare -F sprintmd_provider_interactive >/dev/null 2>&1 || return 1
    [ -t 0 ] && [ -t 1 ]
}

# sprintmd_run_interactive — like sprintmd_run, but opens a LIVE conversation the
# user can reply to turn by turn instead of a one-shot run. Routing:
#   emit — identical to sprintmd_run. The surrounding agent already gives the
#          user an interactive session, so we just hand it the prompt to run.
#   exec — when sprintmd_interactive_ok, call sprintmd_provider_interactive, which
#          inherits the terminal (no stdout capture, no -p/JSON) so the CLI
#          stays in its REPL. Otherwise degrade to the one-shot exec path.
# Used by chat.sh — the one command that is a dialogue rather than a job.
sprintmd_run_interactive() {
    sprintmd_announce_provider
    SPRINTMD_LAST_MODE="$(sprintmd_ai_mode)"
    if [ "$SPRINTMD_LAST_MODE" = "emit" ]; then
        sprintmd_emit_prompt "$@"
        return 0
    fi
    if sprintmd_interactive_ok; then
        sprintmd_provider_interactive "$@"
    else
        sprintmd_provider_exec "$@"
    fi
}

# ── Audit helpers ────────────────────────────────────────────────────
# Shared by polish.sh code-audit and deep-judge modes. Extracted so a fix
# to the manifest priority chain or the summary parser lands in both.

# sprintmd_change_manifest TASK_FILE [EXPLICIT_FILE…]
# Build the change manifest an audit runs against. Priority:
#   AUDIT_MANIFEST env > explicit file list > task ## Completed > git diff.
# Pass TASK_FILE ("" if none) as the first arg and any explicit files after
# it; callers must keep the bash-3.2 empty-array guard when forwarding an
# array (sprintmd_change_manifest "$TASK_FILE" ${FILES[@]+"${FILES[@]}"}).
# Sets two output variables rather than printing (the result is multi-line
# and $(...) runs in a subshell):
#   SPRINTMD_CHANGED_FILES  — newline-separated changed-file list (may be empty)
#   SPRINTMD_CONTEXT_SOURCE — human label of where the list came from
# shellcheck disable=SC2034  # output vars, read by callers
sprintmd_change_manifest() {
    local task_file="$1"; shift
    local -a explicit=("$@")
    SPRINTMD_CHANGED_FILES=""
    SPRINTMD_CONTEXT_SOURCE=""

    # 1. Manifest file from work.sh (most reliable — exact before/after snapshot)
    if [ -n "${AUDIT_MANIFEST:-}" ] && [ -f "${AUDIT_MANIFEST}" ]; then
        SPRINTMD_CHANGED_FILES=$(grep -v '^$' "$AUDIT_MANIFEST" || true)
        SPRINTMD_CONTEXT_SOURCE="manifest from work.sh"

    # 2. Explicit file list from CLI args
    elif [ ${#explicit[@]} -gt 0 ]; then
        SPRINTMD_CHANGED_FILES=$(printf '%s\n' "${explicit[@]}")
        SPRINTMD_CONTEXT_SOURCE="explicit file list"

    # 3. Task file's ## Completed section
    elif [ -n "$task_file" ] && grep -q '^## Completed' "$task_file"; then
        local completed files_sub
        completed=$(sed -n '/^## Completed/,/^## /{ /^## /d; p; }' "$task_file")
        # Prefer the author's own "### Files changed" list — the positively
        # scoped answer to "what did this task touch." Scanning the whole
        # Completed prose misreads a path merely MENTIONED in passing (e.g. a
        # script named as out-of-scope) as a change; the explicit list can't.
        # Fall back to the full prose only when the subsection is absent
        # (older tasks that predate the convention).
        files_sub=$(printf '%s\n' "$completed" \
            | sed -n '/^### Files changed/,/^#/{ /^#/d; p; }')
        [ -n "$(printf '%s' "$files_sub" | tr -d '[:space:]')" ] && completed="$files_sub"
        SPRINTMD_CHANGED_FILES=$(printf '%s\n' "$completed" \
            | grep -oE '[a-zA-Z0-9_/./-]+\.[a-zA-Z]{1,5}' \
            | sort -u \
            | while read -r f; do [ -f "$f" ] && echo "$f"; done || true)
        SPRINTMD_CONTEXT_SOURCE="task ## Completed section"

    # 4. Fallback: git working tree diff
    else
        local staged
        SPRINTMD_CHANGED_FILES=$(git diff --name-only 2>/dev/null || true)
        staged=$(git diff --cached --name-only 2>/dev/null || true)
        SPRINTMD_CHANGED_FILES=$(printf '%s\n%s' "$SPRINTMD_CHANGED_FILES" "$staged" | sort -u | grep -v '^$' || true)
        SPRINTMD_CONTEXT_SOURCE="git working tree diff"
    fi
}

# sprintmd_parse_verdict TOKENS  (reads stdin) -> print the last verdict token.
# TOKENS is a |-separated list of accepted UPPERCASE tokens, e.g.
#   printf '%s' "$OUTPUT" | sprintmd_parse_verdict 'PASS|FIXED|FAIL|BLOCKED'
# The audit scripts pin the verdict to a "VERDICT: <TOKEN>" last line, but a
# model that writes "Verdict — pass" or "**VERDICT: PASS**" would silently
# degrade to UNCLEAR under an exact-uppercase grep. This tolerates case, any
# run of whitespace/punctuation between VERDICT and the token (colon, em/en
# dash, hyphen), and surrounding markdown emphasis. Returns the matched token
# uppercased, or nothing (caller maps empty -> UNCLEAR). Always exits 0 so it
# is safe under set -e in a command substitution.
sprintmd_parse_verdict() {
    local tokens="$1"
    grep -oiE "VERDICT[[:space:][:punct:]]*($tokens)" \
        | tail -1 \
        | grep -oiE "($tokens)" \
        | tr '[:lower:]' '[:upper:]' \
        || true
}

# sprintmd_extract_summary JSON_LOG_FILE -> print the audit summary text.
# Prefers a "## Summary" section; else the 30 lines before a VERDICT: line
# (a strict superset that only fires when ## Summary is absent — the normal
# path is byte-identical for both audits); else the tail of the result.
# Always prints something so callers under set -e never trip.
sprintmd_extract_summary() {
    local json_file="$1"
    python3 -c "
import json, sys, re
try:
    data = json.load(open(sys.argv[1]))
    text = data.get('result', '')
    # Try ## Summary section first
    m = re.search(r'## Summary\n(.*?)(?=\nVERDICT:|\Z)', text, re.DOTALL)
    if m:
        print(m.group(1).strip())
    else:
        lines = text.strip().split('\n')
        verdict_idx = None
        for i, l in enumerate(lines):
            if 'VERDICT:' in l:
                verdict_idx = i
        if verdict_idx is not None and verdict_idx > 0:
            start = max(0, verdict_idx - 30)
            print('\n'.join(lines[start:verdict_idx]).strip())
        elif text:
            print(text[-2000:] if len(text) > 2000 else text)
        else:
            print('(no output captured)')
except Exception as e:
    print(f'(Could not extract summary: {e})')
" "$json_file" 2>/dev/null || echo "(Could not extract summary)"
}

# ── Auto-load on source ─────────────────────────────────────────────
# Populate shell variables from config, with env overrides and defaults.
SPRINTMD_CLI="${SPRINTMD_CLI:-$(sprintmd_cfg CLI)}"
: "${SPRINTMD_CLI:=claude}"

# Capability tier. Empty is fine — sprintmd_ai_tier infers it from the CLI.
SPRINTMD_PROVIDER="${SPRINTMD_PROVIDER:-$(sprintmd_cfg PROVIDER)}"

SPRINTMD_BUDGET_WORK="${SPRINTMD_BUDGET_WORK:-$(sprintmd_cfg BUDGET_WORK)}"
: "${SPRINTMD_BUDGET_WORK:=5.00}"

SPRINTMD_BUDGET_AUDIT="${SPRINTMD_BUDGET_AUDIT:-$(sprintmd_cfg BUDGET_AUDIT)}"
: "${SPRINTMD_BUDGET_AUDIT:=3.00}"

SPRINTMD_AUDIT_MAX_PASSES="${SPRINTMD_AUDIT_MAX_PASSES:-$(sprintmd_cfg AUDIT_MAX_PASSES)}"
: "${SPRINTMD_AUDIT_MAX_PASSES:=2}"

# Load provider profile (defines sprintmd_provider_exec)
sprintmd_load_profile "$SPRINTMD_CLI"
