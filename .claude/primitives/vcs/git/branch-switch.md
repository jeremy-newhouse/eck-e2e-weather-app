---
name: vcs/git:branch-switch
description: Switch to an existing branch
version: "0.4.0"
---

# Branch Switch

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| branch_name | string | Yes | Name of the branch to switch to |

## Implementation

Check out the named branch; the working tree must be clean before switching.

```bash
git checkout <branch_name>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| branch | string | Name of the branch now active in the working tree |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Branch does not exist | Verify branch name with `git branch -a` |
| 1 | Dirty working tree prevents switch | Commit or stash changes before switching |

## Used By

- git-flow (branch switching step)
