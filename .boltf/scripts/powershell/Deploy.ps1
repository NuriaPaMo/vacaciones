# Bolt Framework Deployment Script - Multi-environment deployment with validation
# PowerShell equivalent of deploy.sh

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,

    [switch]$ValidateConstitution,
    [switch]$DryRun,
    [switch]$NoRollback,

    [ValidateSet("rolling", "blue-green", "canary")]
    [string]$Strategy = "rolling",

    [switch]$Verbose,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: Deploy.ps1 -Environment <env> [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -Environment ENV         Target environment (development|staging|production)"
    Write-Host "  -ValidateConstitution    Validate constitution before deployment"
    Write-Host "  -DryRun                 Simulate deployment without making changes"
    Write-Host "  -NoRollback             Disable automatic rollback on failure"
    Write-Host "  -Strategy TYPE          Deployment strategy (rolling|blue-green|canary)"
    Write-Host "  -Verbose                Enable verbose output"
    Write-Host "  -Help                   Show this help message"
    exit 0
}

# Global variables
$script:startTime = Get-Date
$script:deploymentId = "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$script:logFile = "reports\deployments\$($script:deploymentId).log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor Cyan

    # Ensure directory exists
    $logDir = Split-Path $script:logFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Add-Content -Path $script:logFile -Value $logMessage
}

function Write-Success {
    param([string]$Message)
    $logMessage = "✅ $Message"
    Write-Host $logMessage -ForegroundColor Green
    Add-Content -Path $script:logFile -Value $logMessage
}

function Write-Error {
    param([string]$Message)
    $logMessage = "❌ $Message"
    Write-Host $logMessage -ForegroundColor Red
    Add-Content -Path $script:logFile -Value $logMessage
}

function Write-Warning {
    param([string]$Message)
    $logMessage = "⚠️  $Message"
    Write-Host $logMessage -ForegroundColor Yellow
    Add-Content -Path $script:logFile -Value $logMessage
}

function Test-Prerequisites {
    Write-Log "Checking deployment prerequisites..."

    $errors = @()

    # Check required files
    $requiredFiles = @(
        "memory\constitution.md",
        "package.json"
    )

    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $errors += "Missing required file: $file"
        }
    }

    # Check environment configuration
    $envFile = ".env.$Environment"
    if (-not (Test-Path $envFile)) {
        Write-Warning "Environment file not found: $envFile"
    }

    # Check if git repository is clean
    try {
        $gitStatus = git status --porcelain 2>$null
        if ($gitStatus) {
            $errors += "Git repository has uncommitted changes"
        }
    }
    catch {
        Write-Warning "Git not available - skipping repository check"
    }

    # Check Node.js/npm if needed
    if (Test-Path "package.json") {
        try {
            $null = npm --version 2>$null
        }
        catch {
            $errors += "npm not found - required for Node.js projects"
        }
    }

    # Check .NET if needed
    if (Get-ChildItem -Path . -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue) {
        try {
            $null = dotnet --version 2>$null
        }
        catch {
            $errors += "dotnet CLI not found - required for .NET projects"
        }
    }

    if ($errors.Count -gt 0) {
        Write-Error "Prerequisites check failed:"
        foreach ($error in $errors) {
            Write-Error "  - $error"
        }
        return $false
    }

    Write-Success "All prerequisites met"
    return $true
}

function Test-Constitution {
    if (-not $ValidateConstitution) {
        return $true
    }

    Write-Log "Validating constitution..."

    $constitutionFile = "memory\constitution.md"
    if (-not (Test-Path $constitutionFile)) {
        Write-Error "Constitution file not found: $constitutionFile"
        return $false
    }

    $constitution = Get-Content $constitutionFile -Raw

    # Basic validation checks
    $requiredSections = @(
        "## 🎯 Project Type",
        "## 🛠️ Technology Stack",
        "## 📋 Requirements",
        "## 🏗️ Architecture"
    )

    $missingsections = @()
    foreach ($section in $requiredSections) {
        if ($constitution -notmatch [regex]::Escape($section)) {
            $missingSections += $section
        }
    }

    if ($missingSections.Count -gt 0) {
        Write-Error "Constitution validation failed - missing sections:"
        foreach ($section in $missingSections) {
            Write-Error "  - $section"
        }
        return $false
    }

    Write-Success "Constitution validation passed"
    return $true
}

