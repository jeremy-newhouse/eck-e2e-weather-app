# Documentation Directory Structure (Weather App)

> Condensed from evolv-coder-standards. Rules only, no tutorials.
> Run `/eck:pull-from-standards` to compile full standards from source.

## Overview

All project documentation lives under `docs/` in the project root. Feature
documentation uses a flat layout — all deliverables at the same level inside
each feature directory. This keeps paths simple and consistent across the
lifecycle chain (`spec → design → develop → validate → deploy`).

---

## Top-Level Layout

```
docs/
├── INDEX.md                          # Master table of contents (auto-updated by skills)
├── features/                         # Per-feature lifecycle docs
│   └── {KEY}-N-{slug}/            # Flat — all deliverables at same level
│       ├── FRD.md
│       ├── DISCOVERY.md
│       ├── RESEARCH.md
│       ├── DESIGN.md
│       ├── RISK.md
│       ├── QA-PLAN.md
│       ├── TASKS.md
│       ├── DESIGN-REVIEW.md
│       ├── DEV-NOTES.md
│       ├── VALIDATION.md
│       ├── RELEASE.md
│       └── DEPLOY-RECORD.md
├── project/                          # Project-wide documents
│   ├── VISION.md                    # Project vision, problem space, roadmap
│   ├── BRD.md                       # Business requirements, success metrics
│   ├── PRD.md                       # Product requirements, user stories
│   ├── ARCHITECTURE.md              # System architecture, components
│   ├── TECH-STACK.md                # Technology decisions and log
│   ├── BACKLOG.md                   # Feature backlog
│   ├── archive/                     # Superseded/archived docs
│   ├── reference/                   # Reference materials
│   └── research/                    # Research docs
├── adrs/                            # Architecture Decision Records
├── guides/                          # Authoring guides, workflow docs, contributing
└── glossary.md
```

---

## Project Documents (`docs/project/`)

High-level documents that define what is being built and why. Created by
`/start-project` and updated throughout the project lifecycle.

| Document          | Purpose                                              | Created By         |
| ----------------- | ---------------------------------------------------- | ------------------ |
| `VISION.md`       | Project vision, problem space, target users, roadmap | `/start-project`   |
| `BRD.md`          | Business requirements and success metrics            | `/design-document` |
| `PRD.md`          | Product requirements, user stories, personas         | `/design-document` |
| `ARCHITECTURE.md` | System architecture, components, infrastructure      | `/design-arch`     |
| `TECH-STACK.md`   | Technology decisions and decision log                | `/start-project`   |
| `BACKLOG.md`      | Feature backlog with priorities and sizing           | `/start-project`   |

---

## Feature Documents (`docs/features/<KEY>-N-{slug}/`)

Each feature gets its own directory under `docs/features/`, prefixed with its
feature ID for traceability. All deliverables live at the same level — no phase
subdirectories.

### Directory Naming

- Pattern: `WA-{N}-{slug}` (e.g., `ECK-1-user-auth`, `WX-32-weather-dashboard`)
- `WA` comes from `project-constants.md` `PROJECT_KEY` value
- `{N}` is the feature number from `features.json` (no zero-padding, matches JIRA/GitHub/Linear conventions)
- `{slug}` is kebab-case derived from the feature name
- This matches the branch naming convention (`feat/<KEY>-N-{slug}`)

### Feature Document Listing

```
docs/features/{KEY}-N-{slug}/
├── FRD.md                    # Scope definition (problem, goals, out-of-scope)
├── DISCOVERY.md              # Requirements discovery notes
├── RESEARCH.md               # Context, ecosystem, feasibility research
├── DESIGN.md                 # Architecture design, component diagrams
├── DESIGN-SPEC.md            # Technical specification (API, DB, sequences)
├── RISK.md                   # Risk assessment
├── QA-PLAN.md                # Quality assurance test plan
├── TASKS.md                  # Task breakdown with dependency ordering
├── DESIGN-REVIEW.md          # Design completeness and AC-ID addressability gate result
├── DEV-NOTES.md              # Implementation notes, decisions during coding
├── DEVELOP-REVIEW.md         # Task completion, test passing, code quality gate result
├── VALIDATION.md             # Test results, quality gate outcomes
├── VALIDATE-REVIEW.md        # Unified validation verdict gate result
├── RELEASE.md                # Release notes
├── DEPLOY-RECORD.md          # Deployment record (env, date, status)
└── DEPLOY-REVIEW.md          # Stop-point-aware deployment readiness gate result
```

### Skills That Generate Feature Documents

