<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Architecture Quality Gates Script

.DESCRIPTION
    Validates architectural rules: dependency boundaries, contracts, complexity.
    Supports Node.js/TypeScript, .NET, Java, and Python projects.

.PARAMETER Check
    Run all architecture checks (default).

.PARAMETER Report
    Generate detailed HTML/SVG reports.

.PARAMETER Fix
    Attempt to auto-fix where possible.

.PARAMETER CIMode
    Exit with error code on any failure (for CI pipelines).

.EXAMPLE
    .\Architecture-Gates.ps1 -Check

.EXAMPLE
    .\Architecture-Gates.ps1 -Report -CIMode

.NOTES
    Quality Gates Covered:
    1. Dependency Rules (layer enforcement)
    2. Circular Dependencies Detection
    3. Contract Validation (OpenAPI/AsyncAPI)
    4. Complexity Metrics
    5. Fitness Functions
#>

param(
    [switch]$Check,
    [switch]$Report,
    [switch]$Fix,
    [switch]$CIMode
)

# Default to check mode
if (-not $Check -and -not $Report -and -not $Fix) {
    $Check = $true
}

# Track results
$Script:Passed = 0
$Script:Failed = 0
$Script:Warnings = 0

# Thresholds
$Script:MaxCyclomaticComplexity = 10
$Script:MaxCognitiveComplexity = 15
$Script:MaxFunctionLines = 50
$Script:MaxFileLines = 400
$Script:MaxFanOut = 10

# Helper functions
function Write-Info {
    Write-Host "[INFO] $args" -ForegroundColor Blue
}

function Write-Success {
    Write-Host "[✓] $args" -ForegroundColor Green
    $Script:Passed++
}

function Write-Warn {
    Write-Host "[⚠] $args" -ForegroundColor Yellow
    $Script:Warnings++
}

function Write-Fail {
    Write-Host "[✗] $args" -ForegroundColor Red
    $Script:Failed++
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  🏗️  $Title" -ForegroundColor Magenta
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Magenta
}

function Get-ProjectType {
    if (Test-Path "package.json") {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.devDependencies.typescript -or $pkg.dependencies.typescript) {
            return "node-ts"
        }
        return "node"
    }
    elseif ((Test-Path "*.csproj") -or (Test-Path "*.sln")) {
        return "dotnet"
    }
    elseif (Test-Path "pom.xml") {
        return "java-maven"
    }
    elseif (Test-Path "build.gradle") {
        return "java-gradle"
    }
    elseif ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        return "python"
    }
    return "unknown"
}

function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Command,
        [bool]$Critical = $true
    )

    Write-Info "Running: $Name"

    try {
        $result = & $Command
        if ($LASTEXITCODE -eq 0 -or $result -eq $true) {
            Write-Success "$Name passed"
            return $true
        }
    }
    catch {
        # Command failed
    }

    if ($Critical) {
        Write-Fail "$Name FAILED"
    }
    else {
        Write-Warn "$Name has warnings"
    }
    return $false
}

# =============================================================================
# Load Constitution Thresholds
# =============================================================================
function Get-ConstitutionThresholds {
    $constitutionPath = ".boltf/memory/constitution.md"
    if (Test-Path $constitutionPath) {
        Write-Info "Loading thresholds from constitution..."
        $content = Get-Content $constitutionPath -Raw

        if ($content -match "Cyclomatic Complexity.*≤\s*(\d+)") {
            $Script:MaxCyclomaticComplexity = [int]$Matches[1]
            Write-Info "  Cyclomatic Complexity threshold: $($Script:MaxCyclomaticComplexity)"
        }
    }
}

# =============================================================================
# GATE 1: Dependency Rules
# =============================================================================
function Test-DependencyRulesNode {
    # Check dependency-cruiser
    if ((Test-Path ".dependency-cruiser.cjs") -or (Test-Path ".dependency-cruiser.js")) {
        Invoke-Check "Dependency Cruiser" {
            npx depcruise --config .dependency-cruiser.cjs src --output-type err-long
        }
    }
    elseif (Test-Command "npx") {
        Write-Warn "dependency-cruiser not configured"
        Write-Info "To install: npm install --save-dev dependency-cruiser"
        Write-Info "To init: npx depcruise --init"
    }

    # Check eslint-plugin-boundaries
    if (Test-Path "package.json") {
        $pkg = Get-Content "package.json" -Raw
        if ($pkg -match "eslint-plugin-boundaries") {
            Write-Info "eslint-plugin-boundaries detected - rules enforced via ESLint"
        }
    }
}

