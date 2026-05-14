---
name: wa:jira
version: "0.7.4"
description: JIRA issue management for the WA project
disable-model-invocation: false
---

# JIRA Skill

Config-only skill — manage JIRA issues in the WA project. Action: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:jira create "BE: Add auth endpoint" --type task   # Create a task
/wa:jira get WA-123                        # Fetch issue details
/wa:jira search "sprint = active"                     # Search for issues
```

## Project Constants

- Project Key: WA
- Board ID: <BOARD_ID>
- Assignee: <ASSIGNEE_NAME> (<ASSIGNEE_ID>)
- Label: WA (always apply)

## Domain Prefixes for Titles

- BE: Backend
- FE: Frontend
- DB: Database
- DOC: Documentation
- BOT: AI/Bot
- INFRA: Infrastructure
- SEC: Security
- QA: Quality Assurance

## Rules

- Always apply WA label
- Use domain prefix in title
- Never mention Claude, AI tools, or MCP in JIRA
- Use plain text tags: [STARTED], [COMPLETE], [BLOCKED]
- Include acceptance criteria as checklist
- Bugs MUST have a parent epic
- Always set assignee_id to the ASSIGNEE_ID from project-constants.md when creating issues
