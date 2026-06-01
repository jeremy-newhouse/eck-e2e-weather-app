#!/usr/bin/env python3
"""
Standards Compilation Script

Compiles standards from evolv-coder-standards into domain-specific context files
for agent consumption. Supports dynamic pulling from the standards repository
using gh CLI for authenticated access.

The set of files that compose each domain document is read from the standards
repo's manifest.yaml (the canonical source of truth — see the "Compile Groups"
table in evolv-coder-standards/CLAUDE.md), not hardcoded here. This script only
decides WHICH compile groups belong in the embedded standards set (EMBEDDED_GROUPS)
and supplies their human-readable titles/descriptions; the manifest decides which
source files and version each group carries. This keeps the embedded content in
lockstep with the standards repo as it grows.

Usage:
    python3 "$CLAUDE_PROJECT_DIR/.claude/scripts/compile-standards.py"
    python3 "$CLAUDE_PROJECT_DIR/.claude/scripts/compile-standards.py" --check-only
    python3 "$CLAUDE_PROJECT_DIR/.claude/scripts/compile-standards.py" --source /path/to/standards

Environment Variables:
    STANDARDS_SOURCE_DIR: Override default standards source path
    STANDARDS_REPO_URL: GitHub repo URL (default: https://github.com/evolvconsulting/evolv-coder-standards)
    STANDARDS_REPO_BRANCH: Branch to pull from (default: main)
"""

import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import TypedDict


class DomainSpec(TypedDict):
    manifest_domain: str
    version: str
    compile_group: str
    files: list[str]


# Constants
DEFAULT_REPO_URL = "https://github.com/evolvconsulting/evolv-coder-standards"
DEFAULT_REPO_BRANCH = "main"
CACHE_DIR = Path.home() / ".claude" / "evolv-coder-standards"

# Output: the managed project's .claude/context/standards.
# Prefer CLAUDE_PROJECT_DIR (the project root Claude Code exports to hooks and
# skills) so compiled standards always land in the project the agent reads from,
# even if this script is ever invoked via the global runtime copy. Fall back to
# the script's own location (.claude/scripts/ -> .claude/context/standards/)
# when the env var is absent (e.g. direct CLI use from a project checkout).
_project_dir = os.environ.get("CLAUDE_PROJECT_DIR")
if _project_dir:
    OUTPUT_DIR = Path(_project_dir) / ".claude" / "context" / "standards"
else:
    OUTPUT_DIR = Path(__file__).parent.parent / "context" / "standards"

# Which compile groups make up the embedded standards set, in output order.
# Each name must match a `compile_group` value in the standards manifest's
# `domains:` section. Patterns, evaluation, and the *-overview stub groups are
# intentionally excluded — the embedded set is standards + per-language standards
# only. To embed a newly-authored standards domain, add its compile group here.
EMBEDDED_GROUPS: list[str] = [
    "core-standards",
    "frontend-standards",
    "backend-standards",
    "database-standards",
    "devops-standards",
    "documentation-standards",
    "ai-standards",
    "cpp-standards",
    "csharp-standards",
    "dart-standards",
    "go-standards",
    "java-standards",
    "kotlin-standards",
    "php-standards",
    "ruby-standards",
    "rust-standards",
    "swift-standards",
    "typescript-standards",
]

# Human-readable one-line summaries, written into each compiled doc's header.
# The manifest carries no descriptions, so they live here. Keep them in sync
# with the breadth of each domain as the manifest grows.
GROUP_DESCRIPTIONS: dict[str, str] = {
    "core-standards": "Core standards applied by all agents: reference architecture, security, authentication, data flow, caching, observability, API versioning, threat modeling, ADR format",
    "frontend-standards": "Frontend development standards: React, TypeScript, components, server actions, forms, accessibility, API client, i18n, observability",
    "backend-standards": "Backend development standards: Python, FastAPI, error handling, testing, idempotency, rate limiting, background jobs, realtime, resilience, API patterns",
    "database-standards": "Database standards: PostgreSQL, Neo4j, TimescaleDB, naming, schema design, migrations, multi-tenancy, performance",
    "devops-standards": "DevOps standards: Git workflow, CI/CD, environments, monitoring, Docker, IaC, ECS/Fargate, AWS OIDC, supply-chain security, twelve-factor",
    "documentation-standards": "Documentation standards: specifications, architecture definition, BRD/PRD, agentic coding, discovery, glossary, changelog, API reference",
    "ai-standards": "AI/LLM engineering standards: prompt management, model selection, LLM observability, RAG, prompt injection, output handling, agent guardrails, provider integration, tool calling",
    "cpp-standards": "C++ development standards",
    "csharp-standards": "C# development standards",
    "dart-standards": "Dart development standards",
    "go-standards": "Go development standards",
    "java-standards": "Java development standards",
    "kotlin-standards": "Kotlin development standards",
    "php-standards": "PHP development standards",
    "ruby-standards": "Ruby development standards",
    "rust-standards": "Rust development standards",
    "swift-standards": "Swift development standards",
    "typescript-standards": "TypeScript backend development standards",
}

