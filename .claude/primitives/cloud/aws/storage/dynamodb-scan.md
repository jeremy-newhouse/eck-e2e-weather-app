---
name: cloud/aws/storage:dynamodb-scan
description: Scan all items from a DynamoDB table
version: "0.4.0"
---

# DynamoDB Scan

Read every item in a DynamoDB table, optionally filtered by a filter expression.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| table_name | string | Yes | Name of the DynamoDB table to scan |
| filter_expression | string | No | Filter expression applied after the scan |
| expression_attribute_values | string | No | JSON map of expression attribute value substitutions |
| max_items | number | No | Maximum number of items to return |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws dynamodb scan \
  --table-name "{table_name}" \
  {filter_expression ? "--filter-expression \"{filter_expression}\"" : ""} \
  {expression_attribute_values ? "--expression-attribute-values '{expression_attribute_values}'" : ""} \
  {max_items ? "--max-items {max_items}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Items | object[] | Array of items returned by the scan |
| Count | number | Number of items in the result set |
| ScannedCount | number | Total items evaluated before filtering |
| LastEvaluatedKey | object | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `dynamodb:Scan` on this table | Add `dynamodb:Scan` to the IAM policy |
| RESOURCE_NOT_FOUND | Table does not exist in the specified region | Verify table name and region with `aws-cli:dynamodb-list-tables` |
| VALIDATION_ERROR | Malformed filter expression or attribute map | Check expression syntax against DynamoDB documentation |

## Used By

- dev-task (reading table contents during development and debugging)
