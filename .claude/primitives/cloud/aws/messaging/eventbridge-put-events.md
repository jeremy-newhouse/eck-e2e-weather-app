---
name: cloud/aws/messaging:eventbridge-put-events
description: Publish one or more custom events to Amazon EventBridge
version: "0.4.0"
---

# EventBridge Put Events

Send custom events to an Amazon EventBridge event bus using `aws events put-events`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| entries | string | Yes | JSON array of event entry objects (see Implementation for schema) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

Each entry object supports:

| Entry Field | Type | Required | Description |
|-------------|------|----------|-------------|
| Source | string | Yes | Identifies the application or service producing the event |
| DetailType | string | Yes | Free-form string describing the event category |
| Detail | string | Yes | JSON string payload for the event |
| EventBusName | string | No | Name or ARN of the target event bus (default: `default`) |
| Time | string | No | ISO 8601 timestamp for the event |
| Resources | string[] | No | ARNs of resources involved in the event |

## Implementation

```bash
aws events put-events \
  --entries '{entries}' \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

Example `entries` value:

```json
[
  {
    "Source": "myapp.orders",
    "DetailType": "OrderPlaced",
    "Detail": "{\"orderId\": \"123\", \"amount\": 49.99}",
    "EventBusName": "default"
  }
]
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| FailedEntryCount | number | Number of entries that failed to publish (0 on full success) |
| Entries | object[] | Result for each submitted entry |
| Entries[].EventId | string | ID assigned to a successfully published event |
| Entries[].ErrorCode | string | Error code for a failed entry |
| Entries[].ErrorMessage | string | Human-readable error description for a failed entry |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `events:PutEvents` on the target bus | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Specified event bus does not exist | Verify the event bus name or ARN |
| THROTTLED | Request rate exceeded EventBridge API limits | Implement exponential back-off and retry |

## Used By

- dev-task (publish domain events to EventBridge during feature development and integration testing)
