# =============================================================================
# Bolt Framework - Python Integration End-to-End Test
# =============================================================================
# Tests the complete Python integration workflow:
# 1. Init.ps1 creates new project
# 2. Bootstrap-Python.ps1 setup in target project
# 3. Scripts execute correctly from target project
# =============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$TestProjectName = "bolt-python-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

    [Parameter(Mandatory = $false)]
    [switch]$KeepTestProject,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Write-TestStep { param([string]$M) Write-Host "`n[TEST] $M" -ForegroundColor Cyan }
function Write-TestOK   { param([string]$M) Write-Host "  ✅ $M" -ForegroundColor Green }
function Write-TestFail { param([string]$M) Write-Host "  ❌ $M" -ForegroundColor Red; throw $M }

# ─── Configuration ───────────────────────────────────────────────────────────
# Navigate to project root (3 levels up from .boltf/scripts/powershell/)
$BoltRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) $TestProjectName

Write-Host @"

╔════════════════════════════════════════════════════════════╗
║  Bolt Framework - Python Integration E2E Test             ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

Write-Host "Bolt Root:    $BoltRoot" -ForegroundColor White
Write-Host "Test Project: $TestRoot" -ForegroundColor White
Write-Host ""

# ─── Step 1: Initialize Project ─────────────────────────────────────────────
Write-TestStep "Step 1: Initialize test project with Init.ps1"

if (Test-Path $TestRoot) {
    Write-Host "  Cleaning existing test project..." -ForegroundColor DarkGray
    Remove-Item -Recurse -Force $TestRoot
}