function Test-DependencyRulesDotNet {
    # Find architecture test files
    $archTests = Get-ChildItem -Path . -Recurse -Include "*ArchitectureTests*.cs","*ArchTests*.cs" -ErrorAction SilentlyContinue

    if ($archTests) {
        Invoke-Check "Architecture Tests (.NET)" {
            dotnet test --filter "Category=Architecture|FullyQualifiedName~Architecture"
        }
    }
    else {
        Write-Warn "No architecture tests found"
        Write-Info "Consider adding NetArchTest: dotnet add package NetArchTest.Rules"
        Write-Info "Create tests in: tests/Architecture/ArchitectureTests.cs"

        # Provide sample code
        $sampleCode = @"
// Example NetArchTest - tests/Architecture/LayerTests.cs
using NetArchTest.Rules;
using Xunit;

public class LayerTests
{
    [Fact]
    public void Domain_Should_Not_Reference_Infrastructure()
    {
        var result = Types.InAssembly(typeof(DomainMarker).Assembly)
            .Should()
            .NotHaveDependencyOn("Infrastructure")
            .GetResult();

        Assert.True(result.IsSuccessful);
    }
}
"@
        Write-Info "Sample code:`n$sampleCode"
    }
}

function Test-DependencyRulesJava {
    $archTests = Get-ChildItem -Path . -Recurse -Include "*ArchitectureTest*.java","*ArchTest*.java" -ErrorAction SilentlyContinue

    if ($archTests) {
        if (Test-Path "pom.xml") {
            Invoke-Check "ArchUnit Tests (Maven)" { mvn test -Dtest="*ArchTest*" }
        }
        elseif (Test-Path "build.gradle") {
            Invoke-Check "ArchUnit Tests (Gradle)" { gradle test --tests "*ArchTest*" }
        }
    }
    else {
        Write-Warn "No ArchUnit tests found"
        Write-Info "Consider adding ArchUnit: com.tngtech.archunit:archunit-junit5"
    }
}

# =============================================================================
# GATE 2: Circular Dependencies
# =============================================================================
function Test-CircularDependenciesNode {
    if (Test-Command "npx") {
        # Check if madge is available
        $hasMadge = (npm ls madge 2>$null) -or (Test-Command "madge")

        if ($hasMadge) {
            if ($Report) {
                Write-Info "Generating dependency graph..."
                New-Item -ItemType Directory -Force -Path "reports/architecture" | Out-Null
                npx madge --image reports/architecture/dependency-graph.svg src 2>$null
            }

            Invoke-Check "Circular Dependencies (madge)" {
                $output = npx madge --circular src 2>&1
                if ($output -match "No circular dependency") {
                    return $true
                }
                Write-Host $output
                return $false
            }
        }
        else {
            Write-Info "madge not installed - using dependency-cruiser for cycle detection"
        }
    }
}

# =============================================================================
# GATE 3: Contract Validation
# =============================================================================
function Test-OpenAPIContracts {
    $openapiFiles = Get-ChildItem -Path "specs" -Recurse -Include "openapi.yaml","openapi.json" -ErrorAction SilentlyContinue

    if ($openapiFiles) {
        Write-Info "Found OpenAPI specs: $($openapiFiles.FullName -join ', ')"

        foreach ($spec in $openapiFiles) {
            Invoke-Check "OpenAPI Lint: $($spec.Name)" {
                npx @stoplight/spectral-cli lint $spec.FullName
            } -Critical $false
        }
    }
    else {
        Write-Info "No OpenAPI specs found in specs/"
    }
}

