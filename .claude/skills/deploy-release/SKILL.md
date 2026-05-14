---
name: wa:deploy-release
version: "0.7.4"
description: "Create release: git tag, changelog generation, and release notes."
disable-model-invocation: false
---

# Deploy Release

Create release for: $ARGUMENTS

---

## Visual Framework

Follow the visual framework defined in the `output:visual-framework` primitive.

---

## Task Registration

| Stage | Subject            | Active Form         | Statusline      |
| ----- | ------------------ | ------------------- | --------------- |
| 1     | Stage 1: Version   | Determining version | Version (1/4)   |
| 2     | Stage 2: Changelog | Writing changelog   | Changelog (2/4) |
| 3     | Stage 3: Tag       | Creating tag        | Tag (3/4)       |
| 4     | Stage 4: Publish   | Publishing release  | Publish (4/4)   |

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
/wa:deploy-release 1.3.0
/wa:deploy-release --minor
/wa:deploy-release --patch
/wa:deploy-release --major
```

Arguments: explicit version string (e.g., `1.3.0`) or a semver bump flag. If omitted, the version is suggested from commit analysis.

---

## Stage 1: Version

### Inputs

- $ARGUMENTS for optional version string or bump flag (`--major`, `--minor`, `--patch`)
- Last release tag via `git describe --tags --abbrev=0`
- Commit history since last tag via `git:log`

### Activities

1. Check whether a version was provided in $ARGUMENTS:
   - Explicit version string (e.g., `1.3.0`) → validate it is a valid semver value and use it.
   - Bump flag (`--major`, `--minor`, `--patch`) → calculate from the last tag.
   - No argument → proceed to auto-suggest.

2. Find the last release tag:

   ```bash
   git describe --tags --abbrev=0
   ```

3. If no version was provided, analyze commits since the last tag using `git:log` to suggest a semver bump:
   - Any `feat` commit → minor bump.
   - Any `BREAKING CHANGE` in commit footer → major bump.
   - All other types → patch bump.
   - Display the suggested version and the reasoning, then **wait for user confirmation** before proceeding.

4. Confirm the final version with the user. Never proceed without confirmation.

### Outputs

- Confirmed version string (valid semver)
- Last release tag for changelog range

### Exit Criteria

- Version is confirmed by user
- Version is valid semver

---

## Stage 2: Changelog

### Inputs

- Confirmed version from Stage 1
- Last release tag from Stage 1
- Commit history since last tag
- `technical-writer` agent for release notes prose
- `docs:doc-update` primitive for CHANGELOG.md

### Activities

1. Collect all commits since the last release tag using `git:log`:

   ```bash
   git log {last-tag}..HEAD --pretty=format:"%h %s" --no-merges
   ```

2. Group commits by conventional commit type:
   - `feat` → Features
   - `fix` → Bug Fixes
   - `refactor` → Refactors
   - `perf` → Performance
   - `docs` → Documentation
   - `test` → Tests
   - `chore` / `ci` / `build` → Maintenance

3. **MUST** dispatch a `technical-writer` agent to compose release notes prose from the grouped commit list. Do NOT skip agent dispatch and write release notes inline. The agent should produce:
   - A short paragraph summarizing the release theme.
   - Bulleted entries for each changelog group that has at least one entry.

4. Prepend the new release entry to `CHANGELOG.md` using `docs:doc-update`. Use this header format:
   ```markdown
   ## [{version}] — {YYYY-MM-DD}
   ```

### Outputs

- CHANGELOG.md updated with new release entry
- Release notes prose for GitHub release

### Exit Criteria

- CHANGELOG.md contains the new version entry
- Release notes prose is ready for Stage 4

---

## Stage 3: Tag

### Inputs

- Confirmed version from Stage 1
- `git:tag` primitive

### Activities

1. **MUST** verify the version does not already exist as a tag:

   ```bash
   git tag -l "{version}"
   ```

   If the tag exists → stop immediately and report an error. Never overwrite an existing tag.

2. Create an annotated tag using `git:tag` primitive:

   ```bash
   git tag -a "{version}" -m "Release {version} — {YYYY-MM-DD}"
   ```

3. Confirm the tag was created:
   ```bash
   git show {version} --stat
   ```

### Outputs

- Annotated git tag created locally

### Exit Criteria

- Tag exists in local repository
- Tag points to correct commit

---

## Stage 4: Publish

### Inputs

- Tag from Stage 3
- Release notes prose from Stage 2
- Remote origin URL

### Activities

1. Push the tag to the remote:

   ```bash
   git push origin {version}
   ```

2. If the repository is hosted on GitHub, create a GitHub release:
   - Title: `{version}`
   - Body: release notes prose from Stage 2
   - Tag: `{version}`
   - Mark as latest release

3. Display the release summary:
   ```
   Released: {version}
   Tag:      {version}
   Date:     {YYYY-MM-DD}
   URL:      {release-url or "N/A"}
   Entries:  {N} changelog items
   ```

### Outputs

- Tag pushed to remote
- GitHub release created (if applicable)

### Exit Criteria

- Tag is visible on remote
- Release summary displayed with URL

---

## Error Handling

- **Tag already exists**: Stop immediately. Report the existing tag SHA. Suggest a different version number — never overwrite tags.
- **No commits since last tag**: Report that there is nothing to release. Allow the user to override and release anyway if needed.
- **Changelog write failure**: Report the error but continue — the tag and GitHub release are more critical than the CHANGELOG.md write.
- **GitHub release creation failure**: Report the API error. The tag was already pushed; the user can create the GitHub release manually.
- **On error**: Reset the statusline before exiting.
  ```bash
  bash $ECK_HOME/update-stage.sh
  ```
