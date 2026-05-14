---
name: cloud/aws/ai-ml:sagemaker-invoke
description: Invoke a SageMaker real-time inference endpoint and return the prediction
version: "0.4.0"
---

# SageMaker Invoke

Send an inference request to a SageMaker real-time endpoint using `aws sagemaker-runtime invoke-endpoint`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| endpoint_name | string | Yes | Name of the SageMaker endpoint to invoke |
| body | string | Yes | Inference request payload (format depends on the model container) |
| outfile | string | Yes | Local file path where the response body will be written |
| content_type | string | No | MIME type of the request body (e.g., `application/json`, `text/csv`) |
| accept | string | No | MIME type of the expected response |
| target_variant | string | No | Specific production variant to send the request to |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name "{endpoint_name}" \
  --body '{body}' \
  {content_type ? "--content-type \"{content_type}\"" : ""} \
  {accept ? "--accept \"{accept}\"" : ""} \
  {target_variant ? "--target-variant \"{target_variant}\"" : ""} \
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
| (outfile content) | object | Model prediction response written to the specified output file |
| ContentType | string | MIME type of the response |
| InvokedProductionVariant | string | Name of the production variant that handled the request |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `sagemaker:InvokeEndpoint` | Add the required permission to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Endpoint does not exist or is not `InService` | Verify endpoint status with `aws-cli:sagemaker-list-endpoints` |
| THROTTLED | Request rate exceeded endpoint throughput limits | Scale the endpoint or implement exponential back-off |

## Used By

- dev-task (call SageMaker inference endpoints during AI feature development and testing)
