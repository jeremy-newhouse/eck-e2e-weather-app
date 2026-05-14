---
name: vcs/git:worktree-add
description: Create a git worktree for isolated parallel work
version: "0.4.0"
---

# Worktree Add

Create a new git worktree with a dedicated branch for conflict-free parallel execution.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| worktree_path | string | Yes | Filesystem path for the new worktree |
| branch_name | string | Yes | Name of the new branch to create |
| base | string | No | Base ref to branch from (default: HEAD) |

## Implementation

Verify prerequisites, then create the worktree with a new branch based on the specified ref.

Pre-flight checks:

```bash
# Verify git version supports worktrees (2.5+)
git worktree list

# Verify base ref exists
git rev-parse --verify <base>

# Verify branch name is available
git rev-parse --verify <branch_name> 2>/dev/null && echo "ERROR: branch exists"
```

Create the worktree:

```bash
git worktree add -b <branch_name> <worktree_path> <base>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| worktree_path | string | Filesystem path of the created worktree |
| branch_name | string | Name of the branch checked out in the worktree |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Branch name already exists | Choose a unique branch name or delete the existing branch |
| 128 | Base ref not found | Verify the commit SHA or branch name and fetch if needed |
| 128 | Path already exists | Choose a different worktree path or remove the existing directory |
| 1 | Git version does not support worktrees | Upgrade to git 2.5 or later |

## Used By

- orchestrate (spawning isolated parallel work contexts)
