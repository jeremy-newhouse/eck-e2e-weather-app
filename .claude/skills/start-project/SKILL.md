---
name: wa:start-project
version: "0.7.4"
description: "Project kickoff: tech stack, architecture, BRD/PRD, and feature breakdown. Run after /eck:new-project scaffolding."
disable-model-invocation: false
---

# Start Project

> Project kickoff skill. Guides you through tech stack selection, architecture decisions, project documentation, and initial feature planning.

Run after `/eck:new-project` has scaffolded project infrastructure.

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill is interview-driven and must gather all requirements before writing any files.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:start-project                     # Run full project kickoff
```

Run this after `/eck:new-project` has scaffolded the project infrastructure. Guides you through tech stack, architecture, documentation, and feature planning.

---

## Task Registration

| Stage | Subject             | Active Form          | Statusline      |
| ----- | ------------------- | -------------------- | --------------- |
| 1     | Stage 1: Preflight  | Running preflight    | Preflt (1/10)   |
| 2     | Stage 2: Vision     | Defining vision      | Vision (2/10)   |
| 3     | Stage 3: Tech Stack | Selecting tech stack | Stack (3/10)    |
| 4     | Stage 4: Configure  | Configuring project  | Config (4/10)   |
| 5     | Stage 5: Agents     | Setting up agents    | Agents (5/10)   |
| 6     | Stage 6: Standards  | Applying standards   | Stds (6/10)     |
| 7     | Stage 7: Decisions  | Recording decisions  | Decis (7/10)    |
| 8     | Stage 8: Documents  | Writing documents    | Docs (8/10)     |
| 9     | Stage 9: Features   | Planning features    | Features (9/10) |
| 10    | Stage 10: Complete  | Completing setup     | Done (10/10)    |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Stage 1: Preflight

### Inputs

- `.claude/project-constants.md` — scaffolded by `/eck:new-project`
- `.claude/.start-project-completed` — previous completion marker (may not exist)
- Plugin registry — installed and enabled plugins for this Claude Code instance

### Activities

1. Verify `.claude/project-constants.md` exists:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" && echo "PASS" || echo "FAIL"
   ```

   If missing → STOP: "Run `/eck:new-project` first to scaffold project infrastructure."

