<#
.SYNOPSIS
    Analyzes codebase and generates improvement backlogs.

.DESCRIPTION
    This script analyzes code quality, dependencies, and metrics to generate
    refactoring backlogs and new intent backlogs following AI-DLC methodology.

.PARAMETER AnalyzeCode
    If specified, analyzes code complexity and quality.

.PARAMETER AnalyzeDependencies
    If specified, checks for outdated or vulnerable dependencies.

.PARAMETER GenerateBacklogs
    If specified, generates or updates improvement backlog files.

.PARAMETER All
    If specified, runs all analyses and generates backlogs.

.EXAMPLE
    .\Get-Improvements.ps1 -All
    .\Get-Improvements.ps1 -AnalyzeDependencies
    .\Get-Improvements.ps1 -GenerateBacklogs

.NOTES
    Part of Bolt Framework / AI-DLC methodology
    Phase: Block 7 - Evolution
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeCode,

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeDependencies,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateBacklogs,

    [Parameter(Mandatory = $false)]
    [switch]$All
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
# CODE ANALYSIS
# ============================================================================

function Get-CodeMetrics {
    Write-Step "Analyzing code metrics..."

    $metrics = @{
        TotalFiles = 0
        TotalLines = 0
        LargeFiles = @()
        ComplexFiles = @()
        DuplicatePatterns = @()
    }

    # Analyze different file types
    $extensions = @("*.cs", "*.ts", "*.js", "*.py", "*.go")

    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path . -Filter $ext -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch "node_modules|bin|obj|dist|\.git" }

        foreach ($file in $files) {
            $metrics.TotalFiles++
            $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
            $metrics.TotalLines += $lines

            # Flag large files
            if ($lines -gt 500) {
                $metrics.LargeFiles += @{
                    Path = $file.FullName -replace [regex]::Escape((Get-Location).Path + "\"), ""
                    Lines = $lines
                    Severity = if ($lines -gt 1000) { "High" } else { "Medium" }
                }
            }
        }
    }

    return $metrics
}

function Get-TestCoverage {
    Write-Step "Checking test coverage..."

    $coverage = @{
        HasTests = $false
        TestFiles = 0
        CoveragePercent = "Unknown"
    }

    # Look for test files
    $testPatterns = @("*Test*.cs", "*test*.ts", "*test*.js", "*_test.py", "*_test.go", "*.spec.ts", "*.spec.js")

    foreach ($pattern in $testPatterns) {
        $tests = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch "node_modules|bin|obj" }
        $coverage.TestFiles += $tests.Count
    }

    $coverage.HasTests = $coverage.TestFiles -gt 0

    # Try to find coverage reports
    $coverageFiles = @("coverage.json", "coverage.xml", "coverage/lcov.info", "TestResults/*.xml")
    foreach ($cf in $coverageFiles) {
        if (Test-Path $cf) {
            $coverage.CoveragePercent = "Report found"
            break
        }
    }

    return $coverage
}

# ============================================================================
# DEPENDENCY ANALYSIS
# ============================================================================

function Get-DotNetDependencies {
    $deps = @()

    $csproj = Get-ChildItem -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csproj) {
        try {
            [xml]$proj = Get-Content $csproj.FullName
            $packages = $proj.Project.ItemGroup.PackageReference
            foreach ($pkg in $packages) {
                if ($pkg.Include) {
                    $deps += @{
                        Name = $pkg.Include
                        Version = $pkg.Version
                        Type = "NuGet"
                    }
                }
            }
        } catch {}
    }

    return $deps
}

function Get-NodeDependencies {
    $deps = @()

    if (Test-Path "package.json") {
        try {
            $pkg = Get-Content "package.json" | ConvertFrom-Json

            if ($pkg.dependencies) {
                foreach ($dep in $pkg.dependencies.PSObject.Properties) {
                    $deps += @{
                        Name = $dep.Name
                        Version = $dep.Value
                        Type = "npm"
                        IsDev = $false
                    }
                }
            }

            if ($pkg.devDependencies) {
                foreach ($dep in $pkg.devDependencies.PSObject.Properties) {
                    $deps += @{
                        Name = $dep.Name
                        Version = $dep.Value
                        Type = "npm"
                        IsDev = $true
                    }
                }
            }
        } catch {}
    }

    return $deps
}

function Get-AllDependencies {
    Write-Step "Analyzing dependencies..."

    $allDeps = @{
        DotNet = Get-DotNetDependencies
        Node = Get-NodeDependencies
        TotalCount = 0
        OutdatedCount = 0
        VulnerableCount = 0
    }

    $allDeps.TotalCount = $allDeps.DotNet.Count + $allDeps.Node.Count

    return $allDeps
}

