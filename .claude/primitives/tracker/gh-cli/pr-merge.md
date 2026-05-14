---
name: tracker/gh-cli:pr-merge
description: Merge a pull request
version: "0.4.0"
---

# PR Merge

Merge a pull request with the specified merge strategy.

## Parameters

| Parameter     | Type    | Required | Description                                                |
| ------------- | ------- | -------- | ---------------------------------------------------------- |
| number        | number  | No       | PR number (default: PR for current branch)                 |
| method        | string  | No       | Merge method: `merge`, `squash`, `rebase` (default: merge) |
| delete_branch | boolean | No       | Delete head branch after merge (default: true)             |

## Implementation

```bash
gh pr merge {number} --{method} {delete_branch ? "--delete-branch" : ""}
```

## Output

| Field  | Type    | Description                |
| ------ | ------- | -------------------------- |
| merged | boolean | PR was successfully merged |
| url    | string  | URL of the merged PR       |

## Errors

| Code            | Cause                                  | Recovery                   |
| --------------- | -------------------------------------- | -------------------------- |
| MERGE_CONFLICT  | PR has merge conflicts                 | Resolve conflicts and push |
| CHECKS_PENDING  | Required status checks have not passed | Wait for CI to complete    |
| REVIEW_REQUIRED | Required reviews not approved          | Request and obtain reviews |
| PR_NOT_FOUND    | PR does not exist                      | Verify PR number           |

## Used By

- validate-merge (primary merge path)
