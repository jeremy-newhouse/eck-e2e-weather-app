---
name: cloud/aws/deployment:codepipeline-status
description: Get the current execution state of an AWS CodePipeline pipeline
version: "0.4.0"
---

# CodePipeline Status

Return the current state of every stage and action in an AWS CodePipeline pipeline, including the most recent execution status and timestamps.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| pipeline_name | string | Yes | Name of the CodePipeline pipeline |
| region | string | No | AWS region (default: profile/env default) |
| profile | string | No | AWS CLI named profile to use |

## Implementation

```bash
aws codepipeline get-pipeline-state \
  --name "{pipeline_name}" \
  {region ? "--region {region}" : ""} \
  {profile ? "--profile {profile}" : ""} \
  --output json
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| pipelineName | string | Name of the pipeline |
| pipelineVersion | number | Current version number of the pipeline definition |
| stageStates | object[] | Array of stage state objects |
| stageStates[].stageName | string | Name of the stage |
| stageStates[].latestExecution.status | string | Most recent execution status: `InProgress`, `Succeeded`, `Failed`, `Stopped` |
| stageStates[].actionStates | object[] | Per-action status, including entity URLs and error details |
| updated | string | ISO 8601 timestamp of the last state update |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| AUTH_FAILED | AWS credentials missing or expired | Run `aws configure` or refresh session token |
| ACCESS_DENIED | IAM policy does not allow `codepipeline:GetPipelineState` | Add `codepipeline:GetPipelineState` to the IAM policy |
| RESOURCE_NOT_FOUND | Pipeline does not exist in the specified region | Verify the pipeline name and region |
| VALIDATION_ERROR | Malformed pipeline name | Use the exact name of the pipeline as shown in the AWS console |

## Used By

- validate-ci (monitoring pipeline execution state during CI/CD validation)
