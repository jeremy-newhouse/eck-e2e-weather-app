---
name: tracker/gh-cli:pr-checkout
description: Check out a pull request branch locally
version: "0.4.0"
---

# PR Checkout

Check out the head branch of a pull request locally for review or testing.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| number | number | Yes | PR number to check out |

## Implementation

```bash
gh pr checkout {number}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| branch | string | Local branch name checked out |
| success | boolean | Checkout completed without error |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| PR_NOT_FOUND | PR does not exist | Verify PR number |
| DIRTY_WORKTREE | Local working tree has uncommitted changes | Commit or stash changes first |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |

## Used By

- validate-code (checkout PR for review)
