---
name: wa:validate-security
version: "0.7.4"
description: "Security review: vulnerability scan, secret detection, dependency audit."
disable-model-invocation: false
---

# Validate Security

Security review for: $ARGUMENTS

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

## Task Registration

| Stage | Subject            | Active Form      | Statusline      |
| ----- | ------------------ | ---------------- | --------------- |
| 1     | Stage 1: Calibrate | Calibrating scan | Calibrate (1/4) |
| 2     | Stage 2: Secrets   | Scanning secrets | Secrets (2/4)   |
| 3     | Stage 3: Vulns     | Scanning vulns   | Vulns (3/4)     |
| 4     | Stage 4: Report    | Writing report   | Report (4/4)    |

### Statusline Stage Updates

At the **start** of each stage, update the statusline:

```bash
bash $ECK_HOME/update-stage.sh "{Statusline text from table}"
```

At **skill completion** (success or error), reset:

```bash
bash $ECK_HOME/update-stage.sh
```

## Usage

```
/validate-security
/validate-security --rigor lite
/validate-security --rigor standard
/validate-security --rigor strict
```

---

## Stage 1: Calibrate

### Inputs

- `$ARGUMENTS` — optional `--rigor` flag
- `mode:read-dev-rigor` primitive — resolves the current development mode
- Changed files on the current branch (for standard mode conditional check)

### Activities

1. Resolve development mode using the `mode:read-dev-rigor` primitive.

2. Apply mode calibration to determine whether this skill runs at all:
   - **Lite**: Skip the entire skill. Exit with: "Security scan skipped in lite mode."
   - **Standard**: Run only if security-sensitive files have changed. Security-sensitive files include: auth modules, API route handlers, middleware, config files, `.env*`, files containing "password", "token", "secret", or "key" in their path.
   - **Strict**: Always run the full scan.

3. Display mode banner:
   ```
   --- {Mode Name} Mode (Level {N}: {Label}) ---
   Scan: {skipped|conditional|always}
   Tip: Use --rigor lite|standard|strict to override
   ---------------------------------------------
   ```

### Outputs

- Resolved development mode (lite / standard / strict)
- Go/no-go decision for the security scan

### Exit Criteria

- Development mode resolved and banner displayed
- Scan decision made (skip entirely in lite, conditional in standard, always in strict)

---

## Stage 2: Secrets

### Inputs

- `validation:secret-check` primitive
- Code and config files in the project

### Activities

1. **MUST** run the `validation:secret-check` primitive.

2. Scan code and config files for hard-coded secrets, including:
   - API keys and access tokens
   - Passwords and passphrases
   - Connection strings (database, Redis, message queue)
   - Private keys and certificates
   - OAuth client secrets

3. Flag all findings as CRITICAL. A secret in version control is always a CRITICAL finding regardless of mode.

4. For each finding, record:
   - File path and line number
   - Type of secret detected (do not log the secret value itself)
   - Recommended remediation (move to environment variable, use a secrets manager)

### Outputs

- List of secret findings, each with file path, line number, secret type, and remediation
- All findings classified as CRITICAL severity

### Exit Criteria

- Secret scan complete across all code and config files
- All detected secrets recorded with type and remediation (without logging secret values)

---

## Stage 3: Vulns

### Inputs

- Built-in `/security-review` command (Claude Code ships this by default)
- Dependency manifests: `package.json` / `package-lock.json` (Node.js) or `requirements.txt` / `Pipfile` (Python)

### Activities

1. **MUST** run the built-in `/security-review` command for AI-powered security review of the PR diff. This is the primary vulnerability analysis — it reviews branch changes for:
   - Injection attacks (SQL, command, XXE, template, NoSQL, path traversal)
   - Authentication and authorization bypass
   - Crypto and secrets management issues
   - Remote code execution (deserialization, eval injection, XSS)
   - Data exposure (sensitive data logging, PII handling, API leakage)

   The built-in command focuses on HIGH-CONFIDENCE findings (>80% exploitability) and filters false positives. It explicitly excludes DoS, secrets-on-disk (handled by Stage 2), and dependency vulnerabilities (handled below).

2. Run dependency audit (complements the built-in command which excludes library vulns):
   - Node.js projects: `npm audit --json`
   - Python projects: `pip-audit` or `safety check`

3. All findings carry one of three severity levels:
   - **CRITICAL**: Exploitable vulnerability or confirmed secret
   - **WARNING**: Potential vulnerability requiring investigation
   - **INFO**: Hardening opportunity or best-practice deviation

### Outputs

- Vulnerability findings from `/security-review` (AI code review), each with severity level
- Dependency audit results with CVE identifiers and fix versions

### Exit Criteria

- Built-in `/security-review` completed
- Dependency audit completed (or tools unavailable — log warning and skip)
- All findings classified by severity (CRITICAL / WARNING / INFO)

---

## Stage 4: Report

### Inputs

- Secret findings from Stage 2
- Vulnerability and dependency audit findings from Stage 3

### Activities

1. Aggregate all findings from Phases 2 and 3.

2. Produce a security report with the following sections:
   - **Summary**: total CRITICAL / WARNING / INFO counts
   - **Findings by severity**: file path, line number, issue type, and remediation guidance
   - **Dependency audit results**: vulnerable packages with CVE (Common Vulnerabilities and Exposures) identifiers and fix versions
   - **Deploy recommendation**: if any CRITICAL finding exists, output "DEPLOY BLOCK RECOMMENDED -- resolve all CRITICAL findings before deploying"

3. Output format:

   ```
   Security Review: {N} CRITICAL, {N} WARNING, {N} INFO

   CRITICAL
   --------
   [file:line] [issue type]
   Remediation: ...

   WARNING
   -------
   ...

   Dependency Audit
   ----------------
   ...

   Verdict: CLEAR / DEPLOY BLOCK RECOMMENDED
   ```

### Outputs

- Security report displayed to the user (summary, findings by severity, dependency audit, verdict)
- Deploy recommendation (CLEAR or DEPLOY BLOCK RECOMMENDED)

### Exit Criteria

- All findings from Phases 2 and 3 aggregated and displayed
- Deploy recommendation issued based on presence of CRITICAL findings

---

## Error Handling

- Security findings are advisory. The skill reports them but does not automatically block deploys.
- Any CRITICAL finding generates a deploy-block recommendation that the user must act on.
- If dependency audit tools (`npm audit`, `pip-audit`) are not available, log a warning and skip that check rather than failing the entire scan.
- At completion (success or error), reset the statusline:
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
