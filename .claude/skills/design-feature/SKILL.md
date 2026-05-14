---
name: wa:design-feature
version: "0.7.4"
description: "Design-only skill: interview, research, design, docs. Terminates at Stage 7. Enforced by hooks."
disable-model-invocation: false
---

# Design Feature

> Design-only skill. Terminates at Stage 7. Implementation happens in a separate session via `/eck:develop`.

> **Plan mode required.** If not already in plan mode, use `EnterPlanMode` before proceeding. This skill gathers requirements and produces a design — no implementation.

Plan the implementation of: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Usage

```bash
/wa:design-feature "user authentication with OAuth2"    # Design a feature
/wa:design-feature "search API" --rigor lite            # Lightweight design
/wa:design-feature "payment processing" --rigor strict # Full design suite
```

---

## Task Registration

| Stage | Subject            | Active Form          | Statusline      |
| ----- | ------------------ | -------------------- | --------------- |
| 1     | Stage 1: Kickoff   | Starting kickoff     | Kickoff (1/7)   |
| 2     | Stage 2: Marker    | Setting marker       | Marker (2/7)    |
| 3     | Stage 3: Interview | Conducting interview | Interview (3/7) |
| 4     | Stage 4: Research  | Researching context  | Research (4/7)  |
| 5     | Stage 5: Design    | Designing solution   | Design (5/7)    |
| 6     | Stage 6: Document  | Writing documents    | Document (6/7)  |
| 7     | Stage 7: Report    | Generating report    | Report (7/7)    |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Stage 1: Project Kickoff Check

### Inputs

- `.claude/.start-project-completed` marker file (from `/start-project`)
- `$ARGUMENTS` — feature description passed to this skill
- `--rigor` flag (if provided) for workflow calibration

### Activities

1. Check for `.claude/.start-project-completed`:
   ```bash
   cat "$CLAUDE_PROJECT_DIR/.claude/.start-project-completed" 2>/dev/null
   ```
2. If file not found → STOP:
   "Project kickoff has not been completed. Run `/start-project` first to define
   your project's tech stack, architecture, and feature roadmap."
3. If found → load project type level for workflow calibration, then continue to Stage 2.

#### Mode Calibration

Resolve development mode using the `mode:read-dev-rigor` primitive.

Display mode banner (after session marker is written in Stage 2):

```
─── {Mode Name} Mode (Level {N}: {Label}) ───
Docs: {lightweight|standard|full} | Risk gate: {skip|optional|mandatory}
Tip: Use --rigor lite|standard|strict to override
──────────────────────────────────────────────
```

Mode calibration for design-feature phases:

- **Lite**: Docs = lightweight (project brief only), risk gate = skip, specs tier defaults to simple
- **Standard**: Docs = standard (BRD + PRD + features), risk gate = optional, specs tier defaults to standard
- **Strict**: Docs = full (BRD + PRD + ADRs + specs + features + risk assessment), risk gate = mandatory, specs tier defaults to complex

### Outputs

- Confirmed project kickoff status
- Resolved development mode (lite/standard/strict)
- Mode-specific documentation scope and risk gate settings

### Exit Criteria

- `.claude/.start-project-completed` exists and is readable
- Development mode resolved and calibration settings determined
- Ready to proceed to Stage 2

---

## Stage 2: Session Marker (EXTREME PRIORITY)

### Inputs

- `$ARGUMENTS` — feature description for the marker
- Stage 1 completion (project kickoff confirmed)

### Activities

**THIS MUST BE YOUR ABSOLUTE FIRST ACTION. NO OTHER TOOL CALLS BEFORE THIS. NOT EVEN READING FILES.**

The planning guard hooks (`planning-write-guard.sh`, `planning-bash-guard.sh`, `planning-guard.sh`) will BLOCK all implementation-related tool calls when the `.planning-session` marker exists. If you do NOT write this marker as your very first action, the hooks cannot protect the session and you risk bypassing planning phases.

