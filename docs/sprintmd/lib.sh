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
#   move_file SRC DEST         — git mv with plain mv fallback
#   run_with_timeout SECS CMD… — portable timeout (coreutils, gtimeout, or shell)
#   kebab_case STRING          — lowercase, hyphenated slug
#   fiveday_slug NAME [MAX]    — kebab_case + length cap + empty guard (returns 1)
#   fiveday_cfg KEY            — read a value from docs/sprintmd/config
#   fiveday_cfg_set KEY VALUE  — update or append a value in config
#   fiveday_resolve_model SFX  — model resolution: env > config > default
#   fiveday_tier_model SFX     — fiveday_resolve_model, strongest model on claude-code
#   fiveday_profile_line       — one-line pointer to project.md (empty if absent)
#   fiveday_next_blocked_resolution — prompt block: walk one next→blocked BLOCKER
#       (two-path choice, demote inline for B, hand off to define for A). Shared
#       by talk-sprint.sh and the talk-next folder walk so the logic is written once.
#   fiveday_find_task ID [dirs…] — resolve a task file by numeric ID
#   fiveday_review_verdict FILE — READY/BLOCKED/DONE stamp from a define review
#   fiveday_log_path KIND NAME — timestamped log path under docs/tmp
#   fiveday_load_profile [cli] — source the provider profile (fiveday_provider_exec)
#   fiveday_ai_tier            — capability tier: claude-code|cursor|openai|generic
#   fiveday_ai_mode            — "emit" or "exec" for the current environment
#   fiveday_emitted            — true if the last fiveday_run only emitted a prompt
#   fiveday_run ARGS…          — run AI: emit prompt to stdout, or exec the CLI
#   fiveday_interactive_ok     — true if a live session is possible (exec mode,
#       interactive-capable provider, real TTY) — one source of truth
#   fiveday_run_interactive A… — like fiveday_run, but the exec path is a live
#       back-and-forth session (inherits the terminal) instead of one-shot
#   fiveday_change_manifest TASK_FILE [FILE…] — build audit change manifest;
#       sets FIVEDAY_CHANGED_FILES and FIVEDAY_CONTEXT_SOURCE
#   fiveday_parse_verdict TOKENS — (stdin) last VERDICT token, case/format tolerant
#   fiveday_extract_summary JSON — print the summary text from a CLI JSON log