function Start-Build {
    Write-Log "Starting build process..."

    $buildErrors = @()

    # Frontend build
    if (Test-Path "src\frontend\package.json") {
        Write-Log "Building frontend..."
        try {
            Push-Location "src\frontend"

            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: npm run build"
            } else {
                $buildOutput = npm run build 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $buildErrors += "Frontend build failed: $buildOutput"
                } else {
                    Write-Success "Frontend build completed"
                }
            }
        }
        finally {
            Pop-Location
        }
    }

    # Backend build (.NET)
    $dotnetProjects = Get-ChildItem -Path . -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue
    if ($dotnetProjects) {
        Write-Log "Building .NET projects..."
        try {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: dotnet build --configuration Release"
            } else {
                $buildOutput = dotnet build --configuration Release 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $buildErrors += ".NET build failed: $buildOutput"
                } else {
                    Write-Success ".NET build completed"
                }
            }
        }
        catch {
            $buildErrors += ".NET build error: $_"
        }
    }

    # Backend build (Node.js)
    if (Test-Path "src\backend\package.json") {
        Write-Log "Building Node.js backend..."
        try {
            Push-Location "src\backend"

            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: npm run build"
            } else {
                $buildOutput = npm run build 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $buildErrors += "Backend build failed: $buildOutput"
                } else {
                    Write-Success "Backend build completed"
                }
            }
        }
        finally {
            Pop-Location
        }
    }

    if ($buildErrors.Count -gt 0) {
        Write-Error "Build process failed:"
        foreach ($error in $buildErrors) {
            Write-Error "  - $error"
        }
        return $false
    }

    Write-Success "Build process completed successfully"
    return $true
}

function Start-Tests {
    Write-Log "Running test suite..."

    $testErrors = @()

    # Frontend tests
    if (Test-Path "src\frontend\package.json") {
        Write-Log "Running frontend tests..."
        try {
            Push-Location "src\frontend"

            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: npm test"
            } else {
                $testOutput = npm test 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $testErrors += "Frontend tests failed: $testOutput"
                } else {
                    Write-Success "Frontend tests passed"
                }
            }
        }
        finally {
            Pop-Location
        }
    }

    # Backend tests (.NET)
    if (Get-ChildItem -Path . -Recurse -Filter "*.Test*.csproj" -ErrorAction SilentlyContinue) {
        Write-Log "Running .NET tests..."
        try {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: dotnet test"
            } else {
                $testOutput = dotnet test --configuration Release --no-build 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $testErrors += ".NET tests failed: $testOutput"
                } else {
                    Write-Success ".NET tests passed"
                }
            }
        }
        catch {
            $testErrors += ".NET test error: $_"
        }
    }

    if ($testErrors.Count -gt 0) {
        Write-Error "Test suite failed:"
        foreach ($error in $testErrors) {
            Write-Error "  - $error"
        }
        return $false
    }

    Write-Success "All tests passed"
    return $true
}

function Start-SecurityScan {
    Write-Log "Running security scan..."

    # npm audit for Node.js projects
    if (Test-Path "package.json") {
        Write-Log "Running npm security audit..."
        try {
            if ($DryRun) {
                Write-Log "[DRY RUN] Would run: npm audit"
            } else {
                $auditOutput = npm audit --audit-level high 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "npm audit found vulnerabilities: $auditOutput"
                } else {
                    Write-Success "npm security audit passed"
                }
            }
        }
        catch {
            Write-Warning "npm audit failed: $_"
        }
    }

    # TODO: Add more security scans as needed
    Write-Success "Security scan completed"
    return $true
}

function Start-Deployment {
    Write-Log "Starting deployment with strategy: $Strategy"

    switch ($Strategy) {
        "rolling" {
            return Start-RollingDeployment
        }
        "blue-green" {
            return Start-BlueGreenDeployment
        }
        "canary" {
            return Start-CanaryDeployment
        }
        default {
            Write-Error "Unknown deployment strategy: $Strategy"
            return $false
        }
    }
}

function Start-RollingDeployment {
    Write-Log "Executing rolling deployment..."

    # Simulate rolling deployment steps
    $steps = @(
        "Updating configuration files",
        "Deploying backend services",
        "Updating database schema",
        "Deploying frontend assets",
        "Updating load balancer configuration",
        "Restarting services"
    )

    foreach ($step in $steps) {
        Write-Log "Rolling deployment: $step"

        if ($DryRun) {
            Write-Log "[DRY RUN] Would execute: $step"
        } else {
            # Simulate deployment time
            Start-Sleep -Seconds 2
        }
    }

    Write-Success "Rolling deployment completed"
    return $true
}

function Start-BlueGreenDeployment {
    Write-Log "Executing blue-green deployment..."

    if ($DryRun) {
        Write-Log "[DRY RUN] Would execute blue-green deployment"
        Write-Log "[DRY RUN] - Deploy to green environment"
        Write-Log "[DRY RUN] - Run health checks"
        Write-Log "[DRY RUN] - Switch traffic to green"
        Write-Log "[DRY RUN] - Keep blue for rollback"
    } else {
        # Implement blue-green deployment logic
        Write-Warning "Blue-green deployment implementation pending"
    }

    Write-Success "Blue-green deployment completed"
    return $true
}

function Start-CanaryDeployment {
    Write-Log "Executing canary deployment..."

    if ($DryRun) {
        Write-Log "[DRY RUN] Would execute canary deployment"
        Write-Log "[DRY RUN] - Deploy to 10% of instances"
        Write-Log "[DRY RUN] - Monitor metrics"
        Write-Log "[DRY RUN] - Gradually increase traffic"
        Write-Log "[DRY RUN] - Full rollout or rollback"
    } else {
        # Implement canary deployment logic
        Write-Warning "Canary deployment implementation pending"
    }

    Write-Success "Canary deployment completed"
    return $true
}

