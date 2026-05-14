---
name: cloud/aws/compute:ec2-start-stop
description: Start or stop one or more EC2 instances by instance ID
version: "0.4.0"
---

# EC2 Start / Stop Instances

Start or stop EC2 instances. The command returns immediately; use `aws ec2 describe-instances` or `aws ec2 wait` to confirm the target state.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| action | string | Yes | `start` or `stop` |
| instance_ids | list | Yes | One or more EC2 instance IDs |
| force | boolean | No | Force-stop without graceful OS shutdown (stop only, default: false) |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

Start instances:

```bash
aws ec2 start-instances \
  --instance-ids {instance_ids} \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Stop instances:

```bash
aws ec2 stop-instances \
  --instance-ids {instance_ids} \
  --output json \
  ${FORCE:+--force} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

Wait for state change (optional):

```bash
aws ec2 wait instance-running --instance-ids {instance_ids}
aws ec2 wait instance-stopped --instance-ids {instance_ids}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| StartingInstances / StoppingInstances | array | State change objects for each instance |
| [].InstanceId | string | EC2 instance ID |
| [].CurrentState.Name | string | State immediately after the call |
| [].PreviousState.Name | string | State before the call |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `ec2:StartInstances` or `ec2:StopInstances` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Instance ID does not exist or is in a terminal state | Verify instance ID and current state |

## Used By

- dev-task (start dev/test instances before work; stop them afterward to control costs)
