---
name: tracker/gh-cli:pr-list
description: List pull requests with JSON output
version: "0.4.0"
---

# PR List

List pull requests for the current repository with optional filters.

## Parameters

| Parameter | Type   | Required | Description                                                        |
| --------- | ------ | -------- | ------------------------------------------------------------------ |
| state     | string | No       | Filter by state: `open`, `closed`, `merged`, `all` (default: open) |
| base      | string | No       | Filter by base branch                                              |
| head      | string | No       | Filter by head branch                                              |
| author    | string | No       | Filter by author                                                   |
| limit     | number | No       | Maximum results (default: 30)                                      |

## Implementation

```bash
gh pr list \
  --state {state} \
  --json number,title,state,author,baseRefName,headRefName,url,createdAt,updatedAt \
  --limit {limit} \
  {base ? `--base ${base}` : ""} \
  {head ? `--head ${head}` : ""} \
  {author ? `--author ${author}` : ""}
```

## Output

| Field | Type     | Description                                                                      |
| ----- | -------- | -------------------------------------------------------------------------------- |
| prs   | object[] | Array of PR objects with number, title, state, author, branches, URL, timestamps |

## Errors

| Code        | Cause                         | Recovery                           |
| ----------- | ----------------------------- | ---------------------------------- |
| NOT_A_REPO  | Not in a git repository       | Navigate to a repository directory |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login`                |

## Used By

- dev-pr (check for existing PRs)
- deploy-status (PR status dashboard)
