#!/usr/bin/env bash
# audit-code.sh — Code quality audit. See: ./sprint.sh help review-code

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

AI_MODE="$(fiveday_ai_mode)"
MODEL="$(fiveday_resolve_model CODE_AUDIT)"
TOOLS_FIXER="Read,Edit,Write,Bash,Grep,Glob,Agent"
TOOLS_VERIFIER="Read,Bash,Grep,Glob,Agent"
PERMISSIONS="auto"
MAX_TURNS=30
LOG_DIR="docs/tmp"

# ── Parse arguments ─────────────────────────────────────────────────
# Accepts:
#   audit-code.sh <task.md> [max-passes]
#   audit-code.sh <file1> <file2> ... [-- max-passes]
TASK_FILE=""
EXPLICIT_FILES=()
MAX_PASSES="${FIVEDAY_AUDIT_MAX_PASSES:-3}"

if [ $# -eq 0 ]; then
  echo "Usage:" >&2
  echo "  audit-code.sh <task-file.md> [max-passes]" >&2
  echo "  audit-code.sh <file1> <file2> ... [-- max-passes]" >&2
  exit 1
fi

# Check if first arg is a task .md file or a code file
if [[ "$1" == *.md ]] && [ -f "$1" ]; then
  TASK_FILE="$1"
  shift
  # Optional max-passes as second arg
  [ $# -gt 0 ] && MAX_PASSES="$1"
else
  # Collect file args until -- or end
  while [ $# -gt 0 ]; do
    case "$1" in
      --)
        shift
        [ $# -gt 0 ] && MAX_PASSES="$1"
        break
        ;;
      *)
        if [ -f "$1" ]; then
          EXPLICIT_FILES+=("$1")
        else
          echo "✗ File not found: $1" >&2
          exit 1
        fi
        shift
        ;;
    esac
  done
fi

# ── Preflight ───────────────────────────────────────────────────────
# The CLI binary is only required in exec mode; emit mode hands the prompt
# to the surrounding agent and never spawns it.
if [ "$AI_MODE" != "emit" ] && ! command -v "$FIVEDAY_CLI" &>/dev/null; then
  echo "✗ AI CLI '$FIVEDAY_CLI' not found in PATH" >&2
  echo "  Edit docs/sprintmd/config to change CLI, or install the tool." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

# ── Build the change manifest ───────────────────────────────────────
# Priority: AUDIT_MANIFEST env > explicit files > task ## Completed > git diff
fiveday_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
CHANGED_FILES="$FIVEDAY_CHANGED_FILES"
CONTEXT_SOURCE="$FIVEDAY_CONTEXT_SOURCE"

if [ -z "$CHANGED_FILES" ]; then
  echo "▸ No changed files found — nothing to audit"
  echo "  Context source: $CONTEXT_SOURCE"
  echo ""
  echo "  Provide files explicitly:  ./sprint.sh review-code file1.py file2.ts"
  echo "  Or ensure the task has a ## Completed section listing changed files."
  exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
TASK_NAME=""
TASK_CONTENT=""
if [ -n "$TASK_FILE" ]; then
  TASK_NAME=$(basename "$TASK_FILE")
  TASK_CONTENT=$(<"$TASK_FILE")
fi

echo "▸ Auditing $FILE_COUNT changed file(s)${TASK_NAME:+ for: $TASK_NAME}"
echo "  Context source: $CONTEXT_SOURCE"
echo "  Max fixer passes: $MAX_PASSES"
echo "  Files:"
echo "$CHANGED_FILES" | sed 's/^/    /'
echo ""

# ── Emit mode: hand the whole audit to the surrounding agent ──────────
# In emit mode fiveday_run prints the prompt instead of spawning the CLI, so
# the fixer/verifier loop below cannot parse a verdict out of its command
# substitution (the emitted prompt text — which contains "VERDICT: PASS" —
# would be mis-read as a clean pass having audited nothing). Emit one
# combined prompt describing the whole audit instead, mirroring
# audit-excellence.sh's AI_MODE guard.
if [ "$AI_MODE" = "emit" ]; then
  fiveday_run -p "You are auditing the code changes below for the developer.

CLAUDE.md is auto-loaded with project context and conventions. Read it first.

${TASK_FILE:+ORIGINAL TASK FILE: $TASK_FILE
}CHANGED FILES (context source: $CONTEXT_SOURCE):
$CHANGED_FILES

Do a fresh-eyes code audit:
1. Build an impact graph — grep for imports/references to the changed files.
2. Audit for correctness, project conventions, style (touched lines only),
   build/type safety, and unsafe patterns.
3. Fix any issues you find directly.
4. Re-verify your fixes with read-only checks.

Finish with a '## Summary' section, then a final line:
VERDICT: PASS — no issues | FIXED — fixed all | FAIL — couldn't fix all | BLOCKED — needs human"
  exit 0
fi

# ── Build task context block ────────────────────────────────────────
if [ -n "$TASK_CONTENT" ]; then
  TASK_BLOCK="TASK FILE: $TASK_FILE

ORIGINAL TASK:
---
$TASK_CONTENT
---"
else
  TASK_BLOCK="No task file provided. Auditing the listed files directly."
fi

# ── Build checks (deterministic, run before AI) ────────────────────
run_build_checks() {
  local results=""
  local py_files=()
  local ts_files=()

  # Classify files by type
  while IFS= read -r f; do
    case "$f" in
      *.py)          py_files+=("$f") ;;
      *.ts|*.tsx)    ts_files+=("$f") ;;
    esac
  done <<< "$CHANGED_FILES"

  # Python syntax check
  if [ ${#py_files[@]} -gt 0 ]; then
    if command -v python3 &>/dev/null; then
      local py_pass=0 py_fail=0 py_errors=""
      for f in "${py_files[@]}"; do
        if [ -f "$f" ]; then
          local err
          err=$(python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f" 2>&1) && {
            py_pass=$((py_pass + 1))
          } || {
            py_fail=$((py_fail + 1))
            py_errors="${py_errors}\n  FAIL: $f — $err"
          }
        fi
      done
      if [ "$py_fail" -eq 0 ]; then
        results="${results}Python ast.parse: PASS ($py_pass/$((py_pass + py_fail)) files)\n"
      else
        results="${results}Python ast.parse: FAIL ($py_fail failures)${py_errors}\n"
      fi
    else
      results="${results}Python ast.parse: SKIPPED (python3 not found)\n"
    fi
  fi

  # TypeScript type check
  if [ ${#ts_files[@]} -gt 0 ]; then
    # Find the nearest directory with a tsconfig.json
    local ts_dir=""
    for f in "${ts_files[@]}"; do
      local dir
      dir=$(dirname "$f")
      while true; do
        if [ -f "$dir/tsconfig.json" ]; then
          ts_dir="$dir"
          break 2
        fi
        [ "$dir" = "." ] || [ "$dir" = "/" ] && break
        dir=$(dirname "$dir")
      done
    done

    local tsc_runner=""
    if [ -n "$ts_dir" ]; then
      if command -v pnpm &>/dev/null; then tsc_runner="pnpm"
      elif command -v npx &>/dev/null; then tsc_runner="npx"
      fi
    fi

    if [ -n "$tsc_runner" ]; then
      local tsc_err
      tsc_err=$(cd "$ts_dir" && "$tsc_runner" tsc --noEmit 2>&1) && {
        results="${results}TypeScript tsc: PASS (in $ts_dir)\n"
      } || {
        results="${results}TypeScript tsc: FAIL (in $ts_dir)\n$(echo "$tsc_err" | head -20 | sed 's/^/  /')\n"
      }
    else
      results="${results}TypeScript tsc: SKIPPED (pnpm/npx not found or no tsconfig.json)\n"
    fi
  fi

  printf '%b' "$results"
}

BUILD_CHECK_RESULTS=""
echo "▸ Running build checks..."
BUILD_CHECK_RESULTS=$(run_build_checks)
if [ -n "$BUILD_CHECK_RESULTS" ]; then
  echo "$BUILD_CHECK_RESULTS" | sed 's/^/  /'
else
  echo "  (no applicable build checks)"
fi
echo ""

# ── Feed-forward summary extraction ────────────────────────────────
# Provided by lib.sh as fiveday_extract_summary (shared with audit-excellence).

# ── Audit loop ──────────────────────────────────────────────────────
STEP=0
FIXER_COUNT=0
VERIFY_COUNT=0
VERDICT="FAIL"
NEXT_MODE="fixer"
PREV_SUMMARY=""
TIMESTAMP_BASE=$(date +%Y%m%d-%H%M%S)
_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")
_budget_args=()
[ -n "${FIVEDAY_BUDGET_AUDIT:-}" ] && _budget_args=(--budget "$FIVEDAY_BUDGET_AUDIT")
_log_name="${TASK_NAME:-adhoc}"

MAX_STEPS=$((MAX_PASSES * 2))

_cleanup_files=()
trap 'echo ""; echo "▸ Audit interrupted"; rm -f "${_cleanup_files[@]}" 2>/dev/null; exit 130' INT TERM

LAST_MODE=""

while true; do
  MODE="$NEXT_MODE"

  # Hard ceiling on total steps (fixer + verifier combined)
  if [ "$STEP" -ge "$MAX_STEPS" ]; then
    echo "  ✗ Max total steps ($MAX_STEPS) reached"
    break
  fi

  # Enforce fixer pass limit
  if [ "$MODE" = "fixer" ]; then
    if [ "$FIXER_COUNT" -ge "$MAX_PASSES" ]; then
      echo "  ✗ Max fixer passes ($MAX_PASSES) reached"
      break
    fi
    FIXER_COUNT=$((FIXER_COUNT + 1))
  else
    VERIFY_COUNT=$((VERIFY_COUNT + 1))
  fi

  STEP=$((STEP + 1))
  LAST_MODE="$MODE"

  echo "── Step $STEP ($MODE) ──────────────────────────────────"

  # Select tools based on mode
  if [ "$MODE" = "verifier" ]; then
    ACTIVE_TOOLS="$TOOLS_VERIFIER"
  else
    ACTIVE_TOOLS="$TOOLS_FIXER"
  fi

  # Re-scan changed files between passes
  if [ "$STEP" -gt 1 ]; then
    NEW_CHANGES=$(git diff --name-only 2>/dev/null || true)
    NEW_STAGED=$(git diff --cached --name-only 2>/dev/null || true)
    ALL_NEW=$(printf '%s\n%s' "$NEW_CHANGES" "$NEW_STAGED" | sort -u | grep -v '^$' || true)
    if [ -n "$ALL_NEW" ]; then
      MERGED=$(printf '%s\n%s' "$CHANGED_FILES" "$ALL_NEW" | sort -u | grep -v '^$' || true)
      if [ "$MERGED" != "$CHANGED_FILES" ]; then
        CHANGED_FILES="$MERGED"
        FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
        echo "  ▸ Updated file list ($FILE_COUNT files after rescan)"
      fi
    fi
  fi

  # Capture pre-pass diff (fixer only)
  PRE_DIFF_FILE=""
  if [ "$MODE" = "fixer" ]; then
    PRE_DIFF_FILE=$(mktemp "$LOG_DIR/pre-diff-XXXXXX")
    _cleanup_files+=("$PRE_DIFF_FILE")
    # Use HEAD to capture both staged and unstaged changes
    git diff HEAD > "$PRE_DIFF_FILE" 2>/dev/null || git diff > "$PRE_DIFF_FILE" 2>/dev/null || true
  fi

  # ── Build prompt ────────────────────────────────────────────────

  # Build check results block
  BUILD_BLOCK=""
  if [ -n "$BUILD_CHECK_RESULTS" ]; then
    BUILD_BLOCK="
PRE-AUDIT BUILD CHECK RESULTS:
$BUILD_CHECK_RESULTS
Note: These checks ran outside the AI before audit started. Review results but
do not re-run them unless you changed the relevant files during this pass."
  fi

  # Feed-forward context
  FEED_FORWARD=""
  if [ -n "$PREV_SUMMARY" ]; then
    FEED_FORWARD="
PREVIOUS PASS SUMMARY:
$PREV_SUMMARY"
  fi

  if [ "$MODE" = "verifier" ]; then
    # ── Verifier prompt (read-only, focused on confirming fixes) ──
    PASS_CONTEXT="You are VERIFYING fixes made by a previous auditor. You have READ-ONLY tools.
$FEED_FORWARD"

    PROMPT="Code verifier (READ-ONLY). CLAUDE.md is auto-loaded.

$TASK_BLOCK
$PASS_CONTEXT

CHANGED FILES:
$CHANGED_FILES

1. Read changed files and trace imports/references.
2. Verify: correctness, conventions, safety.
$BUILD_BLOCK

Your response's VERY LAST line must be the verdict and nothing after it, in
exactly this form — the literal word VERDICT, a colon, a space, then ONE
uppercase token, no bold, no punctuation, no trailing text:
VERDICT: PASS    (fixes hold up)   or   VERDICT: FAIL   (issues remain)"

  else
    # ── Fixer prompt (full tools, can edit) ──────────────────────
    if [ "$STEP" -eq 1 ]; then
      PASS_CONTEXT="This is the first audit pass. Be thorough."
    else
      PASS_CONTEXT="This is fixer pass $FIXER_COUNT. A previous pass identified issues.
$FEED_FORWARD

Focus on the specific issues identified above. Fix them if you can."
    fi

    PROMPT="Code auditor with FRESH EYES. CLAUDE.md is auto-loaded.

$TASK_BLOCK
$PASS_CONTEXT

CHANGED FILES:
$CHANGED_FILES

1. Build impact graph: Grep for imports/references to changed files.
2. Audit: correctness, conventions, style (touched lines only), build, safety.
3. Fix issues you find.
$BUILD_BLOCK

End with a '## Summary' section. Then your VERY LAST line must be the verdict
and nothing after it, in exactly this form — the literal word VERDICT, a colon,
a space, then ONE uppercase token, no bold, no punctuation, no trailing text:
VERDICT: PASS
Choose the token by meaning — PASS: no issues · FIXED: fixed all you found ·
FAIL: couldn't fix all · BLOCKED: needs a human."
  fi

  # ── Run the CLI ──────────────────────────────────────────────────

  LOG_FILE="$LOG_DIR/log-audit-code-${_log_name%.md}-step${STEP}-${MODE}-$TIMESTAMP_BASE.json"

  OUTPUT=$(fiveday_run -p "$PROMPT" \
    ${_model_args[@]+"${_model_args[@]}"} \
    ${_budget_args[@]+"${_budget_args[@]}"} \
    --tools "$ACTIVE_TOOLS" \
    --permissions "$PERMISSIONS" \
    --max-turns "$MAX_TURNS" \
    --output-format json 2>/dev/null | tee "$LOG_FILE") || true

  # Extract verdict (case/format tolerant — see fiveday_parse_verdict in lib.sh)
  STEP_VERDICT=$(printf '%s' "$OUTPUT" | fiveday_parse_verdict 'PASS|FIXED|FAIL|BLOCKED')
  [ -z "$STEP_VERDICT" ] && STEP_VERDICT="UNCLEAR"

  echo "  Result: $STEP_VERDICT"

  # Capture post-pass diff and detect no-op (fixer only)
  if [ "$MODE" = "fixer" ] && [ -n "$PRE_DIFF_FILE" ]; then
    POST_DIFF_FILE=$(mktemp "$LOG_DIR/post-diff-XXXXXX")
    _cleanup_files+=("$POST_DIFF_FILE")
    git diff HEAD > "$POST_DIFF_FILE" 2>/dev/null || git diff > "$POST_DIFF_FILE" 2>/dev/null || true

    DIFF_PATCH="$LOG_DIR/diff-audit-step${STEP}-$TIMESTAMP_BASE.patch"
    DIFF_DELTA=$(diff "$PRE_DIFF_FILE" "$POST_DIFF_FILE" 2>/dev/null || true)

    rm -f "$PRE_DIFF_FILE" "$POST_DIFF_FILE"
    _cleanup_files=()  # cleared — files removed

    if [ -n "$DIFF_DELTA" ]; then
      echo "$DIFF_DELTA" > "$DIFF_PATCH"
      echo "  ▸ Changes captured in $(basename "$DIFF_PATCH")"
    fi

    # No-op detection: claimed changes but made none
    if [ -z "$DIFF_DELTA" ]; then
      if [ "$STEP_VERDICT" = "FAIL" ]; then
        echo "  ⚠ FAIL with no actual changes — escalating to BLOCKED"
        STEP_VERDICT="BLOCKED"
      elif [ "$STEP_VERDICT" = "FIXED" ]; then
        echo "  ⚠ FIXED with no actual changes — treating as PASS"
        STEP_VERDICT="PASS"
      fi
    fi
  fi

  # Extract feed-forward summary for next pass
  PREV_SUMMARY=$(fiveday_extract_summary "$LOG_FILE")

  # ── Route verdict ──────────────────────────────────────────────
  case "$STEP_VERDICT" in
    PASS)
      VERDICT="PASS"
      if [ "$MODE" = "verifier" ]; then
        echo "  ✓ Verified — audit complete"
      else
        echo "  ✓ Clean pass — no issues found"
      fi
      break
      ;;
    FIXED)
      VERDICT="FIXED"
      if [ "$MODE" = "verifier" ]; then
        # Verifier can't edit, treat FIXED as PASS
        echo "  ✓ Verified (verifier reported FIXED) — audit complete"
        VERDICT="PASS"
        break
      else
        echo "  ▸ Issues fixed — scheduling verify pass"
        NEXT_MODE="verifier"
      fi
      ;;
    FAIL)
      VERDICT="FAIL"
      if [ "$MODE" = "verifier" ]; then
        echo "  ⚠ Verification failed — scheduling fixer pass"
        NEXT_MODE="fixer"
      else
        echo "  ⚠ Issues remain — re-running fixer"
        NEXT_MODE="fixer"
      fi
      ;;
    BLOCKED)
      VERDICT="BLOCKED"
      echo "  ✗ Blocked — needs human intervention"
      break
      ;;
    *)
      echo "  ? Could not parse verdict — treating as FAIL"
      VERDICT="UNCLEAR"
      NEXT_MODE="fixer"
      ;;
  esac
