# Skill Authoring Guide

Guide for creating and customizing workflow skills (slash commands).

**Version:** 0.4.0

---

## Overview

Skills are workflow automations invoked via slash commands. Each skill:

- Defines a multi-step workflow with numbered phases
- Uses the Inputs/Activities/Outputs/Exit Criteria structure per stage
- Has tool health checks and context recovery
- References shared primitives for common operations
- May orchestrate agents or dispatch sub-skills

---

## Lifecycle Chain

The 5 T1 orchestrators form a spec-driven lifecycle:

```
eck:spec → eck:design → eck:develop → eck:validate → eck:deploy
```

---

## Skill Catalog

### T1 Global Orchestrators (5)

| Skill    | Command         | Purpose                              |
| -------- | --------------- | ------------------------------------ |
| spec     | `/eck:spec`     | Requirements + acceptance criteria   |
| design   | `/eck:design`   | Research, design, specs, risk, tasks |
| develop  | `/eck:develop`  | Wave execution with fresh contexts   |
| validate | `/eck:validate` | Quality, code review, security, UAT  |
| deploy   | `/eck:deploy`   | Branch, commit, PR, merge, release   |

### T2 Specify Sub-skills (4)

| Skill          | Command           | Purpose                                |
| -------------- | ----------------- | -------------------------------------- |
| spec-scope     | `/spec-scope`     | Problem statement, goals, out-of-scope |
| spec-discovery | `/spec-discovery` | Collaborative requirements discovery   |
| spec-criteria  | `/spec-criteria`  | Acceptance criteria with AC-IDs        |
| spec-questions | `/spec-questions` | Open questions triage                  |

### T2 Design Sub-skills (10)

| Skill            | Command             | Purpose                                          |
| ---------------- | ------------------- | ------------------------------------------------ |
| design-feature   | `/design-feature`   | Combined design pipeline                         |
| design-research  | `/design-research`  | Online + KB research                             |
| design-arch      | `/design-arch`      | System architecture and service decomposition    |
| design-solution  | `/design-solution`  | Component design and UI/UX patterns              |
| design-specs     | `/design-specs`     | API contracts, DB schemas, sequence diagrams     |
| design-discovery | `/design-discovery` | Collaborative technical discovery (design phase) |
| design-qa        | `/design-qa`        | Quality assurance test plan                      |
| design-adr       | `/design-adr`       | Architecture Decision Records                    |
| design-document  | `/design-document`  | BRD, PRD, technical docs                         |
| design-risk      | `/design-risk`      | Risk assessment (GO/NO-GO)                       |
| dev-plan         | `/dev-plan`         | Task breakdown from design artifacts             |

### T2 Develop Sub-skills (6)

| Skill           | Command            | Purpose                            |
| --------------- | ------------------ | ---------------------------------- |
| dev-feature     | `/dev-feature`     | Execute all tasks under epic       |
| dev-feature-tdd | `/dev-feature-tdd` | TDD-enforced feature execution     |
| dev-task        | `/dev-task`        | Atomic task: TDD, develop, review  |
| dev-sprint      | `/dev-sprint`      | Multi-task tracker execution       |
| dev-simplify    | `/dev-simplify`    | Post-implementation simplification |
| dev-test        | `/dev-test`        | Test generation (TDD red phase)    |

### T2 Validate Sub-skills (5)

| Skill             | Command              | Purpose                       |
| ----------------- | -------------------- | ----------------------------- |
| validate-quality  | `/validate-quality`  | Lint, type checks, test suite |
| validate-code     | `/validate-code`     | Language-aware code review    |
| validate-security | `/validate-security` | Security + secret scanning    |
| validate-ci       | `/validate-ci`       | CI failure diagnosis          |
| validate-uat      | `/validate-uat`      | User acceptance testing       |

### T2 Deploy Sub-skills (9)

| Skill             | Command              | Purpose                  |
| ----------------- | -------------------- | ------------------------ |
| dev-branch        | `/dev-branch`        | Branch creation          |
| dev-commit        | `/dev-commit`        | Staged commit            |
| dev-push          | `/dev-push`          | Push to remote           |
| dev-pr            | `/dev-pr`            | PR creation              |
| validate-approval | `/validate-approval` | PR review gate           |
| validate-merge    | `/validate-merge`    | Merge + tracker update   |
| deploy-release    | `/deploy-release`    | Tag + changelog          |
| deploy-status     | `/deploy-status`     | Git status check         |
| deploy-tracker    | `/deploy-tracker`    | Tracker issue transition |

### Utility Skills

