---
name: cloud/aws/storage:dynamodb-put-item
description: Write a single item to a DynamoDB table
version: "0.4.0"
---

# DynamoDB Put Item

Create or fully replace a single item in a DynamoDB table using its primary key.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| table_name | string | Yes | Name of the DynamoDB table |
| item | string | Yes | JSON representation of the item using DynamoDB attribute format |
| condition_expression | string | No | Conditional write expression (write is skipped if condition fails) |
| expression_attribute_values | string | No | JSON map of expression attribute value substitutions used in the condition |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws dynamodb put-item \
  --table-name "{table_name}" \
  --item '{item}' \
  {condition_expression ? "--condition-expression \"{condition_expression}\"" : ""} \
  {expression_attribute_values ? "--expression-attribute-values '{expression_attribute_values}'" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Attributes | object | Previous item attributes (only present when `--return-values ALL_OLD` is set) |
| ConsumedCapacity | object | Capacity units consumed (only present when return-consumed-capacity is set) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `dynamodb:PutItem` on this table | Add `dynamodb:PutItem` to the IAM policy |
| RESOURCE_NOT_FOUND | Table does not exist in the specified region | Verify table name with `aws-cli:dynamodb-list-tables` |
| VALIDATION_ERROR | Item JSON is malformed or missing required key attributes | Ensure item uses DynamoDB attribute format, e.g. `{"pk": {"S": "value"}}` |
| ConditionalCheckFailedException | Condition expression evaluated to false | Inspect existing item before writing, or remove condition |

## Used By

- dev-task (seeding test data and writing items during feature implementation)
