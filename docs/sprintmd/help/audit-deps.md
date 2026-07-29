Audit dependency updates — file one backlog task listing what's outdated,
what's vulnerable, and how risky the upgrades are.

Usage:
  ./sprint.sh audit-deps

What it does:
  1. Detects the project's package ecosystem(s) by searching the whole tree
     for manifests — package.json, requirements.txt / pyproject.toml / Pipfile,
     Cargo.toml, go.mod, composer.json, Gemfile. Monorepos are first-class: a
     manifest in api/, app/, or packages/* is found and audited from its own
     directory, and every result is labelled with its path. Vendor/build trees
     (node_modules, vendor, .git, dist, build, target, .venv, …) are pruned, so
     it never audits your dependencies' dependencies.
  2. Runs each ecosystem's own native tooling (read-only) to gather:
       - outdated packages  (npm/pnpm/yarn outdated, pip list --outdated,
                              cargo outdated, go list -u -m all,
                              composer outdated, bundle outdated)
       - security advisories (npm/pnpm/yarn audit, pip-audit, cargo audit,
                              govulncheck, composer audit, bundler-audit)
     Any tool that isn't installed is recorded as skipped — never silently
     treated as "clean".
  3. Files ONE backlog task titled "Audit dependency updates" and fills it
     with three sections:
       - Outdated dependencies              (current → latest STABLE, + bump)
       - Security advisories                (CVE/GHSA, severity, fixed-in)
       - Upgrade impact & breaking-change risk
         (semver jump, where THIS codebase uses each dep, risk rating)

Why these terms:
  "audit" is the cross-ecosystem verb for this (npm audit, pip-audit, cargo
  audit, composer audit, bundle audit). "Advisories" is the standard name for
  vulnerability records (CVE/GHSA/OSV). "Breaking-change risk" frames impact
  in semver terms rather than guesswork.

Notes:
  - Universal by delegation: it does not reimplement version resolution — it
    calls each ecosystem's own tools, which already know the latest stable
    release and the current advisory database. No toolchain installed for an
    ecosystem = that ecosystem's blocks say "skipped".
  - Latest STABLE only: pre-release / beta versions are ignored.
  - Runs read-only. It never edits your manifests or lockfiles — it only
    files a task describing the work. Applying the updates is a separate,
    human-reviewed step.
  - Each new run files a fresh task. If an "Audit dependency updates" task is
    already open, close or update it rather than stacking duplicates.
  - Raw tool output is saved under docs/tmp/ and embedded in the task's
    "## Source data" section; the analysis step trims it once the three
    sections are written.

Config:
  MODEL_DEPS=               in docs/sprintmd/config sets the model (falls back to
                            MODEL_DEFAULT).
  FIVEDAY_DEPS_TIMEOUT      per-tool timeout in seconds (default 120).
  FIVEDAY_DEPS_MAX_PROJECTS cap on how many projects (manifest dirs) are
                            audited before the rest are skipped-with-notice
                            (default 25) — raise it for large monorepos.
  FIVEDAY_DEPS_PRUNE        space-separated dir names to exclude from the
                            search (defaults to the usual vendor/build trees).

Related:
  audit       — audits your task files for staleness (unrelated to packages).
  review-code — audits code changes for a task.
