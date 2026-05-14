# Weather App Workflow Quick Reference

Concise command reference for the development workflow (v2.0.0).

---

## Two-Session Model

| Session                | Command                          | Purpose                                                |
| ---------------------- | -------------------------------- | ------------------------------------------------------ |
| **A** (Planning)       | `/design-feature <desc>`         | Research, design, document, create tasks. STOPS after. |
| **B** (Implementation) | `/dev-feature WA-XXX` | Execute all tasks under an epic                        |
| **B** (Single issue)   | `/dev-task WA-XXX`    | Execute a single task with TDD                         |

---

## All Slash Commands

### Planning (Session A)

| Command                  | Purpose                                  |
| ------------------------ | ---------------------------------------- |
| `/design-feature <desc>` | Full 6-stage planning (STOPS at Stage 6) |
| `/spec-discovery`        | Collaborative requirements discovery     |

### Implementation (Session B)

| Command                          | Purpose                           |
| -------------------------------- | --------------------------------- |
| `/dev-feature WA-XXX` | Implement all tasks under an epic |
| `/dev-task WA-XXX`    | Implement a single task (TDD)     |

### Git & Quality

| Command              | Purpose                                    |
| -------------------- | ------------------------------------------ |
| `/git-flow <action>` | Git workflow (status, commit, push, pr)    |
| `/quality-review`    | Run all quality gates (tests, lint, types) |
| `/code-review`       | Manual code review of changes              |
| `/ci-triage`         | Diagnose CI pipeline failures              |

### Documentation

| Command                | Purpose                 |
| ---------------------- | ----------------------- |
| `/confluence <action>` | Manage Confluence pages |
| `/jira <action>`       | Manage JIRA issues      |

### Session Management

| Command            | Purpose                             |
| ------------------ | ----------------------------------- |
| `/learn <insight>` | Capture learning to memory          |
| `/retrospective`   | Session analysis + learning capture |

---

## Agent Dispatch Table

| Prefix | Agent               | Repo              |
| ------ | ------------------- | ----------------- |
| DB-    | database-specialist | Weather App-be |
| BE-    | backend-developer   | Weather App-be |
| FE-    | frontend-developer  | Weather App-fe |
| UI-    | frontend-designer   | Weather App-fe |
| BOT-   | bot-developer       | Weather App-be |
| DOC-   | technical-writer    | Weather App    |
| INFRA- | devops-engineer     | Weather App-be |
| SEC-   | security-specialist | Weather App-be |
| QA-    | integration-qa      | varies            |

---

## Branch Naming

| Branch Type | Pattern                         | Example                              |
| ----------- | ------------------------------- | ------------------------------------ |
| Feature     | `feat/WA-XXX-name`   | `feat/WA-100-user-auth`   |
| Hotfix      | `hotfix/WA-XXX-name` | `hotfix/WA-150-fix-login` |

**Rules:**

- NEVER develop on `main` or `dev`
- Feature branches from `dev`
- One feature branch per epic per repo

---

## Quality Gates

```bash
# Backend
{BACKEND_RUN_CMD} pytest         # Tests
{BACKEND_RUN_CMD} ruff check .   # Lint
{BACKEND_RUN_CMD} mypy .         # Types

# Frontend
npm run test                     # Tests
npm run lint                     # Lint
npm run typecheck                # Types
```

ALL must pass before PR creation.

---

## Context Recovery

```bash
# Check for saved state
cat .checkpoint                  # Last progress snapshot
ls .claude/handovers/            # Pre-compact handovers

# Check git state
git branch -vv && git status

# Resume
/dev-feature WA-XXX   # Resume epic implementation
/dev-task WA-XXX      # Resume single task
```

---

## Complete Workflow

```
Session A:
  /design-feature <description>    # Creates docs + tracker items (6 phases)
  -> STOPS. Review artifacts.

Session B:
  /dev-feature WA-XXX  # Execute tasks, create PRs
  -> Review and merge PRs.

Optional:
  /retrospective                 # Capture session learnings
```

---

## Key Rules

- **Two-session model**: Planning and implementation are SEPARATE sessions
- **Agent dispatch required**: Use Task tool for prefixed tasks
- **Quality gates are BLOCKING**: All must pass before PR
- **Tracker refs in commits**: `Refs: WA-XXX` is mandatory
- **Protected files**: CLAUDE.md, settings.json, project-constants.md require confirmation

---

## Related Documents

- [CLAUDE.md](./CLAUDE.md) - Project reference
- [development-workflow.md](./development-workflow.md) - Full workflow details
- [workflow-diagrams.md](./workflow-diagrams.md) - Visual reference
- [.claude/project-constants.md](./.claude/project-constants.md) - Pre-computed values