# Title overrides where the default `.title()` casing reads poorly (acronyms,
# camelCase product names). Everything else uses the default Title Case.
TITLE_OVERRIDES: dict[str, str] = {
    "ai-standards": "AI Standards",
    "typescript-standards": "TypeScript Standards",
    "cpp-standards": "C++ Standards",
    "csharp-standards": "C# Standards",
    "php-standards": "PHP Standards",
}


def parse_front_matter(content: str) -> tuple[dict[str, str], str]:
    """Parse YAML front matter from markdown content.

    Returns (metadata_dict, body_content).
    """
    metadata: dict[str, str] = {}
    body = content

    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            fm_text = parts[1].strip()
            body = parts[2].strip()
            for line in fm_text.split("\n"):
                line = line.strip()
                if ":" in line and not line.startswith("#"):
                    key, _, value = line.partition(":")
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    if value and not value.startswith("[") and not value.startswith("-"):
                        metadata[key] = value

    return metadata, body


def resolve_standards_source(source_override: str | None = None) -> Path | None:
    """Resolve the standards source directory.

    Resolution chain:
    1. --source CLI argument
    2. STANDARDS_SOURCE_DIR env var
    3. Clone from repo using gh CLI
    4. Cached copy at ~/.claude/evolv-coder-standards/
    """
    # 1. CLI argument
    if source_override:
        source_path = Path(source_override)
        if source_path.exists():
            print(f"Using source from CLI argument: {source_path}")
            return source_path
        print(f"WARNING: Specified source not found: {source_path}")

    # 2. Environment variable
    env_source = os.environ.get("STANDARDS_SOURCE_DIR")
    if env_source:
        source_path = Path(env_source)
        if source_path.exists():
            print(f"Using source from STANDARDS_SOURCE_DIR: {source_path}")
            return source_path
        print(f"WARNING: STANDARDS_SOURCE_DIR not found: {source_path}")

    # 3. Clone from repo
    repo_url = os.environ.get("STANDARDS_REPO_URL", DEFAULT_REPO_URL)
    repo_branch = os.environ.get("STANDARDS_REPO_BRANCH", DEFAULT_REPO_BRANCH)

    cloned = clone_standards_repo(repo_url, repo_branch)
    if cloned:
        return cloned

    # 4. Cached copy
    if CACHE_DIR.exists() and (CACHE_DIR / "manifest.yaml").exists():
        print("Using cached standards from: " + str(CACHE_DIR))
        return CACHE_DIR

    return None


