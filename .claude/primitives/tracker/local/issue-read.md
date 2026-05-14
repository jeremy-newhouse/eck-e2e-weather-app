---
name: tracker/local:issue-read
description: Read a local issue file and parse its YAML frontmatter and body
version: "0.4.0"
---

# Issue Read

Reads `docs/issues/{id}.md` and returns the parsed frontmatter fields alongside the description and comments body.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |

## Implementation

Uses Read tool. No external CLI.

1. Construct the file path as `docs/issues/{id}.md`.
2. Read the file with the Read tool.
3. Parse the YAML frontmatter block (content between the first `---` delimiters).
4. Return the structured frontmatter fields and the markdown body below the frontmatter.

If the file does not exist, return a `NOT_FOUND` error.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID derived from filename |
| title | string | Issue title from frontmatter |
| status | string | Current status: `open`, `in-progress`, `done`, or `closed` |
| priority | string | Priority: `low`, `medium`, `high`, or `urgent` |
| labels | string[] | Applied labels |
| assignee | string | Assigned user (empty string if unset) |
| epic | string | Parent epic ID (empty string if unset) |
| created | string | ISO 8601 creation timestamp |
| updated | string | ISO 8601 last-updated timestamp |
| description | string | Markdown body of the Description section |
| comments | string | Markdown body of the Comments section |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| MALFORMED_FRONTMATTER | YAML frontmatter block is missing or unparseable | Inspect the file manually and correct the frontmatter |

## Used By

- dev-task (loads issue context before starting work)
