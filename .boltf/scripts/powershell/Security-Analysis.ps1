# =============================================================================
# Bolt Framework / AI-DLC - Security Analysis Script (PowerShell)
# =============================================================================
# Performs comprehensive security analysis based on detected technology stack
# Integrates OWASP checks, dependency scanning, and SAST/DAST automation
#
# Usage:
#   .\Security-Analysis.ps1 [OPTIONS]
#
# Parameters:
#   -Constitution PATH        Path to constitution.md file
#   -Stack STACK             Override stack detection (nodejs|dotnet|java|python|golang)
#   -OutputFormat FORMAT     Output format (json|markdown|sarif)
#   -Severity LEVEL          Minimum severity to report (critical|high|medium|low)
#   -Compliance STANDARD     Check compliance (owasp|pci-dss|gdpr|soc2)
#   -Sast                   Run SAST analysis
#   -Sca                    Run dependency/SCA scanning
#   -Secrets                Run secrets scanning
#   -Infrastructure         Scan infrastructure configs
#   -All                    Run all security checks
# =============================================================================

[CmdletBinding()]
param(
    [string]$Constitution = ".boltf/memory/constitution.md",
    [ValidateSet('nodejs', 'dotnet', 'java', 'python', 'golang')]
    [string]$Stack = "",
    [ValidateSet('json', 'markdown', 'sarif')]
    [string]$OutputFormat = "markdown",
    [ValidateSet('critical', 'high', 'medium', 'low')]
    [string]$Severity = "medium",
    [ValidateSet('owasp', 'pci-dss', 'gdpr', 'soc2')]
    [string]$Compliance = "",
    [switch]$Sast,
    [switch]$Sca,
    [switch]$Secrets,
    [switch]$Infrastructure,
    [switch]$All,
    [switch]$Help
)

# Configuration
$script:TechStack = $Stack
$script:OutputDir = "reports/security"
$script:Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:ReportFile = "$script:OutputDir/security-report-$script:Timestamp.md"

# Error handling
$ErrorActionPreference = "Stop"

# Logging functions
function Write-LogInfo { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-LogSuccess { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-LogWarning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-LogError { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-LogStep { param($Message) Write-Host "[STEP] $Message" -ForegroundColor Magenta }

# Show help
if ($Help) {
    Write-Host "Bolt Framework Security Analysis Script (PowerShell)"
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\Security-Analysis.ps1 [PARAMETERS]"
    Write-Host ""
    Write-Host "PARAMETERS:"
    Write-Host "  -Constitution PATH      Path to constitution.md (default: .boltf/memory/constitution.md)"
    Write-Host "  -Stack STACK           Override stack detection (nodejs|dotnet|java|python|golang)"
    Write-Host "  -OutputFormat FORMAT   Output format (json|markdown|sarif) (default: markdown)"
    Write-Host "  -Severity LEVEL        Minimum severity (critical|high|medium|low) (default: medium)"
    Write-Host "  -Compliance STANDARD   Check compliance (owasp|pci-dss|gdpr|soc2)"
    Write-Host "  -Sast                  Run SAST analysis"
    Write-Host "  -Sca                   Run dependency/SCA scanning"
    Write-Host "  -Secrets               Run secrets scanning"
    Write-Host "  -Infrastructure        Scan infrastructure configs"
    Write-Host "  -All                   Run all security checks"
    Write-Host "  -Help                  Show this help message"
    exit 0
}

# Enable all checks if -All is specified
if ($All) {
    $Sast = $true
    $Sca = $true
    $Secrets = $true
    $Infrastructure = $true
}

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                                                  ║" -ForegroundColor Magenta
    Write-Host "║           🔒 Bolt Framework Security Analysis Engine 🔒               ║" -ForegroundColor Magenta
    Write-Host "║                                                                  ║" -ForegroundColor Magenta
    Write-Host "║     Stack-Agnostic Security Scanning with OWASP Integration      ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

# Detect technology stack from constitution or project files
function Get-TechnologyStack {
    if ($script:TechStack) {
        Write-LogInfo "Using explicitly specified stack: $script:TechStack"
        return
    }

    $detectedStack = "unknown"

    # Try to detect from constitution first
    if (Test-Path $Constitution) {
        Write-LogInfo "Reading technology stack from constitution: $Constitution"
        $constitutionContent = Get-Content $Constitution -Raw

        if ($constitutionContent -match "node\.js|typescript|javascript|npm") {
            $detectedStack = "nodejs"
        }
        elseif ($constitutionContent -match "\.net|c#|asp\.net|nuget") {
            $detectedStack = "dotnet"
        }
        elseif ($constitutionContent -match "java|spring|maven|gradle") {
            $detectedStack = "java"
        }
        elseif ($constitutionContent -match "python|django|fastapi|flask|pip") {
            $detectedStack = "python"
        }
        elseif ($constitutionContent -match "go|golang") {
            $detectedStack = "golang"
        }
    }

    # Fallback: detect from project files
    if ($detectedStack -eq "unknown") {
        Write-LogInfo "Constitution not found or stack not specified, detecting from project files..."

        if (Test-Path "package.json") {
            $detectedStack = "nodejs"
        }
        elseif ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue) -or (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
            $detectedStack = "dotnet"
        }
        elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
            $detectedStack = "java"
        }
        elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt") -or (Test-Path "setup.py")) {
            $detectedStack = "python"
        }
        elseif (Test-Path "go.mod") {
            $detectedStack = "golang"
        }
    }

    $script:TechStack = $detectedStack
    Write-LogSuccess "Detected technology stack: $script:TechStack"
}

