<#
.SYNOPSIS
    Bolt Framework Project Status Analyzer

.DESCRIPTION
    Analyzes project state and generates status report for continuity.
    Helps developers and AI agents understand current progress and resume work.

.PARAMETER ReportType
    Type of report to generate: Summary, Full, Features, Tasks, Infra, Quality, Blockers

.PARAMETER Format
    Output format: Markdown (default) or Json

.PARAMETER Feature
    Analyze a specific feature by name

.PARAMETER Save
    Save the report to memory/context/ directory

.EXAMPLE
    .\Get-ProjectStatus.ps1
    # Generates executive summary

.EXAMPLE
    .\Get-ProjectStatus.ps1 -ReportType Full
    # Generates complete analysis

.EXAMPLE
    .\Get-ProjectStatus.ps1 -Format Json -Save
    # Generates JSON report and saves to memory/context/

.EXAMPLE
    .\Get-ProjectStatus.ps1 -Feature "001-user-auth"
    # Analyzes specific feature
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Summary', 'Full', 'Features', 'Tasks', 'Infra', 'Quality', 'Blockers')]
    [string]$ReportType = 'Summary',

    [Parameter()]
    [ValidateSet('Markdown', 'Json')]
    [string]$Format = 'Markdown',

    [Parameter()]
    [string]$Feature = '',

    [Parameter()]
    [switch]$Save
)

# ============================================================================
# Configuration
# ============================================================================

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..").FullName

# Status tracking
$Script:ProjectInfo = @{}
$Script:FeatureStats = @{}
$Script:TaskStats = @{}
$Script:QualityStats = @{}
$Script:InfraStats = @{}
$Script:Blockers = @()
$Script:PendingDecisions = @()
$Script:GitInfo = @{}

# ============================================================================
# Helper Functions
# ============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )

    $colors = @{
        'Header'  = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Info'    = 'White'
        'Section' = 'Blue'
    }

    $symbols = @{
        'Header'  = '═══'
        'Success' = '✅'
        'Warning' = '⚠️'
        'Error'   = '❌'
        'Info'    = 'ℹ️'
        'Section' = '───'
    }

    $color = $colors[$Type]
    $symbol = $symbols[$Type]

    if ($Type -eq 'Header') {
        Write-Host ""
        Write-Host "$symbol $Message $symbol" -ForegroundColor $color
        Write-Host ""
    }
    elseif ($Type -eq 'Section') {
        Write-Host ""
        Write-Host "$symbol $Message $symbol" -ForegroundColor $color
        Write-Host ""
    }
    else {
        Write-Host "$symbol $Message" -ForegroundColor $color
    }
}

function Get-ProgressBar {
    param(
        [int]$Percentage,
        [int]$Width = 20
    )

    $filled = [math]::Floor($Percentage * $Width / 100)
    $empty = $Width - $filled

    $bar = '█' * $filled + '░' * $empty
    return "[$bar] $Percentage%"
}

# ============================================================================
# Analysis Functions
# ============================================================================

function Get-ProjectInfo {
    $constitutionPath = Join-Path $ProjectRoot "memory\constitution.md"

    $Script:ProjectInfo = @{
        Name = "[PROJECT_NAME]"
        Scope = "Not Configured"
        Type = "Not Specified"
        ConstitutionStatus = "❌ Missing"
    }

    if (Test-Path $constitutionPath) {
        $content = Get-Content $constitutionPath -Raw

        $Script:ProjectInfo.ConstitutionStatus = "✅ Present"

        # Determine project scope
        if ($content -match '\[x\].*Infrastructure Only') {
            $Script:ProjectInfo.Scope = "Infrastructure Only"
        }
        elseif ($content -match '\[x\].*Application Development') {
            $Script:ProjectInfo.Scope = "Application Development"
        }
        elseif ($content -match '\[x\].*Full Stack') {
            $Script:ProjectInfo.Scope = "Full Stack"
        }

        # Determine migration context
        if ($content -match '\[x\].*Greenfield') {
            $Script:ProjectInfo.Type = "Greenfield"
        }
        elseif ($content -match '\[x\].*Brownfield') {
            $Script:ProjectInfo.Type = "Brownfield"
        }
        elseif ($content -match '\[x\].*Migration') {
            $Script:ProjectInfo.Type = "Migration"
        }
    }
}