2. Check `.claude/.start-project-completed`:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" 2>/dev/null
   ```

   If found → ask user via AskUserQuestion: "Project kickoff already completed on {date}. Re-run to update project definition? (Y/n)"
   If user declines → STOP.

3. Read `project-constants.md` → load:
   - `Weather App`, `WA`, `A full-stack weather app with Express.js backend and HTML frontend`
   - `3` (1-5 scale)
   - `<PROJECT_PROBLEM>`, `<PROJECT_USERS>`, `<PROJECT_GOALS>`
   - `GitHub`, `<DOC_PLATFORM>`
   - All other project constants

4. Load project type level to determine interview depth:

| Level | Label        | Interview Qs                          | Docs Created                                                   |
| ----- | ------------ | ------------------------------------- | -------------------------------------------------------------- |
| 1     | Spike / PoC  | 3 (tech stack, repo, key features)    | Lightweight project brief                                      |
| 2     | Prototype    | 4 (+ architecture direction)          | Brief + feature outline                                        |
| 3     | MVP          | 6 (+ quality config, branch strategy) | BRD + PRD + features                                           |
| 4     | Pilot / Beta | 7 (+ security, performance)           | BRD + PRD + ADRs + specs + features                            |
| 5     | Production   | 9 (+ integrations, operational)       | Full suite: constitution + BRD + PRD + ADRs + specs + features |

5. Plugin and integration verification:

   **MUST** run `core/ops:plugin-preflight` with `blocking: true` for all required plugins determined by `GitHub` and `<DOC_PLATFORM>`.

   Display plugin status using this format:

   ```
   ## Plugin & Integration Status
   [x] atlassian: installed, enabled — JIRA (ok), Confluence (ok)
       Probe: mcp__atlassian__getVisibleJiraProjects ... ok
   [x] gh CLI: authenticated
       Probe: gh auth status ... ok
   [!] typescript-lsp: not installed — recommended for TypeScript stack
       Install: /plugin install typescript-lsp@claude-plugins-official
   ```

   Status indicators:
   - `[x]` — installed and responding
   - `[!]` — missing, degraded, or recommended but absent

   Plugin mapping by configuration:
   - `GitHub` = JIRA → `atlassian` plugin required (`blocking: true`)
   - `GitHub` = Linear → `linear` plugin required (`blocking: true`)
   - `GitHub` = GitHub Issues → `gh` CLI required (`blocking: true`)
   - `<DOC_PLATFORM>` = Confluence → `atlassian` plugin required (`blocking: true`)
   - `GitHub` = local or none → no required plugins (informational only)
   - Project type >= 3 → `code-review:code-review` recommended (`blocking: false`)

   If a required plugin is missing or not responding: **STOP** with an actionable error:

   ```
   [ERROR] Required plugin '{plugin}' is not installed.
   This skill requires '{plugin}' to interact with {service}.
   Install it with: /plugin install {plugin}@claude-plugins-official
   Or change your tracker with: /eck:switch-tracker
   ```

   For the non-blocking `code-review:code-review` check (project type >= 3): if not installed, display a warning and continue:

   ```
   [!] code-review — not installed (recommended for project type >= 3)
       PR code review: automatic review of pull requests in /eck:validate
       Install: /plugin install code-review@claude-plugins-official
       Note: /validate-code will fall back to ECK reviewer agents if not installed
   ```

6. After plugin checks, write `CODE_REVIEW_PLUGIN` to `project-constants.md`:
   - If `code-review:code-review` is installed: set `CODE_REVIEW_PLUGIN` to `installed`
   - Otherwise: set `CODE_REVIEW_PLUGIN` to `not-installed`

7. Check for backend overrides after plugin status:
   - If `TRACKER_BACKEND_OVERRIDE` is set in `project-constants.md`: display `[i] Tracker override active: <TRACKER_BACKEND_OVERRIDE> (overrides GitHub)`
   - If `DOC_BACKEND_OVERRIDE` is set in `project-constants.md`: display `[i] Docs override active: <DOC_BACKEND_OVERRIDE> (overrides <DOC_PLATFORM>)`

### Outputs

- All project constants loaded into working memory
- Project type level determined for interview depth gating
- Plugin and integration status displayed
- `CODE_REVIEW_PLUGIN` written to `project-constants.md` (`installed` or `not-installed`)
- Active backend overrides reported (if any)
- Re-run consent obtained (if previously completed)

### Exit Criteria

- `project-constants.md` exists and all constants are loaded
- Project type level is set (1-5) and interview depth is determined
- All required plugins are installed and responding (blocking check passed)
- `CODE_REVIEW_PLUGIN` constant written to `project-constants.md`
- If previously completed, user has confirmed re-run

---

## Stage 2: Project Vision Review

### Inputs

- `project-constants.md` — `<PROJECT_PROBLEM>`, `<PROJECT_USERS>`, `<PROJECT_GOALS>` values

### Activities

1. Display the vision/goals recorded by new-project from project-constants.md:

   ```
   ## Project Vision

   **Problem:** {PROJECT_PROBLEM}
   **Target Users:** {PROJECT_USERS}
   **Goals:** {PROJECT_GOALS}
   ```

2. Ask via AskUserQuestion: "Is this still accurate, or would you like to refine it?"
   - Options: "Looks good" / "Refine vision"

3. If refined → update `project-constants.md` with new values

### Outputs

- Confirmed or updated vision statement in `project-constants.md`

### Exit Criteria

- User has confirmed or refined the project vision
- `project-constants.md` reflects the current vision values

---

## Stage 3: Tech Stack Selection

### Inputs

- Confirmed project vision from Stage 2
- `project-constants.md` — current placeholder tech stack values
- `CLAUDE.md` — tech stack section to update

### Activities

1. **Q1: Using standard stack?** (Next.js + FastAPI + PostgreSQL) — ask via AskUserQuestion (Y/n)
   - If yes: record standard stack values
   - If no: ask follow-up questions:
     - Frontend framework? (e.g., Next.js, Remix, SvelteKit, Vue/Nuxt, none)
     - Backend framework? (e.g., FastAPI, Django, Express, Go, none)
     - Database? (e.g., PostgreSQL, MySQL, MongoDB, SQLite, none)

2. **MUST** dispatch architect agents for validation:
   - If backend selected → **MUST** dispatch `backend-architect` agent:
     - Validate backend tech choice for project goals
     - Recommend service patterns (monolith, microservices, serverless)
     - Suggest key libraries and tools
   - If frontend selected → **MUST** dispatch `frontend-architect` agent:
     - Validate frontend tech choice for project goals
     - Recommend component patterns and state management
     - Suggest UI library and styling approach
   - Do NOT skip agent dispatch and perform validation yourself.

3. Present architecture summary via AskUserQuestion → get user approval

4. Update `project-constants.md` with actual tech stack values:
   - Replace default `<BACKEND_RUN_CMD>`, `<BACKEND_PORT>`, `<FRONTEND_PORT>` with actual values

5. Update `CLAUDE.md` tech stack section with selected technologies

#### 3.5: Architecture Validation (project type >= 3)

**Skip this sub-step if `3` < 3.**

Dispatch architect agents for a lightweight architecture validation (15-minute timebox):

- Validate the selected stack fits the project goals and scale requirements
- Flag any architectural anti-patterns or missing components
- Recommend key infrastructure decisions (caching, queuing, CDN)

Present findings summary via AskUserQuestion → get user acknowledgment before proceeding.

### Outputs

- Selected tech stack recorded in `project-constants.md`
- `CLAUDE.md` tech stack section updated with selected technologies
- Architecture validation findings (project type >= 3)

### Exit Criteria

- User has approved the tech stack selection
- `project-constants.md` contains actual tech stack values (not placeholders)
- `CLAUDE.md` reflects the selected technologies
- Architecture validation complete and acknowledged (if project type >= 3)

---

## Stage 4: Configure

### Inputs

- Tech stack selections from Stage 3
- `project-constants.md` — placeholder repo/quality values
- `settings.local.json` — quality command configuration

### Activities

**Q2: Repo structure** — ask via AskUserQuestion:

- Monorepo or separate repositories?
- Frontend path? (current default: `frontend/`)
- Backend path? (current default: `backend/`)

**Q3: Branch strategy** — ask via AskUserQuestion:

- Main branch name? (default: `main`)
- Development branch name? (default: `dev`)
- Feature branch prefix? (default: `feat/`)

**Q4: Quality commands** (project type level >= 3 only) — ask via AskUserQuestion:

- Frontend test command? (default: `npm test`)
- Backend test command? (default: `uv run pytest`)
- Frontend lint command? (default: `npm run lint`)
- Backend lint command? (default: `uv run ruff check .`)
- Frontend typecheck command? (default: `npm run typecheck`)
- Backend typecheck command? (default: `uv run mypy .`)

**Q5: Code review tool** (project type level >= 3 only) — ask via AskUserQuestion:

- Code review tool? (Greptile / GitHub Copilot / Manual)
- Minimum review score? (default: `5/5`)

**Q6: Integration/E2E tests** (project type level >= 3 only) — ask via AskUserQuestion:

- E2E test command? (default: none)
- Integration test scope? (e.g., API integration, browser E2E, both)
- Test environment requirements? (e.g., Docker, database, external services)

#### 4.5: Update Contributing Setup Notes

1. Build a setup block from confirmed package managers and quality commands:
   - Python/uv: `uv sync && cp .env.example .env`
   - Python/poetry: `poetry install`
   - Node/npm: `npm install`
   - Node/pnpm: `pnpm install`
   - Node/bun: `bun install`
   - Go: `go mod download`
   - Multi-stack: create `### Backend` and `### Frontend` subsections