# Initialize security analysis environment
function Initialize-SecurityAnalysis {
    Write-LogStep "Initializing security analysis environment..."

    # Create output directories
    $null = New-Item -ItemType Directory -Path $script:OutputDir -Force
    $null = New-Item -ItemType Directory -Path "$script:OutputDir/sast" -Force
    $null = New-Item -ItemType Directory -Path "$script:OutputDir/sca" -Force
    $null = New-Item -ItemType Directory -Path "$script:OutputDir/secrets" -Force
    $null = New-Item -ItemType Directory -Path "$script:OutputDir/infrastructure" -Force

    # Install required tools based on stack
    switch ($script:TechStack) {
        "nodejs" { Initialize-NodejsSecurityTools }
        "dotnet" { Initialize-DotnetSecurityTools }
        "java" { Initialize-JavaSecurityTools }
        "python" { Initialize-PythonSecurityTools }
        "golang" { Initialize-GoSecurityTools }
        default {
            Write-LogWarning "Unknown stack '$script:TechStack', using generic security tools"
            Initialize-GenericSecurityTools
        }
    }
}

# Initialize Node.js security tools
function Initialize-NodejsSecurityTools {
    Write-LogInfo "Initializing Node.js security tools..."

    if (!(Get-Command "npm" -ErrorAction SilentlyContinue)) {
        Write-LogError "npm is required for Node.js security analysis"
        exit 1
    }

    # Check if ESLint is available
    try {
        npm list eslint 2>$null
        Write-LogInfo "ESLint found for security analysis"
    }
    catch {
        Write-LogInfo "Installing ESLint for security analysis..."
        npm install --no-save eslint @typescript-eslint/eslint-plugin eslint-plugin-security 2>$null
    }
}

# Initialize .NET security tools
function Initialize-DotnetSecurityTools {
    Write-LogInfo "Initializing .NET security tools..."

    if (!(Get-Command "dotnet" -ErrorAction SilentlyContinue)) {
        Write-LogError "dotnet CLI is required for .NET security analysis"
        exit 1
    }

    Write-LogInfo "Security analyzers will be configured via Directory.Build.props"
}

# Initialize Java security tools
function Initialize-JavaSecurityTools {
    Write-LogInfo "Initializing Java security tools..."

    $mavenExists = Get-Command "mvn" -ErrorAction SilentlyContinue
    $gradleExists = Get-Command "gradle" -ErrorAction SilentlyContinue

    if ($mavenExists) {
        Write-LogInfo "Maven detected for Java security analysis"
    }
    elseif ($gradleExists) {
        Write-LogInfo "Gradle detected for Java security analysis"
    }
    else {
        Write-LogWarning "Neither Maven nor Gradle found, some Java security checks may not work"
    }
}

# Initialize Python security tools
function Initialize-PythonSecurityTools {
    Write-LogInfo "Initializing Python security tools..."

    $pythonExists = (Get-Command "python3" -ErrorAction SilentlyContinue) -or (Get-Command "python" -ErrorAction SilentlyContinue)
    if (!$pythonExists) {
        Write-LogError "Python is required for Python security analysis"
        exit 1
    }

    if (Get-Command "pip3" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Installing Python security tools..."
        try {
            pip3 install --user bandit safety pip-audit semgrep 2>$null
        }
        catch {
            Write-LogWarning "Some Python security tools may not be available"
        }
    }
}

