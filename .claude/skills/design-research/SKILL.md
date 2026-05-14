---
name: wa:design-research
version: "0.7.4"
description: "Online and knowledge-base research with heuristic consultation and parallel agent dispatch."
disable-model-invocation: false
---

# Design Research

Research context, ecosystem, and feasibility for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject          | Active Form        | Statusline    |
| ----- | ---------------- | ------------------ | ------------- |
| 1     | Stage 1: Scope   | Scoping research   | Scope (1/4)   |
| 2     | Stage 2: Explore | Exploring codebase | Explore (2/4) |
| 3     | Stage 3: Analyze | Analyzing findings | Analyze (3/4) |
| 4     | Stage 4: Report  | Writing report     | Report (4/4)  |

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
/design-research <topic or feature description>
```

Examples:

```
/design-research OAuth2 refresh token rotation strategy
/design-research competing approaches to real-time notification delivery
```

---

## Stage 1: Scope

### Inputs

- $ARGUMENTS for core research subject
- Project constants from `.claude/project-constants.md`
- Existing research artifacts from `docs/research/`

### Activities

1. Extract the core research subject from $ARGUMENTS
2. Identify which dimensions apply:
   - **Ecosystem**: third-party libraries, frameworks, and tooling options
   - **Feasibility**: technical constraints, compatibility, and effort estimate
   - **Implementation**: patterns, prior art, and reference code
   - **Comparison**: alternative approaches with trade-offs
3. Read project constants:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/project-constants.md"
   ```
4. Check for existing RESEARCH.md or prior research artifacts:
   ```bash
   ls "$CLAUDE_PROJECT_DIR/docs/research/" 2>/dev/null || echo "No research directory found"
   ```
5. Produce a scoping summary listing the dimensions to investigate and the research questions for each

### Outputs

- Research dimensions identified
- Research questions per dimension
- Scoping summary

### Exit Criteria

- At least one research dimension is identified
- Research questions are defined for each dimension

---

## Stage 2: Explore

### Inputs

- Research dimensions and questions from Stage 1
- Project constants and codebase context
- Active heuristics from `.claude/context/heuristics/`

### Activities

1. Use `codebase:explore`, `codebase:search`, and `codebase:read` primitives to survey relevant existing code
2. **MUST** dispatch parallel research agents via `agent:parallel`, one per dimension identified in Stage 1. Do NOT perform research inline — delegate to agents:
   - Each agent receives: the research question, project constants, and relevant codebase context
   - Each agent produces a structured findings block (question, evidence, sources, risks)
3. Consult the heuristic pipeline for domain-specific pitfalls:
   - Load active heuristics from `.claude/context/heuristics/`
   - Flag any heuristics relevant to the research subject
4. **MUST** collect all agent outputs before proceeding to Stage 3. Do NOT proceed with partial outputs unless an agent dispatch failed (see Error Handling).

### Outputs

- Structured findings block per dimension (question, evidence, sources, risks)
- Heuristic warnings (if any)

### Exit Criteria

- All dispatched agents have returned findings
- Heuristic pipeline has been consulted

---

## Stage 3: Analyze

### Inputs

- Agent findings from Stage 2 (all dimensions)
- Heuristic warnings from Stage 2
- Project tech stack and project type level from project constants

### Activities

1. Merge agent findings across all dimensions
2. Identify:
   - Common patterns and consensus approaches
   - Contradictions or conflicting recommendations between agents
   - Risks and unknowns that require further investigation
   - Prior art within the codebase that can be reused or extended
3. Cross-reference findings with active heuristics — flag any heuristic-informed warnings
4. Rank approaches by feasibility and alignment with project tech stack and project type level
5. Produce a ranked shortlist of recommended approaches with rationale

### Outputs

- Ranked shortlist of recommended approaches
- Identified risks, contradictions, and unknowns
- Heuristic-informed warnings

### Exit Criteria

- Approaches are ranked with clear rationale
- All contradictions between agents are identified

---

## Stage 4: Report

### Inputs

- Ranked approaches and analysis from Stage 3
- Research dimensions from Stage 1
- `CONFLUENCE_ENABLED` from project constants

### Activities

1. Write to local docs (always). Create or update `docs/research/RESEARCH-{slug}.md` where `{slug}` is derived from $ARGUMENTS:

   ```bash
   mkdir -p "$CLAUDE_PROJECT_DIR/docs/research/"
   ```

2. Document structure:

   ```markdown
   # Research: {Topic}

   **Date:** {date}
   **Requested by:** design-research
   **Dimensions:** {list of dimensions investigated}

   ## Executive Summary

   {2-3 sentence summary of the recommended approach and key finding}

   ## Findings by Dimension

   ### Ecosystem

   {findings}

   ### Feasibility

   {findings}

   ### Implementation

   {findings}

   ### Comparison

   {findings}

   ## Risk Flags

   {Risks identified, severity, and recommended mitigations}

   ## Heuristic Warnings

   {Any heuristic-informed warnings triggered during analysis}

   ## Recommended Approach

   {Specific recommendation with rationale and trade-offs acknowledged}
   ```

   Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

3. After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:
   - If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `research` in `<CONFLUENCE_SPACE_KEY>` space
     - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
   - If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

### Outputs

- RESEARCH-{slug}.md written to `docs/research/` (always)
- Confluence page synced (if `CONFLUENCE_ENABLED=true`)

### Exit Criteria

- Research document is written to `docs/research/`
- Document contains all investigated dimensions and a clear recommendation
- Confluence publish attempted (if enabled) — failures warned but do not block

---

## Error Handling

| Condition                          | Action                                                               |
| ---------------------------------- | -------------------------------------------------------------------- |
| No `project-constants.md` found    | STOP: "Run `/start-project` first to define project constants."      |
| Agent dispatch returns no findings | Log warning, continue with available findings, note gaps in report   |
| Heuristic pipeline unavailable     | Skip heuristic consultation, note absence in report                  |
| Docs directory write fails         | Output RESEARCH.md content inline and instruct user to save manually |
