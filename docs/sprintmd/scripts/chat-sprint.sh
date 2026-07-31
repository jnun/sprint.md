#!/usr/bin/env bash
# chat-sprint.sh — Walk the whole sprint through, not one task. A deterministic
# shell preflight computes the structural-health findings (broken dependency
# edges, stage violations, blocked-limbo, stale markers, open questions, orphaned
# parents, cycles) and the workable frontier; the conversational layer then walks
# those findings one at a time — same one-detail voice as single-task `chat`.
#
# Reached via `./sprint.sh chat` with NO task id (chat.sh routes here). This is a
# STRUCTURAL health pass ("is this sprint internally consistent and unblocked?"),
# deliberately distinct from `plan think` (a planning critique of a plan). See:
#   ./sprint.sh help chat
#
# Design: the AI is spent DISCUSSING problems, not FINDING them — so token cost
# scales with problems found, not sprint size (the preflight is pure shell).

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

NEXT_DIR="docs/tasks/next"
BLOCKED_DIR="docs/tasks/blocked"

# Stages an OPEN (incomplete) task can occupy. A dependency found here is not yet
# done; found nowhere here (review/done, or absent) it is satisfied — the exact
# rule sprintmd_unmet_deps encodes. Reciprocity/cycle checks only look inward at
# these, so an edge into an archived review/done task never raises hygiene noise.
OPEN_STAGES="backlog next doing blocked"

# ── Empty-sprint guard ───────────────────────────────────────────────
# Nothing queued means there is no sprint to walk. Say so and leave cleanly —
# this is a normal state (between sprints), not an error.
NEXT_COUNT=$(find "$NEXT_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$NEXT_COUNT" -eq 0 ]; then
  echo "▸ Sprint walkthrough"
  echo "  next/ is empty — no sprint to walk. Queue one first:  ./sprint.sh plan"
  exit 0
fi

echo "▸ Sprint walkthrough — checking structural health of $NEXT_COUNT queued task(s)…"
echo ""

# ── Field parsing ────────────────────────────────────────────────────
# No metadata helper exists in lib.sh for these fields; parse by hand, the same
# way chat.sh and the audit scripts do. Always exit 0 so set -e never trips on a
# field that is simply absent.

# field FILE LABEL -> the text after "**LABEL**:" on its first matching line.
field() {
  { grep -m1 -iE "^[[:space:]]*\*\*$2\*\*[[:space:]]*:" "$1" 2>/dev/null || true; } \
    | sed -E 's/^[^:]*:[[:space:]]*//'
}

# id_list "1, #3-5, none" -> "1 3 4 5". Expands N-M ranges; drops none/n-a/blank.
# Leading '#' is optional (same as sprintmd_iter_id_list in lib.sh).
id_list() {
  local raw="$1" tok lo hi n ids=""
  case "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" in
    none*|n/a*|-*|'') return 0 ;;
  esac
  for tok in $(printf '%s' "$raw" | tr ',' ' '); do
    tok="${tok#\#}"
    if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
      [ "$lo" -le "$hi" ] || continue
      for ((n=lo; n<=hi; n++)); do ids="$ids $n"; done
    elif [[ "$tok" =~ ^[0-9]+$ ]]; then
      ids="$ids $tok"
    fi
  done
  printf '%s' "${ids# }"
}

# ── Task index ───────────────────────────────────────────────────────
# One pass over every stage builds "ID<TAB>STAGE<TAB>FILE" lines. Every later
# lookup reads this string instead of re-globbing the tree — bash 3.2 (macOS)
# has no associative arrays, so a shared string + awk is the portable index.
# Iterate SPRINTMD_STAGES rather than hardcoding folder names (lib.sh:251).
build_index() {
  local stage dir f id
  for stage in "${SPRINTMD_STAGES[@]}"; do
    dir="docs/tasks/$stage"
    [ -d "$dir" ] || continue
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      id="$(task_id "$f")"
      [[ "$id" =~ ^[0-9]+$ ]] || continue
      printf '%s\t%s\t%s\n' "$id" "$stage" "$f"
    done
  done
}
INDEX="$(build_index)"

# stage_of ID / file_of ID -> the task's stage / path, empty if it exists nowhere.
stage_of() { printf '%s\n' "$INDEX" | awk -F'\t' -v id="$1" '$1==id{print $2; exit}'; }
file_of()  { printf '%s\n' "$INDEX" | awk -F'\t' -v id="$1" '$1==id{print $3; exit}'; }

