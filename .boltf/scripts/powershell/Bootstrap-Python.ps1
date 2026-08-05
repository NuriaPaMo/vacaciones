# =============================================================================
# Bolt Framework - Python Environment Bootstrap
# =============================================================================
# Ensures Python is available and dependencies are installed in a virtual env
# =============================================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $PWD,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

# ─── Helpers ─────────────────────────────────────────────────────────────────
function Write-Info    { param([string]$M) Write-Host "[INFO] $M" -ForegroundColor Blue }
function Write-Success { param([string]$M) Write-Host "[OK]   $M" -ForegroundColor Green }
function Write-Warn    { param([string]$M) Write-Host "[WARN] $M" -ForegroundColor Yellow }
function Write-Err     { param([string]$M) Write-Host "[ERR]  $M" -ForegroundColor Red }

# ─── Configuration ───────────────────────────────────────────────────────────
$VenvPath = Join-Path $ProjectRoot ".bolt-venv"
$RequirementsFiles = @(
    ".claude/skills/skill-creator/requirements.txt"
    ".claude/skills/skill-bolt-setup-constitution/requirements.txt"
    # Add more requirements.txt paths here as needed
)

Write-Info "Project root: $ProjectRoot"
Write-Info "Virtual environment will be created at: $VenvPath"

# ─── Check Python ────────────────────────────────────────────────────────────
Write-Info "Checking Python installation..."

$pythonCmd = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $version = & $cmd --version 2>&1
        if ($version -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 9) {
                $pythonCmd = $cmd
                Write-Success "Found: $version"
                break
            }
        }
    } catch {
        continue
    }
}

if (-not $pythonCmd) {
    Write-Err "Python 3.9+ not found in PATH"
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║  Python 3.9+ is required for advanced Bolt Framework features           ║
║                                                                          ║
║  Download from: https://www.python.org/downloads/                       ║
║                                                                          ║
║  Make sure to check 'Add Python to PATH' during installation            ║
║                                                                          ║
║  After installation, restart your terminal and run this script again    ║
╚══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Yellow
    exit 1
}

# ─── Create/Activate Virtual Environment ────────────────────────────────────
if (Test-Path $VenvPath) {
    if ($Force) {
        Write-Warn "Removing existing virtual environment..."
        Remove-Item -Recurse -Force $VenvPath
    } else {
        Write-Info "Virtual environment already exists: $VenvPath"
    }
}

if (-not (Test-Path $VenvPath)) {
    Write-Info "Creating virtual environment at: $VenvPath"
    & $pythonCmd -m venv $VenvPath
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to create virtual environment"
        exit 1
    }
    Write-Success "Virtual environment created"
}

# ─── Activate Virtual Environment ───────────────────────────────────────────
$activateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
if (-not (Test-Path $activateScript)) {
    Write-Err "Activation script not found: $activateScript"
    exit 1
}

Write-Info "Activating virtual environment..."
& $activateScript

# ─── Install Dependencies ────────────────────────────────────────────────────
if (-not $SkipInstall) {
    $installed = $false
    foreach ($reqFile in $RequirementsFiles) {
        $fullPath = Join-Path $ProjectRoot $reqFile
        if (Test-Path $fullPath) {
            Write-Info "Installing dependencies from: $reqFile"
            & python -m pip install --quiet --upgrade pip
            & python -m pip install --quiet -r $fullPath
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Dependencies installed from $reqFile"
                $installed = $true
            } else {
                Write-Warn "Failed to install some dependencies from $reqFile"
            }
        }
    }

    if (-not $installed) {
        Write-Warn "No requirements.txt files found or installation failed"
    }
}

# ─── Verification ────────────────────────────────────────────────────────────
Write-Info "Verifying installation..."
$packages = & python -m pip list --format=json | ConvertFrom-Json

$requiredPackages = @("anthropic", "pyyaml")
$missing = @()
foreach ($pkg in $requiredPackages) {
    if (-not ($packages | Where-Object { $_.name -eq $pkg })) {
        $missing += $pkg
    }
}

if ($missing.Count -gt 0) {
    Write-Warn "Some packages may not be installed: $($missing -join ', ')"
    Write-Info "These are needed for advanced features (AI-powered skill optimization)"
} else {
    Write-Success "All required packages installed"
}

# ─── Usage Instructions ──────────────────────────────────────────────────────
Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║  Python environment ready!                                               ║
║                                                                          ║
║  Location: $VenvPath
║  Project:  $ProjectRoot
║                                                                          ║
║  To use Python scripts in this project:                                 ║
║    1. Activate: .\.bolt-venv\Scripts\Activate.ps1                       ║
║    2. Run script: python .claude\skills\skill-creator\scripts\...       ║
║    3. Deactivate: deactivate                                            ║
║                                                                          ║
║  Or use the helper: .\Invoke-PythonScript.ps1 <script-path>             ║
╚══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
