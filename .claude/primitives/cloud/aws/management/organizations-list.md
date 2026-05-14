---
name: cloud/aws/management:organizations-list
description: List all accounts in the AWS Organization
version: "0.4.0"
---

# Organizations List Accounts

Retrieve all AWS accounts in the organization, including their IDs, names, statuses, and email addresses. Requires credentials from the organization's management (root) account or a delegated administrator account.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| max_results | integer | No | Maximum number of accounts to return per page |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws organizations list-accounts \
  --output json \
  ${MAX_RESULTS:+--max-results "$MAX_RESULTS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Accounts | array | List of account objects |
| Accounts[].Id | string | 12-digit AWS account ID |
| Accounts[].Arn | string | Full ARN of the account |
| Accounts[].Name | string | Human-readable account name |
| Accounts[].Email | string | Root email address for the account |
| Accounts[].Status | string | ACTIVE, SUSPENDED, or PENDING_CLOSURE |
| Accounts[].JoinedTimestamp | string | ISO 8601 timestamp when the account joined |
| NextToken | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | Caller is not the management account or a delegated administrator | Use management account credentials |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Account is not part of an AWS Organization | Enable AWS Organizations in the management account |

## Used By

- design-research (enumerate all accounts in a multi-account environment during discovery)
