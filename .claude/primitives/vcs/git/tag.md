---
name: vcs/git:tag
description: Create a git tag
version: "0.4.0"
---

# Tag

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tag_name | string | Yes | Name of the tag |
| message | string | No | Tag message (creates annotated tag when provided) |

## Implementation

Create a lightweight tag or, when a message is provided, an annotated tag.

```bash
git tag [-m "<message>"] <tag_name>
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| tag | string | Name of the created tag |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| 128 | Tag name already exists | Delete the existing tag (`git tag -d <tag_name>`) or choose a unique name |
| 128 | Not inside a git repository | Run from within a git-initialized directory |

## Used By

- git-flow (tagging release commits)
