---
name: cloud/aws/security:secrets-get
description: Retrieve the value of a secret from AWS Secrets Manager
version: "0.4.0"
---

# Secrets Get

Retrieve the current value of a secret stored in AWS Secrets Manager by name or ARN. Returns the secret string or binary, plus version metadata.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| secret-id | string | Yes | Secret name, partial ARN, or full ARN (e.g., `prod/myapp/db-password`) |
| version-id | string | No | Specific version UUID to retrieve (default: current staging label `AWSCURRENT`) |
| version-stage | string | No | Version staging label to retrieve (default: `AWSCURRENT`) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ID}" \
  --output json \
  ${VERSION_ID:+--version-id "$VERSION_ID"} \
  ${VERSION_STAGE:+--version-stage "$VERSION_STAGE"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Extract the secret string value only:

```bash
aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ID}" \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"} \
| jq -r '.SecretString'
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| ARN | string | Full ARN of the secret |
| Name | string | Friendly name of the secret |
| SecretString | string | Plaintext secret value (JSON string or arbitrary string) |
| SecretBinary | string | Base64-encoded binary secret value (mutually exclusive with SecretString) |
| VersionId | string | UUID of the version retrieved |
| VersionStages | array | Staging labels attached to this version (e.g., `AWSCURRENT`) |
| CreatedDate | string | ISO 8601 timestamp when the version was created |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `secretsmanager:GetSecretValue` | Request required IAM permissions or resource-based policy update |
| RESOURCE_NOT_FOUND | Secret name or ARN does not exist in this region | Verify name with `aws-cli:secrets-list` |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- dev-task (retrieve runtime credentials and configuration secrets)