2. Replace `<CONTRIBUTING_SETUP_NOTES>` in `docs/guides/CONTRIBUTING.md` with the generated block. If the file does not exist, skip this step.

#### 4.6: Security Baseline (project type >= 3)

**Skip this sub-step if `3` < 3.**

Ask via AskUserQuestion:

- Authentication model? (OAuth2 / JWT / Session / API Key / None)
- Secret management approach? (e.g., env vars, Vault, AWS Secrets Manager, none yet)

Write to `project-constants.md` as `<AUTH_MODEL>` and `<SECRET_MANAGEMENT>`.
Detailed security design is deferred to design-feature.

**Q7: Repository paths** — ask via AskUserQuestion:

- Primary repo path? (detect from `$CLAUDE_PROJECT_DIR`, default: current working directory)
- Additional repos? (e.g., frontend, backend — list path + description for each)

Populate the Repository Paths table in `project-constants.md`:

```markdown
| Repository     | Description  | Absolute Path    |
| -------------- | ------------ | ---------------- |
| Weather App | Primary repo | /path/to/project |
```

> Paths are machine-specific. The table note already warns to update after cloning to a new machine.

After all answers:

1. Update `project-constants.md` with actual values (including Repository Paths)
2. Update `settings.local.json` with quality commands
3. Replace default placeholder values in all `.claude/` files

