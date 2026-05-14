---
name: cloud/aws/security:guardduty-findings
description: List and retrieve GuardDuty threat findings for a detector
version: "0.4.0"
---

# GuardDuty Findings

List active threat findings from AWS GuardDuty for a detector, then retrieve full finding details including severity, threat type, and affected resources.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| detector-id | string | Yes | GuardDuty detector ID for the target region |
| finding-criteria | string | No | JSON filter criteria (e.g., filter by severity, type, or account) |
| sort-criteria | string | No | JSON sort criteria (field and order for results) |
| max-results | integer | No | Maximum number of finding IDs to return (1–50) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Step 1 — List finding IDs:

```bash
aws guardduty list-findings \
  --detector-id "${DETECTOR_ID}" \
  --output json \
  ${FINDING_CRITERIA:+--finding-criteria "$FINDING_CRITERIA"} \
  ${SORT_CRITERIA:+--sort-criteria "$SORT_CRITERIA"} \
  ${MAX_RESULTS:+--max-results "$MAX_RESULTS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Step 2 — Retrieve full finding details (up to 50 IDs at once):

```bash
aws guardduty get-findings \
  --detector-id "${DETECTOR_ID}" \
  --finding-ids ${FINDING_IDS} \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

To list detector IDs in a region when the detector ID is unknown:

```bash
aws guardduty list-detectors \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

`list-findings` output:

| Field | Type | Description |
|-------|------|-------------|
| FindingIds | array | List of finding ID strings |
| NextToken | string | Pagination token when more results exist |

`get-findings` output:

| Field | Type | Description |
|-------|------|-------------|
| Findings | array | List of full finding objects |
| Findings[].Id | string | Unique finding identifier |
| Findings[].Type | string | Threat type (e.g., `UnauthorizedAccess:EC2/SSHBruteForce`) |
| Findings[].Severity | number | Severity score (2=Low, 5=Medium, 8=High) |
| Findings[].Title | string | Human-readable finding title |
| Findings[].Description | string | Detailed description of the threat |
| Findings[].Resource | object | Affected AWS resource (instance, bucket, IAM entity, etc.) |
| Findings[].Service.Action | object | Action that triggered the finding |
| Findings[].UpdatedAt | string | ISO 8601 timestamp of the last update |
| Findings[].AccountId | string | AWS account ID where the finding occurred |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `guardduty:ListFindings` or `guardduty:GetFindings` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Detector ID does not exist in this region | Run `aws guardduty list-detectors` to find the correct ID |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- validate-security (review active threat findings before release or as part of security audit)
