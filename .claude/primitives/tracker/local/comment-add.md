---
name: tracker/local:comment-add
description: Append a timestamped comment to a local issue file
version: "0.4.0"
---

# Comment Add

Reads an existing issue file and appends a new comment entry under the `## Comments` section with an ISO 8601 timestamp and author attribution.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |
| body | string | Yes | Comment content (markdown) |
| author | string | No | Author name or username (default: empty, meaning the agent) |

## Implementation

Uses Read then Edit tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Verify the `## Comments` section exists. If it is absent, add it at the end of the file before inserting the comment.
3. Format the comment block:

   ```markdown
   ### {YYYY-MM-DDTHH:MM:SSZ} — {author}
   {body}
   ```

   Use the current ISO 8601 timestamp. If `author` is empty, omit the ` — {author}` portion.
4. Use Edit to append the formatted comment block after the last existing content in the `## Comments` section.
5. Use Edit to update the `updated:` frontmatter field to the current ISO 8601 timestamp.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID |
| path | string | Relative path of the updated file |
| timestamp | string | ISO 8601 timestamp applied to the comment |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| EMPTY_BODY | `body` parameter is empty or whitespace-only | Provide non-empty comment content |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- dev-sprint (records progress notes and blockers on active issues)
