---
name: cloud/aws/security:iam-list-users
description: List IAM users in the current AWS account
version: "0.4.0"
---

# IAM List Users

Retrieve all AWS Identity and Access Management (IAM) users in the account, including their ARNs, creation dates, and password last-used timestamps.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| path_prefix | string | No | IAM path prefix to filter results (e.g., `/engineering/`) |
| max_items | integer | No | Maximum number of users to return (default: AWS default pagination) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws iam list-users \
  --output json \
  ${PATH_PREFIX:+--path-prefix "$PATH_PREFIX"} \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"}
```

Note: IAM is a global service; `--region` does not apply but `--profile` still selects the account.

## Output

| Field | Type | Description |
|-------|------|-------------|
| Users | array | List of user objects |
| Users[].UserName | string | IAM user name |
| Users[].UserId | string | Unique user identifier |
| Users[].Arn | string | Full Amazon Resource Name (ARN) |
| Users[].CreateDate | string | ISO 8601 creation timestamp |
| Users[].PasswordLastUsed | string | ISO 8601 timestamp of last console login |
| IsTruncated | boolean | True if additional pages exist |
| Marker | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `iam:ListUsers` | Request required IAM permissions |
| REGION_NOT_SET | Profile not found or no default region set | Run `aws configure` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified path prefix matches no users | Verify path prefix format starts and ends with `/` |

## Used By

- validate-security (audit active IAM users for principle-of-least-privilege review)
