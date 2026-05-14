---
name: vcs/git:pull
description: Pull latest changes from remote
version: "0.4.0"
---

# Pull

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| remote | string | No | Remote name (default: origin) |
| branch | string | No | Branch name (default: current branch) |

## Implementation

Fetch and integrate the latest changes from the specified remote branch.

```bash
git pull <remote> <branch>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| result | string | Summary of commits pulled and files updated |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Merge conflict during pull | Resolve conflicts manually, then commit |
| 128 | Remote not found | Verify remote name with `git remote -v` |
| 128 | Branch not found on remote | Verify branch name exists on the remote |
| 1 | Dirty working tree prevents pull | Commit or stash changes before pulling |

## Used By

- git-flow (syncing with remote before branching)
- dev-task (pulling latest before starting work)
