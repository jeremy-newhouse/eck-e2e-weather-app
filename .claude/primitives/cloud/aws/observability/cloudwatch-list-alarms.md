---
name: cloud/aws/observability:cloudwatch-list-alarms
description: List CloudWatch alarms and their current state
version: "0.4.0"
---

# CloudWatch List Alarms

Retrieve all CloudWatch metric alarms, optionally filtered by state or name prefix, using `aws cloudwatch describe-alarms`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| alarm_name_prefix | string | No | Return only alarms whose name starts with this prefix |
| state_value | string | No | Filter by state: `OK`, `ALARM`, or `INSUFFICIENT_DATA` |
| alarm_names | string | No | Space-separated list of exact alarm names to retrieve |
| max_records | number | No | Maximum number of alarms to return (default: 100) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudwatch describe-alarms \
  {alarm_name_prefix ? "--alarm-name-prefix \"{alarm_name_prefix}\"" : ""} \
  {state_value ? "--state-value {state_value}" : ""} \
  {alarm_names ? "--alarm-names {alarm_names}" : ""} \
  {max_records ? "--max-records {max_records}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| MetricAlarms | object[] | Array of alarm objects |
| MetricAlarms[].AlarmName | string | Name of the alarm |
| MetricAlarms[].StateValue | string | Current state: `OK`, `ALARM`, or `INSUFFICIENT_DATA` |
| MetricAlarms[].StateReason | string | Human-readable explanation of the current state |
| MetricAlarms[].MetricName | string | CloudWatch metric the alarm monitors |
| MetricAlarms[].Threshold | number | Threshold value that triggers the alarm |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudwatch:DescribeAlarms` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded CloudWatch API limits | Reduce polling frequency or implement exponential back-off |

## Used By

- deploy-status (check alarm states to confirm a deployment is healthy)