1. Write the JSON marker file as your **FIRST TOOL CALL**:

   ```bash
   cat > "$CLAUDE_PROJECT_DIR/.planning-session" << 'MARKER'
   {"phase":0,"started":"$(date -u +%Y%m%dT%H%M%SZ)","feature":"$ARGUMENTS","completed":[]}
   MARKER
   ```

2. **Verify** the marker was written:

   ```bash
   cat "$CLAUDE_PROJECT_DIR/.planning-session"
   ```

3. If the marker does not exist after step 1, STOP and report the error. Do not proceed.

### Outputs

- `.planning-session` JSON marker file at `$CLAUDE_PROJECT_DIR/.planning-session`
- Planning guard hooks activated (write-guard, bash-guard, planning-guard)

### Exit Criteria

- `.planning-session` marker file exists and contains valid JSON
- Marker includes feature description, timestamp, and empty completed array
- Planning guard hooks are active and blocking implementation tool calls

---

## Stage Gates

Every stage boundary uses entry/exit gates to enforce ordering. You MUST check the gate before starting a stage and record completion after finishing it.

### Entry Gate Pattern (check before starting stage N)

```bash
COMPLETED=$(jq -r '.completed | join(",")' "$CLAUDE_PROJECT_DIR/.planning-session")
echo "Completed stages: $COMPLETED"
```

Verify that ALL required prior stages are in the completed list. If any are missing, go back and complete them.

### Exit Gate Pattern (record after completing stage N)

```bash
jq '.phase = N | .completed += ["phase-name"]' "$CLAUDE_PROJECT_DIR/.planning-session" > /tmp/.ps-update && mv /tmp/.ps-update "$CLAUDE_PROJECT_DIR/.planning-session"
```

### Stage Completion Requirements

| Stage | Name      | Records        | Required before proceeding  |
| ----- | --------- | -------------- | --------------------------- |
| 2     | marker    | marker created | —                           |
| 3     | interview | `"interview"`  | marker exists               |
| 4     | research  | `"research"`   | interview                   |
| 5     | design    | `"design"`     | interview, research         |
| 6     | document  | `"document"`   | interview, research, design |
| 7     | STOP      | —              | ALL four above              |

---

## Stage 3: Requirements Interview (MANDATORY)

### Inputs

- `.planning-session` marker file (from Stage 2)
- `$ARGUMENTS` — feature description
- Context gathered in Stage 1-2 (project kickoff state, mode calibration)
- Gate check — verify marker exists:
  ```bash
  test -f "$CLAUDE_PROJECT_DIR/.planning-session" && echo "GATE PASS: marker exists" || echo "GATE FAIL: no marker"
  ```

### Activities

**This stage MUST NOT be skipped.** Before any research or design work, gather requirements directly from the user.

1. **MUST** invoke `/spec-discovery $ARGUMENTS` and wait for completion. Do NOT skip this sub-skill or substitute inline questioning.
2. Pass the feature description and any context gathered in Stage 1-2.

> **RULE**: Do NOT proceed to Stage 4 until the user has completed at least one discovery domain. The user's input shapes all subsequent research and design work.

On success: `[x] spec-discovery complete`
On failure: `[!] spec-discovery failed — continuing to next stage`

### Outputs

- Completed requirements discovery (user responses, decisions, and assumptions captured)
- Discovery notes available for subsequent phases

### Exit Criteria

- User has answered at least one round of interview questions
- Record stage completion:
  ```bash
  jq '.phase = 3 | .completed += ["interview"]' "$CLAUDE_PROJECT_DIR/.planning-session" > /tmp/.ps-update && mv /tmp/.ps-update "$CLAUDE_PROJECT_DIR/.planning-session"
  ```

---

## Stage 4: Research

### Inputs

- `.planning-session` marker with `"interview"` in completed array
- `$ARGUMENTS` — feature description
- Interview notes from Stage 3
- Gate check — verify interview complete:
  ```bash
  COMPLETED=$(jq -r '.completed | join(",")' "$CLAUDE_PROJECT_DIR/.planning-session")
  echo "$COMPLETED" | grep -q "interview" && echo "GATE PASS" || echo "GATE FAIL: interview not complete"
  ```