### Outputs

- Updated `project-constants.md` with repo structure, branch strategy, and quality values
- Updated `settings.local.json` with quality commands
- Security baseline constants (`<AUTH_MODEL>`, `<SECRET_MANAGEMENT>`) recorded (project type >= 3)
- All `.claude/` placeholder values replaced with actual values

### Exit Criteria

- Repo structure and branch strategy are recorded
- Quality commands are configured in `settings.local.json` (project type >= 3)
- Security baseline is captured (project type >= 3)
- All placeholder values in `.claude/` files are replaced

---

## Stage 5: Agent Configuration

### Inputs

- Tech stack selections from Stage 3
- `.claude/agents/` — full set of scaffolded agent files

### Activities

Based on tech stack from Stage 3, recommend which agents to keep:

| Condition             | Agents to Remove                                                                          |
| --------------------- | ----------------------------------------------------------------------------------------- |
| No backend framework  | backend-architect, backend-developer, backend-qa, backend-reviewer                        |
| No frontend framework | frontend-architect, frontend-designer, frontend-developer, frontend-qa, frontend-reviewer |
| Not an AI/bot project | bot-developer                                                                             |

1. Present recommendation via AskUserQuestion → get user approval
   - Show which agents will be kept and which will be removed
   - User can override (keep agents that would be removed, or remove additional ones)

2. Delete unneeded agent files from `.claude/agents/`:
   ```bash
   rm "$CLAUDE_PROJECT_DIR/.claude/agents/{agent-name}.md"
   ```

### Outputs

- Trimmed `.claude/agents/` directory containing only relevant agents

### Exit Criteria

- User has approved the agent configuration
- Unneeded agent files are deleted from `.claude/agents/`

---

## Stage 6: Standards & Context

### Inputs

- Tech stack selections from Stage 3
- `<DOC_PLATFORM>` from `project-constants.md`
- `evolv-coder-standards` repository (cloned or embedded defaults)

### Activities

1. **MUST** invoke `/eck:pull-from-standards` to pull fresh standards based on tech stack. Do NOT skip this step or use stale standards.

2. Display standards source notification:
   - On success:
     ```
     [x] Standards: fresh (compiled from evolv-coder-standards at {date})
     ```
   - On failure:
     ```
     [!] Standards: embedded defaults (clone failed: {reason})
     ```

