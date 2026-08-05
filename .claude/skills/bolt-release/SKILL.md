---
name: bolt-release
description: "Orchestrate Bolt Framework releases following SemVer (MAJOR.MINOR.PATCH + pre-release / RC), with quality gates, changelog generation, tag / GitHub Release / artifact creation, and deployment handoff. Triggers: 'create release', 'tag release', 'changelog', 'SemVer bump', 'GitHub Release', 'pre-release', 'TRANSITION phase', '/bolt-release'."
---

# Bolt Release — Methodology

Orchestrate release process with proper versioning, changelog, and
artifacts.

**Bolt Framework Stage**: TRANSITION
**Responsible Agent**: Release Manager

## Available scripts

- Bash: `scripts/bash/create-release.sh`
- PowerShell: `scripts/powershell/Create-Release.ps1`

## Semantic versioning

```text
SEMVER: MAJOR.MINOR.PATCH

MAJOR  → Breaking changes (incompatible API)
MINOR  → New features (backward compatible)
PATCH  → Bug fixes (backward compatible)
```

## Release types

| Type | Version bump | Trigger | Example |
|------|--------------|---------|---------|
| **Major** | X.0.0 | Breaking changes | Remove API endpoint |
| **Minor** | x.Y.0 | New features | Add new endpoint |
| **Patch** | x.y.Z | Bug fixes | Fix validation |
| **Pre-release** | x.y.z-alpha.N | Testing | `1.0.0-alpha.1` |
| **RC** | x.y.z-rc.N | Release candidate | `1.0.0-rc.1` |

## Pre-release checklist

### Quality gates

```bash
# All tests pass
npm test
# or: dotnet test

# Coverage meets threshold
npm run test:coverage

# No linting errors
npm run lint

# No security vulnerabilities
npm audit
# or: dotnet list package --vulnerable

# Build succeeds
npm run build
# or: dotnet build -c Release
```

### Documentation check

- [ ] `README.md` updated.
- [ ] API documentation current.
- [ ] `CHANGELOG.md` prepared.
- [ ] Migration guide (if breaking changes).

### Dependency review

```bash
# Check outdated
npm outdated
# or: dotnet list package --outdated

# Update lock file
npm ci
# or: dotnet restore
```

## Release process

### Step 1: Determine version (from commits)

| Commit type | Version impact |
|-------------|----------------|
| `feat!:` or `BREAKING CHANGE:` | MAJOR |
| `feat:` | MINOR |
| `fix:` | PATCH |
| `docs:`, `style:`, `refactor:` | PATCH (optional) |

### Step 2: Generate changelog

```markdown
# Changelog

## [x.y.z] - YYYY-MM-DD

### Added
- New feature A (#123)
- New feature B (#124)

### Changed
- Updated behavior X (#125)

### Fixed
- Bug fix Y (#126)
- Bug fix Z (#127)

### Deprecated
- Feature W (will be removed in vX+1)
```

### Step 3: Tag + push

```bash
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

### Step 4: Create GitHub Release

Use `gh release create v1.2.3 --notes-file CHANGELOG.md --title "v1.2.3"`
attaching build artifacts (binaries, docker images URIs, OpenAPI bundle).

### Step 5: Handoff

→ `bolt-ops` to deploy the released version to staging / production.

## Quality gates (per release)

- All tests pass on the tagged commit.
- Coverage ≥ constitution threshold.
- No HIGH / CRITICAL CVE in deps.
- Changelog reflects all merged PRs since previous tag.
- Tag pushed and GitHub Release published.

## Related agents (next steps)

- → `bolt-analyze`: pre-release consistency analysis.
- → `bolt-testing`: verify all tests pass before release.
- → `bolt-status`: review overall project status.
- → `bolt-ops`: deploy the release.
