#Requires -Version 5.1
<#
.SYNOPSIS
    Bolt Framework Alignment & Gap Analysis

.DESCRIPTION
    Analyzes alignment between RFP requirements, legacy code, implementation,
    and Bolt Framework methodology compliance. Detects gaps and generates reports.

.PARAMETER Full
    Run complete alignment analysis (all dimensions)

.PARAMETER RfpOnly
    Analyze RFP coverage only

.PARAMETER LegacyOnly
    Analyze legacy code migration only

.PARAMETER MethodologyOnly
    Analyze Bolt Framework methodology compliance only

.PARAMETER GapsOnly
    Show gap summary only

.PARAMETER CreateBaseline
    Create baseline for future comparisons

.PARAMETER CompareTo
    Path to baseline file for comparison

.PARAMETER AsJson
    Output results in JSON format

.PARAMETER SaveReport
    Save report to memory/analysis/

.EXAMPLE
    .\Get-AlignmentAnalysis.ps1
    # Shows executive summary

.EXAMPLE
    .\Get-AlignmentAnalysis.ps1 -Full
    # Complete analysis with all details

.EXAMPLE
    .\Get-AlignmentAnalysis.ps1 -CreateBaseline
    # Create baseline for future comparisons

.EXAMPLE
    .\Get-AlignmentAnalysis.ps1 -CompareTo "memory/baselines/alignment_2024-01-01.json"
    # Compare with previous baseline
#>

