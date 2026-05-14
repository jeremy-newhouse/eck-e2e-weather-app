---
name: wa:dev-test
version: "0.7.4"
description: "Generate failing tests from acceptance criteria (TDD red phase)."
disable-model-invocation: false
---

# Develop Test

Generate failing tests for: $ARGUMENTS

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject             | Active Form       | Statusline      |
| ----- | ------------------- | ----------------- | --------------- |
| 1     | Stage 1: Pre-Flight | Verifying prereqs | Preflight (1/4) |
| 2     | Stage 2: Inputs     | Gathering inputs  | Inputs (2/4)    |
| 3     | Stage 3: Plan       | Planning tests    | Plan (3/4)      |
| 4     | Stage 4: Generate   | Generating tests  | Generate (4/4)  |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Usage

```
/dev-test {issue key or description}
/dev-test --rigor lite {issue key}
/dev-test --rigor strict {issue key}
```

Generate a failing test suite from acceptance criteria before development begins. This is the TDD "red phase" — all generated tests must fail when run against the current codebase.

---

## Stage 1: Pre-Flight

### Inputs

- `$ARGUMENTS` — issue key or description and optional `--rigor` flag
- `mode:read-dev-rigor` primitive — development mode resolution
- `.claude/project-constants.md` — project constants and test framework configuration
- Existing test directory — test pattern conventions

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Test depth: {happy path only|happy + error paths|happy + error + edge + boundary}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

3. Apply mode calibration to test depth:
   - **Lite**: Happy path only — one test per acceptance criterion, skip error and edge cases
   - **Standard**: Happy path + error paths — test both success and failure for each acceptance criterion
   - **Strict**: Happy path + error paths + edge cases + boundary conditions — comprehensive coverage

4. Read project constants and test framework configuration from `.claude/project-constants.md`.

5. Scan the test directory for existing test patterns to ensure new tests follow project conventions.

### Outputs

- Resolved development mode and test depth calibration
- Mode banner displayed to user
- Project constants and test framework configuration loaded
- Existing test conventions identified

### Exit Criteria

- Development mode resolved and displayed
- Test depth determined for all subsequent phases
- Project test framework and conventions identified

---

## Stage 2: Inputs

### Inputs

- `$ARGUMENTS` — issue key or description text
- Configured tracker (via tracker:router) for issue fetching
- `codebase:read` primitive — source file analysis
- `package.json`, `pyproject.toml`, or `setup.cfg` — test framework detection
- `.claude/project-constants.md` — `npm test` fallback

### Activities

1. Read acceptance criteria from the issue or $ARGUMENTS:
   - If $ARGUMENTS contains a tracker issue key (e.g., `WA-123`), fetch the full issue from the configured tracker
   - Otherwise, use the text of $ARGUMENTS as the acceptance criteria directly

2. Use `codebase:read` to understand the module under test:
   - Identify the file(s) the new tests will exercise
   - Read existing type signatures, interfaces, and function contracts
   - Note any current test coverage for those modules

3. Identify the test framework from project configuration:
   - Check `package.json` (`jest`, `vitest`, `mocha`, etc.)
   - Check `pyproject.toml` or `setup.cfg` (`pytest`)
   - Check `.claude/project-constants.md` for `npm test` if framework is ambiguous
   - If not determinable, ask the user before proceeding

### Outputs

- Acceptance criteria extracted from issue or `$ARGUMENTS`
- Module-under-test analysis (files, type signatures, interfaces, existing coverage)
- Identified test framework and conventions

### Exit Criteria

- Acceptance criteria available and understood
- Module under test identified with type signatures and contracts read
- Test framework determined (or user prompted if ambiguous)

---

## Stage 3: Plan

### Inputs

- Acceptance criteria from Stage 2
- Module-under-test analysis from Stage 2
- Test depth calibration from Stage 1 (mode-dependent)

### Activities

1. Build a test plan mapping table before writing any code. Scope rows by mode:
   - **Lite**: Happy path rows only
   - **Standard**: Happy path + error path rows
   - **Strict**: Happy path + error path + edge case + boundary rows

   | AC # | Acceptance Criterion     | Test Case(s)                  | Type       | Mode    |
   | ---- | ------------------------ | ----------------------------- | ---------- | ------- |
   | AC-1 | [criterion text]         | test\_[description]           | happy path | all     |
   | AC-1 | [criterion text]         | test\_[description]\_error    | error path | std+rig |
   | AC-2 | [criterion text]         | test\_[description]           | happy path | all     |
   | ...  | Edge case: [description] | test\_[description]\_edge     | edge case  | strict  |
   | ...  | Boundary: [description]  | test\_[description]\_boundary | boundary   | strict  |

2. Present the test plan to the user for approval before generating any test code.

3. Do NOT proceed to Stage 4 without explicit user approval.

### Outputs

- Test plan mapping table linking acceptance criteria to test cases
- User approval of the test plan

### Exit Criteria

- Test plan table complete with all rows scoped to current mode
- User has explicitly approved the test plan

---

## Stage 4: Generate

### Inputs

- Approved test plan from Stage 3
- Test framework and conventions from Phases 1-2
- Module-under-test analysis from Stage 2
- `npm test` from `.claude/project-constants.md`

### Activities

1. Write test files following the project's existing test conventions:
   - Place test files adjacent to source files or in the designated test directory per project convention
   - Use descriptive test file names that identify the module under test
   - Include a comment at the top of each file referencing the acceptance criteria source (issue key or description)

2. Framework-specific patterns:

   **Backend (Python / pytest)**
   - Async test functions: `async def test_...()`
   - Use fixtures for dependencies (DB sessions, authenticated clients)
   - Use factory functions for test data — not raw dicts
   - Assert specific error codes and messages, not just that a call fails

   **Frontend (TypeScript / React + Vitest or Jest)**
   - Component tests: render, interact, assert using Testing Library
   - Hook tests: `renderHook` with `act`
   - Mock external dependencies (API calls, auth providers)
   - Prefer role-based queries over test ID selectors

   **Other frameworks**: Follow the conventions found in Stage 1 scan of existing test files.

3. **MUST** execute `npm test` from project-constants.md to verify all generated tests fail when run. Do NOT skip test execution.
   - New tests must show as failures or compile-time errors (both are valid red states)
   - If any new test passes unexpectedly, flag it before completing

4. Output summary:
   - List of test files created with paths
   - Total test count
   - Confirmation that all tests are in red state
   - Links back to acceptance criteria for each test group

### Outputs

- Test files written to project following conventions
- Test execution results confirming red state
- Summary report: files created, test count, red state confirmation, AC links

### Exit Criteria

- All test files written and placed per project conventions
- All generated tests fail against the current codebase (red phase confirmed)
- Summary displayed to user
- Statusline reset

---

## Error Handling

- **Test framework not detected**: Ask the user to specify the framework before proceeding to Stage 4.
- **No acceptance criteria found**: If the issue key does not resolve or $ARGUMENTS contains no recognizable criteria, stop and ask the user to provide acceptance criteria directly.
- **Tests pass immediately (not red)**: Flag each unexpectedly passing test by name. Ask the user: "The following tests pass without any development: [list]. This may indicate the feature already exists or the tests are trivially true. How should we proceed?"
- **Skill error or interrupt**: Reset the statusline before exiting:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
