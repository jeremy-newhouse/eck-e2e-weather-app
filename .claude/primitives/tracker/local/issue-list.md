---
name: tracker/local:issue-list
description: List local issues with optional filtering by status, priority, or label
version: "0.4.0"
---

# Issue List

Globs `docs/issues/WA-*.md`, reads frontmatter from each file, and returns a filtered list of issues.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_key | string | No | ID prefix filter (default: `LOCAL`) |
| status | string | No | Filter by status: `open`, `in-progress`, `done`, or `closed` |
| priority | string | No | Filter by priority: `low`, `medium`, `high`, or `urgent` |
| label | string | No | Filter to issues containing this label |
| epic | string | No | Filter to issues belonging to this epic ID |
| assignee | string | No | Filter to issues assigned to this user |

## Implementation

Uses Glob and Read tools. No external CLI.

1. Glob `docs/issues/WA-*.md` to collect all matching file paths.
2. For each file, Read the file and parse the YAML frontmatter.
3. Apply each provided filter against the corresponding frontmatter field. For `label`, check that the value appears in the `labels` array.
4. Return the filtered set sorted by ID (ascending numeric order).

When no filters are provided, all issues for the given project key are returned.

## Output

| Field | Type | Description |
|-------|------|-------------|
| issues | object[] | Array of issue summaries, each containing `id`, `title`, `status`, `priority`, `labels`, `assignee`, `epic` |
| count | number | Total number of issues returned after filtering |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_ISSUES_DIR | `docs/issues/` does not exist | Verify the project has a `docs/issues/` directory |
| NO_RESULTS | No files match the applied filters | Broaden or remove filter parameters |
| MALFORMED_FRONTMATTER | One or more files have unparseable frontmatter | Inspect flagged files and correct the frontmatter |

## Used By

- dev-task (surveys existing issues before creating new ones)
- deploy-status (queries open and in-progress issues for release report)
