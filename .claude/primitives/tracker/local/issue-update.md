---
name: tracker/local:issue-update
description: Update one or more frontmatter fields in a local issue file
version: "0.4.0"
---

# Issue Update

Reads an existing issue file and applies targeted edits to its YAML frontmatter fields, then updates the `updated` timestamp.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |
| title | string | No | New issue title |
| priority | string | No | New priority: `low`, `medium`, `high`, or `urgent` |
| labels | string[] | No | Replacement labels array |
| assignee | string | No | New assignee name or username |
| epic | string | No | New parent epic ID |
| description | string | No | Replacement markdown body for the Description section |

## Implementation

Uses Read then Edit tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. For each provided parameter, use the Edit tool to replace the corresponding frontmatter line.
   - For scalar fields (e.g., `title`), replace the full YAML line: `title: "old"` → `title: "new"`.
   - For the `labels` array, replace the full `labels:` line with the new inline array.
   - For `description`, replace the content between `## Description` and the next `##` heading.
3. Always update the `updated:` frontmatter field to the current ISO 8601 timestamp as a final edit.

Do not call Edit unless the parameter value has changed; skip unchanged fields.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID |
| path | string | Relative path of the updated file |
| fields_updated | string[] | Names of frontmatter fields that were changed |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| NO_CHANGES | No parameters provided or all values are identical to existing | Pass at least one field with a new value |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- dev-task (updates priority, assignee, or description during work)
