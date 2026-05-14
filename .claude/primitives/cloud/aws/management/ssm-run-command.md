---
name: cloud/aws/management:ssm-run-command
description: Run a command on managed EC2 instances via SSM Run Command
version: "0.4.0"
---

# SSM Run Command

Execute a command on one or more SSM-managed EC2 instances using `aws ssm send-command`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| document_name | string | Yes | SSM document name (e.g., `AWS-RunShellScript`, `AWS-RunPowerShellScript`) |
| targets | string | Yes | JSON array of target objects specifying instances by ID or tag (e.g., `[{"Key":"tag:Env","Values":["prod"]}]`) |
| parameters | string | No | JSON map of document parameter values (e.g., `{"commands":["echo hello"]}`) |
| timeout_seconds | number | No | Time in seconds before the command times out (default: 3600; max: 172800) |
| comment | string | No | Short description of the command execution |
| output_s3_bucket_name | string | No | S3 bucket to store command output |
| output_s3_key_prefix | string | No | S3 key prefix for command output objects |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ssm send-command \
  --document-name "{document_name}" \
  --targets '{targets}' \
  {parameters ? "--parameters '{parameters}'" : ""} \
  {timeout_seconds ? "--timeout-seconds {timeout_seconds}" : ""} \
  {comment ? "--comment \"{comment}\"" : ""} \
  {output_s3_bucket_name ? "--output-s3-bucket-name \"{output_s3_bucket_name}\"" : ""} \
  {output_s3_key_prefix ? "--output-s3-key-prefix \"{output_s3_key_prefix}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

Poll for results:

```bash
aws ssm get-command-invocation \
  --command-id "{command_id}" \
  --instance-id "{instance_id}" \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| Command.CommandId | string | Unique identifier for the command execution |
| Command.Status | string | Overall status: `Pending`, `InProgress`, `Success`, `Cancelled`, `Failed`, or `TimedOut` |
| Command.TargetCount | number | Number of instances targeted |
| Command.CompletedCount | number | Number of instances that have completed execution |
| Command.ErrorCount | number | Number of instances that reported errors |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:SendCommand` on the target document | Add `ssm:SendCommand` and the required document permissions to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Target instances are not registered with SSM or do not match the targets filter | Verify the SSM agent is running and instances are managed |
| THROTTLED | Request rate exceeded SSM API limits | Implement exponential back-off and retry |

## Used By

- dev-task (execute remote commands on managed instances during deployment and debugging)
