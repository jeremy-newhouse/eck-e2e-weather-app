---
name: docs/local:doc-create
description: Create a markdown documentation file in the local docs directory
version: "0.4.0"
---

# Doc Create

## Parameters

| Parameter | Type   | Required | Description                                                  |
| --------- | ------ | -------- | ------------------------------------------------------------ |
| type      | string | Yes      | Document type: `specs`, `adrs`, `design`, `research`, `risk` |
| filename  | string | Yes      | File name in kebab-case (e.g., `user-auth-spec.md`)          |
| title     | string | Yes      | Document title                                               |
| content   | string | Yes      | Markdown content with YAML frontmatter                       |

## Implementation

Uses Write tool to create `docs/{type}/{filename}`.

All local docs must include YAML frontmatter:

```yaml
---
title: "Document Title"
type: spec-feat | spec-api | spec-data | adr | design | research | interview | risk
status: draft | accepted | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

Directory structure:

```
docs/
├── specs/          # Feature specs, API specs, data specs
├── adrs/           # Architecture Decision Records
├── design/         # UI/UX design docs
├── research/       # Research and interview notes
├── risk/           # Risk assessments
└── README.md       # Index page
```

## Output

| Field | Type   | Description                                                              |
| ----- | ------ | ------------------------------------------------------------------------ |
| path  | string | Relative path of the created file (e.g., `docs/specs/user-auth-spec.md`) |

## Errors

| Code                | Cause                                              | Recovery                                                  |
| ------------------- | -------------------------------------------------- | --------------------------------------------------------- |
| INVALID_TYPE        | `type` is not one of the allowed values            | Use one of: `specs`, `adrs`, `design`, `research`, `risk` |
| FILE_EXISTS         | File already exists at target path                 | Use `local-docs:doc-update` to modify an existing file    |
| MISSING_FRONTMATTER | Content does not include required YAML frontmatter | Add frontmatter block before writing                      |

## Used By

- design-feature (when DOC_PLATFORM = "Local markdown")
- design-solution
