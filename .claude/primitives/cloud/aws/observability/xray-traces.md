---
name: cloud/aws/observability:xray-traces
description: Retrieve X-Ray trace summaries for distributed request tracing
version: "0.4.0"
---

# X-Ray Traces

Fetch summaries of distributed traces from AWS X-Ray using `aws xray get-trace-summaries`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| start_time | number | Yes | Start of the time range as Unix epoch seconds |
| end_time | number | Yes | End of the time range as Unix epoch seconds |
| filter_expression | string | No | X-Ray filter expression (e.g., `responsetime > 5`, `service("my-api")`) |
| sampling | boolean | No | Return a representative sample rather than all traces (default: false) |
| time_range_type | string | No | `TraceId` (default) or `Event` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws xray get-trace-summaries \
  --start-time {start_time} \
  --end-time {end_time} \
  {filter_expression ? "--filter-expression \"{filter_expression}\"" : ""} \
  {sampling ? "--sampling" : "--no-sampling"} \
  {time_range_type ? "--time-range-type {time_range_type}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| TraceSummaries | object[] | Array of trace summary objects |
| TraceSummaries[].Id | string | Unique trace identifier |
| TraceSummaries[].Duration | number | Total trace duration in seconds |
| TraceSummaries[].ResponseTime | number | Time from first request byte to last response byte |
| TraceSummaries[].HasError | boolean | True if any segment recorded an error (4xx) |
| TraceSummaries[].HasFault | boolean | True if any segment recorded a fault (5xx) |
| TraceSummaries[].HasThrottle | boolean | True if any segment was throttled |
| TraceSummaries[].ServiceIds | object[] | Services involved in the trace |
| ApproximateTime | string | Approximate timestamp of the earliest trace returned |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `xray:GetTraceSummaries` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | No traces found for the specified time range | Widen the time range or confirm X-Ray tracing is enabled on the service |
| THROTTLED | Request rate exceeded X-Ray API limits | Reduce polling frequency or use pagination tokens |

## Used By

- validate-ci (verify end-to-end request tracing for latency and fault detection)
