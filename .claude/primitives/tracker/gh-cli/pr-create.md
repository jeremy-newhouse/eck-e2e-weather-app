---
name: tracker/gh-cli:pr-create
description: Create a pull request using the gh CLI
version: "0.4.0"
---

# PR Create

Create a pull request on GitHub from the current or specified branch.

## Parameters

| Parameter | Type     | Required | Description                                |
| --------- | -------- | -------- | ------------------------------------------ |
| title     | string   | Yes      | PR title                                   |
| body      | string   | Yes      | PR description (markdown)                  |
| base      | string   | No       | Base branch (default: repo default branch) |
| head      | string   | No       | Head branch (default: current branch)      |
| draft     | boolean  | No       | Create as draft PR (default: false)        |
| labels    | string[] | No       | Labels to apply                            |
| reviewers | string[] | No       | Reviewer usernames to request              |

## Implementation

```bash
gh pr create \
  --title "{title}" \
  --body "{body}" \
  --base {base} \
  --head {head} \
  {draft ? "--draft" : ""} \
  {labels ? labels.map(l => `--label "${l}"`).join(" ") : ""} \
  {reviewers ? reviewers.map(r => `--reviewer "${r}"`).join(" ") : ""}
```

## Output

| Field  | Type   | Description           |
| ------ | ------ | --------------------- |
| url    | string | URL of the created PR |
| number | number | PR number             |

## Errors

| Code             | Cause                                              | Recovery                             |
| ---------------- | -------------------------------------------------- | ------------------------------------ |
| NO_COMMITS       | Head branch has no commits ahead of base           | Push commits before creating PR      |
| PR_EXISTS        | A PR already exists for this head/base combination | Use `gh pr view` to find existing PR |
| AUTH_FAILED      | Not authenticated with gh CLI                      | Run `gh auth login`                  |
| BRANCH_NOT_FOUND | Head or base branch does not exist on remote       | Push branch first                    |

## Used By

- dev-pr (primary PR creation path)
