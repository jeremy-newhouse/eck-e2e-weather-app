---
name: tracker:router
description: Dispatch tracker operations to the configured backend
version: "0.5.0"
type: router
---

# Tracker Router

Routes abstract `tracker:*` operations to concrete backend primitives based on the project's `TRACKER_TYPE` setting.

## Dispatch Table

| TRACKER_TYPE  | Default Backend | Plugin Required                   | CLI Required |
| ------------- | --------------- | --------------------------------- | ------------ |
| JIRA          | jira-official   | atlassian@claude-plugins-official | —            |
| GitHub Issues | gh-cli          | —                                 | gh           |
| Linear        | linear-official | linear@claude-plugins-official    | —            |
| local         | local-issues    | —                                 | —            |

## Resolution Protocol

1. Read `TRACKER_TYPE` from `.claude/project-constants.md`
2. Check `TRACKER_BACKEND_OVERRIDE` — if set, use that backend instead of default
3. Match backend from Dispatch Table (or override)
4. If backend is `*-official`:
   a. Run `core/ops:plugin-preflight` for the required plugin
   b. If plugin missing: STOP with install guidance
   c. Run `core/ops:mcp-preflight` with the plugin's probe tool
   d. If MCP unreachable: STOP with connectivity error
5. If backend is `gh-cli`: verify `gh auth status`
6. If backend is `local-issues`: proceed directly
7. If backend is `*-custom`: run `core/ops:mcp-preflight` with custom probe tool
8. Resolve primitive at `{backend}/{operation}.md`
9. Execute per that file's Implementation section

### GitHub Issues Fallback

GitHub Issues uses `gh-cli` exclusively — no MCP plugin dependency. The `github@claude-plugins-official` plugin is NOT required. If `gh auth status` fails, STOP with:

```
GitHub CLI is not authenticated.
Run: gh auth login
```

### Override Mechanism

Set `TRACKER_BACKEND_OVERRIDE` in `.claude/project-constants.md` to bypass the default backend:

- `jira-custom` — use custom JIRA MCP server tools (requires scaffold/custom/ primitives)
- `github-custom` — use custom GitHub MCP server tools
- `linear-custom` — use custom Linear MCP server tools

When an override is set, `core/ops:mcp-preflight` validates the custom MCP server instead of checking for an official plugin.

## Core Operations

All backends implement these operations:

- `issue-create` - Create a new issue
- `issue-read` - Read issue details
- `issue-update` - Update issue fields
- `issue-search` - Search/query issues
- `issue-transition` - Change issue status
- `comment-add` - Add a comment to an issue

## Extended Operations

Not all backends support these. Check the backend directory for availability.

| Operation        | Available In                     |
| ---------------- | -------------------------------- |
| issue-close      | gh-cli, linear-cli, local-issues |
| issue-list       | gh-cli, linear-cli, local-issues |
| issue-view       | gh-cli, linear-cli, local-issues |
| issue-link       | jira-official                    |
| pr-create        | gh-cli                           |
| pr-read          | gh-cli                           |
| pr-view          | gh-cli                           |
| pr-list          | gh-cli                           |
| pr-merge         | gh-cli                           |
| pr-review        | gh-cli                           |
| pr-checkout      | gh-cli                           |
| epic-create      | jira-official, local-issues      |
| epic-read        | jira-official, local-issues      |
| epic-list        | local-issues                     |
| sprint-read      | jira-official, local-issues      |
| sprint-manage    | jira-official                    |
| milestone-create | gh-cli                           |
| milestone-read   | gh-cli                           |
| cycle-read       | linear-official, linear-cli      |
| project-create   | linear-official, linear-cli      |
| project-read     | linear-official, linear-cli      |
| label-add        | gh-cli, local-issues             |
| label-list       | linear-cli                       |
| comment-read     | jira-official, local-issues      |
| attachment-add   | jira-official                    |
| board-read       | jira-official                    |
| field-read       | jira-official                    |
| release-create   | gh-cli                           |
| release-list     | gh-cli                           |
| release-view     | gh-cli                           |
| repo-clone       | gh-cli                           |
| repo-create      | gh-cli                           |
| repo-fork        | gh-cli                           |
| repo-view        | gh-cli                           |
| workflow-list    | gh-cli                           |
| workflow-logs    | gh-cli                           |
| workflow-run     | gh-cli                           |
| workflow-view    | gh-cli                           |
| api-call         | gh-cli                           |
| auth-status      | gh-cli                           |
| team-list        | linear-cli                       |
| team-view        | linear-cli                       |

## Used By

- deploy-tracker
- deploy-review
- core/ops:close-feature-issue
- validate-merge
- validate-approval
- deploy-promote
- deploy-status
- dev-pr
- dev-task
- dev-feature
- dev-sprint
- design-feature
- create-feature
- start-project
- git-status
- project-status
- checkpoint-verify
- greptile-gate
