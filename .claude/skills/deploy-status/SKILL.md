---
name: wa:deploy-status
version: "0.7.4"
description: "Multi-repo git status dashboard with branch health, PR status, and sync checks."
disable-model-invocation: false
---

# Deploy Status

Git status dashboard for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form        | Statusline    |
| ----- | ---------------- | ------------------ | ------------- |
| 1     | Stage 1: Scan    | Scanning repos     | Scan (1/3)    |
| 2     | Stage 2: Analyze | Analyzing health   | Analyze (2/3) |
| 3     | Stage 3: Report  | Building dashboard | Report (3/3)  |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Usage

```
/wa:deploy-status
/wa:deploy-status --all
```

Arguments are optional. By default, reports on the current repository. `--all` includes all repositories listed in project constants.

This skill is **read-only**. It does not modify any files or run any git write operations.

---

## Stage 1: Scan

### Inputs

- $ARGUMENTS for optional `--all` flag
- Multi-repo path list from `.claude/project-constants.md` (if `--all`)
- `git:status` primitive for each repository

### Activities

1. Determine repositories to inspect:
   - Always include the current repository.
   - If `--all` is in $ARGUMENTS or a multi-repo path list is defined in `.claude/project-constants.md` → include all listed repositories.

2. For each repository, use `git:status` to collect raw state:

   ```bash
   git -C {repo-path} status --porcelain=v2 --branch
   git -C {repo-path} stash list
   git -C {repo-path} log --oneline -1
   ```

3. Fetch remote state for each repository:

   ```bash
   git -C {repo-path} fetch --quiet origin
   git -C {repo-path} rev-list --left-right --count HEAD...@{upstream}
   ```

4. If a repository path is inaccessible, record the error and continue scanning the remaining repositories. Never abort the full scan for a single failure.

### Outputs

- Raw git state for each repository (branch, porcelain status, stash list, last commit)
- Remote state (ahead/behind counts)

### Exit Criteria

- All accessible repositories have been scanned
- Inaccessible repositories are recorded as errors

---

## Stage 2: Analyze

### Inputs

- Raw git state from Stage 1 for each repository
- Remote state (ahead/behind) from Stage 1
- PR data via `tracker:pr-list` (resolve backend via `tracker:router`, if available)

### Activities

For each repository, compute the following health indicators:

**Branch health:**

- Current branch name.
- Commits ahead of upstream (unpushed commits).
- Commits behind upstream (remote has new commits).
- Diverged flag: set when ahead > 0 AND behind > 0 simultaneously.
- Stale flag: set when the last commit on the branch is older than 7 days.

**Working tree state:**

- Staged but uncommitted changes (count).
- Modified tracked files (count).
- Untracked files (count).
- Stash count.

**PR status** (via `tracker:pr-list` from `tracker:router`):

- Open PRs for the current branch: title, base branch, draft status.
- CI check summary: PASSING, FAILING, or PENDING.
- Mergeable status: OK, CONFLICT, or UNKNOWN.

**Sync with default branches:**

- Commits on `dev` not in `main` (dev ahead).
- Commits on `main` not in `dev` (main ahead — indicates drift requiring merge).

### Outputs

- Health indicators per repository (branch health, working tree, PR status, sync state)
- Warning list (diverged, stale, conflicts, failing CI, etc.)

### Exit Criteria

- All health indicators are computed for every scanned repository

---

## Stage 3: Report

### Inputs

- Health indicators and warnings from Stage 2

### Activities

Display a structured dashboard. Include all sections even if empty.

```
## Weather App — Repository Status Dashboard
Fetched: {timestamp UTC}

### Repository Overview

| Repo | Branch | Last Commit | Age | Ahead | Behind | Staged | Modified | Untracked | Stash |
|------|--------|-------------|-----|-------|--------|--------|----------|-----------|-------|
| ...  | ...    | ...         | ... | ...   | ...    | ...    | ...      | ...       | ...   |

Show `--` for zero values. Truncate commit message at 50 characters.

### Dev-Main Sync

| Repo | Dev ahead of Main | Main ahead of Dev | Status |
|------|-------------------|-------------------|--------|

Status values: SYNCED | DRIFT | DIVERGED

### Open Pull Requests

| Repo | PR | Branch | Target | Review | CI | Mergeable | Age |
|------|----|--------|--------|--------|----|-----------|-----|

Show "No open PRs" if none exist.

### Branches

| Repo | Branch | Status |
|------|--------|--------|

Status values: active | tracking | local-only | stale (>7 days)
Skip `main` and `dev`. Show "Only dev + main" if no feature branches exist.

### Warnings

Numbered list of detected issues:
1. Main ahead of dev — must merge main into dev
2. Unpushed commits (ahead > 0)
3. Behind upstream (behind > 0)
4. Diverged branch (ahead AND behind > 0)
5. Stash entries present
6. PR targeting main instead of dev
7. PR with merge conflicts
8. PR with failing CI
9. Stale branch (no commits in 7+ days)

If none: "No warnings — all clear"

### Suggested Actions

Prioritized, actionable list based on warnings. Most critical first.
Be specific: include repo name, branch name, and counts.

If none: "No actions needed — repos are healthy"
```

### Outputs

- Formatted status dashboard displayed to user

### Exit Criteria

- Dashboard is displayed with all sections populated

---

## Error Handling

- **Repository inaccessible**: Mark it as `UNAVAILABLE` in the dashboard and continue with the remaining repositories.
- **Tracker backend unavailable**: Skip PR status columns. Note in the dashboard that the tracker backend is not available for PR data.
- **Remote fetch failure**: Use cached remote state and add a note that remote data may be stale.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
