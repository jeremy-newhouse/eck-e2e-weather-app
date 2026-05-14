---
name: docs/local:doc-list
description: List documentation files by type directory
version: "0.4.0"
---

# Doc List

## Parameters

| Parameter | Type   | Required | Description                                                     |
| --------- | ------ | -------- | --------------------------------------------------------------- |
| type      | string | No       | Directory filter: `specs`, `adrs`, `design`, `research`, `risk` |
| status    | string | No       | Frontmatter status filter: `draft`, `accepted`, `superseded`    |

## Implementation

Uses Glob tool on `docs/{type}/**/*.md`. When `type` is omitted, globs `docs/**/*.md`.

If `status` filter is provided, uses Grep to match the `status:` field in frontmatter.

## Output

| Field | Type     | Description                                    |
| ----- | -------- | ---------------------------------------------- |
| files | string[] | Relative paths of matching documentation files |
| count | number   | Total number of files returned                 |

## Errors

| Code         | Cause                                                   | Recovery                                                     |
| ------------ | ------------------------------------------------------- | ------------------------------------------------------------ |
| NO_DOCS_DIR  | `docs/` directory does not exist                        | Verify project has a `docs/` directory; create it if missing |
| INVALID_TYPE | Provided `type` does not match an existing subdirectory | Use one of: `specs`, `adrs`, `design`, `research`, `risk`    |
| NO_RESULTS   | No files match the given filters                        | Broaden or remove filters                                    |

## Used By

- design-feature (lifecycle review)
- sync-context (when DOC_PLATFORM = "Local markdown")
