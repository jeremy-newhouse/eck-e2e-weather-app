---
name: core/ops:mcp-preflight
description: Validate a single MCP server is reachable before use
version: "0.5.0"
---

# MCP Preflight

Probe an MCP server with a minimal read operation to verify connectivity before dispatching work to it. Used by `tracker:router` and `docs:router` to enforce the no-silent-fallback policy.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| service | string | Yes | Service name: jira, confluence, linear, github, greptile |
| backend | string | No | Backend type: `official` (default) or `custom`. Determines which probe tools to use. |
| blocking | boolean | No | If true (default), STOP on failure. If false, return result only. |

## Implementation

Probe the MCP server with a minimal read operation. Tool names differ by backend type:

### Official Plugin Probes (default)

| Service | Probe Call | Plugin |
|---------|-----------|--------|
| jira | `mcp__atlassian__getVisibleJiraProjects` | atlassian@claude-plugins-official |
| confluence | `mcp__atlassian__getConfluenceSpaces` | atlassian@claude-plugins-official |
| linear | `mcp__linear__list_teams` (TBD) | linear@claude-plugins-official |
| greptile | `mcp__greptile__list_code_reviews` (limit=1) | greptile@claude-plugins-official |

### Custom MCP Server Probes (legacy)

| Service | Probe Call |
|---------|-----------|
| jira | `mcp__jira__get_projects` (limit=1) |
| confluence | `mcp__confluence__get_spaces` (limit=1) |
| linear | `mcp__linear__list_teams` (limit=1) |
| github | `mcp__github__list_repos` (limit=1) |
| greptile | `mcp__greptile__list_code_reviews` (limit=1) |

```python
def mcp_preflight(inputs):
    service = inputs["service"]
    backend = inputs.get("backend", "official")
    blocking = inputs.get("blocking", True)

    official_probes = {
        "jira":       lambda: mcp__atlassian__getVisibleJiraProjects(),
        "confluence": lambda: mcp__atlassian__getConfluenceSpaces(),
        "linear":     lambda: mcp__linear__list_teams(limit=1),
        "greptile":   lambda: mcp__greptile__list_code_reviews(limit=1),
    }

    custom_probes = {
        "jira":       lambda: mcp__jira__get_projects(limit=1),
        "confluence": lambda: mcp__confluence__get_spaces(limit=1),
        "linear":     lambda: mcp__linear__list_teams(limit=1),
        "github":     lambda: mcp__github__list_repos(limit=1),
        "greptile":   lambda: mcp__greptile__list_code_reviews(limit=1),
    }

    probes = official_probes if backend == "official" else custom_probes

    if service not in probes:
        return {"available": False, "service": service,
                "error": f"Unknown service: {service}"}

    try:
        probes[service]()
        return {"available": True, "service": service, "error": None}
    except Exception as e:
        error_msg = str(e)
        if "auth" in error_msg.lower() or "401" in error_msg or "403" in error_msg:
            code = "MCP_AUTH_FAILED"
        else:
            code = "MCP_UNAVAILABLE"

        result = {"available": False, "service": service, "error": error_msg}

        if blocking:
            plugin_hint = ""
            if backend == "official":
                plugin_hint = (
                    f"\n  3. Verify the official plugin is enabled: "
                    f"/plugin install <plugin>@claude-plugins-official"
                )
            raise McpUnavailableError(
                f"{service} MCP server is not responding ({code}).\n"
                f"Options:\n"
                f"  1. Check plugin configuration and verify the server is running\n"
                f"  2. Run /eck:switch-tracker or /eck:switch-docs to change platform"
                f"{plugin_hint}\n"
            )

        return result
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| available | boolean | Server responded successfully |
| service | string | Service name checked |
| error | string? | Error message if unavailable |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| MCP_UNAVAILABLE | Server did not respond or plugin is not configured | Verify plugin is installed and enabled |
| MCP_AUTH_FAILED | Server responded with auth error | Check API key / credentials in plugin configuration |

## Used By

- start-project (Stage 1 informational probe)
- deploy-tracker (Stage 1 MCP validation)
- dev-task (via tracker:router)
- design-document (via docs:router)
