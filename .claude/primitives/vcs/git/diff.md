---
name: vcs/git:diff
description: Show changes between commits or working tree
version: "0.4.0"
---

# Diff

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | No | Commit, branch, or tag to compare against |
| staged | boolean | No | Show staged changes only (default: false) |

## Implementation

Display the diff between the working tree (or index) and the specified target.

```bash
git diff [--staged] [<target>]
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| diff_output | string | Unified diff text showing added and removed lines |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Target ref not found | Verify the commit SHA, branch, or tag exists |
| 128 | Not inside a git repository | Run from within a git-initialized directory |

## Used By

- validate-code (reviewing changes before approval)
- dev-task (inspecting work-in-progress changes)
