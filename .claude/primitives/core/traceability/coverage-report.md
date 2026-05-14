---
name: core/traceability:coverage-report
description: Scan lifecycle documents and compute per-AC-ID coverage matrix across specify, plan, develop, and validate phases
version: "0.4.0"
---

# traceability:coverage-report

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| feature_slug | string | Yes | kebab-case feature directory name under `docs/` |
| docs_path | string | Yes | Absolute path to `docs/{feature}/` directory |

## Implementation

Scan all lifecycle documents for a feature and aggregate per-AC-ID status into a coverage matrix. This primitive is read-only — it does not modify any files.

### Data Sources

Scan these documents in order. Missing documents are noted as gaps, not errors.

| Document | Location | Extracts |
|----------|----------|----------|
| FRD.md | `docs/{feature}/FRD.md` | AC table (ID, Criterion, Status), Retired rows |
| TASKS.md | `docs/{feature}/../TASKS.md` or `docs/{feature}/TASKS.md` | AC Coverage table (AC-ID → Task mapping), Task table (Task → Status) |
| DEV-NOTES.md | `docs/{feature}/DEV-NOTES.md` or `docs/{feature}/../develop/DEV-NOTES.md` | AC Coverage table (Task → AC-IDs Covered), Uncovered AC table |
| VALIDATION.md | `docs/{feature}/VALIDATION.md` or `docs/{feature}/../validate/VALIDATION.md` | AC Checklist (AC-ID → Result: Pass/Fail/Partial) |

### Scanning Protocol

1. **Read FRD.md** — Parse the `## Acceptance Criteria` table. For each row, extract:
   - `AC-ID`: the identifier (e.g., AC-1)
   - `Criterion`: the criterion text (truncated to 40 chars for display)
   - `Status`: Pending, Pass, Fail, or Retired

2. **Read TASKS.md** — Parse the `### Acceptance Criteria Coverage` table and the `## Tasks` table:
   - Map each AC-ID to its covering task(s)
   - Determine task status from the Tasks table (Open, In Progress, Done)
   - An AC-ID is "Planned" if it appears in the coverage table with at least one task

3. **Read DEV-NOTES.md** — Parse the `## AC Coverage` table:
   - Map each task to the AC-IDs it implemented
   - An AC-ID is "Implemented" if at least one covering task appears in the dev notes AC Coverage table
   - Check the `### Uncovered AC` table for explicitly uncovered criteria

4. **Read VALIDATION.md** — Parse the `## AC Checklist` table:
   - Map each AC-ID to its verification result (Pass, Fail, Partial)
   - An AC-ID is "Tested" if it appears in the checklist with any result

### Coverage Matrix Computation

For each AC-ID found in FRD.md, compute lifecycle status:

| Column | Symbol | Condition |
|--------|--------|-----------|
| Specified | `✓` | AC-ID exists in FRD.md with non-Retired status |
| Planned | `✓` | AC-ID mapped to at least one task in TASKS.md |
| Implemented | `✓` | AC-ID covered by a task in DEV-NOTES.md AC Coverage |
| Tested | `✓` | AC-ID has Pass result in VALIDATION.md |
| (partial) | `◐` | AC-ID has Partial or in-progress status |
| (missing) | `-` | Document not found or AC-ID not referenced |
| (retired) | `⊘` | AC-ID has Retired status in FRD.md |

### Summary Metrics

Compute these aggregate metrics (exclude Retired from denominators):

- **Total AC-IDs**: count of all AC-IDs in FRD.md
- **Active**: total minus retired
- **Retired**: count of Retired status
- **Planned**: count of active AC-IDs with task mapping / active count
- **Implemented**: count of active AC-IDs with dev coverage / active count
- **Tested**: count of active AC-IDs with Pass result / active count
- **Coverage score**: percentage of active AC-IDs that are fully traced (specified + planned + implemented + tested)
- **Gaps**: list of active AC-IDs missing from any lifecycle phase

## Output

| Field | Type | Description |
|-------|------|-------------|
| matrix | array | Per-AC-ID rows with Specified/Planned/Implemented/Tested columns |
| summary | object | Aggregate metrics (total, active, retired, planned, implemented, tested, coverage_score) |
| gaps | array | AC-IDs not fully traced across all lifecycle phases |
| document_status | array | Which lifecycle documents were found and how many AC-IDs each referenced |

The output document format:

```markdown
## AC-ID Coverage Matrix

| AC-ID | Criterion | Specified | Planned | Implemented | Tested | Status |
|-------|-----------|-----------|---------|-------------|--------|--------|
| AC-1 | {truncated criterion} | ✓ | ✓ | ✓ | ✓ | Pass |
| AC-2 | {truncated criterion} | ✓ | ✓ | ◐ | - | In Progress |
| AC-3 | {truncated criterion} | ✓ | - | - | - | Gap |
| AC-4 | {truncated criterion} | ⊘ | - | - | - | Retired |

## Coverage Summary

- Total: {N} AC-IDs ({active} active, {retired} retired)
- Planned: {X}/{active} ({pct}%)
- Implemented: {Y}/{active} ({pct}%)
- Tested: {Z}/{active} ({pct}%)
- Full coverage: {W}/{active} ({pct}%)
- Gaps: {list of AC-IDs not fully traced}

## Document Status

| Document | Found | AC-IDs Referenced |
|----------|-------|-------------------|
| FRD.md | ✓ / - | {count} |
| TASKS.md | ✓ / - | {count} |
| DEV-NOTES.md | ✓ / - | {count} |
| VALIDATION.md | ✓ / - | {count} |
```

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| DOCS_PATH_NOT_FOUND | `docs_path` directory does not exist | Halt and report missing path |
| NO_FRD_MD | FRD.md not found (required anchor document) | Halt — cannot compute matrix without AC-ID source |
| PARSE_ERROR | A lifecycle document has malformed AC tables | Note the document as unparseable, continue with remaining documents |

## Used By

- `eck:ac-coverage` (global skill for AC-ID traceability dashboard)
