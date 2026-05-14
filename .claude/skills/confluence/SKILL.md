---
name: wa:confluence
version: "0.7.4"
description: Confluence page management for the {CONFLUENCE_SPACE_KEY} space
disable-model-invocation: false
---

# Confluence Skill

Config-only skill — manage Confluence pages in the <CONFLUENCE_SPACE_KEY> space. Action: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:confluence create "Page Title" --label specapi    # Create a labeled page
/wa:confluence search "authentication"                # Search space for pages
/wa:confluence label 12345 accepted specfeat           # Add labels to a page
```

## Space Constants

- Space Key: <CONFLUENCE_SPACE_KEY>
- Space ID: <CONFLUENCE_SPACE_ID>
- Homepage ID: <CONFLUENCE_HOMEPAGE_ID>

## Label Taxonomy

### Status Labels (mutually exclusive)

- `accepted` - Reviewed and active, synced to agent context
- `draft` - Work in progress, not synced
- `superseded` - Replaced by a newer document, not synced
- `deprecated` - No longer relevant, not synced

### Type Labels

- `architecture` - System architecture docs
- `prd` - Product requirements
- `datamodel` - Data model documentation
- `specapi` - API specifications
- `specfeat` - Feature specifications
- `specdesign` - Design specifications
- `specdata` - Data specifications
- `adr` - Architecture Decision Records
- `llm` - LLM/AI-specific specs
- `specifications` - Spec index pages

## Rules

- **MUST** add both a status label AND a type label on every page operation. Do NOT create or update a page without both label types.
- Use `accepted` for pages that agents MUST reference
- Page titles MUST follow: "Weather App - {Title}" for top-level, "SPEC-<TYPE>-<NUM>: {Title}" for specs
