<#
.SYNOPSIS
    Generates incident postmortem documentation.

.DESCRIPTION
    This script creates structured postmortem reports following blameless
    postmortem principles and the AI-DLC methodology.

.PARAMETER Title
    The title/description of the incident.

.PARAMETER Severity
    Incident severity (SEV1, SEV2, SEV3, SEV4).

.PARAMETER StartTime
    When the incident started (ISO format or parseable date string).

.PARAMETER EndTime
    When the incident was resolved.

.PARAMETER Interactive
    If specified, prompts for incident details interactively.

.EXAMPLE
    .\Generate-Postmortem.ps1 -Title "API Outage" -Severity SEV2
    .\Generate-Postmortem.ps1 -Interactive

.NOTES
    Part of Bolt Framework / AI-DLC methodology
    Phase: Block 6 - Operations
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [ValidateSet("SEV1", "SEV2", "SEV3", "SEV4")]
    [string]$Severity = "SEV3",

    [Parameter(Mandatory = $false)]
    [string]$StartTime,

    [Parameter(Mandatory = $false)]
    [string]$EndTime,

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

function ConvertTo-Slug {
    param([string]$Text)
    $slug = $Text.ToLower()
    $slug = $slug -replace "[^a-z0-9\s-]", ""
    $slug = $slug -replace "\s+", "-"
    $slug = $slug -replace "-+", "-"
    $slug = $slug.Trim("-")
    return $slug.Substring(0, [Math]::Min(50, $slug.Length))
}