# Initialize Go security tools
function Initialize-GoSecurityTools {
    Write-LogInfo "Initializing Go security tools..."

    if (!(Get-Command "go" -ErrorAction SilentlyContinue)) {
        Write-LogError "Go compiler is required for Go security analysis"
        exit 1
    }

    if (!(Get-Command "gosec" -ErrorAction SilentlyContinue)) {
        Write-LogInfo "Installing gosec for Go security analysis..."
        try {
            go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest 2>$null
        }
        catch {
            Write-LogWarning "gosec installation failed"
        }
    }
}

# Initialize generic security tools
function Initialize-GenericSecurityTools {
    Write-LogInfo "Initializing generic security tools..."

    if (!(Get-Command "git" -ErrorAction SilentlyContinue)) {
        Write-LogError "Git is required for security analysis"
        exit 1
    }
}

# Run SAST (Static Application Security Testing)
function Invoke-SastAnalysis {
    if (!$Sast) { return }

    Write-LogStep "Running SAST analysis for $script:TechStack..."

    switch ($script:TechStack) {
        "nodejs" { Invoke-NodejsSast }
        "dotnet" { Invoke-DotnetSast }
        "java" { Invoke-JavaSast }
        "python" { Invoke-PythonSast }
        "golang" { Invoke-GoSast }
        default { Invoke-GenericSast }
    }
}

# Node.js SAST analysis
function Invoke-NodejsSast {
    Write-LogInfo "Running Node.js SAST analysis..."

    # ESLint with security rules
    if (Get-Command "npx" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running ESLint security analysis..."
        try {
            npx eslint . --ext .js,.ts --format json --output-file "$script:OutputDir/sast/eslint-security.json" 2>$null
        }
        catch {
            Write-LogWarning "ESLint analysis failed"
        }
    }

    # Semgrep for Node.js
    if (Get-Command "semgrep" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running Semgrep for Node.js..."
        try {
            semgrep --config=p/nodejs --json --output="$script:OutputDir/sast/semgrep-nodejs.json" . 2>$null
        }
        catch {
            Write-LogWarning "Semgrep analysis failed"
        }
    }
}

# .NET SAST analysis
function Invoke-DotnetSast {
    Write-LogInfo "Running .NET SAST analysis..."

    # Build with analyzers
    $projectFiles = Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue
    $projectFiles += Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue

    if ($projectFiles) {
        Write-LogInfo "Running .NET build with security analyzers..."
        try {
            dotnet build --configuration Release --verbosity minimal > "$script:OutputDir/sast/dotnet-build.log" 2>&1
        }
        catch {
            Write-LogWarning ".NET build analysis failed"
        }
    }

    Write-LogInfo ".NET security analysis via MSBuild analyzers completed"
}

# Python SAST analysis
function Invoke-PythonSast {
    Write-LogInfo "Running Python SAST analysis..."

    # Bandit analysis
    if (Get-Command "bandit" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running Bandit security analysis..."
        try {
            bandit -r . -f json -o "$script:OutputDir/sast/bandit.json" 2>$null
        }
        catch {
            Write-LogWarning "Bandit analysis failed"
        }
    }

    # Semgrep for Python
    if (Get-Command "semgrep" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running Semgrep for Python..."
        try {
            semgrep --config=p/python --json --output="$script:OutputDir/sast/semgrep-python.json" . 2>$null
        }
        catch {
            Write-LogWarning "Semgrep analysis failed"
        }
    }
}

# Go SAST analysis
function Invoke-GoSast {
    Write-LogInfo "Running Go SAST analysis..."

    # gosec analysis
    if (Get-Command "gosec" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running gosec security analysis..."
        try {
            gosec -fmt json -out "$script:OutputDir/sast/gosec.json" ./... 2>$null
        }
        catch {
            Write-LogWarning "gosec analysis failed"
        }
    }

    # go vet
    if (Get-Command "go" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running go vet analysis..."
        try {
            go vet ./... > "$script:OutputDir/sast/go-vet.log" 2>&1
        }
        catch {
            Write-LogWarning "go vet analysis failed"
        }
    }
}

# Generic SAST analysis
function Invoke-GenericSast {
    Write-LogInfo "Running generic SAST analysis..."

    # Semgrep with generic rules
    if (Get-Command "semgrep" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running Semgrep with generic security rules..."
        try {
            semgrep --config=p/security-audit --json --output="$script:OutputDir/sast/semgrep-generic.json" . 2>$null
        }
        catch {
            Write-LogWarning "Generic Semgrep analysis failed"
        }
    }
}

