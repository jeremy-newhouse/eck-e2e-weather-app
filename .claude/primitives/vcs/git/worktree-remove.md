---
name: vcs/git:worktree-remove
description: Remove a git worktree and clean up its branch
version: "0.4.0"
---

# Worktree Remove

Remove a git worktree and optionally delete its associated branch.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| worktree_path | string | Yes | Filesystem path of the worktree to remove |

## Implementation

Check for uncommitted changes, then remove the worktree and perform a safe branch delete.

Safety check:

```bash
# Verify no uncommitted changes in the worktree
git -C <worktree_path> status --porcelain
```

If uncommitted changes exist, stop and report:

```
ERROR: Worktree at <worktree_path> has uncommitted changes.
Commit or stash changes before removing.
```

Remove the worktree:

```bash
# Get the branch name before removing
BRANCH=$(git -C <worktree_path> branch --show-current)

# Remove the worktree
git worktree remove <worktree_path>

# Delete the branch (safe delete — fails if unmerged)
git branch -d "$BRANCH"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| result | string | Confirmation that the worktree directory was removed |
| branch_status | string | Whether the associated branch was deleted or retained (unmerged) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Worktree has uncommitted changes | Commit or stash changes inside the worktree before removing |
| 1 | Branch has unmerged changes — safe delete refused | Merge or manually review; use `git branch -D` only after confirming changes are safe to discard |
| 128 | Worktree path not found | Verify the path with `git worktree list` |

## Used By

- orchestrate (cleaning up after parallel work completes)