function Get-FeatureStatus {
    $specsDir = Join-Path $ProjectRoot "specs"

    $Script:FeatureStats = @{
        Total = 0
        Complete = 0
        InProgress = 0
        Pending = 0
        Features = @()
    }

    if (Test-Path $specsDir) {
        $featureDirs = Get-ChildItem -Path $specsDir -Directory

        foreach ($featureDir in $featureDirs) {
            $Script:FeatureStats.Total++

            $featureName = $featureDir.Name
            $reqFile = Join-Path $featureDir.FullName "requirements\requirements.md"
            $planFile = Join-Path $featureDir.FullName "planning\plan.md"
            $tasksFile = Join-Path $featureDir.FullName "planning\tasks.md"

            $reqStatus = if (Test-Path $reqFile) { "✅" } else { "❌" }
            $planStatus = if (Test-Path $planFile) { "✅" } else { "❌" }
            $tasksStatus = if (Test-Path $tasksFile) { "✅" } else { "❌" }

            $featureStatus = "⏳ Pending"
            $completion = 0

            if ($reqStatus -eq "✅" -and $planStatus -eq "✅" -and $tasksStatus -eq "✅") {
                # Check task completion
                if (Test-Path $tasksFile) {
                    $tasksContent = Get-Content $tasksFile -Raw
                    $totalTasks = ([regex]::Matches($tasksContent, '^\- \[', 'Multiline')).Count
                    $doneTasks = ([regex]::Matches($tasksContent, '^\- \[x\]', 'Multiline')).Count

                    if ($totalTasks -gt 0) {
                        $completion = [math]::Round(($doneTasks / $totalTasks) * 100)

                        if ($doneTasks -eq $totalTasks) {
                            $featureStatus = "✅ Complete"
                            $Script:FeatureStats.Complete++
                        }
                        elseif ($doneTasks -gt 0) {
                            $featureStatus = "🔄 In Progress"
                            $Script:FeatureStats.InProgress++
                        }
                        else {
                            $featureStatus = "⏳ Ready"
                            $Script:FeatureStats.Pending++
                        }
                    }
                }
            }
            elseif ($reqStatus -eq "✅") {
                $featureStatus = "🔄 Planning"
                $Script:FeatureStats.InProgress++
            }
            else {
                $Script:FeatureStats.Pending++
            }

            $Script:FeatureStats.Features += @{
                Name = $featureName
                Requirements = $reqStatus
                Plan = $planStatus
                Tasks = $tasksStatus
                Status = $featureStatus
                Completion = $completion
            }
        }
    }
}

function Get-TaskStatus {
    $specsDir = Join-Path $ProjectRoot "specs"

    $Script:TaskStats = @{
        Total = 0
        Done = 0
        InProgress = 0
        Pending = 0
        Blocked = 0
        Percentage = 0
        CurrentBolt = ""
        CurrentTasks = @()
        ByFeature = @()
    }

    if (Test-Path $specsDir) {
        $tasksFiles = Get-ChildItem -Path $specsDir -Recurse -Filter "tasks.md"

        foreach ($tasksFile in $tasksFiles) {
            $featureName = (Get-Item $tasksFile.DirectoryName).Parent.Name
            $content = Get-Content $tasksFile.FullName -Raw

            $totalTasks = ([regex]::Matches($content, '^\- \[', 'Multiline')).Count
            $doneTasks = ([regex]::Matches($content, '^\- \[x\]', 'Multiline')).Count
            $pendingTasks = $totalTasks - $doneTasks

            $Script:TaskStats.Total += $totalTasks
            $Script:TaskStats.Done += $doneTasks
            $Script:TaskStats.Pending += $pendingTasks

            $Script:TaskStats.ByFeature += @{
                Feature = $featureName
                Total = $totalTasks
                Done = $doneTasks
                Pending = $pendingTasks
            }

            # Find current bolt
            if (-not $Script:TaskStats.CurrentBolt) {
                $boltMatch = [regex]::Match($content, '^## (Bolt \d+.*?)$', 'Multiline')
                if ($boltMatch.Success) {
                    $Script:TaskStats.CurrentBolt = $boltMatch.Groups[1].Value
                }

                # Get pending tasks
                $pendingMatches = [regex]::Matches($content, '^\- \[ \] (.+)$', 'Multiline')
                $Script:TaskStats.CurrentTasks = $pendingMatches | Select-Object -First 5 | ForEach-Object { $_.Groups[1].Value }
            }
        }
    }

    if ($Script:TaskStats.Total -gt 0) {
        $Script:TaskStats.Percentage = [math]::Round(($Script:TaskStats.Done / $Script:TaskStats.Total) * 100)
    }
}

