Scan dependency updates — file one backlog task listing what's outdated,
what's vulnerable, and how risky the upgrades are (keep family).

Usage:
  ./sprint.sh deps

What it does:
  1. Detects the project's package ecosystem(s) by searching the whole tree
     for manifests — package.json, requirements.txt / pyproject.toml / Pipfile,
     Cargo.toml, go.mod, composer.json, Gemfile. Monorepos are first-class: a
     manifest in api/, app/, or packages/* is found and scanned from its own
     directory, and every result is labelled with its path. Vendor/build trees
     (node_modules, vendor, .git, dist, build, target, .venv, …) are pruned, so
     it never scans your dependencies' dependencies.
  2. Runs each ecosystem's own native tooling (read-only) to gather:
       - outdated packages  (npm/pnpm/yarn outdated, pip list --outdated,
                              cargo outdated, go list -u -m all,
                              composer outdated, bundle outdated)
       - security advisories (npm/pnpm/yarn audit, pip-audit, cargo audit,
                              govulncheck, composer audit, bundler-audit)
     Any tool that isn't installed is recorded as skipped — never silently
     treated as "clean".
  3. Files ONE backlog task and fills it with three sections:
       - Outdated dependencies              (current → latest STABLE, + bump)
       - Security advisories                (CVE/GHSA, severity, fixed-in)
       - Upgrade impact & breaking-change risk
         (semver jump, where THIS codebase uses each dep, risk rating)

Notes:
  - Universal by delegation: it does not reimplement version resolution — it
    calls each ecosystem's own tools. Ecosystem "audit" CLIs (npm audit, …)
    stay as internal tool names; the sprint.md command is `deps`.
  - No toolchain installed for an ecosystem = that ecosystem's blocks say
    "skipped".
