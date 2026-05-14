---
name: vcs/git:merge
description: Merge a branch into current branch
version: "0.4.0"
---

# Merge

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| branch_name | string | Yes | Name of the branch to merge |
| no_ff | boolean | No | Use --no-ff flag to preserve merge commit (default: true) |

## Implementation

Merge the specified branch into the current branch, preserving a merge commit by default.

```bash
git merge [--no-ff] <branch_name>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| merge_commit | string | SHA of the merge commit created (when --no-ff used) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Merge conflict | Resolve conflicts manually, then `git merge --continue` |
| 128 | Branch not found | Verify the branch name exists locally or fetch from remote |
| 1 | Already up to date | No action needed; branches share the same history |

## Used By

- git-flow (merging feature branches)
