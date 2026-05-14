---
name: vcs/git:branch-create
description: Create and checkout a new branch
version: "0.4.0"
---

# Branch Create

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| branch_name | string | Yes | Name of the new branch |
| base | string | No | Base branch to create from (default: dev) |

## Implementation

Fetch the base branch, pull latest, then create and checkout the new branch.

```bash
git checkout <base>
git pull
git checkout -b <branch_name>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| branch | string | Name of the newly created and checked-out branch |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Branch name already exists | Choose a unique branch name or delete the existing branch |
| 128 | Base branch not found locally or remotely | Verify base branch name and run `git fetch` |
| 1 | Dirty working tree prevents checkout | Commit or stash changes before creating a branch |

## Used By

- dev-task (new feature or fix branch creation)
- git-flow (branch management step)