_FIVEDAY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
_FIVEDAY_SED_GNU=""
sed_inplace() {
    if [ -z "$_FIVEDAY_SED_GNU" ]; then
        if sed --version 2>/dev/null | grep -q GNU; then
            _FIVEDAY_SED_GNU=1
        else
            _FIVEDAY_SED_GNU=0
        fi
    fi
    if [ "$_FIVEDAY_SED_GNU" = 1 ]; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

move_file() {
    git mv "$1" "$2" 2>/dev/null || mv "$1" "$2"
}

# Portable timeout: run_with_timeout SECONDS CMD [ARGS…]
# For external programs, prefer GNU coreutils `timeout` (or `gtimeout` on
# macOS). Neither can exec a *shell function* — they only run programs on
# PATH — so when the target is a function (e.g. fiveday_run) we always take
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

# kebab_case "Some Title!" -> "some-title"
kebab_case() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-zA-Z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# fiveday_slug NAME [MAXLEN] -> a filename-safe slug for NAME.
# kebab-cases NAME, caps it to MAXLEN chars (default 50) and trims any trailing
# hyphen the cut leaves behind. Prints the slug on stdout; a truncation note
# goes to stderr so it never pollutes command-substitution capture. Returns 1
# with empty output when NAME has no slug-able characters (all symbols/unicode)
# so callers reject it instead of writing "NNN-.md" or a hidden ".md".
fiveday_slug() {
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

FIVEDAY_CONFIG_FILE="${FIVEDAY_CONFIG_FILE:-${_FIVEDAY_LIB_DIR}/config}"

# ── Config reader ────────────────────────────────────────────────────
# Reads KEY from the flat config file. Returns empty string if the key
# is absent or the file doesn't exist.
fiveday_cfg() {
    local key="$1"
    [ -f "$FIVEDAY_CONFIG_FILE" ] || return 0
    awk -F= -v k="$key" '!/^[[:space:]]*#/ && $1 == k { print substr($0, length(k)+2) }' "$FIVEDAY_CONFIG_FILE" | tail -1
}

# ── Config writer ────────────────────────────────────────────────────
# Updates a key in-place, or appends it if not present.
fiveday_cfg_set() {
    local key="$1" value="$2"
    if [ ! -f "$FIVEDAY_CONFIG_FILE" ]; then
        echo "${key}=${value}" > "$FIVEDAY_CONFIG_FILE"
        return
    fi
    if grep -q "^${key}=" "$FIVEDAY_CONFIG_FILE"; then
        # Escape the replacement for a |-delimited sed s-command: a literal
        # |, &, or \ in the value would otherwise corrupt the substitution.
        local esc_value
        esc_value=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
        sed_inplace "s|^${key}=.*|${key}=${esc_value}|" "$FIVEDAY_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$FIVEDAY_CONFIG_FILE"
    fi
}

# ── Model resolver ───────────────────────────────────────────────────
# Usage: model=$(fiveday_resolve_model TASKS)
#
# Precedence: env FIVEDAY_MODEL_<SUFFIX> > config MODEL_<SUFFIX>
#             > config MODEL_DEFAULT > empty (CLI picks its own)
fiveday_resolve_model() {
    local suffix="$1"
    local env_var="FIVEDAY_MODEL_${suffix}"

    # Environment variable wins
    if [ "${!env_var+set}" = "set" ]; then
        printf '%s' "${!env_var}"
        return
    fi

    # Config per-script model
    local val
    val=$(fiveday_cfg "MODEL_${suffix}")
    if [ -n "$val" ]; then
        printf '%s' "$val"
        return
    fi

    # Config global default
    val=$(fiveday_cfg "MODEL_DEFAULT")
    printf '%s' "$val"
}

# ── Tier-aware model resolver ────────────────────────────────────────
# Usage: model=$(fiveday_tier_model FEATURE)
#
# Like fiveday_resolve_model, but when nothing is configured (env/config both
# empty) and the provider tier supports model selection (claude-code), fall
# back to the strongest appropriate alias instead of letting the CLI pick its
# cheaper default. For interactive, reasoning-heavy flows — the feature Q&A
# and the idea Feynman protocol — the best model is worth it unless the user
# has pinned one. Other tiers can't select a model, so this returns empty
# (their default.sh passthrough would only warn about a dropped flag).
fiveday_tier_model() {
    local suffix="$1" model
    model="$(fiveday_resolve_model "$suffix")"
    if [ -z "$model" ] && [ "$(fiveday_ai_tier)" = "claude-code" ]; then
        model="opus"
    fi
    printf '%s' "$model"
}

# ── Task helpers ─────────────────────────────────────────────────────

# Emit a "read project.md" line if a profile exists (else nothing).
# Always returns 0 so it is safe in `var=$(fiveday_profile_line)` under set -e.
fiveday_profile_line() {
    [ -f "docs/sprintmd/project.md" ] || return 0
    printf '%s' "
Also read docs/sprintmd/project.md for project-specific stack and conventions."
}

# ── Shared walkthrough instruction: resolving a next→blocked BLOCKER ──
# A next/ task that depends on a task still parked in blocked/ can never run —
# the executor silently HOLDS it until the dependency leaves blocked/. Both the
# no-id sprint walk (talk-sprint.sh) and the folder walk (talk next) surface this
# edge, and BOTH must resolve it the same way. Written once here so neither
# reimplements — and drifts from — the other.
#
# Emits the prompt block that tells the conversational layer how to walk ONE such
# edge: present the two real paths as a choice, action Path B (demote) inline,
# hand Path A (define the dependency) off to talk's fresh-context chain, and gate
# the drop path behind an on-the-spot edge audit. Path A's hand-off mirrors
# talk.sh's own emit-vs-exec split: an emit-mode claude-code session can spawn a
# fresh subagent; every other environment prints the command to run in a fresh
# window. Always returns 0 so it is safe in `x=$(fiveday_next_blocked_resolution)`.
fiveday_next_blocked_resolution() {
    local path_a
    if [ "$(fiveday_ai_mode)" = "emit" ] && [ "$(fiveday_ai_tier)" = "claude-code" ]; then
        path_a="Hand this off to a FRESH context — do NOT redefine the dependency inline here. Launch a NEW subagent (Task tool) for the blocked dependency, aimed at the MOST-UPSTREAM undefined one first (the dependency whose own '**Depends on**' has no undefined deps left; break ties by lowest id). Its entire instruction: 'Run ./sprint.sh talk <dep-id> and carry that task as far toward READY as you can on your own — read any *Context from talk* note in its file, refine it, and if a question genuinely needs the human, leave it in the file's ## Questions section and report it back.' Tell the user you spun up a fresh agent for <dep-id> and say in one line what it is picking up."
    else
        path_a="Hand this off — do NOT redefine the dependency inline here. Tell the user the exact command to run in a FRESH window:  ./sprint.sh talk <dep-id>  (for the most-upstream undefined dependency). Keeping each session's context small is the point of chaining out."
    fi
    printf '%s' "─── RESOLVING A next→blocked BLOCKER (dependent task <D> in next/ depends on task <B> in blocked/) ───
A next/ task that depends on a task still sitting in blocked/ can NEVER run: the executor ('tasks') silently HOLDS it until the dependency leaves blocked/. Do not merely report this — close the loop. Present the TWO REAL paths as an explicit choice and act on the one the user picks. Do NOT frame 'drop the Depends on line' as a way out of a genuine block — that only makes <D> LOOK runnable while the work it needs is still undone (the folder-satisfaction trap).

PATH A — DEFINE THE BLOCKED DEPENDENCY <B> (choose when the dependency is real and still needed):
${path_a}
Either way, talk's own close-the-loop branch stamps <B> '**Status: READY**' and git mv's it back into next/, which makes <D> runnable — you do not rebuild that machinery here, you point at it.

PATH B — DEMOTE THE DEPENDENT TASK <D> BACK TO backlog/ (choose to pull it out of the sprint):
On the user's OK, action this INLINE: move <D> out of the sprint so next/ holds no work blocked on an undefined task —  git mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file>  (fall back to plain 'mv' if git mv fails because the file is uncommitted). THEN RE-SCAN next/ for any OTHER task that also depends on <B>: the preflight already emitted a SEPARATE BLOCKER finding for each (next task, blocked dep) pair, so <B>'s other dependents are already in the findings list — recognize them by the same blocked id <B>, do not run a fresh board scan. Only when NONE remain may you say 'the sprint no longer contains work blocked on <B>.' If siblings remain, name them and offer to resolve each in turn (A or B).

THE DROP PATH — a metadata correction for a STALE or SPURIOUS edge ONLY, and only after an on-the-spot audit:
Dropping the '**Depends on**:' line is NOT one of the two resolution paths above. It is reserved for an edge that is not a genuine dependency. Before you may even offer it, AUDIT THE EDGE on the spot — a bounded, READ-ONLY reasoning step, NOT a define pass: read WHY <D> needed <B> (what <D>'s Problem/Success actually required from <B>) and check whether that need is already satisfied elsewhere or has become obsolete. ONLY an edge that FAILS this audit (need already met / no longer needed) may be dropped from <D>'s Depends on line. An edge whose need still stands IS a real dependency: route to A or B, never drop. No audit, no drop."
}

# Resolve a task file by numeric ID. Prints "path<TAB>stage-dir" on success.
# Default search order matches the task lifecycle.
fiveday_find_task() {
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

# Timestamped log path: fiveday_log_path define 42-fix-thing.md
fiveday_log_path() {
    local kind="$1" name="$2"
    printf 'docs/tmp/log-%s-%s-%s.json' "$kind" "${name%.md}" "$(date +%Y%m%d-%H%M%S)"
}

# The task lifecycle folders, in order. One source of truth for every script
# that iterates stages (search, validate, check-alignment, sync, talk-sprint…).
# shellcheck disable=SC2034
FIVEDAY_STAGES=(backlog next doing blocked review "done")

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

# fiveday_review_verdict FILE -> READY | BLOCKED | DONE | "" (no verdict).
# Reads only the LAST "## Questions" section and requires the line-anchored
# bold stamp define.sh's review writes. A loose grep for "Status: BLOCKED"
# anywhere in the file once mis-routed a READY task to blocked/ because its
# body *quoted* the verdict vocabulary — this helper exists so no script
# ever parses the stamp loosely again.
fiveday_review_verdict() {
    awk '/^## Questions[[:space:]]*$/{s=""; f=1} f{s=s $0 "\n"} END{printf "%s", s}' "$1" 2>/dev/null \
        | { grep -m1 -oE '^\*\*Status: (READY|BLOCKED|DONE)\*\*' || true; } \
        | sed 's/\*//g; s/Status: //'
}

# fiveday_unmet_deps FILE -> prints the space-separated dependency task IDs that
# are NOT yet complete: those still sitting in backlog/, next/, doing/, or
# blocked/. Empty output means every declared dependency is complete (has reached
# review/ or done/) or none were declared — so the task is clear to run.
#
# Reads the '**Depends on**:' metadata field — a comma/space list of task numbers
# with 'N-M' ranges expanded. 'none', an empty value, or a missing field all mean
# no dependencies. An ID that resolves to no task file anywhere is treated as
# complete (the task finished and was archived), so a stale reference can never
# wedge a queue. This is what makes a dependency wait self-clearing: as each
# dependency lands in review/, the dependent task becomes runnable on the next
# pass with no human action.
fiveday_unmet_deps() {
    local file="$1" raw tok lo hi n id ids="" unmet=""
    raw=$(grep -m1 -iE '^[[:space:]]*\*\*Depends on\*\*[[:space:]]*:' "$file" 2>/dev/null \
            | sed -E 's/^[^:]*:[[:space:]]*//') || true
    [ -z "$raw" ] && return 0
    case "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" in
        none*|n/a*|-*|'') return 0 ;;
    esac
    for tok in $(printf '%s' "$raw" | tr ',' ' '); do
        if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
            [ "$lo" -le "$hi" ] || continue
            for ((n=lo; n<=hi; n++)); do ids="$ids $n"; done
        elif [[ "$tok" =~ ^[0-9]+$ ]]; then
            ids="$ids $tok"
        fi
    done
    for id in $ids; do
        if find docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked \
              -maxdepth 1 -name "${id}-*.md" 2>/dev/null | grep -q .; then
            unmet="$unmet $id"
        fi
    done
    [ -n "$unmet" ] && printf '%s' "$unmet" | tr ' ' '\n' \
        | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    return 0
}

# ── DOC_STATE (ID allocation) and templates ──────────────────────────

FIVEDAY_DOC_STATE="${FIVEDAY_DOC_STATE:-docs/sprintmd/DOC_STATE.md}"

# alloc_id KEY [STATE] -> prints HIGHEST+1 for "**KEY**: N"; returns 1 if the
# file or a valid current value is missing (caller prints the error).
alloc_id() {
    local key="$1" state="${2:-$FIVEDAY_DOC_STATE}" highest
    [ -f "$state" ] || return 1
    highest=$(grep "^\*\*${key}\*\*:" "$state" | sed 's/.*: *//' | tr -d '[:space:]')
    [[ "$highest" =~ ^[0-9]+$ ]] || return 1
    printf '%s' "$((highest + 1))"
}

# bump_doc_state KEY VALUE [STATE] -> set "**KEY**: VALUE" (append if missing).
bump_doc_state() {
    local key="$1" value="$2" state="${3:-$FIVEDAY_DOC_STATE}"
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
# forever. Auto-released via an EXIT trap. fiveday_unlock is idempotent.
FIVEDAY_LOCK_DIR=""
fiveday_lock() {
    local lockdir tries=0 stole=0
    lockdir="$(dirname "$FIVEDAY_DOC_STATE")/.sprint-alloc.lock"
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
    FIVEDAY_LOCK_DIR="$lockdir"
    trap 'fiveday_unlock' EXIT
    return 0
}

fiveday_unlock() {
    [ -n "$FIVEDAY_LOCK_DIR" ] && rmdir "$FIVEDAY_LOCK_DIR" 2>/dev/null
    FIVEDAY_LOCK_DIR=""
}

# ── Provider profile loader ──────────────────────────────────────────
# Sources the provider profile that defines fiveday_provider_exec().
# Profiles live in docs/sprintmd/cli/<provider>.sh.
fiveday_load_profile() {
    local cli="${1:-$FIVEDAY_CLI}"
    FIVEDAY_CLI="$cli"

    local cli_dir="${_FIVEDAY_LIB_DIR}/cli"
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
#   claude-code | cursor | openai | generic
# Precedence: config/env PROVIDER (written by setup.sh) > inference from
# the CLI binary name. The inference mirrors setup.sh's picker so an install
# that upgrades without re-running the picker still resolves a sane tier.
# Later scripts branch on this: full orchestration (subagents, JSON output,
# budget caps) on claude-code; graceful degradation elsewhere. See the
# capability matrix in docs/sprintmd/ai/provider-capabilities.md.
fiveday_ai_tier() {
    if [ -n "${FIVEDAY_PROVIDER:-}" ]; then
        printf '%s' "$FIVEDAY_PROVIDER"
        return
    fi
    case "$FIVEDAY_CLI" in
        claude)              printf 'claude-code' ;;
        cursor-agent|cursor) printf 'cursor' ;;
        codex)               printf 'openai' ;;
        *)                   printf 'generic' ;;
    esac
}

# ── AI execution mode ────────────────────────────────────────────────
# emit — print the prompt to stdout for the surrounding agent to execute
#        (used when already inside an AI session, or no CLI is installed).
# exec — spawn the configured CLI binary (standalone terminal, loops, CI).
#
# Precedence: FIVEDAY_MODE env > config MODE > auto-detect.
# Auto-detect: a coding-agent session → emit; else exec if the CLI exists,
# otherwise emit as a last resort (better to show the prompt than to fail).
# Resolved once and cached: nothing this depends on (env, config, CLI
# presence) changes within a single invocation, and fiveday_run calls this on
# every AI request — the uncached path spawns awk+tail (via fiveday_cfg) each
# time, which is hot in the audit/triage/tasks loops.
_FIVEDAY_MODE_CACHE=""
fiveday_ai_mode() {
    [ -n "$_FIVEDAY_MODE_CACHE" ] && { printf '%s' "$_FIVEDAY_MODE_CACHE"; return; }

    local m="${FIVEDAY_MODE:-$(fiveday_cfg MODE)}"
    if [ -z "$m" ]; then
        if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] \
           || [ -n "${CURSOR_TRACE_ID:-}" ] || [ -n "${CURSOR_SESSION_ID:-}" ] \
           || [ -n "${AI_AGENT:-}" ] || [ -n "${FIVEDAY_IN_AGENT:-}" ]; then
            m="emit"
        elif command -v "$FIVEDAY_CLI" >/dev/null 2>&1; then
            m="exec"
        else
            m="emit"
        fi
    fi
    _FIVEDAY_MODE_CACHE="$m"
    printf '%s' "$m"
}

