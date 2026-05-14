---
name: cloud/aws/ai-ml:bedrock-list-models
description: List available Amazon Bedrock foundation models
version: "0.4.0"
---

# Bedrock List Models

Retrieve foundation models available for inference in the current region using `aws bedrock list-foundation-models`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| by_provider | string | No | Filter results to a specific model provider (e.g., `Anthropic`, `Amazon`, `Meta`) |
| by_output_modality | string | No | Filter by output type: `TEXT`, `IMAGE`, or `EMBEDDING` |
| by_inference_type | string | No | Filter by inference type: `ON_DEMAND` or `PROVISIONED` |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws bedrock list-foundation-models \
  {by_provider ? "--by-provider \"{by_provider}\"" : ""} \
  {by_output_modality ? "--by-output-modality {by_output_modality}" : ""} \
  {by_inference_type ? "--by-inference-type {by_inference_type}" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| modelSummaries | object[] | Array of available model summary objects |
| modelSummaries[].modelId | string | Identifier used in `aws-cli:bedrock-invoke` |
| modelSummaries[].modelName | string | Human-readable model name |
| modelSummaries[].providerName | string | Name of the model provider |
| modelSummaries[].inputModalities | string[] | Accepted input types (e.g., `TEXT`, `IMAGE`) |
| modelSummaries[].outputModalities | string[] | Produced output types |
| modelSummaries[].modelLifecycle.status | string | Lifecycle status: `ACTIVE` or `LEGACY` |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `bedrock:ListFoundationModels` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| THROTTLED | Request rate exceeded Bedrock API limits | Implement exponential back-off and retry |

## Used By

- design-research (identify available Bedrock models to select the best fit for a feature)
