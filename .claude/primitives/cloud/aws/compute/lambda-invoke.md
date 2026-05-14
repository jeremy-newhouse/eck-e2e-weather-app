---
name: cloud/aws/compute:lambda-invoke
description: Synchronously invoke a Lambda function with an optional JSON payload
version: "0.4.0"
---

# Lambda Invoke

Invoke an AWS Lambda function and capture its response. Supports synchronous (RequestResponse) and asynchronous (Event) invocation types.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| function_name | string | Yes | Function name, ARN, or partial ARN |
| payload | string | No | JSON string or `fileb://path` to a binary payload file |
| invocation_type | string | No | `RequestResponse` (default), `Event`, or `DryRun` |
| log_type | string | No | `Tail` to include last 4 KB of execution log in response |
| output_file | string | No | Local file path to write the function response body |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws lambda invoke \
  --function-name {function_name} \
  --output json \
  ${PAYLOAD:+--payload "$PAYLOAD"} \
  ${INVOCATION_TYPE:+--invocation-type "$INVOCATION_TYPE"} \
  ${LOG_TYPE:+--log-type "$LOG_TYPE"} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"} \
  ${OUTPUT_FILE:-/dev/stdout}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| StatusCode | integer | HTTP status code of the invocation (200 = success) |
| FunctionError | string | `Handled` or `Unhandled` if the function returned an error |
| LogResult | string | Base64-encoded tail of the execution log (if `--log-type Tail`) |
| ExecutedVersion | string | Version of the function that was invoked |
| (output file) | JSON | Function response payload written to the specified file |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `lambda:InvokeFunction` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Function name or ARN does not exist in the region | Verify function name with `aws lambda list-functions` |

## Used By

- dev-task (invoke Lambda functions during integration testing or manual verification)
