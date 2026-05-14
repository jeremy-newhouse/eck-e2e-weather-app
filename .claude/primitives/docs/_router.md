---
name: docs:router
description: Dispatch documentation operations to the configured backend
version: "0.7.4"
type: router
---

# Docs Router

Routes abstract `docs:*` operations to concrete backend primitives. Core operations always resolve to the local-docs backend. Confluence operations are conditionally available based on `CONFLUENCE_ENABLED`.

## Dispatch Table

| Operation   | Backend             | Condition               | Plugin Required                   |
| ----------- | ------------------- | ----------------------- | --------------------------------- |
| doc-create  | local-docs          | always                  | —                                 |
| doc-read    | local-docs          | always                  | —                                 |
| doc-update  | local-docs          | always                  | —                                 |
| doc-search  | local-docs          | always                  | —                                 |
| doc-list    | local-docs          | always                  | —                                 |
| doc-publish | confluence-official | CONFLUENCE_ENABLED=true | atlassian@claude-plugins-official |
| doc-pull    | confluence-official | CONFLUENCE_ENABLED=true | atlassian@claude-plugins-official |
| doc-diff    | confluence-official | CONFLUENCE_ENABLED=true | atlassian@claude-plugins-official |

## Resolution Protocol

1. Read `CONFLUENCE_ENABLED` from `.claude/project-constants.md`
2. Backward compat: if `CONFLUENCE_ENABLED` is absent but `DOC_PLATFORM` is present:
   - `DOC_PLATFORM=Confluence` → treat as `CONFLUENCE_ENABLED=true`
   - `DOC_PLATFORM=Local` → treat as `CONFLUENCE_ENABLED=false`
   - Emit: `[>] DOC_PLATFORM is deprecated and will be removed in v0.7.4. Use CONFLUENCE_ENABLED instead.`
3. Core operations always resolve to the local-docs backend:
   - `doc-create` → `local-docs/doc-create.md`
   - `doc-read` → `local-docs/doc-read.md`
   - `doc-update` → `local-docs/doc-update.md`
   - `doc-search` → `local-docs/doc-search.md`
   - `doc-list` → `local-docs/doc-list.md`
4. Confluence operations (only when `CONFLUENCE_ENABLED=true`):
   - `doc-publish` → `confluence-official/page-create.md` (new) or `confluence-official/page-update.md` (existing)
   - `doc-pull` → read from Confluence, write to local
   - `doc-diff` → compare local hash vs Confluence content
   - For all confluence-official operations:
     a. Run `core/ops:plugin-preflight` for `atlassian@claude-plugins-official`
     b. If plugin missing: STOP with install guidance
     c. Run `core/ops:mcp-preflight` with probe tool `mcp__atlassian__getConfluenceSpaces`
     d. If MCP unreachable: STOP with connectivity error
5. Check `DOC_BACKEND_OVERRIDE` — if set, use that backend instead of the default for the matched operation
6. If backend is `*-custom`: run `core/ops:mcp-preflight` with custom probe tool
7. Execute per the resolved primitive file's Implementation section

### Override Mechanism

Set `DOC_BACKEND_OVERRIDE` in `.claude/project-constants.md` to bypass the default backend:

- `confluence-custom` — use custom Confluence MCP server tools (requires scaffold/custom/ primitives)

When an override is set, `core/ops:mcp-preflight` validates the custom MCP server instead of checking for an official plugin.

## Core Operations

Always resolved to the local-docs backend, regardless of `CONFLUENCE_ENABLED`:

- `doc-create` — create a new local document
- `doc-read` — read local document content
- `doc-update` — update local document content
- `doc-search` — search local documents
- `doc-list` — list local documents

## Confluence Operations

Available only when `CONFLUENCE_ENABLED=true`:

- `doc-publish` — publish local document to Confluence (creates or updates remote page)
- `doc-pull` — pull Confluence page content into local storage
- `doc-diff` — compare local document hash against current Confluence content

## Extended Operations

| Operation     | Available In        |
| ------------- | ------------------- |
| page-children | confluence-official |
| label-add     | confluence-official |
| label-remove  | confluence-official |

## Used By

- design-document
- sync-context
- design-feature
- checkpoint-verify
