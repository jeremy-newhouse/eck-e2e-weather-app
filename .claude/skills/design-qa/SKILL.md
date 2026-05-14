---
name: wa:design-qa
version: "0.7.4"
description: "QA plan and test strategy: test scope, environments, coverage targets, and automation approach."
disable-model-invocation: false
---

# Design QA

Generate a QA plan for: $ARGUMENTS

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill produces planning artifacts — no implementation.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form       | Statusline     |
| ----- | ----------------- | ----------------- | -------------- |
| 1     | Stage 1: Context  | Loading context   | Context (1/4)  |
| 2     | Stage 2: Strategy | Defining strategy | Strategy (2/4) |
| 3     | Stage 3: Plan     | Building QA plan  | Plan (3/4)     |
| 4     | Stage 4: Document | Writing QA plan   | Document (4/4) |

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

## Usage

```
/design-qa <feature-description> [--rigor lite|standard|strict]
```

Examples:

```
/design-qa user notification preferences
/design-qa CSV export pipeline --rigor strict
/design-qa OAuth2 login with session management
```

**Output:** `docs/{feature}/QA-PLAN.md` containing test strategy, coverage targets, and environment requirements.

---

## Stage 1: Context

Load all available planning artifacts before defining the QA strategy.

### Inputs

- `$ARGUMENTS` — feature description
- `.claude/project-constants.md` — project key, tech stack, quality commands
- `docs/{feature}/FRD.md` — acceptance criteria with AC-IDs (if present)
- `docs/{feature}/ARCHITECTURE.md` — architecture design (if present)
- `docs/{feature}/DESIGN.md` — detailed design (if present)
- `docs/{feature}/NFR.md` — non-functional requirements (if present)
- Development mode via `mode:read-dev-rigor` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Resolve development mode using the `mode:read-dev-rigor` primitive.

3. Load prior artifacts in order:
   - FRD.md — extract AC-IDs for test case mapping
   - ARCHITECTURE.md — identify integration points
   - DESIGN.md — identify component boundaries
   - NFR.md — extract performance, security, and reliability targets

4. Extract quality commands from project constants:
   - `<TEST_CMD_FRONTEND>`, `<TEST_CMD_BACKEND>`
   - `<LINT_CMD_FRONTEND>`, `<LINT_CMD_BACKEND>`
   - `<E2E_TEST_CMD>` (if configured)

5. Display context summary listing loaded artifacts and test infrastructure.

### Outputs

- AC-IDs loaded for test case mapping
- Quality infrastructure identified
- Context summary displayed

### Exit Criteria

- Project constants loaded
- Development mode resolved
- All available prior artifacts catalogued

---

## Stage 2: Strategy

Define the test strategy based on feature scope and rigor level.

### Inputs

- Context summary from Stage 1
- AC-IDs from FRD.md
- Architecture and design artifacts
- Development mode

### Activities

1. Determine test scope based on mode:

   | Mode         | Test Layers                                       | Coverage Target        |
   | ------------ | ------------------------------------------------- | ---------------------- |
   | **Lite**     | Unit tests only                                   | Happy-path ACs covered |
   | **Standard** | Unit + integration tests                          | All active ACs covered |
   | **Strict**   | Unit + integration + E2E + security + performance | All ACs + NFRs covered |

2. Map AC-IDs to test types:

   For each AC-ID in FRD.md, determine:
   - **Test type**: Unit, Integration, E2E, Manual, or Security
   - **Component**: Which module/service owns this test
   - **Priority**: P1 (must-have), P2 (should-have), P3 (nice-to-have)

3. Identify test environment requirements:
   - Local development (always)
   - CI pipeline (Standard+)
   - Staging environment (Strict)
   - Performance test environment (Strict, if NFRs exist)

4. Define coverage targets:
   - Line/branch coverage thresholds
   - AC-ID coverage percentage
   - NFR verification scope

5. Present strategy summary to user via `AskUserQuestion` for approval.

### Outputs

- Test scope and layer definitions
- AC-ID to test type mapping
- Environment requirements
- Coverage targets
- User-approved strategy

### Exit Criteria

- Test strategy confirmed by user
- All active AC-IDs mapped to test types

---

## Stage 3: Plan

Build the detailed QA plan from the approved strategy.

### Inputs

- Approved test strategy from Stage 2
- AC-ID to test type mapping
- Environment requirements

### Activities

1. For each test layer, define:

   **Unit Tests**
   - Components to test
   - Key test scenarios per component
   - Mocking strategy for external dependencies

   **Integration Tests** (Standard+)
   - Integration points to verify
   - Test data requirements
   - Service dependency management (Docker, test doubles)

   **E2E Tests** (Strict)
   - Critical user flows to cover
   - Browser/platform matrix (if frontend)
   - Test data seeding approach

   **Security Tests** (Strict)
   - OWASP checks applicable to this feature
   - Authentication/authorization test scenarios
   - Input validation and injection tests

   **Performance Tests** (Strict, if NFRs exist)
   - Load test scenarios from NFR targets
   - Baseline measurements needed
   - Tooling requirements (k6, artillery, etc.)

