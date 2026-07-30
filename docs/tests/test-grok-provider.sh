#!/usr/bin/env bash
# Test: Grok Build first-class provider (plan 5 / tasks 251–256)
#
# Covers tier inference, emit detection (GROK_AGENT), profile load, model
# default, orchestration helpers, and tool-mapping fail-open behavior.
# Does not launch a live Grok TUI or call the network.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTMD="$ROOT/docs/sprintmd"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    printf '    expected: %q\n' "$expected"
    printf '    actual:   %q\n' "$actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_true() {
  local desc="$1"; shift
  if "$@"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected success)"
    FAIL=$((FAIL + 1))
  fi
}

assert_false() {
  local desc="$1"; shift
  if "$@"; then
    echo "  FAIL: $desc (expected failure)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected to contain '$needle')"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-grok-provider.sh ==="

# Isolate config so this repo's live CLI/PROVIDER don't leak into tests.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/docs/sprintmd/cli" "$TMPDIR/docs/sprintmd/ai" "$TMPDIR/docs/tmp"
cp "$SPRINTMD/lib.sh" "$TMPDIR/docs/sprintmd/lib.sh"
cp "$SPRINTMD/cli/"*.sh "$TMPDIR/docs/sprintmd/cli/"
# Minimal config: empty MODE, no PROVIDER (force inference from CLI).
cat > "$TMPDIR/docs/sprintmd/config" << 'EOF'
CLI=grok
PROVIDER=
MODE=
MODEL_DEFAULT=
MODEL_CHAT=
EOF

cd "$TMPDIR"
# Clear agent env so mode tests start clean.
unset CLAUDECODE CLAUDE_CODE_SESSION_ID CURSOR_TRACE_ID CURSOR_SESSION_ID
unset GROK_AGENT AI_AGENT SPRINTMD_IN_AGENT SPRINTMD_MODE SPRINTMD_PROVIDER SPRINTMD_CLI
export SPRINTMD_CLI=grok
# shellcheck source=/dev/null
source docs/sprintmd/lib.sh

echo "Test 1: tier inference CLI=grok → grok-build"
assert_eq "tier is grok-build" "grok-build" "$(sprintmd_ai_tier)"

echo "Test 2: profile defines interactive + exec"
assert_true "sprintmd_provider_exec is a function" declare -F sprintmd_provider_exec
assert_true "sprintmd_provider_interactive is a function" declare -F sprintmd_provider_interactive
assert_eq "SPRINTMD_PROVIDER_INTERACTIVE=1" "1" "${SPRINTMD_PROVIDER_INTERACTIVE:-}"

echo "Test 3: GROK_AGENT → emit mode"
_SPRINTMD_MODE_CACHE=""
export GROK_AGENT=1
assert_eq "mode emit with GROK_AGENT" "emit" "$(sprintmd_ai_mode)"
unset GROK_AGENT
_SPRINTMD_MODE_CACHE=""

echo "Test 4: no agent env + CLI on PATH → exec (or emit if grok missing)"
# Force CLI presence via a fake binary if needed for stable exec.
if ! command -v grok >/dev/null 2>&1; then
  mkdir -p "$TMPDIR/bin"
  printf '#!/bin/sh\nexit 0\n' > "$TMPDIR/bin/grok"
  chmod +x "$TMPDIR/bin/grok"
  export PATH="$TMPDIR/bin:$PATH"
fi
_SPRINTMD_MODE_CACHE=""
assert_eq "mode exec outside agent" "exec" "$(sprintmd_ai_mode)"

echo "Test 5: explicit MODE overrides auto-detect"
export SPRINTMD_MODE=emit
_SPRINTMD_MODE_CACHE=""
assert_eq "MODE=emit override" "emit" "$(sprintmd_ai_mode)"
export SPRINTMD_MODE=exec
_SPRINTMD_MODE_CACHE=""
assert_eq "MODE=exec override" "exec" "$(sprintmd_ai_mode)"
unset SPRINTMD_MODE
_SPRINTMD_MODE_CACHE=""

echo "Test 6: orchestration helpers"
assert_true "orchestration_capable on grok-build" sprintmd_orchestration_capable
assert_eq "subagent tool name" "spawn_subagent" "$(sprintmd_subagent_tool_name)"
_phrase="$(sprintmd_subagent_spawn_phrase "next-id")"
assert_contains "spawn phrase mentions spawn_subagent" "$_phrase" "spawn_subagent"
assert_contains "spawn phrase has general-purpose" "$_phrase" "general-purpose"
assert_contains "own fresh has spawn_subagent" "$(sprintmd_subagent_own_fresh)" "spawn_subagent"
assert_contains "parallel dispatch has spawn_subagent" "$(sprintmd_subagent_parallel_dispatch)" "spawn_subagent"

echo "Test 7: claude-code helpers still say Task tool"
export SPRINTMD_PROVIDER=claude-code
assert_true "orchestration_capable on claude-code" sprintmd_orchestration_capable
assert_eq "claude subagent tool name" "Task tool" "$(sprintmd_subagent_tool_name)"
assert_contains "claude own fresh Task tool" "$(sprintmd_subagent_own_fresh)" "Task tool"
export SPRINTMD_PROVIDER=generic
assert_false "generic not orchestration_capable" sprintmd_orchestration_capable
unset SPRINTMD_PROVIDER
assert_eq "back to grok-build" "grok-build" "$(sprintmd_ai_tier)"

echo "Test 8: tier model default grok-4.5"
assert_eq "tier model CHAT is grok-4.5" "grok-4.5" "$(sprintmd_tier_model CHAT)"

echo "Test 9: tool mapping (map known Claude names; fail-open on unknown)"
# shellcheck source=/dev/null
source docs/sprintmd/cli/grok.sh
mapped="$(_sprintmd_grok_map_tools "Read,Edit,Write,Bash,Grep,Glob")"
assert_eq "map core tools" "read_file,search_replace,write,run_terminal_command,grep,list_dir" "$mapped"
mapped_agent="$(_sprintmd_grok_map_tools "Read,Edit,Agent" || true)"
# Agent is skipped; Read+Edit still map
assert_eq "Agent skipped, rest map" "read_file,search_replace" "$mapped_agent"
if _sprintmd_grok_map_tools "Read,UnknownTool" >/dev/null 2>&1; then
  echo "  FAIL: unmapped tool should fail-open (return non-zero)"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: unmapped tool fails open"
  PASS=$((PASS + 1))
fi

echo "Test 10: profile file ships under docs (ship mirrors to src)"
assert_true "cli/grok.sh exists in docs" test -f "$SPRINTMD/cli/grok.sh"

echo "Test 11: provider banner once per process"
# Capture stderr only (pipe so -t 2 is false; no /dev/tty double in CI).
banner_out=$(
  SPRINTMD_CLI=grok SPRINTMD_PROVIDER=grok-build SPRINTMD_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTMD"'/lib.sh"
    sprintmd_announce_provider
    sprintmd_announce_provider
  ' 2>&1 >/dev/null
)
assert_contains "banner names grok" "$banner_out" "Provider: grok (grok-build)"
assert_contains "banner names mode" "$banner_out" "mode: exec"
# Exactly one banner line (second call is a no-op).
banner_lines=$(printf '%s\n' "$banner_out" | grep -c 'Provider:' || true)
assert_eq "banner once only" "1" "$banner_lines"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
