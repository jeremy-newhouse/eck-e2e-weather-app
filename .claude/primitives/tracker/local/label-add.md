---
name: tracker/local:label-add
description: Add a label to the labels array in a local issue frontmatter
version: "0.4.0"
---

# Label Add

Reads an existing issue file and inserts a new label into the `labels:` frontmatter array if it is not already present.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID (e.g., `LOCAL-003`) |
| label | string | Yes | Label to add (e.g., `bug`, `blocked`, `needs-review`) |

## Implementation

Uses Read then Edit tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Parse the `labels:` frontmatter line. Supported formats:
   - Inline array: `labels: [bug, backend]`
   - Empty array: `labels: []`
3. Check whether `label` already exists in the array. If it does, return early without modification.
4. Insert the new label into the inline array and use Edit to replace the `labels:` line with the updated value.
5. Use Edit to update the `updated:` frontmatter field to the current ISO 8601 timestamp.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID |
| path | string | Relative path of the updated file |
| labels | string[] | Full updated labels array after the addition |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| ALREADY_PRESENT | Label already exists in the array | No action needed |
| EMPTY_LABEL | `label` parameter is empty or whitespace-only | Provide a non-empty label string |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- dev-task (applies category and priority labels during issue creation workflow)
