<#
.SYNOPSIS
    Creates a release/deployment unit documentation for Bolt Framework projects.

.DESCRIPTION
    This script generates deployment unit documentation, updates CHANGELOG,
    and prepares release artifacts following the AI-DLC methodology.

.PARAMETER Version
    The version number for the release (e.g., "1.0.0").

.PARAMETER ReleaseType
    The type of release: major, minor, or patch.

.PARAMETER DryRun
    If specified, shows what would be done without making changes.

.EXAMPLE
    .\Create-Release.ps1 -Version "1.0.0"
    .\Create-Release.ps1 -ReleaseType "minor"
    .\Create-Release.ps1 -Version "1.0.0" -DryRun

.NOTES
    Part of Bolt Framework / AI-DLC methodology
    Phase: Block 5 - Release
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [ValidateSet("major", "minor", "patch")]
    [string]$ReleaseType = "patch",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n📋 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ️  $Message" -ForegroundColor Blue
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "  ❌ $Message" -ForegroundColor Red
}

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

function Get-LastVersion {
    $tags = git tag --list "v*" --sort=-v:refname 2>$null
    if ($tags) {
        $lastTag = ($tags -split "`n")[0]
        return $lastTag -replace "^v", ""
    }
    return "0.0.0"
}

function Get-NextVersion {
    param(
        [string]$CurrentVersion,
        [string]$BumpType
    )

    $parts = $CurrentVersion -split "\."
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($BumpType) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }

    return "$major.$minor.$patch"
}

# ============================================================================
# QUALITY GATES
# ============================================================================

function Test-QualityGates {
    Write-Step "Checking Quality Gates..."

    $results = @{
        UnitTests = @{ Status = "⬜"; Details = "Not checked" }
        Integration = @{ Status = "⬜"; Details = "Not checked" }
        Security = @{ Status = "⬜"; Details = "Not checked" }
        Coverage = @{ Status = "⬜"; Details = "Not checked" }
    }

    # Check for test results
    if (Test-Path "TestResults") {
        $results.UnitTests.Status = "✅"
        $results.UnitTests.Details = "Tests found"
    }

    # Check for security scan results
    if (Test-Path "security-report.*") {
        $results.Security.Status = "✅"
        $results.Security.Details = "Scan completed"
    }

    return $results
}

# ============================================================================
# CHANGELOG GENERATION
# ============================================================================

function Get-CommitsSinceLastRelease {
    $lastTag = git describe --tags --abbrev=0 2>$null
    if ($lastTag) {
        $commits = git log "$lastTag..HEAD" --pretty=format:"%s|%h|%an" 2>$null
    } else {
        $commits = git log --pretty=format:"%s|%h|%an" 2>$null
    }

    $parsed = @{
        Added = @()
        Changed = @()
        Fixed = @()
        Security = @()
        Other = @()
    }

    foreach ($commit in ($commits -split "`n")) {
        if (-not $commit) { continue }

        $parts = $commit -split "\|"
        $message = $parts[0]
        $hash = $parts[1]

        $entry = "- $message ($hash)"

        if ($message -match "^(feat|add|new)") {
            $parsed.Added += $entry
        }
        elseif ($message -match "^(change|update|refactor)") {
            $parsed.Changed += $entry
        }
        elseif ($message -match "^(fix|bug|patch)") {
            $parsed.Fixed += $entry
        }
        elseif ($message -match "^(security|vuln)") {
            $parsed.Security += $entry
        }
        else {
            $parsed.Other += $entry
        }
    }

    return $parsed
}

function Update-Changelog {
    param(
        [string]$Version,
        [hashtable]$Changes
    )

    $date = Get-Date -Format "yyyy-MM-dd"
    $changelogPath = "CHANGELOG.md"

    $newEntry = @"

## [$Version] - $date

"@

    if ($Changes.Added.Count -gt 0) {
        $newEntry += "`n### Added`n"
        $newEntry += ($Changes.Added -join "`n") + "`n"
    }

    if ($Changes.Changed.Count -gt 0) {
        $newEntry += "`n### Changed`n"
        $newEntry += ($Changes.Changed -join "`n") + "`n"
    }

    if ($Changes.Fixed.Count -gt 0) {
        $newEntry += "`n### Fixed`n"
        $newEntry += ($Changes.Fixed -join "`n") + "`n"
    }

    if ($Changes.Security.Count -gt 0) {
        $newEntry += "`n### Security`n"
        $newEntry += ($Changes.Security -join "`n") + "`n"
    }

    if (Test-Path $changelogPath) {
        $content = Get-Content $changelogPath -Raw
        # Insert after the header
        $content = $content -replace "(# Changelog\s*\n)", "`$1$newEntry"
        Set-Content -Path $changelogPath -Value $content
    } else {
        $header = "# Changelog`n`nAll notable changes to this project will be documented in this file.`n"
        Set-Content -Path $changelogPath -Value ($header + $newEntry)
    }

    return $newEntry
}

# ============================================================================
# DEPLOYMENT UNIT GENERATION
# ============================================================================

