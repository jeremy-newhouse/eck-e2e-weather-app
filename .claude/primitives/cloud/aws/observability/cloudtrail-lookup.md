---
name: cloud/aws/observability:cloudtrail-lookup
description: Search CloudTrail event history by attribute, time range, or resource
version: "0.4.0"
---

# CloudTrail Lookup

Query recent AWS API activity from CloudTrail using `aws cloudtrail lookup-events`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| lookup_attributes | string | No | JSON array of `{AttributeKey, AttributeValue}` filters (e.g., EventName, Username, ResourceName) |
| start_time | string | No | ISO 8601 start time to constrain results |
| end_time | string | No | ISO 8601 end time to constrain results |
| max_results | number | No | Maximum number of events to return (default: 50; max: 50 per page) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws cloudtrail lookup-events \
  {lookup_attributes ? "--lookup-attributes {lookup_attributes}" : ""} \
  {start_time ? "--start-time \"{start_time}\"" : ""} \
  {end_time ? "--end-time \"{end_time}\"" : ""} \
  {max_results ? "--max-results {max_results}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Events | object[] | Array of CloudTrail event records |
| Events[].EventId | string | Unique identifier for the event |
| Events[].EventName | string | AWS API action that was called |
| Events[].EventTime | string | Timestamp of the event |
| Events[].Username | string | IAM identity that performed the action |
| Events[].Resources | object[] | AWS resources involved in the event |
| Events[].CloudTrailEvent | string | Raw JSON event record (includes request and response details) |
| NextToken | string | Pagination token; present when more results exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `cloudtrail:LookupEvents` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded CloudTrail API limits | Reduce request frequency or switch to CloudTrail Lake for high-volume queries |

## Used By

- validate-security (audit API calls for unauthorized access or privilege escalation)
