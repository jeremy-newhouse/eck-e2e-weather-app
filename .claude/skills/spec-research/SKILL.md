---
name: wa:spec-research
version: "0.7.4"
description: "Domain research, prior art, technical feasibility, and constraints analysis for spec-driven development."
disable-model-invocation: false
---

# Spec Research

Research domain context, prior art, and technical feasibility for: $ARGUMENTS

> **Spec phase sub-skill.** Produces research findings that inform scope definition and acceptance criteria.

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject           | Active Form          | Statusline     |
| ----- | ----------------- | -------------------- | -------------- |
| 1     | Stage 1: Context  | Loading context      | Context (1/4)  |
| 2     | Stage 2: Research | Researching domain   | Research (2/4) |
| 3     | Stage 3: Analyze  | Analyzing findings   | Analyze (3/4)  |
| 4     | Stage 4: Document | Writing research doc | Document (4/4) |

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
/spec-research <topic or feature description>
```

Examples:

```
/spec-research OAuth2 refresh token rotation strategy
/spec-research real-time notification delivery approaches
/spec-research multi-tenant data isolation patterns
```

**Output:** `docs/{feature}/RESEARCH.md`

---

## Stage 1: Context

### Inputs

- `$ARGUMENTS` — research topic or feature description
- `.claude/project-constants.md` — project key, tech stack, project type
- Existing research artifacts from `docs/{feature}/` or `docs/research/`
- Development mode via `mode:read-dev-rigor` primitive

### Activities

1. Read project constants:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```

   If missing, STOP: "Run `/start-project` first to define project constants."

2. Resolve development mode using the `mode:read-dev-rigor` primitive.

3. Identify research dimensions based on the feature description:
   - **Domain knowledge**: What does this feature domain look like? Industry standards, common patterns.
   - **Prior art**: How have similar features been built in comparable systems?
   - **Technical feasibility**: Can the current tech stack support this? What constraints exist?
   - **Codebase context**: What existing code, patterns, or infrastructure can be leveraged?

4. Use `codebase:explore` primitive to survey relevant existing code.