### Activities

1. **MUST** invoke `/design-research $ARGUMENTS` and wait for completion. Do NOT perform research inline — delegate to the sub-skill.
2. Pass the feature description and any interview notes from Stage 3.

On success: `[x] design-research complete`
On failure: `[!] design-research failed — continuing to next stage`

### Outputs

- Research findings and codebase analysis
- Technical context for design phase

### Exit Criteria

- Research sub-skill has completed (success or acknowledged failure)
- Record stage completion:
  ```bash
  jq '.phase = 4 | .completed += ["research"]' "$CLAUDE_PROJECT_DIR/.planning-session" > /tmp/.ps-update && mv /tmp/.ps-update "$CLAUDE_PROJECT_DIR/.planning-session"
  ```

---

## Stage 5: Design

### Inputs

- `.planning-session` marker with `"interview"` and `"research"` in completed array
- `$ARGUMENTS` — feature description
- All prior stage artifacts (interview notes, research findings)
- Gate check — verify interview and research complete:
  ```bash
  COMPLETED=$(jq -r '.completed | join(",")' "$CLAUDE_PROJECT_DIR/.planning-session")
  echo "$COMPLETED" | grep -q "interview" && echo "$COMPLETED" | grep -q "research" && echo "GATE PASS" || echo "GATE FAIL: missing prerequisites"
  ```

### Activities

1. **MUST** invoke `/design-solution $ARGUMENTS` and wait for completion. Do NOT produce design artifacts inline — delegate to the sub-skill.
2. Pass all prior stage artifacts as context.

On success: `[x] design-solution complete`
On failure: `[!] design-solution failed — continuing to next stage`

### Outputs

- Design decisions and architectural approach
- Component/module design artifacts

### Exit Criteria

- Design sub-skill has completed (success or acknowledged failure)
- Record stage completion:
  ```bash
  jq '.phase = 5 | .completed += ["design"]' "$CLAUDE_PROJECT_DIR/.planning-session" > /tmp/.ps-update && mv /tmp/.ps-update "$CLAUDE_PROJECT_DIR/.planning-session"
  ```

---

## Stage 6: Document

### Inputs

- `.planning-session` marker with `"interview"`, `"research"`, and `"design"` in completed array
- `$ARGUMENTS` — feature description
- All prior stage artifacts (interview notes, research findings, design decisions)
- Resolved development mode (determines documentation scope)
- Gate check — verify interview, research, and design complete:
  ```bash
  COMPLETED=$(jq -r '.completed | join(",")' "$CLAUDE_PROJECT_DIR/.planning-session")
  for phase in interview research design; do
    echo "$COMPLETED" | grep -q "$phase" || { echo "GATE FAIL: $phase not complete"; exit 1; }
  done
  echo "GATE PASS: all prerequisites met"
  ```

### Activities

**THIS STAGE IS MANDATORY. DO NOT SKIP IT.**

#### Mode-Based Documentation Scope

- **Lite**: Lightweight documentation only — create a project brief (feature spec) covering scope, goals, and key decisions. Skip research docs, formal ADRs, risk assessments, and detailed API/data specs.
- **Standard**: Standard documentation suite — create BRD, PRD, feature spec, and key specs (API, data). ADRs for significant decisions. Risk assessment optional.
- **Strict**: Full documentation suite — create ALL document types below including formal ADRs, risk assessment, and detailed specs. Nothing is optional.

1. **MUST** invoke `/design-document $ARGUMENTS` and `/design-adr $ARGUMENTS` (if in scope). Do NOT write documentation inline — delegate to the sub-skills.
2. Pass all prior stage artifacts as context.
3. Each sub-skill writes output to `docs/` first. If `CONFLUENCE_ENABLED=true`, the sub-skill handles publishing to Confluence internally — the orchestrator takes no action on publishing.

On success: `[x] design-document complete` / `[x] design-adr complete`
On failure: `[!] {sub-skill} failed — continuing to next stage`

#### Context Sync

After all documents are created, sync context files so agents have fresh specs for implementation:

