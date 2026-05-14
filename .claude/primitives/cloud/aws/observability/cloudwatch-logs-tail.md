---
name: cloud/aws/observability:cloudwatch-logs-tail
description: Stream live log events from a CloudWatch Logs log group
version: "0.4.0"
---

# CloudWatch Logs Tail

Continuously stream new log events from a CloudWatch Logs log group using `aws logs tail --follow`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| log_group_name | string | Yes | Name of the log group to tail (e.g., `/aws/lambda/my-function`) |
| follow | boolean | No | Keep streaming new events until interrupted (default: true) |
| since | string | No | Return events no older than this duration (e.g., `5m`, `1h`, `1d`; default: `10s`) |
| filter_pattern | string | No | CloudWatch filter pattern to apply (e.g., `ERROR`) |
| format | string | No | Output format: `detailed` (default) or `short` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws logs tail "{log_group_name}" \
  --follow \
  {since ? "--since {since}" : ""} \
  {filter_pattern ? "--filter-pattern \"{filter_pattern}\"" : ""} \
  {format ? "--format {format}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""}
```

Note: `aws logs tail` does not support `--output json`; it streams formatted text to stdout. Remove `--follow` to read a bounded snapshot and exit.

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout lines) | string | Timestamped log event lines in the format `YYYY/MM/DD HH:MM:SS.mmm [stream] message` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `logs:FilterLogEvents` or `logs:GetLogEvents` | Add the required permissions to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Log group does not exist | Verify the log group name and region |
| THROTTLED | Request rate exceeded CloudWatch Logs API limits | Reduce polling frequency or use `cloudwatch-logs-query` for batch analysis |

## Used By

- dev-task (monitor Lambda or container logs in real time during development)