def clone_standards_repo(repo_url: str, branch: str) -> Path | None:
    """Clone the standards repo using gh CLI.

    Returns the path to the cloned repo, or None if cloning failed.
    """
    # Check gh CLI is available and authenticated
    try:
        subprocess.run(
            ["gh", "auth", "status"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("WARNING: gh CLI not available or not authenticated. Skipping repo clone.")
        return None

    # Clone to temp directory
    tmp_dir = Path(tempfile.mkdtemp(prefix="claude-standards-"))
    repo_name = repo_url.rstrip("/").split("/")[-1]

    try:
        print(f"Cloning standards from {repo_url} (branch: {branch})...")
        subprocess.run(
            [
                "gh", "repo", "clone", repo_url,
                str(tmp_dir / repo_name),
                "--", "--depth", "1", "--branch", branch,
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        clone_path = tmp_dir / repo_name
        print(f"Successfully cloned to: {clone_path}")

        # Update cache
        if CACHE_DIR.exists():
            shutil.rmtree(CACHE_DIR)
        shutil.copytree(clone_path, CACHE_DIR)
        print("Updated cache at: " + str(CACHE_DIR))

        return clone_path

    except subprocess.CalledProcessError as e:
        print(f"WARNING: Failed to clone standards repo: {e.stderr}")
        # Clean up temp dir
        shutil.rmtree(tmp_dir, ignore_errors=True)
        return None


def read_file_content(filepath: Path) -> str:
    """Read file content, return empty string if not found."""
    try:
        return filepath.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(f"  WARNING: File not found: {filepath}")
        return ""


def strip_front_matter(content: str) -> str:
    """Remove YAML front matter from content, keeping the body."""
    _, body = parse_front_matter(content)
    return body


def parse_manifest_domains(source_dir: Path) -> dict[str, DomainSpec]:
    """Parse the `domains:` section of manifest.yaml.

    Returns a dict keyed by compile_group, each carrying the manifest domain
    name, version, and ordered file list. Only the top-level `domains:` block
    is read; patterns/evaluation/templates/etc. are intentionally excluded from
    the embedded standards set.
    """
    manifest_path = source_dir / "manifest.yaml"
    specs: dict[str, DomainSpec] = {}

    if not manifest_path.exists():
        return specs

    content = manifest_path.read_text(encoding="utf-8")

    in_domains = False
    in_files = False
    cur_name = ""
    cur: dict[str, object] | None = None

    def flush(name: str, data: dict[str, object] | None) -> None:
        if not name or data is None:
            return
        compile_group = data.get("compile_group")
        if isinstance(compile_group, str) and compile_group:
            specs[compile_group] = {
                "manifest_domain": name,
                "version": str(data.get("version", "unknown")),
                "compile_group": compile_group,
                "files": list(data.get("files", [])),  # type: ignore[call-overload]
            }

    for raw in content.split("\n"):
        stripped = raw.strip()

        if not in_domains:
            if stripped == "domains:":
                in_domains = True
            continue

        # A non-indented, non-empty line is the next top-level key: domains end.
        if raw and not raw.startswith(" "):
            flush(cur_name, cur)
            cur_name, cur, in_files = "", None, False
            in_domains = False
            continue

        if not stripped:
            continue

        # Domain header: exactly two-space indent, e.g. "  frontend:"
        if raw.startswith("  ") and not raw.startswith("    ") and stripped.endswith(":"):
            flush(cur_name, cur)
            cur_name = stripped[:-1].strip()
            cur = {"files": []}
            in_files = False
            continue

        # Domain attributes: four-space indent.
        if cur is not None and raw.startswith("    ") and not raw.startswith("      "):
            if stripped.startswith("version:"):
                cur["version"] = stripped.split(":", 1)[1].strip().strip('"').strip("'")
                in_files = False
            elif stripped.startswith("compile_group:"):
                cur["compile_group"] = stripped.split(":", 1)[1].strip().strip('"').strip("'")
                in_files = False
            elif stripped == "files:":
                in_files = True
            else:
                in_files = False
            continue

        # File entries: six-space indent under "files:".
        if cur is not None and in_files and raw.startswith("      ") and stripped.startswith("- "):
            files_list = cur["files"]
            assert isinstance(files_list, list)
            files_list.append(stripped[2:].strip())
            continue

    flush(cur_name, cur)
    return specs


def compile_domain(
    compile_group: str,
    files: list[str],
    description: str,
    version: str,
    title: str,
    source_dir: Path,
) -> str:
    """Compile all files for a domain into a single markdown document."""
    lines: list[str] = []
    compiled_at = datetime.now().strftime("%Y-%m-%d %H:%M")

    # Determine source repo info
    source_label = "evolv-coder-standards"

    # Header
    lines.append(f"# {title}")
    lines.append("")
    lines.append(f"> {description}")
    lines.append("")
    lines.append(f"**Compiled**: {compiled_at}")
    lines.append(f"**Source**: {source_label}")
    lines.append(f"**Domain Version**: {version}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Table of contents
    lines.append("## Contents")
    lines.append("")
    for file_path in files:
        name = Path(file_path).stem.replace("-", " ").title()
        anchor = Path(file_path).stem.lower().replace(" ", "-")
        lines.append(f"- [{name}](#{anchor})")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Compile each file
    files_found = 0
    for file_path in files:
        full_path = source_dir / file_path
        content = read_file_content(full_path)

        if content:
            files_found += 1
            # Strip front matter from source files
            body = strip_front_matter(content)

            # Get version from front matter if available
            metadata, _ = parse_front_matter(content)
            file_version = metadata.get("version", "")
            version_note = f" (v{file_version})" if file_version else ""

            lines.append(f"<!-- Source: {file_path}{version_note} -->")
            lines.append("")
            lines.append(body)
            lines.append("")
            lines.append("---")
            lines.append("")

    # Add compilation metadata footer
    lines.append("<!-- Compilation Metadata")
    lines.append(f"  domain: {compile_group}")
    lines.append(f"  domain_version: {version}")
    lines.append(f"  compiled_at: {compiled_at}")
    lines.append(f"  source: {source_label}")
    lines.append(f"  files_compiled: {files_found}/{len(files)}")
    lines.append("-->")

    return "\n".join(lines)


def check_freshness(source_dir: Path, specs: dict[str, DomainSpec]) -> None:
    """Check if compiled standards are up to date with source."""
    print("Standards Freshness Check")
    print("=" * 50)
    print("")

    any_stale = False
    for compile_group in EMBEDDED_GROUPS:
        spec = specs.get(compile_group)
        source_version = spec["version"] if spec else "unknown"
        output_file = OUTPUT_DIR / f"{compile_group}.md"

        if spec is None:
            print(f"  {compile_group}: NOT IN MANIFEST")
            any_stale = True
            continue

        if not output_file.exists():
            print(f"  {compile_group}: MISSING (source: v{source_version})")
            any_stale = True
            continue

        # Read compiled file for version info
        content = output_file.read_text(encoding="utf-8")
        compiled_version = "unknown"
        for line in content.split("\n"):
            if "domain_version:" in line:
                compiled_version = line.split(":", 1)[1].strip()
                break

        if compiled_version != source_version:
            print(f"  {compile_group}: STALE (compiled: v{compiled_version}, source: v{source_version})")
            any_stale = True
        else:
            print(f"  {compile_group}: OK (v{source_version})")

    print("")
    if any_stale:
        print("Run compile-standards.py to update stale files.")
    else:
        print("All compiled standards are up to date.")


def main() -> None:
    """Main entry point."""
    # Parse CLI arguments
    check_only = "--check-only" in sys.argv
    source_override = None

    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == "--source" and i + 1 < len(sys.argv):
            source_override = sys.argv[i + 1]

    # Resolve source
    source_dir = resolve_standards_source(source_override)

    if source_dir is None:
        print("ERROR: No standards source found.")
        print("")
        print("Resolution chain attempted:")
        print("  1. --source CLI argument")
        print("  2. STANDARDS_SOURCE_DIR environment variable")
        print("  3. gh repo clone (requires gh CLI + auth)")
        print("  4. Cached copy at ~/.claude/evolv-coder-standards/")
        print("")
        print("Options:")
        print("  - Install gh CLI and authenticate: gh auth login")
        print("  - Set STANDARDS_SOURCE_DIR to a local clone")
        print("  - Run: gh repo clone evolvconsulting/evolv-coder-standards ~/.claude/evolv-coder-standards")
        return

    # Read domain specs (files + versions) from the manifest
    specs = parse_manifest_domains(source_dir)

    # Check-only mode
    if check_only:
        check_freshness(source_dir, specs)
        return

    if not specs:
        print(f"ERROR: No domains parsed from manifest at: {source_dir / 'manifest.yaml'}")
        sys.exit(1)

    # Compile
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Compiling standards from: {source_dir}")
    # Concatenate (not an f-string) so the scaffold syntax-migration classifier
    # does not read the all-caps OUTPUT_DIR brace token as a template placeholder.
    print("Output directory: " + str(OUTPUT_DIR))
    print("")

    compiled = 0
    missing: list[str] = []
    for compile_group in EMBEDDED_GROUPS:
        spec = specs.get(compile_group)
        if spec is None:
            missing.append(compile_group)
            print(f"  WARNING: compile group not found in manifest: {compile_group}")
            continue

        description = GROUP_DESCRIPTIONS.get(
            compile_group, f"{compile_group.replace('-', ' ')} from evolv-coder-standards"
        )
        title = TITLE_OVERRIDES.get(compile_group, compile_group.replace("-", " ").title())
        content = compile_domain(
            compile_group, spec["files"], description, spec["version"], title, source_dir
        )

        output_file = OUTPUT_DIR / f"{compile_group}.md"
        output_file.write_text(content, encoding="utf-8")

        size_kb = len(content.encode("utf-8")) / 1024
        print(f"  -> {output_file.name} ({size_kb:.1f} KB, v{spec['version']}, {len(spec['files'])} files)")
        compiled += 1

    print("")
    print(f"Standards compilation complete. {compiled} domain files generated.")
    if missing:
        print(
            f"ERROR: {len(missing)} embedded group(s) missing from manifest: "
            f"{', '.join(missing)}. The manifest may have been reindented, "
            f"commented, or renamed; refusing to emit an incomplete standards set."
        )
        sys.exit(1)

    # Clean up temp clone directory if it was used
    # (cache was already updated in clone_standards_repo)


if __name__ == "__main__":
    main()
