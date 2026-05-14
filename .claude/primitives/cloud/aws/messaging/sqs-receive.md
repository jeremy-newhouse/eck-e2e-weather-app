---
name: cloud/aws/messaging:sqs-receive
description: Poll messages from an SQS queue
version: "0.4.0"
---

# SQS Receive

Read one or more messages from an Amazon SQS queue using `aws sqs receive-message`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| queue_url | string | Yes | Full URL of the SQS queue to poll |
| max_number_of_messages | number | No | Maximum messages to retrieve per call (1–10; default: 1) |
| wait_time_seconds | number | No | Long-poll duration in seconds (0–20; default: 0 for short poll) |
| visibility_timeout | number | No | Seconds the message is hidden from other consumers after retrieval |
| attribute_names | string | No | Space-separated queue attribute names to include (e.g., `All`) |
| message_attribute_names | string | No | Space-separated message attribute names to return |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sqs receive-message \
  --queue-url "{queue_url}" \
  {max_number_of_messages ? "--max-number-of-messages {max_number_of_messages}" : ""} \
  {wait_time_seconds ? "--wait-time-seconds {wait_time_seconds}" : ""} \
  {visibility_timeout ? "--visibility-timeout {visibility_timeout}" : ""} \
  {attribute_names ? "--attribute-names {attribute_names}" : ""} \
  {message_attribute_names ? "--message-attribute-names {message_attribute_names}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Messages | object[] | Array of received message objects (empty array if queue is empty) |
| Messages[].MessageId | string | Unique identifier of the message |
| Messages[].ReceiptHandle | string | Handle used to delete or change visibility of the message |
| Messages[].MD5OfBody | string | MD5 digest for integrity verification |
| Messages[].Body | string | Message payload |
| Messages[].Attributes | object | System attributes (e.g., `ApproximateFirstReceiveTimestamp`) |
| Messages[].MessageAttributes | object | Custom message attributes |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sqs:ReceiveMessage` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Queue URL does not exist | Verify the queue URL with `aws sqs list-queues` |
| THROTTLED | Request rate exceeded SQS API limits | Increase `wait_time_seconds` to use long polling and reduce API calls |

## Used By

- dev-task (consume and inspect messages during development and integration testing)
