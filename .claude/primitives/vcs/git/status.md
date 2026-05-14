---
name: vcs/git:status
description: Check working tree status
version: "0.4.0"
---

# Status

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| none | — | — | This primitive takes no parameters |

## Implementation

Display the state of the working tree and index, showing staged, unstaged, and untracked changes.

```bash
git status
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| status_output | string | Working tree status listing staged, unstaged, and untracked files |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Not inside a git repository | Run from within a git-initialized directory |

## Used By

- dev-task (verifying clean state before committing)
- git-flow (checking state before branch operations)
- design-risk (checking repository cleanliness as a risk signal)