# is_open STAGE -> 0 if the stage holds incomplete work.
is_open() { case " $OPEN_STAGES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ── Open-question extraction ─────────────────────────────────────────
# The single most common reason a task looks ready but isn't. Two precise
# sources, never free prose:
#   (a) the '### Questions for the developer' subsection (define/chat convention);
#   (b) a strict inline "Open questions:" LABEL in ## Notes — a line that is ONLY
#       that label, then the list directly under it (the pre-migration 222 shape).
# From either, keep only TOP-LEVEL list items (marker at column 0) — continuation
# sub-bullets of a resolved item are indented and so are skipped — and drop any
# item already marked resolved/answered/decided or a none-sentinel. Conservative
# by design; the conversational layer re-reads the file and skips anything
# already settled, so a stray false positive costs one glance, never a bad edit.
open_questions() {
  local file="$1"
  {
    awk '
      /^### Questions for the developer[[:space:]]*$/ { cap=1; next }
      cap && /^(## |### )/ { cap=0 }
      cap { print }
    ' "$file"
    awk '
      /^[#>*[:space:]]*[Oo]pen [Qq]uestions?[[:space:]:*]*$/ { cap=1; next }
      cap && (/^[[:space:]]*$/ || /^(## |### )/) { cap=0 }
      cap { print }
    ' "$file"
  } 2>/dev/null \
    | grep -E '^([-*]|[0-9]+\.)[[:space:]]' \
    | grep -viE '^([-*]|[0-9]+\.)[[:space:]]+\**(resolved|answered|decided|settled|none)\b' \
    | sed -E 's/^([-*]|[0-9]+\.)[[:space:]]*//; s/\*\*//g; s/[[:space:]]+/ /g' \
    || true
}

# short TEXT [MAX] -> collapse to a single scannable line, ellipsizing past MAX.
# Findings feed a terminal list and the prompt; the AI re-reads the file for the
# verbatim question, so the summary only needs to be recognizable, not complete.
short() {
  local text="$1" max="${2:-140}"
  if [ "${#text}" -gt "$max" ]; then
    printf '%s…' "${text:0:$max}"
  else
    printf '%s' "$text"
  fi
}

# ── Findings accumulator ─────────────────────────────────────────────
# One line per finding: SEV<TAB>CATEGORY<TAB>ID<TAB>FILE<TAB>SUMMARY<TAB>FIX.
# Kept single-line so `sort` can order the whole set most-blocking-first (lowest
# SEV) and, within a severity, by task id. Severities:
#   1 BLOCKER    2 INTEGRITY    3 ORDERING    4 HYGIENE
FINDINGS=""
add_finding() {
  FINDINGS="${FINDINGS}$(printf '%s\t%s\t%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4" "$5" "$6")
"
}

# Task ids in the sprint board under review (next/ + blocked/), numerically.
board_ids() {
  printf '%s\n' "$INDEX" \
    | awk -F'\t' '$2=="next" || $2=="blocked" { print $1 }' \
    | sort -n
}

# ── Structural checks ────────────────────────────────────────────────
for id in $(board_ids); do
  file="$(file_of "$id")"
  stage="$(stage_of "$id")"
  deps="$(id_list "$(field "$file" 'Depends on')")"
  blocks="$(id_list "$(field "$file" 'Blocks')")"
  parent="$(id_list "$(field "$file" 'Parent')")"
  verdict="$(sprintmd_review_verdict "$file")"

  # 1. Dangling edges — a dep/blocks id with no file anywhere on disk.
  for d in $deps; do
    [ -n "$(stage_of "$d")" ] && continue
    add_finding 2 INTEGRITY "$id" "$file" \
      "declares 'Depends on: $d' but task $d exists in no stage (broken edge)" \
      "correct the id, or drop $d from the Depends on line"
  done
  for b in $blocks; do
    [ -n "$(stage_of "$b")" ] && continue
    add_finding 2 INTEGRITY "$id" "$file" \
      "declares 'Blocks: $b' but task $b exists in no stage (broken edge)" \
      "correct the id, or drop $b from the Blocks line"
  done

  # 2. One-way edges — A depends on B, but B (if still open) omits A from Blocks.
  #    Checked only when B is open, so an edge into an archived task is silent.
  for d in $deps; do
    df="$(file_of "$d")"; [ -n "$df" ] || continue
    is_open "$(stage_of "$d")" || continue
    dbl="$(id_list "$(field "$df" 'Blocks')")"
    case " $dbl " in *" $id "*) : ;; *)
      add_finding 4 HYGIENE "$id" "$file" \
        "depends on $d, but task $d's 'Blocks' does not list $id (one-way edge)" \
        "add $id to task $d's Blocks line so the edge is reciprocal" ;;
    esac
  done

  # 3. Orphaned parent — a Parent id pointing at a task that no longer exists.
  for p in $parent; do
    [ -n "$(stage_of "$p")" ] && continue
    add_finding 4 HYGIENE "$id" "$file" \
      "names 'Parent: $p' but task $p exists in no stage (orphaned parent)" \
      "point Parent at the real plan, or set it to none"
  done

  # 4. Outstanding questions — surfaced one per finding so each can be walked
  #    and written back singly. On a READY next/ task these are integrity bugs
  #    (marked ready, not actually ready); elsewhere they are ordering issues.
  #    A task correctly stamped BLOCKED already advertises why it can't run —
  #    re-surfacing its recorded question would be noise, so skip that case.
  if [ "$verdict" != "BLOCKED" ]; then
  while IFS= read -r q; do
    [ -n "$q" ] || continue
    qshort="$(short "$q")"
    if [ "$stage" = "next" ] && [ "$verdict" = "READY" ]; then
      add_finding 2 INTEGRITY "$id" "$file" \
        "is marked READY but carries an open question: \"$qshort\"" \
        "answer/decide it and write the resolution back into the file, or 'chat $id' to define it"
    else
      add_finding 3 ORDERING "$id" "$file" \
        "has an outstanding question: \"$qshort\"" \
        "answer/decide it and write the resolution back into the file, or 'chat $id' to define it"
    fi
  done <<EOF
$(open_questions "$file")
EOF
  fi

  # 5. Stage-specific checks.
  if [ "$stage" = "next" ]; then
    # Stale-ready — queued to run without gate's READY verdict.
    if [ "$verdict" != "READY" ]; then
      add_finding 4 HYGIENE "$id" "$file" \
        "sits in next/ without a '**Status: READY**' stamp (work will skip it)" \
        "run 'chat $id' to finish defining it, or 'gate' to vet it"
    fi
    # Dependency-stage violations — grade each unmet dep by where it sits.
    for u in $(sprintmd_unmet_deps "$file"); do
      ustage="$(stage_of "$u")"
      case "$ustage" in
        blocked)
          add_finding 1 BLOCKER "$id" "$file" \
            "depends on $u, which is BLOCKED — this task cannot actually run yet" \
            "PATH A: define $u so it can leave blocked/ (hands off to 'chat $u'); or PATH B: demote this task to backlog/ so the sprint holds no work blocked on $u" ;;
        backlog)
          add_finding 3 ORDERING "$id" "$file" \
            "depends on $u, still in backlog/ — prerequisite is not even in the sprint" \
            "pull $u into the sprint ('plan') or defer this task until it is planned" ;;
        # next/doing: both in flight — frontier ordering handles it, not a finding.
      esac
    done
  fi

  if [ "$stage" = "blocked" ]; then
    # Blocked-limbo — parked in blocked/ with no marker and no Questions section
    # explaining why. The 207/221 case: reads ready, invisible to any reader.
    if [ "$verdict" != "BLOCKED" ] && ! grep -qE '^## Questions[[:space:]]*$' "$file"; then
      add_finding 3 ORDERING "$id" "$file" \
        "sits in blocked/ with no '**Status: BLOCKED**' and no '## Questions' — parked but invisible, almost certainly mis-filed" \
        "move it to backlog/ to be reconsidered (the safe default for a mis-parked file); only record a BLOCKED reason, or commit to sprint via bash docs/sprintmd/scripts/promote-to-sprint.sh <file> (never raw mv into next/)"
    fi
  fi
