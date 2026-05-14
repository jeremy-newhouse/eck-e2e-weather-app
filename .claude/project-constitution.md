# Weather App - Project Constitution

**Version**: 1.0.0
**Created**: <DATE>
**Last Updated**: <DATE>
**Status**: Draft
**Project**: Weather App
**Owner**: <OWNER_NAME>

---

## 1. Purpose & Scope

This document defines the governing principles, constraints, and quality standards for the Weather App project. It is the highest-priority authority in the source of truth hierarchy.

**What this document governs:** principles, constraints, and invariants that remain stable across the project lifecycle.

**What this document does not govern:** operational procedures (`CLAUDE.md`), component inventories (`project-catalog.yaml`), configuration values (`project-constants.md`), or feature specifications (`docs/`).

**Relationship to other documents:**

| Document                             | Governs                                      | Changes when                           |
| ------------------------------------ | -------------------------------------------- | -------------------------------------- |
| Constitution (this)                  | Principles, constraints, invariants          | Rarely — requires stakeholder approval |
| `CLAUDE.md`                          | Operational instructions, procedures         | Features or infrastructure change      |
| `project-constants.md`               | Pre-computed values for skills/agents        | Project configuration changes          |
| ECS standards                        | Normative coding standards, patterns         | Standards evolve                       |
| ADRs (`docs/adrs/`)                  | Architectural decisions with context         | Major technical decisions              |
| Feature specs (`docs/`)              | Feature requirements and acceptance criteria | Per feature                            |
| Contributing guides (`docs/guides/`) | Authoring standards and how-to               | New patterns emerge                    |

---

## 2. Architecture Principles

### 2.1 Core Architecture

<!-- Define the primary architecture pattern for this project -->

```
[User] → [Frontend] → [Backend] → [Database]
```

### 2.2 Non-Negotiable Principles

| Principle     | Description                 | Rationale               |
| ------------- | --------------------------- | ----------------------- |
| [Principle 1] | [What it means in practice] | [Why this is important] |
| [Principle 2] | [What it means in practice] | [Why this is important] |

### 2.3 Primitive-First Operations

**Statement:** Skills and agents must use primitives for all standard operations (git, tracker, docs, review). Ad-hoc shell commands are prohibited where a primitive exists.

**Rationale:** Primitives enforce consistency, auditability, and safety controls uniformly across all workflows.

### 2.4 Stage-Based Orchestration

**Statement:** T1 orchestrators must use numbered stages starting at 1. Every stage must have Inputs, Activities, Outputs, and Exit Criteria subsections.

**Rationale:** Uniform stage structure enables resumability, progress tracking, and predictable execution.

---

## 3. Technology Constraints

**Statement:** The following platform choices are locked. Agents must not propose alternatives without a constitutional exception.

| Layer        | Constraint                                                       | Minimum Version |
| ------------ | ---------------------------------------------------------------- | --------------- |
| Runtime      | Node.js                                                          | >= 22           |
| CLI Platform | Claude Code                                                      | >= 2.1.76       |
| Hook Scripts | Bash (POSIX-compatible)                                          | —               |
| Hook Helpers | Node.js, Python                                                  | >= 22, >= 3.11  |
| CI/CD        | GitHub Actions                                                   | —               |
| OS Support   | Linux, macOS, Windows WSL2 (Tier 1). Native Windows unsupported. | —               |

<!-- Add project-specific technology constraints below -->

| Layer    | Technology         | Version        | Non-Negotiable? |
| -------- | ------------------ | -------------- | --------------- |
| Frontend | [e.g., Next.js]    | [e.g., 16+]    | Yes/No          |
| Backend  | [e.g., FastAPI]    | [e.g., 0.115+] | Yes/No          |
| Database | [e.g., PostgreSQL] | [e.g., 16+]    | Yes/No          |

---

## 4. Quality Standards

### 4.1 Code Quality Thresholds

| Standard                  | Threshold                                                         |
| ------------------------- | ----------------------------------------------------------------- |
| Tests                     | All must pass                                                     |
| Infrastructure count sync | Zero drift                                                        |
| Lint errors               | Zero                                                              |
| Skill frontmatter         | Must include name, version, description, disable-model-invocation |
| Stage numbering           | Integer >= 1                                                      |
| Statusline text           | <= 40 characters                                                  |

### 4.2 PR Requirements

Every pull request must:

- Pass all CI checks
- Have at least one reviewer approval
- Update documentation when behavior changes
- Reference a spec or backlog item for feature PRs
- Maintain AC-ID traceability for SDD features

### 4.3 Documentation Requirements

- All new features must have a Feature Requirements Document (FRD)
- Major technical decisions must have an Architecture Decision Record (ADR)
- All planned work must have a backlog entry
- Feature docs must follow the SDD lifecycle (Spec -> Design -> Develop -> Validate -> Deploy)

---

## 5. Security Requirements

### 5.1 Secrets Management

