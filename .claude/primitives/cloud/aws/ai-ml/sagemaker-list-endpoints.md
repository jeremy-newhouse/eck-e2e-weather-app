---
name: cloud/aws/ai-ml:sagemaker-list-endpoints
description: List Amazon SageMaker inference endpoints and their status
version: "0.4.0"
---

# SageMaker List Endpoints

Retrieve all SageMaker real-time inference endpoints in the current region using `aws sagemaker list-endpoints`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name_contains | string | No | Return only endpoints whose name contains this substring |
| status_equals | string | No | Filter by status: `OutOfService`, `Creating`, `Updating`, `SystemUpdating`, `RollingBack`, `InService`, `Deleting`, or `Failed` |
| sort_by | string | No | Sort key: `Name` (default) or `CreationTime` or `LastModifiedTime` or `Status` |
| sort_order | string | No | Sort direction: `Ascending` (default) or `Descending` |
| max_results | number | No | Maximum number of endpoints to return |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sagemaker list-endpoints \
  {name_contains ? "--name-contains \"{name_contains}\"" : ""} \
  {status_equals ? "--status-equals {status_equals}" : ""} \
  {sort_by ? "--sort-by {sort_by}" : ""} \
  {sort_order ? "--sort-order {sort_order}" : ""} \
  {max_results ? "--max-results {max_results}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Endpoints | object[] | Array of endpoint summary objects |
| Endpoints[].EndpointName | string | Name of the endpoint |
| Endpoints[].EndpointArn | string | ARN of the endpoint |
| Endpoints[].EndpointStatus | string | Current lifecycle status |
| Endpoints[].CreationTime | string | ISO 8601 creation timestamp |
| Endpoints[].LastModifiedTime | string | ISO 8601 timestamp of the last update |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sagemaker:ListEndpoints` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded SageMaker API limits | Implement exponential back-off and retry |

## Used By

- design-research (inventory available SageMaker endpoints before designing AI feature integration)
