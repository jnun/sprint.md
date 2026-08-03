#!/usr/bin/env bash
# check-inventory.sh — Walk the synthetic board and print how *current*
# SprintBias helpers classify each canary's unmet deps.
#
# This is a diagnostic, not a pass/fail gate for every Expected cell in
# MATRIX.md (many require Plan 15). It does fail if the board is missing
# or seed layout is broken.
#
# Usage:
#   bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh [BOARD]
#
# BOARD defaults to ./board next to this script. When BOARD is the fixture
# board, we temporarily cd there and source the *repo* lib.sh so helpers
# match product code.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# fixture lives at docs/tests/fixtures/dep-glitch-matrix → repo is 4 levels up
REPO="$(cd "$HERE/../../../.." && pwd)"
BOARD="${1:-$HERE/board}"

if [ ! -d "$BOARD/docs/tasks/next" ]; then
  echo "✗ No board at $BOARD — run seed.sh first" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$REPO/docs/sprintmd/lib.sh"

cd "$BOARD"

echo "=== dep-glitch-matrix inventory ==="
echo "board: $BOARD"
echo "lib:   $REPO/docs/sprintmd/lib.sh"
echo ""

stage_of() {
  local id="$1"
  sprintmd_task_stage "$id" 2>/dev/null || true
}

# Print classification line for one dependency id.
classify_dep() {
  local id="$1" stage path
  stage="$(stage_of "$id")"
  path="$(sprintmd_task_path "$id" 2>/dev/null || true)"
  if [ -z "$stage" ]; then
    # Fold tombstones / ledger hints
    case "$id" in
      9011) echo "MS/FD  missing-or-fold  (ledger: folded→9012; tombstone may exist)" ;;
      9013) echo "MS/SP  missing-split-parent  (children 9014 next, 9015 backlog)" ;;
      9041) echo "MS     chat-removed  (no survivor)" ;;
      9042) echo "MS/FD  replaced  (survivor 9043)" ;;
      9010) echo "MS     pure-dangling" ;;
      *)    echo "MS     missing-no-file" ;;
    esac
    return 0
  fi
  local extra=""
  if [ -n "$path" ]; then
    if grep -q '^## Completed' "$path" 2>/dev/null; then
      extra="${extra} +Completed"
    fi
    if grep -qiE '^\*\*Folded into\*\*:' "$path" 2>/dev/null; then
      extra="${extra} +FoldedInto"
    fi
    if grep -q '^## Outcome' "$path" 2>/dev/null; then
      local res
      res=$(grep -m1 '^\*\*Result\*\*:' "$path" 2>/dev/null | sed 's/.*: *//' || true)
      [ -n "$res" ] && extra="${extra} +Outcome:${res}"
    fi
    if [ "$(sprintmd_review_verdict "$path")" = "READY" ]; then
      extra="${extra} +READY"
    elif [ "$(sprintmd_review_verdict "$path")" = "BLOCKED" ]; then
      extra="${extra} +BLOCKED"
    fi
  fi
  printf '%-6s %s%s\n' "$stage" "present" "$extra"
}

echo "── Canary unmet deps (current sprintmd_unmet_deps + stage class) ──"
echo ""

canaries=$(find docs/tasks/next -name '90[5-8][0-9]-*.md' | sort -t/ -k4)
for f in $canaries; do
  [ -f "$f" ] || continue
  id=$(basename "$f" | sed 's/-.*//')
  title=$(grep -m1 '^# ' "$f" | sed 's/^# Task [0-9]*: //')
  unmet="$(sprintmd_unmet_deps "$f" || true)"
  echo "▸ #${id}  ${title}"
  if [ -z "$unmet" ]; then
    echo "    unmet: (none) — current gating would treat as runnable"
  else
    echo "    unmet: $unmet"
    for d in $unmet; do
      printf '      → %s  ' "$d"
      classify_dep "$d" | tr '\n' ' '
      echo
    done
  fi
  # Also show raw Depends on for hash/malformed cases outside canary range
  echo ""
