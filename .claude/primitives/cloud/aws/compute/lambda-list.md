---
name: cloud/aws/compute:lambda-list
description: List Lambda functions deployed in a region
version: "0.4.0"
---

# Lambda List Functions

Retrieve all Lambda functions in a region, including their ARNs, runtimes, handler paths, memory settings, and last-modified timestamps.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| function_version | string | No | `ALL` to include all versions (default: latest only) |
| max_items | integer | No | Maximum number of functions to return per page |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws lambda list-functions \
  --output json \
  ${FUNCTION_VERSION:+--function-version "$FUNCTION_VERSION"} \
  ${MAX_ITEMS:+--max-items "$MAX_ITEMS"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Functions | array | List of function configuration objects |
| Functions[].FunctionName | string | Function name |
| Functions[].FunctionArn | string | Full ARN of the function |
| Functions[].Runtime | string | Runtime identifier (e.g., `nodejs20.x`, `python3.12`) |
| Functions[].Handler | string | Entry-point handler (e.g., `index.handler`) |
| Functions[].MemorySize | integer | Allocated memory in MB |
| Functions[].Timeout | integer | Maximum execution time in seconds |
| Functions[].LastModified | string | ISO 8601 timestamp of last deployment |
| NextMarker | string | Pagination token for the next page |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `lambda:ListFunctions` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | No functions exist in the region (empty result, not an error) | Verify region is correct |

## Used By

- design-research (inventory serverless functions during architecture discovery)
