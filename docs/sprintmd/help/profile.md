AI-guided project profile generator.

Auto-detects the project's stack from files and manifests, confirms
with the user, and writes a flat profile to docs/sprintmd/project.md.
All AI-powered commands include that profile in their context so
tasks inherit project-specific conventions automatically.

On update, re-scans the project, diffs against the existing profile,
and surfaces detected drift (new frameworks, test configs, etc.)
instead of only asking what changed.

Usage:
  ./sprint.sh profile           # create or update project profile (interactive)
  ./sprint.sh profile show      # print current profile (no AI)
  ./sprint.sh -g profile        # Grok Build for this run (leading -c = Claude)

profile show cats docs/sprintmd/project.md, or prints a short "no
profile yet" message with the create command. No AI session is started.

After running profile (create/update):
  - docs/sprintmd/project.md exists with project conventions
  - chat, gate, plan, and work pick it up automatically