done

echo "── Special / integrity samples ──"
echo ""

for id in 9016 9018 9019 9020 9036 9037 9038 9081 9082 9083 9086 9087 9089; do
  f=$(find docs/tasks -name "${id}-*.md" 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    echo "▸ #${id}  (no file)"
    continue
  fi
  stage=$(stage_of "$id")
  deps=$(sprintmd_meta_value "$f" "Depends on")
  blocks=$(sprintmd_meta_value "$f" "Blocks")
  plan=$(sprintmd_meta_value "$f" "Plan")
  parent=$(sprintmd_meta_value "$f" "Parent")
  unmet=$(sprintmd_unmet_deps "$f" || true)
  echo "▸ #${id}  [${stage}]  Depends=[${deps}]  Blocks=[${blocks}]  Plan=[${plan}]  Parent=[${parent}]"
  echo "    unmet_deps → [${unmet}]"
  echo ""
done

echo "── Fold / split ledger cross-check ──"
echo ""
for pair in "9011:9012" "9042:9043" "9013:9014"; do
  from=${pair%%:*}; to=${pair##*:}
  fs=$(stage_of "$from"); ts=$(stage_of "$to")
  echo "  $from (${fs:-MISSING}) → $to (${ts:-MISSING})"
done
echo ""

echo "── FALSE GREEN detector (Plan 15 gaps) ──"
echo "    Current sprintmd_unmet_deps treats 'no file anywhere' as complete."
echo "    These canaries Declares a missing/fold id but show unmet empty:"
echo ""
false_green=0
# canary_id:expected_missing_dep_ids
for row in \
  "9055:9010" \
  "9057:9041" \
  "9058:9042" \
  "9059:9013" \
  "9067:9010" \
  "9080:9010 9013"
do
  cid=${row%%:*}; expect=${row#*:}
  f=$(find docs/tasks/next -name "${cid}-*.md" | head -1)
  [ -n "$f" ] || continue
  unmet="$(sprintmd_unmet_deps "$f" || true)"
  raw=$(sprintmd_meta_value "$f" "Depends on")
  for mid in $expect; do
    # if raw depends includes mid and mid has no stage and mid not in unmet → false green
    case " $raw " in *" $mid "*|*"#$mid "*|*,$mid,*|*" $mid,"*|",$mid "*) ;;
      *)
        # also allow bare list without spaces
        case ",${raw// /}," in *",${mid},"*|*",#${mid},"*) ;;
          *) continue ;;
        esac
        ;;
    esac
    st=$(stage_of "$mid")
    if [ -z "$st" ]; then
      case " $unmet " in *" $mid "*) ;;
        *)
          echo "  ✗ #$cid depends on missing #$mid but unmet_deps omits it (false green)"
          false_green=$((false_green + 1))
          ;;
      esac
    fi
  done
done
# Range canary: 9074 expands 9001-9003; 9001/9002 met, 9003 open — ok
# Fold tombstone 9056 correctly shows 9011 in backlog (not false green)
if [ "$false_green" -eq 0 ]; then
  echo "  (none detected — unexpected if missing ids are still treated complete)"
else
  echo ""
  echo "  $false_green false-green edge(s). Plan 15 #328/#330 should make these unmet or 'broken'."
fi
echo ""

echo "── Umbrella #9080 raw Depends on ──"
u=$(find docs/tasks/next -name '9080-*.md' | head -1)
if [ -n "$u" ]; then
  echo "  $(sprintmd_meta_value "$u" "Depends on")"
  echo "  unmet → [$(sprintmd_unmet_deps "$u" || true)]"
fi
echo ""

echo "── Counts ──"
for s in backlog next doing blocked review done; do
  n=$(find "docs/tasks/$s" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  printf '  %-8s %s\n' "$s" "$n"
done

echo ""
echo "Done. Compare stages to MATRIX.md Expected column."
echo "Gaps where unmet is empty but Expected is broken/missing are Plan 15 work."
