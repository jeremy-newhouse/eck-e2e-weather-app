---
name: cloud/aws/management:ssm-session
description: Open an interactive shell session to a managed EC2 instance via SSM Session Manager
version: "0.4.0"
---

# SSM Session

Start an interactive shell session on an SSM-managed instance without requiring SSH or a bastion host using `aws ssm start-session`.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target | string | Yes | Instance ID (e.g., `i-0123456789abcdef0`) or managed node ID to connect to |
| document_name | string | No | SSM session document to use (default: `SSM-SessionManagerRunShell`) |
| parameters | string | No | JSON map of document-specific parameters |
| reason | string | No | Human-readable reason for starting the session (audit trail) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Prerequisite: install the Session Manager plugin for the AWS CLI.

```bash
aws ssm start-session \
  --target "{target}" \
  {document_name ? "--document-name \"{document_name}\"" : ""} \
  {parameters ? "--parameters '{parameters}'" : ""} \
  {reason ? "--reason \"{reason}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""}
```

Note: `start-session` opens an interactive terminal; it does not support `--output json`.

Port-forwarding variant:

```bash
aws ssm start-session \
  --target "{target}" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["{remote_port}"],"localPortNumber":["{local_port}"]}' \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| SessionId | string | Identifier for the session (visible in session history) |
| (interactive terminal) | stream | Live shell session on the target instance |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ssm:StartSession` on the target | Add `ssm:StartSession` and `ssm:TerminateSession` to the IAM policy |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Target instance is not registered with SSM or is offline | Verify the SSM agent status and instance ID |
| THROTTLED | Session quota for the account has been reached | Terminate unused sessions or request a quota increase |

## Used By

- dev-task (access managed instances for debugging and manual inspection without SSH)
