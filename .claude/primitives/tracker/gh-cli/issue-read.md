---
name: tracker/gh-cli:issue-read
description: Read issue details via gh CLI (maps to schema issue-read contract)
version: "0.6.5"
---

# Issue Read

Read detailed information about a specific GitHub issue. This is the schema-compatible `issue-read` operation — it maps to `gh issue view` under the hood.

## Parameters

| Parameter | Type   | Required | Description  |
| --------- | ------ | -------- | ------------ |
| id        | string | Yes      | Issue number |

## Implementation

```bash
gh issue view {id} --json number,title,body,state,labels,assignees,url,createdAt,updatedAt,closedAt
```

## Output

Mapped to the `tracker:schema` contract:

| Field       | Type     | Description                     |
| ----------- | -------- | ------------------------------- |
| id          | string   | Issue number (as string)        |
| title       | string   | Issue title                     |
| description | string   | Issue body                      |
| status      | string   | Issue state (OPEN, CLOSED)      |
| assignee    | string   | First assignee login (or empty) |
| labels      | string[] | Label names                     |
| url         | string   | Issue URL                       |

### Field Mapping

| Schema field | GitHub JSON field  | Transform            |
| ------------ | ------------------ | -------------------- |
| id           | number             | `String(number)`     |
| description  | body               | direct               |
| status       | state              | direct (OPEN/CLOSED) |
| assignee     | assignees[0].login | first or empty       |
| labels       | labels[].name      | map to strings       |

## Errors

| Code            | Cause                         | Recovery            |
| --------------- | ----------------------------- | ------------------- |
| ISSUE_NOT_FOUND | Issue number does not exist   | Verify issue number |
| AUTH_FAILED     | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- dev-task (read issue details for implementation)
- deploy-tracker (read issue status before transition)