function Get-QualityStatus {
    $Script:QualityStats = @{
        LineCoverage = "N/A"
        BranchCoverage = "N/A"
        MutationScore = "N/A"
        Status = "❓ Not Measured"
    }

    # Check for coverage reports
    $coverageSummary = Join-Path $ProjectRoot "coverage\coverage-summary.json"
    if (Test-Path $coverageSummary) {
        try {
            $coverage = Get-Content $coverageSummary -Raw | ConvertFrom-Json
            $Script:QualityStats.LineCoverage = $coverage.total.lines.pct
            $Script:QualityStats.BranchCoverage = $coverage.total.branches.pct
        }
        catch {
            # Silently ignore parsing errors
        }
    }

    # Check for mutation reports
    $mutationReport = Join-Path $ProjectRoot "reports\mutation\mutation.json"
    if (Test-Path $mutationReport) {
        try {
            $mutation = Get-Content $mutationReport -Raw | ConvertFrom-Json
            $Script:QualityStats.MutationScore = $mutation.mutationScore
        }
        catch {
            # Silently ignore parsing errors
        }
    }

    # Determine overall status
    if ($Script:QualityStats.LineCoverage -ne "N/A") {
        if ([double]$Script:QualityStats.LineCoverage -ge 80) {
            $Script:QualityStats.Status = "✅ Good"
        }
        elseif ([double]$Script:QualityStats.LineCoverage -ge 60) {
            $Script:QualityStats.Status = "⚠️ Below Target"
        }
        else {
            $Script:QualityStats.Status = "❌ Critical"
        }
    }
}

function Get-InfrastructureStatus {
    $Script:InfraStats = @{
        Status = "Not present"
        Tool = ""
        Modules = 0
    }

    $bicepDir = Join-Path $ProjectRoot "infra\bicep"
    $terraformDir = Join-Path $ProjectRoot "infra\terraform"
    $platformDir = Join-Path $ProjectRoot "platform"

    if (Test-Path $bicepDir) {
        $Script:InfraStats.Tool = "Bicep"
        $Script:InfraStats.Status = "✅ Present"
        $Script:InfraStats.Modules = (Get-ChildItem -Path $bicepDir -Recurse -Filter "*.bicep" -File).Count
    }
    elseif (Test-Path $terraformDir) {
        $Script:InfraStats.Tool = "Terraform"
        $Script:InfraStats.Status = "✅ Present"
        $Script:InfraStats.Modules = (Get-ChildItem -Path $terraformDir -Recurse -Filter "*.tf" -File).Count
    }
    elseif (Test-Path $platformDir) {
        $Script:InfraStats.Tool = "Landing Zone"
        $Script:InfraStats.Status = "✅ Present"
        $bicepCount = (Get-ChildItem -Path $platformDir -Recurse -Filter "*.bicep" -File -ErrorAction SilentlyContinue).Count
        $tfCount = (Get-ChildItem -Path $platformDir -Recurse -Filter "*.tf" -File -ErrorAction SilentlyContinue).Count
        $Script:InfraStats.Modules = $bicepCount + $tfCount
    }
}