function Test-AsyncAPIContracts {
    $asyncapiFiles = Get-ChildItem -Path "specs" -Recurse -Include "asyncapi.yaml","asyncapi.json" -ErrorAction SilentlyContinue

    if ($asyncapiFiles) {
        Write-Info "Found AsyncAPI specs: $($asyncapiFiles.FullName -join ', ')"

        if (Test-Command "asyncapi") {
            foreach ($spec in $asyncapiFiles) {
                Invoke-Check "AsyncAPI Validate: $($spec.Name)" {
                    asyncapi validate $spec.FullName
                } -Critical $false
            }
        }
        else {
            Write-Warn "AsyncAPI CLI not installed"
            Write-Info "To install: npm install -g @asyncapi/cli"
        }
    }
}

function Test-PactContracts {
    $pactFiles = Get-ChildItem -Path . -Recurse -Include "*.pact.json","*PactTest*" -ErrorAction SilentlyContinue

    if ($pactFiles -or (Test-Path "pacts")) {
        Write-Info "Pact contracts detected"

        $projectType = Get-ProjectType
        switch -Wildcard ($projectType) {
            "node*" {
                Invoke-Check "Pact Verification" {
                    npm run test:pact 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        npx jest --testPathPattern=pact
                    }
                } -Critical $false
            }
            "dotnet" {
                Invoke-Check "Pact Verification" {
                    dotnet test --filter "Category=Pact"
                } -Critical $false
            }
        }
    }
    else {
        Write-Info "No Pact contracts found"
    }
}

# =============================================================================
# GATE 4: Complexity Metrics
# =============================================================================
function Test-ComplexityNode {
    $hasEslint = (Test-Path "eslint.config.mjs") -or (Test-Path ".eslintrc.js") -or (Test-Path ".eslintrc.json")

    if ($hasEslint) {
        Write-Info "Checking ESLint complexity rules..."

        $eslintConfig = Get-ChildItem -Path . -Include "eslint.config.mjs",".eslintrc.*" -ErrorAction SilentlyContinue |
            Get-Content -Raw -ErrorAction SilentlyContinue

        if ($eslintConfig -match "complexity") {
            Write-Success "ESLint complexity rules configured"
        }
        else {
            Write-Warn "Consider adding complexity rules to ESLint:"
            Write-Info "  'complexity': ['error', { max: $($Script:MaxCyclomaticComplexity) }]"
            Write-Info "  'max-lines-per-function': ['error', { max: $($Script:MaxFunctionLines) }]"
        }
    }

    if (Test-Path "sonar-project.properties") {
        Write-Info "SonarQube configured - complexity metrics available in dashboard"
    }
}

function Test-ComplexityDotNet {
    $csproj = Get-ChildItem -Path . -Include "*.csproj" -Recurse -ErrorAction SilentlyContinue |
        Get-Content -Raw -ErrorAction SilentlyContinue

    if ($csproj -match "Microsoft.CodeAnalysis") {
        Write-Success "Roslyn analyzers configured"
    }
    else {
        Write-Warn "Consider adding Roslyn analyzers for complexity metrics"
        Write-Info "  dotnet add package Microsoft.CodeAnalysis.NetAnalyzers"
    }

    if ((Test-Path ".editorconfig") -and ((Get-Content ".editorconfig" -Raw) -match "dotnet_code_quality")) {
        Write-Success "Code quality rules in .editorconfig"
    }
}

# =============================================================================
# GATE 5: Fitness Functions
# =============================================================================
function Test-BuildTime {
    if ($CIMode) {
        Write-Info "Skipping build time check in CI mode"
        return
    }

    Write-Info "Checking build time..."
    $startTime = Get-Date

    $projectType = Get-ProjectType
    switch -Wildcard ($projectType) {
        "node*" { npm run build 2>&1 | Out-Null }
        "dotnet" { dotnet build --no-restore 2>&1 | Out-Null }
    }

    $buildTime = ((Get-Date) - $startTime).TotalSeconds

    if ($buildTime -lt 300) {
        Write-Success "Build time: $([math]::Round($buildTime, 1))s (< 5min threshold)"
    }
    else {
        Write-Warn "Build time: $([math]::Round($buildTime, 1))s (exceeds 5min threshold)"
    }
}