| Lifecycle Phase | Skill               | Output File                      |
| --------------- | ------------------- | -------------------------------- |
| Spec            | `/spec-scope`       | `FRD.md`                         |
| Spec            | `/spec-discovery`   | `DISCOVERY.md`                   |
| Spec            | `/spec-review`      | `SPEC-REVIEW.md`                 |
| Design          | `/design-research`  | `RESEARCH.md`                    |
| Design          | `/design-arch`      | `DESIGN.md`                      |
| Design          | `/design-specs`     | `DESIGN-SPEC.md`                 |
| Design          | `/design-discovery` | `DESIGN-DISCOVERY.md`            |
| Design          | `/design-risk`      | `RISK.md`                        |
| Design          | `/design-qa`        | `QA-PLAN.md`                     |
| Design          | `/design-feature`   | Full design suite                |
| Design          | `/design-review`    | `DESIGN-REVIEW.md`               |
| Develop         | `/dev-plan`         | `TASKS.md`                       |
| Develop         | `/develop-review`   | `DEVELOP-REVIEW.md`              |
| Validate        | `/validate-review`  | `VALIDATE-REVIEW.md`             |
| Deploy          | `/deploy-release`   | `RELEASE.md`, `DEPLOY-RECORD.md` |
| Deploy          | `/deploy-review`    | `DEPLOY-REVIEW.md`               |

---

## Architecture Decision Records (`docs/adrs/`)

One file per significant architectural decision.

| Convention    | Rule                                                       |
| ------------- | ---------------------------------------------------------- |
| Filename      | `ADR-NNN-{short-title}.md` (e.g., `ADR-001-tech-stack.md`) |
| Numbering     | Zero-padded 3-digit, sequential                            |
| Created by    | `/design-adr`                                              |
| Status values | `draft`, `accepted`, `superseded`, `deprecated`            |

---

## Documentation Index (`docs/INDEX.md`)

The master table of contents for all project documentation. Initialized by
`/start-project` from the `INDEX.md.template`.

### Auto-Generated Sections

Skills update INDEX.md automatically using marker comments:

```markdown
<!-- AUTO-GENERATED: feature-list-start -->

...feature entries...

<!-- AUTO-GENERATED: feature-list-end -->

<!-- AUTO-GENERATED: adr-list-start -->

...ADR entries...

<!-- AUTO-GENERATED: adr-list-end -->

<!-- AUTO-GENERATED: deploy-list-start -->

...deployment records...

<!-- AUTO-GENERATED: deploy-list-end -->
```

Do not edit content between markers — it will be overwritten by skills.

---

## FRD.md vs DESIGN.md

These two documents serve different purposes at different lifecycle phases:

| Document    | Phase  | Purpose                       | Contains                                                       |
| ----------- | ------ | ----------------------------- | -------------------------------------------------------------- |
| `FRD.md`    | Spec   | **What** to build and **why** | Problem statement, goals, scope boundaries, out-of-scope       |
| `DESIGN.md` | Design | **How** to build it           | API contracts, DB schemas, sequence diagrams, technical detail |

`FRD.md` is input to the design phase. `DESIGN.md` is output from it.

---

## Document File Naming Rules

| Convention     | Rule                                                                                |
| -------------- | ----------------------------------------------------------------------------------- |
| Type prefix    | UPPERCASE (`SPEC-`, `PRD-`, `ADR-`, `DESIGN-`, `RESEARCH-`, `RISKS-`, `INTERVIEW-`) |
| Topic suffix   | Lowercase kebab-case (`SPEC-api-contracts.md`)                                      |
| Lifecycle docs | No topic suffix needed (`FRD.md`, `TASKS.md`, `DESIGN.md`, `ARCHITECTURE.md`)       |
| QA results     | Lowercase descriptive (`accessibility.md`, `test-results.md`)                       |

---

## Document Frontmatter

All project documents use YAML frontmatter:

```yaml
---
title: "{Document Title}"
date: "{YYYY-MM-DD}"
status: "draft"
feature: "{feature-slug}"
author: "{Author}"
version: "0.7.0"
type: "{document-type}"
---
```

### Status Values

| Status       | Meaning                                          | Synced to context? |
| ------------ | ------------------------------------------------ | ------------------ |
| `draft`      | Work in progress, not reviewed                   | No                 |
| `accepted`   | Reviewed and active                              | **Yes**            |
| `superseded` | Replaced by a newer document (link to successor) | No                 |
| `deprecated` | No longer relevant, not replaced                 | No                 |

A superseded document must link to its replacement.

---

## Related Documents

- `documentation-standards.md` — content and formatting rules for documents
- `naming-conventions.md` — naming rules for skills, primitives, agents, and files