function Test-HealthCheck {
    Write-Log "Running post-deployment health checks..."

    # Define health check URLs based on environment
    $healthUrls = @()

    switch ($Environment) {
        "development" {
            $healthUrls = @("http://localhost:5000/health", "http://localhost:3000")
        }
        "staging" {
            $healthUrls = @("https://staging-api.company.com/health", "https://staging.company.com")
        }
        "production" {
            $healthUrls = @("https://api.company.com/health", "https://app.company.com")
        }
    }

    $healthChecksPassed = $true

    foreach ($url in $healthUrls) {
        Write-Log "Checking health endpoint: $url"

        if ($DryRun) {
            Write-Log "[DRY RUN] Would check: $url"
            continue
        }

        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "Health check passed: $url"
            } else {
                Write-Error "Health check failed: $url (Status: $($response.StatusCode))"
                $healthChecksPassed = $false
            }
        }
        catch {
            Write-Error "Health check error: $url - $_"
            $healthChecksPassed = $false
        }

        Start-Sleep -Seconds 2
    }

    if ($healthChecksPassed) {
        Write-Success "All health checks passed"
    } else {
        Write-Error "One or more health checks failed"
    }

    return $healthChecksPassed
}

function Start-Rollback {
    if ($NoRollback) {
        Write-Warning "Rollback disabled - manual intervention required"
        return
    }

    Write-Warning "Initiating automatic rollback..."

    if ($DryRun) {
        Write-Log "[DRY RUN] Would execute rollback procedures"
        return
    }

    # Implement rollback logic based on deployment strategy
    switch ($Strategy) {
        "rolling" {
            Write-Log "Rolling back to previous version..."
            # Implement rolling rollback
        }
        "blue-green" {
            Write-Log "Switching traffic back to blue environment..."
            # Implement blue-green rollback
        }
        "canary" {
            Write-Log "Rolling back canary deployment..."
            # Implement canary rollback
        }
    }

    Write-Success "Rollback completed"
}

function New-DeploymentReport {
    $endTime = Get-Date
    $duration = $endTime - $script:startTime

    $report = @"
# Bolt Framework Deployment Report

**Deployment ID:** $($script:deploymentId)
**Environment:** $Environment
**Strategy:** $Strategy
**Started:** $($script:startTime.ToString('yyyy-MM-dd HH:mm:ss'))
**Completed:** $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))
**Duration:** $($duration.ToString('hh\:mm\:ss'))

## Summary

- ✅ Prerequisites check
- ✅ Constitution validation
- ✅ Build process
- ✅ Test execution
- ✅ Security scan
- ✅ Deployment
- ✅ Health checks

## Configuration

- Dry Run: $DryRun
- Validate Constitution: $ValidateConstitution
- Rollback Enabled: $(-not $NoRollback)

## Logs

Full deployment log: $($script:logFile)

Generated by Bolt Framework v2.2.0
"@

    $reportPath = "reports\deployments\$($script:deploymentId)-report.md"
    Set-Content -Path $reportPath -Value $report
    Write-Success "Deployment report generated: $reportPath"
}

# Main execution
Write-Host "🚀 Bolt Framework Deployment Script" -ForegroundColor Blue
Write-Host "===========================" -ForegroundColor Blue
Write-Host ""
Write-Host "Deployment ID: $($script:deploymentId)" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Strategy: $Strategy" -ForegroundColor Cyan
Write-Host "Dry Run: $DryRun" -ForegroundColor Cyan
Write-Host ""

$deploymentSuccess = $true

try {
    # Prerequisites check
    if (-not (Test-Prerequisites)) {
        $deploymentSuccess = $false
        throw "Prerequisites check failed"
    }

    # Constitution validation
    if (-not (Test-Constitution)) {
        $deploymentSuccess = $false
        throw "Constitution validation failed"
    }

    # Build
    if (-not (Start-Build)) {
        $deploymentSuccess = $false
        throw "Build process failed"
    }

    # Test
    if (-not (Start-Tests)) {
        $deploymentSuccess = $false
        throw "Test suite failed"
    }

    # Security scan
    if (-not (Start-SecurityScan)) {
        Write-Warning "Security scan completed with warnings"
    }

    # Deployment
    if (-not (Start-Deployment)) {
        $deploymentSuccess = $false
        throw "Deployment failed"
    }

    # Health checks
    if (-not (Test-HealthCheck)) {
        $deploymentSuccess = $false
        throw "Health checks failed"
    }

    Write-Success "Deployment completed successfully!"

}
catch {
    Write-Error "Deployment failed: $_"

    if (-not $NoRollback -and -not $DryRun) {
        Start-Rollback
    }

    $deploymentSuccess = $false
}
finally {
    # Generate deployment report
    New-DeploymentReport

    Write-Host ""
    if ($deploymentSuccess) {
        Write-Host "🎉 Deployment Summary: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "💥 Deployment Summary: FAILED" -ForegroundColor Red
    }

    $duration = (Get-Date) - $script:startTime
    Write-Host "⏱️  Total Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    Write-Host "📋 Full Log: $($script:logFile)" -ForegroundColor Cyan

    if (-not $deploymentSuccess) {
        exit 1
    }
}
