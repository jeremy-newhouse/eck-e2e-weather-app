---
name: wa:validate-docs
version: "0.7.4"
description: "Feature documentation quality gate: AC-ID traceability, doc freshness, terminology compliance, and artifact consistency."
disable-model-invocation: false
---

# Validate Docs

Validate documentation quality for: $ARGUMENTS

> **Validate phase sub-skill.** Checks feature-scoped documentation accuracy and completeness. Dispatches `technical-writer` agent for content review and uses `traceability:coverage-report` for AC-ID coverage.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject         | Active Form           | Statusline   |
| ----- | --------------- | --------------------- | ------------ |
| 1     | Stage 1: Scope  | Scoping doc review    | Scope (1/4)  |
| 2     | Stage 2: Trace  | Checking traceability | Trace (2/4)  |
| 3     | Stage 3: Review | Reviewing docs        | Review (3/4) |
| 4     | Stage 4: Report | Writing report        | Report (4/4) |

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
/validate-docs <feature-description>
/validate-docs                          # Uses active feature from lifecycle
```

**Output:** Per-check results with PASS/WARN/FAIL verdicts and a composite documentation quality score.

---

## Stage 1: Scope

```bash
bash $ECK_HOME/update-stage.sh "Scope (1/4)"
```

### Inputs

- `$ARGUMENTS` — feature description or active feature from lifecycle
- `.claude/project-constants.md` — project key, doc platform
- Development rigor via `mode:read-dev-rigor` primitive

### Activities

1. Resolve feature slug from active lifecycle or `$ARGUMENTS`.
2. Inventory feature documentation artifacts:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   ls docs/${FEATURE_SLUG}/ 2>/dev/null
   ```

3. Inventory changed files since the feature branch diverged (for freshness check):

   ```bash
   git diff --name-only $(git merge-base HEAD dev)..HEAD 2>/dev/null
   ```

4. Load the terminology glossary:

   ```bash
   cat .claude/context/standards/terminology-glossary.md 2>/dev/null || echo "No glossary"
   ```

5. Determine check depth by rigor:

   | Check                  | Lite     | Standard | Strict   |
   | ---------------------- | -------- | -------- | -------- |
   | AC-ID traceability     | ADVISORY | BLOCKING | BLOCKING |
   | Doc freshness          | SKIP     | ADVISORY | BLOCKING |
   | Terminology compliance | SKIP     | ADVISORY | BLOCKING |
   | Artifact consistency   | ADVISORY | BLOCKING | BLOCKING |

### Outputs

- Feature artifact inventory
- Changed file list
- Check depth configuration

### Exit Criteria

- Feature slug resolved
- At least one doc artifact found (or absence noted)

---

## Stage 2: Trace

```bash
bash $ECK_HOME/update-stage.sh "Trace (2/4)"
```

### Inputs

- Feature slug from Stage 1
- `docs/{feature}/FRD.md` — AC-IDs
- `docs/{feature}/TASKS.md` — task-to-AC mapping
- Git commit history for the feature

### Activities

1. **AC-ID traceability** — invoke `traceability:coverage-report` primitive:

   ```
   Parameters:
     feature_slug: {FEATURE_SLUG}
     docs_path: docs/{feature}/
   ```

   Evaluate the coverage matrix:
   - PASS: All active AC-IDs are Specified + Planned + Implemented
   - WARN: Coverage score > 80% but gaps exist
   - FAIL: Coverage score < 80% or any AC-ID has zero downstream references

2. **Commit-AC threading** — scan commit messages for AC-ID references:

   ```bash
   git log --oneline $(git merge-base HEAD dev)..HEAD | grep -i "AC-[0-9]"
   ```

   Compare referenced AC-IDs in commits against FRD.md AC-IDs. Flag any AC-IDs with zero commit references.

