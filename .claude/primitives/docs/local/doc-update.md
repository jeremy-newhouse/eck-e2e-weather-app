---
name: docs/local:doc-update
description: Update an existing local documentation file
version: "0.4.0"
---

# Doc Update

## Parameters

| Parameter | Type   | Required | Description                                                    |
| --------- | ------ | -------- | -------------------------------------------------------------- |
| path      | string | Yes      | Relative path within `docs/` (e.g., `specs/user-auth-spec.md`) |
| content   | string | Yes      | Updated markdown content (preserves frontmatter structure)     |

## Implementation

Uses Edit tool to modify `docs/{path}`.

Always update the `updated` date in frontmatter. Set `status` according to the appropriate transition:

- `draft` → `accepted` (when approved)
- `accepted` → `superseded` (when replaced by a newer document)
- `accepted` → `deprecated` (when no longer relevant, not replaced)

## Output

| Field   | Type   | Description                                               |
| ------- | ------ | --------------------------------------------------------- |
| path    | string | Relative path of the updated file                         |
| updated | string | New value of the `updated` frontmatter field (YYYY-MM-DD) |

## Errors

| Code                | Cause                                              | Recovery                                                                       |
| ------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------ |
| FILE_NOT_FOUND      | No file exists at `docs/{path}`                    | Use `local-docs:doc-create` to create a new file                               |
| INVALID_STATUS      | Proposed status transition is not valid            | Follow allowed transitions: `draft` → `accepted` → `superseded` / `deprecated` |
| MISSING_FRONTMATTER | Content does not include required YAML frontmatter | Preserve the original frontmatter block and update only body content           |

## Used By

- design-feature
- design-solution