3. **If Confluence configured (`<DOC_PLATFORM>` = Confluence):**
   - Collect Confluence detail questions via AskUserQuestion:
     - Label taxonomy prefix? (default: project key lowercase)
     - Key pages to reference? (list page IDs with titles)
   - Update `project-constants.md` with Confluence details (`wa`, `<PAGE_ID>`)
   - **MUST** run `/sync-context` to populate `.claude/context/project/`

4. **If Local docs (`<DOC_PLATFORM>` = Local markdown):**
   - Create `docs/` directory structure:
     ```bash
     mkdir -p docs/{guides,project,adrs}
     ```
   - **MUST** run `/sync-context` to populate `.claude/context/project/`

### Outputs

- Fresh or default standards in `.claude/context/standards/`
- `.claude/context/project/` populated via `/sync-context`
- Confluence details in `project-constants.md` (if Confluence platform)
- `docs/` directory structure created (if local markdown platform)

### Exit Criteria

- Standards are available (fresh or embedded defaults)
- Context is synced to `.claude/context/project/`
- Doc platform-specific configuration is complete

---

## Stage 7: Decisions (project type level >= 4)

**Skip this stage if `3` < 4.**

### Inputs

- Tech stack and architecture validation from Stage 3
- Security baseline from Stage 4 (`<AUTH_MODEL>`)
- `<DOC_PLATFORM>` and `<CONFLUENCE_SPACE_KEY>` from `project-constants.md`

### Activities

1. **MUST** dispatch architect agents for deep architecture design:
   - `backend-architect` → service architecture, data flow, API design patterns
   - `frontend-architect` → component hierarchy, state management, SSR vs CSR strategy
   - Do NOT perform architecture design yourself — agents MUST do this work.

2. At project type level >= 4: **MUST** dispatch `security-specialist` → auth model, threat surface analysis

3. Present architecture summary via AskUserQuestion → get user approval

4. Create ADRs:
   - **Local docs:** `docs/adrs/001-tech-stack.md`, `docs/adrs/002-architecture.md`, ...
   - **Confluence:** create pages with `adr` label in `<CONFLUENCE_SPACE_KEY>` space

### Outputs

- Architecture design documents from architect agents
- ADR files created (`docs/adrs/` or Confluence pages)

### Exit Criteria

- User has approved the architecture summary
- ADRs are written to the appropriate doc platform

---

## Stage 8: Documents

### Inputs

- Project vision from Stage 2 (problem, users, goals)
- Tech stack from Stage 3 (frameworks, databases, key libraries)
- Repository structure from Stage 4 (paths, branch strategy)
- Architecture decisions from Stage 7 (if applicable)
- `3` and `<DOC_PLATFORM>` from `project-constants.md`

### Activities

Output depends on project type level and doc platform.

#### Local (`<DOC_PLATFORM>` = "Local markdown")

| Level | Files Created                                           |
| ----- | ------------------------------------------------------- |
| 1-2   | `docs/project/VISION.md`                                |
| 3-5   | `docs/project/BRD.md`, `docs/project/PRD.md`            |
| 5     | Fill in `project-constitution.md` (root-level template) |

#### Confluence

| Level | Pages Created                                                  |
| ----- | -------------------------------------------------------------- |
| 1-2   | Project Brief page (label: `prd`, `accepted`)                  |
| 3-5   | BRD page, PRD page (labels: `prd`, `accepted`)                 |
| 5     | Architecture Overview page (label: `architecture`, `accepted`) |

#### Document Content Sources

Use the following information gathered during this workflow to generate documents:

- Project vision (Stage 2): problem, users, goals
- Tech stack (Stage 3): frameworks, databases, key libraries
- Architecture decisions (Stage 7, if applicable): service patterns, component hierarchy
- Repository structure (Stage 4): paths, branch strategy

### Outputs

- Project documentation files appropriate to project type level (brief, BRD, PRD, constitution)
- Documents written to local `docs/` or Confluence pages

### Exit Criteria

- All documents required for the project type level are created
- Documents contain substantive content drawn from interview phases (not empty templates)

