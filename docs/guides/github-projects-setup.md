# GitHub Projects Kanban Board Setup

This guide shows you how to set up the automated GitHub Projects kanban board for sprint.md task management.

## What This Does

Automatically syncs your task files to a visual kanban board that non-technical partners can view:

- **Move a file between folders** → Issue updates → Kanban board updates
- **No manual updating** required
- **Share with partners** via GitHub Projects URL

## Prerequisites & Setup

This feature requires the GitHub CLI tool and proper authentication. Follow these steps in order:

### Step 1: Install GitHub CLI

**macOS (Homebrew):**
```bash
brew install gh
```

**Linux (apt/deb):**
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Windows (winget):**
```bash
winget install --id GitHub.cli
```

**Other platforms:** See [https://cli.github.com/manual/installation](https://cli.github.com/manual/installation)

### Step 2: Authenticate with GitHub

Run this command:
```bash
gh auth login
```

Follow the prompts:
- Choose "GitHub.com"
- Choose "HTTPS" or "SSH" (either works)
- Choose "Login with a web browser"
- Copy the one-time code shown
- Press Enter to open your browser and paste the code

### Step 3: Add Project Permissions

**IMPORTANT:** The default authentication doesn't include permissions for GitHub Projects. You must add them:

```bash
gh auth refresh -s project,read:project
```

This will:
- Open your browser again
- Ask you to authorize additional permissions
- Grant access to create and manage GitHub Projects

**If you skip this step**, you'll get an error: `your authentication token is missing required scopes`

## Status Columns

The board columns come straight from your task folders under `docs/tasks/` — **the folder name is the column name, verbatim.** Out of the box that's 6 statuses:

1. **`backlog`** — Tasks defined but not yet scheduled
2. **`next`** — Tasks queued for the current sprint
3. **`doing`** — Tasks actively being worked on
4. **`blocked`** — Tasks that can't proceed given the current state
5. **`review`** — Tasks in testing and review
6. **`done`** — Completed tasks (their issues are closed)

Because the folders drive everything, adding a new folder (e.g. `docs/tasks/qa/`) automatically becomes a new `qa` status — you don't edit the workflows or this list. The column labels match the lowercase folder names exactly; that's what lets a brand-new folder create its own column with no code change.

## Create and Configure the Project Board

**Before proceeding:** Make sure you've completed Steps 1-3 above (Install, Authenticate, Add Permissions).

### Step 4: Create the Project

Run this command in your terminal (replace `YourProject` with your actual project name):

```bash
gh project create --owner @me --title "YourProject Task Board"
```

For example, if your repo is called "myapp", use:
```bash
gh project create --owner @me --title "myapp Task Board"
```

This will output something like:
```
https://github.com/users/YourUsername/projects/1
```

The number at the end (`1` in this example) is your **PROJECT_NUMBER**.

### Step 5: Find Your Project Number (if needed)

If you need to find it again:

```bash
gh project list --owner @me
```

Look for your project name (e.g., "myapp Task Board") and note the number.

### Step 6: Create a Personal Access Token (PAT)

GitHub Actions workflows need a Personal Access Token to interact with GitHub Projects v2.

1. Go to: https://github.com/settings/tokens?type=beta
2. Click **"Generate new token"** → **"Generate new token (fine-grained)"**
3. Configure the token:
   - **Token name**: `sprint.md-project-automation`
   - **Expiration**: Choose your preference (90 days, 1 year, or custom)
   - **Repository access**: Select "Only select repositories" → Choose your repo (e.g., `sprint.md`)
   - **Permissions**:
     - **Repository permissions**:
       - Issues: Read and write
       - Metadata: Read-only (auto-selected)
     - **Account permissions**:
       - Projects: Read and write ← **CRITICAL**
4. Click **"Generate token"**
5. **COPY THE TOKEN** - you won't see it again!

### Step 7: Add Tokens to GitHub Repository

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)

