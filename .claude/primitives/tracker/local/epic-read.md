---
name: tracker/local:epic-read
description: Read a local epic file and list all child issues belonging to it
version: "0.4.0"
---

# Epic Read

Reads the epic file at `docs/issues/{id}.md` and then globs all issue files to find children whose `epic:` frontmatter field references this epic's ID.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Epic ID (e.g., `LOCAL-001`) |
| project_key | string | No | ID prefix used to scope child issue glob (default: `LOCAL`) |

## Implementation

Uses Read and Glob tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Parse the frontmatter. Confirm `type: epic` is present; if not, return an `NOT_AN_EPIC` error.
3. Glob `docs/issues/WA-*.md` to collect all files.
4. For each file (excluding the epic itself), Read the file and check whether the `epic:` frontmatter field equals `{id}`.
5. Collect matching child issue summaries: `id`, `title`, `status`, `priority`.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Epic ID |
| title | string | Epic title |
| status | string | Epic status |
| priority | string | Epic priority |
| labels | string[] | Epic labels |
| assignee | string | Epic assignee |
| description | string | Markdown body of the Description section |
| children | object[] | Array of child issue summaries (`id`, `title`, `status`, `priority`) |
| child_count | number | Total number of child issues |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:epic-list` |
| NOT_AN_EPIC | File exists but `type: epic` is absent from frontmatter | Use `local-issues:issue-read` for regular issues |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- dev-feature (loads epic context and child issue list before implementation)