---

## Stage 9: Feature Backlog

### Inputs

- All interview answers from Phases 2-7
- Architecture decisions and tech stack context
- `GitHub` from `project-constants.md`

### Activities

1. Based on interview answers + architecture decisions, create outline-level feature list
2. Each feature MUST include:
   - Name
   - 1-2 sentence description
   - Rough size: S / M / L
   - Priority: P1 / P2 / P3

3. Present for user approval via AskUserQuestion
   - User can add, remove, or modify features
   - User can adjust priorities and sizes

4. After approval, register each feature in the lifecycle backlog:

   ```bash
   # For each approved feature:
   PRIORITY_NUM=1  # P1=1, P2=2, P3=3
   node $ECK_HOME/update-lifecycle.js register "$FEATURE_NAME" \
     --description "$DESCRIPTION" --priority $PRIORITY_NUM
   ```

   Features are registered in `backlog` state (no activation, no `first_started_at`).

5. **If tracker configured (JIRA, Linear, GitHub Issues):** also create tracker issues:

   ```bash
   # Resolve via tracker:router → tracker:issue-create
   ISSUE_RESULT=$(tracker:issue-create --title "$FEATURE_NAME" --label "epic" --body "$DESCRIPTION" 2>/dev/null || echo "")
   ISSUE_NUMBER=$(echo "$ISSUE_RESULT" | grep -oE '[0-9]+$')
   [ -n "$ISSUE_NUMBER" ] && node $ECK_HOME/update-lifecycle.js register "$FEATURE_NAME" --issue $ISSUE_NUMBER
   ```

   - **If tracker plugin unavailable:** STOP with error:
     `"GitHub plugin is not installed or not responding. Install the required plugin or run /eck:switch-tracker to change tracker type."`
     Do NOT silently fall back to local-only.

6. Write `docs/project/BACKLOG.md` with the approved feature list (formatted as a table with name, description, size, priority).

### Outputs

- Approved feature list registered in `.claude/lifecycle.json` in `backlog` state
- `docs/project/BACKLOG.md` with formatted feature list
- Tracker issues created (if tracker configured)

### Exit Criteria

- User has approved the feature backlog
- All features registered in lifecycle.json
- Features are in `backlog` state (not activated)

---

## Stage 10: Completion

### Inputs

- All configuration from Phases 1-9
- Feature list from Stage 9
- Documents created in Stage 8
- `.claude/context/project/` — context to finalize

### Activities

#### Step 0: Sync Context

**MUST** invoke `/sync-context` to compile all gathered context (standards, docs, architecture decisions) into `.claude/context/project/` for use by subsequent skills. Do NOT skip this step.

#### Step 1: Write Completion Marker

Write `.claude/.start-project-completed`:

```bash
cat > "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" << 'EOF'
{
  "completed_at": "{TIMESTAMP}",
  "project_type_level": 3,
  "tech_stack": {
    "frontend": "{FRONTEND_FRAMEWORK}",
    "backend": "{BACKEND_FRAMEWORK}",
    "database": "{DATABASE}"
  },
  "features_created": {FEATURE_COUNT},
  "docs_created": ["{DOC_LIST}"]
}
EOF
```

#### Step 2: Update Registry

**Reference:** `ops:registry-update` primitive for the canonical write procedure.

If registry does not exist, log warning and skip this step.

Update the project's entry in `$ECK_HOME/registry.yaml`:

- `deployment.start_project_completed: true`
- `enrichment.tech_stack`: summary string from Stage 3 tech stack selections
- `enrichment.last_enriched`: current ISO-8601 date
- `last_modified_at`: current ISO-8601 date

Append to sync_history:

```yaml
- date: "{DATE}"
  action: "start-project-completed"
  performed_by: "/start-project"
  summary: "Tech stack: {STACK}"
```

Recompute `project_summary` per the `ops:registry-update` primitive.

Use atomic write: write to `registry.yaml.tmp`, then rename to `registry.yaml`.

