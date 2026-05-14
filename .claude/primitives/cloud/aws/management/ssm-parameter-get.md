---
name: cloud/aws/management:ssm-parameter-get
description: Retrieve a value from AWS Systems Manager Parameter Store
version: "0.4.0"
---

# SSM Parameter Get

Read a single parameter from AWS Systems Manager (SSM) Parameter Store using `aws ssm get-parameter`, with optional decryption for `SecureString` parameters.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Full parameter name or path (e.g., `/myapp/prod/db-password`) |
| with_decryption | boolean | No | Decrypt `SecureString` parameters using the associated KMS key (default: false) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ssm get-parameter \
  --name "{name}" \
  {with_decryption ? "--with-decryption" : "--no-with-decryption"} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Parameter.Name | string | Full parameter name |
| Parameter.Type | string | Parameter type: `String`, `StringList`, or `SecureString` |
| Parameter.Value | string | Parameter value (plaintext for `String`; decrypted if `--with-decryption` was used) |
| Parameter.Version | number | Parameter version number |
| Parameter.LastModifiedDate | string | ISO 8601 timestamp of the last modification |
| Parameter.ARN | string | Amazon Resource Name of the parameter |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:GetParameter` or KMS decrypt | Add `ssm:GetParameter` and `kms:Decrypt` to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| PARAMETER_NOT_FOUND | Parameter name does not exist in the specified region | Verify the name with `aws-cli:ssm-parameter-list` |

## Used By

- dev-task (read configuration and secrets from Parameter Store during development)