function Get-InteractiveInput {
    Write-Host "`n🔍 Incident Details Collection" -ForegroundColor Magenta
    Write-Host "================================`n" -ForegroundColor Magenta

    $details = @{}

    $details.Title = Read-Host "Incident title/description"

    Write-Host "`nSeverity levels:"
    Write-Host "  SEV1 - Critical: Complete outage, major business impact"
    Write-Host "  SEV2 - High: Significant degradation, notable impact"
    Write-Host "  SEV3 - Medium: Partial issue, limited impact"
    Write-Host "  SEV4 - Low: Minor issue, minimal impact"
    $sevInput = Read-Host "Severity (SEV1/SEV2/SEV3/SEV4) [SEV3]"
    $details.Severity = if ($sevInput) { $sevInput } else { "SEV3" }

    $details.StartTime = Read-Host "Start time (YYYY-MM-DD HH:MM or press Enter for now)"
    if (-not $details.StartTime) { $details.StartTime = Get-Date -Format "yyyy-MM-dd HH:mm" }

    $details.EndTime = Read-Host "End time (YYYY-MM-DD HH:MM or press Enter for now)"
    if (-not $details.EndTime) { $details.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm" }

    $details.Services = Read-Host "Affected services (comma-separated)"
    $details.UsersAffected = Read-Host "Users affected (number or 'unknown')"
    $details.RootCause = Read-Host "Root cause (brief description, or 'TBD')"
    $details.Resolution = Read-Host "How was it resolved (brief description)"

    return $details
}

# ============================================================================
# POSTMORTEM GENERATION
# ============================================================================

function New-Postmortem {
    param(
        [string]$Title,
        [string]$Severity,
        [string]$StartTime,
        [string]$EndTime,
        [string]$Services,
        [string]$UsersAffected,
        [string]$RootCause,
        [string]$Resolution
    )

    # Ensure directory exists
    $pmDir = "docs/postmortems"
    if (-not (Test-Path $pmDir)) {
        New-Item -ItemType Directory -Path $pmDir -Force | Out-Null
    }

    $date = Get-Date -Format "yyyy-MM-dd"
    $slug = ConvertTo-Slug $Title
    $pmPath = "$pmDir/postmortem_${date}_${slug}.md"

    # Calculate duration
    $duration = "TBD"
    try {
        $start = [datetime]::Parse($StartTime)
        $end = [datetime]::Parse($EndTime)
        $span = $end - $start
        $duration = "{0:D2}:{1:D2}" -f [int]$span.TotalHours, $span.Minutes
    } catch {}

    $incidentId = "INC-$date-001"
    $author = $env:USERNAME
    if (-not $author) { $author = "[Author Name]" }

    # Default values
    if (-not $Services) { $Services = "[Service Name]" }
    if (-not $UsersAffected) { $UsersAffected = "Unknown" }
    if (-not $RootCause) { $RootCause = "To be determined" }
    if (-not $Resolution) { $Resolution = "To be documented" }

    $content = @"
# Postmortem: $Title

## Incident Summary

| Property | Value |
|----------|-------|
| **Incident ID** | $incidentId |
| **Date** | $date |
| **Duration** | $duration |
| **Severity** | $Severity |
| **Status** | Resolved |
| **Author** | $author |
| **Reviewers** | [Add reviewers] |

### Impact

| Metric | Value |
|--------|-------|
| Users Affected | $UsersAffected |
| Revenue Impact | [Estimate or N/A] |
| SLO Impact | [Error budget consumed] |
| Customer Tickets | [Number or N/A] |

### Services Affected

| Service | Impact Level | Duration |
|---------|--------------|----------|
| $Services | [Full/Degraded] | $duration |

---

## Executive Summary

[Write a 2-3 sentence summary for leadership. What happened, how long, what was the impact, and is it fully resolved?]

---

## Timeline

All times in UTC.

| Time | Event | Actor |
|------|-------|-------|
| $StartTime | Incident began / First alert | System |
| [HH:MM] | On-call engineer paged | [Name/System] |
| [HH:MM] | Investigation started | [Name] |
| [HH:MM] | Root cause identified | [Name] |
| [HH:MM] | Mitigation applied | [Name] |
| $EndTime | Service restored | [Name] |
| [HH:MM] | All-clear declared | [Name] |

---

## Root Cause Analysis

### What Happened

$RootCause

[Expand with detailed technical explanation of what went wrong]

### Why It Happened

**Immediate Cause**:
[The direct trigger of the incident]

**Contributing Factors**:
1. [Factor 1 - e.g., Missing monitoring]
2. [Factor 2 - e.g., Insufficient testing]
3. [Factor 3 - e.g., Documentation gap]

### 5 Whys Analysis

1. **Why** did [symptom] occur?
   - Because [reason 1]
2. **Why** did [reason 1] happen?
   - Because [reason 2]
3. **Why** did [reason 2] happen?
   - Because [reason 3]
4. **Why** did [reason 3] happen?
   - Because [reason 4]
5. **Why** did [reason 4] happen?
   - Because [root cause]

---

## Detection

### How Was It Detected?

- [ ] Automated monitoring/alerting
- [ ] Customer report
- [ ] Internal user report
- [ ] Routine check
- [ ] Other: [Specify]

### Detection Metrics

| Metric | Value |
|--------|-------|
| Time to Detection (TTD) | [Minutes] |
| Time to Acknowledgment (TTA) | [Minutes] |
| Time to Mitigation (TTM) | [Minutes] |
| Time to Resolution (TTR) | [Minutes] |

### Detection Gaps

[What monitoring or alerting was missing that could have detected this sooner?]

---

## Response

### What Went Well

1. [Positive aspect of incident response]
2. [Another positive aspect]
3. [Another positive aspect]

### What Went Wrong

1. [Issue with incident response]
2. [Another issue]
3. [Another issue]

### Where We Got Lucky

1. [Lucky circumstance that reduced impact]
2. [Another lucky circumstance]

---

## Resolution

### Immediate Fix

$Resolution

``````bash
# Commands or steps taken (if applicable)
[Document actual commands used]
``````

### Permanent Fix

[What is being done to prevent recurrence]

---

## Action Items

| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|
| 1 | [Prevent: Action to stop recurrence] | [Name] | P1 | [Date] | ⬜ |
| 2 | [Detect: Action to find it faster] | [Name] | P2 | [Date] | ⬜ |
| 3 | [Mitigate: Action to reduce impact] | [Name] | P2 | [Date] | ⬜ |
| 4 | [Process: Update runbook/docs] | [Name] | P3 | [Date] | ⬜ |

### Action Item Legend

- 🔴 **Prevent**: Stop this from happening again
- 🟡 **Detect**: Find it faster next time
- 🟢 **Mitigate**: Reduce impact if it happens again
- 🔵 **Process**: Improve our procedures

---

## Lessons Learned

### Technical Lessons

1. [Technical lesson]
2. [Technical lesson]

### Process Lessons

1. [Process lesson]
2. [Process lesson]

### Documentation Updates Needed

- [ ] Runbook: [Section to update]
- [ ] Architecture docs: [What to add]
- [ ] Onboarding: [What to include]

---

## Appendix

### Relevant Logs

``````
[Key log snippets that illustrate the issue]
``````

### Metrics/Graphs

[Links to relevant dashboards or embedded graphs]

### Related Incidents

| Incident | Date | Similarity |
|----------|------|------------|
| [INC-XXX] | [Date] | [How related] |

### References

- [Link to incident channel/thread]
- [Link to relevant documentation]
- [Link to related PRs/commits]

---

## Sign-off

| Role | Name | Reviewed | Date |
|------|------|----------|------|
| Incident Commander | [Name] | ⬜ | |
| Engineering Lead | [Name] | ⬜ | |
| Service Owner | [Name] | ⬜ | |

---

## Blameless Culture Reminder

> **Remember**: This postmortem is about learning, not blame.
> - Focus on **systems** and **processes**, not individuals
> - Use "the system allowed" instead of "[person] caused"
> - Assume everyone acted with best intentions and available information
> - Goal is **prevention**, not punishment

---

*Generated by Bolt Framework Postmortem Command*
*Date: $(Get-Date -Format "yyyy-MM-dd HH:mm")*
"@

    Set-Content -Path $pmPath -Value $content
    return $pmPath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "`n📝 Bolt Framework Postmortem Generator" -ForegroundColor Magenta
Write-Host "===================================`n" -ForegroundColor Magenta

$details = @{}

if ($Interactive) {
    $details = Get-InteractiveInput
    $Title = $details.Title
    $Severity = $details.Severity
    $StartTime = $details.StartTime
    $EndTime = $details.EndTime
} else {
    if (-not $Title) {
        $Title = Read-Host "Enter incident title"
    }
    if (-not $StartTime) {
        $StartTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    }
    if (-not $EndTime) {
        $EndTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    }
    $details = @{
        Services = ""
        UsersAffected = ""
        RootCause = ""
        Resolution = ""
    }
}

Write-Step "Generating Postmortem Document..."

$pmPath = New-Postmortem `
    -Title $Title `
    -Severity $Severity `
    -StartTime $StartTime `
    -EndTime $EndTime `
    -Services $details.Services `
    -UsersAffected $details.UsersAffected `
    -RootCause $details.RootCause `
    -Resolution $details.Resolution

Write-Success "Postmortem created: $pmPath"

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Postmortem document generated successfully!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Complete the postmortem document: $pmPath"
Write-Host "  2. Fill in timeline details"
Write-Host "  3. Complete root cause analysis"
Write-Host "  4. Assign action item owners"
Write-Host "  5. Schedule postmortem review meeting"
Write-Host "  6. Run @Bolt Ops to update runbook"
Write-Host "  7. Run @Bolt Improve to add action items to backlog`n"