function Get-BlockersAndDecisions {
    $Script:Blockers = @()
    $Script:PendingDecisions = @()

    # Search for blockers in task files
    $specsDir = Join-Path $ProjectRoot "specs"
    if (Test-Path $specsDir) {
        $tasksFiles = Get-ChildItem -Path $specsDir -Recurse -Filter "tasks.md"
        foreach ($file in $tasksFiles) {
            $content = Get-Content $file.FullName -Raw
            if ($content -match 'blocked|blocker') {
                $featureName = (Get-Item $file.DirectoryName).Parent.Name
                $Script:Blockers += "[$featureName] Found blocker reference"
            }
        }
    }

    # Search for pending ADRs
    $adrDir = Join-Path $ProjectRoot "docs\architecture\decisions"
    if (Test-Path $adrDir) {
        $adrFiles = Get-ChildItem -Path $adrDir -Filter "*.md"
        foreach ($adr in $adrFiles) {
            $content = Get-Content $adr.FullName -Raw
            if ($content -match 'Status.*Proposed|Status.*Pending') {
                $Script:PendingDecisions += "$($adr.Name) (Pending approval)"
            }
        }
    }

    # Check memory/decisions
    $decisionDir = Join-Path $ProjectRoot "memory\decisions"
    if (Test-Path $decisionDir) {
        $decisionFiles = Get-ChildItem -Path $decisionDir -Filter "*.md"
        foreach ($dec in $decisionFiles) {
            $content = Get-Content $dec.FullName -Raw
            if ($content -match 'Status.*Pending|Status.*Open') {
                $Script:PendingDecisions += $dec.Name
            }
        }
    }
}

function Get-GitInfo {
    $Script:GitInfo = @{
        LastCommit = "N/A"
        LastCommitDate = "N/A"
        CurrentBranch = "N/A"
        UncommittedChanges = 0
    }

    $gitDir = Join-Path $ProjectRoot ".git"
    if (Test-Path $gitDir) {
        try {
            Push-Location $ProjectRoot

            $Script:GitInfo.LastCommit = git log -1 --format="%h - %s (%cr)" 2>$null
            $Script:GitInfo.LastCommitDate = git log -1 --format="%ci" 2>$null
            $Script:GitInfo.CurrentBranch = git branch --show-current 2>$null
            $Script:GitInfo.UncommittedChanges = (git status --porcelain 2>$null | Measure-Object).Count

            Pop-Location
        }
        catch {
            Pop-Location
        }
    }
}

# ============================================================================
# Report Generation
# ============================================================================

function New-SummaryReport {
    Write-ColorOutput "🚀 Bolt Framework Project Status" -Type 'Header'

    Write-Host "Project:       $($Script:ProjectInfo.Name)"
    Write-Host "Type:          $($Script:ProjectInfo.Type) | Scope: $($Script:ProjectInfo.Scope)"
    Write-Host "Branch:        $($Script:GitInfo.CurrentBranch)"
    Write-Host "Last Activity: $($Script:GitInfo.LastCommit)"
    Write-Host ""

    Write-ColorOutput "Quick Stats" -Type 'Section'

    Write-Host "| Metric        | Value |"
    Write-Host "|---------------|-------|"
    Write-Host "| Constitution  | $($Script:ProjectInfo.ConstitutionStatus) |"
    Write-Host "| Features      | $($Script:FeatureStats.Complete)/$($Script:FeatureStats.Total) complete |"
    Write-Host "| Tasks         | $(Get-ProgressBar -Percentage $Script:TaskStats.Percentage) |"
    Write-Host "| Quality       | $($Script:QualityStats.Status) |"
    Write-Host "| Uncommitted   | $($Script:GitInfo.UncommittedChanges) files |"
    Write-Host ""

    Write-ColorOutput "🎯 Resume Work" -Type 'Section'

    if ($Script:TaskStats.CurrentBolt) {
        Write-Host "Current Bolt: $($Script:TaskStats.CurrentBolt)" -ForegroundColor White
        Write-Host ""
        Write-Host "Next tasks to complete:"
        foreach ($task in $Script:TaskStats.CurrentTasks | Select-Object -First 3) {
            Write-Host "  - [ ] $task"
        }
    }
    else {
        Write-Host "No active tasks found. Use @Bolt Feature to start a new feature."
    }
    Write-Host ""

    if ($Script:Blockers.Count -gt 0) {
        Write-ColorOutput "⚠️ Blockers" -Type 'Section'
        foreach ($blocker in $Script:Blockers) {
            Write-Host "  - $blocker" -ForegroundColor Yellow
        }
    }

    if ($Script:PendingDecisions.Count -gt 0) {
        Write-ColorOutput "❓ Pending Decisions" -Type 'Section'
        foreach ($decision in $Script:PendingDecisions) {
            Write-Host "  - $decision" -ForegroundColor Yellow
        }
    }

    Write-ColorOutput "Recommended Actions" -Type 'Section'

    if ($Script:ProjectInfo.ConstitutionStatus -eq "❌ Missing") {
        Write-Host "\ud83d\udd34 HIGH: Create project constitution with @Bolt Constitution" -ForegroundColor Red
    }

    if ($Script:Blockers.Count -gt 0) {
        Write-Host "\ud83d\udd34 HIGH: Resolve blockers with @Bolt Clarify" -ForegroundColor Red
    }

    if ($Script:TaskStats.CurrentTasks.Count -gt 0) {
        $nextTask = $Script:TaskStats.CurrentTasks[0]
        if ($nextTask -match 'T\\d+') {
            Write-Host "\ud83d\udfe1 MEDIUM: Continue with $($Matches[0]) using @Bolt Implement" -ForegroundColor Yellow
        }
    }

    if ($Script:QualityStats.Status -match "Below Target|Critical") {
        Write-Host "\ud83d\udfe1 MEDIUM: Improve test coverage with @Bolt Testing" -ForegroundColor Yellow
    }
}