[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$RfpOnly,
    [switch]$LegacyOnly,
    [switch]$MethodologyOnly,
    [switch]$GapsOnly,
    [switch]$CreateBaseline,
    [string]$CompareTo,
    [switch]$AsJson,
    [switch]$SaveReport
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Results storage
$AlignmentScores = @{}
$GapCounts = @{
    Critical = 0
    High = 0
    Medium = 0
    Low = 0
    Total = 0
}
$CriticalGaps = @()
$HighGaps = @()
$Recommendations = @()

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 65) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "--- $Text ---" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success { param([string]$Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Warning { param([string]$Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }
function Write-Error { param([string]$Text) Write-Host "❌ $Text" -ForegroundColor Red }
function Write-Info { param([string]$Text) Write-Host "ℹ️  $Text" -ForegroundColor Cyan }

function Get-ProgressBar {
    param(
        [int]$Percentage,
        [int]$Width = 20
    )

    $filled = [math]::Floor($Percentage * $Width / 100)
    $empty = $Width - $filled

    $bar = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    return "$bar $Percentage%"
}

function Get-StatusIcon {
    param([int]$Score)

    if ($Score -ge 80) { return "✅" }
    elseif ($Score -ge 50) { return "⚠️" }
    else { return "❌" }
}

# ============================================================================
# Project Detection
# ============================================================================

function Get-ProjectContext {
    $result = @{
        Type = "Greenfield"
        Scope = "Application Development"
        MigrationStrategy = ""
        HasRfp = $false
        HasLegacy = $false
    }

    $constitutionPath = Join-Path $ProjectRoot ".boltf/memory/constitution.md"

    if (Test-Path $constitutionPath) {
        $content = Get-Content $constitutionPath -Raw

        # Detect project type
        if ($content -match "\[x\].*Greenfield") {
            $result.Type = "Greenfield"
        }
        elseif ($content -match "\[x\].*Brownfield") {
            $result.Type = "Brownfield"
        }
        elseif ($content -match "\[x\].*(Legacy Migration|Migration)") {
            $result.Type = "Migration"
        }

        # Detect scope
        if ($content -match "\[x\].*Infrastructure Only") {
            $result.Scope = "Infrastructure Only"
        }
        elseif ($content -match "\[x\].*Application Development") {
            $result.Scope = "Application Development"
        }
        elseif ($content -match "\[x\].*Full Stack") {
            $result.Scope = "Full Stack"
        }

        # Detect migration strategy
        if ($content -match "\[x\].*Strangler") {
            $result.MigrationStrategy = "Strangler Fig"
        }
        elseif ($content -match "\[x\].*Big Bang") {
            $result.MigrationStrategy = "Big Bang"
        }
        elseif ($content -match "\[x\].*Branch by Abstraction") {
            $result.MigrationStrategy = "Branch by Abstraction"
        }
    }

    # Check for RFP materials
    $rfpDir = Join-Path $ProjectRoot "demo/from_rfp"
    if (Test-Path $rfpDir) {
        $rfpFiles = Get-ChildItem $rfpDir -File -Include "*.md","*.pdf","*.docx" -ErrorAction SilentlyContinue
        $result.HasRfp = ($rfpFiles.Count -gt 0)
    }

    # Check for legacy code
    $legacyDir = Join-Path $ProjectRoot "demo/from_old_src"
    if (Test-Path $legacyDir) {
        $legacyFiles = Get-ChildItem $legacyDir -File -Recurse -ErrorAction SilentlyContinue
        $result.HasLegacy = ($legacyFiles.Count -gt 0)
    }

    return $result
}

# ============================================================================
# RFP Analysis
# ============================================================================

function Get-RfpCoverage {
    $rfpDir = Join-Path $ProjectRoot "demo/from_rfp"
    $specsDir = Join-Path $ProjectRoot "specs"

    $result = @{
        TotalItems = 0
        CoveredItems = 0
        PendingItems = 0
        Documents = @()
        Uncovered = @()
    }

    if (-not (Test-Path $rfpDir)) {
        $script:AlignmentScores["rfp"] = 0
        return $result
    }

    $rfpFiles = Get-ChildItem $rfpDir -File -Include "*.md","*.txt" -ErrorAction SilentlyContinue

    foreach ($file in $rfpFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Count requirement items
        $items = ([regex]::Matches($content, "^[-*]|^[0-9]+\.", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count

        # Estimate coverage based on specs
        $covered = 0
        if (Test-Path $specsDir) {
            $specFiles = Get-ChildItem $specsDir -Recurse -File -Filter "*.md" -ErrorAction SilentlyContinue
            foreach ($spec in $specFiles) {
                $specContent = Get-Content $spec.FullName -Raw -ErrorAction SilentlyContinue
                if ($specContent -match "RFP|requirement|$($file.BaseName)") {
                    $covered += ([regex]::Matches($specContent, "RFP|requirement", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
                }
            }
        }

        if ($covered -gt $items) { $covered = $items }

        $result.TotalItems += $items
        $result.CoveredItems += $covered

        $docCoverage = if ($items -gt 0) { [math]::Floor($covered * 100 / $items) } else { 0 }

        $result.Documents += @{
            Name = $file.Name
            Items = $items
            Covered = $covered
            Coverage = $docCoverage
        }

        $pending = $items - $covered
        if ($pending -gt 0) {
            $result.Uncovered += "$($file.Name): $pending items uncovered"
        }
    }

    $result.PendingItems = $result.TotalItems - $result.CoveredItems

    if ($result.TotalItems -gt 0) {
        $script:AlignmentScores["rfp"] = [math]::Floor($result.CoveredItems * 100 / $result.TotalItems)
    } else {
        $script:AlignmentScores["rfp"] = 0
    }

    return $result
}

# ============================================================================
# Legacy Code Analysis
# ============================================================================

function Get-LegacyMigrationStatus {
    $legacyDir = Join-Path $ProjectRoot "demo/from_old_src"
    $srcDir = Join-Path $ProjectRoot "src"

    $result = @{
        Files = 0
        Lines = 0
        Functions = 0
        Migrated = 0
        ByLanguage = @()
        Unmigrated = @()
    }

    if (-not (Test-Path $legacyDir)) {
        $script:AlignmentScores["legacy"] = 0
        return $result
    }

    $langStats = @{}
    $legacyFiles = Get-ChildItem $legacyDir -File -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $legacyFiles) {
        $result.Files++
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $lines = ($content -split "`n").Count
        $result.Lines += $lines

        $ext = $file.Extension.ToLower()
        $funcs = 0
        $lang = "Other"

        switch -Regex ($ext) {
            "\.cbl|\.cob|\.cobol" {
                $lang = "COBOL"
                $funcs = ([regex]::Matches($content, "PERFORM|SECTION|PARAGRAPH", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
            }
            "\.vb|\.bas|\.frm" {
                $lang = "VB"
                $funcs = ([regex]::Matches($content, "Sub |Function |Property ", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
            }
            "\.java" {
                $lang = "Java"
                $funcs = ([regex]::Matches($content, "public |private |protected |void |static ")).Count
            }
            "\.sql" {
                $lang = "SQL"
                $funcs = ([regex]::Matches($content, "CREATE PROCEDURE|CREATE FUNCTION|EXEC ", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
            }
        }

        $result.Functions += $funcs

        if (-not $langStats.ContainsKey($lang)) {
            $langStats[$lang] = @{ Files = 0; Lines = 0; Functions = 0 }
        }
        $langStats[$lang].Files++
        $langStats[$lang].Lines += $lines
        $langStats[$lang].Functions += $funcs
    }

    foreach ($lang in $langStats.Keys) {
        $result.ByLanguage += @{
            Language = $lang
            Files = $langStats[$lang].Files
            Lines = $langStats[$lang].Lines
            Functions = $langStats[$lang].Functions
        }
    }

    # Estimate migration based on new source
    if (Test-Path $srcDir) {
        $newFiles = Get-ChildItem $srcDir -Recurse -File -Include "*.cs","*.ts","*.js" -ErrorAction SilentlyContinue
        $result.Migrated = [math]::Min($newFiles.Count * 2, $result.Functions)
    }

    if ($result.Functions -gt 0) {
        $script:AlignmentScores["legacy"] = [math]::Floor($result.Migrated * 100 / $result.Functions)
    } else {
        $script:AlignmentScores["legacy"] = 0
    }

    $unmigrated = $result.Functions - $result.Migrated
    if ($unmigrated -gt 0) {
        $result.Unmigrated += "$unmigrated functions not yet migrated"
    }

    return $result
}

# ============================================================================
# Methodology Compliance
# ============================================================================

function Get-MethodologyCompliance {
    $specsDir = Join-Path $ProjectRoot "specs"
    $memoryDir = Join-Path $ProjectRoot "memory"
    $docsDir = Join-Path $ProjectRoot "docs"

    $result = @{
        PhaseScores = @()
        Missing = @()
    }

    $totalScore = 0
    $phaseCount = 0

    # INCEPTION: Constitution
    $inceptionScore = 0
    $constitutionPath = Join-Path $memoryDir "constitution.md"
    if (Test-Path $constitutionPath) {
        $lines = (Get-Content $constitutionPath).Count
        if ($lines -gt 100) { $inceptionScore = 100 }
        elseif ($lines -gt 50) { $inceptionScore = 70 }
        else { $inceptionScore = 30 }
    }
    $result.PhaseScores += @{ Phase = "INCEPTION"; Artifacts = "constitution.md"; Score = $inceptionScore }
    $totalScore += $inceptionScore
    $phaseCount++

    # DISCOVERY: Domain analysis
    $discoveryScore = 0
    if (Test-Path (Join-Path $ProjectRoot "demo/from_rfp")) { $discoveryScore += 30 }
    $toRfpDir = Join-Path $ProjectRoot "demo/to_rfp"
    if ((Test-Path $toRfpDir) -and (Get-ChildItem $toRfpDir -ErrorAction SilentlyContinue).Count -gt 0) { $discoveryScore += 40 }
    if ((Test-Path (Join-Path $docsDir "domain-model.md")) -or (Test-Path (Join-Path $docsDir "domain"))) { $discoveryScore += 30 }
    $result.PhaseScores += @{ Phase = "DISCOVERY"; Artifacts = "domain analysis"; Score = $discoveryScore }
    $totalScore += $discoveryScore
    $phaseCount++

    # SPECIFY: Requirements
    $specifyScore = 0
    $totalFeatures = 0
    $featuresWithReqs = 0
    if (Test-Path $specsDir) {
        $featureDirs = Get-ChildItem $specsDir -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $featureDirs) {
            $totalFeatures++
            if (Test-Path (Join-Path $dir.FullName "requirements/requirements.md")) { $featuresWithReqs++ }
        }
    }
    if ($totalFeatures -gt 0) { $specifyScore = [math]::Floor($featuresWithReqs * 100 / $totalFeatures) }
    $result.PhaseScores += @{ Phase = "SPECIFY"; Artifacts = "requirements.md"; Score = $specifyScore }
    $totalScore += $specifyScore
    $phaseCount++

    # PLAN: Plans and tasks
    $planScore = 0
    $featuresWithPlan = 0
    $featuresWithTasks = 0
    if (Test-Path $specsDir) {
        $featureDirs = Get-ChildItem $specsDir -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $featureDirs) {
            if (Test-Path (Join-Path $dir.FullName "planning/plan.md")) { $featuresWithPlan++ }
            if (Test-Path (Join-Path $dir.FullName "planning/tasks.md")) { $featuresWithTasks++ }
        }
    }
    if ($totalFeatures -gt 0) { $planScore = [math]::Floor(($featuresWithPlan + $featuresWithTasks) * 50 / $totalFeatures) }
    $result.PhaseScores += @{ Phase = "PLAN"; Artifacts = "plan.md, tasks.md"; Score = $planScore }
    $totalScore += $planScore
    $phaseCount++

    # EXECUTE: Source code
    $executeScore = 0
    $srcDir = Join-Path $ProjectRoot "src"
    if (Test-Path $srcDir) {
        $srcFiles = Get-ChildItem $srcDir -Recurse -File -Include "*.cs","*.ts","*.js","*.py" -ErrorAction SilentlyContinue
        if ($srcFiles.Count -gt 0) { $executeScore = 50 }
        if ($srcFiles.Count -gt 10) { $executeScore = 75 }
        if ($srcFiles.Count -gt 50) { $executeScore = 100 }
    }
    $result.PhaseScores += @{ Phase = "EXECUTE"; Artifacts = "src/ code"; Score = $executeScore }
    $totalScore += $executeScore
    $phaseCount++

    # VALIDATE: Tests
    $validateScore = 0
    $testFiles = Get-ChildItem $ProjectRoot -Recurse -File -Include "*.test.*","*.spec.*","*Tests.cs","test_*.py" -ErrorAction SilentlyContinue
    if ($testFiles.Count -gt 0) { $validateScore = 30 }
    if ($testFiles.Count -gt 10) { $validateScore = 60 }
    if (Test-Path (Join-Path $ProjectRoot "coverage/coverage-summary.json")) { $validateScore += 20 }
    if (Test-Path (Join-Path $ProjectRoot "reports/mutation/mutation.json")) { $validateScore += 20 }
    $result.PhaseScores += @{ Phase = "VALIDATE"; Artifacts = "tests, coverage"; Score = [math]::Min($validateScore, 100) }
    $totalScore += [math]::Min($validateScore, 100)
    $phaseCount++

    # OPERATE: CI/CD
    $operateScore = 0
    $workflowsDir = Join-Path $ProjectRoot ".github/workflows"
    if ((Test-Path $workflowsDir) -and (Get-ChildItem $workflowsDir -Filter "*.yml" -ErrorAction SilentlyContinue).Count -gt 0) { $operateScore += 30 }
    if (Test-Path (Join-Path $ProjectRoot "infra")) { $operateScore += 35 }
    if ((Test-Path (Join-Path $ProjectRoot "docker-compose.yml")) -or (Test-Path (Join-Path $ProjectRoot "Dockerfile"))) { $operateScore += 35 }
    $result.PhaseScores += @{ Phase = "OPERATE"; Artifacts = "CI/CD, infra"; Score = $operateScore }
    $totalScore += $operateScore
    $phaseCount++

    # Overall methodology score
    if ($phaseCount -gt 0) {
        $script:AlignmentScores["methodology"] = [math]::Floor($totalScore / $phaseCount)
    } else {
        $script:AlignmentScores["methodology"] = 0
    }

    # Track missing items
    if ($inceptionScore -lt 100) { $result.Missing += "Constitution incomplete" }
    if ($discoveryScore -lt 50) { $result.Missing += "Domain analysis missing" }
    if ($specifyScore -lt 50) { $result.Missing += "Requirements incomplete" }
    if ($planScore -lt 50) { $result.Missing += "Planning incomplete" }
    if ($executeScore -lt 50) { $result.Missing += "Implementation behind" }
    if ([math]::Min($validateScore, 100) -lt 50) { $result.Missing += "Testing insufficient" }
    if ($operateScore -lt 50) { $result.Missing += "CI/CD not configured" }

    return $result
}

# ============================================================================
# Additional Analyses
# ============================================================================

function Get-TestingStatus {
    $testFiles = Get-ChildItem $ProjectRoot -Recurse -File -Include "*.test.*","*.spec.*","*Tests.cs","test_*.py" -ErrorAction SilentlyContinue
    $testCount = $testFiles.Count

    # Try to get coverage
    $coverage = 0
    $coveragePath = Join-Path $ProjectRoot "coverage/coverage-summary.json"
    if (Test-Path $coveragePath) {
        try {
            $coverageData = Get-Content $coveragePath | ConvertFrom-Json
            $coverage = [math]::Floor($coverageData.total.lines.pct)
        } catch {
            $coverage = $testCount * 5
        }
    } elseif ($testCount -gt 0) {
        $coverage = [math]::Min($testCount * 5, 100)
    }

    $script:AlignmentScores["testing"] = $coverage
}

function Get-DocumentationStatus {
    $docScore = 0
    $maxDocs = 5
    $docCount = 0

    if (Test-Path (Join-Path $ProjectRoot "README.md")) { $docCount++ }
    if (Test-Path (Join-Path $ProjectRoot ".boltf/memory/constitution.md")) { $docCount++ }
    $docsDir = Join-Path $ProjectRoot "docs"
    if ((Test-Path $docsDir) -and (Get-ChildItem $docsDir -ErrorAction SilentlyContinue).Count -gt 0) { $docCount++ }
    $adrDir = Join-Path $ProjectRoot "docs/architecture/decisions"
    if ((Test-Path $adrDir) -and (Get-ChildItem $adrDir -ErrorAction SilentlyContinue).Count -gt 0) { $docCount++ }
    if ((Test-Path (Join-Path $ProjectRoot "CONTRIBUTING.md")) -or (Test-Path (Join-Path $ProjectRoot "CHANGELOG.md"))) { $docCount++ }

    $script:AlignmentScores["documentation"] = [math]::Floor($docCount * 100 / $maxDocs)
}

function Get-InfrastructureStatus {
    $infraScore = 0
    $maxItems = 5
    $infraItems = 0

    if ((Test-Path (Join-Path $ProjectRoot "infra/bicep")) -or (Test-Path (Join-Path $ProjectRoot "infra/terraform"))) { $infraItems++ }
    if (Test-Path (Join-Path $ProjectRoot "Dockerfile")) { $infraItems++ }
    if (Test-Path (Join-Path $ProjectRoot "docker-compose.yml")) { $infraItems++ }
    $workflowsDir = Join-Path $ProjectRoot ".github/workflows"
    if ((Test-Path $workflowsDir) -and (Get-ChildItem $workflowsDir -Filter "*.yml" -ErrorAction SilentlyContinue).Count -gt 0) { $infraItems++ }
    if ((Test-Path (Join-Path $ProjectRoot "k8s")) -or (Test-Path (Join-Path $ProjectRoot "infra/k8s"))) { $infraItems++ }

    $script:AlignmentScores["infrastructure"] = [math]::Floor($infraItems * 100 / $maxItems)
}

# ============================================================================
# Gap Analysis
# ============================================================================

function Get-GapAnalysis {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData,
        [hashtable]$MethodData
    )

    # RFP gaps
    if ($AlignmentScores["rfp"] -lt 100) {
        $rfpGap = 100 - $AlignmentScores["rfp"]
        $script:GapCounts.Total += $RfpData.PendingItems
        if ($rfpGap -gt 50) {
            $script:GapCounts.Critical++
            $script:CriticalGaps += "RFP coverage only $($AlignmentScores["rfp"])%"
        } elseif ($rfpGap -gt 30) {
            $script:GapCounts.High++
            $script:HighGaps += "RFP coverage at $($AlignmentScores["rfp"])%"
        }
    }

    # Legacy migration gaps
    if ($AlignmentScores["legacy"] -lt 100 -and $ProjectContext.HasLegacy) {
        $legacyGap = 100 - $AlignmentScores["legacy"]
        $unmigrated = $LegacyData.Functions - $LegacyData.Migrated
        $script:GapCounts.Total += $unmigrated
        if ($legacyGap -gt 60) {
            $script:GapCounts.Critical++
            $script:CriticalGaps += "Legacy migration only $($AlignmentScores["legacy"])%"
        } elseif ($legacyGap -gt 30) {
            $script:GapCounts.High++
            $script:HighGaps += "Legacy migration at $($AlignmentScores["legacy"])%"
        }
    }

    # Methodology gaps
    if ($AlignmentScores["methodology"] -lt 80) {
        $script:GapCounts.Total += $MethodData.Missing.Count
        foreach ($missing in $MethodData.Missing) {
            $script:GapCounts.Medium++
        }
    }

    # Testing gaps
    if ($AlignmentScores["testing"] -lt 80) {
        $script:GapCounts.High++
        $script:HighGaps += "Test coverage at $($AlignmentScores["testing"])% (target: 80%)"
    }

    # Documentation gaps
    if ($AlignmentScores["documentation"] -lt 60) {
        $script:GapCounts.Low++
    }

    # Calculate overall alignment
    $scoreSum = 0
    $scoreCount = 0
    foreach ($key in @("rfp", "legacy", "methodology", "testing", "documentation", "infrastructure")) {
        if ($AlignmentScores.ContainsKey($key) -and $AlignmentScores[$key]) {
            $scoreSum += $AlignmentScores[$key]
            $scoreCount++
        }
    }

    if ($scoreCount -gt 0) {
        $script:AlignmentScores["overall"] = [math]::Floor($scoreSum / $scoreCount)
    } else {
        $script:AlignmentScores["overall"] = 0
    }

    # Generate recommendations
    if ($AlignmentScores["rfp"] -lt 50) {
        $script:Recommendations += @{
            Priority = "High"
            Action = "Create feature specs for uncovered RFP items"
            Command = "@Bolt Feature"
        }
    }
    if ($AlignmentScores["legacy"] -lt 50 -and $ProjectContext.HasLegacy) {
        $script:Recommendations += @{
            Priority = "High"
            Action = "Analyze and migrate legacy functions"
            Command = "@Bolt Analyze"
        }
    }
    if ($AlignmentScores["methodology"] -lt 60) {
        $script:Recommendations += @{
            Priority = "Medium"
            Action = "Complete missing methodology artifacts"
            Command = "@Bolt Specify"
        }
    }
    if ($AlignmentScores["testing"] -lt 80) {
        $script:Recommendations += @{
            Priority = "High"
            Action = "Improve test coverage"
            Command = "@Bolt Testing"
        }
    }
}

# ============================================================================
# Report Generation
# ============================================================================

function Show-SummaryReport {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData,
        [hashtable]$MethodData
    )

    Write-Header "🎯 Bolt Framework Alignment Analysis"

    Write-Host "Project Type: " -NoNewline
    Write-Host $ProjectContext.Type -ForegroundColor White -NoNewline
    Write-Host " | Scope: " -NoNewline
    Write-Host $ProjectContext.Scope -ForegroundColor White

    if ($ProjectContext.MigrationStrategy) {
        Write-Host "Migration Strategy: " -NoNewline
        Write-Host $ProjectContext.MigrationStrategy -ForegroundColor White
    }

    Write-Host "Has RFP: " -NoNewline
    Write-Host $ProjectContext.HasRfp -ForegroundColor White -NoNewline
    Write-Host " | Has Legacy: " -NoNewline
    Write-Host $ProjectContext.HasLegacy -ForegroundColor White
    Write-Host ""

    Write-Section "Overall Alignment: $($AlignmentScores["overall"])%"
    Write-Host (Get-ProgressBar $AlignmentScores["overall"])
    Write-Host ""

    # Dimensions table
    Write-Host "| Dimension            | Score                        | Status |"
    Write-Host "|---------------------|------------------------------|--------|"

    $dimensions = @(
        @{ Key = "rfp"; Label = "RFP Coverage"; ShowIf = $ProjectContext.HasRfp }
        @{ Key = "legacy"; Label = "Legacy Migration"; ShowIf = $ProjectContext.HasLegacy }
        @{ Key = "methodology"; Label = "Bolt Framework Methodology"; ShowIf = $true }
        @{ Key = "testing"; Label = "Testing"; ShowIf = $true }
        @{ Key = "documentation"; Label = "Documentation"; ShowIf = $true }
        @{ Key = "infrastructure"; Label = "Infrastructure"; ShowIf = $true }
    )

    foreach ($dim in $dimensions) {
        if (-not $dim.ShowIf) { continue }
        $score = $AlignmentScores[$dim.Key]
        if ($null -eq $score) { $score = 0 }
        $status = Get-StatusIcon $score
        $bar = Get-ProgressBar $score
        Write-Host ("| {0,-19} | {1,-28} | {2}      |" -f $dim.Label, $bar, $status)
    }

    Write-Host ""

    Write-Section "Gap Summary"

    Write-Host "| Priority     | Count |"
    Write-Host "|-------------|-------|"
    Write-Host "| 🔴 Critical | $($GapCounts.Critical)     |"
    Write-Host "| 🟠 High     | $($GapCounts.High)     |"
    Write-Host "| 🟡 Medium   | $($GapCounts.Medium)     |"
    Write-Host "| 🟢 Low      | $($GapCounts.Low)     |"
    Write-Host "| **Total**   | **$($GapCounts.Total)**   |"
    Write-Host ""

    if ($CriticalGaps.Count -gt 0) {
        Write-Section "🔴 Critical Gaps"
        foreach ($gap in $CriticalGaps) {
            Write-Host "  - $gap" -ForegroundColor Red
        }
        Write-Host ""
    }

    if ($HighGaps.Count -gt 0) {
        Write-Section "🟠 High Priority Gaps"
        foreach ($gap in $HighGaps) {
            Write-Host "  - $gap" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Section "🎯 Recommended Actions"

    if ($Recommendations.Count -gt 0) {
        Write-Host "| # | Priority | Action                                    | Command           |"
        Write-Host "|---|----------|-------------------------------------------|-------------------|"
        $i = 1
        foreach ($rec in $Recommendations) {
            Write-Host ("| {0} | {1,-8} | {2,-41} | ``{3}``             |" -f $i, $rec.Priority, $rec.Action, $rec.Command)
            $i++
        }
    } else {
        Write-Host "No critical actions needed. Project is well-aligned!" -ForegroundColor Green
    }
}

function Show-FullReport {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData,
        [hashtable]$MethodData
    )

    Show-SummaryReport -ProjectContext $ProjectContext -RfpData $RfpData -LegacyData $LegacyData -MethodData $MethodData

    if ($ProjectContext.HasRfp -and $RfpData.Documents.Count -gt 0) {
        Write-Section "📄 RFP Coverage Detail"

        Write-Host "| Document                  | Items | Covered | Coverage |"
        Write-Host "|--------------------------|-------|---------|----------|"
        foreach ($doc in $RfpData.Documents) {
            Write-Host ("| {0,-24} | {1,-5} | {2,-7} | {3}%      |" -f $doc.Name, $doc.Items, $doc.Covered, $doc.Coverage)
        }
        Write-Host ("| **TOTAL**                | **{0}** | **{1}** | **{2}%** |" -f $RfpData.TotalItems, $RfpData.CoveredItems, $AlignmentScores["rfp"])
        Write-Host ""

        if ($RfpData.Uncovered.Count -gt 0) {
            Write-Host "**Uncovered Items:**" -ForegroundColor Yellow
            foreach ($item in $RfpData.Uncovered) {
                Write-Host "  - $item"
            }
            Write-Host ""
        }
    }

    if ($ProjectContext.HasLegacy -and $LegacyData.Files -gt 0) {
        Write-Section "📦 Legacy Code Migration"

        Write-Host "| Language | Files | Lines  | Functions | Migrated |"
        Write-Host "|----------|-------|--------|-----------|----------|"
        foreach ($lang in $LegacyData.ByLanguage) {
            Write-Host ("| {0,-8} | {1,-5} | {2,-6} | {3,-9} | -        |" -f $lang.Language, $lang.Files, $lang.Lines, $lang.Functions)
        }
        Write-Host ("| **TOTAL** | **{0}** | **{1}** | **{2}** | **{3}** |" -f $LegacyData.Files, $LegacyData.Lines, $LegacyData.Functions, $LegacyData.Migrated)
        Write-Host ""
        Write-Host "Migration Progress: $(Get-ProgressBar $AlignmentScores["legacy"])"
        Write-Host ""
    }

    Write-Section "📋 Bolt Framework Methodology Compliance"

    Write-Host "| Phase     | Artifacts           | Compliance |"
    Write-Host "|-----------|---------------------|------------|"
    foreach ($phase in $MethodData.PhaseScores) {
        $status = Get-StatusIcon $phase.Score
        Write-Host ("| {0,-9} | {1,-19} | {2}% {3}     |" -f $phase.Phase, $phase.Artifacts, $phase.Score, $status)
    }
    Write-Host ""

    if ($MethodData.Missing.Count -gt 0) {
        Write-Host "**Missing Elements:**" -ForegroundColor Yellow
        foreach ($missing in $MethodData.Missing) {
            Write-Host "  - $missing"
        }
    }
}

function Get-JsonReport {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData
    )

    $report = @{
        project = @{
            type = $ProjectContext.Type
            scope = $ProjectContext.Scope
            migrationStrategy = $ProjectContext.MigrationStrategy
            hasRfp = $ProjectContext.HasRfp
            hasLegacy = $ProjectContext.HasLegacy
        }
        alignment = @{
            overall = $AlignmentScores["overall"]
            rfp = $AlignmentScores["rfp"]
            legacy = $AlignmentScores["legacy"]
            methodology = $AlignmentScores["methodology"]
            testing = $AlignmentScores["testing"]
            documentation = $AlignmentScores["documentation"]
            infrastructure = $AlignmentScores["infrastructure"]
        }
        gaps = @{
            total = $GapCounts.Total
            critical = $GapCounts.Critical
            high = $GapCounts.High
            medium = $GapCounts.Medium
            low = $GapCounts.Low
        }
        rfp = @{
            totalItems = $RfpData.TotalItems
            coveredItems = $RfpData.CoveredItems
            pendingItems = $RfpData.PendingItems
        }
        legacy = @{
            files = $LegacyData.Files
            lines = $LegacyData.Lines
            functions = $LegacyData.Functions
            migrated = $LegacyData.Migrated
        }
        generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }

    return $report | ConvertTo-Json -Depth 5
}

function New-Baseline {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData
    )

    $baselineDir = Join-Path $ProjectRoot "memory/baselines"
    if (-not (Test-Path $baselineDir)) {
        New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd"
    $baselineFile = Join-Path $baselineDir "alignment_$timestamp.json"

    $json = Get-JsonReport -ProjectContext $ProjectContext -RfpData $RfpData -LegacyData $LegacyData
    $json | Out-File -FilePath $baselineFile -Encoding UTF8

    Write-Success "Baseline created: $baselineFile"
}

function Compare-Baseline {
    param(
        [string]$BaselineFile
    )

    if (-not (Test-Path $BaselineFile)) {
        Write-Error "Baseline file not found: $BaselineFile"
        return
    }

    $prev = Get-Content $BaselineFile | ConvertFrom-Json
    $prevDate = $prev.generatedAt -replace "T.*", ""

    Write-Header "📊 Alignment Comparison"

    Write-Host "Comparing with baseline: $prevDate"
    Write-Host ""

    Write-Host "| Dimension        | Previous | Current | Delta   |"
    Write-Host "|------------------|----------|---------|---------|"

    $comparisons = @(
        @{ Label = "Overall"; Prev = $prev.alignment.overall; Curr = $AlignmentScores["overall"] }
        @{ Label = "RFP Coverage"; Prev = $prev.alignment.rfp; Curr = $AlignmentScores["rfp"] }
        @{ Label = "Legacy Migration"; Prev = $prev.alignment.legacy; Curr = $AlignmentScores["legacy"] }
        @{ Label = "Methodology"; Prev = $prev.alignment.methodology; Curr = $AlignmentScores["methodology"] }
        @{ Label = "Testing"; Prev = $prev.alignment.testing; Curr = $AlignmentScores["testing"] }
    )

    foreach ($comp in $comparisons) {
        $delta = $comp.Curr - $comp.Prev
        $sign = if ($delta -gt 0) { "+" } else { "" }
        $color = if ($delta -gt 0) { "Green" } elseif ($delta -lt 0) { "Red" } else { "White" }
        Write-Host ("| {0,-16} | {1,-8}% | {2,-7}% | " -f $comp.Label, $comp.Prev, $comp.Curr) -NoNewline
        Write-Host ("{0}{1}%    |" -f $sign, $delta) -ForegroundColor $color
    }
}

function Save-Report {
    param(
        [hashtable]$ProjectContext,
        [hashtable]$RfpData,
        [hashtable]$LegacyData,
        [hashtable]$MethodData
    )

    $analysisDir = Join-Path $ProjectRoot "memory/analysis"
    if (-not (Test-Path $analysisDir)) {
        New-Item -ItemType Directory -Path $analysisDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $analysisDir "alignment_$timestamp.md"

    $reportContent = @"
# Alignment Analysis Report

**Generated**: $(Get-Date)

## Overall Alignment: $($AlignmentScores["overall"])%

| Dimension | Score |
|-----------|-------|
| RFP Coverage | $($AlignmentScores["rfp"])% |
| Legacy Migration | $($AlignmentScores["legacy"])% |
| Methodology | $($AlignmentScores["methodology"])% |
| Testing | $($AlignmentScores["testing"])% |
| Documentation | $($AlignmentScores["documentation"])% |
| Infrastructure | $($AlignmentScores["infrastructure"])% |

## Gap Summary

- Critical: $($GapCounts.Critical)
- High: $($GapCounts.High)
- Medium: $($GapCounts.Medium)
- Low: $($GapCounts.Low)
- **Total**: $($GapCounts.Total)
"@

    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8

    Write-Success "Report saved: $reportFile"
}

# ============================================================================
# Main
# ============================================================================

function Main {
    # Run all analyses
    $projectContext = Get-ProjectContext
    $rfpData = Get-RfpCoverage
    $legacyData = Get-LegacyMigrationStatus
    $methodData = Get-MethodologyCompliance
    Get-TestingStatus
    Get-DocumentationStatus
    Get-InfrastructureStatus
    Get-GapAnalysis -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData -MethodData $methodData

    # Handle special modes
    if ($CreateBaseline) {
        New-Baseline -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData
        return
    }

    if ($CompareTo) {
        Compare-Baseline -BaselineFile $CompareTo
        return
    }

    # Generate output
    if ($AsJson) {
        Get-JsonReport -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData
    }
    elseif ($Full) {
        Show-FullReport -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData -MethodData $methodData
    }
    elseif ($RfpOnly) {
        Write-Header "RFP Coverage Analysis"
        Write-Host "Coverage: $(Get-ProgressBar $AlignmentScores["rfp"])"
    }
    elseif ($LegacyOnly) {
        Write-Header "Legacy Migration Analysis"
        Write-Host "Progress: $(Get-ProgressBar $AlignmentScores["legacy"])"
    }
    elseif ($MethodologyOnly) {
        Write-Header "Methodology Compliance"
        foreach ($phase in $methodData.PhaseScores) {
            Write-Host "$($phase.Phase): $($phase.Score)%"
        }
    }
    elseif ($GapsOnly) {
        Write-Header "Gap Analysis"
        Write-Host "Critical: $($GapCounts.Critical) | High: $($GapCounts.High) | Medium: $($GapCounts.Medium) | Low: $($GapCounts.Low)"
    }
    else {
        Show-SummaryReport -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData -MethodData $methodData
    }

    # Save if requested
    if ($SaveReport) {
        Save-Report -ProjectContext $projectContext -RfpData $rfpData -LegacyData $legacyData -MethodData $methodData
    }
}

# Run main
Main
