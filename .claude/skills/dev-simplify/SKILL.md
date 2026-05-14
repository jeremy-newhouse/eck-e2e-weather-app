---
name: wa:dev-simplify
version: "0.7.4"
description: "Post-development code simplification: deduplication, naming, dead code removal."
disable-model-invocation: false
---

# Develop Simplify

Simplify and clean up code after development: $ARGUMENTS

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject           | Active Form        | Statusline     |
| ----- | ----------------- | ------------------ | -------------- |
| 1     | Stage 1: Scan     | Scanning code      | Scan (1/3)     |
| 2     | Stage 2: Simplify | Simplifying code   | Simplify (2/3) |
| 3     | Stage 3: Validate | Validating changes | Validate (3/3) |

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
/dev-simplify
/dev-simplify feat/WA-123-short-description
```

Run after development is complete to remove duplication, improve naming, and eliminate dead code without changing observable behavior. Skipped automatically in lite mode.

**Mode behavior:**

- **Lite**: Skip this skill entirely — exit immediately after reading mode
- **Standard / Strict**: Run all three phases

---

## Stage 1: Scan

### Inputs

- `$ARGUMENTS` — optional branch name for diff target
- `mode:read-dev-rigor` primitive — development mode resolution
- Feature branch changed files via `git diff`

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.
   - **Lite mode**: Stop here. Output: "Simplification skipped in lite mode." Reset statusline and exit.

2. Identify all files changed in the current feature branch relative to the base branch:

   ```bash
   git diff --name-only {BASE_BRANCH}...HEAD
   ```

   If $ARGUMENTS contains a branch name, use that branch. Otherwise use the current branch.

3. Load each changed file for analysis.

4. Detect simplification opportunities across the changed files:

   | Category                 | Examples                                                                                            |
   | ------------------------ | --------------------------------------------------------------------------------------------------- |
   | Code duplication         | Repeated logic blocks, copy-pasted functions                                                        |
   | Poor naming              | Single-letter variables outside loops, misleading function names, abbreviated names without context |
   | Dead code                | Unused imports, unreferenced variables, functions never called                                      |
   | Overly complex logic     | Nested conditionals that can be flattened, manual loops replaceable with standard library calls     |
   | Unnecessary abstractions | Wrapper classes that add no value, over-parameterized functions                                     |

5. Produce a prioritized list of simplification candidates with file, line range, category, and proposed change for each.

### Outputs

- List of changed files in the feature branch
- Prioritized simplification candidates with file, line range, category, and proposed change

### Exit Criteria

- Development mode resolved (or skill exited for lite mode)
- All changed files loaded and analyzed
- Simplification candidate list produced and prioritized

---

## Stage 2: Simplify

### Inputs

- Changed files list from Stage 1
- Simplification candidate list from Stage 1
- Base branch reference for diff
- `agent:dispatch` primitive — agent dispatch mechanism
- `review:simplifier` primitive — simplification rules

### Activities

1. **MUST** dispatch `code-simplifier` agent via `agent:dispatch` with the `review:simplifier` primitive. Do NOT skip agent dispatch and perform simplification inline. Pass:
   - The list of changed files from Stage 1
   - The candidate list from Stage 1
   - The base branch for diff reference
   - Instruction: "Apply only changes that preserve observable behavior. Do not refactor logic, only reduce complexity and remove redundancy."

2. For each simplification applied:
   - **Deduplication**: Extract shared logic into a clearly named helper function or module. Update all call sites.
   - **Renaming**: Replace unclear identifiers with names that state intent. Update all references in the changed files.
   - **Dead code removal**: Delete unused imports, variables, and unreachable functions.
   - **Control flow simplification**: Flatten deeply nested conditionals. Replace verbose loops with idiomatic equivalents.

3. Each simplification is isolated and independently reviewable — one logical change per commit is preferred.

4. Commit simplification changes as a separate atomic commit:
   ```
   refactor: simplify {scope}
   ```
   where `{scope}` describes the area simplified (e.g., `user-auth helpers`, `payment retry logic`).

### Outputs

- Simplified source files with applied changes
- Atomic commit(s) with `refactor: simplify {scope}` message

### Exit Criteria

- All viable simplification candidates applied or skipped with reason
- Each simplification committed as an isolated, reviewable change
- No observable behavior changes introduced

---

## Stage 3: Validate

### Inputs

- Simplified source files from Stage 2
- `review:test` primitive — test execution
- `review:lint` primitive — lint verification
- `npm test` and `npm run lint` from `.claude/project-constants.md`

### Activities

1. **MUST** run `review:test` to confirm tests still pass after simplification:

   ```bash
   npm test
   ```

   - If any test fails, identify which simplification caused the failure, revert that specific change, and report it.
   - Re-run tests after each revert to confirm the suite is green before proceeding.

2. **MUST** run `review:lint` to confirm no new lint issues were introduced:

   ```bash
   npm run lint
   ```

   - Fix any new issues introduced by simplification before completing.

3. Output a summary of all changes made:
   - Files modified
   - Count of simplifications applied by category
   - Any simplifications reverted and the reason

4. Reset the statusline:
   ```bash
   bash $ECK_HOME/update-stage.sh
   ```

### Outputs

- Green test suite confirming no regressions
- Clean lint report
- Summary of all changes: files modified, simplification counts by category, any reverted changes

### Exit Criteria

- All tests pass after simplification
- No new lint issues introduced
- Summary displayed to user
- Statusline reset

---

## Error Handling

- **Simplification breaks tests**: Revert the specific change that caused the failure. Report which simplification failed and why. Continue with remaining candidates.
- **Observable behavior change detected**: If a proposed simplification would alter return values, side effects, or error behavior, skip it and note it in the summary. Never simplify code that changes observable behavior (Reliability principle).
- **Lite mode**: Exit after Stage 1 mode check with message: "Simplification skipped in lite mode." Reset statusline before exiting.
- **Skill error or interrupt**: Reset the statusline before exiting:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
