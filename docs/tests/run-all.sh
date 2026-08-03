#!/usr/bin/env bash
# run-all.sh — Entry point for the SprintBias *platform* test suite.
#
# Dev-only (does not ship). See docs/guides/running-tests.md.
#
# Usage:
#   bash docs/tests/run-all.sh              # unit: all test-*.sh
#   bash docs/tests/run-all.sh --unit       # same
#   bash docs/tests/run-all.sh --emit       # unit + emit/matrix smokes
#   bash docs/tests/run-all.sh --list       # print what would run
#   bash docs/tests/run-all.sh --live       # print pointer to dual-provider guide
#
# Exit 0 only if every selected script exits 0.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TESTS="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

MODE=unit
LIST_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --unit)  MODE=unit ;;
    --emit)  MODE=emit ;;
    --live)  MODE=live ;;
    --list)  LIST_ONLY=1 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done

if [ "$MODE" = "live" ]; then
  cat <<'EOF'
Tier 3 (live dual-provider) is not automated in this harness.

Follow the maintainer ritual:
  docs/guides/dual-provider-smoke.md

Preconditions: ./ship.sh, then fresh setup.sh into /tmp per provider.
For a lighter Grok check (mostly offline):
  bash docs/tests/smoke-grok-spine.sh
EOF
  exit 0
fi

# Ordered unit scripts: discovery is stable sort; put create/validate early for
# readable logs. Anything new matching test-*.sh is still picked up.
unit_scripts=()
while IFS= read -r f; do
  unit_scripts+=("$f")
done < <(find "$TESTS" -maxdepth 1 -name 'test-*.sh' -type f | sort)

emit_scripts=(
  "$TESTS/test-command-matrix-smoke.sh"
  "$TESTS/smoke-grok-spine.sh"
)

scripts=("${unit_scripts[@]}")
if [ "$MODE" = "emit" ]; then
  # unit first, then emit extras (skip if already in unit list)
  for e in "${emit_scripts[@]}"; do
    base=$(basename "$e")
    already=0
    for u in "${unit_scripts[@]}"; do
      [ "$(basename "$u")" = "$base" ] && already=1 && break
    done
    [ "$already" -eq 0 ] && [ -f "$e" ] && scripts+=("$e")
  done
fi

if [ "$LIST_ONLY" -eq 1 ]; then
  echo "Mode: $MODE"
  for s in "${scripts[@]}"; do
    echo "  ${s#$ROOT/}"
  done
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ platform suite  mode=$MODE  scripts=${#scripts[@]}"
echo "  guide: docs/guides/running-tests.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS_S=0
FAIL_S=0
FAILED_NAMES=()

for s in "${scripts[@]}"; do
  rel="${s#$ROOT/}"
  name=$(basename "$s")
  echo "── $rel ──"
  set +e
  bash "$s"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    echo "  ▸ script OK ($name)"
    PASS_S=$((PASS_S + 1))
  else
    echo "  ▸ script FAIL ($name) exit=$rc"
    FAIL_S=$((FAIL_S + 1))
    FAILED_NAMES+=("$name")
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Suite: $PASS_S passed, $FAIL_S failed (of ${#scripts[@]} scripts)"
if [ "$FAIL_S" -gt 0 ]; then
  echo "  Failed:"
  for n in "${FAILED_NAMES[@]}"; do echo "    - $n"; done
  echo "  See docs/guides/running-tests.md"
  exit 1
fi
echo "  All selected scripts green."
exit 0