function New-DeploymentUnit {
    param(
        [string]$Version,
        [hashtable]$QualityGates,
        [hashtable]$Changes
    )

    # Ensure directory exists
    $duDir = "docs/deployment_units"
    if (-not (Test-Path $duDir)) {
        New-Item -ItemType Directory -Path $duDir -Force | Out-Null
    }

    # Get next DU number
    $existingDUs = Get-ChildItem -Path $duDir -Filter "deployment_unit_*.md" -ErrorAction SilentlyContinue
    $nextNum = 1
    if ($existingDUs) {
        $nums = $existingDUs | ForEach-Object {
            if ($_.Name -match "deployment_unit_(\d+)\.md") { [int]$matches[1] }
        }
        if ($nums) { $nextNum = ($nums | Measure-Object -Maximum).Maximum + 1 }
    }

    $duNum = "{0:D3}" -f $nextNum
    $duPath = "$duDir/deployment_unit_$duNum.md"
    $date = Get-Date -Format "yyyy-MM-dd"

    # Determine release type
    $lastVersion = Get-LastVersion
    $releaseType = "Patch"
    if ($lastVersion -ne "0.0.0") {
        $lastParts = $lastVersion -split "\."
        $newParts = $Version -split "\."
        if ($newParts[0] -gt $lastParts[0]) { $releaseType = "Major" }
        elseif ($newParts[1] -gt $lastParts[1]) { $releaseType = "Minor" }
    }

    # Calculate totals
    $featuresCount = $Changes.Added.Count
    $fixesCount = $Changes.Fixed.Count
    $changesCount = $Changes.Changed.Count

    $content = @"
# Deployment Unit: DU-$duNum

## Release Summary

| Property | Value |
|----------|-------|
| Version | $Version |
| Release Date | $date |
| Release Type | $releaseType |
| Previous Version | $lastVersion |
| DU Number | $duNum |

## What's Included

### Features ($featuresCount)
$($Changes.Added -join "`n")

### Bug Fixes ($fixesCount)
$($Changes.Fixed -join "`n")

### Changes ($changesCount)
$($Changes.Changed -join "`n")

## Quality Gates Results

| Gate | Status | Details |
|------|--------|---------|
| Unit Tests | $($QualityGates.UnitTests.Status) | $($QualityGates.UnitTests.Details) |
| Integration Tests | $($QualityGates.Integration.Status) | $($QualityGates.Integration.Details) |
| Security Scan | $($QualityGates.Security.Status) | $($QualityGates.Security.Details) |
| Code Coverage | $($QualityGates.Coverage.Status) | $($QualityGates.Coverage.Details) |

## Deployment Checklist

### Pre-Deployment
- [ ] Backup current state
- [ ] Notify stakeholders
- [ ] Verify rollback capability
- [ ] Check deployment window

### Deployment Steps
1. Deploy database migrations (if any)
2. Deploy backend services
3. Deploy frontend (if applicable)
4. Update configurations
5. Verify health checks

### Post-Deployment
- [ ] Run smoke tests
- [ ] Monitor error rates (15 min)
- [ ] Verify key metrics
- [ ] Confirm with stakeholders

## Rollback Plan

### Automatic Triggers
- Error rate > 5%
- Health check failures > 3 consecutive
- P95 latency > 500ms for 5 minutes

### Manual Rollback
``````bash
# Git
git revert HEAD

# Kubernetes (if applicable)
kubectl rollout undo deployment/[service-name]

# Docker (if applicable)
docker-compose down && docker-compose up -d --build
``````

## Sign-off

| Role | Name | Approved | Date |
|------|------|----------|------|
| Tech Lead | | ⬜ | |
| QA | | ⬜ | |
| Product Owner | | ⬜ | |

---

*Generated by Bolt Framework Release Command*
*Date: $date*
"@

    Set-Content -Path $duPath -Value $content
    return $duPath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "`n🚀 Bolt Framework Release Generator" -ForegroundColor Magenta
Write-Host "================================`n" -ForegroundColor Magenta

# Determine version
if (-not $Version) {
    $currentVersion = Get-LastVersion
    Write-Info "Current version: $currentVersion"
    $Version = Get-NextVersion -CurrentVersion $currentVersion -BumpType $ReleaseType
    Write-Info "Next version ($ReleaseType): $Version"
}

if ($DryRun) {
    Write-Warn "DRY RUN MODE - No changes will be made"
}

# Check quality gates
$qualityGates = Test-QualityGates
foreach ($gate in $qualityGates.Keys) {
    $status = $qualityGates[$gate].Status
    $details = $qualityGates[$gate].Details
    Write-Host "  $status $gate : $details"
}

# Get changes since last release
Write-Step "Collecting changes since last release..."
$changes = Get-CommitsSinceLastRelease
Write-Info "Found: $($changes.Added.Count) added, $($changes.Fixed.Count) fixed, $($changes.Changed.Count) changed"

if ($DryRun) {
    Write-Step "Would create deployment unit for v$Version"
    Write-Step "Would update CHANGELOG.md"
    Write-Step "Would create git tag v$Version"
    exit 0
}

# Generate deployment unit
Write-Step "Generating Deployment Unit..."
$duPath = New-DeploymentUnit -Version $Version -QualityGates $qualityGates -Changes $changes
Write-Success "Created: $duPath"

# Update changelog
Write-Step "Updating CHANGELOG..."
$changelogEntry = Update-Changelog -Version $Version -Changes $changes
Write-Success "CHANGELOG.md updated"

# Git operations
Write-Step "Git operations..."
git add docs/deployment_units/ CHANGELOG.md 2>$null
Write-Success "Files staged"

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Release v$Version prepared successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review the deployment unit: $duPath"
Write-Host "  2. Get required sign-offs"
Write-Host "  3. Commit changes: git commit -m `"chore: prepare release v$Version`""
Write-Host "  4. Create tag: git tag -a v$Version -m `"Release v$Version`""
Write-Host "  5. Push: git push origin main --tags"
Write-Host "  6. Run @Bolt Ops after deployment`n"