#### Step 3: Display Summary

```
## Project Kickoff Complete

**Project:** Weather App (WA)
**Project Type:** Level 3
**Tech Stack:** {FRONTEND} + {BACKEND} + {DATABASE}

#### What Was Configured

| Category | Details |
|----------|---------|
| Tech Stack | {framework summary} |
| Repository | {repo structure summary} |
| Agents | {N} active (trimmed from 16) |
| Standards | {compiled/default} |
| Documents | {list of docs created} |
| Features | {N} features defined |

#### Lifecycle Commands

| Session | Command | Purpose |
|---------|---------|---------|
| Specify | `/eck:spec "description"` | Gather requirements and interview |
| Planning | `/eck:design "description"` | Research, design, document, create tasks |
| Development | `/eck:develop {KEY}-123` | Execute feature tasks |
| Validation | `/eck:validate` | Run quality gates |
| Deployment | `/eck:deploy` | Ship to environment |

#### Useful Commands

| Command | Purpose |
|---------|---------|
| `/eck:spec <desc>` | Define feature requirements |
| `/eck:design <desc>` | Plan a feature (after spec) |
| `/eck:develop <key>` | Execute feature tasks |
| `/eck:validate` | Run quality gates |
| `/eck:deploy` | Ship to environment |
| `/dev-sprint` | Execute a sprint's worth of tasks |
| `/learn <topic>` | Capture session learning |
| `/retrospective` | End-of-session analysis |

#### Next Steps

Select your first feature from the backlog:
   /eck:select-feature

The lifecycle is: select → spec → design → develop → validate → deploy
```

### Post-Setup Checklist

Verify these items before proceeding:

```bash
# Configuration complete
test -f "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" && echo "[x] Completion marker" || echo "[!] Completion marker MISSING"
grep -q "Weather App" "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" && echo "[!] Unreplaced placeholders" || echo "[x] Constants populated"

# Context synced
test -d "$CLAUDE_PROJECT_DIR/.claude/context/standards" && echo "[x] Standards context" || echo "[!] Standards MISSING"
test -d "$CLAUDE_PROJECT_DIR/.claude/context/project" && echo "[x] Project context" || echo "[!] Project context MISSING"

# Docs structure
test -f "$CLAUDE_PROJECT_DIR/docs/INDEX.md" && echo "[x] docs/INDEX.md" || echo "[!] docs/ skeleton MISSING"

# No conditional sections left
grep -q "START:CONFLUENCE" "$CLAUDE_PROJECT_DIR/.claude/project-constants.md" && echo "[!] Conditional section markers not cleaned" || echo "[x] Constants trimmed"

# git-status collector configured
grep -q "Weather App\|{TARGET_PATH}\|{REPO_NAME}\|{REPO_PATH}" "$CLAUDE_PROJECT_DIR/.claude/skills/git-status/collect.sh" 2>/dev/null && echo "[!] git-status collect.sh has unresolved placeholders" || echo "[x] git-status configured"
```

### Outputs

- `.claude/.start-project-completed` marker file with project metadata
- Final context sync to `.claude/context/project/`
- Project kickoff summary displayed to user
- Post-setup checklist verified

### Exit Criteria

- Completion marker is written with accurate metadata
- Context is synced and up to date
- User has seen the summary and next-steps guidance
- Post-setup checklist passed
- Statusline is reset via `update-stage.sh`

---

## Error Handling

| Condition                      | Behavior                                                                                 |
| ------------------------------ | ---------------------------------------------------------------------------------------- |
| project-constants.md missing   | Display error and STOP — run `/eck:new-project` first                                    |
| Standards clone fails          | Log warning, continue with embedded defaults                                             |
| Architect agent dispatch fails | Log warning, continue without architecture validation                                    |
| Tracker issue creation fails   | STOP with actionable error — do NOT silently fall back to local-only (per Stage 9 rules) |
| sync-context fails             | Log warning, continue — context can be synced manually later                             |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
