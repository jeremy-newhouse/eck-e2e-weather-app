---
name: core/output:error-handler
description: Standard error handling patterns for all staged skills
version: "0.5.8"
type: reference
---

# output:error-handler

Standard error handling patterns for all staged skills. Reference this primitive instead of inlining error display logic.

---

## Error Display Pattern

Use this pattern for all error output:

```bash
source $ECK_HOME/colors.sh
printf '%b\n' "${RED}[!]${RESET} Error message here"
printf '%b\n' "    ${DIM}Recovery guidance here.${RESET}"
```

---

## Sub-skill Failure

When a dispatched sub-skill fails:

1. Log the error with the sub-skill name
2. Determine if the failure is **blocking** or **non-blocking**
3. Continue or halt based on the classification

```bash
source $ECK_HOME/colors.sh
printf '%b\n' "${RED}[!]${RESET} {sub-skill-name} failed — {continuing|halting}"
printf '%b\n' "    ${DIM}Check sub-skill output for details.${RESET}"
```

---

## Gate Failure

When a quality or risk gate returns a failing verdict:

1. Display the gate result prominently with a stage banner
2. List the specific failures
3. Reset the statusline
4. STOP execution — do not proceed past a failed gate

```bash
source $ECK_HOME/colors.sh
echo ""
printf '%b\n' "${ORANGE}${BOLD}Gate: {GATE_NAME}${RESET}"
echo ""
printf '%b\n' "${RED}[!]${RESET} Gate failed: {reason}"
printf '%b\n' "    ${DIM}{Recovery guidance}${RESET}"
```

Then reset the statusline:

```bash
bash $ECK_HOME/update-stage.sh
```

---

## Blocking vs Non-Blocking Errors

| Error Type       | Behavior                                                 | Examples                                                      |
| ---------------- | -------------------------------------------------------- | ------------------------------------------------------------- |
| **Blocking**     | STOP execution, reset statusline, display recovery steps | Gate failure, dev-task failure, critical prerequisite missing |
| **Non-blocking** | Log error, mark stage as failed, continue to next stage  | Optional sub-skill failure, non-critical research failure     |

### Decision Rule

An error is **blocking** if:

- It is a gate failure (risk, quality, security)
- The failed stage is the final mandatory stage (e.g., `dev-task` in `eck:design`)
- A critical prerequisite is missing (e.g., no `TASKS.md` for `eck:develop`)

All other errors are **non-blocking** — log them and continue.

---

## Statusline Reset on Error

Any skill that terminates due to an error **must** reset the statusline before stopping:

```bash
bash $ECK_HOME/update-stage.sh
```

This ensures the statusline does not display a stale stage after the skill exits.

---

## Error Handling Section Template

Every staged skill must include an Error Handling section. Use this template:

```markdown
## Error Handling

| Condition                     | Behavior                          |
| ----------------------------- | --------------------------------- |
| {sub-skill} fails             | Log error, continue to next stage |
| {gate} fails                  | Display report and STOP           |
| Critical prerequisite missing | Display error and STOP            |

Follow the error display, gate failure, and statusline reset patterns defined
in the `output:error-handler` primitive.
```

## Used By

- All staged skills (T1 orchestrators and T2 sub-skills) reference this primitive for error display patterns
- `dev-feature`
- `dev-feature-tdd`
- `dev-task`
- `dev-sprint`
- `design-feature`
- `validate-quality`
- `validate-code`
- `validate-uat`
- `validate-ci`
- `validate-security`
- `dev-branch`
- `dev-commit`
- `validate-merge`
- `dev-pr`
- `dev-push`
- `deploy-release`
