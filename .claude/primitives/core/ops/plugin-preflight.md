---
name: core/ops:plugin-preflight
description: Verify required official plugins are installed and enabled
version: "0.5.0"
---

# Plugin Preflight

Evaluates which official Claude Code plugins are required, recommended, or informational for the current project configuration. Used by routers and skills to enforce plugin dependencies before dispatching work.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| context | string | No | Calling context for error messages (e.g., skill name) |
| check_levels | string[] | No | Levels to check: `required`, `recommended`, `informational` (default: `["required"]`) |
| blocking | boolean | No | If true (default), STOP on missing required plugins. If false, return result only. |
| skill | string | No | Filter to rules relevant to a specific skill |

## Implementation

1. Read `plugin-manifest.yaml` from `$ECK_HOME/plugin-manifest.yaml`
2. Read `enabledPlugins` from `~/.claude/settings.json`
3. Read project config from `.claude/project-constants.md` (TRACKER_TYPE, DOC_PLATFORM, tech stack fields)
4. Evaluate `dependency_rules` — match conditions against project config
5. Evaluate `tech_stack_rules` — match tech stack fields
6. For each matched rule:
   a. Check if the required plugin is in `enabledPlugins`
   b. If `requires_cli` is set instead, verify CLI availability (e.g., `gh auth status`)
   c. Classify result as satisfied or missing

```python
def plugin_preflight(inputs):
    context = inputs.get("context", "")
    check_levels = inputs.get("check_levels", ["required"])
    blocking = inputs.get("blocking", True)

    # Load manifest
    manifest = yaml_load("$ECK_HOME/plugin-manifest.yaml")
    if not manifest:
        return {"satisfied": False, "error": "PLUGIN_MANIFEST_MISSING",
                "error_message": "plugin-manifest.yaml not found. Run installer to restore."}

    # Load enabled plugins
    settings = json_load("~/.claude/settings.json")
    enabled = settings.get("enabledPlugins", [])

    # Load project config
    constants = read_project_constants()

    satisfied, blocking_missing, warned_missing, informed_missing, installed = [], [], [], []

    # Evaluate dependency rules
    for rule in manifest.get("dependency_rules", []):
        if not condition_matches(rule["condition"], constants):
            continue
        if rule.get("level", "required") not in check_levels:
            continue

        plugin = rule.get("plugin")
        cli = rule.get("requires_cli")

        if plugin and plugin in enabled:
            installed.append(plugin)
        elif cli and cli_available(cli):
            installed.append(f"cli:{cli}")
        elif rule["level"] == "required":
            blocking_missing.append({
                "plugin": plugin or f"cli:{cli}",
                "error_code": rule["error_code"],
                "error_message": rule["error_message"]
            })
        elif rule["level"] == "recommended":
            warned_missing.append({"plugin": plugin, "message": rule.get("error_message", "")})
        else:
            informed_missing.append({"plugin": plugin})

    # Evaluate tech stack rules
    if "recommended" in check_levels:
        for rule in manifest.get("tech_stack_rules", []):
            if not tech_stack_matches(rule["condition"], constants):
                continue
            plugin = rule["plugin"]
            if plugin in enabled:
                installed.append(plugin)
            else:
                warned_missing.append({"plugin": plugin, "level": "recommended"})

    all_satisfied = len(blocking_missing) == 0
    result = {
        "satisfied": all_satisfied,
        "blocking_missing": blocking_missing,
        "warned_missing": warned_missing,
        "informed_missing": informed_missing,
        "installed": list(set(installed)),
    }

    if blocking and not all_satisfied:
        messages = [m["error_message"] for m in blocking_missing]
        raise PluginRequiredError(
            f"Required plugin(s) missing for {context}:\n" +
            "\n".join(f"  - {m}" for m in messages)
        )

    return result
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| satisfied | boolean | All required plugins are installed |
| blocking_missing | object[] | Required plugins that are missing (with error_code + error_message) |
| warned_missing | object[] | Recommended plugins that are missing |
| informed_missing | object[] | Informational plugins that are missing |
| installed | string[] | All matched plugins that are installed |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| PLUGIN_REQUIRED_TRACKER | Tracker plugin missing for configured TRACKER_TYPE | Install the required plugin: `/plugin install <plugin>` |
| PLUGIN_REQUIRED_DOCS | Docs plugin missing for configured DOC_PLATFORM | Install the required plugin: `/plugin install <plugin>` |
| PLUGIN_MANIFEST_MISSING | plugin-manifest.yaml not found | Run `npx @evolvconsulting/evolv-coder-kit --global` to restore |

## Used By

- start-project (Stage 1 blocking preflight)
- plugin-status (comprehensive display)
- deploy-tracker (via tracker:router)
- design-document (via docs:router)
- dev-sprint (via health-check)
