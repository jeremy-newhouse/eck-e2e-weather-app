# Agent Authoring Guide

Guide for creating and customizing project agents.

---

## Overview

Agents are specialized AI assistants with defined roles, responsibilities, and constraints. Each agent has a specific purpose in the development workflow.

---

## Agent Catalog

### Orchestration
| Agent | Purpose | Model |
|-------|---------|-------|
| task-coordinator | Orchestrates complete task lifecycle | opus |
| code-simplifier | Reviews for over-engineering | opus |

### Backend Track
| Agent | Purpose | Model |
|-------|---------|-------|
| backend-architect | Technical architecture (HOW) | opus |
| backend-designer | API contracts (WHAT) | opus |
| backend-developer | Implementation | opus |
| backend-qa | Testing | opus |
| backend-reviewer | Code review | opus |

### Frontend Track
| Agent | Purpose | Model |
|-------|---------|-------|
| frontend-architect | Component architecture (HOW) | opus |
| frontend-designer | UI/UX design (WHAT) | opus |
| frontend-developer | Implementation | opus |
| frontend-qa | E2E testing | opus |
| frontend-reviewer | Code review | opus |

### Cross-Cutting
| Agent | Purpose | Model |
|-------|---------|-------|
| database-specialist | Schema, migrations | opus |
| devops-engineer | CI/CD, deployment | opus |
| security-specialist | Security review (has authority) | opus |
| integration-qa | Cross-service testing | opus |
| technical-writer | Documentation | opus |

### Optional (AI/Bot)
| Agent | Purpose | Model |
|-------|---------|-------|
| bot-architect | Bot service architecture | opus |
| bot-developer | Bot implementation | opus |

---

## Agent Structure

Every agent file follows this structure:

```markdown
---
name: agent-name
description: "Description with examples"
model: opus | sonnet
color: purple | green | etc
---

# Agent content

## Task Tracker Constants
[Pre-computed values]

## Global Exclusions
[Standard exclusion list]

## Your Role
[Agent responsibilities]

## Standards Reference
[Links to relevant standards]

## Completion Requirements
[What must be done before completion]
```

---

## Creating a New Agent

### 1. Choose a Template

Copy an existing agent that's closest to your needs:
- Developer: Start with `backend-developer.md` or `frontend-developer.md`
- Architect: Start with `backend-architect.md` or `frontend-architect.md`
- QA: Start with `backend-qa.md` or `frontend-qa.md`
- Reviewer: Start with `backend-reviewer.md` or `frontend-reviewer.md`

### 2. Update Frontmatter

```yaml
---
name: my-new-agent
description: "Clear description of what this agent does.

Examples:

<example>
Context: When to use this agent.
user: \"User request\"
assistant: \"How Claude responds\"
</example>"
model: opus  # or sonnet for simpler tasks
color: green  # choose a unique color
---
```

### 3. Define the Role

Clearly state:
- What the agent is responsible for
- What it is NOT responsible for
- When it should be invoked
- What it should produce

### 4. Add Standards References

Link to relevant standards documents:

```markdown
## Standards Reference

- Python: `standards/backend/python.md`
- Testing: `standards/backend/testing.md`
```

### 5. Define Completion Requirements

Be explicit about what must be done:

```markdown
## Completion Checklist

Before reporting complete:

- [ ] All acceptance criteria implemented
- [ ] Tests written and passing
- [ ] No linting errors
- [ ] No type errors
- [ ] Spec compliance verified
```

---

## Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| name | Yes | Agent identifier (kebab-case) |
| description | Yes | Purpose and examples |
| model | Yes | `opus` or `sonnet` |
| color | No | UI color for agent |

### Model Selection

| Model | Use For |
|-------|---------|
| opus | Complex tasks, architecture, review |
| sonnet | Simple tasks, quick operations |

### Color Options

purple, green, blue, orange, yellow, red, pink, cyan, teal, lime, indigo, gray

---

## Best Practices

### Do
- Keep roles focused and specific
- Include clear examples in description
- Reference standards documents
- Define explicit completion criteria
- Include recovery instructions

### Don't
- Create agents with overlapping responsibilities
- Make agents too general
- Skip the standards references
- Forget completion requirements

---

## Removing Agents

Remove agents your project doesn't need:

```bash
# If no bot services
rm .claude/agents/bot-architect.md
rm .claude/agents/bot-developer.md

# If no frontend
rm .claude/agents/frontend-*.md

# If no backend
rm .claude/agents/backend-*.md
```

---

## Agent Hierarchy

When agents disagree, this hierarchy applies:

1. **security-specialist** - Wins on security matters
2. **architect** - Wins on architecture over developer
3. **designer** - Wins on UX/ergonomics
4. **reviewer** - Final say on code quality
5. **User** - Decides cross-domain conflicts

---

## Related Documentation

- [Skill Authoring](../skills/README.md)
- [Development Workflow](../../development-workflow.md)
- [CLAUDE.md](../../CLAUDE.md)
