---
name: tracker/gh-cli:repo-fork
description: Fork a GitHub repository
version: "0.4.0"
---

# Repo Fork

Create a fork of a GitHub repository under the authenticated user's account.

## Parameters

| Parameter   | Type    | Required | Description                                            |
| ----------- | ------- | -------- | ------------------------------------------------------ |
| repo        | string  | Yes      | Repository in `owner/name` format                      |
| clone       | boolean | No       | Clone the fork locally after creation (default: false) |
| remote_name | string  | No       | Name for the upstream remote (default: upstream)       |

## Implementation

```bash
gh repo fork {repo} --clone={clone} --remote-name={remote_name}
```

## Output

| Field    | Type    | Description                  |
| -------- | ------- | ---------------------------- |
| fork_url | string  | URL of the created fork      |
| success  | boolean | Fork completed without error |

## Errors

| Code           | Cause                                  | Recovery            |
| -------------- | -------------------------------------- | ------------------- |
| REPO_NOT_FOUND | Source repository does not exist       | Verify repo name    |
| FORK_EXISTS    | Fork already exists under user account | Use existing fork   |
| AUTH_FAILED    | Not authenticated with gh CLI          | Run `gh auth login` |

## Used By

- dev-pr (fork-based contribution workflow)
