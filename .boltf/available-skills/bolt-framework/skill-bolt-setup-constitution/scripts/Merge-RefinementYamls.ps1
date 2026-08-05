<#
.SYNOPSIS
    Merge all scope refinement YAML files into a single merged-refinement.yaml

.DESCRIPTION
    This script collects all *-refinement.yaml files from the refinement-states
    directory and merges them into a unified merged-refinement.yaml file.

    It automatically detects conflicts (same article appearing in multiple scopes)
    and calculates summary statistics.

.PARAMETER ProjectPath
    Path to the Bolt Framework project root (default: current directory)

.PARAMETER Force
    Overwrite existing merged-refinement.yaml without prompting

.EXAMPLE
    .\Merge-RefinementYamls.ps1 -ProjectPath ./my-project

.EXAMPLE
    .\Merge-RefinementYamls.ps1 -ProjectPath ./my-project -Force
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = ".",

    [switch]$Force
)

# ─── Logging ─────────────────────────────────────────────────────────────────
function Write-Info    { param([string]$M) Write-Host "[INFO] $M" -ForegroundColor Blue }
function Write-Success { param([string]$M) Write-Host "[OK]   $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }
function Write-Err     { param([string]$M) Write-Host "[ERR]  $M" -ForegroundColor Red }

# ─── Simple YAML Parser ──────────────────────────────────────────────────────
function ConvertFrom-SimpleYaml {
    param([string]$Content)

    # Simple YAML parser for our use case
    # For production, consider using PowerShell-Yaml module
    $lines = $Content -split "`n"
    $result = @{}
    $currentArray = $null

    foreach ($line in $lines) {
        $line = $line.TrimEnd()

        # Skip comments and empty lines
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Section headers (no indentation)
        if ($line -match '^(\w+):(.*)$') {
            $key = $matches[1]
            $value = $matches[2].Trim()

            if ([string]::IsNullOrWhiteSpace($value)) {
                # This is a section start
                $result[$key] = @()
                $currentArray = $result[$key]
            } else {
                # Simple key-value
                $result[$key] = $value
            }
        }
        # Array items
        elseif ($line -match '^\s+-\s+(.+)$') {
            if ($null -ne $currentArray) {
                $currentArray += $matches[1].Trim()
            }
        }
    }

    return $result
}

# ─── Main Script ─────────────────────────────────────────────────────────────

Write-Info "Bolt Framework - Merge Refinement YAMLs v1.0.0"
Write-Info "Project path: $ProjectPath"
Write-Host ""

# Validate project path
if (-not (Test-Path $ProjectPath)) {
    Write-Err "Project path does not exist: $ProjectPath"
    exit 1
}

$refinementStatesDir = Join-Path $ProjectPath ".boltf\memory\refinement-states"

if (-not (Test-Path $refinementStatesDir)) {
    Write-Err "Refinement states directory not found: $refinementStatesDir"
    Write-Err "Run constitution refinement first"
    exit 1
}

# Find all scope refinement files (exclude merged-refinement.yaml)
$refinementFiles = Get-ChildItem -Path $refinementStatesDir -Filter "*-refinement.yaml" |
    Where-Object { $_.Name -ne "merged-refinement.yaml" }

if ($refinementFiles.Count -eq 0) {
    Write-Err "No refinement YAML files found in: $refinementStatesDir"
    exit 1
}

Write-Info "Found $($refinementFiles.Count) scope refinement file(s):"
foreach ($file in $refinementFiles) {
    Write-Info "  • $($file.Name)"
}
Write-Host ""

# Check if merged file already exists
$mergedPath = Join-Path $refinementStatesDir "merged-refinement.yaml"
if ((Test-Path $mergedPath) -and -not $Force) {
    Write-Warn "merged-refinement.yaml already exists"
    $response = Read-Host "Overwrite? (y/N)"
    if ($response.ToLower() -ne 'y') {
        Write-Info "Merge cancelled"
        exit 0
    }
}

# ─── Load and merge all refinement files ─────────────────────────────────────

Write-Info "Loading and merging refinement files..."

$mergedData = @{
    scopes = @()
    total_scopes = 0
    total_articles = 0
    total_decisions = 0
    merge_timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    conflicts = @()
}

$articleRegistry = @{}  # Track articles across scopes for conflict detection

foreach ($file in $refinementFiles) {
    $scopeName = $file.BaseName -replace '-refinement$', ''
    Write-Info "Processing scope: $scopeName"

    try {
        # Load YAML content (using simple parser or full YAML if available)
        $content = Get-Content $file.FullName -Raw

        # Try to use PowerShell-Yaml if available, otherwise use simple parser
        try {
            Import-Module powershell-yaml -ErrorAction Stop
            $scopeData = ConvertFrom-Yaml $content
        }
        catch {
            # Fallback to simple parser
            $scopeData = ConvertFrom-SimpleYaml $content
        }

        # Extract article count and decisions
        $articleCount = 0
        $decisionCount = 0

        if ($scopeData.constitution -and $scopeData.constitution.articles) {
            $articleCount = $scopeData.constitution.articles.Count
            $decisionCount = ($scopeData.constitution.articles |
                Where-Object { $_.decisions -ne $null }).Count
        }

        # Add scope to merged data
        $scopeEntry = @{
            scope = $scopeName
            articles_count = $articleCount
            decisions_count = $decisionCount
            data = $scopeData
        }

        $mergedData.scopes += $scopeEntry
        $mergedData.total_articles += $articleCount
        $mergedData.total_decisions += $decisionCount

        # Track articles for conflict detection
        if ($scopeData.constitution -and $scopeData.constitution.articles) {
            foreach ($article in $scopeData.constitution.articles) {
                $articleId = $article.article
                if (-not $articleRegistry.ContainsKey($articleId)) {
                    $articleRegistry[$articleId] = @()
                }
                $articleRegistry[$articleId] += $scopeName
            }
        }

        Write-Success "  Added $articleCount articles, $decisionCount decisions"
    }
    catch {
        Write-Err "  Failed to load $($file.Name): $_"
    }
}

$mergedData.total_scopes = $mergedData.scopes.Count

# ─── Detect conflicts ────────────────────────────────────────────────────────

Write-Host ""
Write-Info "Detecting conflicts..."

$conflictCount = 0
foreach ($articleId in $articleRegistry.Keys) {
    $scopes = $articleRegistry[$articleId]
    if ($scopes.Count -gt 1) {
        $conflict = @{
            article = $articleId
            scopes = $scopes
            resolution = "pending"
        }
        $mergedData.conflicts += $conflict
        $conflictCount++
        Write-Warn "  Conflict: $articleId appears in: $($scopes -join ', ')"
    }
}

if ($conflictCount -eq 0) {
    Write-Success "No conflicts detected"
}

# ─── Write merged YAML ───────────────────────────────────────────────────────

Write-Host ""
Write-Info "Writing merged-refinement.yaml..."

$yamlContent = @"
# =============================================================================
# Bolt Framework - Merged Refinement State
# Generated: $($mergedData.merge_timestamp)
# =============================================================================
# This file contains the merged refinement decisions from all active scopes.
# Used by constitution generation phase to create the final constitution.md
# =============================================================================

# Summary Statistics
total_scopes: $($mergedData.total_scopes)
total_articles: $($mergedData.total_articles)
total_decisions: $($mergedData.total_decisions)
merge_timestamp: $($mergedData.merge_timestamp)
has_conflicts: $($conflictCount -gt 0)

# Scopes
scopes:
"@

foreach ($scopeEntry in $mergedData.scopes) {
    $yamlContent += @"

  - scope: $($scopeEntry.scope)
    articles_count: $($scopeEntry.articles_count)
    decisions_count: $($scopeEntry.decisions_count)
    source_file: $($scopeEntry.scope)-refinement.yaml
"@
}

if ($conflictCount -gt 0) {
    $yamlContent += "`n`n# Conflicts (articles appearing in multiple scopes)"
    $yamlContent += "`nconflicts:"
    foreach ($conflict in $mergedData.conflicts) {
        $yamlContent += "`n  - article: `"$($conflict.article)`""
        $yamlContent += "`n    scopes: [$($conflict.scopes -join ', ')]"
        $yamlContent += "`n    resolution: $($conflict.resolution)"
    }
}

$yamlContent += @"

`n
# =============================================================================
# Detailed Scope Data
# =============================================================================
# Each scope's full refinement data is preserved below for reference.
# The constitution generator will merge these based on the summary above.
# =============================================================================

scope_data:
"@

foreach ($scopeEntry in $mergedData.scopes) {
    $scopeFile = Join-Path $refinementStatesDir "$($scopeEntry.scope)-refinement.yaml"
    $scopeContent = Get-Content $scopeFile -Raw

    $yamlContent += "`n`n  # Scope: $($scopeEntry.scope)"
    $yamlContent += "`n  $($scopeEntry.scope):"

    # Indent the scope content
    $indentedContent = ($scopeContent -split "`n" | ForEach-Object { "    $_" }) -join "`n"
    $yamlContent += "`n$indentedContent"
}

# Write to file
Set-Content -Path $mergedPath -Value $yamlContent -Encoding UTF8

Write-Success "Merged refinement file created: merged-refinement.yaml"
Write-Host ""
Write-Info "Summary:"
Write-Info "  • Scopes merged: $($mergedData.total_scopes)"
Write-Info "  • Total articles: $($mergedData.total_articles)"
Write-Info "  • Total decisions: $($mergedData.total_decisions)"
Write-Info "  • Conflicts detected: $conflictCount"
Write-Host ""
Write-Success "Merge complete!"
