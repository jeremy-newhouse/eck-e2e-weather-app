---
name: cloud/aws/observability:cloudwatch-logs-query
description: Run a CloudWatch Logs Insights query and retrieve the results
version: "0.4.0"
---

# CloudWatch Logs Query

Start a CloudWatch Logs Insights query with `aws logs start-query`, then poll `aws logs get-query-results` until the query completes.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| log_group_names | string | Yes | Space-separated list of log group names to query |
| query_string | string | Yes | Logs Insights query string (e.g., `fields @timestamp, @message | filter @message like /ERROR/`) |
| start_time | number | Yes | Query start time as Unix epoch seconds |
| end_time | number | Yes | Query end time as Unix epoch seconds |
| limit | number | No | Maximum number of log events to return (default: 1000) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Start the query:

```bash
aws logs start-query \
  --log-group-names {log_group_names} \
  --query-string "{query_string}" \
  --start-time {start_time} \
  --end-time {end_time} \
  {limit ? "--limit {limit}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

Poll for results (repeat until `status` is `Complete`):

```bash
aws logs get-query-results \
  --query-id "{query_id}" \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| queryId | string | Identifier returned by `start-query`; used to poll results |
| status | string | Query status: `Scheduled`, `Running`, `Complete`, `Failed`, or `Cancelled` |
| results | object[][] | Array of result rows; each row is an array of `{field, value}` objects |
| statistics.recordsMatched | number | Total log events that matched the query |
| statistics.recordsScanned | number | Total log events scanned during the query |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `logs:StartQuery` or `logs:GetQueryResults` | Add the required permissions to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | One or more log group names do not exist | Verify log group names with `aws logs describe-log-groups` |
| THROTTLED | Concurrent query limit reached for the account | Wait for existing queries to complete before starting new ones |

## Used By

- validate-ci (search for errors in CI pipeline execution logs)
