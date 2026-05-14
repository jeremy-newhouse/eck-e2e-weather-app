---
name: cloud/aws/storage:dynamodb-query
description: Query items from a DynamoDB table using a key condition expression
version: "0.4.0"
---

# DynamoDB Query

Retrieve items from a DynamoDB table that satisfy a key condition expression, using the table's primary key or a global secondary index (GSI).

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| table_name | string | Yes | Name of the DynamoDB table to query |
| key_condition_expression | string | Yes | Key condition expression (partition key required) |
| expression_attribute_values | string | Yes | JSON map of expression attribute value substitutions |
| expression_attribute_names | string | No | JSON map of expression attribute name aliases |
| index_name | string | No | Name of the GSI to query instead of the base table |
| filter_expression | string | No | Additional filter applied after key condition evaluation |
| scan_index_forward | boolean | No | Sort order — `true` ascending, `false` descending (default: true) |
| max_items | number | No | Maximum number of items to return |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws dynamodb query \
  --table-name "{table_name}" \
  --key-condition-expression "{key_condition_expression}" \
  --expression-attribute-values '{expression_attribute_values}' \
  {expression_attribute_names ? "--expression-attribute-names '{expression_attribute_names}'" : ""} \
  {index_name ? "--index-name {index_name}" : ""} \
  {filter_expression ? "--filter-expression \"{filter_expression}\"" : ""} \
  {scan_index_forward === false ? "--no-scan-index-forward" : ""} \
  {max_items ? "--max-items {max_items}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Items | object[] | Items matching the key condition (and optional filter) |
| Count | number | Number of items returned |
| ScannedCount | number | Items evaluated before filtering |
| LastEvaluatedKey | object | Pagination token; present when more pages exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `dynamodb:Query` on this table | Add `dynamodb:Query` to the IAM policy |
| RESOURCE_NOT_FOUND | Table or index does not exist in the specified region | Verify table and index names |
| VALIDATION_ERROR | Malformed key condition expression or missing attribute values | Review expression syntax and ensure all placeholders are in the values map |

## Used By

- dev-task (targeted item retrieval during feature implementation and debugging)