done

# ── Dependency cycles ────────────────────────────────────────────────
# A 3-colour DFS over Depends-on edges among open tasks. EXPLORED is the black
# set (nodes whose whole subtree has been walked with no new cycle), so each
# node is expanded exactly once — O(V+E), not the exponential re-traversal a
# path-only DFS suffers on diamond/fan-out graphs (an ordinary plan where two
# tasks share a prerequisite). The current path is the grey set: re-entering a
# grey node closes a cycle, whose members are the path slice FROM that node
# onward (the acyclic lead-in is excluded). Distinct cycles are deduped by their
# sorted member set and attributed to the lowest member id.
EXPLORED=""
CYCLE_SEEN=""
_record_cycle() {                        # $1 = space-separated member ids
  local members key lo
  # shellcheck disable=SC2086  # $1 is a space-separated id list; split is intended
  members="$(printf '%s\n' $1 | sort -un | tr '\n' ' ')"
  members="${members% }"
  key="$(printf '%s' "$members" | tr -d ' ')"
  case " $CYCLE_SEEN " in *" $key "*) return 0 ;; esac
  CYCLE_SEEN="$CYCLE_SEEN $key"
  lo="${members%% *}"
  add_finding 2 INTEGRITY "$lo" "$(file_of "$lo")" \
    "is part of a dependency cycle (tasks: $members)" \
    "break the loop — one of these tasks must not depend on the next"
}
_dfs_cycle() {
  local node="$1" path="$2" d df
  case " $EXPLORED " in *" $node "*) return 0 ;; esac   # black: subtree done
  case " $path " in
    *" $node "*)                                        # grey: cycle closed
      _record_cycle "$node ${path##* "$node"}"
      return 0 ;;
  esac
  df="$(file_of "$node")"
  if [ -n "$df" ] && is_open "$(stage_of "$node")"; then
    for d in $(id_list "$(field "$df" 'Depends on')"); do
      _dfs_cycle "$d" "$path $node"
    done
  fi
  EXPLORED="$EXPLORED $node"                            # blacken once explored
}
for id in $(board_ids); do
  _dfs_cycle "$id" ""