function Test-TestQuality {
    Write-Info "Analyzing test quality..."

    $projectType = Get-ProjectType
    switch -Wildcard ($projectType) {
        "node*" {
            $testFiles = Get-ChildItem -Path "src" -Recurse -Include "*.spec.ts","*.test.ts" -ErrorAction SilentlyContinue
            $testCount = $testFiles.Count

            if ($testCount -gt 0) {
                $mockCount = ($testFiles | Get-Content -Raw | Select-String -Pattern "jest\.mock|vi\.mock|mock\(" -AllMatches).Matches.Count
                $mockRatio = [math]::Round(($mockCount / $testCount) * 100, 1)

                Write-Info "Test files: $testCount, Mock usages: $mockCount"

                if ($mockRatio -gt 300) {
                    Write-Warn "High mock ratio ($mockRatio%) - consider improving architecture"
                }
                else {
                    Write-Success "Mock ratio acceptable ($mockRatio%)"
                }
            }
        }
    }
}

# =============================================================================
# Main Execution
# =============================================================================
Write-Host "`n🏗️  Bolt Framework Architecture Quality Gates" -ForegroundColor Magenta
Write-Host "======================================`n" -ForegroundColor Magenta

$projectType = Get-ProjectType
Write-Info "Detected project type: $projectType"
Get-ConstitutionThresholds

# Gate 1: Dependency Rules
Write-Section "Gate 1: Dependency Rules"
switch -Wildcard ($projectType) {
    "node*" { Test-DependencyRulesNode }
    "dotnet" { Test-DependencyRulesDotNet }
    "java*" { Test-DependencyRulesJava }
    "python" {
        if (Test-Command "lint-imports") {
            Invoke-Check "Import Linter" { lint-imports }
        }
        else {
            Write-Warn "import-linter not installed (pip install import-linter)"
        }
    }
    default { Write-Info "Dependency rules not configured for $projectType" }
}

# Gate 2: Circular Dependencies
Write-Section "Gate 2: Circular Dependencies"
switch -Wildcard ($projectType) {
    "node*" { Test-CircularDependenciesNode }
    "dotnet" { Write-Info "Circular dependencies checked via NetArchTest in Gate 1" }
    "java*" { Write-Info "Circular dependencies checked via ArchUnit in Gate 1" }
    default { Write-Info "Circular dependency check not configured for $projectType" }
}

# Gate 3: Contract Validation
Write-Section "Gate 3: Contract Validation"
Test-OpenAPIContracts
Test-AsyncAPIContracts
Test-PactContracts

# Gate 4: Complexity Metrics
Write-Section "Gate 4: Complexity Metrics"
switch -Wildcard ($projectType) {
    "node*" { Test-ComplexityNode }
    "dotnet" { Test-ComplexityDotNet }
    "python" {
        if (Test-Command "radon") {
            Invoke-Check "Radon Complexity" { radon cc src -a -nc } -Critical $false
        }
        else {
            Write-Warn "radon not installed (pip install radon)"
        }
    }
    default { Write-Info "Complexity metrics not configured for $projectType" }
}

# Gate 5: Fitness Functions
Write-Section "Gate 5: Fitness Functions"
Test-BuildTime
Test-TestQuality

# Summary
Write-Section "Architecture Gates Summary"
Write-Host ""
Write-Host "  Passed:   $($Script:Passed)" -ForegroundColor Green
Write-Host "  Failed:   $($Script:Failed)" -ForegroundColor Red
Write-Host "  Warnings: $($Script:Warnings)" -ForegroundColor Yellow
Write-Host ""

if ($Script:Failed -gt 0) {
    Write-Fail "Architecture gates FAILED"
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  1. Review dependency rules in .dependency-cruiser.cjs"
    Write-Host "  2. Check for circular imports with 'npx madge --circular src'"
    Write-Host "  3. Validate OpenAPI specs with 'npx spectral lint specs/*/contracts/openapi.yaml'"
    Write-Host ""

    if ($CIMode) {
        exit 1
    }
}
else {
    if ($Script:Warnings -gt 0) {
        Write-Warn "Architecture gates PASSED with warnings"
        Write-Host "Consider addressing warnings to improve architecture quality."
    }
    else {
        Write-Success "All architecture gates PASSED"
    }
    exit 0
}