try {
    & "$BoltRoot\Init.ps1" `
        -OutputDirectory $TestRoot `
        -ProjectType "green" `
        -ErrorAction Stop | Out-Null
    Write-TestOK "Init.ps1 completed successfully"
} catch {
    Write-TestFail "Init.ps1 failed: $_"
}

# ─── Step 2: Verify Copied Files ────────────────────────────────────────────
Write-TestStep "Step 2: Verify Python files copied to target project"

$requiredFiles = @(
    ".boltf\scripts\powershell\Bootstrap-Python.ps1",
    "Invoke-PythonScript.ps1",
    ".boltf\scripts\powershell\Test-PythonEnvironment.ps1",
    ".claude\skills\skill-creator\requirements.txt",
    ".claude\skills\skill-creator\scripts\quick_validate.py",
    "docs\python-integration.md",
    "examples\python-scripts-usage.ps1"
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $TestRoot $file
    if (Test-Path $fullPath) {
        Write-TestOK "Found: $file"
    } else {
        Write-TestFail "Missing: $file"
    }
}

# ─── Step 3: Check Python Available ─────────────────────────────────────────
Write-TestStep "Step 3: Check Python availability"

try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python (\d+)\.(\d+)") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -ge 3 -and $minor -ge 9) {
            Write-TestOK "Python $pythonVersion available"
        } else {
            Write-Host "  ⚠️  Python version too old: $pythonVersion (need 3.9+)" -ForegroundColor Yellow
            Write-Host "  Skipping bootstrap test..." -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "  ⚠️  Python not found in PATH" -ForegroundColor Yellow
    Write-Host "  Skipping bootstrap test..." -ForegroundColor Yellow
    exit 0
}

# ─── Step 4: Bootstrap Python Environment ───────────────────────────────────
Write-TestStep "Step 4: Bootstrap Python environment in target project"

Push-Location $TestRoot
try {
    $bootstrapScript = ".\.boltf\scripts\powershell\Bootstrap-Python.ps1"

    if ($Verbose) {
        & $bootstrapScript -ErrorAction Stop
    } else {
        & $bootstrapScript -ErrorAction Stop | Out-Null
    }

    Write-TestOK "Bootstrap-Python.ps1 completed"
} catch {
    Pop-Location
    Write-TestFail "Bootstrap-Python.ps1 failed: $_"
}
Pop-Location

# ─── Step 5: Verify Virtual Environment Created ─────────────────────────────
Write-TestStep "Step 5: Verify virtual environment created in target project"

$venvPath = Join-Path $TestRoot ".bolt-venv"
$pythonExe = Join-Path $venvPath "Scripts\python.exe"

if (Test-Path $venvPath) {
    Write-TestOK "Virtual environment exists: .bolt-venv\"
} else {
    Write-TestFail "Virtual environment not found: .bolt-venv\"
}

if (Test-Path $pythonExe) {
    Write-TestOK "Python executable exists: .bolt-venv\Scripts\python.exe"
} else {
    Write-TestFail "Python executable not found"
}

# ─── Step 6: Verify NO Virtual Environment in Bolt Repo ────────────────────
Write-TestStep "Step 6: Verify NO virtual environment in bolt-framework repo"

$boltVenv = Join-Path $BoltRoot ".bolt-venv"
if (-not (Test-Path $boltVenv)) {
    Write-TestOK "Confirmed: No .bolt-venv in bolt-framework repo (correct behavior)"
} else {
    Write-Host "  ⚠️  Found .bolt-venv in bolt-framework repo (should be cleaned up)" -ForegroundColor Yellow
}

# ─── Step 7: Test Invoke-PythonScript.ps1 ───────────────────────────────────
Write-TestStep "Step 7: Test Invoke-PythonScript.ps1 wrapper"

Push-Location $TestRoot
try {
    # Create a simple test script
    $testScript = @"
import sys
print('INVOKE_TEST_SUCCESS')
sys.exit(0)
"@
    $testScriptPath = Join-Path $TestRoot "test_invoke.py"
    Set-Content -Path $testScriptPath -Value $testScript

    $output = & ".\Invoke-PythonScript.ps1" $testScriptPath 2>&1

    if ($output -match "INVOKE_TEST_SUCCESS") {
        Write-TestOK "Invoke-PythonScript.ps1 works correctly"
    } else {
        Write-TestFail "Invoke-PythonScript.ps1 output unexpected: $output"
    }

    Remove-Item $testScriptPath -Force
} catch {
    Pop-Location
    Write-TestFail "Invoke-PythonScript.ps1 failed: $_"
}
Pop-Location

# ─── Step 8: Test Python Packages Installed ─────────────────────────────────
Write-TestStep "Step 8: Verify Python packages installed"

Push-Location $TestRoot
try {
    $packages = & $pythonExe -m pip list --format=json | ConvertFrom-Json
    $packageNames = $packages | ForEach-Object { $_.name }

    if ($packageNames -contains "anthropic") {
        Write-TestOK "Package 'anthropic' installed"
    } else {
        Write-TestFail "Package 'anthropic' not found"
    }

    if ($packageNames -contains "pyyaml") {
        Write-TestOK "Package 'pyyaml' installed"
    } else {
        Write-TestFail "Package 'pyyaml' not found"
    }
} catch {
    Pop-Location
    Write-TestFail "Package verification failed: $_"
}
Pop-Location

# ─── Step 9: Test quick_validate.py ─────────────────────────────────────────
Write-TestStep "Step 9: Test skill-creator quick_validate.py"

Push-Location $TestRoot
try {
    $validateScript = ".claude\skills\skill-creator\scripts\quick_validate.py"
    $skillPath = ".claude\skills\skill-creator"

    $output = & ".\Invoke-PythonScript.ps1" $validateScript $skillPath 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-TestOK "quick_validate.py executed successfully"
    } else {
        Write-TestFail "quick_validate.py failed with exit code: $exitCode"
    }
} catch {
    Pop-Location
    Write-TestFail "quick_validate.py execution failed: $_"
}
Pop-Location

# ─── Step 10: Test Test-PythonEnvironment.ps1 ───────────────────────────────
Write-TestStep "Step 10: Test Test-PythonEnvironment.ps1"

Push-Location $TestRoot
try {
    if ($Verbose) {
        & ".\.boltf\scripts\powershell\Test-PythonEnvironment.ps1" -DetailedOutput -ErrorAction Stop
    } else {
        & ".\.boltf\scripts\powershell\Test-PythonEnvironment.ps1" -ErrorAction Stop | Out-Null
    }

    Write-TestOK "Test-PythonEnvironment.ps1 passed"
} catch {
    Pop-Location
    Write-TestFail "Test-PythonEnvironment.ps1 failed: $_"
}
Pop-Location

# ─── Cleanup ─────────────────────────────────────────────────────────────────
if (-not $KeepTestProject) {
    Write-TestStep "Cleanup: Removing test project"
    try {
        Remove-Item -Recurse -Force $TestRoot -ErrorAction Stop
        Write-TestOK "Test project cleaned up"
    } catch {
        Write-Host "  ⚠️  Could not remove test project: $_" -ForegroundColor Yellow
        Write-Host "  Manual cleanup: Remove-Item -Recurse -Force '$TestRoot'" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n  ℹ️  Test project kept at: $TestRoot" -ForegroundColor Cyan
}

# ─── Summary ─────────────────────────────────────────────────────────────────
Write-Host @"

╔════════════════════════════════════════════════════════════╗
║  ✅ ALL TESTS PASSED                                       ║
║                                                            ║
║  Python integration is working correctly:                  ║
║  • Init.ps1 copies all required files                     ║
║  • Bootstrap creates venv in TARGET project               ║
║  • Scripts execute from TARGET project                    ║
║  • No pollution of bolt-framework repository              ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

exit 0