done

# ── Workable frontier ────────────────────────────────────────────────
# Mirror work.sh's real gate exactly (readiness + unmet-dep check) so the
# frontier this reports is what the executor will actually run — no second model
# of "runnable" to drift from the one that ships.
RUNNABLE=""
WAITING=""
for id in $(printf '%s\n' "$INDEX" | awk -F'\t' '$2=="next"{print $1}' | sort -n); do
  file="$(file_of "$id")"
  unmet="$(sprintmd_unmet_deps "$file")"
  if [ "$(sprintmd_review_verdict "$file")" != "READY" ]; then
    continue                                   # not runnable; already a finding
  elif [ -n "$unmet" ]; then
    WAITING="${WAITING}  - $id waits on: ${unmet}
"
  else
    RUNNABLE="$RUNNABLE $id"
  fi
done
RUNNABLE="${RUNNABLE# }"

# ── Sort + render findings ───────────────────────────────────────────
SORTED="$(printf '%s' "$FINDINGS" | grep -v '^$' \
  | sort -t"$(printf '\t')" -k1,1n -k3,3n || true)"
FINDING_COUNT=$(printf '%s' "$SORTED" | grep -c '^' || true)
[ -z "$SORTED" ] && FINDING_COUNT=0

# Human-readable, numbered, most-blocking first. Same text feeds the terminal
# summary and the conversational prompt, so what the user skims and what the AI
# walks can never disagree.
render_findings() {
  printf '%s\n' "$SORTED" | awk -F'\t' '
    NF >= 6 {
      n++
      printf "%d. [%s] Task %s: %s\n", n, $2, $3, $5
      printf "     fix:  %s\n", $6
      printf "     file: %s\n", $4
    }'
}

# ── Summary (≤3 lines) ───────────────────────────────────────────────
RUN_N=$(printf '%s' "$RUNNABLE" | wc -w | tr -d ' ')
WAIT_N=$(printf '%s' "$WAITING" | grep -c '^' || true)
[ -z "$WAITING" ] && WAIT_N=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Sprint: $NEXT_COUNT queued  ·  $RUN_N runnable now  ·  $WAIT_N waiting  ·  $FINDING_COUNT finding(s)"
if [ -n "$RUNNABLE" ]; then
  echo "  Frontier (what 'work' would run now): $RUNNABLE"
  # "runnable" mirrors the executor's gate (READY + deps met); a listed task can
  # still carry a finding below, so the two views are complementary, not at odds.
  [ "$FINDING_COUNT" -gt 0 ] && echo "  (some frontier tasks may still carry findings below — walk those first)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Zero findings: report and exit without spending a token ──────────
# A clean board needs no conversation — the whole point of the shell preflight
# is that AI runs only when there is something to discuss.
if [ "$FINDING_COUNT" -eq 0 ]; then
  echo "✓ No structural issues — dependency edges, stages, and markers are consistent."
  echo ""
  if [ -n "$WAITING" ]; then
    echo "Waiting on in-sprint prerequisites (frontier ordering will release these):"
    printf '%s' "$WAITING"
    echo ""
  fi
  echo "Start the sprint whenever you're ready:  ./sprint.sh work"
  exit 0
fi

echo "$FINDING_COUNT structural finding(s), most-blocking first:"
echo ""
render_findings
echo ""

# ── Conversational walkthrough ───────────────────────────────────────
# The findings are already computed; the AI's only job is to WALK them with the
# user, one at a time, and act on each within the task pipeline. Same rhythm and
# altitude as single-task chat.

