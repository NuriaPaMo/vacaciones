# =============================================================================
# Bolt Framework - Python Script Executor
# =============================================================================
# Convenience wrapper to execute Python scripts in the Bolt virtual environment
# =============================================================================

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs
)

$ErrorActionPreference = "Stop"

# ─── Configuration ───────────────────────────────────────────────────────────
$ProjectRoot = $PSScriptRoot
$VenvPath = Join-Path $ProjectRoot ".bolt-venv"
$ActivateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
$PythonExe = Join-Path $VenvPath "Scripts\python.exe"

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Write-Err { param([string]$M) Write-Host "[ERR]  $M" -ForegroundColor Red }

# ─── Validate Virtual Environment ───────────────────────────────────────────
if (-not (Test-Path $VenvPath)) {
    Write-Err "Python virtual environment not found: $VenvPath"
    Write-Host "Run: .\.boltf\scripts\powershell\Bootstrap-Python.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $PythonExe)) {
    Write-Err "Python executable not found: $PythonExe"
    Write-Host "Recreate venv: .\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force" -ForegroundColor Yellow
    exit 1
}

# ─── Validate Script Path ────────────────────────────────────────────────────
if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
    $ScriptPath = Join-Path $ProjectRoot $ScriptPath
}

if (-not (Test-Path $ScriptPath)) {
    Write-Err "Script not found: $ScriptPath"
    exit 1
}

# ─── Execute Script ──────────────────────────────────────────────────────────
$arguments = @($ScriptPath) + $ScriptArgs
& $PythonExe @arguments
exit $LASTEXITCODE
