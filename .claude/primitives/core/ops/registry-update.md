---
name: core/ops:registry-update
description: Canonical read-modify-write procedure for the global project registry
version: "0.4.3"
---

# Registry Update

Canonical read-modify-write procedure for the global project registry at `$ECK_HOME/registry.yaml`.

> **ALL registry-writing skills MUST reference this primitive.** Any skill that modifies the registry without following this procedure is non-compliant. If the registry file does not exist, skip the update, log a warning, and continue skill execution — never hard-fail on a missing registry.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_key | string | Yes | The project key to update in the registry |
| fields | object | Yes | Skill-specific field updates to apply to the project entry |
| sync_entry | object | Yes | Entry to append to sync_history — ALL 4 fields required: `{ date, action, performed_by, summary }` |
| audit_result | object | No | If updating last_audit, include health_score to auto-set audit_status |
| pull_candidates_new | array | No | New pull_candidates from an audit — merged with existing using status lifecycle |

## Field Tiers

Every project entry uses a 3-tier field classification. Writers MUST respect these tiers when creating or updating entries.

### Tier 1 — Identity (required at creation by ALL writers)

| Field | Type | Constraint |
|-------|------|------------|
| `project_name` | string | Required |
| `project_path` | string | Absolute path, must be unique across active entries |
| `project_key` | string | Must equal the YAML map key |
| `state` | enum | One of: `discovered`, `managed`, `archived` |
| `audit_status` | enum | One of: `pending`, `passing`, `failing`, `error` |
| `last_modified_at` | string | ISO-8601 date, set automatically on every write |

### Tier 2 — Configuration (required for `managed` state, `null` for `discovered`)

| Field | Type | Default |
|-------|------|---------|
| `tracker_type` | string\|null | `null` |
| `doc_platform` | string\|null | `null` |
| `divergence_policy` | string\|null | `"standard"` |
| `dev_rigor` | string\|null | `null` |
| `project_type` | string\|null | `null` |
| `learning_autonomy` | string\|null | `null` |
| `deployment` | block\|null | `null` for discovered; required block for managed |

### Tier 3 — Operational (always present, initialized to safe defaults)

| Field | Type | Default |
|-------|------|---------|
| `enrichment` | block | `{ tech_stack: null, last_enriched: null }` |
| `last_audit` | block | All-null defaults (date, report_path, health_score, health_grade, synced: 0, modified: 0, outdated: 0, missing: 0, custom: 0) |
| `pull_candidates` | array | `[]` |
| `sync_history` | array | `[]` |

### Deployment Block (when present)

```yaml
deployment:
  initial_deploy_date: "YYYY-MM-DD"
  deployed_by: "/eck:skill-name"
  template_version: "0.4.0"
  has_deployed_catalog: true|false
  start_project_completed: true|false
```

### Enrichment Block

```yaml
enrichment:
  tech_stack: null        # e.g., "Next.js + FastAPI + PostgreSQL"
  last_enriched: null     # ISO-8601 date of last start-project run
```

> **Note:** `features_planned` and `docs_created` have been removed from the enrichment block as of v0.4.1. These belong in project-level artifacts, not the global registry.

## State Machine

### Project Lifecycle States

| State | Meaning | Created By |
|-------|---------|------------|
| `discovered` | Found by audit, not yet managed | `audit-unmanaged-project` only |
| `managed` | Actively tracked and maintained | `new-project`, `migrate-project` |
| `archived` | No longer actively monitored | `archive-project` |

### Valid State Transitions

| From | To | Trigger |
|------|-----|---------|
| `discovered` | `managed` | `/eck:migrate-project` |
| `discovered` | `archived` | `/eck:archive-project` |
| `managed` | `archived` | `/eck:archive-project` |
| `archived` | `managed` | `/eck:restore-project` |

**No other transitions are valid.** If a skill attempts to write a `state` value that violates this table, log an error and skip the state change. The rest of the registry update may proceed.

### audit_status (orthogonal axis)

| Status | Meaning |
|--------|---------|
| `pending` | Initial state, or post-update awaiting re-audit |
| `passing` | `health_score >= 75` |
| `failing` | `health_score < 75` |
| `error` | Unrecoverable audit error |

Staleness is NOT stored — computed at read time: `is_stale = (today - last_audit.date) > 7 days`

## Implementation

### 1. Read

