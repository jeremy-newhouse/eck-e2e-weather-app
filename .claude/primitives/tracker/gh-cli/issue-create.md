---
name: tracker/gh-cli:issue-create
description: Create a GitHub issue using the gh CLI
version: "0.4.0"
---

# Issue Create

Create a new issue on GitHub with labels and assignees.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| title | string | Yes | Issue title |
| body | string | Yes | Issue body (markdown) |
| labels | string[] | No | Labels to apply |
| assignees | string[] | No | GitHub usernames to assign |
| milestone | string | No | Milestone title or number |
| project | string | No | Project name or number to add issue to |

## Implementation

```bash
gh issue create \
  --title "{title}" \
  --body "{body}" \
  {labels ? labels.map(l => `--label "${l}"`).join(" ") : ""} \
  {assignees ? assignees.map(a => `--assignee "${a}"`).join(" ") : ""} \
  {milestone ? `--milestone "${milestone}"` : ""} \
  {project ? `--project "${project}"` : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| url | string | URL of the created issue |
| number | number | Issue number |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |
| LABEL_NOT_FOUND | Specified label does not exist | Create label first or check spelling |
| MILESTONE_NOT_FOUND | Specified milestone does not exist | Create milestone first |

## Used By

- dev-task (create issues via CLI instead of MCP)