# Run SCA (Software Composition Analysis) - Dependency scanning
function Invoke-ScaAnalysis {
    if (!$Sca) { return }

    Write-LogStep "Running SCA/Dependency analysis for $script:TechStack..."

    switch ($script:TechStack) {
        "nodejs" { Invoke-NodejsSca }
        "dotnet" { Invoke-DotnetSca }
        "java" { Invoke-JavaSca }
        "python" { Invoke-PythonSca }
        "golang" { Invoke-GoSca }
        default { Write-LogInfo "No specific SCA tools for stack: $script:TechStack" }
    }
}

# Node.js SCA analysis
function Invoke-NodejsSca {
    Write-LogInfo "Running Node.js dependency analysis..."

    # npm audit
    if ((Test-Path "package.json") -and (Get-Command "npm" -ErrorAction SilentlyContinue)) {
        Write-LogInfo "Running npm audit..."
        try {
            npm audit --audit-level=moderate --json > "$script:OutputDir/sca/npm-audit.json" 2>$null
        }
        catch {
            Write-LogWarning "npm audit failed"
        }
    }

    # yarn audit if using yarn
    if ((Test-Path "yarn.lock") -and (Get-Command "yarn" -ErrorAction SilentlyContinue)) {
        Write-LogInfo "Running yarn audit..."
        try {
            yarn audit --json > "$script:OutputDir/sca/yarn-audit.json" 2>$null
        }
        catch {
            Write-LogWarning "yarn audit failed"
        }
    }
}

# .NET SCA analysis
function Invoke-DotnetSca {
    Write-LogInfo "Running .NET dependency analysis..."

    # dotnet list package --vulnerable
    if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Checking for vulnerable .NET packages..."
        try {
            dotnet list package --vulnerable --include-transitive > "$script:OutputDir/sca/dotnet-vulnerable.log" 2>&1
        }
        catch {
            Write-LogWarning ".NET vulnerability check failed"
        }
    }
}

# Python SCA analysis
function Invoke-PythonSca {
    Write-LogInfo "Running Python dependency analysis..."

    # Safety check
    if (Get-Command "safety" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running Safety vulnerability check..."
        try {
            safety check --json --output "$script:OutputDir/sca/safety.json" 2>$null
        }
        catch {
            Write-LogWarning "Safety check failed"
        }
    }

    # pip-audit
    if (Get-Command "pip-audit" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running pip-audit..."
        try {
            pip-audit --format=json --output="$script:OutputDir/sca/pip-audit.json" 2>$null
        }
        catch {
            Write-LogWarning "pip-audit failed"
        }
    }
}

# Go SCA analysis
function Invoke-GoSca {
    Write-LogInfo "Running Go dependency analysis..."

    # govulncheck
    if (Get-Command "govulncheck" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running govulncheck..."
        try {
            govulncheck -json ./... > "$script:OutputDir/sca/govulncheck.json" 2>$null
        }
        catch {
            Write-LogWarning "govulncheck failed"
        }
    }
}

# Run secrets scanning
function Invoke-SecretsScanning {
    if (!$Secrets) { return }

    Write-LogStep "Running secrets scanning..."

    # TruffleHog if available
    if (Get-Command "trufflehog" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running TruffleHog secrets scan..."
        try {
            trufflehog filesystem . --json > "$script:OutputDir/secrets/trufflehog.json" 2>$null
        }
        catch {
            Write-LogWarning "TruffleHog scan failed"
        }
    }

    # GitLeaks if available
    if (Get-Command "gitleaks" -ErrorAction SilentlyContinue) {
        Write-LogInfo "Running GitLeaks secrets scan..."
        try {
            gitleaks detect --source . --report-format json --report-path "$script:OutputDir/secrets/gitleaks.json" 2>$null
        }
        catch {
            Write-LogWarning "GitLeaks scan failed"
        }
    }

    # Basic pattern matching for common secrets
    Invoke-BasicSecretsScanning
}

