---
name: core/ops:health-check
description: Verify all external dependencies are available
version: "0.5.0"
---

# Health Check

Verify that all required external tools and services are accessible before starting a workflow.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tools | string[] | No | Specific tools to check (default: all configured) |
| required | string[] | No | Services that MUST pass — failure is blocking (default: []) |
| fail_fast | boolean | No | Stop on first failure (default: false) |

## Implementation

Run each configured check and collect results. Default checks:

| Check | Tool/Service | Validation |
|-------|--------------|------------|
| `git` | Git CLI | `git --version` returns 0 |
| `gh` | GitHub CLI | `gh auth status` returns 0 |
| `jira` | JIRA (official plugin) | `mcp__atlassian__getVisibleJiraProjects` succeeds |
| `confluence` | Confluence (official plugin) | `mcp__atlassian__getConfluenceSpaces` succeeds |
| `linear` | Linear (official plugin) | `mcp__linear__list_teams` succeeds |
| `greptile` | Greptile MCP | `mcp__greptile__list_code_reviews` succeeds |
| `aws` | AWS CLI | `aws sts get-caller-identity` returns 0 |
| `plugins` | Official plugins | `core/ops:plugin-preflight` with all levels |

```python
def health_check(inputs):
    checks = inputs.get("tools", ["git", "gh", "jira", "confluence", "greptile"])
    required = inputs.get("required", [])
    fail_fast = inputs.get("fail_fast", False)
    results, failed = [], []

    for check_name in checks:
        try:
            if check_name == "git":
                Bash("git --version")
            elif check_name == "gh":
                Bash("gh auth status")
            elif check_name == "jira":
                mcp__atlassian__getVisibleJiraProjects()
            elif check_name == "confluence":
                mcp__atlassian__getConfluenceSpaces()
            elif check_name == "linear":
                mcp__linear__list_teams(limit=1)
            elif check_name == "greptile":
                mcp__greptile__list_code_reviews(limit=1)
            elif check_name == "aws":
                Bash("aws sts get-caller-identity --output json")
            elif check_name == "plugins":
                result = plugin_preflight(check_levels=["required", "recommended", "informational"], blocking=False)
                if not result["satisfied"]:
                    raise Exception(f"Missing required plugins: {result['blocking_missing']}")
            results.append({"name": check_name, "status": "ok"})
        except:
            results.append({"name": check_name, "status": "failed"})
            failed.append(check_name)
            if fail_fast:
                break

    blocking = [f for f in failed if f in required]
    return {
        "success": len(failed) == 0,
        "blocking": len(blocking) > 0,
        "results": results,
        "failed": failed,
        "blocking_failures": blocking,
    }
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| success | boolean | All checks passed |
| blocking | boolean | True if any required check failed |
| results | object[] | Individual check results with name and status |
| failed | string[] | Names of failed checks |
| blocking_failures | string[] | Names of required checks that failed |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| GIT_UNAVAILABLE | Git CLI not installed or not in PATH | Install git |
| GH_AUTH_FAILED | GitHub CLI not authenticated | Run `gh auth login` |
| JIRA_UNAVAILABLE | JIRA not connected via official plugin | Install: `/plugin install atlassian@claude-plugins-official` |
| CONFLUENCE_UNAVAILABLE | Confluence not connected via official plugin | Install: `/plugin install atlassian@claude-plugins-official` |
| LINEAR_UNAVAILABLE | Linear not connected via official plugin | Install: `/plugin install linear@claude-plugins-official` |
| GREPTILE_UNAVAILABLE | Greptile MCP server not connected | Check MCP configuration |
| AWS_AUTH_FAILED | AWS CLI not configured | Run `aws configure` or check credentials |
| PLUGIN_CHECK_FAILED | One or more required plugins missing | Run `/eck:plugin-status` for details |

## Used By

- dev-sprint (Stage 0 pre-flight check)
- design-feature (Stage 0 optional)
