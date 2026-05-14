---
name: tracker/local:sprint-read
description: Read the current sprint definition from docs/issues/sprint.md
version: "0.4.0"
---

# Sprint Read

Reads `docs/issues/sprint.md`, which defines the active sprint's goal, dates, and the set of issue IDs committed to the sprint.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| resolve_issues | boolean | No | When `true`, read each referenced issue file and return full issue summaries (default: `false`) |

## Implementation

Uses Read tool (and optionally Glob). No external CLI.

1. Read `docs/issues/sprint.md` with the Read tool.
2. Parse the YAML frontmatter to extract sprint metadata.
3. Parse the `## Issues` section to collect the list of referenced issue IDs.
4. If `resolve_issues` is `true`, read each referenced issue file (`docs/issues/{id}.md`) and attach the parsed frontmatter summary.

Sprint file format:

```markdown
---
sprint: 1
goal: "Sprint goal statement"
start: 2026-01-01
end: 2026-01-14
status: active  # active | complete | planned
---

## Issues

- LOCAL-003
- LOCAL-004
- LOCAL-007

## Notes

Optional sprint notes here.
```

If `docs/issues/sprint.md` does not exist, return a `NO_SPRINT_FILE` error rather than creating the file.

## Output

| Field | Type | Description |
|-------|------|-------------|
| sprint | number | Sprint number |
| goal | string | Sprint goal statement |
| start | string | Sprint start date (`YYYY-MM-DD`) |
| end | string | Sprint end date (`YYYY-MM-DD`) |
| status | string | Sprint status: `active`, `complete`, or `planned` |
| issue_ids | string[] | List of issue IDs committed to the sprint |
| issues | object[] | Full issue summaries (only populated when `resolve_issues` is `true`) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| NO_SPRINT_FILE | `docs/issues/sprint.md` does not exist | Create the sprint file manually or via the sprint planning workflow |
| MALFORMED_FRONTMATTER | Sprint file frontmatter cannot be parsed | Inspect and correct `docs/issues/sprint.md` |
| MISSING_ISSUES_SECTION | The `## Issues` heading is absent | Add an `## Issues` section listing issue IDs |

## Used By

- dev-sprint (loads the active sprint before beginning sprint execution)
