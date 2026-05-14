---
name: cloud/aws/compute:lambda-logs
description: Filter and tail CloudWatch log events for a Lambda function
version: "0.4.0"
---

# Lambda Logs

Query CloudWatch Logs for events emitted by a Lambda function. Uses the `/aws/lambda/{function-name}` log group and supports time range and pattern filtering.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| function_name | string | Yes | Lambda function name (used to derive the log group) |
| filter_pattern | string | No | CloudWatch filter pattern (e.g., `ERROR`, `[level=ERROR]`) |
| start_time | integer | No | Start of the time range in epoch milliseconds |
| end_time | integer | No | End of the time range in epoch milliseconds |
| limit | integer | No | Maximum number of log events to return (default: 10000) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws logs filter-log-events \
  --log-group-name "/aws/lambda/{function_name}" \
  --output json \
  ${FILTER_PATTERN:+--filter-pattern "$FILTER_PATTERN"} \
  ${START_TIME:+--start-time "$START_TIME"} \
  ${END_TIME:+--end-time "$END_TIME"} \
  ${LIMIT:+--limit "$LIMIT"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| events | array | List of log event objects |
| events[].timestamp | integer | Event timestamp in epoch milliseconds |
| events[].message | string | Log message content |
| events[].logStreamName | string | CloudWatch log stream the event belongs to |
| nextToken | string | Pagination token for the next page of results |
| searchedLogStreams | array | Log streams that were searched |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `logs:FilterLogEvents` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Log group `/aws/lambda/{function_name}` does not exist | Verify function has been invoked at least once to create the log group |

## Used By

- validate-ci (retrieve Lambda execution logs to verify function behavior after deployment)
