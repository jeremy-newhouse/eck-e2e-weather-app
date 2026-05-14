---
name: core/ops:checkpoint-require-complete
description: Block workflow if prior workflow is incomplete
version: "0.4.0"
---

# Checkpoint Require Complete

Block workflow execution if a prior workflow is incomplete. Zero-trust enforcement pattern.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| blocking_marker | string | Yes | Marker that triggers the check (e.g., TASKS_COMPLETE) |
| required_marker | string | Yes | Marker that MUST exist (e.g., SPRINT_COMPLETE) |
| file | string | No | State file path (default: .sprint-state) |
| override | boolean | No | Allow bypass with user confirmation (default: false) |

## Implementation

Check the state file for the blocking marker without the required completion marker.

```bash
if [ -f .sprint-state ]; then
  if grep -q "{blocking_marker}" .sprint-state && ! grep -q "{required_marker}" .sprint-state; then
    echo "BLOCKED: Prior sprint incomplete"
    LAST_PHASE=$(grep -o 'PHASE_[0-9]*_COMPLETE' .sprint-state | tail -1)
    if [ -n "$LAST_PHASE" ]; then
      NEXT_PHASE=$((${LAST_PHASE//[^0-9]/} + 1))
      echo "RESUME: Phase $NEXT_PHASE"
    else
      echo "RESUME: Stage 6 (Post-task phases)"
    fi
    exit 1
  fi
fi
echo "PASS: No incomplete prior workflow"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Check passed (no blocking condition) |
| blocked | boolean | Prior workflow is incomplete |
| resume_phase | string | Phase to resume at if blocked |
| message | string | Explanation for user |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| INCOMPLETE_PRIOR | blocking_marker exists without required_marker | Resume prior workflow or use override |

## Used By

- dev-sprint (Stage 0 blocking check)