FIVEDAY_LAST_MODE=""
fiveday_emitted() { [ "$FIVEDAY_LAST_MODE" = "emit" ]; }

# Print the prompt (system prompt + user prompt + trailing positionals) for
# the surrounding agent to act on. Provider-only flags are consumed/ignored.
fiveday_emit_prompt() {
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

# fiveday_run — route an AI request to emit or exec based on the mode.
# Same argument surface as the provider profiles.
fiveday_run() {
    FIVEDAY_LAST_MODE="$(fiveday_ai_mode)"
    if [ "$FIVEDAY_LAST_MODE" = "emit" ]; then
        fiveday_emit_prompt "$@"
        return 0
    fi
    fiveday_provider_exec "$@"
}

# fiveday_interactive_ok — true when a live back-and-forth session is actually
# possible right now. The single source of truth for that decision, consulted
# both by fiveday_run_interactive (to route the run) and by callers like
# talk.sh (to decide whether to warn about a degraded single pass) — so the
# warning and the behaviour can never drift apart. All three conditions must
# hold:
#   1. exec mode        — in emit mode the surrounding agent is the session.
#   2. provider opt-in  — the loaded profile sets FIVEDAY_PROVIDER_INTERACTIVE=1
#                         and defines fiveday_provider_interactive (claude does;
#                         others don't, so they degrade to one-shot).
#   3. a real terminal  — both stdin and stdout are TTYs; a REPL on a pipe or in
#                         CI would just block on input that never arrives.
# Adding interactive support to another provider is one line in its profile —
# no edits here or in callers.
fiveday_interactive_ok() {
    [ "$(fiveday_ai_mode)" = "exec" ]                        || return 1
    [ "${FIVEDAY_PROVIDER_INTERACTIVE:-0}" = 1 ]             || return 1
    declare -F fiveday_provider_interactive >/dev/null 2>&1 || return 1
    [ -t 0 ] && [ -t 1 ]
}

# fiveday_run_interactive — like fiveday_run, but opens a LIVE conversation the
# user can reply to turn by turn instead of a one-shot run. Routing:
#   emit — identical to fiveday_run. The surrounding agent already gives the
#          user an interactive session, so we just hand it the prompt to run.
#   exec — when fiveday_interactive_ok, call fiveday_provider_interactive, which
#          inherits the terminal (no stdout capture, no -p/JSON) so the CLI
#          stays in its REPL. Otherwise degrade to the one-shot exec path.
# Used by talk.sh — the one command that is a dialogue rather than a job.
fiveday_run_interactive() {
    FIVEDAY_LAST_MODE="$(fiveday_ai_mode)"
    if [ "$FIVEDAY_LAST_MODE" = "emit" ]; then
        fiveday_emit_prompt "$@"
        return 0
    fi
    if fiveday_interactive_ok; then
        fiveday_provider_interactive "$@"
    else
        fiveday_provider_exec "$@"
    fi
}

# ── Audit helpers ────────────────────────────────────────────────────
# Shared by the audit-code and audit-excellence scripts. Extracted so a fix
# to the manifest priority chain or the summary parser lands in both.

# fiveday_change_manifest TASK_FILE [EXPLICIT_FILE…]
# Build the change manifest an audit runs against. Priority:
#   AUDIT_MANIFEST env > explicit file list > task ## Completed > git diff.
# Pass TASK_FILE ("" if none) as the first arg and any explicit files after
# it; callers must keep the bash-3.2 empty-array guard when forwarding an
# array (fiveday_change_manifest "$TASK_FILE" ${FILES[@]+"${FILES[@]}"}).
# Sets two output variables rather than printing (the result is multi-line
# and $(...) runs in a subshell):
#   FIVEDAY_CHANGED_FILES  — newline-separated changed-file list (may be empty)
#   FIVEDAY_CONTEXT_SOURCE — human label of where the list came from
# shellcheck disable=SC2034  # output vars, read by callers
fiveday_change_manifest() {
    local task_file="$1"; shift
    local -a explicit=("$@")
    FIVEDAY_CHANGED_FILES=""
    FIVEDAY_CONTEXT_SOURCE=""

    # 1. Manifest file from tasks.sh (most reliable — exact before/after snapshot)
    if [ -n "${AUDIT_MANIFEST:-}" ] && [ -f "${AUDIT_MANIFEST}" ]; then
        FIVEDAY_CHANGED_FILES=$(grep -v '^$' "$AUDIT_MANIFEST" || true)
        FIVEDAY_CONTEXT_SOURCE="manifest from tasks.sh"

    # 2. Explicit file list from CLI args
    elif [ ${#explicit[@]} -gt 0 ]; then
        FIVEDAY_CHANGED_FILES=$(printf '%s\n' "${explicit[@]}")
        FIVEDAY_CONTEXT_SOURCE="explicit file list"

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
        FIVEDAY_CHANGED_FILES=$(printf '%s\n' "$completed" \
            | grep -oE '[a-zA-Z0-9_/./-]+\.[a-zA-Z]{1,5}' \
            | sort -u \
            | while read -r f; do [ -f "$f" ] && echo "$f"; done || true)
        FIVEDAY_CONTEXT_SOURCE="task ## Completed section"

    # 4. Fallback: git working tree diff
    else
        local staged
        FIVEDAY_CHANGED_FILES=$(git diff --name-only 2>/dev/null || true)
        staged=$(git diff --cached --name-only 2>/dev/null || true)
        FIVEDAY_CHANGED_FILES=$(printf '%s\n%s' "$FIVEDAY_CHANGED_FILES" "$staged" | sort -u | grep -v '^$' || true)
        FIVEDAY_CONTEXT_SOURCE="git working tree diff"
    fi
}

# fiveday_parse_verdict TOKENS  (reads stdin) -> print the last verdict token.
# TOKENS is a |-separated list of accepted UPPERCASE tokens, e.g.
#   printf '%s' "$OUTPUT" | fiveday_parse_verdict 'PASS|FIXED|FAIL|BLOCKED'
# The audit scripts pin the verdict to a "VERDICT: <TOKEN>" last line, but a
# model that writes "Verdict — pass" or "**VERDICT: PASS**" would silently
# degrade to UNCLEAR under an exact-uppercase grep. This tolerates case, any
# run of whitespace/punctuation between VERDICT and the token (colon, em/en
# dash, hyphen), and surrounding markdown emphasis. Returns the matched token
# uppercased, or nothing (caller maps empty -> UNCLEAR). Always exits 0 so it
# is safe under set -e in a command substitution.
fiveday_parse_verdict() {
    local tokens="$1"
    grep -oiE "VERDICT[[:space:][:punct:]]*($tokens)" \
        | tail -1 \
        | grep -oiE "($tokens)" \
        | tr '[:lower:]' '[:upper:]' \
        || true
}

# fiveday_extract_summary JSON_LOG_FILE -> print the audit summary text.
# Prefers a "## Summary" section; else the 30 lines before a VERDICT: line
# (a strict superset that only fires when ## Summary is absent — the normal
# path is byte-identical for both audits); else the tail of the result.
# Always prints something so callers under set -e never trip.
fiveday_extract_summary() {
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
FIVEDAY_CLI="${FIVEDAY_CLI:-$(fiveday_cfg CLI)}"
: "${FIVEDAY_CLI:=claude}"

# Capability tier. Empty is fine — fiveday_ai_tier infers it from the CLI.
FIVEDAY_PROVIDER="${FIVEDAY_PROVIDER:-$(fiveday_cfg PROVIDER)}"

FIVEDAY_BUDGET_TASKS="${FIVEDAY_BUDGET_TASKS:-$(fiveday_cfg BUDGET_TASKS)}"
: "${FIVEDAY_BUDGET_TASKS:=5.00}"

FIVEDAY_BUDGET_AUDIT="${FIVEDAY_BUDGET_AUDIT:-$(fiveday_cfg BUDGET_AUDIT)}"
: "${FIVEDAY_BUDGET_AUDIT:=3.00}"

FIVEDAY_AUDIT_MAX_PASSES="${FIVEDAY_AUDIT_MAX_PASSES:-$(fiveday_cfg AUDIT_MAX_PASSES)}"
: "${FIVEDAY_AUDIT_MAX_PASSES:=2}"

# Load provider profile (defines fiveday_provider_exec)
fiveday_load_profile "$FIVEDAY_CLI"
