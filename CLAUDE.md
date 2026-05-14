# CLAUDE.md

A full-stack weather app with Express.js backend and HTML frontend

## What This Repo Is

<!-- Describe the repository's purpose and what it contains -->

| Repo          | Contains                                                                     | Purpose                                                       |
| ------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `Weather App` | Express.js REST API, plain HTML/CSS/JS frontend, Node.js built-in test suite | Serve weather data via REST API and render it in a browser UI |

## Governance

Principles, constraints, and invariants are governed by `.claude/project-constitution.md` (rarely changes). This file (`CLAUDE.md`) contains operational instructions and procedures (changes with features). Pre-computed values live in `.claude/project-constants.md` (changes with config). To amend the constitution, see its S8 Amendment Process.

## Directory Structure

```
Weather App/
├── .claude/                    # AI agent infrastructure
│   ├── agents/                 # Agent definitions
│   ├── skills/                 # Skill definitions
│   ├── hooks/                  # Hook scripts
│   ├── primitives/             # Primitive operations
│   ├── output-modes/           # Mode definitions
│   ├── heuristics/             # Learning pipeline
│   ├── context/                # Standards + project context
│   ├── scripts/                # Utility scripts
│   ├── settings.json           # Hook config
│   ├── settings.local.json     # Project permissions
│   ├── project-constitution.md # Governing principles (top authority)
│   └── project-constants.md    # Pre-computed values for skills/agents
├── docs/                       # Documentation
│   ├── guides/                 # Contributing guides + workflow docs
│   ├── project/                # Project docs (BRD, PRD, backlog)
│   ├── adrs/                   # Architecture Decision Records
│   └── INDEX.md                # Documentation index
└── CLAUDE.md                   # This file
```

## Development Workflow

Two-session model separating planning from implementation:

| Session                | Command                       | Purpose                                                |
| ---------------------- | ----------------------------- | ------------------------------------------------------ |
| **A** (Planning)       | `/<PK>:design-feature <desc>` | Research, design, document, create tasks. STOPS after. |
| **B** (Implementation) | `/<PK>:dev-feature WA-XXX`    | Execute all tasks under an epic                        |
| **B** (Single issue)   | `/<PK>:dev-task WA-XXX`       | Execute a single task with TDD                         |

Full workflow docs: `docs/guides/development-workflow.md`

## Agent Selection

| Prefix | Agent               | Repo        |
| ------ | ------------------- | ----------- |
| BE-    | backend-developer   | Weather App |
| FE-    | frontend-developer  | Weather App |
| UI-    | frontend-designer   | Weather App |
| DOC-   | technical-writer    | Weather App |
| INFRA- | devops-engineer     | Weather App |
| SEC-   | security-specialist | Weather App |
| QA-    | integration-qa      | varies      |

## Source of Truth

| Topic              | File                                              |
| ------------------ | ------------------------------------------------- |
| Constitution       | `.claude/project-constitution.md`                 |
| Project constants  | `.claude/project-constants.md`                    |
| Naming conventions | `.claude/context/standards/naming-conventions.md` |
| Workflow docs      | `docs/guides/`                                    |
| Variable syntax    | `docs/guides/variable-syntax-conventions.md`      |

## Tech Stack

<!-- Populated by /start-project -->

- **Frontend**: Plain HTML/CSS/JavaScript (no framework, no bundler)
- **Backend**: Node.js 22, Express.js
- **Database**: None (in-memory stub data)

## Quality Gates

See `.claude/project-constants.md` for gate commands.

| Gate  | Command             |
| ----- | ------------------- |
| Tests | `npm test`          |
| Lint  | `npm run lint`      |
| Types | `npm run typecheck` |

## Contributing Guide

@docs/guides/CONTRIBUTING.md

## Learned Guidance

@.claude/heuristics/active-guidance.md

---

**Version**: 0.7.4 | **Updated**: 2026-05-14
