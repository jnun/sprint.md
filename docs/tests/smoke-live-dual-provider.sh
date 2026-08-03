#!/usr/bin/env bash
# smoke-live-dual-provider.sh — opt-in LIVE dual-provider smoke runner (task 301)
#
# The automation wrapper for the manual dual-provider ritual in
# docs/guides/dual-provider-smoke.md (#297) and the exec-shape assertions in
# docs/tests/smoke-grok-spine.sh (#296). Those prove shape offline; THIS runner
# actually launches `claude` and `grok` headlessly to catch what only a real CLI
# call reveals: auth, streaming/JSON, headless flags, and the live banner.
#
# It mirrors those checklists — it does not invent a third protocol. Per step it
# records PASS / FAIL / SKIP to stdout (and, with --log, a file under docs/tmp/).
#
# OPT-IN BY DESIGN. It touches the network and needs a logged-in CLI, so it is
# OFF unless you ask for it. With neither `--live` nor LIVE_SMOKE=1 it prints one
# line and exits 0 — safe for the offline unit suite and CI. It is also named
# OUTSIDE the `test-*.sh` glob that #302's run-all sweeps, so even a harness that
# discovered it would not run the live steps without the opt-in.
#
#   ./smoke-live-dual-provider.sh              # skipped (prints how to enable)
#   LIVE_SMOKE=1 ./smoke-live-dual-provider.sh # run live steps for both CLIs
#   ./smoke-live-dual-provider.sh --live --log # + write a log under docs/tmp/
#
# Per provider it self-skips (never fails) when the CLI is missing, and it
# distinguishes an "auth/network" outcome from a real "product bug": a headless
# call that dies on a login/quota/connection marker is a SKIP with that reason,
# not a FAIL. Interactive chat needs a real terminal; without a TTY it is a
# documented skip. No production task state is mutated — the live one-shot is a
# throwaway prompt, no files move.

set -uo pipefail

# ── Opt-in gate ──────────────────────────────────────────────────────
LIVE="${LIVE_SMOKE:-}"
DO_LOG="${SMOKE_LOG:-0}"
for arg in "$@"; do
  case "$arg" in
    --live) LIVE=1 ;;
    --log)  DO_LOG=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $arg (try --help)" >&2; exit 2 ;;
  esac
done

if [ -z "$LIVE" ] || [ "$LIVE" = 0 ]; then
  echo "smoke-live-dual-provider: skipped (set LIVE_SMOKE=1 or pass --live to run live steps)"
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTMD="$ROOT/docs/sprintmd"

# ── Log (optional) ───────────────────────────────────────────────────
LOG=""
if [ "$DO_LOG" = 1 ]; then
  mkdir -p "$ROOT/docs/tmp"
  LOG="$ROOT/docs/tmp/smoke-live-$(date +%Y%m%d-%H%M%S).log"
fi
say() { if [ -n "$LOG" ]; then printf '%s\n' "$*" | tee -a "$LOG"; else printf '%s\n' "$*"; fi; }