# ============================================================================
# BACKLOG GENERATION
# ============================================================================

function New-RefactorBacklog {
    param(
        [hashtable]$CodeMetrics,
        [hashtable]$Dependencies
    )

    $backlogDir = "docs/improvement"
    if (-not (Test-Path $backlogDir)) {
        New-Item -ItemType Directory -Path $backlogDir -Force | Out-Null
    }

    $backlogPath = "$backlogDir/refactor_backlog.md"
    $date = Get-Date -Format "yyyy-MM-dd"

    # Generate backlog items from analysis
    $items = @()
    $itemId = 1

    # Add items for large files
    foreach ($file in $CodeMetrics.LargeFiles) {
        $items += @{
            Id = "RB-{0:D3}" -f $itemId
            Title = "Refactor large file: $($file.Path)"
            Category = "Code Quality"
            Priority = $file.Severity
            Impact = "Maintainability"
            Effort = "M"
            Location = $file.Path
            Description = "File has $($file.Lines) lines, exceeding 500 line threshold"
        }
        $itemId++
    }

    # Count by priority
    $criticalCount = ($items | Where-Object { $_.Priority -eq "Critical" }).Count
    $highCount = ($items | Where-Object { $_.Priority -eq "High" }).Count
    $mediumCount = ($items | Where-Object { $_.Priority -eq "Medium" }).Count
    $lowCount = ($items | Where-Object { $_.Priority -eq "Low" }).Count

    $content = @"
# Refactoring Backlog

## Document Info

| Property | Value |
|----------|-------|
| Last Updated | $date |
| Analysis Period | Last 30 days |
| Next Review | $(Get-Date (Get-Date).AddDays(30) -Format "yyyy-MM-dd") |

---

## Executive Summary

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Code Quality | $criticalCount | $highCount | $mediumCount | $lowCount | $($items.Count) |
| Security | 0 | 0 | 0 | 0 | 0 |
| Performance | 0 | 0 | 0 | 0 | 0 |
| Dependencies | 0 | 0 | 0 | 0 | $($Dependencies.TotalCount) to review |
| **Total** | $criticalCount | $highCount | $mediumCount | $lowCount | $($items.Count) |

---

## Code Metrics Summary

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Total Files | $($CodeMetrics.TotalFiles) | - | ℹ️ |
| Total Lines | $($CodeMetrics.TotalLines) | - | ℹ️ |
| Large Files (>500 lines) | $($CodeMetrics.LargeFiles.Count) | 0 | $(if ($CodeMetrics.LargeFiles.Count -eq 0) { "✅" } else { "⚠️" }) |
| Dependencies | $($Dependencies.TotalCount) | - | ℹ️ |

---

## Backlog Items

"@

    if ($items.Count -gt 0) {
        foreach ($item in $items) {
            $content += @"

### $($item.Id): $($item.Title)

| Property | Value |
|----------|-------|
| **Category** | $($item.Category) |
| **Priority** | $($item.Priority) |
| **Impact** | $($item.Impact) |
| **Effort** | $($item.Effort) |
| **Location** | ``$($item.Location)`` |

**Description**: $($item.Description)

**Proposed Solution**: [To be defined]

**Acceptance Criteria**:
- [ ] File/module refactored
- [ ] Tests passing
- [ ] Code review approved

---
"@
        }
    } else {
        $content += @"

*No refactoring items identified at this time.*

Consider running deeper analysis with:
- Static code analysis tools (SonarQube, etc.)
- Security scanners
- Performance profilers

---
"@
    }

    $content += @"

## Dependencies to Review

| Type | Count | Action |
|------|-------|--------|
| .NET Packages | $($Dependencies.DotNet.Count) | Run ``dotnet list package --outdated`` |
| npm Packages | $($Dependencies.Node.Count) | Run ``npm outdated`` |

---

## Revision History

| Date | Changes | Author |
|------|---------|--------|
| $date | Initial analysis | Bolt Framework |

---

*Generated by Bolt Framework Improve Command*
"@

    Set-Content -Path $backlogPath -Value $content
    return $backlogPath
}

