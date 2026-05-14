---
name: wa:validate-code
version: "0.7.4"
description: "Language-aware code review with severity-filtered findings."
disable-model-invocation: false
---

# Validate Code

Code review for: $ARGUMENTS

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject         | Active Form    | Statusline   |
| ----- | --------------- | -------------- | ------------ |
| 1     | Stage 1: Scope  | Scoping review | Scope (1/3)  |
| 2     | Stage 2: Review | Reviewing code | Review (2/3) |
| 3     | Stage 3: Report | Writing report | Report (3/3) |

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
/validate-code
/validate-code path/to/file.ts
/validate-code --rigor lite
/validate-code --rigor standard
/validate-code --rigor strict
```

---

## Stage 1: Scope

### Inputs

- `$ARGUMENTS` — optional file path or `--rigor` flag
- `mode:read-dev-rigor` primitive — resolves the current development mode
- `.claude/project-constants.md` — reads `CODE_REVIEW_PLUGIN` constant
- Greptile MCP configuration
- `git:diff` — changed files on the current branch vs base branch

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Determine review mechanism (priority order):
   - **Greptile**: Check if Greptile MCP is configured → use `review:greptile-gate` on open PR
   - **code-review plugin**: Read `CODE_REVIEW_PLUGIN` from `.claude/project-constants.md` → if `installed`, use `code-review:code-review` plugin on open PR
   - **ECK agents (fallback)**: Neither above available → dispatch `backend-reviewer` / `frontend-reviewer` agents on changed files

3. Display mode banner:

   ```
   --- {Mode Name} Mode (Level {N}: {Label}) ---
   Severity: {CRITICAL only|CRITICAL+WARNING|all}
   Review: {greptile|code-review-plugin|eck-agents}
   Tip: Use --rigor lite|standard|strict to override
   ---------------------------------------------
   ```

4. Identify changed files (needed for ECK agent fallback and for simplifier scope):
   - If a specific file or path was passed in $ARGUMENTS, use that.
   - Otherwise, identify changed files in the current branch via `git:diff` (comparing HEAD to the base branch).

5. If mechanism is ECK agents, classify files by language:
   - Backend: `.py`, `.go`, `.java`, `.rb`, `.rs`, server-side `.ts`/`.js`
   - Frontend: `.tsx`, `.jsx`, client-side `.ts`/`.js`, `.vue`, `.svelte`
   - Determine which reviewer agents to dispatch: backend-reviewer, frontend-reviewer, or both

### Outputs

- Resolved development mode (lite / standard / strict)
- Review mechanism determined (greptile / code-review-plugin / eck-agents)
- List of changed files (classified by language if ECK agents selected)

### Exit Criteria

- Development mode resolved and banner displayed
- Review mechanism determined
- File list identified

---

## Stage 2: Review

### Inputs

- Review mechanism from Stage 1 (greptile / code-review-plugin / eck-agents)
- Changed files and open PR from Stage 1
- `review:greptile-gate` primitive
- `code-review:code-review` plugin
- `review:simplifier` primitive
- `agent:dispatch` — `backend-reviewer` and/or `frontend-reviewer` agents (fallback only)

### Activities

1. Execute review using the mechanism from Stage 1:

   **If Greptile configured:**
   Execute the `review:greptile-gate` primitive on the open PR. See [primitives/review/greptile-gate.md](../../primitives/review/greptile-gate.md) for full procedure.

   **Else if CODE_REVIEW_PLUGIN=installed:**
   Invoke the `code-review:code-review` plugin on the open PR.

   **Else (ECK agents fallback):**
   Dispatch language-aware agents via `agent:dispatch`:
   - `backend-reviewer`: reviews server code for correctness, security, performance, and architecture
   - `frontend-reviewer`: reviews client code for correctness, accessibility, and UX concerns
   - Agents run in parallel when both are dispatched.

2. Each reviewer produces findings with one of three severity levels:
   - **CRITICAL**: Must fix — correctness bugs, security holes, data loss risk
   - **WARNING**: Should fix — performance problems, error-handling gaps, maintainability concerns
   - **INFO**: Optional — style suggestions, minor improvements

3. **MUST** apply `review:simplifier` for over-engineering and YAGNI (You Aren't Gonna Need It) style suggestions. This produces INFO-level findings.

### Outputs

- Raw findings list from review mechanism, each with severity level (CRITICAL / WARNING / INFO)
- Simplifier findings (INFO-level)

### Exit Criteria

- Review mechanism completed (or failed with logged errors)
- Simplifier analysis complete

---

## Stage 3: Report

### Inputs

- Raw findings from Stage 2 (all reviewer agents and simplifier)
- Resolved development mode from Stage 1 (determines severity filter)

### Activities

1. Aggregate all findings from all reviewer agents.

2. Filter findings by mode:
   - **Lite**: CRITICAL findings only
   - **Standard**: CRITICAL and WARNING findings
   - **Strict**: All findings (CRITICAL, WARNING, INFO)

3. Display findings grouped by severity (CRITICAL first, then WARNING, then INFO). For each finding include:
   - File path and line number
   - Severity label
   - Description of the issue
   - Suggested fix (required for CRITICAL and WARNING)

4. Display a summary count at the end:
   ```
   Review complete: {N} CRITICAL, {N} WARNING, {N} INFO
   ```

### Outputs

- Filtered and grouped findings displayed to the user
- Summary count of findings by severity

### Exit Criteria

- All mode-appropriate findings displayed with file paths, severity, descriptions, and suggested fixes
- Summary count displayed

---

## Error Handling

- Code review is advisory and never blocks other workflows.
- If a reviewer agent fails, record the error and continue with any remaining agents.
- If no changed files are found and no $ARGUMENTS path is provided, report "No files to review" and exit cleanly.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
