---
name: cloud/aws/management:ssm-parameter-put
description: Create or update a value in AWS Systems Manager Parameter Store
version: "0.4.0"
---

# SSM Parameter Put

Write or overwrite a parameter in AWS Systems Manager (SSM) Parameter Store using `aws ssm put-parameter`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Full parameter name or path (e.g., `/myapp/prod/db-password`) |
| value | string | Yes | Parameter value to store |
| type | string | Yes | Parameter type: `String`, `StringList`, or `SecureString` |
| description | string | No | Human-readable description of the parameter |
| key_id | string | No | KMS key ID or ARN for `SecureString` encryption (default: AWS-managed key) |
| overwrite | boolean | No | Allow overwriting an existing parameter (default: false) |
| tier | string | No | Storage tier: `Standard` (default), `Advanced`, or `Intelligent-Tiering` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ssm put-parameter \
  --name "{name}" \
  --value "{value}" \
  --type {type} \
  {description ? "--description \"{description}\"" : ""} \
  {key_id ? "--key-id \"{key_id}\"" : ""} \
  {overwrite ? "--overwrite" : ""} \
  {tier ? "--tier {tier}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Version | number | Version number of the created or updated parameter |
| Tier | string | Storage tier applied to the parameter |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:PutParameter` or KMS encrypt | Add `ssm:PutParameter` and `kms:GenerateDataKey` to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| PARAMETER_NOT_FOUND | Parameter exists but `--overwrite` was not set and it cannot be created | Add `--overwrite` flag or check the parameter name |
| THROTTLED | Request rate exceeded SSM API limits | Implement exponential back-off and retry |

## Used By

- dev-task (write configuration and secrets to Parameter Store during setup and deployment)
