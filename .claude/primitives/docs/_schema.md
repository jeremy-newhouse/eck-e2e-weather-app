---
name: docs:schema
description: Interface contract for documentation domain operations
version: "0.5.0"
type: schema
---

# Docs Schema

Defines the common interface for documentation operations across all backends.

## doc-create

| Parameter | Type     | Required | Description              |
| --------- | -------- | -------- | ------------------------ |
| title     | string   | Yes      | Document title           |
| content   | string   | Yes      | Document body (markdown) |
| parent    | string   | No       | Parent document/space ID |
| labels    | string[] | No       | Labels/tags to apply     |

**Returns:** `id` (string), `url` (string)

**Backend parameter mapping:**

- Confluence: `parent` -> `parent_id` or `space_key`, `content` -> ADF conversion
- Local: `title` -> filename derivation, `parent` -> directory path

**Confluence frontmatter written on first publish:**

```yaml
confluence:
  page_id: 12345 # Confluence page ID (set after first publish)
  space_key: ECK # Confluence space key
  last_hash: abc123def # Content hash at last publish
  last_published: 2026-03-22T12:00:00Z # ISO timestamp of last publish
```

- **Optional** — only populated after the first successful publish to Confluence.
- Written exclusively by the `confluence-publish` skill; never written by design skills directly.
- Read by `confluence-reconcile` for drift detection (compares `last_hash` against current content hash).
- Ignored by `sync-context`, which only reads `status` and `type` from frontmatter.

## doc-read

| Parameter | Type   | Required | Description         |
| --------- | ------ | -------- | ------------------- |
| id        | string | Yes      | Document identifier |

**Returns:** `id`, `title`, `content`, `url`, `last_modified`

## doc-search

| Parameter | Type   | Required | Description                   |
| --------- | ------ | -------- | ----------------------------- |
| query     | string | Yes      | Search query                  |
| max       | number | No       | Maximum results (default: 10) |

**Returns:** Array of `{ id, title, excerpt, url }`

## doc-update

| Parameter | Type   | Required | Description         |
| --------- | ------ | -------- | ------------------- |
| id        | string | Yes      | Document identifier |
| content   | string | Yes      | Updated content     |
| title     | string | No       | Updated title       |

**Returns:** `id`, `url`, `version`

## Used By

- design-document
- sync-context
- design-feature
