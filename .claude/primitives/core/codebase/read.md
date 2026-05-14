---
name: core/codebase:read
description: Read file contents
version: "0.4.0"
---

# Codebase Read

Read the contents of a file, optionally in chunks for large files.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file_path | string | Yes | Absolute path to the file to read |
| offset | integer | No | Line number to start reading from |
| limit | integer | No | Maximum number of lines to read |

## Implementation

Uses Claude Code Read tool.

For large files, use `offset` and `limit` parameters to read in chunks.

## Output

| Field | Type | Description |
|-------|------|-------------|
| contents | string | Raw file text, optionally bounded by `offset` and `limit` |
| line_count | integer | Total number of lines in the file |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| FILE_NOT_FOUND | Path does not exist on disk | Confirm the absolute path; use `codebase:explore` to locate the file |
| PERMISSION_DENIED | Process lacks read access | Check file permissions before retrying |
| OFFSET_OUT_OF_RANGE | `offset` exceeds file length | Read without `offset` first to determine actual line count |

## Used By

- All skills (universal file-reading primitive)
