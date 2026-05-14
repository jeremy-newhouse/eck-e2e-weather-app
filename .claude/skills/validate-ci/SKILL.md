---
name: wa:validate-ci
version: "0.7.4"
description: "Diagnose CI pipeline failures with root cause classification and fix proposals."
disable-model-invocation: false
---

# Validate CI

Diagnose CI failure for: $ARGUMENTS

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject | Active Form | Statusline |
|-------|---------|-------------|------------|
| 1 | Stage 1: Collect | Collecting logs | Collect (1/3) |
| 2 | Stage 2: Diagnose | Diagnosing failure | Diagnose (2/3) |
| 3 | Stage 3: Propose | Proposing fix | Propose (3/3) |

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
/validate-ci
/validate-ci <run-id>
/validate-ci <branch-name>
```

---

## Stage 1: Collect

### Inputs
- `$ARGUMENTS` — optional run ID or branch name
- `.github/workflows/` directory, `.gitlab-ci.yml`, or CI system from `project-constants.md`
- CI logs from the failing run (retrieved via `gh` CLI or API)

### Activities

1. Identify the CI system in use:
   - GitHub Actions: check for `.github/workflows/` directory
   - GitLab CI: check for `.gitlab-ci.yml`
   - Other: use the CI system configured in project-constants.md

2. Retrieve CI logs for the failing run:
   - **GitHub Actions**: `gh run view <run-id> --log` or `gh run list --branch <branch> --limit 1` if no run ID was provided
   - **GitLab CI**: retrieve via GitLab API or MCP tool
   - If $ARGUMENTS contains a run ID or branch name, use it; otherwise use the current branch

3. Extract from the logs:
   - The failing step name (e.g., "Run tests", "Lint", "Build")
   - The full error output and stack trace from the failing step
   - Surrounding log context (10-20 lines before and after the error)
   - The workflow file path and the failing job definition

### Outputs
- Identified CI system type
- Failing step name, error output, stack trace, and surrounding log context
- Workflow file path and failing job definition

### Exit Criteria
- CI system identified
- Failing run logs retrieved and key error details extracted

---

## Stage 2: Diagnose

### Inputs
- Extracted log details from Stage 1 (failing step, error output, workflow file)
- Git commit history since last green CI run
- Changed files on the current branch

### Activities

1. Identify commits introduced since the last green CI run on this branch:
   ```bash
   git log --oneline <last-green-sha>..HEAD
   ```
   If the last green SHA is unknown, use the merge-base with the base branch.

2. Map changed files to the failing step:
   - `.py` files failing pytest -> likely Code Bug or Test Bug
   - `.ts`/`.js` files failing vitest/jest -> likely Code Bug or Test Bug
   - Workflow files (`.github/workflows/*.yml`) failing -> likely Config error
   - `package.json` or `requirements.txt` changes with install failure -> likely Dependency

3. Classify the root cause into one of six categories:

   | Classification | Description | Example |
   |----------------|-------------|---------|
   | Code Bug | Logic error in application code | TypeError, assertion failure |
   | Test Bug | Error in test code, not application | Wrong fixture, stale mock |
   | Config | CI/CD configuration issue | Missing env var, wrong path |
   | Dependency | Package version conflict or missing dep | Version mismatch, install failure |
   | Flaky | Intermittent, non-deterministic failure | Timing issue, external service call |
   | Infra | CI runner or environment issue | Out of memory, disk full, network timeout |

4. Record the classification, the evidence from the logs, and the confidence level:
   - **HIGH** (>90%): Error directly traces to a specific changed line
   - **MEDIUM** (60-90%): Strong circumstantial evidence from logs and changed files
   - **LOW** (<60%): Unable to pinpoint; multiple possible causes

### Outputs
- Root cause classification (one of six categories)
- Evidence summary linking logs to changed files
- Confidence level (HIGH / MEDIUM / LOW)

### Exit Criteria
- Root cause classified with supporting evidence
- Confidence level assigned

---

## Stage 3: Propose

### Inputs
- Root cause classification from Stage 2
- Evidence and confidence level from Stage 2
- Failing step details and affected file paths from Stage 1

### Activities

1. Generate the smallest safe fix based on the classification from Stage 2:

   - **Code Bug**: Show the exact file path, line number, and a before/after code diff.
   - **Test Bug**: Show the corrected test code with an explanation of why the test was wrong.
   - **Config**: Show the exact change to the CI workflow file or environment configuration.
   - **Dependency**: Show the version pin or update command (`npm install pkg@version`, `pip install pkg==version`).
   - **Flaky**: Suggest adding a retry policy to the failing step; note that root cause may be external and flag for monitoring.
   - **Infra**: Suggest re-running the pipeline; if the issue is recurring, provide runner configuration guidance.

2. Output the proposal in this format:

   ```
   ## CI Triage Report

   ### Summary
   - Branch: [branch name]
   - Failing Step: [step name]
   - Classification: [category]
   - Confidence: HIGH / MEDIUM / LOW

   ### Diagnosis
   [Root cause explanation with evidence from logs and changed files]

   ### Affected Files
   - path/to/file (line N) — [what is wrong]

   ### Proposed Fix
   [Code diff or configuration change]

   ### Validation
   - Run: [command to validate the fix]
   - Expected: [what success looks like]

   ### If Fix Does Not Work
   [Alternative investigation steps]
   ```

3. If confidence is LOW, include manual investigation steps and recommend that the user examine the raw logs before applying any fix.

### Outputs
- CI Triage Report displayed to the user (summary, diagnosis, affected files, proposed fix, validation steps)

### Exit Criteria
- Triage report displayed with classification, evidence, proposed fix, and validation command
- Low-confidence reports include manual investigation steps

---

## Error Handling

- If CI logs are inaccessible (no `gh` CLI, no API token, insufficient permissions), display clear instructions for the user to paste logs manually, then continue with Stage 2 using the pasted content.
- If the CI system cannot be detected, ask the user which system is in use before proceeding.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
