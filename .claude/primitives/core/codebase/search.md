---
name: core/codebase:search
description: Search code for patterns
version: "0.4.0"
---

# Codebase Search

Search files for regex patterns using the ripgrep-backed Grep tool.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| pattern | string | Yes | Regex pattern to search for |
| file_glob | string | No | File pattern filter (e.g., `*.py`, `**/*.ts`) |

## Implementation

Uses Claude Code Grep tool with ripgrep backend.

Example:

```
pattern: "def.*authenticate"
file_glob: "**/*.py"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| matches | array | List of matching lines with file path and line number |
| match_count | integer | Total number of matches found |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INVALID_REGEX | Pattern is not valid regex syntax | Escape special characters and retry |
| NO_MATCHES | Pattern found no results | Broaden the pattern or confirm the target files exist |
| GLOB_NO_FILES | `file_glob` matched no files | Verify the glob expression against the directory structure |

## Used By

- validate-ci (locating CI configuration patterns)
- validate-code (finding code anti-patterns)
- dev-task (locating symbols and call sites during implementation)