# Basic secrets pattern matching
function Invoke-BasicSecretsScanning {
    Write-LogInfo "Running basic secrets pattern scan..."

    $secretsFile = "$script:OutputDir/secrets/pattern-matches.txt"

    # Initialize report
    @"
# Basic Secrets Scan Results
# Generated: $(Get-Date)

"@ | Out-File -FilePath $secretsFile -Encoding utf8

    # AWS Keys
    "## AWS Access Keys" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    $awsMatches = Get-ChildItem -Recurse -File | Where-Object { $_.Name -notlike "node_modules" -and $_.Directory.Name -ne ".git" } |
                  Select-String -Pattern "AKIA[0-9A-Z]{16}" -ErrorAction SilentlyContinue
    if ($awsMatches) {
        $awsMatches | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }
    else {
        "No AWS keys found" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }

    # API Keys
    "`n## Potential API Keys" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    $apiMatches = Get-ChildItem -Recurse -File | Where-Object { $_.Name -notlike "node_modules" -and $_.Directory.Name -ne ".git" } |
                  Select-String -Pattern "api[_-]key.*[`"']\s*[a-z0-9]{20,}" -ErrorAction SilentlyContinue
    if ($apiMatches) {
        $apiMatches | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }
    else {
        "No API keys found" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }

    # Database URLs
    "`n## Database Connection Strings" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    $dbMatches = Get-ChildItem -Recurse -File | Where-Object { $_.Name -notlike "node_modules" -and $_.Directory.Name -ne ".git" } |
                 Select-String -Pattern "mongodb://|postgres://|mysql://|mssql://" -ErrorAction SilentlyContinue
    if ($dbMatches) {
        $dbMatches | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }
    else {
        "No database URLs found" | Out-File -FilePath $secretsFile -Append -Encoding utf8
    }

    Write-LogInfo "Basic secrets scan completed: $secretsFile"
}

# Run infrastructure security scanning
function Invoke-InfrastructureScanning {
    if (!$Infrastructure) { return }

    Write-LogStep "Running infrastructure security scanning..."

    # Docker security
    if (Test-Path "Dockerfile") {
        Invoke-DockerSecurityScan
    }

    # Kubernetes security
    $k8sFiles = Get-ChildItem -Filter "*.yaml" -ErrorAction SilentlyContinue
    $k8sFiles += Get-ChildItem -Filter "*.yml" -ErrorAction SilentlyContinue
    if ($k8sFiles) {
        Invoke-KubernetesSecurityScan
    }

    # Terraform security
    $tfFiles = Get-ChildItem -Filter "*.tf" -ErrorAction SilentlyContinue
    if ($tfFiles) {
        Invoke-TerraformSecurityScan
    }
}

# Docker security scanning
function Invoke-DockerSecurityScan {
    Write-LogInfo "Running Docker security analysis..."

    $dockerReport = "$script:OutputDir/infrastructure/dockerfile-analysis.txt"

    @"
# Dockerfile Security Analysis
# Generated: $(Get-Date)

## Security Issues Found:
"@ | Out-File -FilePath $dockerReport -Encoding utf8

    $dockerContent = Get-Content "Dockerfile" -Raw

    # Check for common issues
    if ($dockerContent -match "FROM.*:latest") {
        $latestLines = (Get-Content "Dockerfile" | Select-String "FROM.*:latest").LineNumber
        "❌ Uses 'latest' tag (line $($latestLines -join ', '))" | Out-File -FilePath $dockerReport -Append -Encoding utf8
    }

    if ($dockerContent -match "USER root|^USER 0") {
        $rootLines = (Get-Content "Dockerfile" | Select-String "USER root|^USER 0").LineNumber
        "❌ Runs as root user (line $($rootLines -join ', '))" | Out-File -FilePath $dockerReport -Append -Encoding utf8
    }

    if ($dockerContent -notmatch "USER ") {
        "⚠️ No explicit USER directive found (may run as root)" | Out-File -FilePath $dockerReport -Append -Encoding utf8
    }

    Write-LogInfo "Docker security analysis completed: $dockerReport"
}

# Kubernetes security scanning
function Invoke-KubernetesSecurityScan {
    Write-LogInfo "Running Kubernetes security analysis..."

    $k8sReport = "$script:OutputDir/infrastructure/k8s-analysis.txt"

    @"
# Kubernetes Security Analysis
# Generated: $(Get-Date)

"@ | Out-File -FilePath $k8sReport -Encoding utf8

    $yamlFiles = Get-ChildItem -Filter "*.yaml" -ErrorAction SilentlyContinue
    $yamlFiles += Get-ChildItem -Filter "*.yml" -ErrorAction SilentlyContinue

    foreach ($file in $yamlFiles) {
        "## Analysis of $($file.Name):" | Out-File -FilePath $k8sReport -Append -Encoding utf8

        $content = Get-Content $file.FullName -Raw

        # Check for security contexts
        if ($content -notmatch "securityContext:") {
            "⚠️ No securityContext defined" | Out-File -FilePath $k8sReport -Append -Encoding utf8
        }

        # Check for privileged containers
        if ($content -match "privileged: true") {
            "❌ Privileged container found" | Out-File -FilePath $k8sReport -Append -Encoding utf8
        }

        # Check for resource limits
        if ($content -notmatch "resources:") {
            "⚠️ No resource limits defined" | Out-File -FilePath $k8sReport -Append -Encoding utf8
        }

        "" | Out-File -FilePath $k8sReport -Append -Encoding utf8
    }

    Write-LogInfo "Kubernetes security analysis completed: $k8sReport"
}

