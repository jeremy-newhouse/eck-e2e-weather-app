---
name: cloud/aws/compute:eks-describe
description: Describe an EKS cluster including version, status, networking, and endpoint
version: "0.4.0"
---

# EKS Describe Cluster

Retrieve full configuration and status for a named Amazon EKS cluster, including Kubernetes version, API server endpoint, OIDC issuer, networking configuration, and logging settings.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | EKS cluster name |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws eks describe-cluster \
  --name {name} \
  --output json \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| cluster.name | string | Cluster name |
| cluster.arn | string | Full cluster ARN |
| cluster.status | string | CREATING, ACTIVE, DELETING, FAILED, or UPDATING |
| cluster.version | string | Kubernetes version (e.g., `1.30`) |
| cluster.endpoint | string | API server endpoint URL |
| cluster.roleArn | string | IAM role ARN used by the control plane |
| cluster.resourcesVpcConfig | object | VPC, subnets, and security group configuration |
| cluster.identity.oidc.issuer | string | OIDC issuer URL for IAM Roles for Service Accounts (IRSA) |
| cluster.logging | object | Enabled control-plane log types |
| cluster.tags | object | Key-value tag pairs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `eks:DescribeCluster` | Request required IAM permissions |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |
| RESOURCE_NOT_FOUND | Named cluster does not exist in the region | Verify cluster name with `aws eks list-clusters` |

## Used By

- design-research (retrieve cluster version and networking details during architecture discovery)
