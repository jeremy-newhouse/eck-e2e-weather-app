---
name: cloud/aws/messaging:sns-publish
description: Publish a message to an SNS topic or directly to an endpoint
version: "0.4.0"
---

# SNS Publish

Send a notification message to an Amazon SNS topic or a direct endpoint using `aws sns publish`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| topic_arn | string | No | ARN of the SNS topic to publish to (required when `target_arn` is omitted) |
| target_arn | string | No | ARN of a specific endpoint to publish to (alternative to `topic_arn`) |
| message | string | Yes | Message payload to publish |
| subject | string | No | Subject line (used for email subscriptions) |
| message_structure | string | No | Set to `json` to send different payloads per protocol |
| message_attributes | string | No | JSON map of message attribute objects for filtering |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sns publish \
  {topic_arn ? "--topic-arn \"{topic_arn}\"" : ""} \
  {target_arn ? "--target-arn \"{target_arn}\"" : ""} \
  --message "{message}" \
  {subject ? "--subject \"{subject}\"" : ""} \
  {message_structure ? "--message-structure {message_structure}" : ""} \
  {message_attributes ? "--message-attributes '{message_attributes}'" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| MessageId | string | Unique identifier assigned to the published message |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sns:Publish` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Topic ARN or target ARN does not exist | Verify the ARN with `aws-cli:sns-list-topics` |
| THROTTLED | Request rate exceeded SNS API limits | Implement exponential back-off and retry |

## Used By

- dev-task (trigger notifications and fan-out events during feature development)