- Secrets must never be committed to the repository
- `.env`, `.pem`, and `.key` files are blocked by hook enforcement
- API keys and credentials must not appear in code or configuration

### 5.2 Protected Files

- `CLAUDE.md`, `.claude/settings.json`, and `.claude/project-constants.md` must not be modified without explicit human approval
- `.github/workflows/` requires manual review for all changes

### 5.3 Destructive Operations

- Force-push, recursive delete, and production deploys must require human confirmation
- `chmod 777`, `sudo`, and pipe-to-shell are globally denied

---

## 6. Agent Behavioral Policy

### 6.1 Autonomy Boundaries

Agents may perform all development activities (code generation, bug fixes, test generation, documentation, refactoring, infrastructure changes) but all output must be reviewed by a human before merge.

### 6.2 Escalation Triggers

Agents must escalate to a human when:

- Modifying protected files (S5.2)
- Performing destructive operations (S5.3)
- Encountering ambiguity that could affect architecture or security
- Operating outside the declared scope of their current task

### 6.3 Safety Invariants

- Safety hooks (protect-files, detect-secrets, hitl-approval, security-gate) must always be registered in `settings.json`
- Safety hooks are controlled via the `protectionsEnabled` flag — they are never removed, only toggled
- Hook scripts must not be modified without explicit approval
- Disabling hooks permanently requires a constitutional exception
- **Protection state is user-controlled:** Agents must NEVER enable or disable protections (`protectionsEnabled` in `global-state.json`) without an explicit, direct user instruction. Audit findings, security recommendations, and test failures are not authorization to change protection state. When tests fail because of protection state, fix the tests — do not change the flag.

### 6.4 Source of Truth Hierarchy

When generating or modifying code, agents must respect this precedence:

1. This Constitution (highest priority)
2. Feature Specifications (`docs/`)
3. Architecture Decision Records (`docs/adrs/`)
4. CLAUDE.md project instructions
5. Coding standards (ECS)
6. Contributing guides (`docs/guides/`)
7. Existing code patterns
8. General best practices

### 6.5 Quality Requirements for AI-Generated Code

AI-generated code must:

- Pass all linting and type checks
- Not introduce placeholder values in non-template files
- Not contain TODOs without ticket references
- Follow skill authoring standards (frontmatter, stage structure, statusline)
- Use primitives for all standard operations

---

## 7. Design Constraints

### 7.1 SDD Lifecycle

All features must follow the Spec-Driven Development lifecycle: Spec -> Design -> Develop -> Validate -> Deploy. No phase may be skipped without a constitutional exception.

### 7.2 Phase Gate Enforcement

- Every T1 orchestrator must auto-invoke its `<phase>-review` sub-skill as the final stage
- Failed gates must block progression to the next phase
- The `--force` flag may override gates; behavior varies by rigor level (lite=warn, standard=confirm, strict=blocked)
- Gate verdicts must be recorded with PASS or FAIL

### 7.3 Terminology

| Term  | Definition                                                   |
| ----- | ------------------------------------------------------------ |
| Phase | SDD lifecycle level: Spec, Design, Develop, Validate, Deploy |
| Stage | Numbered step within a phase's T1 orchestrator               |
| Gate  | Phase boundary verdict: PASS or FAIL                         |
| Guard | Runtime binary allow/deny                                    |
| Check | Point-in-time PASS/FAIL                                      |

### 7.4 Context Tiers

Agent context must follow the three-tier model:

- **Tier 1 (Standards):** Always loaded. Authoritative for coding conventions.
- **Tier 2 (Project):** Loaded on demand by orchestrators. Synced from documentation.
- **Tier 3 (Task):** Passed inline per task dispatch. Never persisted.

---

## 8. Amendment Process

### 8.1 Requesting a Change

Constitutional changes require:

1. A written proposal identifying the principle to add, modify, or remove
2. Rationale explaining why the change is needed
3. Impact analysis on existing specs and workflows
4. Stakeholder approval (Engineering Lead)

### 8.2 Requesting an Exception

When a specification or implementation cannot meet a constitutional requirement:

1. Document the specific requirement that cannot be met
2. Explain why (technical, timeline, cost)
3. Propose mitigation or alternative approach
4. Get approval from Tech Lead + Product Owner
5. Document exception in the specification with an expiration date

```markdown
## Constitutional Exception

**Requirement**: [Which requirement cannot be met]
**Reason**: [Why it cannot be met]
**Impact**: [What is the risk/impact]
**Mitigation**: [How risk is reduced]
**Approved By**: [Names and dates]
**Expiration**: [When this exception expires]
**Remediation Plan**: [How this will be fixed]
```

---

## Approval

| Role             | Name | Date | Status  |
| ---------------- | ---- | ---- | ------- |
| Engineering Lead |      |      | Pending |

---

## Revision History

| Version | Date   | Author   | Changes                                  |
| ------- | ------ | -------- | ---------------------------------------- |
| 1.0.0   | <DATE> | Template | Initial constitution (scaffold template) |
