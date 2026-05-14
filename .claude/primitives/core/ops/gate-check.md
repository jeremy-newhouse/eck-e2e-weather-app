---
name: "core/ops:gate-check"
description: "Validates phase prerequisites before T1 orchestrator execution"
version: "0.7.1"
---

# core/ops:gate-check

Formalizes the two-layer prerequisite check invoked by T1 orchestrators in Stage 0. Verifies lifecycle status and gate verdict before allowing phase advancement.

## Parameters

| Parameter              | Required | Description                                                                            |
| ---------------------- | -------- | -------------------------------------------------------------------------------------- |
| `feature_slug`         | Yes      | Feature identifier (kebab-case slug from lifecycle.json)                               |
| `required_step`        | Yes      | Prior step that must be complete (e.g., `spec` for design phase)                       |
| `review_artifact_path` | No       | (deprecated, informational only) Path to prior stage's review artifact for audit trail |
| `passing_verdicts`     | No       | Array of acceptable verdicts. Default: `["PASS", "CONDITIONAL"]`                       |
| `rigor`                | Yes      | Current rigor level (`lite`, `standard`, `strict`)                                     |

## Implementation

### Step 1: Read Lifecycle Status

```bash
node $ECK_HOME/update-lifecycle.js read <feature_slug>
```

Parse the JSON output. Locate `steps.<required_step>`.

### Step 2: Validate Step Completion

Check `steps.<required_step>.status === "done"`.

If not done:

- Report: "Prerequisite step `<required_step>` is not complete (status: `<actual_status>`)."
- Set `passed: false`

### Step 3: Validate Gate Verdict

Check `steps.<required_step>.gate_verdict` is in `passing_verdicts`.

If no gate verdict or verdict not in passing list:

- Report: "Prior gate verdict missing or not passing (verdict: `<actual_verdict>`)."
- Set `passed: false`

### Step 4: Apply Rigor Override Policy

If `passed: false`:

| Rigor      | Override Behavior                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------ |
| `lite`     | `override_allowed: true`. Display warning and proceed with notice.                                                 |
| `standard` | `override_allowed: true`. Require `--force` flag + explicit "YES" confirmation. Record override in lifecycle.json. |
| `strict`   | `override_allowed: false`. Hard block. Must fix and re-run.                                                        |

If `--force` flag is present AND `override_allowed: true`:

```bash
node $ECK_HOME/update-lifecycle.js start <feature_slug> <current_step> --force --reason "<user_reason>"
```

## Output

Return structured result:

```json
{
  "passed": true|false,
  "lifecycle_status": "done|active|pending|failed|gated",
  "gate_verdict": "PASS|CONDITIONAL|FAIL|null",
  "override_allowed": true|false,
  "blocking_reason": "string|null"
}
```

## Errors

| Error                  | Cause                                           | Recovery                                                               |
| ---------------------- | ----------------------------------------------- | ---------------------------------------------------------------------- |
| Feature not found      | `feature_slug` not registered in lifecycle.json | Register feature first via `/eck:spec` or `/eck:create-feature`        |
| Step not found         | Invalid `required_step` value                   | Use valid step name: `spec`, `design`, `develop`, `validate`, `deploy` |
| Lifecycle file missing | No lifecycle.json exists                        | Run `/eck:create-feature` to initialize lifecycle tracking             |

## Used By

- `eck:design` (Stage 0 — requires spec done)
- `eck:develop` (Stage 0 — requires design done)
- `eck:validate` (Stage 0 — requires develop done)
- `eck:deploy` (Stage 0 — requires validate done)
