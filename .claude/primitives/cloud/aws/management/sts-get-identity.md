---
name: cloud/aws/management:sts-get-identity
description: Return the AWS account, user, and ARN for the active credentials
version: "0.4.0"
---

# STS Get Caller Identity

Call the AWS Security Token Service (STS) to return the account ID, user ID, and ARN of the credentials currently in use. Commonly used as a credentials health check before running subsequent AWS operations.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sts get-caller-identity \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| UserId | string | Unique identifier of the calling entity |
| Account | string | AWS account ID (12-digit number) |
| Arn | string | Full ARN of the calling user, role, or assumed-role session |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured, expired, or revoked | Run `aws configure` or refresh temporary credentials |
| ACCESS_DENIED | SCP or permission boundary blocks `sts:GetCallerIdentity` | Verify organization SCPs with the account owner |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Named profile does not exist in `~/.aws/credentials` | Verify profile name with `aws configure list-profiles` |

## Used By

- dev-sprint (pre-sprint health check to confirm AWS access before long-running operations)
