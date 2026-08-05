<#
.SYNOPSIS
    Sorts constitution articles by criticality (high, medium, low)

.DESCRIPTION
    Reads a YAML file containing constitution articles and outputs a new YAML
    with articles sorted by criticality: high first, then medium, then low.

.PARAMETER InputFile
    Path to the input YAML file

.PARAMETER OutputFile
    Path to the output YAML file (default: input file with .sorted.yaml suffix)

.EXAMPLE
    .\Sort-ConstitutionByCriticality.ps1 -InputFile .\refinement-state.yaml
    .\Sort-ConstitutionByCriticality.ps1 -InputFile .\state.yaml -OutputFile .\sorted.yaml
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

# Install powershell-yaml if not available
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing powershell-yaml module..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module powershell-yaml

# Verify input file exists
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

# Determine output file path
if (-not $OutputFile) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $directory = [System.IO.Path]::GetDirectoryName($InputFile)
    if ([string]::IsNullOrEmpty($directory)) {
        $directory = "."
    }
    $OutputFile = Join-Path $directory "$baseName.sorted.yaml"
}

Write-Host "Reading YAML from: $InputFile" -ForegroundColor Cyan

# Read the YAML file
$yamlContent = Get-Content -Path $InputFile -Raw
$data = ConvertFrom-Yaml $yamlContent

# Check if constitution and articles exist
if (-not $data.constitution) {
    Write-Error "No 'constitution' key found in YAML"
    exit 1
}

if (-not $data.constitution.articles) {
    Write-Warning "No 'articles' array found in constitution"
    $data | ConvertTo-Yaml | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Host "Output written to: $OutputFile" -ForegroundColor Green
    exit 0
}

# Define criticality order
$criticalityOrder = @{
    'high'   = 1
    'medium' = 2
    'low'    = 3
}

Write-Host "Sorting $($data.constitution.articles.Count) articles by criticality..." -ForegroundColor Cyan

# Sort articles by criticality
$sortedArticles = $data.constitution.articles | Sort-Object {
    $crit = $_.criticallity
    if ([string]::IsNullOrEmpty($crit)) {
        return 999  # Put items without criticality at the end
    }
    $order = $criticalityOrder[$crit.ToLower()]
    if ($null -eq $order) {
        return 999  # Unknown criticality goes to the end
    }
    return $order
}

# Replace articles with sorted version
$data.constitution.articles = $sortedArticles

# Convert back to YAML and save
Write-Host "Writing sorted YAML to: $OutputFile" -ForegroundColor Cyan
$data | ConvertTo-Yaml | Set-Content -Path $OutputFile -Encoding UTF8

# Summary
$highCount = ($sortedArticles | Where-Object { $_.criticallity -eq 'high' }).Count
$mediumCount = ($sortedArticles | Where-Object { $_.criticallity -eq 'medium' }).Count
$lowCount = ($sortedArticles | Where-Object { $_.criticallity -eq 'low' }).Count
$unknownCount = ($sortedArticles | Where-Object { [string]::IsNullOrEmpty($_.criticallity) -or ($_.criticallity -notin @('high', 'medium', 'low')) }).Count

Write-Host "`nSorting complete!" -ForegroundColor Green
Write-Host "  High:    $highCount articles" -ForegroundColor Red
Write-Host "  Medium:  $mediumCount articles" -ForegroundColor Yellow
Write-Host "  Low:     $lowCount articles" -ForegroundColor Gray
if ($unknownCount -gt 0) {
    Write-Host "  Unknown: $unknownCount articles" -ForegroundColor Magenta
}
Write-Host "`nOutput file: $OutputFile" -ForegroundColor Green
