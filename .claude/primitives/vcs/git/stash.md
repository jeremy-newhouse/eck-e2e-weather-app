---
name: vcs/git:stash
description: Stash or restore working changes
version: "0.4.0"
---

# Stash

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| action | enum | Yes | Stash action: `push`, `pop`, or `list` |

## Implementation

Save, restore, or list stashed working tree changes.

```bash
git stash <action>
```

- `push` — saves current working tree changes to the stash stack
- `pop` — restores the most recent stash and removes it from the stack
- `list` — displays all stash entries

## Output

| Field | Type | Description |
|-------|------|-------------|
| stash_ref | string | Stash reference created (push only, e.g. `stash@{0}`) |
| stash_list | string | Formatted list of stash entries (list only) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 1 | No local changes to stash (push) | Verify the working tree has modifications before stashing |
| 1 | No stash entries exist (pop) | Check stash list before attempting to pop |
| 1 | Stash pop conflict with current working tree | Resolve conflicts manually after pop |

## Used By

- git-flow (stashing before branch operations)
