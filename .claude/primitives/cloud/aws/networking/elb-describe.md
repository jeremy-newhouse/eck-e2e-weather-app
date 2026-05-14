---
name: cloud/aws/networking:elb-describe
description: List Application, Network, or Gateway load balancers in a region
version: "0.4.0"
---

# ELB Describe

List Elastic Load Balancers (Application Load Balancers, Network Load Balancers, and Gateway Load Balancers) using the ELBv2 API.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| load-balancer-arns | string[] | No | One or more load balancer ARNs to retrieve |
| names | string[] | No | One or more load balancer names to retrieve |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws elbv2 describe-load-balancers \
  --output json \
  ${LB_ARNS:+--load-balancer-arns $LB_ARNS} \
  ${LB_NAMES:+--names $LB_NAMES} \
  ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
  ${AWS_REGION:+--region "$AWS_REGION"}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| LoadBalancers | array | List of load balancer objects |
| LoadBalancers[].LoadBalancerArn | string | Full ARN of the load balancer |
| LoadBalancers[].LoadBalancerName | string | Human-readable name |
| LoadBalancers[].Type | string | Load balancer type (`application`, `network`, `gateway`) |
| LoadBalancers[].Scheme | string | `internet-facing` or `internal` |
| LoadBalancers[].State.Code | string | Current state (`active`, `provisioning`, `failed`) |
| LoadBalancers[].DNSName | string | DNS name to route traffic to the load balancer |
| LoadBalancers[].VpcId | string | VPC the load balancer is deployed in |
| LoadBalancers[].AvailabilityZones | array | AZ and subnet assignments |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials not configured or expired | Run `aws configure` or refresh credentials |
| ACCESS_DENIED | IAM policy does not allow `elasticloadbalancing:DescribeLoadBalancers` | Request required IAM permissions |
| RESOURCE_NOT_FOUND | Specified ARN or name does not exist in this region | Verify name or ARN and target region |
| REGION_NOT_SET | No region provided and none found in config | Pass `--region` or set `AWS_DEFAULT_REGION` |

## Used By

- design-research (inventory load balancers and traffic routing for architecture scope)
