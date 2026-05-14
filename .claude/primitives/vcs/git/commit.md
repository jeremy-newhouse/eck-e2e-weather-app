---
name: vcs/git:commit
description: Create a git commit with message
version: "0.4.0"
---

# Commit

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| message | string | Yes | Commit message text |
| files | list | No | Files to stage (default: all changed files) |

## Implementation

Stage the specified files (or all changes if none specified) then create the commit.

```bash
git add <files>
git commit -m "<message>"
```

If no files are specified, uses `git add -A` to stage all changes.

## Output

| Field | Type | Description |
|-------|------|-------------|
| commit_sha | string | SHA of the newly created commit |
| message | string | Commit message as recorded |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | Nothing to commit (working tree clean) | Verify files were modified before committing |
| 1 | File path not found | Check specified file paths exist in the working tree |
| 128 | Not inside a git repository | Run from within a git-initialized directory |

## Used By

- dev-task (committing implementation work)
- git-flow (commit step in workflow)
