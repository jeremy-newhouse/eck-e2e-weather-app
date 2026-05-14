---
name: tracker/local:comment-read
description: Read the Comments section from a local issue file
version: "0.4.0"
---

# Comment Read

Reads `docs/issues/{id}.md` and extracts the content of the `## Comments` section as structured comment entries.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |
| limit | number | No | Return only the most recent N comments (default: all) |

## Implementation

Uses Read tool. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Locate the `## Comments` heading and extract all content beneath it to end-of-file.
3. Split the content on `### ` to identify individual comment blocks.
4. For each block, parse the heading line to extract the timestamp and author (format: `{timestamp} — {author}`).
5. If `limit` is provided, return only the last N entries (most recent comments are assumed to appear last).

## Output

| Field | Type | Description |
|-------|------|-------------|
| comments | object[] | Array of comment objects, each with `timestamp` (string), `author` (string), and `body` (string) |
| count | number | Total number of comments in the file |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| NO_COMMENTS | The `## Comments` section is empty or absent | No comments have been added yet; use `local-issues:comment-add` |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- dev-task (reviews comment history before resuming work on an issue)
