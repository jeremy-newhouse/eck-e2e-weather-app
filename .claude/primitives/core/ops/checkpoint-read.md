---
name: core/ops:checkpoint-read
description: Read checkpoint file and parse workflow state
version: "0.4.0"
---

# Checkpoint Read

Read the checkpoint state file and parse it to determine workflow progress.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file | string | No | State file path (default: .sprint-state) |

## Implementation

Read and parse the state file to extract markers and determine resume point.

```bash
cat .sprint-state
```

### State Inference

| Last Marker | State | Resume At |
|-------------|-------|-----------|
| None | Fresh start | Stage 0 |
| SPRINT_START | Mid-sprint | Stage 5 (check TASK_COMPLETE markers) |
| TASKS_COMPLETE | Post-task | Stage 6 |
| PHASE_6_COMPLETE | Testing done | Stage 7 |
| PHASE_7_COMPLETE | Docs done | Stage 8 |
| PHASE_8_COMPLETE | Sprint closed | Stage 9 |
| PHASE_9_COMPLETE | PR created | Stage 10 |
| PHASE_10_COMPLETE | Retro done | Sprint complete |
| SPRINT_COMPLETE | All done | Nothing to resume |

Recovery is linear: find last marker, resume at next stage.

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Read succeeded |
| exists | boolean | State file exists |
| markers | object | Parsed markers and timestamps |
| last_marker | string | Most recent marker |
| state | string | Inferred workflow state |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| FILE_NOT_FOUND | State file does not exist | Fresh start, no recovery needed |
| READ_FAILED | Cannot read state file | Check file permissions |
| PARSE_ERROR | State file format corrupted | Delete and restart sprint |

## Used By

- dev-sprint (Stage 0 recovery check)
- eck:resume (session recovery)