| Skill                   | Command                    | Purpose                     |
| ----------------------- | -------------------------- | --------------------------- |
| start-project           | `/start-project`           | Initial project scaffolding |
| git-flow                | `/git-flow`                | Git workflow operations     |
| git-status              | `/git-status`              | Git status display          |
| learn                   | `/learn`                   | Quick learning capture      |
| retrospective           | `/retrospective`           | Session analysis            |
| sync-context            | `/sync-context`            | Sync project docs           |
| confluence              | `/confluence`              | Confluence management       |
| jira                    | `/jira`                    | JIRA management             |
| evolve                  | `/evolve`                  | Self-improvement            |
| orchestrate             | `/orchestrate`             | Generic orchestration       |
| refresh-project-catalog | `/refresh-project-catalog` | Catalog refresh             |
| heuristic-status        | `/heuristic-status`        | Heuristic display           |

---

## Skill Structure

Every skill has a `SKILL.md` file (uppercase):

````markdown
---
name: skill-name
version: "0.4.0"
description: Brief description of what this skill does
disable-model-invocation: false
---

# Skill Name

[Purpose and overview]

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject       | Active Form        | Statusline |
| ----- | ------------- | ------------------ | ---------- |
| 1     | Stage 1: Name | Present-continuous | Name (1/N) |

## Statusline Stage Updates

At the start of each stage:

```bash
bash $ECK_HOME/update-stage.sh "Name (N/M)"
```
````

At skill completion (success or error):

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Usage

[Invocation syntax, flags, examples]

---

## Stage 1: Name

### Inputs

- What this stage reads

### Activities

1. Step-by-step workflow

### Outputs

- Artifacts produced

### Exit Criteria

- What must be true before next stage

---

## Error Handling

Follow the error handling pattern in the `output:error-handler` primitive.

---

## Related Documents

[Links to related skills, primitives, docs]

````

---

## Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| name | Yes | Skill identifier |
| version | Yes | Semver version (quoted string) |
| description | Yes | Brief description |
| disable-model-invocation | Yes | Always `true` — skills are prompt-only |

---

## Creating a New Skill

### 1. Create Directory

```bash
mkdir .claude/skills/my-skill
````

### 2. Create SKILL.md

Use the structure above. Required sections:

1. Frontmatter with all 4 fields
2. Title + description
3. Visual Framework reference
4. Task Registration table (with Statusline column)
5. Statusline Stage Updates
6. Usage section
7. Numbered phases with Inputs/Activities/Outputs/Exit Criteria
8. Error Handling reference
9. Related Documents

### 3. Define Workflow Stages

Structure each stage with 4 mandatory subsections:

- **Inputs** — what data/artifacts the stage reads
- **Activities** — numbered steps to perform
- **Outputs** — artifacts produced by the stage
- **Exit Criteria** — conditions that must be true before proceeding

### 4. Add to settings.local.json

```json
{
  "permissions": {
    "allow": ["Skill(my-skill)"]
  }
}
```

### 5. Add to project-catalog.yaml

```yaml
my-skill:
  version: "0.4.0"
  owner: "platform-team"
  model_tier: "sonnet"
  description: "What this skill does"
  invocable: true
  last_updated: "{DATE}"
```

---

## Best Practices

### Do

- Include tool health checks in Stage 1
- Document context recovery instructions
- Break into clear, numbered stages
- Use Inputs/Activities/Outputs/Exit Criteria in every stage
- Reference shared primitives — never inline their logic
- Validate outputs at each stage via Exit Criteria
- Keep statusline text ≤ 15 characters

### Don't

- Skip frontmatter fields (all 4 are required)
- Assume tools are available without health checks
- Create monolithic workflows without stage decomposition
- Use `skill.md` (lowercase) — always `SKILL.md`
- Inline visual framework rules — reference `output:visual-framework`
- Forget to reset statusline on completion

---

## Skill Tiers

| Tier          | Role                                             | Example                            |
| ------------- | ------------------------------------------------ | ---------------------------------- |
| T1 Global     | Orchestrators — canonical lifecycle entry points | `eck:spec`, `eck:design`           |
| T2 Scope      | Scope-level coordination within a T1 domain      | `design-feature`, `dev-sprint`     |
| T2 Functional | Single-concern sub-skills dispatched by T1       | `design-research`, `validate-code` |
| Config-only   | Platform configuration — exempt from phases      | `jira`, `confluence`               |

---

## Removing Skills

Remove skills you don't need:

```bash
rm -rf .claude/skills/validate-ci  # If no CI pipeline
```

Update `settings.local.json` to remove permissions and `project-catalog.yaml` to remove the entry.

---

## Related Documentation

- [Agent Authoring](../agents/README.md)
- [Naming Conventions](../context/standards/naming-conventions.md)
- [Visual Framework](../primitives/output/visual-framework.md)
- [Error Handler](../primitives/output/error-handler.md)
