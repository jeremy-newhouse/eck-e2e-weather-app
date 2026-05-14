---
version: "0.4.0"
disable-model-invocation: false
---

# Develop-Sprint Skill - Modular Structure

This skill executes a sprint's worth of tasks with dependency ordering, tracker state persistence, and sprint summary.

## Structure

```
.claude/skills/dev-sprint/
├── skill.md                     # Main orchestrator - overview, constants, workflow phases
├── recovery.md                  # Context recovery procedures
├── phases/                      # Detailed stage instructions
│   ├── prereq.md                # Stage 2: Tool Health Check
│   │                            # Stage 3: PR Status Check
│   ├── planning.md              # Stage 1: Sprint Identification
│   │                            # Stage 2: Dependency Analysis
│   │                            # Stage 3: User Confirmation
│   ├── execution.md             # Stage 4: Sprint Setup
│   │                            # Stage 5: Sprint Execution
│   └── closure.md               # Stage 6: Sprint Integration
│                                # Stage 7: Documentation Commit
│                                # Stage 8: Sprint Completion
│                                # Stage 9: Sprint Report
└── prompts/                     # Agent prompt templates
    ├── developer.md             # Developer dispatch template
    └── planner.md               # Planning phase prompts
```

## File Descriptions

### skill.md

Main orchestrator file. Contains:

- Skill metadata (name, description)
- Tracker constants (WA, <BOARD_ID>)
- Global exclusions (archive/, node_modules/, etc.)
- Usage examples
- Prerequisites and pre-sprint checklist
- Tracker MCP tool reference
- Claude Task Management integration
- Phase validation protocol
- Orchestrator role clarification
- Stage summaries with references to detailed stage files
- Sprint progress visibility (TaskList)
- Git strategy (branch hierarchy, naming conventions)
- Task routing reference
- Important notes

### recovery.md

Context recovery procedures. Contains:

- Recovery sources (feature folder, tracker, git state)
- Quick recovery steps after context loss
- Recovery states mapping (tracker comments -> resume points)
- Full recovery procedure
- Tracker sprint state format
- Recovery command reference

### phases/prereq.md

Prerequisites and tool health checks. Contains:

- **Stage 2: Tool Health Check (BLOCKING)**
  - Tracker MCP verification
  - Git CLI verification
  - GitHub CLI verification
  - Tool health summary
- **Stage 3: PR Status Check (BLOCKING)**
  - Check for open PRs (blocking)
  - Verify dev branch is clean
  - Proceed to sprint identification

### phases/planning.md

Sprint planning phases. Contains:

- **Stage 1: Sprint Identification**
  - Parse arguments (Epic ID, sprint name, task IDs)
  - Load sprint tasks from tracker
  - Check for existing sprint state
  - Verify Epic status
  - Validate success criteria
- **Stage 2: Dependency Analysis**
  - Build task dependency graph
  - Topological sort for execution order
  - Output execution plan with agent assignments
- **Stage 3: User Confirmation**
  - Show execution plan
  - Get user approval to proceed

### phases/execution.md

Sprint execution phases. Contains:

- **Stage 4: Sprint Setup**
  - Initialize sprint state in tracker Epic
  - Create feature branch if needed
  - Create sprint branch from feature
  - Transition Epic to "In Progress"
  - Start tracker sprint (automatic)
  - Verify sprint started
- **Stage 5: Sprint Execution**
  - Initialize Claude Tasks for tracking
  - Execute tasks in dependency order
  - Handle task failures
  - Track progress in tracker

### phases/closure.md

Sprint closure phases. Contains:

- **Stage 6: Sprint Integration**
  - Run integration tests (if cross-service)
  - Invoke integration-qa if needed
- **Stage 7: Documentation Commit**
  - Identify documentation changes
  - Update CHANGELOG.md
  - Commit documentation if changes exist
  - Push documentation branch
- **Stage 8: Sprint Completion**
  - Update tracker Epic with completion
  - Complete tracker sprint (automatic)
- **Stage 9: Sprint Completion Report**
  - Add structured completion report to Epic
  - Calculate velocity
  - Transition Epic status (if final sprint)
  - Generate sprint summary report
  - Offer to create PRs (sprint -> feature -> dev)

### prompts/developer.md

Developer dispatch template. Contains:

- Complete prompt template for dispatching developer agents
- Tracker constants
- Task details structure
- Success criteria format
- Agent selection guidance
- Specification references
- Sprint context
- Dependencies
- File hints
- Progress tracking via parent task comments (NOT subtasks)

### prompts/planner.md

Planning prompt template. Contains:

- Dependency analysis prompt
- Topological sort algorithm guidance
- Execution plan output template
- Parallel execution opportunities format

## Benefits of Modular Structure

1. **Maintainability:** Each stage in its own file makes updates easier
2. **Readability:** Slim main file with clear references
3. **Reusability:** Prompt templates can be reused across skills
4. **Navigation:** Easy to jump to specific stage documentation
5. **Context Management:** Smaller files reduce token usage when reading specific phases
6. **Separation of Concerns:** Prerequisites, planning, execution, and closure are logically separated
