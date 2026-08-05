<#
.SYNOPSIS
    Plans and manages system retirement/decommissioning.

.DESCRIPTION
    This script helps plan the retirement of systems or features following
    AI-DLC methodology. It identifies consumers, plans migrations, and
    generates decommissioning documentation.

.PARAMETER SystemName
    Name of the system/feature to retire.

.PARAMETER TargetDate
    Target retirement date.

.PARAMETER ListConsumers
    If specified, lists potential consumers of the system.

.PARAMETER GeneratePlan
    If specified, generates a retirement plan document.

.PARAMETER Interactive
    If specified, runs in interactive mode with prompts.

.EXAMPLE
    .\Plan-Retirement.ps1 -SystemName "Legacy API" -TargetDate "2024-12-31"
    .\Plan-Retirement.ps1 -ListConsumers -SystemName "Payment Module"
    .\Plan-Retirement.ps1 -Interactive

.NOTES
    Part of Bolt Framework / AI-DLC methodology
    Phase: Block 8 - Retirement
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SystemName,

    [Parameter(Mandatory = $false)]
    [string]$TargetDate,

    [Parameter(Mandatory = $false)]
    [switch]$ListConsumers,

    [Parameter(Mandatory = $false)]
    [switch]$GeneratePlan,

    [Parameter(Mandatory = $false)]
    [switch]$Interactive
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

function Read-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    $defaultDisplay = if ($Default) { " [$Default]" } else { "" }
    Write-Host "$Prompt$defaultDisplay`: " -NoNewline -ForegroundColor Yellow
    $input = Read-Host

    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

function Read-MultiLineInput {
    param([string]$Prompt)

    Write-Host "$Prompt (enter empty line to finish):" -ForegroundColor Yellow
    $lines = @()
    while ($true) {
        $line = Read-Host "  "
        if ([string]::IsNullOrWhiteSpace($line)) {
            break
        }
        $lines += $line
    }
    return $lines
}

# ============================================================================
# CONSUMER ANALYSIS
# ============================================================================

function Get-PotentialConsumers {
    param([string]$SystemName)

    Write-Step "Analyzing potential consumers of '$SystemName'..."

    $consumers = @()

    # Look for references in various file types
    $searchPattern = $SystemName.ToLower() -replace '\s+', '[-_\s]?'

    $fileTypes = @("*.cs", "*.ts", "*.js", "*.json", "*.yaml", "*.yml", "*.xml", "*.md")

    foreach ($type in $fileTypes) {
        $files = Get-ChildItem -Path . -Filter $type -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch "node_modules|bin|obj|dist|\.git" }

        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match $searchPattern) {
                $consumers += @{
                    Type = "Code Reference"
                    Location = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\"), ""
                    FileType = $file.Extension
                }
            }
        }
    }

    # Check for API routes or endpoints
    $apiPatterns = @("api/", "endpoint", "route", "controller")
    foreach ($pattern in $apiPatterns) {
        $files = Get-ChildItem -Path . -Filter "*.cs" -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -match "Controller|Route|Endpoint" }
        foreach ($file in $files) {
            $consumers += @{
                Type = "API Endpoint"
                Location = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\"), ""
                FileType = ".cs"
            }
        }
    }

    return $consumers | Sort-Object -Property Location -Unique
}

# ============================================================================
# RETIREMENT PLAN GENERATION
# ============================================================================

