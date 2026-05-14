---
name: core/validation:type-safety
description: Enforce type safety rules
version: "0.4.0"
---

# Type Safety

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file_path | string | Yes | Path to file to validate |
| language | string | Yes | Language: `python` or `typescript` |

## Implementation

TypeScript: Check for `any` types

```bash
grep -n ": any" <file_path>
```

Python: Check for missing type hints

```bash
grep -n "def.*)" <file_path> | grep -v "->"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| violations | array | Type safety violations with file, line, and description |
| violation_count | number | Total number of violations |
| verdict | string | `PASS` (zero violations) or `FAIL` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| FILE_NOT_FOUND | `file_path` does not exist | Halt and report missing file |
| INVALID_LANGUAGE | `language` is not `python` or `typescript` | Halt and report invalid parameter |

## Used By

- `validate-code`
- `validate-quality`
