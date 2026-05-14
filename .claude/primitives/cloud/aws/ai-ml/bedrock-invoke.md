---
name: cloud/aws/ai-ml:bedrock-invoke
description: Invoke an Amazon Bedrock foundation model and return the response body
version: "0.4.0"
---

# Bedrock Invoke

Send an inference request to an Amazon Bedrock foundation model using `aws bedrock-runtime invoke-model`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| model_id | string | Yes | Bedrock model identifier (e.g., `anthropic.claude-3-5-sonnet-20241022-v2:0`) |
| body | string | Yes | JSON request payload conforming to the model's input schema |
| outfile | string | Yes | Local file path where the response body will be written |
| content_type | string | No | MIME type of the request body (default: `application/json`) |
| accept | string | No | MIME type of the expected response (default: `application/json`) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws bedrock-runtime invoke-model \
  --model-id "{model_id}" \
  --body '{body}' \
  {content_type ? "--content-type \"{content_type}\"" : ""} \
  {accept ? "--accept \"{accept}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json \
  "{outfile}"
```

Read the response:

```bash
cat "{outfile}" | jq .
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (outfile content) | object | Model-specific response JSON written to the specified output file |
| contentType | string | MIME type of the response |
| body | string | Base64-encoded response body (decoded automatically by the CLI) |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `bedrock:InvokeModel` or model access not enabled | Add the permission and enable model access in the Bedrock console |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Model ID does not exist or is not available in the region | Verify the model ID with `aws-cli:bedrock-list-models` |
| THROTTLED | Request rate or token quota exceeded | Implement exponential back-off or request a quota increase |

## Used By

- dev-task (call foundation models for AI-powered feature development and testing)
