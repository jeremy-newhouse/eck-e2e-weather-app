# Project Constants

Pre-computed task tracker and project values. Referenced by skills and agents.

**Last Updated:** 2026-05-14

---

## Project Identity

| Constant              | Value                                                              | Description                                        |
| --------------------- | ------------------------------------------------------------------ | -------------------------------------------------- |
| PROJECT_NAME          | Weather App                                                        | Project display name                               |
| PROJECT_KEY           | WA                                                                 | Project identifier                                 |
| PROJECT_KEY_LOWERCASE | wa                                                                 | Lowercased PROJECT_KEY — derived, do not edit      |
| PROJECT_DESCRIPTION   | A full-stack weather app with Express.js backend and HTML frontend | Project description                                |
| CONFLUENCE_ENABLED    | false                                                              | Enable Confluence publishing (boolean: true/false) |

<!-- Migration: DOC_PLATFORM is deprecated. If found, map Confluence→true, Local→false -->

---

## Task Tracker Constants

| Constant             | Value                                                  | Description                                                                  |
| -------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| TRACKER_TYPE         | GitHub                                                 | JIRA \| GitHub \| Linear \| none                                             |
| TRACKER_URL          | https://github.com/jeremy-newhouse/eck-e2e-weather-app | Task tracker instance URL                                                    |
| BOARD_ID             |                                                        | Agile board ID                                                               |
| BOARD_NAME           |                                                        | Board display name                                                           |
| ASSIGNEE_ID          |                                                        | Default assignee ID                                                          |
| ASSIGNEE_NAME        |                                                        | Default assignee name                                                        |
| TRACKER_SYNC_ENABLED | false (derived)                                        | Set by preflight, not user-configurable. true when tracker preflight passes. |

---

<!-- START:CONFLUENCE — Remove this section if CONFLUENCE_ENABLED != true -->

## Confluence Constants

| Constant               | Value | Description        |
| ---------------------- | ----- | ------------------ |
| CONFLUENCE_SPACE_KEY   |       | Space key          |
| CONFLUENCE_SPACE_ID    |       | Space numeric ID   |
| CONFLUENCE_SPACE_NAME  |       | Space display name |
| CONFLUENCE_HOMEPAGE_ID |       | Homepage page ID   |
| LABEL_PREFIX           | wa    | Label prefix       |

<!-- END:CONFLUENCE -->

---

## Repository Paths

> Machine-local paths are not stored in this file. See `.claude/project-paths.local.md` (copy from `project-paths.local.md.example` on first checkout — gitignored, machine-specific).

---

## Application Paths

| Constant      | Value   | Description                          |
| ------------- | ------- | ------------------------------------ |
| FRONTEND_PATH | public/ | Frontend source root (if applicable) |
| BACKEND_PATH  |         | Backend source root (if applicable)  |

---

## Branch Configuration

| Branch             | Purpose                 |
| ------------------ | ----------------------- |
| main               | Production (protected)  |
| dev                | Integration (protected) |
| feat/WA-XXX-name   | Feature development     |
| hotfix/WA-XXX-name | Emergency fixes         |

### Branch Names (Constants)

| Constant    | Value | Description             |
| ----------- | ----- | ----------------------- |
| DEV_BRANCH  | dev   | Integration branch name |
| MAIN_BRANCH | main  | Production branch name  |

---

## Quality Gate Configuration

| Gate   | Backend Command | Frontend Command |
| ------ | --------------- | ---------------- |
| Tests  | npm test        | npm test         |
| Lint   | npm run lint    | npm run lint     |
| Format |                 |                  |
| Types  |                 |                  |

<!-- Type check examples by language:
  Python (mypy):   uv run mypy .        or  mypy .
  Python (pyright): uv run pyright      or  pyright
  TypeScript:      npx tsc --noEmit     or  tsc --noEmit
  Go:              go vet ./...
  If N/A, validate-quality auto-detects from config files (mypy.ini, pyrightconfig.json, pyproject.toml, tsconfig.json).
-->

### Command Constants

| Constant          | Value             | Description                        |
| ----------------- | ----------------- | ---------------------------------- |
| TEST_COMMAND      | npm test          | Primary test command               |
| LINT_COMMAND      | npm run lint      | Lint command for this project      |
| TYPECHECK_COMMAND | npm run typecheck | Typecheck command for this project |

---

## Project Configuration

| Constant             | Value    | Description                                              |
| -------------------- | -------- | -------------------------------------------------------- |
| PROJECT_TYPE         | 3        | Project type level (1-5) — source of truth               |
| DEV_RIGOR            | standard | Auto-derived from project type (do not set directly)     |
| CONFLUENCE_SPACE_KEY |          | Confluence space key (n/a when CONFLUENCE_ENABLED=false) |

Type mapping: 1-2=lite, 3=standard, 4-5=strict
Override per-session with: --rigor lite|standard|strict

---

## Learning Configuration

| Constant          | Value   | Description                                             |
| ----------------- | ------- | ------------------------------------------------------- |
| LEARNING_AUTONOMY | advisor | Learning autonomy level (observer\|advisor\|autonomous) |

---

## Standards Repository

| Constant              | Value                                                    | Description                   |
| --------------------- | -------------------------------------------------------- | ----------------------------- |
| STANDARDS_REPO_URL    | https://github.com/evolvconsulting/evolv-coder-standards | GitHub repo URL for standards |
| STANDARDS_REPO_BRANCH | main                                                     | Branch to pull from           |

**Defaults:**

- `STANDARDS_REPO_URL`: `https://github.com/evolvconsulting/evolv-coder-standards`
- `STANDARDS_REPO_BRANCH`: `main`

---

## Loop & Retry Configuration

> Controls iteration limits for retry/rework loops across skills. See audit inventory for full details.

| Constant                  | Value    | Description                                                                               |
| ------------------------- | -------- | ----------------------------------------------------------------------------------------- |
| MAX_GATE_RETRIES          | 3        | Max re-runs for review gates (spec-review, design-review, validate-review, deploy-review) |
| MAX_APPROVAL_ROUNDS       | 10       | Max approval iterations (spec-criteria, spec-discovery)                                   |
| MAX_AGENT_LOOP_ITERATIONS | 5        | Default for agent:loop primitive (orchestrate)                                            |
| MAX_AGENT_LOOP_HARD_CAP   | 10       | Absolute ceiling for agent:loop                                                           |
| MAX_SPRINT_TASK_RETRIES   | 2        | Max retries per task in dev-sprint                                                        |
| LOOP_EXHAUSTION_ACTION    | escalate | What happens at max: escalate (to user) or fail                                           |

---

## Code Review Configuration

| Constant           | Value         | Description                                       |
| ------------------ | ------------- | ------------------------------------------------- |
| CODE_REVIEW_PLUGIN | not-installed | PR code review plugin: installed \| not-installed |

Set by `/start-project` preflight. Determines review mechanism in `/validate-code`:
Greptile (if MCP configured) > code-review plugin (if installed) > ECK reviewer agents (fallback)

---

<!-- START:OVERRIDES — Remove if no backend overrides configured -->

## Plugin & Backend Overrides

| Constant                 | Value | Description                            |
| ------------------------ | ----- | -------------------------------------- |
| TRACKER_BACKEND_OVERRIDE |       | Custom tracker backend (empty=default) |
| DOC_BACKEND_OVERRIDE     |       | Custom docs backend (empty=default)    |

<!-- END:OVERRIDES -->
