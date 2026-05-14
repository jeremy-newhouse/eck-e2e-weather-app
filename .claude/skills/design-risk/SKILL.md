---
name: wa:design-risk
version: "0.7.4"
description: "Risk assessment gate with 5-category evaluation and GO/NO-GO decision."
disable-model-invocation: false
---

# Design Risk

Evaluate risks for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form      | Statusline      |
| ----- | ------------------ | ---------------- | --------------- |
| 1     | Stage 1: Calibrate | Calibrating risk | Calibrate (1/2) |
| 2     | Stage 2: Assess    | Assessing risk   | Assess (2/2)    |

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
/design-risk <feature or system description> [--rigor lite|standard|strict]
```

Examples:

```
/design-risk OAuth2 refresh token implementation
/design-risk database migration for user table --rigor strict
```

---

## Stage 1: Calibrate

Resolve mode and load context before assessing.

### Inputs

- `$ARGUMENTS` — feature or system description
- `--rigor` flag (if provided)
- `mode:read-dev-rigor` primitive
- Prior design-\* outputs (architecture, research, specs — if available)
- Project constants: `3`, `Weather App`

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Display mode banner:

   ```
   ─── {Mode Name} Mode (Level {N}: {Label}) ───
   Risk categories: {2 core|all 5|all 5} | Gate: {optional|optional|mandatory}
   Tip: Use --rigor lite|standard|strict to override
   ──────────────────────────────────────────────
   ```

3. Apply mode calibration:
   - **Lite**: Assess Technical and Security/Compliance only (2 categories). Gate is optional.
   - **Standard**: Assess all 5 categories. Gate is optional — user decides whether to invoke.
   - **Strict**: Assess all 5 categories. Gate is mandatory before implementation proceeds.

4. Load context from prior design-\* outputs:
   - Architecture document (if available)
   - Research findings (if available)
   - Specs (if available)
   - Project constants: `3`, `Weather App`

### Outputs

- Resolved development mode (lite, standard, or strict)
- Mode banner displayed to user
- Loaded context from prior design artifacts

### Exit Criteria

- Development mode is resolved and displayed
- Applicable risk categories are determined (2 for lite, 5 for standard/strict)
- All available prior design context is loaded

---

## Stage 2: Assess

Produce a GO/NO-GO decision based on risk category evaluation.

### Inputs

- Resolved development mode from Stage 1
- Applicable risk categories (2 for lite, 5 for standard/strict)
- Loaded context from prior design artifacts
- `$ARGUMENTS` — feature or system description
- Project constants: `CONFLUENCE_ENABLED`, `<CONFLUENCE_SPACE_KEY>`

### Activities

1. Evaluate risks across applicable categories per the rules below.

#### Purpose

Stop-the-line control that prevents wasted implementation work by identifying blocking risks before coding begins.

#### Risk Categories

**Mode behavior:**

- **Lite**: Assess categories 1 and 3 only (Technical + Security/Compliance)
- **Standard / Strict**: Assess all 5 categories

Assess each applicable category on a GREEN/YELLOW/RED scale:

##### 1. Technical Risk

- Complexity of implementation relative to team experience
- Unknown technologies or unproven patterns
- Performance implications at expected load
- Integration complexity with existing systems

##### 2. Operational Risk

- Deployment complexity and required coordination
- Monitoring and observability gaps
- Difficulty of rollback if the release fails
- Data migration requirements and reversibility

##### 3. Security / Compliance Risk

- Authentication and authorization changes
- PII or sensitive data handling
- Third-party API exposure and trust boundaries
- OWASP Top 10 considerations relevant to this feature

##### 4. Product Risk

- User experience impact and potential for regression
- Breaking changes to existing features
- Scope creep potential given current requirements clarity
- Unclear or conflicting requirements between stakeholders

##### 5. Dependency Risk

- External service dependencies and their reliability
- Team or resource availability for the timeline
- Blocking issues in other systems or teams
- Third-party library stability and maintenance status

#### Severity Levels

| Level  | Meaning                               | Action                              |
| ------ | ------------------------------------- | ----------------------------------- |
| GREEN  | Low risk, well understood             | Proceed                             |
| YELLOW | Moderate risk, mitigations identified | Proceed with documented mitigations |
| RED    | High risk, unresolved blockers        | STOP — resolve before proceeding    |

2. Apply decision rules to determine GO/NO-GO verdict.

#### Decision Rules

- **Any RED** = NO-GO (must resolve the blocker before proceeding)
- **3 or more YELLOW** = NO-GO (cumulative risk is too high)
- **All GREEN** = GO
- **1-2 YELLOW with documented mitigations** = GO with conditions

3. Format the assessment output.

#### Output Format

```markdown
## Risk Assessment: {Feature or System}

### Summary

- **Overall Verdict**: GO / NO-GO
- **Mode**: {Lite|Standard|Strict}
- **Assessed**: {date}

### Category Scores

| Category            | Score            | Key Concern |
| ------------------- | ---------------- | ----------- |
| Technical           | GREEN/YELLOW/RED | {concern}   |
| Operational         | GREEN/YELLOW/RED | {concern}   |
| Security/Compliance | GREEN/YELLOW/RED | {concern}   |
| Product             | GREEN/YELLOW/RED | {concern}   |
| Dependency          | GREEN/YELLOW/RED | {concern}   |

### Mitigations Required (YELLOW items)

1. {mitigation with owner and timeline}

### Blockers (RED items)

1. {blocker with resolution requirement}

### Recommendation

GO / NO-GO with rationale
```

4. Store the assessment to local docs (always):

#### Storage

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/docs/risk/"
```

Write to `docs/risk/risk-{slug}.md` with frontmatter: `title`, `status: accepted`, `type: risk`, `date`, `verdict: GO|NO-GO`
Use `docs/local:doc-create` if the file does not exist, or `docs/local:doc-update` if it does.

After local write succeeds, check `CONFLUENCE_ENABLED` from project constants:

- If `CONFLUENCE_ENABLED=true`: call `confluence-publish` for the written file, with labels `accepted`, `riskassessment` in `<CONFLUENCE_SPACE_KEY>` space
  - On publish failure: display a warning and preserve the local artifact — do NOT block or stop
- If `CONFLUENCE_ENABLED` is not set or false: skip Confluence publish

### Outputs

- Risk assessment document with category scores (GREEN/YELLOW/RED) written to `docs/risk/risk-{slug}.md` (always)
- Confluence page synced (if `CONFLUENCE_ENABLED=true`)
- GO/NO-GO verdict with rationale
- Mitigations list for YELLOW items (if any)
- Blockers list for RED items (if any)

### Exit Criteria

- All applicable risk categories are scored
- Decision rules are applied and verdict is determined
- Assessment document is written to `docs/risk/`
- Confluence publish attempted (if enabled) — failures warned but do not block
- If NO-GO, blocking risks and required mitigations are clearly listed

---

## Error Handling

| Condition                            | Action                                                                              |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| No `project-constants.md` found      | STOP: "Run `/start-project` first to define project constants."                     |
| No prior design-\* context available | Proceed with assessment based on $ARGUMENTS alone; note limited context in report   |
| Result is NO-GO                      | List all blocking risks and required mitigations clearly; do not suggest proceeding |
| Doc platform write fails             | Output assessment inline and instruct user to save manually                         |
