---
name: cloud/aws/storage:dynamodb-list-tables
description: List all DynamoDB tables in an AWS account and region
version: "0.4.0"
---

# DynamoDB List Tables

Return the names of all DynamoDB tables available in the target region.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| limit | number | No | Maximum number of table names to return per page (default: 100) |
| exclusive_start_table_name | string | No | Pagination token — first table name to evaluate (from a previous response) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws dynamodb list-tables \
  {limit ? "--limit {limit}" : ""} \
  {exclusive_start_table_name ? "--exclusive-start-table-name {exclusive_start_table_name}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| TableNames | string[] | Names of tables in the region |
| LastEvaluatedTableName | string | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `dynamodb:ListTables` | Add `dynamodb:ListTables` to the IAM policy |
| VALIDATION_ERROR | Invalid limit value or malformed pagination token | Use a positive integer for limit and copy the token exactly from the previous response |

## Used By

- design-research (discovering existing DynamoDB tables during architecture research)
