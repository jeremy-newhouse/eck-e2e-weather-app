---
name: vcs/git:rebase
description: Rebase current branch onto target
version: "0.4.0"
---

# Rebase

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Target branch or commit to rebase onto |

## Implementation

Reapply commits from the current branch on top of the target ref, producing a linear history.

```bash
git rebase <target>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| result | string | Confirmation of commits replayed onto the target |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Rebase conflict | Resolve conflicts, then `git rebase --continue`; abort with `git rebase --abort` |
| 128 | Target ref not found | Verify the branch or commit exists and fetch if needed |
| 1 | Dirty working tree | Commit or stash changes before rebasing |

## Used By

- git-flow (rebasing feature branch onto updated base)
