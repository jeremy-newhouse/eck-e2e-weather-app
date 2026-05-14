---
name: core/ops:checkpoint-write
description: Write a checkpoint marker to the state file
version: "0.4.0"
---

# Checkpoint Write

Write a checkpoint marker to the state file for workflow recovery and audit trails.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| marker | string | Yes | Checkpoint marker name (e.g., SPRINT_START, TASK_COMPLETE:KEY) |
| file | string | No | State file path (default: .sprint-state) |
| data | string | No | Additional data to record alongside the marker |

## Implementation

Append a timestamped marker line to the state file.

```bash
echo "{marker}: {data} at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> .sprint-state
```

### Marker Types

| Marker | Stage | Description |
|--------|-------|-------------|
| `SPRINT_START` | 4 | Sprint initialized |
| `TASK_COMPLETE:<KEY>` | 5 | Individual task done |
| `TASKS_COMPLETE` | 5 | All tasks in sprint done |
| `PHASE_6_COMPLETE` | 6 | Integration tests passed |
| `PHASE_7_COMPLETE` | 7 | Documentation committed |
| `PHASE_8_COMPLETE` | 8 | Sprint closed in tracker (verified) |
| `PHASE_9_COMPLETE` | 9 | PR created and reviewed |
| `PHASE_10_COMPLETE` | 10 | Retrospective created (verified) |
| `SPRINT_COMPLETE` | Final | All phases done |

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | Write succeeded |
| path | string | State file path used |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| WRITE_FAILED | Cannot write to state file | Check file permissions and disk space |
| INVALID_PATH | State file path invalid | Use default .sprint-state or valid path |

## Used By

- dev-sprint (throughout all phases)
- dev-task (task completion markers)