function New-FullReport {
    New-SummaryReport

    Write-ColorOutput "📋 Features Detail" -Type 'Section'

    if ($Script:FeatureStats.Features.Count -gt 0) {
        Write-Host "| Feature | Requirements | Plan | Tasks | Status | Completion |"
        Write-Host "|---------|--------------|------|-------|--------|------------|"
        foreach ($feature in $Script:FeatureStats.Features) {
            Write-Host "| $($feature.Name) | $($feature.Requirements) | $($feature.Plan) | $($feature.Tasks) | $($feature.Status) | $($feature.Completion)% |"
        }
    }
    else {
        Write-Host "No features found in specs/ directory."
    }

    Write-ColorOutput "📊 Tasks Detail" -Type 'Section'

    if ($Script:TaskStats.ByFeature.Count -gt 0) {
        Write-Host "| Feature | Total | Done | Pending |"
        Write-Host "|---------|-------|------|---------|"
        foreach ($stat in $Script:TaskStats.ByFeature) {
            Write-Host "| $($stat.Feature) | $($stat.Total) | $($stat.Done) | $($stat.Pending) |"
        }
    }

    Write-Host ""
    Write-Host "Total Progress: $($Script:TaskStats.Done)/$($Script:TaskStats.Total) tasks complete ($($Script:TaskStats.Percentage)%)"

    Write-ColorOutput "🧪 Quality Metrics" -Type 'Section'

    $lineStatus = if ($Script:QualityStats.LineCoverage -ne "N/A" -and [double]$Script:QualityStats.LineCoverage -ge 80) { "✅" } else { "⚠️" }
    $branchStatus = if ($Script:QualityStats.BranchCoverage -ne "N/A" -and [double]$Script:QualityStats.BranchCoverage -ge 75) { "✅" } else { "⚠️" }
    $mutationStatus = if ($Script:QualityStats.MutationScore -ne "N/A" -and [double]$Script:QualityStats.MutationScore -ge 70) { "✅" } else { "⚠️" }

    Write-Host "| Metric          | Target | Current | Status |"
    Write-Host "|-----------------|--------|---------|--------|"
    Write-Host "| Line Coverage   | ≥80%   | $($Script:QualityStats.LineCoverage)% | $lineStatus |"
    Write-Host "| Branch Coverage | ≥75%   | $($Script:QualityStats.BranchCoverage)% | $branchStatus |"
    Write-Host "| Mutation Score  | ≥70%   | $($Script:QualityStats.MutationScore)% | $mutationStatus |"

    if ($Script:ProjectInfo.Scope -in @("Infrastructure Only", "Full Stack")) {
        Write-ColorOutput "🏗️ Infrastructure" -Type 'Section'

        Write-Host "| Component | Status |"
        Write-Host "|-----------|--------|"
        Write-Host "| IaC Tool  | $($Script:InfraStats.Tool) |"
        Write-Host "| Status    | $($Script:InfraStats.Status) |"
        Write-Host "| Modules   | $($Script:InfraStats.Modules) files |"
    }
}