done

echo ""

# ── Append audit notes to task file (if we have one) ────────────────
if [ -n "$TASK_FILE" ]; then
  {
    echo ""
    echo "## Audit"
    echo ""
    echo "- **Steps run**: $STEP ($FIXER_COUNT fixer + $VERIFY_COUNT verifier)"
    echo "- **Final verdict**: $VERDICT"
    echo "- **Final mode**: ${LAST_MODE:-$MODE}"
    echo "- **Date**: $(date +%Y-%m-%d)"
    echo "- **Files audited**: $FILE_COUNT"
    echo "- **Context source**: $CONTEXT_SOURCE"
    if [ -n "$BUILD_CHECK_RESULTS" ]; then
      echo "- **Build checks**: $(echo "$BUILD_CHECK_RESULTS" | head -1 | tr -d '\n')"
    fi
  } >> "$TASK_FILE"
fi

case "$VERDICT" in
  PASS)
    echo "✓ Code audit passed ($STEP step(s): $FIXER_COUNT fixer + $VERIFY_COUNT verifier)"
    exit 0
    ;;
  UNCLEAR)
    # No parseable verdict — distinguish "CLI never ran" from "model reworded
    # its last line" so the user knows whether to fix their install or re-run.
    echo "? Code audit: could not parse a verdict after $STEP step(s)"
    if [ -n "${LOG_FILE:-}" ] && [ ! -s "$LOG_FILE" ]; then
      echo "  Last log is empty — the AI CLI likely failed to start (check '$FIVEDAY_CLI' install/auth)"
    else
      echo "  The model's final line held no recognizable VERDICT token."
      echo "  Inspect the log tail in $LOG_DIR/, then re-run: ./sprint.sh review-code <files>"
    fi
    exit 1
    ;;
  *)
    echo "⚠ Code audit completed with warnings after $STEP step(s)"
    echo "  Final verdict: $VERDICT"
    echo "  Review audit logs in $LOG_DIR/"
    exit 1
    ;;
esac