```
Load $ECK_HOME/registry.yaml
If file does not exist → set skipped=true, log warning, continue skill execution
If file cannot be parsed → set skipped=true, log warning, continue skill execution
Verify schema_version field exists (accept schema_version or version for compat)
```

### 1.5. Conflict Detection

**For new project entries only** (action is `initial-deploy` or creating a previously non-existent key):

1. **Key conflict:** If `projects.{project_key}` already exists AND the entry's `state` is NOT `archived`:
   - STOP with error: `KEY_CONFLICT` — "Project key '{project_key}' is already registered at {existing_project_path}. Use a different PROJECT_KEY, run /eck:update-project to update, or /eck:archive-project to archive the old entry first."

2. **Path conflict:** Scan ALL existing entries for `project_path == new entry's project_path`:
   - If match found with `state` = `discovered` or `managed` → STOP with error: `PATH_CONFLICT` — "Project '{existing_key}' is already registered at this path. Use /eck:audit-current-project to update it, or /eck:archive-project {existing_key} first."
   - If match found with `state` = `archived` → log warning: "An archived project at this path exists ({existing_key}). Proceeding with new entry." Continue.

3. **Key-field consistency:** If `projects.{project_key}.project_key` exists and does not equal `{project_key}`, reject with `REGISTRY_MALFORMED`.

### 2. Modify

Apply skill-specific changes to the project entry under `projects.{project_key}`.

**Creating new entries:**

Only these skills may create new project entries:
- `/eck:new-project` — creates with `state: "managed"`, all Tier 1 + Tier 2 + Tier 3 fields
- `/eck:audit-unmanaged-project` — creates with `state: "discovered"`, Tier 1 required, Tier 2 fields set to `null`
- `/eck:migrate-project` — creates with `state: "managed"` (when no prior entry exists)

All other skills that encounter a missing project entry MUST NOT create it. Instead, log a warning: "Project '{project_key}' not found in registry. Run /eck:new-project or /eck:audit-unmanaged-project first." and skip the registry update.

**Updating existing entries:**

Update only the fields relevant to the current operation. Always set `last_modified_at` to the current ISO-8601 date.

### 2.5. Validate State Transition

If the `state` field is being changed:

1. Read the current `state` value from the existing entry
2. Check the transition against the Valid State Transitions table above
3. If the transition is NOT in the table → log error: `INVALID_TRANSITION` — "Cannot transition from '{current}' to '{new}'. Skipping state change." Apply all other field updates normally.

### 3. Set audit_status

When `audit_result` is provided:
- `health_score >= 75` → set `audit_status: "passing"`
- `health_score < 75` → set `audit_status: "failing"`
- Unrecoverable error during audit → set `audit_status: "error"`

### 4. Append sync_history

> **MANDATORY — never skip this step.** Every registry write MUST append exactly one sync_history entry. Omitting this step causes silent audit trail gaps that accumulate across operations.

Every `sync_entry` MUST contain ALL four fields. No exceptions:

```yaml
- date: "{ISO-8601 date}"
  action: "{operation-name}"
  performed_by: "{/eck:skill-name or /skill-name}"
  summary: "{one-sentence description of what changed}"
```

| Field | Required | Format | Example |
|-------|----------|--------|---------|
| `date` | Yes | ISO-8601 date (YYYY-MM-DD) | `"2026-03-08"` |
| `action` | Yes | Short operation name | `"audit"`, `"migrate"`, `"initial-deploy"` |
| `performed_by` | Yes | Skill name with prefix | `"/eck:audit-current-project"` |
| `summary` | Yes | One sentence | `"Health score: 85, 2 improvements found"` |

**Dedup guard:** If the last entry in `sync_history` has the same `action` AND `performed_by` AND the `date` matches today, skip the append. This prevents duplicate entries from retried operations.

### 4.5. Merge pull_candidates

When `pull_candidates_new` is provided (from an audit operation):

**Do NOT replace the array wholesale.** Merge using this procedure:

1. For each candidate in `pull_candidates_new`:
   - If a matching `file` entry already exists in `pull_candidates`:
     - If existing entry's `status` is `pending` → update `description`, `type`, `confidence`, set `last_seen` to today
     - If existing entry's `status` is NOT `pending` (reviewed/submitted/pulled/rejected) → preserve existing entry unchanged, only update `last_seen`
   - If no matching `file` exists → append with `status: "pending"`, `first_seen: today`, `last_seen: today`