5. Check for existing research:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   ls "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/" 2>/dev/null || echo "No feature directory"
   ls "$CLAUDE_PROJECT_DIR/docs/research/" 2>/dev/null || echo "No research directory"
   ```

6. Apply mode calibration:
   - **Lite**: Domain knowledge + codebase context only. Skip prior art deep-dive.
   - **Standard**: All 4 dimensions. Balanced depth.
   - **Strict**: All 4 dimensions with exhaustive coverage, quantified feasibility assessment.

### Outputs

- Research dimensions identified with questions
- Existing context catalogued
- Mode-calibrated research scope

### Exit Criteria

- Project constants loaded
- Research dimensions and questions defined
- Mode calibration applied

---

## Stage 2: Research

### Inputs

- Research dimensions from Stage 1
- Project constants and codebase context
- Active heuristics from `.claude/context/heuristics/`

### Activities

1. **MUST** dispatch parallel research agents via `agent:parallel`, one per dimension. Do NOT run research dimensions sequentially when parallel dispatch is available:
   - Each agent receives: the research question, project constants, relevant codebase context
   - Each agent produces a structured findings block

2. For **Domain knowledge**:
   - Industry standards and best practices
   - Common patterns and anti-patterns
   - Regulatory or compliance considerations

3. For **Prior art**:
   - Similar implementations in open-source projects
   - Framework-specific approaches
   - Known pitfalls and lessons learned

4. For **Technical feasibility**:
   - Tech stack compatibility assessment
   - Performance implications
   - Dependency requirements
   - Integration complexity with existing systems

5. For **Codebase context**:
   - Existing patterns that can be extended
   - Code that would need modification
   - Technical debt in affected areas
   - Test infrastructure available

6. Consult the heuristic pipeline:
   - Load active heuristics from `.claude/context/heuristics/`
   - Flag any heuristics relevant to the research topic

### Outputs

- Structured findings per dimension
- Heuristic warnings (if any)

### Exit Criteria

- All research agents have returned findings
- Heuristic pipeline consulted

---

## Stage 3: Analyze

### Inputs

- Research findings from Stage 2
- Project tech stack and constraints

### Activities

1. Synthesize findings across all dimensions:
   - Identify consensus approaches
   - Flag contradictions or risks
   - Assess feasibility against project constraints

2. Produce a recommendation with rationale:
   - Recommended approach with trade-offs acknowledged
   - Key constraints and limitations identified
   - Risks that need mitigation during design

3. Identify implications for spec:
   - Suggested scope boundaries
   - Potential acceptance criteria themes
   - Technical constraints that affect requirements

### Outputs

- Synthesized analysis with recommendation
- Spec implications identified

### Exit Criteria

- Recommendation produced with rationale
- Spec implications documented

---

## Stage 4: Document

### Inputs

- Analysis and recommendation from Stage 3
- Research dimensions from Stage 1

### Activities

1. Create the research document:

   ```bash
   FEATURE_SLUG=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/"
   ```

2. Write `docs/{feature}/RESEARCH.md`:

   ```markdown
   # Spec Research: {Topic}

   **Date:** {date}
   **Feature:** {$ARGUMENTS}
   **Status:** Draft
   **Dimensions:** {list of dimensions investigated}

   ## Executive Summary

   {2-3 sentence summary of the recommended approach and key findings}

   ## Domain Knowledge

   {industry standards, common patterns, compliance considerations}

   ## Prior Art

   {similar implementations, framework-specific approaches, lessons learned}

   ## Technical Feasibility

   {tech stack compatibility, performance implications, integration complexity}

   ## Codebase Context

   {existing patterns, affected code, technical debt, test infrastructure}

   ## Risk Flags

   {risks identified with severity and recommended mitigations}

   ## Heuristic Warnings

   {any heuristic-informed warnings triggered during analysis}

   ## Recommendation

   {specific recommendation with rationale and trade-offs}

   ## Spec Implications

   {suggested scope boundaries, AC themes, technical constraints for requirements}
   ```

3. Verify the write:

   ```bash
   test -f "$CLAUDE_PROJECT_DIR/docs/${FEATURE_SLUG}/RESEARCH.md" && echo "[x] RESEARCH.md written" || echo "[!] Write failed"
   ```

4. Print completion summary:

   ```bash
   source $ECK_HOME/colors.sh
   echo ""
   printf '%b\n' "${ORANGE}${BOLD}Spec Research Complete${RESET}"
   echo ""
   printf '%b\n' "Feature: {$ARGUMENTS}"
   printf '%b\n' "Dimensions: {N} investigated"
   printf '%b\n' "Risks: {N} identified"
   printf '%b\n' "Output: docs/{feature}/RESEARCH.md"
   echo ""
   ```

5. Print next steps:
   ```
   Next steps:
   - Define scope: /spec-scope {$ARGUMENTS}
   - Full spec: /eck:spec {$ARGUMENTS}
   ```

### Outputs

- `docs/{feature}/RESEARCH.md` written
- Completion summary displayed

### Exit Criteria

- RESEARCH.md written and verified on disk
- Completion summary and next steps printed

---

## Error Handling

| Condition                          | Behavior                                                        |
| ---------------------------------- | --------------------------------------------------------------- |
| No `project-constants.md` found    | STOP: "Run `/start-project` first to define project constants." |
| Research agent returns no findings | Log warning, continue with available findings, note gaps        |
| Heuristic pipeline unavailable     | Skip heuristic consultation, note absence                       |
| Docs directory write fails         | Output content inline; instruct user to save manually           |

Follow the error display, gate failure, and statusline reset patterns defined in the `output:error-handler` primitive.

---

## Related Documents

- `output:visual-framework` — terminal output conventions
- `output:error-handler` — error display and statusline reset patterns
- `mode:read-dev-rigor` — development mode resolution
- `scaffold/global/skills/spec/SKILL.md` — Spec orchestrator (parent)
- `scaffold/project/skills/spec-scope/SKILL.md` — scope definition (run after)
- `scaffold/project/skills/spec-criteria/SKILL.md` — acceptance criteria (run after)
