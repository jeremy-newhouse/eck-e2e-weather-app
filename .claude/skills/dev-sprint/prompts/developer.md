---
version: "0.4.0"
disable-model-invocation: false
---

# Developer Dispatch Template

Use this template when dispatching a developer agent for a sprint task.

```
Tool: Task
Parameters:
  subagent_type: "{developer-agent-from-prefix}"
  description: "Develop {task-key}"
  prompt: |
    Develop tracker task {task-key}.

    ## Tracker Constants
    - PROJECT_KEY: WA
    - ASSIGNEE_ACCOUNT_ID: {ASSIGNEE_ACCOUNT_ID}

    ## Task Details
    - ID: {task-key}
    - Summary: {from tracker}
    - Description: {full description from tracker}
    - Type: {issue type}
    - Priority: {priority}

    ## Success Criteria
    {extracted checkbox list from tracker description}

    ## Agent Selection

    Based on task prefix, use the routing table:
    - Task Prefix: {e.g., BE-, FE-, BOT-}
    - Developer Agent: {agent name matching prefix}

    ## Specification References
    - Feature: {SPEC-{KEY}-N if found in description}
    - API: {SPEC-API-XXX if found in description}

    ## Sprint Context
    - Epic: {parent epic key}
    - Sprint Name: {sprint name}
    - Tasks Completed: {X/Y}
    - This is task {N} of {total}

    ## Dependencies
    - Blocked by: {list of blocking tasks - all should be Done}
    - Blocks: {list of tasks this blocks}

    ## File Hints (from previous tasks if known)
    - {any file paths mentioned in related tasks}

    ## Instructions
    1. Read your agent definition: .claude/agents/{agent}.md
    2. Read relevant specs and standards
    3. Write failing tests FIRST (TDD)
    4. Develop minimum code to pass tests
    5. Run quality gate before reporting done
    6. Return completion report with:
       - Files created/modified
       - Tests written and passing
       - Any issues encountered

    ## Progress Tracking

    The orchestrator (dev-sprint) handles tracker comments.
    Focus on development and returning a clear completion report.
```
