---
name: cloud/aws/deployment:codebuild-start
description: Start a build for an AWS CodeBuild project
version: "0.4.0"
---

# CodeBuild Start Build

Trigger a new build run for an AWS CodeBuild project, optionally overriding source, environment variables, or other build settings for this specific run.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project_name | string | Yes | Name of the CodeBuild project to build |
| source_version | string | No | Branch, tag, or commit SHA to build (overrides project default) |
| environment_variables_override | string | No | JSON array of environment variable override objects, e.g. `[{"name":"ENV","value":"prod","type":"PLAINTEXT"}]` |
| buildspec_override | string | No | Path or inline buildspec YAML to use instead of the project's buildspec |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws codebuild start-build \
  --project-name "{project_name}" \
  {source_version ? "--source-version {source_version}" : ""} \
  {environment_variables_override ? "--environment-variables-override '{environment_variables_override}'" : ""} \
  {buildspec_override ? "--buildspec-override \"{buildspec_override}\"" : ""} \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| build.id | string | Unique build ID in the form `{project_name}:{build_uuid}` |
| build.buildStatus | string | Initial status: `IN_PROGRESS` |
| build.startTime | string | ISO 8601 timestamp when the build started |
| build.currentPhase | string | Current build phase (e.g., `QUEUED`, `PROVISIONING`) |
| build.logs.deepLink | string | URL to the full build log in CloudWatch Logs |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `codebuild:StartBuild` on this project | Add `codebuild:StartBuild` to the IAM policy |
| RESOURCE_NOT_FOUND | CodeBuild project does not exist in the specified region | Verify the project name and region |
| VALIDATION_ERROR | Malformed environment variable override JSON or invalid buildspec path | Review the JSON array format and buildspec file path |

## Used By

- validate-ci (triggering CodeBuild runs as part of CI pipeline validation)
