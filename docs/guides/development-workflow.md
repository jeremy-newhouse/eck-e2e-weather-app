# Weather App Development Workflow

Comprehensive development workflow for the Weather App project (v2.0.0).

---

## Overview

This workflow uses a **two-session model** separating planning (documentation only) from implementation (code execution).

```
SESSION A: PLANNING                SESSION B: IMPLEMENTATION
(No code changes)                  (Code development)
     |                                  |
     /design-feature <desc>               /dev-feature WA-XXX
       |                                  |
       Stage 1: Interview (MANDATORY)     Step 1: Gather context
       Stage 2: Research                  Step 2: Build plan
       Stage 3: Design                   Step 3: Plan approval (USER)
       Stage 4: Document                 Step 4: Execute batches
       Stage 5: Create tasks             Step 5: Review + QA
       Stage 6: STOP                     Step 6: Create PR
                |                         Step 7: Update tracker
                v
         User reviews docs               /dev-task WA-XXX
         before implementing             (single-issue alternative)
```

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

## Session A: Planning (`/design-feature`)

### Stage 0: Session Marker

Creates `.planning-session` file to activate `planning-guard.sh` hook, which blocks developer agent dispatch during planning.

### Stage 1: Interview (MANDATORY)

Requirements gathering via `AskUserQuestion`. 2-4 questions per round, max 4 rounds.

### Stage 2: Research

1. Search specs for related documents
2. Check tracker for related issues
3. Scan codebase for existing patterns
4. Search external sources if needed

**Output:** Research findings integrated into design phase.

### Stage 3: Design

Dispatch architect/designer agents based on task type:

- Backend changes -> backend-architect
- Frontend changes -> frontend-architect + frontend-designer
- Mixed -> both in parallel

### Stage 4: Document

Create full document suite (8 document types):

- SPEC-FEAT: Feature specification
- SPEC-API: API contract (if backend)
- SPEC-DATA: Data model changes (if DB)
- SPEC-DESIGN: UI/UX specifications (if frontend)
- ADR: Architecture Decision Records
- Research summary
- Interview transcript
- Risk assessment

### Stage 5: Create Tasks

Create tracker items:

- Epic with description and spec links
- Child issues with domain prefixes (DB-, BE-, FE-, etc.)
- Dependencies between issues
- Acceptance criteria from specs

### Stage 6: Report and STOP

Prints summary of all created artifacts, then STOPS. **Never** proceeds to implementation.

---

## Session B: Implementation (`/dev-feature WA-XXX`)

### Step 1: Gather Context

Fetch epic details, child issues, and all linked specifications.

### Step 2: Build Plan

Create dependency graph and batch execution order:

1. DB- tasks first (schema changes)
2. BE- tasks second (API endpoints)
3. FE-/BOT-/UI- tasks third (consumers)
4. DOC- tasks fourth (documentation)
5. QA- tasks last (verification)

### Step 3: Plan Approval (USER MUST APPROVE)

Display execution plan with task order, agent assignments, and repo targets. Wait for explicit user approval.

### Step 4: Execute Batches

For each task, dispatch the appropriate agent:

1. Write failing tests (TDD red phase, skip for DB/DOC/UI/INFRA/SEC)
2. Implement the feature
3. Run code-simplifier review

### Step 5: Review + QA

Parallel review gates:

- Quality gates: tests, lint, typecheck (ALL must pass)
- Code review: dispatch appropriate reviewer by file type
- Security review: dispatch security-specialist (if security-relevant)
- QA verification: dispatch appropriate QA agent

### Step 6: Create PR

One PR per affected repo: `feat/WA-XXX` -> `dev`

**PR requirements:**

- All quality gates pass
- Code review approved
- Spec reference in description
- `Refs: WA-XXX` in commits

### Step 7: Update Tracker

Add implementation notes to issues. Do NOT transition to Done (reviewer closes after merge).

---

## Single-Issue: `/dev-task WA-XXX`

10-step TDD workflow for individual issues:

1. **Setup**: Create feature branch `feat/WA-XXX-description`
2. **Context**: Fetch issue details and linked specs
3. **Plan**: Present plan, get USER APPROVAL
4. **TDD Red**: Write failing tests (skip for DB/DOC/UI/INFRA/SEC)
5. **Develop**: Dispatch agent by prefix
6. **Simplify**: Code-simplifier review
7. **Review**: Quality gates + code review + security (parallel)
8. **QA**: Integration testing if applicable
9. **Commit + PR**: Create PR (STOP, do not merge)
10. **Update**: Add notes to tracker (do not close)

---

## Branch Strategy

### Branch Hierarchy

```
main (PRODUCTION) <- Release PRs only
  |
  +-- dev (INTEGRATION) <- Feature PRs only
        |
        +-- feat/WA-XXX-name <- Feature branches
```

### Branch Rules

- **NEVER** commit directly to `main` or `dev`
- Feature branches created from `dev`
- One feature branch per epic per repo
- Push immediately after branch creation

---

## Quality Gates

| Gate  | Backend Command                  | Frontend Command    |
| ----- | -------------------------------- | ------------------- |
| Tests | `node server.js pytest`       | `npm run test`      |
| Lint  | `node server.js ruff check .` | `npm run lint`      |
| Types | `node server.js mypy .`       | `npm run typecheck` |

**ALL gates must pass before PR creation.**

---

## Git Flow Commands

| Command            | Action                                    |
| ------------------ | ----------------------------------------- |
| `/git-flow status` | Show branch state and uncommitted changes |
| `/git-flow commit` | Conventional commit with tracker ref      |
| `/git-flow push`   | Push current branch to remote             |
| `/git-flow pr`     | Create PR for current branch              |

---

## Context Recovery

### Planning Phase Recovery

Check for `.planning-session` file and feature artifacts:

- No artifacts -> Start fresh with `/design-feature`
- Partial artifacts -> Resume at appropriate stage

### Execution Phase Recovery

1. Check `.checkpoint` file for saved progress
2. Check `.claude/handovers/` for pre-compact handovers
3. Check git state: `git branch -vv && git status`
4. Check tracker for current task state
5. Resume with `/dev-feature` or `/dev-task`

### Hooks That Help Recovery

- `context-recovery.sh` (SessionStart): Auto-loads checkpoint and latest handover
- `pre-compact.sh` (PreCompact): Saves handover before context compression
- `checkpoint-save.sh` (PostToolUse): Saves progress after file edits

---

## Complete Workflow

```
Session A (New Claude session):
1. /design-feature <description>     # 6 phases -> docs + tracker items
   -> STOPS. Review all artifacts before proceeding.

Session B (New Claude session):
2. /dev-feature WA-XXX  # Execute all tasks under epic
   -> Creates PRs, updates tracker. Does NOT merge.

Post-Implementation:
3. Review PRs, request changes if needed
4. Merge PRs when approved
5. /retrospective                  # Capture learnings (optional)
```

---

## Related Documents

- [CLAUDE.md](./CLAUDE.md) - Project reference
- [workflow-quick-reference.md](./workflow-quick-reference.md) - Command reference
- [workflow-diagrams.md](./workflow-diagrams.md) - Visual diagrams
- [project-constitution.md](./project-constitution.md) - Governance rules
- [.claude/project-constants.md](./.claude/project-constants.md) - Pre-computed values

---

**Version**: 2.0.0
**Template**: Development Workflow
