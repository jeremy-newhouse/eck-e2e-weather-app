---
name: tracker/local:issue-close
description: Close a local issue by setting its status to closed
version: "0.4.0"
---

# Issue Close

Reads an issue file and sets `status: closed` in the YAML frontmatter, then updates the `updated` timestamp.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | string | Yes | Issue ID to close (e.g., `LOCAL-003`) |

## Implementation

Uses Read then Edit tools. No external CLI.

1. Read `docs/issues/{id}.md` with the Read tool.
2. Verify the current `status` field. If it is already `closed`, return early without modification.
3. Use Edit to replace the `status:` frontmatter line:
   - `status: open` → `status: closed`
   - `status: in-progress` → `status: closed`
   - `status: done` → `status: closed`
4. Use Edit to update the `updated:` field to the current ISO 8601 timestamp.

## Output

| Field | Type | Description |
|-------|------|-------------|
| id | string | Issue ID |
| path | string | Relative path of the updated file |
| previous_status | string | Status value before closure |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NOT_FOUND | File `docs/issues/{id}.md` does not exist | Verify the ID with `local-issues:issue-list` |
| ALREADY_CLOSED | Issue status is already `closed` | No action needed |
| MALFORMED_FRONTMATTER | Frontmatter cannot be parsed | Inspect and correct the file manually before retrying |

## Used By

- deploy-tracker (closes resolved issues during release finalization)
