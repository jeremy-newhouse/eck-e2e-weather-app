---
name: tracker/gh-cli:release-create
description: Create a GitHub release with tag and notes
version: "0.4.0"
---

# Release Create

Create a GitHub release with an associated git tag and release notes.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| tag | string | Yes | Git tag name (e.g., v1.0.0) |
| title | string | No | Release title (default: tag name) |
| notes | string | No | Release notes (markdown) |
| notes_file | string | No | Path to file containing release notes |
| draft | boolean | No | Create as draft release (default: false) |
| prerelease | boolean | No | Mark as prerelease (default: false) |
| target | string | No | Target branch or commit SHA (default: default branch) |

## Implementation

```bash
gh release create {tag} \
  --title "{title}" \
  {notes ? `--notes "${notes}"` : ""} \
  {notes_file ? `--notes-file "${notes_file}"` : ""} \
  {draft ? "--draft" : ""} \
  {prerelease ? "--prerelease" : ""} \
  {target ? `--target ${target}` : ""}
```

## Output

| Field | Type | Description |
|-------|------|-------------|
| url | string | URL of the created release |
| tag | string | Git tag name |

## Errors

| Code | Cause | Recovery |
|------|-------|----------|
| TAG_EXISTS | Tag already exists | Use a different tag or delete existing |
| AUTH_FAILED | Not authenticated with gh CLI | Run `gh auth login` |
| INVALID_TARGET | Target branch or SHA does not exist | Verify target |

## Used By

- deploy-release (create GitHub releases)