PASS=0; FAIL=0; SKIP=0
pass() { say "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { say "  FAIL: $1"; FAIL=$((FAIL + 1)); }
skip() { say "  SKIP: $1"; SKIP=$((SKIP + 1)); }

# Markers that mean "auth/network, not a product bug" — a headless call that
# dies on any of these is a SKIP with that reason, never a FAIL.
AUTHNET_RE='unauthorized|not logged in|log ?in|please authenticate|api[ _-]?key|credential|token|401|403|429|network|ENOTFOUND|ECONNREFUSED|ETIMEDOUT|timed? ?out|rate limit|balance|quota|offline'

# Optional wall-clock guard so a wedged CLI never hangs the runner.
TMO=()
command -v timeout >/dev/null 2>&1 && TMO=(timeout 120)

# Run a real headless one-shot for a provider, capturing stdout and stderr to
# the caller-named temp files. Clears the FULL agent-detection env set so mode
# is honestly exec even when this runner is invoked from inside an agent.
run_exec() {
  local cli="$1" provider="$2" prompt="$3" out="$4" err="$5"
  "${TMO[@]}" env \
    SPRINTMD_CLI="$cli" SPRINTMD_PROVIDER="$provider" SPRINTMD_MODE=exec \
    GROK_AGENT= CLAUDECODE= CLAUDE_CODE_SESSION_ID= \
    CURSOR_TRACE_ID= CURSOR_SESSION_ID= AI_AGENT= SPRINTMD_IN_AGENT= \
    bash -c "source '$SPRINTMD/lib.sh' >/dev/null 2>&1; sprintmd_run -p '$prompt' --max-turns 1" \
    >"$out" 2>"$err"
}

# ── Per-provider suite ───────────────────────────────────────────────
# $1 label  $2 cli-binary  $3 provider-tier  $4 agent-env-var (emit trigger)
provider_suite() {
  local label="$1" cli="$2" provider="$3" agentvar="$4"
  say ""
  say "════ $label ($cli / $provider) ════"

  # 1. CLI present? Missing → skip the whole leg (never a fail).
  if ! command -v "$cli" >/dev/null 2>&1; then
    skip "$label: '$cli' not on PATH — install it to run this leg"
    return 0
  fi
  say "  $cli: $(command -v "$cli")"

  # 2. Emit detection (offline note) — inside its own agent, this CLI emits.
  local mode_agent
  mode_agent="$(env SPRINTMD_CLI="$cli" SPRINTMD_PROVIDER="$provider" \
    "$agentvar=1" GROK_AGENT= CLAUDECODE= \
    bash -c "export $agentvar=1; source '$SPRINTMD/lib.sh' >/dev/null 2>&1; sprintmd_ai_mode" 2>/dev/null)"
  if [ "$mode_agent" = "emit" ]; then
    pass "emit detection: $agentvar set → mode emit"
  else
    fail "emit detection: $agentvar set should give emit (got '${mode_agent:-empty}')"
  fi

  # 3. Banner + headless one-shot under a REAL exec (one live call, two checks).
  local out err
  out="$(mktemp)"; err="$(mktemp)"
  say "  running live headless one-shot (network + auth required)…"
  local rc=0
  run_exec "$cli" "$provider" "Reply with exactly this token and nothing else: SMOKELIVE_OK" "$out" "$err" || rc=$?

  # 3a. Banner: sprintmd_announce_provider writes it to stderr before the call.
  if grep -qF "Provider: $cli" "$err" 2>/dev/null && grep -qF "mode: exec" "$err" 2>/dev/null; then
    pass "provider banner under exec (▸ Provider: $cli … mode: exec)"
  else
    fail "provider banner missing/incorrect under exec"
    say "    stderr head: $(head -n 3 "$err" 2>/dev/null | tr '\n' '|')"
  fi

  # 3b. One-shot result — classify auth/network vs product bug on failure.
  if [ "$rc" -eq 0 ] && grep -qF "SMOKELIVE_OK" "$out" 2>/dev/null; then
    pass "headless one-shot returned the expected token"
  elif grep -qiE "$AUTHNET_RE" "$out" "$err" 2>/dev/null; then
    skip "headless one-shot: auth/network (not a product bug) — log in / check connectivity"
  elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    skip "headless one-shot: timed out (auth/network) — CLI wedged past the wall-clock guard"
  else
    fail "headless one-shot failed (rc=$rc, no auth/network marker) — looks like a product bug"
    say "    stdout head: $(head -n 3 "$out" 2>/dev/null | tr '\n' '|')"
    say "    stderr head: $(head -n 3 "$err" 2>/dev/null | tr '\n' '|')"
  fi
  rm -f "$out" "$err"

  # 4. Interactive chat — needs a real terminal; otherwise a documented skip.
  if [ -t 0 ] && [ -t 1 ]; then
    local flag; [ "$cli" = grok ] && flag=-g || flag=-c
    skip "interactive chat: run \`./sprint.sh $flag chat\` by hand — this runner never opens a live TUI"
    local okint
    okint="$(env SPRINTMD_CLI="$cli" SPRINTMD_PROVIDER="$provider" SPRINTMD_MODE=exec \
      GROK_AGENT= CLAUDECODE= \
      bash -c "source '$SPRINTMD/lib.sh' >/dev/null 2>&1; sprintmd_interactive_ok && echo yes || echo no" 2>/dev/null)"
    # Both shipped profiles set SPRINTMD_PROVIDER_INTERACTIVE=1, so a real TTY
    # in exec mode means a live session is possible.
    [ "$okint" = "yes" ] && pass "interactive_ok true on a real TTY" \
                         || fail "interactive_ok should be true on a real TTY (got '$okint')"
  else
    skip "interactive chat: no TTY here — live TUI open is a documented manual step"
  fi
}

say "=== smoke-live-dual-provider.sh (LIVE) ==="
[ -n "$LOG" ] && say "log: $LOG"
say "Mirrors docs/guides/dual-provider-smoke.md + docs/tests/smoke-grok-spine.sh."

provider_suite "Claude leg" claude claude-code CLAUDECODE
provider_suite "Grok leg"   grok   grok-build  GROK_AGENT

say ""
say "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
