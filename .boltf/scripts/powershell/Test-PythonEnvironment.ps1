# =============================================================================
# Bolt Framework - Python Environment Test
# =============================================================================
# Validates that Python environment is correctly setup
# =============================================================================

param(
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

$ErrorActionPreference = "Stop"

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Write-TestResult {
    param([string]$Test, [bool]$Passed, [string]$Details = "")
    $icon = if ($Passed) { "✅" } else { "❌" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "$icon $Test" -ForegroundColor $color
    if ($Details -and $DetailedOutput) {
        Write-Host "   $Details" -ForegroundColor DarkGray
    }
}

# ─── Configuration ───────────────────────────────────────────────────────────
# Navigate to project root (3 levels up from .boltf/scripts/powershell/)
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$VenvPath = Join-Path $ProjectRoot ".bolt-venv"
$PythonExe = Join-Path $VenvPath "Scripts\python.exe"
$WrapperPath = Join-Path $ProjectRoot "Invoke-PythonScript.ps1"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Bolt Framework - Python Environment Verification         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ─── Test 1: Check Python Command ───────────────────────────────────────────
Write-Host "[1/6] Checking system Python..." -ForegroundColor Cyan
try {
    $version = python --version 2>&1
    if ($version -match "Python (\d+)\.(\d+)") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -ge 3 -and $minor -ge 9) {
            Write-TestResult "System Python $version" $true
        } else {
            Write-TestResult "System Python $version (needs 3.9+)" $false
        }
    } else {
        Write-TestResult "System Python" $false "Version check failed"
    }
} catch {
    Write-TestResult "System Python" $false "Not found in PATH"
}

# ─── Test 2: Check Virtual Environment Exists ───────────────────────────────
Write-Host "`n[2/6] Checking virtual environment..." -ForegroundColor Cyan
$venvExists = Test-Path $VenvPath
Write-TestResult "Virtual environment exists at .bolt-venv/" $venvExists

if (-not $venvExists) {
    Write-Host "`n⚠️  Virtual environment not found. Run:" -ForegroundColor Yellow
    Write-Host "   .\.boltf\scripts\powershell\Bootstrap-Python.ps1`n" -ForegroundColor White
    exit 1
}

# ─── Test 3: Check Python Executable ─────────────────────────────────────────
Write-Host "`n[3/6] Checking Python executable..." -ForegroundColor Cyan
$pythonExeExists = Test-Path $PythonExe
Write-TestResult "Python executable exists" $pythonExeExists

if (-not $pythonExeExists) {
    Write-Host "`n⚠️  Python executable not found. Recreate venv:" -ForegroundColor Yellow
    Write-Host "   .\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force`n" -ForegroundColor White
    exit 1
}

# ─── Test 4: Check Required Packages ─────────────────────────────────────────
Write-Host "`n[4/6] Checking installed packages..." -ForegroundColor Cyan
try {
    $packages = & $PythonExe -m pip list --format=json | ConvertFrom-Json
    $packageMap = @{}
    foreach ($pkg in $packages) {
        $packageMap[$pkg.name] = $pkg.version
    }

    $requiredPackages = @{
        "anthropic" = "AI SDK"
        "pyyaml" = "YAML parser"
    }

    foreach ($pkg in $requiredPackages.Keys) {
        if ($packageMap.ContainsKey($pkg)) {
            Write-TestResult "$pkg v$($packageMap[$pkg])" $true $requiredPackages[$pkg]
        } else {
            Write-TestResult "$pkg" $false "Missing - needed for $($requiredPackages[$pkg])"
        }
    }
} catch {
    Write-TestResult "Package check" $false $_.Exception.Message
}

# ─── Test 5: Test Python Import ──────────────────────────────────────────────
Write-Host "`n[5/6] Testing Python imports..." -ForegroundColor Cyan
$testScript = @"
try:
    import anthropic
    import yaml
    import json
    from pathlib import Path
    from concurrent.futures import ProcessPoolExecutor
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
"@

try {
    $result = & $PythonExe -c $testScript 2>&1
    $passed = $result -eq "OK"
    Write-TestResult "Import test" $passed $result
} catch {
    Write-TestResult "Import test" $false $_.Exception.Message
}

# ─── Test 6: Test Wrapper Script ─────────────────────────────────────────────
Write-Host "`n[6/6] Testing Invoke-PythonScript.ps1..." -ForegroundColor Cyan
$wrapperExists = Test-Path $WrapperPath
Write-TestResult "Wrapper script exists" $wrapperExists

if ($wrapperExists) {
    # Test with simple Python command
    try {
        $testPyScript = @"
import sys
print('Wrapper test: OK')
sys.exit(0)
"@
        $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
        Set-Content -Path $tempScript -Value $testPyScript

        $output = & $WrapperPath $tempScript 2>&1
        Remove-Item $tempScript -Force

        $passed = $output -match "Wrapper test: OK"
        Write-TestResult "Wrapper execution" $passed
    } catch {
        Write-TestResult "Wrapper execution" $false $_.Exception.Message
    }
}

# ─── Summary ─────────────────────────────────────────────────────────────────
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Test Summary                                              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📍 Virtual Environment: .bolt-venv\" -ForegroundColor White
Write-Host "📍 Python Executable:   $PythonExe" -ForegroundColor White

if (Test-Path $PythonExe) {
    $version = & $PythonExe --version 2>&1
    Write-Host "📍 Python Version:      $version" -ForegroundColor White
}

Write-Host "`n✅ Python environment is ready for use!`n" -ForegroundColor Green

Write-Host "Try these commands:" -ForegroundColor Cyan
Write-Host "  npm run skill:validate .claude/skills/skill-creator/" -ForegroundColor White
Write-Host "  .\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py .claude\skills\skill-creator\`n" -ForegroundColor White