2. Define the test execution order:
   - Pre-commit: unit tests + lint
   - CI: unit + integration
   - Pre-merge: full suite including E2E (if configured)
   - Pre-release: security + performance (if Strict)

3. Identify automation opportunities:
   - Which tests can be fully automated
   - Which require manual verification
   - CI pipeline integration points

### Outputs

- Detailed test plan per layer
- Test execution order
- Automation assessment

### Exit Criteria

- All test layers defined with scenarios
- Execution order documented
- Automation opportunities identified

---

## Stage 4: Document

Write the QA plan to `docs/{feature}/QA-PLAN.md`.

### Inputs

- Complete test plan from Stage 3
- AC-ID mapping from Stage 2
- `$ARGUMENTS` — feature description

### Activities

1. Determine the output path:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write the QA plan:

   ```markdown
   # QA Plan: {Feature Name}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Status:** Draft
   **Rigor:** {lite|standard|strict}

   ## Test Strategy

   | Layer       | Scope   | Coverage Target |
   | ----------- | ------- | --------------- |
   | Unit        | {scope} | {target}        |
   | Integration | {scope} | {target}        |
   | E2E         | {scope} | {target}        |
   | Security    | {scope} | {target}        |
   | Performance | {scope} | {target}        |

   ## AC-ID Test Mapping

   | AC-ID    | Test Type   | Component   | Priority | Automated |
   | -------- | ----------- | ----------- | -------- | --------- |
   | AC-1     | Unit        | {component} | P1       | Yes       |
   | AC-2     | Integration | {component} | P1       | Yes       |
   | AC-SEC-1 | Security    | {component} | P1       | Partial   |

   ## Test Layers

   ### Unit Tests

   {detailed scenarios}

   ### Integration Tests

   {detailed scenarios}

   ### E2E Tests

   {detailed scenarios, if applicable}

   ### Security Tests

   {detailed scenarios, if applicable}

   ### Performance Tests

   {detailed scenarios, if applicable}

   ## Test Environments

   | Environment | Purpose          | Setup                |
   | ----------- | ---------------- | -------------------- |
   | Local       | Development      | {setup instructions} |
   | CI          | Automated checks | {pipeline config}    |
   | Staging     | Pre-release      | {requirements}       |

   ## Test Execution Order

   1. Pre-commit: {commands}
   2. CI pipeline: {commands}
   3. Pre-merge: {commands}
   4. Pre-release: {commands}

   ## Test Data Requirements

   {seed data, fixtures, test doubles}

   ## Automation Assessment

   | Category    | Automated | Manual | Notes   |
   | ----------- | --------- | ------ | ------- |
   | Unit        | {N}       | 0      | {notes} |
   | Integration | {N}       | {N}    | {notes} |
   | E2E         | {N}       | {N}    | {notes} |

   ## Open Questions

   {unresolved testing questions}
   ```

3. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/QA-PLAN.md" && echo "[x] QA-PLAN.md written" || echo "[!] Write failed"
   ```

4. Print completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}QA Plan Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Rigor: {MODE}"
   printf '%b\n' "Test layers: {N} defined"
   printf '%b\n' "AC coverage: {N}/{TOTAL} ACs mapped"
   printf '%b\n' "Automated: {N}% automatable"
   printf '%b\n' "Output: docs/{feature}/QA-PLAN.md"
   echo ""
   ```

5. Print next steps:
   ```
   Next steps:
   - Assess risks: /design-risk {$ARGUMENTS}
   - Start implementation: /eck:develop
   ```

### Outputs

- `docs/{feature}/QA-PLAN.md` written
- Completion summary displayed

### Exit Criteria

- QA-PLAN.md written and verified on disk
- Completion summary and next steps printed

---

## Error Handling

| Condition                           | Behavior                                                                               |
| ----------------------------------- | -------------------------------------------------------------------------------------- |
| No `project-constants.md` found     | STOP: "Run `/start-project` first to define project constants."                        |
| No FRD.md found                     | Warn; generate test plan from $ARGUMENTS and available artifacts without AC-ID mapping |
| No architecture or design artifacts | Warn; generate test plan at higher level without component-specific tests              |
| Docs directory write fails          | Output QA-PLAN.md content inline; instruct user to save manually                       |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `scaffold/project/skills/design-solution/SKILL.md` — architecture design (input)
- `scaffold/project/skills/design-specs/SKILL.md` — specification artifacts (input)
- `scaffold/project/skills/design-risk/SKILL.md` — risk assessment (run after)
