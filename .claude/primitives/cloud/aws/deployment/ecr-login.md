---
name: cloud/aws/deployment:ecr-login
description: Authenticate the local Docker client with an Amazon ECR registry
version: "0.4.0"
---

# ECR Login

Retrieve a temporary authentication token from Amazon Elastic Container Registry (ECR) and pipe it to `docker login` so subsequent `docker push` and `docker pull` commands succeed against the registry.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| registry | string | Yes | ECR registry URI in the form `{account_id}.dkr.ecr.{region}.amazonaws.com` |
| region | string | No | AWS region of the ECR registry (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws ecr get-login-password \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
| docker login \
  --username AWS \
  --password-stdin \
  "{registry}"
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| (stdout) | string | `Login Succeeded` on success |
| (exit 0) | — | Docker client is authenticated and ready to push/pull |

The authentication token is valid for 12 hours.

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `ecr:GetAuthorizationToken` | Add `ecr:GetAuthorizationToken` to the IAM policy |
| RESOURCE_NOT_FOUND | Registry URI is incorrect or the registry does not exist | Verify the account ID and region in the registry URI |
| VALIDATION_ERROR | Docker daemon is not running or the registry URI is malformed | Start the Docker daemon and check the registry URI format |

## Used By

- deploy-release (authenticating Docker before pushing container images to ECR)
