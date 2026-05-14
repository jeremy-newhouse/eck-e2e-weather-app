---
name: cloud/aws/messaging:sns-list-topics
description: List all SNS topics in the current account and region
version: "0.4.0"
---

# SNS List Topics

Retrieve all Amazon SNS topics owned by the caller using `aws sns list-topics`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| next_token | string | No | Pagination token returned by a previous call |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sns list-topics \
  {next_token ? "--next-token \"{next_token}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Topics | object[] | Array of topic objects |
| Topics[].TopicArn | string | Amazon Resource Name (ARN) of the topic |
| NextToken | string | Pagination token; present when more topics exist |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sns:ListTopics` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded SNS API limits | Implement exponential back-off and retry |

## Used By

- design-research (inventory SNS topics to understand existing messaging infrastructure)
