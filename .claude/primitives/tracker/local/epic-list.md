---
name: tracker/local:epic-list
description: List all local epics by filtering for type epic in issue frontmatter
version: "0.4.0"
---

# Epic List

Globs `docs/issues/WA-*.md`, reads each file's frontmatter, and returns only those with `type: epic`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_key | string | No | ID prefix filter (default: `LOCAL`) |
| status | string | No | Filter by epic status: `open`, `in-progress`, `done`, or `closed` |

## Implementation

Uses Glob and Read tools. No external CLI.

1. Glob `docs/issues/WA-*.md` to collect all file paths.
2. For each file, Read the file and parse the YAML frontmatter.
3. Retain only files where `type: epic` is present in the frontmatter.
4. If `status` is provided, further filter by matching the `status` field.
5. Return results sorted by ID (ascending numeric order).

## Output

| Field | Type | Description |
|-------|------|-------------|
| epics | object[] | Array of epic summaries, each containing `id`, `title`, `status`, `priority`, `labels`, `assignee` |
| count | number | Total number of epics returned |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_ISSUES_DIR | `docs/issues/` does not exist | Verify the project has a `docs/issues/` directory |
| NO_RESULTS | No epics match the applied filters | Broaden or remove filter parameters; create epics with `local-issues:epic-create` |
| MALFORMED_FRONTMATTER | One or more files have unparseable frontmatter | Inspect flagged files and correct the frontmatter |

## Used By

- dev-task (surveys existing epics before creating new work structure)
