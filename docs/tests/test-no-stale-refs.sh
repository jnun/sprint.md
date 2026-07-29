#!/usr/bin/env bash
# Test: no stale legacy references after the sprint.md rename.
#
# Guards the class of bug that slipped through the docs/5day -> docs/sprint ->
# docs/sprintmd rename: a reference in a form the search didn't anticipate
# (e.g. a relative "../sprint/scripts" that a "docs/sprint"-anchored sweep
# skipped). Any future rename that misses a spot fails here instead of at
# runtime in a user's install.
#
# Scope: functional + distributable surfaces only. The file list comes from git
# (tracked + untracked-but-not-ignored), which excludes .git, the sprint.md
# submodule's internals, and gitignored paths (docs/tmp) for free. We further
# drop the src/ mirror (ship.sh regenerates it from docs/sprintmd and verifies
# it) and dev-internal work-item narratives (tasks/ideas/features/bugs) that
# legitimately discuss project history.
#
# Written for bash 3.2 (macOS default): indexed arrays only, no mapfile.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
PASS=0
FAIL=0

# Build the policed file list once, from git.
FILES=()
while IFS= read -r f; do
    [ -f "$f" ] && FILES+=("$f")
done < <(
    { git ls-files; git ls-files --others --exclude-standard; } 2>/dev/null \
        | grep -E '\.(sh|md|yml|template)$|(^|/)config$' \
        | grep -vE '^(src/|docs/(tasks|ideas|features|bugs)/)' \
        | sort -u
)

# check [-i] <regex> <label> — fail if any policed file (other than this test)
# matches. A leading -i makes the match case-insensitive (for prose patterns
# whose capitalization varies).
check() {
    local ci=""
    if [ "$1" = "-i" ]; then ci="-i"; shift; fi
    local re="$1" label="$2" hits
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "  FAIL: $label (no files to scan — not a git repo?)"
        FAIL=$((FAIL + 1))
        return
    fi
    # Exclude the two rename-tooling files that legitimately CONTAIN the legacy
    # names as tripwire patterns / documentation rather than as real references:
    # this test itself, and ship.sh (whose LEGACY_RE gate scans for them).
    hits=$(grep $ci -InE "$re" "${FILES[@]}" 2>/dev/null \
        | grep -vE '(^|/)(ship|test-no-stale-refs)\.sh:')
    if [ -n "$hits" ]; then
        echo "  FAIL: $label"
        echo "$hits" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    fi
}

echo "=== test-no-stale-refs.sh ==="

# Legacy framework directory (any path form).
check 'docs/5day' "no docs/5day path references"

# Legacy launcher name.
check '5day\.sh' "no 5day.sh launcher references"

# Interim framework dir docs/sprint/ that is NOT the final docs/sprintmd/.
# 'docs/sprintmd' has 'm' after 'sprint'; 'docs/sprint/' has '/'. The [^m]
# excludes sprintmd while catching docs/sprint/, docs/sprint at EOL, etc.
check 'docs/sprint([^m]|$)' "no non-sprintmd docs/sprint path references"

# Relative / bare framework-subdir refs like ../sprint/scripts that a
# 'docs/sprint'-anchored replace would miss. [^m] before 'sprint' skips sprintmd.
check '(^|[^m])sprint/(scripts|ai|help|cli|guides|lib|config|DOC_STATE|theory)' \
    "no bare/relative sprint/ framework references"

# The framework dir shown bare in a path/tree context: "sprint/" followed by
# whitespace or end-of-line (e.g. a directory-tree diagram "└── sprint/"). The
# trailing [[:space:]]|$ requirement avoids matching the workflow-noun prose
# "sprint/backlog" (a 'b' follows the slash, not whitespace).
check '(^|[^m])sprint/([[:space:]]|$)' \
    "no bare sprint/ framework-dir references (tree diagrams)"

# Old brand prose. FIVEDAY_ env vars are intentionally retained and are not a
# brand string, so they are not matched here.
check '5DayDocs|Five Day Docs|5 Day Docs' "no legacy brand prose"

# ── Epic 212 stale patterns (docs/guides + docs/tests audit) ─────────
# These guard the specific rot this epic hunted down, so it can never silently
# return. Each is prophylactic: the tree is clean today, and this list keeps it
# clean on every future edit.

# A build/mirror script that never existed. Two guides were deleted for citing
# it; nothing should mention it again. The real mirror tool is ship.sh.
check 'build-distribution\.sh' "no build-distribution.sh references"

# 'setup.sh .' written as if it SYNCS docs/ into src/. setup.sh is the installer
# (it installs INTO a target project); the mirror step is ship.sh. Matching
# 'setup.sh' followed by a literal '.' argument catches the miswritten sync.
check 'setup\.sh[[:space:]]+\.' "no 'setup.sh .' sync claims"

# A root-level /VERSION. Versioning lives at src/VERSION (bumped by ship.sh);
# there is no repo-root VERSION file. Anchor to a path-like '/VERSION' or a
# leading 'VERSION' so ordinary prose ("the VERSION was bumped") is not matched.
check '(^|[^A-Za-z])/VERSION([^A-Za-z]|$)' "no root /VERSION claims"

# Reversed source-of-truth model. docs/ is authored and src/ is the generated
# mirror; any text claiming the reverse ("src/ is source of truth", "edit in
# src") teaches the exact inversion that corrupts the ship workflow.
check -i 'src/ is (the )?source of truth|edit in src' \
    "no reversed src/-is-source-of-truth phrasing"

# Distribution AI-pointer files ship to users but are gitignored, so they are
# absent from the git-based FILES list above. A stale brand here reaches every
# install, so scan them by explicit path. (This blind spot shipped a "5DayDocs"
# reference in src/CLAUDE.md, src/.cursorrules and src/.windsurfrules once.)
pointer_hits=""
for pf in src/CLAUDE.md src/AGENTS.md src/GEMINI.md src/.cursorrules \
          src/.windsurfrules src/.github/copilot-instructions.md; do
    [ -f "$pf" ] || continue
    m=$(grep -InE '5DayDocs|Five Day Docs|docs/5day|5day\.sh' "$pf" 2>/dev/null)
    [ -n "$m" ] && pointer_hits="${pointer_hits}${pf}: ${m}
"
done
if [ -n "$pointer_hits" ]; then
    echo "  FAIL: shipped AI-pointer files free of legacy refs"
    printf '%s' "$pointer_hits" | sed 's/^/        /'
    FAIL=$((FAIL + 1))
else
    echo "  PASS: shipped AI-pointer files free of legacy refs"
    PASS=$((PASS + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
