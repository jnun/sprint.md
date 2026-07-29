# Label-to-Project Status Sync

Automatically update your GitHub Project board when labels are applied to issues.

## What This Does

Your task folders are the single source of truth:

```
docs/tasks/backlog/   →  "backlog" label  →  "backlog" project status
docs/tasks/next/      →  "next" label     →  "next" project status
docs/tasks/doing/   →  "doing" label  →  "doing" project status
docs/tasks/blocked/   →  "blocked" label  →  "blocked" project status
docs/tasks/review/    →  "review" label   →  "review" project status
docs/tasks/done/      →  "done" label     →  "done" project status
```

No hardcoded mapping. Add `docs/tasks/qa/` and `qa` becomes a valid label and project status automatically.

## How It Works

1. You (or the task sync workflow) apply a label to a GitHub issue
2. GitHub Actions fires `sync-status-to-label.yml` automatically
3. The workflow reads your `docs/tasks/` folder names to discover valid statuses
4. If the label matches a folder name, it updates the issue's project board status
5. If the status option doesn't exist on the board yet, it creates one
6. Conflicting status labels are removed (only one status at a time)

**No webhook setup required.** GitHub Actions responds to label events natively — there is nothing to configure on the GitHub website beyond the items below.

## Prerequisites

You need a GitHub Project board. If you already set one up for task sync, you're most of the way there. If not, see [GITHUB-PROJECTS-SETUP.md](../GITHUB-PROJECTS-SETUP.md) for the full walkthrough.

## Setup

### 1. Create a GitHub Project (if you don't have one)

```bash
gh project create --owner @me --title "MyProject Task Board"
```

Note the project number from the output URL (e.g., `https://github.com/users/you/projects/3` → number is `3`).

### 2. Create a Personal Access Token (PAT)

1. Go to: https://github.com/settings/tokens?type=beta
2. Click **Generate new token** (fine-grained)
3. Configure:
   - **Token name**: `sprint.md-project-automation`
   - **Expiration**: Your preference
   - **Repository access**: Select your repo
   - **Permissions**:
     - Repository → Issues: **Read and write**
     - Account → Projects: **Read and write**
4. Click **Generate token** and copy it

### 3. Add the secret and variable to your repository

Go to your repo → **Settings** → **Secrets and variables** → **Actions**:

**Secret** (Secrets tab → New repository secret):
- Name: `GH_PROJECT_TOKEN`
- Value: the PAT you just created

**Variable** (Variables tab → New repository variable):
- Name: `PROJECT_NUMBER`
- Value: your project number (e.g., `3`)

### 4. Verify

Apply a `backlog` label to any issue in your repository. Go to **Actions** and confirm the "Sync Labels to Project Status" workflow runs. Check your project board — the issue should appear in the correct column.

## Adding Custom Statuses

Just create a folder:

```bash
mkdir docs/tasks/qa
```

Push to main. The next time a `qa` label is applied to an issue, the workflow will:
1. See that `qa` matches the `docs/tasks/qa/` folder
2. Create a `qa` status option on the project board (if it doesn't exist)
3. Set the issue's status to `qa`

## How This Relates to Task Sync

Two workflows, two responsibilities:

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `sync-tasks-to-issues.yml` | File push to `docs/tasks/` | Creates/updates issues, applies labels |
| `sync-status-to-label.yml` | Label applied to issue | Updates project board status |

They complement each other. The task sync creates issues and labels them. This workflow picks up those labels (or any manually applied labels) and keeps the project board in sync.

## Troubleshooting

### Workflow doesn't run
- Confirm `sync-status-to-label.yml` exists in `.github/workflows/`
- The workflow only triggers on label events — it won't run on push

### "Project not found"
- Verify `PROJECT_NUMBER` is set correctly in repository variables
- Verify the PAT owner has access to the project

### "Status field not found"
- Your project needs a field called **Status** (type: single select)
- New GitHub Projects create this by default, but check Settings → Custom fields

### "Could not create status option"
- The PAT may lack `project` scope — regenerate with Account → Projects: Read and write
- Organization projects may require admin-level access for field modifications

### Labels not being cleaned up
- The workflow removes conflicting status labels using `GITHUB_TOKEN`
- `GITHUB_TOKEN` label changes do NOT re-trigger this workflow (GitHub's built-in infinite-loop prevention)