2. For existing entries whose `file` is NOT in `pull_candidates_new`:
   - If `status` is `pending` → remove (no longer detected as a candidate)
   - If `status` is NOT `pending` → preserve (user has reviewed/acted on it)

**Pull candidate entry schema:**

```yaml
- file: ".claude/skills/design-feature/SKILL.md"
  type: improvement|project-specific|regression
  confidence: high|medium|low
  description: "Added risk-gate phase that upstream lacks"
  status: pending|reviewed|submitted|pulled|rejected
  first_seen: "YYYY-MM-DD"
  last_seen: "YYYY-MM-DD"
```

### 5. Recompute project_summary

> **MANDATORY — never skip this step.** Every registry write MUST recompute `project_summary`. Skipping causes the dashboard metrics in `/eck:project-status` to silently drift from reality. This step is deterministic — running it multiple times produces identical results.

Iterate all projects and recompute:

- `total_projects` — count of all project entries
- `active_projects` — count where `state != "archived"`
- `last_project_audit` — most recent `last_audit.date` across all projects
- `pull_candidates_total` — sum of all `pull_candidates` array lengths (all statuses)
- `pull_candidates_pending` — sum of `pull_candidates` entries where `status == "pending"`
- `health_distribution` — count projects by grade bucket (A: 90-100, B: 80-89, C: 70-79, D: 60-69, F: <60)
- `health_stats` — `average`, `median`, `highest`, `lowest` of all non-null health scores
- `by_tracker` — count projects grouped by `tracker_type`
- `by_platform` — count projects grouped by `doc_platform`
- `by_template_version` — count projects grouped by `deployment.template_version`
- `totals` — sum `synced`, `modified`, `outdated`, `missing`, `custom` across all `last_audit` blocks
- `projects_with_deployed_catalog` — count where `deployment.has_deployed_catalog == true`

### 5.5. Backup

Before writing, create a backup of the current registry:

```
Copy registry.yaml → registry.yaml.bak (overwrite previous backup)
```

This provides single-generation recovery. If both `registry.yaml` and `registry.yaml.bak` are corrupt, the registry can be rebuilt by running `/eck:audit-unmanaged-project` on each project directory.

### 6. Atomic Write

```
Write updated YAML to registry.yaml.tmp
Move (rename) registry.yaml.tmp → registry.yaml
```

If an orphaned `registry.yaml.tmp` exists from a previous failed write, remove it before writing.

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Registry was updated successfully |
| skipped | boolean | Registry update was skipped (file missing or malformed) |
| project_key | string | The project key that was updated |
| summary_recomputed | boolean | Whether project_summary was recomputed |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| REGISTRY_MISSING | Registry file does not exist | Skip update, log info, continue skill |
| REGISTRY_MALFORMED | Registry file cannot be parsed or key-field mismatch | Skip update, log warning, continue skill |
| ATOMIC_WRITE_FAILED | Temp file write or rename failed | Log error, leave original intact |
| KEY_CONFLICT | project_key already registered (active entry) | Stop, report to user |
| PATH_CONFLICT | project_path already registered (active entry) | Stop, report to user |
| INVALID_TRANSITION | State change violates the transitions table | Skip state change, apply other updates |

## Used By

### Writers

- new-project (Step 13: register new managed project)
- audit-unmanaged-project (Stage 8: register discovered project or update existing)
- audit-current-project (Stage 5.2: update health and pull_candidates)
- migrate-project (Stage 4: transition state discovered→managed)
- update-project (Stage 7: set audit_status pending after template change)
- start-project (Stage 10.2: write enrichment data)
- audit-security (Stage 6: append security audit to sync_history)
- pull-from-global-catalog (Stage 9: append sync_history)
- pull-from-user-catalog (Stage 7: append sync_history)
- submit-to-repo (Stage 8: append sync_history per source project)
- deploy (final phase: append deployment event to sync_history)
- validate (final phase: append validation outcome to sync_history)
- pull-from-standards (final phase: append standards sync to sync_history)
- refresh-project-catalog (final phase: append catalog refresh to sync_history)
- archive-project (Stage 2: transition state to archived)
- restore-project (Stage 2: transition state archived→managed)

### Readers (no write)

- project-status (Stage 2-3: dashboard render, per-project detail)
- push-to-user-catalog (Stage 2: cross-project dedup via pull_candidates)
- evolv-statusline.js hook (readRegistryProject: devRigor, projectType, learningAutonomy, state, auditStatus, staleness)
