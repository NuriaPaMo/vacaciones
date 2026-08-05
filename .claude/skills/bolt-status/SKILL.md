---
name: bolt-status
description: "Generate comprehensive project status reports across all Bolt Framework lifecycle phases. Analyzes artifacts, code metrics, git history, monitoring data to produce executive summary + phase-by-phase status. Triggers: 'project status', 'status report', 'phase progress', 'health check', 'velocity report', 'overall progress', '/bolt-status'."
---

# Bolt Status — Methodology

Generate comprehensive project status reports across all Bolt lifecycle
phases.

**Bolt Framework Stage**: CROSS-PHASE (Status reporting)
**Responsible Agent**: Project Status Reporter

## Available scripts

- Bash: `scripts/bash/project-status.sh`
- PowerShell: `scripts/powershell/Get-ProjectStatus.ps1`

## Status dimensions

| Dimension | Metrics | Source |
|-----------|---------|--------|
| **Phase Progress** | % complete per phase | Artifacts analysis |
| **Quality** | Coverage, debt, issues | Code analysis |
| **Velocity** | Stories/sprint, cycle time | Git history |
| **Health** | Uptime, performance | Monitoring |
| **Risk** | Blockers, dependencies | Issue tracker |

## Analysis process

### 1. Artifact analysis

```yaml
artifacts:
  inception:
    constitution: .boltf/memory/constitution.md
    status: [exists|missing|outdated]
  discovery:
    features: specs/*/requirements/requirements.md
    count: [N]
    complete: [N]
  construction:
    implementations: src/**/*
    test_coverage: [X]%
  transition:
    releases: CHANGELOG.md
    documentation: docs/*
  production:
    deployments: [count]
    incidents: [count]
```

### 2. Code analysis

```bash
# Code statistics
cloc src/ --json

# Test coverage
npm run test:coverage --json

# Complexity metrics
npx code-complexity src/ --format json

# Dependency status
npm outdated --json
```

### 3. Git analysis

```bash
# Recent activity
git log --oneline --since="2 weeks ago" | wc -l

# Contributors
git shortlog -sn --since="1 month ago"

# Branch status
git branch -a --list "feature/*"
```

## Report structure

### Executive summary

```markdown
## Executive Summary

| Metric | Value | Trend | Status |
|--------|-------|-------|--------|
| Overall Health | [X] % | ↑/↓/→ | 🟢/🟡/🔴 |
| Sprint Progress | [X] % | ↑/↓/→ | 🟢/🟡/🔴 |
| Quality Score | [X] % | ↑/↓/→ | 🟢/🟡/🔴 |
| Risk Level | LOW/MED/HIGH | ↑/↓/→ | 🟢/🟡/🔴 |
```

### Phase status

```markdown
## Phase Status

### INCEPTION ✅
| Artifact | Status | Notes |
|----------|--------|-------|
| Constitution | ✅ Complete | Last updated [date] |
| Tech Stack | ✅ Defined | [stack summary] |
| Standards | ✅ Documented | [X] rules |

### DISCOVERY 🔄
| Feature | Requirements | Gherkin | Plan | Status |
|---------|--------------|---------|------|--------|
| [F-001] | ✅ | ✅ | ✅ | Complete |
| [F-002] | ✅ | 🔄 | ⬜ | In Progress |
| [F-003] | ⬜ | ⬜ | ⬜ | Not Started |

**Progress**: 1/3 features ready (33 %)

### CONSTRUCTION 🔄
| Feature | Implemented | Tested | Reviewed | Status |
|---------|-------------|--------|----------|--------|

### TRANSITION ⏳
| Release | Version | Date | Status |
|---------|---------|------|--------|

### PRODUCTION ⏳
| Metric | Value |
|--------|-------|
| Uptime (30d) | [%] |
| Deployments (30d) | [N] |
| Incidents (SEV-1/2) | [N] |
```

### Risk register

```markdown
## Risks
| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R-001 | ... | H/M/L | H/M/L | ... |
```

## Quality gates

- Report covers all 6 phases.
- All metrics reference their source.
- Recent git activity reflected.
- Risk register up to date.

## Related agents (next steps)

- → `bolt-analyze`: detailed consistency analysis.
- → `bolt-improve`: improvement opportunities.
- → `bolt-alignment`: business-technical alignment check.
- → `bolt-ops`: operational health status.
