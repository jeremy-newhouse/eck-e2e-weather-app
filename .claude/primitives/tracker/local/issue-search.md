---
name: tracker/local:issue-search
description: Search local issue files by content pattern or frontmatter field value
version: "0.4.0"
---

# Issue Search

Uses Grep to find issues whose content or frontmatter matches a given pattern, scoped to `docs/issues/`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| pattern | string | Yes | Search pattern (regex supported) |
| project_key | string | No | Restrict search to files matching `WA-*.md` (default: all files in `docs/issues/`) |
| field | string | No | Restrict search to a specific frontmatter field name (e.g., `title`, `labels`) |
| case_insensitive | boolean | No | Enable case-insensitive matching (default: `false`) |

## Implementation

Uses Grep tool. No external CLI.

1. Set the search path to `docs/issues/`.
2. If `project_key` is provided, apply the glob filter `WA-*.md`; otherwise use `*.md`.
3. If `field` is provided, prefix the pattern to target the frontmatter line: `{field}:.*{pattern}`.
4. Run Grep with `output_mode: "content"` and `-n: true` to return line numbers.
5. If `case_insensitive` is `true`, pass `-i: true`.

## Output

| Field | Type | Description |
|-------|------|-------------|
| matches | object[] | Each match includes `file` (relative path), `line` (line number), and `text` (matching line content) |
| count | number | Total number of matching lines across all files |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_ISSUES_DIR | `docs/issues/` does not exist | Verify the project has a `docs/issues/` directory |
| NO_RESULTS | Pattern produced no matches | Broaden the pattern or remove the `field` restriction |
| INVALID_PATTERN | Regex pattern is malformed | Validate pattern syntax before invoking |

## Used By

- design-research (finds issues related to a topic or keyword)