# Terraform security scanning
function Invoke-TerraformSecurityScan {
    Write-LogInfo "Running Terraform security analysis..."

    $tfReport = "$script:OutputDir/infrastructure/terraform-analysis.txt"

    @"
# Terraform Security Analysis
# Generated: $(Get-Date)

## Basic Security Checks:
"@ | Out-File -FilePath $tfReport -Encoding utf8

    $tfFiles = Get-ChildItem -Filter "*.tf"

    # Check for hardcoded secrets
    $passwordMatches = $tfFiles | Select-String -Pattern 'password\s*=\s*"' -ErrorAction SilentlyContinue
    if ($passwordMatches) {
        "❌ Hardcoded passwords found in Terraform files" | Out-File -FilePath $tfReport -Append -Encoding utf8
        $passwordMatches | Out-File -FilePath $tfReport -Append -Encoding utf8
    }

    # Check for public access
    $publicMatches = $tfFiles | Select-String -Pattern "0.0.0.0/0" -ErrorAction SilentlyContinue
    if ($publicMatches) {
        "⚠️ Open access (0.0.0.0/0) found in Terraform files" | Out-File -FilePath $tfReport -Append -Encoding utf8
        $publicMatches | Out-File -FilePath $tfReport -Append -Encoding utf8
    }

    Write-LogInfo "Terraform security analysis completed: $tfReport"
}

# Generate comprehensive security report
function New-SecurityReport {
    Write-LogStep "Generating comprehensive security report..."

    $reportContent = @"
# 🔒 Bolt Framework Security Analysis Report

**Generated**: $(Get-Date)
**Technology Stack**: $script:TechStack
**Constitution**: $Constitution
**Analysis Scope**: SAST=$Sast SCA=$Sca Secrets=$Secrets Infrastructure=$Infrastructure

---

## Executive Summary

| Category | Status | Details |
|----------|--------|---------|
| 🔍 SAST Analysis | $(if($Sast){'✅ Completed'}else{'⏭️ Skipped'}) | Static code analysis |
| 📦 SCA Analysis | $(if($Sca){'✅ Completed'}else{'⏭️ Skipped'}) | Dependency vulnerabilities |
| 🔑 Secrets Scan | $(if($Secrets){'✅ Completed'}else{'⏭️ Skipped'}) | Exposed credentials |
| 🏗️ Infrastructure | $(if($Infrastructure){'✅ Completed'}else{'⏭️ Skipped'}) | Config security |

---

## Technology Stack Analysis: $script:TechStack

"@

    # Add stack-specific security information
    switch ($script:TechStack) {
        "nodejs" { $reportContent += Get-NodejsSecuritySummary }
        "dotnet" { $reportContent += Get-DotnetSecuritySummary }
        "python" { $reportContent += Get-PythonSecuritySummary }
        "golang" { $reportContent += Get-GoSecuritySummary }
        default { $reportContent += "`n### Generic Security Analysis`nBasic security checks performed for unknown technology stack." }
    }

    # Add OWASP Top 10 mapping
    $reportContent += Get-OwaspMapping

    # Add detailed findings
    $reportContent += Get-DetailedFindings

    # Add recommendations
    $reportContent += Get-SecurityRecommendations

    $reportContent | Out-File -FilePath $script:ReportFile -Encoding utf8

    Write-LogSuccess "Security report generated: $script:ReportFile"
}

# Stack-specific security summaries
function Get-NodejsSecuritySummary {
    $npmVersion = ""
    $yarnVersion = ""

    try { $npmVersion = (npm --version) + " ✅" } catch { $npmVersion = "npm ❌" }
    try { $yarnVersion = "yarn ✅" } catch { $yarnVersion = "" }

    return @"

### Node.js/JavaScript Security Profile

**Package Manager**: $npmVersion $yarnVersion
**Security Tools Used**: ESLint Security Plugin, Semgrep, npm audit
**Key Risk Areas**: Prototype pollution, Command injection, XSS, Dependency vulnerabilities

"@
}

