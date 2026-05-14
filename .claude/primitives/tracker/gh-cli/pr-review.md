---
name: tracker/gh-cli:pr-review
description: Submit a review on a pull request
version: "0.4.0"
---

# PR Review

Submit an approve, request-changes, or comment review on a pull request.

## Parameters

| Parameter | Type   | Required | Description                                                    |
| --------- | ------ | -------- | -------------------------------------------------------------- |
| number    | number | Yes      | PR number                                                      |
| action    | string | Yes      | Review action: `approve`, `request-changes`, `comment`         |
| body      | string | No       | Review comment body (required for request-changes and comment) |

## Implementation

```bash
gh pr review {number} --{action} --body "{body}"
```

## Output

| Field     | Type    | Description                       |
| --------- | ------- | --------------------------------- |
| submitted | boolean | Review was successfully submitted |

## Errors

| Code         | Cause                            | Recovery                 |
| ------------ | -------------------------------- | ------------------------ |
| PR_NOT_FOUND | PR does not exist                | Verify PR number         |
| SELF_REVIEW  | Cannot review own PR (some orgs) | Request another reviewer |
| AUTH_FAILED  | Not authenticated with gh CLI    | Run `gh auth login`      |

## Used By

- validate-approval (automated review submission)
