---
name: tracker/local:issue-create
description: Create a new local issue file with YAML frontmatter in docs/issues/
version: "0.4.0"
---

# Issue Create

Writes a new `docs/issues/WA-<NNN>.md` file, auto-incrementing the ID from existing files.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Issue title |
| description | string | Yes | Issue description (markdown body) |
| priority | string | No | `low`, `medium` (default), `high`, or `urgent` |
| labels | string[] | No | Array of label strings |
| assignee | string | No | Assignee name or username |
| epic | string | No | Parent epic ID (e.g., `LOCAL-001`) |
| project_key | string | No | ID prefix (default: `LOCAL`) |

## Implementation

Uses Glob then Write tools. No external CLI.

1. Glob `docs/issues/WA-*.md` to collect existing files.
2. Parse the numeric suffix from each filename, find the maximum, and increment by one. If no files exist, start at `001`.
3. Format the new ID as `WA-<NNN>` (zero-padded to 3 digits).
4. Write the file to `docs/issues/{id}.md` using the Write tool.

Issue file format:

```markdown
---
title: "Issue title"
status: open
priority: medium
labels: []
assignee: ""
epic: ""
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

## Description

Issue description here.

## Comments
```

Set `created` and `updated` to the current ISO 8601 timestamp.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Assigned issue ID (e.g., `LOCAL-003`) |
| path | string | Relative path of the created file (e.g., `docs/issues/LOCAL-003.md`) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_ISSUES_DIR | `docs/issues/` does not exist | Create the directory before invoking |
| FILE_EXISTS | Target file already exists | A concurrent write may have used the same ID; re-run to recalculate next ID |
| MISSING_TITLE | `title` parameter is empty | Provide a non-empty title string |

## Used By

- dev-task (creates issues for planned work items)
