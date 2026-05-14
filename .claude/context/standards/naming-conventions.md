# Naming Conventions

Authoritative naming specification for all assets in the evolv-coder-kit ecosystem.

**Version:** 0.4.3

---

## Skill Naming

| Scope                             | Pattern                     | Example                                        |
| --------------------------------- | --------------------------- | ---------------------------------------------- |
| Global                            | `eck:<skill>`               | `eck:design`, `eck:deploy`                     |
| Project T1 (orchestrator-aligned) | `<PK>:<t1-verb>-<scope>`    | `myapp:design-feature`, `myapp:dev-sprint`     |
| Project T2 (functional)           | `<PK>:<t1-verb>-<function>` | `myapp:design-research`, `myapp:validate-code` |
| Project utility                   | `<PK>:<descriptive-name>`   | `myapp:git-status`, `myapp:learn`              |
| Config-only                       | `<PK>:<platform>`           | `myapp:jira`, `myapp:confluence`               |

Where `<PK>` = `wa` from `project-constants.md`.

---

## Primitive Naming

| Pattern                                    | Example                                                           | Notes                                           |
| ------------------------------------------ | ----------------------------------------------------------------- | ----------------------------------------------- |
| Abstract: `<domain>:<operation>`           | `tracker:issue-create`, `docs:doc-create`                         | Skills use this — routed via `_router.md`       |
| Concrete: `<domain>/<backend>:<operation>` | `tracker/jira-official:issue-create`, `cloud/aws/storage:s3-list` | Router output — used in Implementation sections |
| Core: `core/<namespace>:<action>`          | `core/ops:health-check`, `core/review:code-review`                | No routing needed — always deployed             |
| Legacy alias: `<old-namespace>:<action>`   | `jira-official:issue-create`                                      | Backward compat — resolved via `_index.yaml`    |

---

## Agent Naming

| Pattern           | Example                                   | Notes                                               |
| ----------------- | ----------------------------------------- | --------------------------------------------------- |
| `<domain>-<role>` | `backend-developer`, `frontend-architect` | No namespace prefix — agents are referenced by name |
| Language-specific | `go-developer`, `rust-developer`          | Domain = language                                   |
| Cross-cutting     | `security-specialist`, `technical-writer` | Domain = discipline                                 |

---

## File Naming

| Asset              | Filename             | Convention                                    |
| ------------------ | -------------------- | --------------------------------------------- |
| Skills (all tiers) | `SKILL.md`           | **Uppercase** (Claude Code official standard) |
| Primitives         | `<action>.md`        | Lowercase kebab-case                          |
| Agents             | `<domain>-<role>.md` | Lowercase kebab-case                          |
| Directories        | `<name>/`            | Lowercase kebab-case                          |

---

## Documentation Naming

### Directory Naming

| Type               | Pattern              | Example                                          |
| ------------------ | -------------------- | ------------------------------------------------ |
| Feature docs       | `<KEY>-<id>-<slug>/` | `ECK-032-ab-testing/`, `WA-001-weather-cli/`     |
| Feature (fallback) | `FEAT-<id>-<slug>/`  | `FEAT-1-discovery-system/` (when no project key) |
| Category docs      | `<category>/`        | `adrs/`, `project/`                              |
| QA subdirectory    | `qa/`                | `ECK-032-ab-testing/qa/`                         |

Feature directories are named by project key, sequential ID, and slug. The `<KEY>` comes from `features.json` `project_key`. Category directories (adrs/, project/) use descriptive names without numbers. Legacy `feat-NN-*` and `FEAT-NNN-*` directories are grandfathered.

### Document File Naming

| Type                    | Pattern                        | Example                               |
| ----------------------- | ------------------------------ | ------------------------------------- |
| Functional requirements | `FRD.md`                       | `docs/{feature}/FRD.md`               |
| Product requirements    | `PRD.md`                       | `docs/PRD.md`                         |
| Business requirements   | `BRD.md`                       | `docs/BRD.md`                         |
| Architecture            | `ARCHITECTURE.md`              | `docs/{feature}/ARCHITECTURE.md`      |
| Detailed design         | `DESIGN.md`                    | `docs/{feature}/DESIGN.md`            |
| Tasks breakdown         | `TASKS.md`                     | `docs/{feature}/TASKS.md`             |
| Architecture decisions  | `ADR-NNN-<topic>.md`           | `ADR-001-cli-packages.md`             |
| Research                | `RESEARCH.md`                  | `docs/{feature}/RESEARCH.md`          |
| Risk registers          | `RISK.md`                      | `docs/{feature}/RISK.md`              |
| QA plan                 | `QA-PLAN.md`                   | `docs/{feature}/QA-PLAN.md`           |
| Spec discovery          | `DISCOVERY.md`                 | `docs/{feature}/DISCOVERY.md`         |
| Design discovery        | `DESIGN-DISCOVERY.md`          | `docs/{feature}/DESIGN-DISCOVERY.md`  |
| API contracts           | `API-CONTRACT.md`              | `docs/{feature}/API-CONTRACT.md`      |
| Data schemas            | `DATA-SCHEMA.md`               | `docs/{feature}/DATA-SCHEMA.md`       |
| Sequence diagrams       | `SEQUENCES.md`                 | `docs/{feature}/SEQUENCES.md`         |
| Non-functional reqs     | `NFR.md`                       | `docs/{feature}/NFR.md`               |
| QA results              | `<descriptive>.md` (lowercase) | `accessibility.md`, `test-results.md` |
| Index                   | `INDEX.md`                     | `docs/INDEX.md`                       |

Document type prefixes are UPPERCASE. Topic suffixes are lowercase kebab-case.

---

## Frontmatter Requirements

### Version Field

- **Required** on ALL skills (global and project)
- Format: `version: "X.Y.Z"` (semver, quoted string)
- All versions baselined at `0.4.0`; modified skills updated to release version

### disable-model-invocation Field

- **Required** on ALL skills — default is `false` (both user and system can invoke)
- Set `true` only for skills restricted to user-only invocation

---

## Lifecycle Chain

The 5 T1 orchestrators form a spec-driven lifecycle chain:

```
eck:spec → eck:design → eck:develop → eck:validate → eck:deploy
```

Each orchestrator's final summary includes a "Next Step" pointing to the next in the chain.

---

## Stage Structure Standard

Every stage in T1 orchestrators and stage-based T2 sub-skills uses 4 mandatory subsections:

```markdown
## Stage N: Name

### Inputs

- What this stage reads

### Activities

- Numbered steps

### Outputs

- Artifacts produced

### Exit Criteria

- What must be true before next stage
```

---

## Tier Definitions

| Tier          | Role                                                   | Examples                                                              |
| ------------- | ------------------------------------------------------ | --------------------------------------------------------------------- |
| T1            | Global orchestrators — canonical entry points          | `eck:spec`, `eck:design`, `eck:develop`, `eck:validate`, `eck:deploy` |
| T2 Scope      | Scope-level coordination within a T1 domain            | `design-feature`, `dev-sprint`                                        |
| T2 Functional | Single-concern sub-skills dispatched by T1 or T2 scope | `design-research`, `validate-code`, `dev-commit`                      |
| T3            | Primitives — atomic, reusable operations               | `git:commit`, `mode:read-dev-rigor`                                   |
