---
name: tracker/gh-cli:pr-view
description: View pull request details as JSON
version: "0.4.0"
---

# PR View

Retrieve detailed information about a specific pull request.

## Parameters

| Parameter | Type   | Required | Description                                |
| --------- | ------ | -------- | ------------------------------------------ |
| number    | number | No       | PR number (default: PR for current branch) |

## Implementation

```bash
gh pr view {number} --json number,title,body,state,author,baseRefName,headRefName,url,additions,deletions,commits,files,reviews,statusCheckRollup,labels,milestone
```

## Output

| Field             | Type     | Description                     |
| ----------------- | -------- | ------------------------------- |
| number            | number   | PR number                       |
| title             | string   | PR title                        |
| state             | string   | PR state (OPEN, CLOSED, MERGED) |
| statusCheckRollup | object[] | CI check statuses               |
| reviews           | object[] | Review decisions                |

## Errors

| Code         | Cause                         | Recovery            |
| ------------ | ----------------------------- | ------------------- |
| PR_NOT_FOUND | PR number does not exist      | Verify PR number    |
| AUTH_FAILED  | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-approval (check PR status and reviews)
- validate-ci (check CI status)
