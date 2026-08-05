<#
.SYNOPSIS
    Shared environment variable loader for Azure DevOps sync scripts (PowerShell)

.DESCRIPTION
    Reads .env file from the project root, populates $env: variables (if not
    already set), builds the standard $script:Config hashtable, and validates
    that the PAT token is present.

    All PowerShell scripts should dot-source this file at the top:

        . "$PSScriptRoot\_EnvLoader.ps1"

    After sourcing, $script:Config is available with these keys:
      Organization, Project, AreaPath, Iteration, RequiredTag

    Environment-variable / .env precedence:
      1. Already-set $env:VAR  (CLI or parent shell)
      2. Value from .env file
      3. Built-in default

.NOTES
    Mirrors the same behaviour as _env-loader.sh (bash).
    See templates/template.env for the full variable reference.
#>

# =============================================================================
# Resolve project root (4 levels up from scripts/powershell/)
# =============================================================================

$_loaderDir  = $PSScriptRoot
$_projectRoot = (Resolve-Path (Join-Path $_loaderDir "..\..\..\.." )).Path

# =============================================================================
# Load .env file (skip comments and blank lines; don't overwrite existing vars)
# =============================================================================

$_envFile = Join-Path $_projectRoot ".env"

if (Test-Path $_envFile) {
    Get-Content $_envFile | ForEach-Object {
        $line = $_.Trim()

        # Skip blank lines and comments
        if (-not $line -or $line.StartsWith('#')) { return }

        $eqIndex = $line.IndexOf('=')
        if ($eqIndex -le 0) { return }

        $key   = $line.Substring(0, $eqIndex).Trim()
        $value = $line.Substring($eqIndex + 1).Trim()

        # Only set if the variable is not already defined in the environment
        if (-not [System.Environment]::GetEnvironmentVariable($key)) {
            [System.Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
}

# =============================================================================
# Configuration with defaults (env vars override defaults)
# =============================================================================

function _Default([string]$EnvVar, [string]$Fallback) {
    $val = [System.Environment]::GetEnvironmentVariable($EnvVar)
    if ($val) { return $val } else { return $Fallback }
}

$script:Config = @{
    Organization = _Default 'AZURE_DEVOPS_ORG'          ''
    Project      = _Default 'AZURE_DEVOPS_PROJECT'      ''
    AreaPath     = _Default 'AZURE_DEVOPS_AREA_PATH'    ''
    Iteration    = _Default 'AZURE_DEVOPS_ITERATION'    ''
    RequiredTag  = _Default 'AZURE_DEVOPS_REQUIRED_TAG' 'Bolt Framework'
}

# =============================================================================
# Validation
# =============================================================================

if (-not $env:AZURE_DEVOPS_EXT_PAT) {
    Write-Host "❌ Missing required environment variable: AZURE_DEVOPS_EXT_PAT" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set it before running any script:" -ForegroundColor Yellow
    Write-Host '  $env:AZURE_DEVOPS_EXT_PAT = "your-pat-token"' -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or add it to .env at the project root (never commit this file)." -ForegroundColor Yellow
    Write-Host "See template: .claude/skills/azure-devops-sync/templates/template.env" -ForegroundColor Yellow
    throw "AZURE_DEVOPS_EXT_PAT is not set. Cannot continue."
}

# =============================================================================
# Shared helper: Write-StatusMessage (avoids duplication in every script)
# =============================================================================

function Write-StatusMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info"    { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
    }

    $prefix = switch ($Type) {
        "Info"    { "ℹ️" }
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error"   { "❌" }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}