_MODEL="$(sprintmd_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

FRONTIER_BLOCK="Runnable now: ${RUNNABLE:-none}"
[ -n "$WAITING" ] && FRONTIER_BLOCK="${FRONTIER_BLOCK}
Waiting on in-sprint prerequisites:
$(printf '%s' "$WAITING")"

FINDINGS_RENDERED="$(render_findings)"

# The next→blocked resolution logic (present two paths, demote inline for B,
# hand off to chat for A, keep the drop path behind an edge audit) is shared
# with the chat-next folder walk (task 226). It lives in lib.sh so both entry
# points walk the edge identically — do not inline a second copy here.
NEXT_BLOCKED_RESOLUTION="$(sprintmd_next_blocked_resolution)"

# Shared Conversation Method — stated once in ai/conversation.md, not restated below.
_METHOD="$(sprintmd_conversation_method)" || exit 1

APPEND_PROMPT="You are a senior engineer running a structural-health stand-up over a queued sprint — is it internally consistent and unblocked? NOT a planning critique of whether it is the right plan ('./sprint.sh plan think' owns that). A shell preflight already found every issue below; WALK them with the user and fix each, one at a time.

$_METHOD

SPRINT STATE
$NEXT_COUNT tasks queued in $NEXT_DIR/.
$FRONTIER_BLOCK

FINDINGS (already computed, most-blocking first — do not re-scan):
$FINDINGS_RENDERED

HOW TO OPEN
At most three lines: queued count, runnable frontier ids, finding count. Then walk findings — do not dump them all at once.

HOW TO WALK — one finding at a time, order listed (most-blocking first)
For EACH finding:
1. VERIFY against the named task file first. Preflight is conservative; if already resolved, say so in one line and move on. Never act on an unconfirmed finding.
2. STATE in one or two sentences what is wrong and why it matters for running the sprint.
3. RECOMMEND a specific fix (findings carry one) and OFFER TO ACT. Acting is only these, inside the task pipeline:
   - fix a metadata edge (Depends on / Blocks / Parent);
   - mis-parked blocked/ (no '**Status: BLOCKED**', no '## Questions'): DEFAULT move to backlog/ (git mv $BLOCKED_DIR/<file> docs/tasks/backlog/<file> || mv $BLOCKED_DIR/<file> docs/tasks/backlog/<file>); only stamp BLOCKED, or commit to sprint via bash docs/sprintmd/scripts/promote-to-sprint.sh <file> (gate: READY→next/; never raw mv into next/);
   - stamp or correct a '**Status:**' marker;
   - next→blocked BLOCKER: two-path choice under 'RESOLVING A next→blocked BLOCKER' below — do NOT drop Depends on to paper over it;
   - real definition work: CHAIN OUT to './sprint.sh chat <id>' in a fresh window — do not redefine inline.
4. MOVE ON — note what is settled, then the next finding.

OUTSTANDING QUESTIONS — write back, do not merely discuss
Surface as: Task <id> has an outstanding question: \"<question text>\". Let the user ANSWER, DECIDE, or give FEEDBACK; write it into the task file:
   - replace the open question with a resolved decision under '### Resolved decisions (<date>, by the developer)', and
   - when none remain, flip '**Status:**' to READY.
If it needs real definition work, chain './sprint.sh chat <id>' instead.

$NEXT_BLOCKED_RESOLUTION

RULES
- One finding at a time; wait between findings; no parroting.
- What and why, not how. No code snippets.
- WRITES: task files under docs/tasks/ and stage moves only. Always move with: git mv SRC DEST || mv SRC DEST. Read anything; write nothing else.
- Recap when done: fixed, chained to 'chat <id>', final frontier. Then stop."

# ── Emit vs exec: same interactivity contract as chat.sh ─────────────
# A live back-and-forth needs an interactive-capable provider on a real
# terminal. When exec mode can't offer one, degrade to a single pass and say so
# plainly rather than pretending a conversation happened. The same
# sprintmd_interactive_ok that routes the run decides the warning, so they agree.
if [ "$(sprintmd_ai_mode)" = "exec" ] && ! sprintmd_interactive_ok; then
  echo -e "${YELLOW}Note: a live walkthrough needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single pass over the findings instead. To wire up the full experience,${NC}"
  echo -e "${YELLOW}see docs/sprintmd/guides/use_chat.md${NC}"
  echo ""
fi

sprintmd_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "chat-sprint" \
  "Walk this sprint through: open with the ≤3-line summary, then take the findings one at a time, most-blocking first — verify each against its file, then fix it or chain into 'chat <id>'."
