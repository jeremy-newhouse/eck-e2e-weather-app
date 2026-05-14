---
name: cloud/aws/security:secrets-list
description: List secrets stored in AWS Secrets Manager with optional name filter
version: "0.4.0"
---

# Secrets List

List all secrets visible to the caller in AWS Secrets Manager, including their ARNs, names, descriptions, and rotation configuration.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| filters | string[] | No | Key=Values filter pairs (e.g., `Key=name,Values=prod/`) to narrow results |
| max-results | integer | No | Maximum number of secrets to return per page (1–100) |
| sort-order | string | No | Sort order for results: `asc` or `desc` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws secretsmanager list-secrets \
  --output json \
  ${FILTERS:+--filters $FILTERS} \
  ${MAX_RESULTS:+--max-results "$MAX_RESULTS"} \
  ${SORT_ORDER:+--sort-order "$SORT_ORDER"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| SecretList | array | List of secret metadata objects |
| SecretList[].ARN | string | Full ARN of the secret |
| SecretList[].Name | string | Friendly name of the secret |
| SecretList[].Description | string | Optional description |
| SecretList[].LastChangedDate | string | ISO 8601 timestamp of the last value change |
| SecretList[].LastRotatedDate | string | ISO 8601 timestamp of the last automatic rotation |
| SecretList[].RotationEnabled | boolean | Whether automatic rotation is configured |
| SecretList[].Tags | array | Name/Value tag pairs |
| NextToken | string | Pagination token when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `secretsmanager:ListSecrets` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- validate-security (audit secret inventory, rotation status, and naming conventions)
