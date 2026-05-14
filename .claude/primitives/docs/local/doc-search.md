---
name: docs/local:doc-search
description: Search local documentation files by content
version: "0.4.0"
---

# Doc Search

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| pattern | string | Yes | Search pattern (regex supported) |
| type | string | No | Directory filter: `specs`, `adrs`, `design`, `research`, `risk` |
| glob | string | No | File pattern override (e.g., `*.md`) |

## Implementation

Uses Grep tool on `docs/` directory. When `type` is provided, scopes the search to `docs/{type}/`. When `glob` is provided, applies it as the file filter.

## Output

| Field | Type | Description |
|-------|------|-------------|
| matches | object[] | Each match includes `file` (relative path), `line` (line number), and `text` (matching line content) |
| count | number | Total number of matching lines |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_DOCS_DIR | `docs/` directory does not exist | Verify project has a `docs/` directory |
| NO_RESULTS | Pattern produced no matches | Broaden pattern or remove `type`/`glob` filters |
| INVALID_PATTERN | Regex pattern is malformed | Validate pattern syntax before invoking |

## Used By

- design-feature (research phase)
- dev-feature (context gathering)