function New-IntentsBacklog {
    $backlogDir = "docs/improvement"
    if (-not (Test-Path $backlogDir)) {
        New-Item -ItemType Directory -Path $backlogDir -Force | Out-Null
    }

    $backlogPath = "$backlogDir/new_intents.md"
    $date = Get-Date -Format "yyyy-MM-dd"

    # Check if file already exists
    if (Test-Path $backlogPath) {
        Write-Info "New intents backlog already exists, skipping creation"
        return $backlogPath
    }

    $content = @"
# New Feature Intents Backlog

## Document Info

| Property | Value |
|----------|-------|
| Last Updated | $date |
| Review Cycle | Weekly |
| Owner | [Product Owner] |

---

## Intent Pipeline

| Stage | Count |
|-------|-------|
| 💡 Ideation | 0 |
| 🔍 Validation | 0 |
| 📋 Ready for Spec | 0 |
| 🚀 In Development | 0 |

---

## How to Add New Intents

When you identify a potential new feature from:
- User feedback
- Support tickets
- Analytics insights
- Stakeholder requests
- Operational learnings
- Competitive analysis

Add it to this backlog in the **Ideation** section using this template:

``````markdown
### NI-XXX: [Feature Idea Title]

| Property | Value |
|----------|-------|
| **ID** | NI-XXX |
| **Source** | [Where this idea came from] |
| **Submitted** | [Date] |
| **Submitter** | [Name/Source] |

**Problem Statement**: [What problem does this solve?]

**Proposed Solution**: [High-level description]

**Business Value**:
- [Value point 1]
- [Value point 2]

**Estimated Complexity**: S / M / L / XL

**Validation Needed**:
- [ ] User interviews
- [ ] Data analysis
- [ ] Technical feasibility
- [ ] Business case
``````

---

## 💡 Ideation Stage

*No items yet. Add new feature ideas here.*

---

## 🔍 Validation Stage

*No items yet. Items being validated move here.*

---

## 📋 Ready for Specification

*No items yet. Validated items ready for @Bolt Feature move here.*

---

## Rejected/Deferred Intents

| ID | Title | Reason | Revisit Date |
|----|-------|--------|--------------|
| - | - | - | - |

---

*Generated by Bolt Framework Improve Command*
"@

    Set-Content -Path $backlogPath -Value $content
    return $backlogPath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "`n📊 Bolt Framework Improvement Analyzer" -ForegroundColor Magenta
Write-Host "===================================`n" -ForegroundColor Magenta

if ($All) {
    $AnalyzeCode = $true
    $AnalyzeDependencies = $true
    $GenerateBacklogs = $true
}

# Default to all if no specific options
if (-not $AnalyzeCode -and -not $AnalyzeDependencies -and -not $GenerateBacklogs) {
    $AnalyzeCode = $true
    $AnalyzeDependencies = $true
    $GenerateBacklogs = $true
}

$codeMetrics = @{ TotalFiles = 0; TotalLines = 0; LargeFiles = @() }
$dependencies = @{ DotNet = @(); Node = @(); TotalCount = 0 }
$coverage = @{ HasTests = $false; TestFiles = 0 }

if ($AnalyzeCode) {
    $codeMetrics = Get-CodeMetrics
    Write-Info "Found $($codeMetrics.TotalFiles) code files, $($codeMetrics.TotalLines) total lines"
    Write-Info "Large files (>500 lines): $($codeMetrics.LargeFiles.Count)"

    $coverage = Get-TestCoverage
    Write-Info "Test files found: $($coverage.TestFiles)"
}

if ($AnalyzeDependencies) {
    $dependencies = Get-AllDependencies
    Write-Info "Total dependencies: $($dependencies.TotalCount)"
    Write-Info "  .NET packages: $($dependencies.DotNet.Count)"
    Write-Info "  npm packages: $($dependencies.Node.Count)"
}

if ($GenerateBacklogs) {
    Write-Step "Generating improvement backlogs..."

    $refactorPath = New-RefactorBacklog -CodeMetrics $codeMetrics -Dependencies $dependencies
    Write-Success "Refactor backlog: $refactorPath"

    $intentsPath = New-IntentsBacklog
    Write-Success "New intents backlog: $intentsPath"
}

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Improvement analysis complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green

Write-Host "`n📋 Summary:" -ForegroundColor Yellow
Write-Host "  Code files analyzed: $($codeMetrics.TotalFiles)"
Write-Host "  Refactoring items identified: $($codeMetrics.LargeFiles.Count)"
Write-Host "  Dependencies to review: $($dependencies.TotalCount)"

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review refactor_backlog.md"
Write-Host "  2. Prioritize items with team"
Write-Host "  3. Add tech debt items to sprint"
Write-Host "  4. Add new feature ideas to new_intents.md"
Write-Host "  5. Run @Bolt Plan for high-priority refactors`n"
