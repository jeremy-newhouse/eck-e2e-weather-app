---
name: cloud/aws/messaging:sqs-send
description: Send a message to an SQS queue
version: "0.4.0"
---

# SQS Send

Deliver a message to an Amazon SQS standard or FIFO queue using `aws sqs send-message`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| queue_url | string | Yes | Full URL of the target SQS queue |
| message_body | string | Yes | Message payload (plain text or JSON string) |
| delay_seconds | number | No | Seconds to delay delivery for standard queues (0–900) |
| message_group_id | string | No | Message group identifier required for FIFO queues |
| message_deduplication_id | string | No | Deduplication token required for FIFO queues without content-based deduplication |
| message_attributes | string | No | JSON map of message attribute objects |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sqs send-message \
  --queue-url "{queue_url}" \
  --message-body "{message_body}" \
  {delay_seconds ? "--delay-seconds {delay_seconds}" : ""} \
  {message_group_id ? "--message-group-id \"{message_group_id}\"" : ""} \
  {message_deduplication_id ? "--message-deduplication-id \"{message_deduplication_id}\"" : ""} \
  {message_attributes ? "--message-attributes '{message_attributes}'" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| MessageId | string | Unique identifier assigned to the sent message |
| MD5OfMessageBody | string | MD5 digest of the message body for integrity verification |
| MD5OfMessageAttributes | string | MD5 digest of message attributes (present when attributes are set) |
| SequenceNumber | string | Sequence number assigned by FIFO queues |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sqs:SendMessage` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Queue URL does not exist or belongs to another account | Verify the queue URL with `aws sqs list-queues` |
| THROTTLED | Request rate exceeded SQS API limits | Implement exponential back-off and retry |

## Used By

- dev-task (publish messages to queues during feature development and integration testing)
