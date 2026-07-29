AI-guided project profile generator.

Auto-detects the project's stack from files and manifests, confirms
with the user, and writes a flat profile to docs/sprintmd/project.md.
All AI-powered commands include that profile in their context so
tasks inherit project-specific conventions automatically.

Usage:
  ./sprint.sh profile           # create or update project profile

After running:
  - docs/sprintmd/project.md exists with project conventions
  - talk, define, plan, and tasks pick it up automatically
