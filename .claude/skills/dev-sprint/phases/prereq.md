---
version: "0.6.5"
disable-model-invocation: false
---

# Stage 2: Tool Health Check (BLOCKING)

**CRITICAL**: Verify all required tools are operational before proceeding.

## Step 2.1: Verify Tracker Connectivity

Read `GitHub` from `.claude/project-constants.md` and resolve the backend via `tracker:router`.

**If official MCP backend (JIRA, Confluence, Linear):**

- Run `core/ops:mcp-preflight` to validate MCP connectivity

**If gh-cli (GitHub Issues):**

- Verify `gh auth status` exits with code 0

**If local:**

- Skip connectivity check (local tracker always available)

**If error or no response:**

```markdown
## Tracker Unavailable - SPRINT STOPPED

Cannot execute sprint without tracker access. Tracker is required for:

- Reading task details
- Updating task status
- Persisting sprint state
- Starting/completing sprints

### Recovery Steps

1. Check tracker configuration in `.claude/project-constants.md`
2. If MCP backend: Run `/mcp` and check tracker server status
3. If gh-cli: Run `gh auth login` and complete authentication
4. Re-run: `/dev-sprint $ARGUMENTS`

**STOP - Do not proceed until tracker is working.**
```

## Step 2.2: Verify Git CLI

```bash
git --version
```

**If exit code non-zero:**

```markdown
## Git Unavailable - SPRINT STOPPED

Cannot execute sprint without Git access.

### Recovery Steps

1. Verify git is installed: `which git`
2. Verify git config exists
3. Re-run: `/dev-sprint $ARGUMENTS`

**STOP - Do not proceed until Git is working.**
```

## Step 2.3: Verify GitHub CLI

```bash
gh auth status
```

**If exit code non-zero:**

```markdown
## GitHub CLI Unavailable - SPRINT STOPPED

Cannot execute sprint without GitHub CLI for PR operations.

### Recovery Steps

1. Verify gh is installed: `which gh`
2. Run `gh auth login` and complete authentication
3. Re-run: `/dev-sprint $ARGUMENTS`

**STOP - Do not proceed until gh CLI is authenticated.**
```

## Step 2.4: Tool Health Summary

After all checks pass, output:

```markdown
## Tool Health Check - PASSED

- Tracker MCP: OK Connected
- Git CLI: OK Available
- GitHub CLI: OK Authenticated

Proceeding to Stage 3...
```

---

# Stage 3: PR Status Check (BLOCKING)

**CRITICAL**: Before starting any sprint, verify no open PRs block execution.

**Do NOT proceed if:**

- Any open sprint PRs for this Epic exist (sprint -> feature)
- Any open feature PRs for this Epic exist (feature -> dev)
- Previous sprint branches have unmerged changes

## Step 3.1: Check for Open PRs

```bash
# Check each repository that may have open PRs
# Repos defined in project-constants.md under Repository Paths
# Resolve via tracker:router → tracker:pr-list
for REPO_PATH in {DOCS_PATH} public/ {BACKEND_PATH}; do
  cd "$REPO_PATH"
  tracker:pr-list --state open --json number,title,headRefName,baseRefName
done
```

**Note:** Look for PRs with:

- `headRefName` starting with `sprint/{epic-key}` (sprint PRs for this Epic)
- `headRefName` starting with `feature/{epic-key}` (feature PR for this Epic)

## Step 3.2: If Open PRs Found - STOP

If any open PRs are detected, display and STOP:

```markdown
## Open Pull Requests Detected

Cannot start sprint with unmerged PRs.

### {Repo Name}

| PR # | Title | Branch |
| ---- | ----- | ------ |
| #N   | ...   | ...    |

**Action Required:**

- Review and merge pending PRs
- Or close PRs if no longer needed
```

After merging, re-run: `/dev-sprint $ARGUMENTS`

**STOP - Do not proceed until PRs are merged.**

## Step 3.3: Verify Dev Branch is Clean

```bash
# For each repository
for REPO_PATH in {DOCS_PATH} public/ {BACKEND_PATH}; do
  cd "$REPO_PATH"
  git fetch origin
  git checkout dev
  git pull origin dev
  git status  # Should show "nothing to commit, working tree clean"
done
```

If uncommitted changes exist, ask user to resolve before proceeding.

## Step 3.4: Proceed to Sprint Identification

Only if:

- No blocking open PRs for this Epic (sprint or feature PRs)
- Dev branches are up to date in all repos
- No uncommitted changes
