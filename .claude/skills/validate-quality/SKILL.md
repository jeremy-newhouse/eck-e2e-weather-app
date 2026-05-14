---
name: wa:validate-quality
version: "0.7.4"
description: "Run quality gates: tests, lint, type checks with mode-calibrated depth."
disable-model-invocation: false
---

# Validate Quality

Run quality gates for: $ARGUMENTS

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject            | Active Form        | Statusline      |
| ----- | ------------------ | ------------------ | --------------- |
| 1     | Stage 1: Calibrate | Calibrating gates  | Calibrate (1/5) |
| 2     | Stage 2: Tests     | Running tests      | Tests (2/5)     |
| 3     | Stage 3: Lint      | Running linter     | Lint (3/5)      |
| 4     | Stage 4: Format    | Checking formatter | Format (4/5)    |
| 5     | Stage 5: Types     | Checking types     | Types (5/5)     |

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
/validate-quality
/validate-quality --rigor lite
/validate-quality --rigor standard
/validate-quality --rigor strict
```

---

## Stage 1: Calibrate

### Inputs

- `$ARGUMENTS` — optional `--rigor` flag
- `mode:read-dev-rigor` primitive — resolves the current development mode
- Project config files: `jest.config.*`, `vitest.config.*`, `pytest.ini`, `.eslintrc*`, `pyproject.toml`, `tsconfig.json`, `mypy.ini`, `pyrightconfig.json`
- `.claude/project-constants.md` — `npm test`, `npm run lint`, `<TYPECHECK_COMMAND>`

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Detect tooling from project config files:
   - Test runner: check for `jest`, `vitest`, `pytest`, `node --test`, or `npm test` in `project-constants.md`
   - Linter: check for `.eslintrc*`, `pyproject.toml` (ruff/flake8), or `npm run lint` in `project-constants.md`
   - Formatter: check for `.prettierrc*`, `pyproject.toml` (ruff format), or `<FORMAT_COMMAND>` in `project-constants.md`
   - Type checker: check for `tsconfig.json`, `mypy.ini`, `pyrightconfig.json`, `[tool.mypy]`/`[tool.pyright]` in `pyproject.toml`, or `<TYPECHECK_COMMAND>` in `project-constants.md`

3. Display mode banner:

   ```
   --- {Mode Name} Mode (Level {N}: {Label}) ---
   Gates: {tests only|tests+lint|tests+lint+types}
   Tip: Use --rigor lite|standard|strict to override
   ---------------------------------------------
   ```

4. Apply mode calibration to gate selection:
   - **Lite**: Run tests only (Stages 3, 4, and 5 are skipped)
   - **Standard**: Run tests + lint + format (Stage 5 is skipped)
   - **Strict**: Run tests + lint + format + type checks

### Outputs

- Resolved development mode (lite / standard / strict)
- Detected tooling for each gate (test runner, linter, formatter, type checker)
- Gate selection plan (which stages will run vs skip)

### Exit Criteria

- Development mode resolved and banner displayed
- All available gate tools detected
- Gate selection plan determined based on mode

---

## Stage 2: Tests

### Inputs

- `npm test` from `.claude/project-constants.md` under "Quality Gate Configuration"
- `review:test` primitive

### Activities

1. Look up `npm test` from `.claude/project-constants.md` under "Quality Gate Configuration".
2. Run the `review:test` primitive using the resolved test command.
3. Report:
   - Pass/fail count per suite
   - Coverage percentage if the runner outputs it
   - Full error output for any failing tests

### Outputs

- Test results: pass/fail count per suite
- Coverage percentage (if available)
- Full error output for failing tests

### Exit Criteria

- Test command executed and results captured
- Pass/fail counts and any errors reported

---

## Stage 3: Lint

**Lite mode**: Skip this stage entirely.

### Inputs

- `npm run lint` from `.claude/project-constants.md` under "Quality Gate Configuration"
- `review:lint` primitive
- Gate selection plan from Stage 1 (determines whether this stage runs)

### Activities

1. Look up `npm run lint` from `.claude/project-constants.md` under "Quality Gate Configuration".
2. Run the `review:lint` primitive using the resolved lint command.
3. Report:
   - Error count and warning count
   - File paths and line numbers for each finding
   - Full lint output on failure

### Outputs

- Lint results: error count and warning count
- File paths and line numbers for each finding
- Full lint output (on failure)

### Exit Criteria

- Lint command executed and results captured (or stage skipped in lite mode)
- Error and warning counts reported

---

## Stage 4: Format

**Lite mode**: Skip this stage entirely.

### Inputs

- `<FORMAT_COMMAND>` from `.claude/project-constants.md` under "Quality Gate Configuration"
- Gate selection plan from Stage 1 (determines whether this stage runs)

### Activities

1. Look up `<FORMAT_COMMAND>` from `.claude/project-constants.md` under "Quality Gate Configuration".
   - Backend: `<BACKEND_FORMAT_CMD>` (e.g., `ruff format --check .`)
   - Frontend: `<FRONTEND_FORMAT_CMD>` (e.g., `npx prettier --check .`)
2. If the format command is `N/A` or not configured, skip and note that formatting is not configured for this project.
3. Run the format check command in `--check` mode (verify only, do not modify files).
4. Report:
   - Pass/fail status
   - File paths for any unformatted files
   - Full output on failure

### Outputs

- Format check results: pass/fail status
- File paths for unformatted files (if any)
- Full format output (on failure)

### Exit Criteria

- Format check command executed and results captured (or stage skipped in lite mode)
- Pass/fail status reported

---

## Stage 5: Types

**Lite and Standard modes**: Skip this stage entirely.

### Inputs

- `<TYPECHECK_COMMAND>` from `.claude/project-constants.md` under "Quality Gate Configuration"
- `review:typecheck` primitive
- Gate selection plan from Stage 1 (determines whether this stage runs)

### Activities

1. Look up `<BACKEND_TYPECHECK_CMD>` and `<FRONTEND_TYPECHECK_CMD>` from `.claude/project-constants.md` under "Quality Gate Configuration".
2. If both are `N/A` or not configured, attempt auto-detection:
   - **mypy**: detected if `mypy.ini` exists, or `pyproject.toml` contains `[tool.mypy]` or `[mypy]`
   - **pyright**: detected if `pyrightconfig.json` exists, or `pyproject.toml` contains `[tool.pyright]`
   - **TypeScript**: detected if `tsconfig.json` exists
   - Auto-detected commands: `uv run mypy .`, `uv run pyright`, `npx tsc --noEmit` (fall back to `mypy .` / `pyright` / `tsc --noEmit` if `uv`/`npx` not available)
   - If both mypy config and pyright config are present, prefer the one with a dedicated config file (`mypy.ini` or `pyrightconfig.json`)
3. If no type checker is configured or detected, skip and note that type checking is not configured for this project.
4. Run the `review:typecheck` primitive using the resolved type-check command(s). Run backend and frontend checks independently if both are configured.
5. Report:
   - Total type error count
   - File paths, line numbers, and error messages for each finding

### Outputs

- Type check results: total error count
- File paths, line numbers, and error messages for each finding

### Exit Criteria

- Type check command executed and results captured (or stage skipped in lite/standard mode)
- All type errors reported with file locations

---

## Final: Quality Gate Decision

**MUST** apply `validation:quality-gate` to determine the overall pass/fail verdict across all gates that ran. Do NOT skip the verdict computation.

- **MUST** report a summary table of each gate with PASS/FAIL status.
- If any gate fails, **MUST** list all failures before reporting the final verdict. Do NOT silently swallow failures.
- Each gate is independent — **MUST** report all results even if one fails earlier.

### Stage Exit Verification

Before reporting the final verdict, **MUST** verify:

- [ ] All scheduled gates have been executed (or explicitly skipped by mode)
- [ ] Results are captured for every executed gate

If any scheduled gate was not executed and not explicitly skipped: report as FAIL for that gate.

---

## Error Handling

- If a gate command is not found or exits with an unexpected error (not a test failure), report the error and continue to the next gate.
- Do not abort the skill on a single gate failure; complete all scheduled gates first.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