function Get-DotnetSecuritySummary {
    $dotnetVersion = ""
    try { $dotnetVersion = (dotnet --version) } catch { $dotnetVersion = "Not detected" }

    return @"

### .NET Security Profile

**Framework**: $dotnetVersion
**Security Tools Used**: Microsoft Security Code Analysis, Built-in analyzers
**Key Risk Areas**: Deserialization, SQL injection, XSS in Razor, CSRF

"@
}

function Get-PythonSecuritySummary {
    $pythonVersion = ""
    try { $pythonVersion = (python --version) } catch {
        try { $pythonVersion = (python3 --version) } catch { $pythonVersion = "Not detected" }
    }

    return @"

### Python Security Profile

**Version**: $pythonVersion
**Security Tools Used**: Bandit, Safety, pip-audit
**Key Risk Areas**: Code injection, Deserialization, SSTI, SQL injection

"@
}

function Get-GoSecuritySummary {
    $goVersion = ""
    try { $goVersion = (go version) } catch { $goVersion = "Not detected" }

    return @"

### Go Security Profile

**Version**: $goVersion
**Security Tools Used**: gosec, go vet, govulncheck
**Key Risk Areas**: Command injection, Path traversal, Race conditions

"@
}

# OWASP Top 10 mapping
function Get-OwaspMapping {
    return @"

---

## OWASP Top 10 Coverage Analysis

| OWASP Category | Coverage | Status | Tools |
|----------------|----------|--------|-------|
| A01: Broken Access Control | 🟡 Partial | Manual review needed | Constitution validation |
| A02: Cryptographic Failures | 🟡 Partial | Basic checks | Pattern matching |
| A03: Injection | ✅ Covered | Automated | SAST tools |
| A04: Insecure Design | 🔴 Manual | Architecture review | Constitution compliance |
| A05: Security Misconfiguration | 🟡 Partial | Infrastructure scan | Config analysis |
| A06: Vulnerable Components | ✅ Covered | Automated | SCA tools |
| A07: Auth Failures | 🟡 Partial | Code analysis | SAST + manual |
| A08: Data Integrity | 🔴 Manual | Design review | Constitution validation |
| A09: Logging Failures | 🟡 Partial | Code analysis | Pattern matching |
| A10: SSRF | 🟡 Partial | SAST analysis | Code analysis |

**Legend**: ✅ Automated coverage | 🟡 Partial coverage | 🔴 Manual review required

"@
}

# Detailed findings
function Get-DetailedFindings {
    $findings = @"

---

## Detailed Security Findings

"@

    # Process SAST findings
    if ($Sast) {
        $findings += "`n### 🔍 Static Analysis (SAST) Findings`n"

        $sastFiles = Get-ChildItem "$script:OutputDir/sast/*.json" -ErrorAction SilentlyContinue
        if ($sastFiles) {
            $findings += "Analysis files generated:`n"
            foreach ($file in $sastFiles) {
                $findings += "- $($file.Name)`n"
            }
        }
        else {
            $findings += "No SAST analysis files found.`n"
        }
        $findings += "`n"
    }

    # Process SCA findings
    if ($Sca) {
        $findings += "### 📦 Dependency Analysis (SCA) Findings`n"

        $scaFiles = Get-ChildItem "$script:OutputDir/sca/*" -ErrorAction SilentlyContinue
        if ($scaFiles) {
            $findings += "Analysis files generated:`n"
            foreach ($file in $scaFiles) {
                $findings += "- $($file.Name)`n"
            }
        }
        else {
            $findings += "No SCA analysis files found.`n"
        }
        $findings += "`n"
    }

    # Process secrets findings
    if ($Secrets) {
        $findings += "### 🔑 Secrets Scanning Findings`n"

        if (Test-Path "$script:OutputDir/secrets/pattern-matches.txt") {
            $findings += "Basic pattern matching results available in reports/security/secrets/`n"
        }
        $findings += "`n"
    }

    return $findings
}