function New-JsonReport {
    $report = @{
        project = @{
            name = $Script:ProjectInfo.Name
            type = $Script:ProjectInfo.Type
            scope = $Script:ProjectInfo.Scope
            constitution = $Script:ProjectInfo.ConstitutionStatus
            branch = $Script:GitInfo.CurrentBranch
        }
        features = @{
            total = $Script:FeatureStats.Total
            complete = $Script:FeatureStats.Complete
            inProgress = $Script:FeatureStats.InProgress
            pending = $Script:FeatureStats.Pending
        }
        tasks = @{
            total = $Script:TaskStats.Total
            done = $Script:TaskStats.Done
            pending = $Script:TaskStats.Pending
            blocked = $Script:TaskStats.Blocked
            percentage = $Script:TaskStats.Percentage
        }
        quality = @{
            lineCoverage = $Script:QualityStats.LineCoverage
            branchCoverage = $Script:QualityStats.BranchCoverage
            mutationScore = $Script:QualityStats.MutationScore
            status = $Script:QualityStats.Status
        }
        git = @{
            lastCommit = $Script:GitInfo.LastCommit
            uncommittedChanges = $Script:GitInfo.UncommittedChanges
        }
        currentWork = @{
            bolt = $Script:TaskStats.CurrentBolt
            hasBlockers = ($Script:Blockers.Count -gt 0)
            hasPendingDecisions = ($Script:PendingDecisions.Count -gt 0)
        }
        generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }

    $report | ConvertTo-Json -Depth 10
}

function Save-Report {
    $contextDir = Join-Path $ProjectRoot "memory\context"
    if (-not (Test-Path $contextDir)) {
        New-Item -ItemType Directory -Path $contextDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $contextDir "status_$timestamp.md"
    $latestFile = Join-Path $contextDir "last-session.md"

    # Capture and save report
    $reportContent = @"
# Project Status Report

**Generated**: $(Get-Date)

$(New-FullReport | Out-String)
"@

    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    Copy-Item -Path $reportFile -Destination $latestFile -Force

    Write-ColorOutput "Report saved to: $reportFile" -Type 'Success'
    Write-ColorOutput "Latest session: $latestFile" -Type 'Info'
}

# ============================================================================
# Main
# ============================================================================

function Main {
    # Run all analysis
    Get-ProjectInfo
    Get-FeatureStatus
    Get-TaskStatus
    Get-QualityStatus
    Get-InfrastructureStatus
    Get-BlockersAndDecisions
    Get-GitInfo

    # Generate output
    if ($Format -eq 'Json') {
        New-JsonReport
    }
    else {
        switch ($ReportType) {
            'Full' {
                New-FullReport
            }
            'Features' {
                Write-ColorOutput "Features Status" -Type 'Header'
                foreach ($feature in $Script:FeatureStats.Features) {
                    Write-Host "| $($feature.Name) | $($feature.Status) | $($feature.Completion)% |"
                }
            }
            'Tasks' {
                Write-ColorOutput "Tasks Status" -Type 'Header'
                foreach ($stat in $Script:TaskStats.ByFeature) {
                    Write-Host "| $($stat.Feature) | $($stat.Done)/$($stat.Total) |"
                }
                Write-Host ""
                Write-Host "Current: $($Script:TaskStats.CurrentBolt)"
            }
            'Quality' {
                Write-ColorOutput "Quality Metrics" -Type 'Header'
                Write-Host "Line Coverage:   $($Script:QualityStats.LineCoverage)%"
                Write-Host "Branch Coverage: $($Script:QualityStats.BranchCoverage)%"
                Write-Host "Mutation Score:  $($Script:QualityStats.MutationScore)%"
            }
            'Blockers' {
                Write-ColorOutput "Blockers & Decisions" -Type 'Header'
                Write-Host "Blockers:"
                foreach ($b in $Script:Blockers) { Write-Host "  - $b" }
                Write-Host "Pending Decisions:"
                foreach ($d in $Script:PendingDecisions) { Write-Host "  - $d" }
            }
            'Infra' {
                Write-ColorOutput "Infrastructure Status" -Type 'Header'
                Write-Host "Tool:    $($Script:InfraStats.Tool)"
                Write-Host "Status:  $($Script:InfraStats.Status)"
                Write-Host "Modules: $($Script:InfraStats.Modules)"
            }
            default {
                New-SummaryReport
            }
        }
    }

    # Save if requested
    if ($Save) {
        Save-Report
    }
}

# Run main function
Main
