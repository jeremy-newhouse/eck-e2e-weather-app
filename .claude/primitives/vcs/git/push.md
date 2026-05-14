---
name: vcs/git:push
description: Push current branch to remote
version: "0.4.0"
---

# Push

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| remote | string | No | Remote name (default: origin) |
| force | boolean | No | Force push using --force-with-lease (default: false) |

## Implementation

Push the current branch to the specified remote. When force is true, uses `--force-with-lease` to prevent overwriting remote changes made by others.

```bash
git push <remote> <branch>
# or with force:
git push --force-with-lease <remote> <branch>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| result | string | Confirmation of the refs pushed and remote state |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Remote has commits not in local branch | Pull and rebase or use force push (with caution) |
| 1 | `--force-with-lease` rejected — remote ref updated since last fetch | Fetch latest and review before retrying |
| 128 | Remote not found | Verify remote name with `git remote -v` |
| 128 | No upstream configured | Set upstream with `git push --set-upstream <remote> <branch>` |

## Used By

- dev-task (publishing branch after commit)
- git-flow (pushing branch to remote)