# Security recommendations
function Get-SecurityRecommendations {
    $recommendations = @"

---

## Security Recommendations

### Immediate Actions (Critical Priority)

1. **Enable Security Scanning in CI/CD**
   - Integrate this security analysis script in your GitHub Actions/Azure Pipelines
   - Set up automatic security scanning on every pull request
   - Block deployments if critical vulnerabilities are found

2. **Secrets Management**
   - Remove any hardcoded secrets found during analysis
   - Implement proper secrets management (Azure Key Vault, HashiCorp Vault, etc.)
   - Use environment variables or secure vaults for all sensitive data

3. **Dependency Management**
   - Keep all dependencies up to date
   - Enable automated dependency vulnerability scanning
   - Implement a dependency update policy

### Stack-Specific Recommendations

"@

    switch ($script:TechStack) {
        "nodejs" {
            $recommendations += @"
#### Node.js Specific:
- Configure ESLint with security rules in your IDE and CI/CD
- Use ``npm audit fix`` regularly to update vulnerable dependencies
- Consider using ``npm ci`` instead of ``npm install`` in production
- Enable Node.js security-related flags in production (``--security``)

"@
        }
        "dotnet" {
            $recommendations += @"
#### .NET Specific:
- Enable all .NET security analyzers in Directory.Build.props
- Use ``dotnet list package --vulnerable`` regularly
- Configure Content Security Policy for web applications
- Enable request validation and CSRF protection

"@
        }
        "python" {
            $recommendations += @"
#### Python Specific:
- Run ``bandit`` regularly as part of your development workflow
- Use ``safety check`` to scan for known vulnerabilities
- Consider using ``pip-audit`` for comprehensive dependency analysis
- Enable security-related linting rules in your IDE

"@
        }
    }

    $recommendations += @"

### Constitution Integration

Add these security policies to your ```.boltf/memory/constitution.md```:

``````yaml
security:
  static_analysis:
    enabled: true
    tools: ["eslint-security", "semgrep", "bandit"]  # Adjust based on stack
    block_on_high: true

  dependency_scanning:
    enabled: true
    update_frequency: weekly
    vulnerability_threshold: medium

  secrets_scanning:
    enabled: true
    pre_commit_hooks: true

  compliance:
    owasp_top10: enforced
    standards: [$(if($Compliance){"$Compliance"}else{"owasp"})]
``````

### Next Steps

1. Review all generated analysis files in ``reports/security/``
2. Address any critical or high-severity findings
3. Integrate security scanning into your development workflow
4. Set up monitoring and alerting for security events
5. Schedule regular security reviews and penetration testing

---

*This report was generated by Bolt Framework Security Analysis Engine*
*For questions or support, consult the Bolt Security Agent documentation*

"@

    return $recommendations
}

# Main execution
function Main {
    Show-Banner

    Write-LogInfo "Starting Bolt Framework Security Analysis..."
    Write-LogInfo "Constitution file: $Constitution"
    Write-LogInfo "Output directory: $script:OutputDir"
    Write-LogInfo "Minimum severity: $Severity"

    # Detect technology stack
    Get-TechnologyStack

    if ($script:TechStack -eq "unknown") {
        Write-LogError "Unable to detect technology stack. Please specify with -Stack parameter."
        Write-LogInfo "Supported stacks: nodejs, dotnet, java, python, golang"
        exit 1
    }

    # Initialize security analysis environment
    Initialize-SecurityAnalysis

    # Run security analyses
    Invoke-SastAnalysis
    Invoke-ScaAnalysis
    Invoke-SecretsScanning
    Invoke-InfrastructureScanning

    # Generate comprehensive report
    New-SecurityReport

    Write-LogSuccess "Security analysis completed!"
    Write-LogInfo "Report available at: $script:ReportFile"
    Write-LogInfo "Detailed analysis files in: $script:OutputDir"

    # Show summary
    Write-Host ""
    Write-Host "📊 Analysis Summary:" -ForegroundColor Cyan
    Write-Host "  Technology Stack: $script:TechStack"
    Write-Host "  SAST Analysis: $(if($Sast){'✅ Completed'}else{'⏭️ Skipped'})"
    Write-Host "  SCA Analysis: $(if($Sca){'✅ Completed'}else{'⏭️ Skipped'})"
    Write-Host "  Secrets Scan: $(if($Secrets){'✅ Completed'}else{'⏭️ Skipped'})"
    Write-Host "  Infrastructure: $(if($Infrastructure){'✅ Completed'}else{'⏭️ Skipped'})"
    Write-Host ""
    Write-Host "🚀 Next: Review the security report and implement recommended fixes!" -ForegroundColor Magenta
}

# Execute main function
Main
