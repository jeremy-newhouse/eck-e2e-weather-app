---
name: cloud/aws/security:iam-list-roles
description: List IAM roles in the current AWS account
version: "0.4.0"
---

# IAM List Roles

Retrieve all AWS Identity and Access Management (IAM) roles in the account, including their ARNs, trust policy documents, and creation dates.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| path_prefix | string | No | IAM path prefix to filter results (e.g., `/service-role/`) |
| max_items | integer | No | Maximum number of roles to return (default: AWS default pagination) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws iam list-roles \
  --output json \
  ${PATH_PREFIX:+--path-prefix "$PATH_PREFIX"} \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"}
```

Note: IAM is a global service; `--region` does not apply but `--profile` still selects the account.

## Output

| Field | Type | Description |
|-------|------|-------------|
| Roles | array | List of role objects |
| Roles[].RoleName | string | IAM role name |
| Roles[].RoleId | string | Unique role identifier |
| Roles[].Arn | string | Full Amazon Resource Name (ARN) |
| Roles[].AssumeRolePolicyDocument | object | URL-encoded trust relationship policy |
| Roles[].CreateDate | string | ISO 8601 creation timestamp |
| IsTruncated | boolean | True if additional pages exist |
| Marker | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `iam:ListRoles` | Request required IAM permissions |
| REGION_NOT_SET | Profile not found or no default region set | Run `aws configure` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified path prefix matches no roles | Verify path prefix format starts and ends with `/` |

## Used By

- validate-security (audit IAM roles for over-permissive trust relationships)