**Add the PAT as a Secret:**
1. Click the **Secrets** tab
2. Click **"New repository secret"**
3. Enter:
   - **Name**: `GH_PROJECT_TOKEN`
   - **Value**: Paste the token you just created
4. Click **"Add secret"**

**Add the Project Number as a Variable:**
1. Click the **Variables** tab
2. Click **"New repository variable"**
3. Enter:
   - **Name**: `PROJECT_NUMBER`
   - **Value**: Your project number (e.g., `3`)
4. Click **"Add variable"**

### Step 8: Confirm the Status Field Exists

The workflows create the status options for you — each option is auto-created from a task folder name the first time a task lands in that folder, so you normally don't add them by hand. You just need the **Status** field itself to exist (new projects have it by default).

To confirm:

1. Go to your project: `https://github.com/users/YourUsername/projects/<PROJECT_NUMBER>`
2. Click the **⋯** (three dots) in the top right
3. Click **Settings**
4. In the left sidebar, click **Custom fields**
5. Verify a single-select field named **Status** exists (if it doesn't, create one — the workflow reports an error if it's missing)

If auto-creation of an option fails (the workflow logs a warning), add it manually here using the exact folder name — `backlog`, `next`, `doing`, `blocked`, `review`, `done`.

### Step 9: Test the Setup

1. Move a task file between folders (e.g., from `backlog` to `next`)
2. Commit and push:
   ```bash
   git add docs/tasks/
   git commit -m "Test: Move task to next folder"
   git push
   ```
3. Go to **Actions** tab in GitHub and watch the workflow run
4. Check your project board - the task should appear in the correct column

## Verification

✅ **Success looks like:**
- Workflow runs without errors
- Issues appear in your project
- Issues are in the correct status column
- Moving files between folders updates the board

## Troubleshooting

### "please run: gh auth login"
- You haven't authenticated with GitHub CLI yet
- Run `gh auth login` and follow the prompts
- See Step 2 above for detailed instructions

### "your authentication token is missing required scopes [project read:project]"
- Your authentication doesn't have permission to manage GitHub Projects
- Run: `gh auth refresh -s project,read:project`
- This will open your browser to authorize the additional permissions
- See Step 3 above for details

### "Could not find project item"
- The item was just added and needs time to sync (usually ~1 second)
- This is a harmless warning on first run

### "Status field may need to be created"
- Complete Step 8 above to confirm a single-select **Status** field exists
- Options are auto-created from folder names; if you add one manually, match a folder exactly: `backlog`, `next`, `doing`, `blocked`, `review`, `done`

### "WARNING: GH_PROJECT_TOKEN secret not set"
- You haven't created or added the Personal Access Token yet
- Complete Step 6 & 7 above to create and add the PAT
- The workflow cannot add issues to projects without this token

### Workflow doesn't run
- Check that `PROJECT_NUMBER` is set in repository variables
- Verify the workflow has permissions (Settings → Actions → General → Workflow permissions)
- Ensure changes are pushed to the `main` branch

### Project not found
- Verify the PROJECT_NUMBER is correct
- Ensure the project is owned by you (`@me`) or your organization

## Sharing the Board

Once set up, share your board with partners:

1. Go to your project URL
2. Click **⋯** → **Settings**
3. Under **Visibility**, choose:
   - **Private** - Only collaborators can see
   - **Public** - Anyone with the link can view (read-only for non-collaborators)
4. Share the project URL with your partners

## Label-to-Status Sync

A second workflow (`sync-status-to-label.yml`) keeps your project board in sync when labels are applied to issues — whether by the task sync or manually. It uses your folder names as the source of truth, so adding a new folder automatically creates a new status option.

See [Label-to-Project Status Sync Guide](github-label-project-sync.md) for details.

## Automation Summary

The workflows automatically:
1. Creates/updates GitHub Issues from task files
2. Adds issues to your project board
3. Sets the status column based on folder location
4. Updates labels to match status
5. Closes issues when tasks move to "done"
6. Syncs project board status when labels are applied

**You just move files. Everything else is automatic.**