3. Display traceability results:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}AC-ID Traceability${RESET}"
   echo ""
   printf '%b\n' "Coverage: {score}% ({covered}/{total} AC-IDs)"
   printf '%b\n' "Commit refs: {N}/{total} AC-IDs referenced in commits"
   # Per-gap:
   printf '%b\n' "${YELLOW}[>]${RESET} AC-{N}: not referenced in any commit"
   ```

### Outputs

- Coverage matrix from `traceability:coverage-report`
- Commit-AC threading gaps
- Traceability verdict (PASS/WARN/FAIL)

### Exit Criteria

- Coverage report generated
- Commit threading analyzed

---

## Stage 3: Review

```bash
bash $ECK_HOME/update-stage.sh "Review (3/4)"
```

### Inputs

- Changed file list from Stage 1
- Feature doc artifacts
- Terminology glossary

### Activities

1. **Doc freshness** — dispatch `technical-writer` agent to check:
   - For each changed code file, does a corresponding doc mention exist?
   - Are README sections that reference changed modules still accurate?
   - Were any new public APIs added without doc coverage?

   Agent receives: changed file list, feature doc directory contents, project constants.
   Agent returns: list of stale doc references with file:line locations.

   ```bash
   source $ECK_HOME/colors.sh
   # Per finding:
   printf '%b\n' "${YELLOW}[>]${RESET} {doc_file}:{line} — references {code_file} which was modified"
   # Or if clean:
   printf '%b\n' "${GREEN}[x]${RESET} Doc freshness: all references current"
   ```

2. **Terminology compliance** — grep feature docs for deprecated terms from the glossary:

   Scan all `.md` files in `docs/{feature}/` for each deprecated term in `terminology-glossary.md`:

   ```bash
   # For each deprecated term in the glossary Naming Renames table:
   grep -rn "{deprecated_term}" docs/${FEATURE_SLUG}/ --include="*.md"
   ```

   Exclude:
   - Lines inside changelog/history sections
   - Lines documenting the rename itself (e.g., "renamed from X to Y")
   - Lines in code fences showing backward-compat mappings

   ```bash
   source $ECK_HOME/colors.sh
   # Per finding:
   printf '%b\n' "${YELLOW}[>]${RESET} {file}:{line} — uses '${deprecated}', canonical: '${canonical}'"
   # Or if clean:
   printf '%b\n' "${GREEN}[x]${RESET} Terminology: no deprecated terms found"
   ```

3. **Artifact consistency** — dispatch `technical-writer` agent to verify:
   - FRD.md version/revision matches what was implemented
   - TASKS.md task statuses are consistent (no "Open" tasks if all code is committed)
   - DESIGN-REVIEW.md verdict is present if design phase was completed
   - Cross-references between artifacts resolve (e.g., FRD.md references in TASKS.md point to real AC-IDs)

   Agent returns: list of inconsistencies with severity.

   ```bash
   source $ECK_HOME/colors.sh
   # Per finding:
   printf '%b\n' "${RED}[!]${RESET} {artifact}: {inconsistency description}"
   # Or if clean:
   printf '%b\n' "${GREEN}[x]${RESET} Artifact consistency: all cross-references valid"
   ```

### Outputs

- Doc freshness findings
- Terminology violations
- Artifact consistency findings

### Exit Criteria

- All three review checks completed
- Findings collected with severity

---

## Stage 4: Report

```bash
bash $ECK_HOME/update-stage.sh "Report (4/4)"
```

### Inputs

- All findings from Stages 2-3
- Check depth from Stage 1

### Activities

1. Apply check depth (BLOCKING/ADVISORY/SKIP) to determine per-check verdicts:

   | Result | Condition                       |
   | ------ | ------------------------------- |
   | PASS   | No findings at current severity |
   | WARN   | ADVISORY-level findings only    |
   | FAIL   | BLOCKING-level findings         |

2. Compute composite score:
   - Each check: PASS=1.0, WARN=0.5, FAIL=0.0
   - Composite: average of enabled checks (skip checks excluded from denominator)

3. Display report:

   ```bash
   source $ECK_HOME/colors.sh

   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Documentation Quality${RESET}"
   echo ""
   printf '%b\n' "${GREEN}[x]${RESET} AC-ID traceability    PASS  (coverage: 100%)"
   printf '%b\n' "${YELLOW}[>]${RESET} Doc freshness         WARN  (2 stale references)"
   printf '%b\n' "${GREEN}[x]${RESET} Terminology            PASS  (no deprecated terms)"
   printf '%b\n' "${RED}[!]${RESET} Artifact consistency   FAIL  (3 cross-ref errors)"
   echo ""
   printf '%b\n' "Score: {composite}%"
   printf '%b\n' "Verdict: {PASS | WARN | FAIL}"
   echo ""
   ```

4. Return verdict and findings to the validate orchestrator.

### Outputs

- Per-check verdicts with findings
- Composite documentation quality score
- Overall verdict (PASS/WARN/FAIL)

### Exit Criteria

- All enabled checks have a verdict
- Composite score computed
- Report displayed

---

## Agent Dispatch

This skill dispatches these agents:

| Agent              | Purpose              | Receives                                        | Returns                             |
| ------------------ | -------------------- | ----------------------------------------------- | ----------------------------------- |
| `technical-writer` | Doc freshness review | Changed files, doc artifacts, project constants | Stale reference list with file:line |
| `technical-writer` | Artifact consistency | Feature doc directory, FRD.md, TASKS.md         | Inconsistency list with severity    |

Both dispatches use the same `technical-writer` agent but with different task prompts. Dispatches may run in parallel via `agent:parallel` primitive.

## Primitives Used

| Primitive                      | Purpose                                       |
| ------------------------------ | --------------------------------------------- |
| `traceability:coverage-report` | AC-ID coverage matrix across lifecycle phases |
| `mode:read-dev-rigor`          | Rigor level for check depth                   |
| `agent:parallel`               | Parallel agent dispatch for review checks     |

---

## Error Handling

| Scenario                       | Behavior                                                 |
| ------------------------------ | -------------------------------------------------------- |
| No FRD.md found                | Skip AC-ID traceability, note as gap                     |
| No git history (fresh repo)    | Skip doc freshness, note as gap                          |
| No glossary file               | Skip terminology check, note as gap                      |
| Agent dispatch fails           | Record check as FAIL, continue to next                   |
| All checks skipped (lite mode) | Return PASS with note "all checks skipped at lite rigor" |

Follow the `output:error-handler` primitive for error display conventions.

At completion (success or error), reset the statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Related Documents

- `scaffold/project/context/standards/terminology-glossary.md` — canonical term reference
- `scaffold/project/primitives/core/traceability/coverage-report.md` — AC-ID coverage primitive
- `scaffold/project/agents/technical-writer.md` — agent for doc freshness and consistency review
- `scaffold/global/skills/validate/SKILL.md` — validate orchestrator (parent)
- `.claude/skills/audit-doc-drift/SKILL.md` — project-wide drift detection (complementary)
