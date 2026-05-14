---
name: tracker/local:epic-create
description: Create a new local epic file with type epic in YAML frontmatter
version: "0.4.0"
---

# Epic Create

Writes a new `docs/issues/WA-<NNN>.md` file with `type: epic` in the frontmatter, auto-incrementing the ID across all issue files.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Epic title |
| description | string | Yes | Epic description and goals (markdown body) |
| priority | string | No | `low`, `medium` (default), `high`, or `urgent` |
| labels | string[] | No | Array of label strings |
| assignee | string | No | Assignee name or username |
| project_key | string | No | ID prefix (default: `LOCAL`) |

## Implementation

Uses Glob then Write tools. No external CLI.

1. Glob `docs/issues/WA-*.md` to collect all existing files (issues and epics share the same ID sequence).
2. Parse the numeric suffix from each filename, find the maximum, and increment by one. If no files exist, start at `001`.
3. Format the new ID as `WA-<NNN>` (zero-padded to 3 digits).
4. Write `docs/issues/{id}.md` using the Write tool with `type: epic` included in the frontmatter.

Epic file format:

```markdown
---
title: "Epic title"
type: epic
status: open
priority: medium
labels: []
assignee: ""
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

## Description

Epic description and goals here.

## Comments
```

Set `created` and `updated` to the current ISO 8601 timestamp. Epics do not have an `epic:` field (they are the parent, not a child).

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Assigned epic ID (e.g., `LOCAL-001`) |
| path | string | Relative path of the created file (e.g., `docs/issues/LOCAL-001.md`) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_ISSUES_DIR | `docs/issues/` does not exist | Create the directory before invoking |
| FILE_EXISTS | Target file already exists | A concurrent write may have used the same ID; re-run to recalculate next ID |
| MISSING_TITLE | `title` parameter is empty | Provide a non-empty title string |

## Used By

- dev-task (creates epics to group related work items)