1. **MUST** run `/sync-context` to compile newly created documents into `.claude/context/project/`. Do NOT skip context sync — /eck:develop depends on up-to-date context files.
2. This ensures /eck:develop will have up-to-date context files when it starts

### Outputs

- Documentation artifacts (scope depends on mode: project brief, BRD, PRD, specs, ADRs, risk assessment)
- Synced context files in `.claude/context/project/`

### Exit Criteria

- All mode-appropriate documentation sub-skills have completed
- Context sync has run successfully
- Record stage completion:
  ```bash
  jq '.phase = 6 | .completed += ["document"]' "$CLAUDE_PROJECT_DIR/.planning-session" > /tmp/.ps-update && mv /tmp/.ps-update "$CLAUDE_PROJECT_DIR/.planning-session"
  ```

---

## Stage 7: Report and STOP

### Inputs

- `.planning-session` marker with ALL four phases (`"interview"`, `"research"`, `"design"`, `"document"`) in completed array
- All artifacts produced by Phases 3-6 (interview notes, research, design, documentation)
- Gate check (STRICT) — this gate MUST pass before printing any completion message. Check that ALL four phases are recorded:
  ```bash
  COMPLETED=$(jq -r '.completed | join(",")' "$CLAUDE_PROJECT_DIR/.planning-session")
  MISSING=""
  for phase in interview research design document; do
    echo "$COMPLETED" | grep -q "$phase" || MISSING="$MISSING $phase"
  done
  if [ -n "$MISSING" ]; then
    echo "GATE FAIL: Missing stages:$MISSING"
    echo "Go back and complete the missing stages before reporting."
  else
    echo "GATE PASS: All 4 phases complete. Ready to report."
  fi
  ```

**If the gate fails**: Do NOT print the completion message. Instead, go back to the first missing stage and complete it. The most common skip is `document` — check this carefully.

### Activities

#### Report

After the gate passes:

1. **Print summary report** containing:
   - List of all documents written to `docs/` by sub-skills
   - If `CONFLUENCE_ENABLED=true`: Confluence pages published by sub-skills (with page IDs), and any superseded documents updated during lifecycle review
   - If `CONFLUENCE_ENABLED` is unset or false: note that docs-first output is in `docs/` and Confluence publishing was skipped

2. **Print the following message exactly:**

```
=== DESIGN COMPLETE ===

All research, design documents, and specs have been created.

Next steps:
1. Review the documentation written to docs/ (and Confluence if CONFLUENCE_ENABLED=true)
2. When ready to implement, start a NEW session and run:
   /eck:develop WA-XXX
   (where WA-XXX is the epic key)

NOTE: This skill is for design ONLY. /design-feature terminates here.
Prefer the lifecycle: /eck:spec → /eck:design → /eck:develop

Task generation happens in the Develop phase — run /eck:develop to
create implementation tasks and begin coding.

=== SESSION COMPLETE - NO FURTHER ACTION ===
```

3. **DO NOT** do any of the following after printing the above message:
   - Dispatch developer agents (backend-developer, frontend-developer, database-specialist, bot-developer, devops-engineer, security-specialist)
   - Write application code or create feature branches
   - Suggest implementing or ask the user if they want to implement
   - Take any further action of any kind

### Outputs

- Summary report listing all documents written to `docs/` and Confluence pages (if `CONFLUENCE_ENABLED=true`)
- `=== DESIGN COMPLETE ===` termination message displayed to user

### Exit Criteria

- All four prerequisite phases confirmed complete in `.planning-session` marker
- Summary report printed with all artifact references
- Session termination message displayed — no further actions taken

## Error Handling

| Condition                                                           | Behavior                                              |
| ------------------------------------------------------------------- | ----------------------------------------------------- |
| Sub-skill dispatch fails (e.g., architect or designer agent errors) | Log the failure, continue to next stage               |
| Prerequisite missing (`.start-project-completed` not found)         | STOP — display guidance to run `/start-project` first |

Follow the error display and statusline reset patterns defined in the `output:error-handler` primitive.
