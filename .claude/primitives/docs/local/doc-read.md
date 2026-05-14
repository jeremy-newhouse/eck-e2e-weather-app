---
name: docs/local:doc-read
description: Read a local documentation file
version: "0.4.0"
---

# Doc Read

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| path | string | Yes | Relative path within `docs/` (e.g., `specs/user-auth-spec.md`) |

## Implementation

Uses Read tool to read `docs/{path}`.

## Output

| Field | Type | Description |
|-------|------|-------------|
| content | string | Full markdown content of the file including frontmatter |
| frontmatter | object | Parsed YAML frontmatter fields (`title`, `type`, `status`, `created`, `updated`) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| FILE_NOT_FOUND | No file exists at `docs/{path}` | Use `local-docs:doc-list` to find valid paths |
| INVALID_PATH | Path traverses outside `docs/` | Provide a path relative to `docs/` without `../` segments |

## Used By

- design-feature
- dev-feature
- sync-context (when DOC_PLATFORM = "Local markdown")