function New-RetirementPlan {
    param(
        [hashtable]$PlanData
    )

    $retirementDir = "docs/retirement"
    if (-not (Test-Path $retirementDir)) {
        New-Item -ItemType Directory -Path $retirementDir -Force | Out-Null
    }

    $safeFileName = $PlanData.SystemName -replace '\s+', '-' -replace '[^\w\-]', ''
    $planPath = "$retirementDir/${safeFileName}-retirement-plan.md"
    $date = Get-Date -Format "yyyy-MM-dd"

    # Calculate timeline
    $targetDate = if ($PlanData.TargetDate) {
        [DateTime]::Parse($PlanData.TargetDate)
    } else {
        (Get-Date).AddMonths(6)
    }
    $daysRemaining = ($targetDate - (Get-Date)).Days

    $content = @"
# Retirement Plan: $($PlanData.SystemName)

## Document Info

| Property | Value |
|----------|-------|
| Document ID | RET-$(Get-Date -Format "yyyyMMdd-HHmmss") |
| Created | $date |
| Status | 📝 Draft |
| System/Feature | $($PlanData.SystemName) |
| Target Retirement Date | $($targetDate.ToString("yyyy-MM-dd")) |
| Days Remaining | $daysRemaining |

---

## Executive Summary

$($PlanData.Reason)

---

## Retirement Justification

### Business Rationale

$($PlanData.BusinessReason)

### Technical Rationale

$($PlanData.TechnicalReason)

### Cost Analysis

| Category | Current Cost | Post-Retirement Savings |
|----------|--------------|------------------------|
| Infrastructure | [TBD] | [TBD] |
| Maintenance | [TBD] | [TBD] |
| Support | [TBD] | [TBD] |
| **Total** | [TBD] | [TBD] |

---

## Impact Assessment

### Known Consumers

| Consumer | Type | Impact Level | Migration Required |
|----------|------|--------------|-------------------|
"@

    if ($PlanData.Consumers -and $PlanData.Consumers.Count -gt 0) {
        foreach ($consumer in $PlanData.Consumers | Select-Object -First 20) {
            $content += "| ``$($consumer.Location)`` | $($consumer.Type) | Medium | Yes |`n"
        }
    } else {
        $content += "| *No consumers identified* | - | - | - |`n"
    }

    $content += @"

### Dependencies

| System/Component | Dependency Type | Action Required |
|------------------|-----------------|-----------------|
| [Identify dependencies] | [Direct/Indirect] | [Action] |

### Stakeholder Impact

| Stakeholder Group | Impact | Communication Plan |
|-------------------|--------|-------------------|
| Development Team | High | Weekly updates |
| Operations | Medium | Migration guide |
| End Users | $(if ($daysRemaining -gt 90) { "Low" } else { "High" }) | Documentation update |

---

## Migration Strategy

### Replacement System

$($PlanData.Replacement)

### Migration Approach

- [ ] **Big Bang**: Complete migration on single date
- [x] **Phased**: Gradual migration by component/consumer
- [ ] **Parallel Run**: Both systems active during transition

### Migration Steps

1. **Phase 1: Preparation** (Weeks 1-2)
   - [ ] Complete consumer inventory
   - [ ] Document all integration points
   - [ ] Create migration runbooks

2. **Phase 2: Development** (Weeks 3-6)
   - [ ] Build/configure replacement system
   - [ ] Create migration scripts
   - [ ] Develop testing strategy

3. **Phase 3: Testing** (Weeks 7-8)
   - [ ] Integration testing
   - [ ] Performance testing
   - [ ] User acceptance testing

4. **Phase 4: Migration** (Weeks 9-10)
   - [ ] Execute migration per consumer
   - [ ] Validate each migration
   - [ ] Monitor for issues

5. **Phase 5: Retirement** (Weeks 11-12)
   - [ ] Final data backup
   - [ ] Decommission old system
   - [ ] Archive documentation

---

## Communication Plan

### Timeline

| Date | Milestone | Communication |
|------|-----------|---------------|
| $date | Plan created | Internal team |
| $(Get-Date (Get-Date).AddDays(7) -Format "yyyy-MM-dd") | Consumer notification | Email to stakeholders |
| $(Get-Date $targetDate.AddDays(-30) -Format "yyyy-MM-dd") | Final warning | All consumers |
| $(Get-Date $targetDate -Format "yyyy-MM-dd") | System retired | Confirmation notice |

### Templates

<details>
<summary>📧 Initial Consumer Notification</summary>

```
Subject: [Action Required] $($PlanData.SystemName) Retirement Notice

Dear Team,

This is to inform you that $($PlanData.SystemName) is scheduled for retirement
on $($targetDate.ToString("yyyy-MM-dd")).

**What this means for you:**
- [Impact specific to consumer]

**What you need to do:**
- [Migration steps]

**Timeline:**
- [Key dates]

Please reach out if you have questions.
```

</details>

---

## Rollback Plan

If retirement needs to be reversed:

1. **Restore from backup**: [Location and procedure]
2. **Reconfigure DNS/routing**: [Steps]
3. **Notify consumers**: [Communication]
4. **Update status**: Set retirement status to "Deferred"

---

## Success Criteria

| Criteria | Target | Status |
|----------|--------|--------|
| All consumers migrated | 100% | ⬜ Pending |
| No production incidents | 0 | ⬜ Pending |
| Documentation archived | Complete | ⬜ Pending |
| Resources reclaimed | 100% | ⬜ Pending |
| Stakeholder sign-off | All | ⬜ Pending |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Unknown consumers | Medium | High | Extended discovery period |
| Migration delays | Medium | Medium | Buffer time in schedule |
| Data loss | Low | Critical | Multiple backup strategy |
| Stakeholder resistance | Low | Medium | Clear communication |

---

## Checklist

### Pre-Retirement
- [ ] All consumers identified and notified
- [ ] Migration plan documented per consumer
- [ ] Replacement system ready
- [ ] Rollback plan tested
- [ ] Final backup completed
- [ ] Stakeholder sign-offs obtained

### Retirement Day
- [ ] Final monitoring check
- [ ] Execute decommission script
- [ ] Verify system unreachable
- [ ] Update DNS/routing
- [ ] Notify all stakeholders

### Post-Retirement
- [ ] Archive all documentation
- [ ] Release infrastructure resources
- [ ] Close related support tickets
- [ ] Update architecture diagrams
- [ ] Conduct lessons learned session

---

## Revision History

| Date | Changes | Author |
|------|---------|--------|
| $date | Initial plan created | Bolt Framework |

---

*Generated by Bolt Framework Retire Command*
"@

    Set-Content -Path $planPath -Value $content
    return $planPath
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

function Start-InteractiveRetirement {
    $planData = @{
        SystemName = ""
        TargetDate = ""
        Reason = ""
        BusinessReason = ""
        TechnicalReason = ""
        Replacement = ""
        Consumers = @()
    }

    Write-Step "Interactive Retirement Planning"

    $planData.SystemName = Read-UserInput "System/Feature name to retire"
    if ([string]::IsNullOrWhiteSpace($planData.SystemName)) {
        Write-Err "System name is required"
        return
    }

    $planData.TargetDate = Read-UserInput "Target retirement date (YYYY-MM-DD)" (Get-Date (Get-Date).AddMonths(6) -Format "yyyy-MM-dd")

    Write-Host "`n" -NoNewline
    $planData.Reason = Read-UserInput "Brief summary of why this is being retired" "System is being replaced with modern alternative"

    Write-Host "`n" -NoNewline
    $planData.BusinessReason = Read-UserInput "Business reason for retirement" "Cost reduction and improved capabilities"

    Write-Host "`n" -NoNewline
    $planData.TechnicalReason = Read-UserInput "Technical reason for retirement" "Legacy technology, maintenance burden, security concerns"

    Write-Host "`n" -NoNewline
    $planData.Replacement = Read-UserInput "What replaces this system?" "New system/process TBD"

    Write-Host "`n" -NoNewline
    $analyzeConsumers = Read-UserInput "Analyze codebase for potential consumers? (y/n)" "y"
    if ($analyzeConsumers -eq "y") {
        $planData.Consumers = Get-PotentialConsumers -SystemName $planData.SystemName
        Write-Info "Found $($planData.Consumers.Count) potential consumer references"
    }

    return $planData
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "\n\ud83c\udfda\ufe0f Bolt Framework Retirement Planner" -ForegroundColor Magenta
Write-Host "==================================`n" -ForegroundColor Magenta

$planData = $null

if ($Interactive) {
    $planData = Start-InteractiveRetirement
    if ($null -eq $planData) {
        exit 1
    }
} else {
    if (-not $SystemName) {
        Write-Err "System name is required. Use -SystemName or -Interactive"
        Write-Host "`nUsage examples:"
        Write-Host "  .\Plan-Retirement.ps1 -Interactive"
        Write-Host "  .\Plan-Retirement.ps1 -SystemName 'Legacy API' -GeneratePlan"
        Write-Host "  .\Plan-Retirement.ps1 -SystemName 'Old Module' -ListConsumers`n"
        exit 1
    }

    $planData = @{
        SystemName = $SystemName
        TargetDate = if ($TargetDate) { $TargetDate } else { (Get-Date).AddMonths(6).ToString("yyyy-MM-dd") }
        Reason = "System scheduled for retirement"
        BusinessReason = "Business requirements changed"
        TechnicalReason = "Technical debt and maintenance burden"
        Replacement = "To be determined"
        Consumers = @()
    }

    if ($ListConsumers) {
        $planData.Consumers = Get-PotentialConsumers -SystemName $SystemName

        Write-Step "Consumer Analysis Results"
        if ($planData.Consumers.Count -eq 0) {
            Write-Info "No direct code references found"
        } else {
            Write-Info "Found $($planData.Consumers.Count) potential consumers:"
            foreach ($consumer in $planData.Consumers | Select-Object -First 10) {
                Write-Host "    • $($consumer.Location) [$($consumer.Type)]"
            }
            if ($planData.Consumers.Count -gt 10) {
                Write-Info "... and $($planData.Consumers.Count - 10) more"
            }
        }

        if (-not $GeneratePlan) {
            Write-Host "`nUse -GeneratePlan to create a full retirement plan`n"
            exit 0
        }
    }
}

if ($GeneratePlan -or $Interactive) {
    Write-Step "Generating retirement plan..."

    if (-not $planData.Consumers -or $planData.Consumers.Count -eq 0) {
        $planData.Consumers = Get-PotentialConsumers -SystemName $planData.SystemName
    }

    $planPath = New-RetirementPlan -PlanData $planData
    Write-Success "Retirement plan created: $planPath"
}

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Retirement planning complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review and complete the retirement plan"
Write-Host "  2. Identify and notify all consumers"
Write-Host "  3. Schedule migration workshops"
Write-Host "  4. Set up monitoring for migration progress"
Write-Host "  5. Plan rollback scenarios`n"
