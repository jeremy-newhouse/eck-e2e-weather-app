---
name: core/ops:checkpoint-verify
description: Verify that an expected artifact exists
version: "0.6.5"
---

# Checkpoint Verify

Verify that an expected artifact exists before recording a checkpoint. Implements atomic verification — checkpoint is only written after confirmed existence.

## Parameters

| Parameter | Type   | Required | Description                                                   |
| --------- | ------ | -------- | ------------------------------------------------------------- |
| type      | string | Yes      | Artifact type: epic_comment, sprint_closed, pr, retrospective |
| context   | object | Yes      | Context for verification (keys depend on type)                |

## Implementation

Execute the appropriate verification check, then write a checkpoint marker only on success.

**epic_comment**: Check for a matching comment on the epic issue.

```bash
# Resolve via tracker:router → tracker:comment-read
comments = tracker:comment-read(issue_key=context["epic_key"])
exists = any(context["pattern"] in c.body for c in comments)
```

**sprint_closed**: Verify sprint is in closed state.

```bash
# Resolve via tracker:router → tracker:sprint-read
sprints = tracker:sprint-read(board_id={BOARD_ID}, state="closed")
exists = context["sprint_id"] in [s["id"] for s in sprints]
```

**pr**: Check for an open PR on the branch.

```bash
# Resolve via tracker:router → tracker:pr-list
tracker:pr-list --head "{context.branch}" --json url,number -q '.[0]'
```

**retrospective**: Search for retrospective page in docs platform.

```bash
# Resolve via docs:router → docs:doc-search
pages = docs:doc-search(query='title~"Sprint N Retrospective"')
exists = len(pages) > 0
```

### Atomic Behavior

1. Execute verification command
2. Parse result
3. IF artifact exists: write checkpoint marker, return `{success: true, exists: true}`
4. IF artifact missing: DO NOT write checkpoint, return `{success: true, exists: false}`
5. IF verification fails (API error): DO NOT write checkpoint, return `{success: false}`

## Output

| Field   | Type    | Description                               |
| ------- | ------- | ----------------------------------------- |
| success | boolean | Verification completed without error      |
| exists  | boolean | Artifact was found                        |
| details | object  | Artifact details if found (URL, ID, etc.) |

## Errors

| Code               | Cause                        | Recovery                                            |
| ------------------ | ---------------------------- | --------------------------------------------------- |
| ARTIFACT_NOT_FOUND | Expected artifact missing    | Re-run the action that creates it                   |
| API_ERROR          | External service unavailable | Retry after delay                                   |
| INVALID_TYPE       | Unknown verification type    | Use: epic_comment, sprint_closed, pr, retrospective |

## Used By

- dev-sprint (Phases 8, 9, 10 verification steps)
- eck:resume (artifact checks during recovery)
