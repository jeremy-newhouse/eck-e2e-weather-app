---
name: cloud/aws/observability:cloudwatch-get-metrics
description: Retrieve metric statistics for a CloudWatch metric over a time range
version: "0.4.0"
---

# CloudWatch Get Metrics

Fetch statistical data points for a named CloudWatch metric using `aws cloudwatch get-metric-statistics`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| namespace | string | Yes | CloudWatch metric namespace (e.g., `AWS/Lambda`) |
| metric_name | string | Yes | Name of the metric to query |
| dimensions | string | No | JSON array of `{Name, Value}` dimension filters |
| start_time | string | Yes | ISO 8601 start time (e.g., `2026-03-06T00:00:00Z`) |
| end_time | string | Yes | ISO 8601 end time (e.g., `2026-03-06T01:00:00Z`) |
| period | number | Yes | Granularity in seconds (minimum 60, must be multiple of 60) |
| statistics | string | Yes | Comma-separated statistics: `Average`, `Sum`, `Maximum`, `Minimum`, `SampleCount` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudwatch get-metric-statistics \
  --namespace "{namespace}" \
  --metric-name "{metric_name}" \
  {dimensions ? "--dimensions {dimensions}" : ""} \
  --start-time "{start_time}" \
  --end-time "{end_time}" \
  --period {period} \
  --statistics {statistics} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Datapoints | object[] | Array of data points, each with `Timestamp`, `Average`, `Sum`, `Maximum`, `Minimum`, `SampleCount`, and `Unit` |
| Label | string | Display label for the metric |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudwatch:GetMetricStatistics` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Namespace or metric name does not exist in the region | Verify namespace and metric name in the CloudWatch console |
| THROTTLED | Request rate exceeded CloudWatch API limits | Reduce polling frequency or implement exponential back-off |

## Used By

- deploy-status (verify service health metrics after deployment)
