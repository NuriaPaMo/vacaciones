<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Quality Gates Script

.DESCRIPTION
    Runs quality checks including linting, testing, and security scanning.

.PARAMETER Check
    Run checks without fixing (default behavior).

.PARAMETER Fix
    Attempt to auto-fix issues where possible.

.PARAMETER Full
    Run full suite including security scan and coverage.

.EXAMPLE
    .\Quality-Gates.ps1 -Check

.EXAMPLE
    .\Quality-Gates.ps1 -Fix -Full
#>

param(
    [switch]$Check,
    [switch]$Fix,
    [switch]$Full,
    # Scope mutation testing to a specific service/module (Bolt-scope mode).
    # Auto-detected from git branch (feature/<name>/...) if omitted.
    # Pass 'full' to force full-solution scan regardless of branch.
    [string]$BoltScope = ""
)

# Default to check mode if neither specified
if (-not $Check -and -not $Fix) {
    $Check = $true
}

# Track results
$Script:Passed = 0
$Script:Failed = 0
$Script:Warnings = 0

# Helper functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success {
    Write-Host "[✓] $args" -ForegroundColor Green
    $Script:Passed++
}
function Write-Warning {
    Write-Host "[⚠] $args" -ForegroundColor Yellow
    $Script:Warnings++
}
function Write-Fail {
    Write-Host "[✗] $args" -ForegroundColor Red
    $Script:Failed++
}
function Write-Section {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "  $args" -ForegroundColor Blue
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Blue
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Info "Running: $Name"

    try {
        & $Command
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-Success "$Name passed"
            return $true
        } else {
            Write-Fail "$Name failed"
            return $false
        }
    } catch {
        Write-Fail "$Name failed: $_"
        return $false
    }
}

# ── Stryker scope helpers ───────────────────────────────────────────────────────────────────────────────

# Service name overrides for names that don't follow kebab-case → PascalCase convention.
# Add project-specific entries here or in a consumer repo overlay.
$script:ServiceNameMap = @{
    'autenticacion-autorizacion' = 'Auth'
    'gestion-adjuntos'           = 'Attachments'
    'gestion-peritos'            = 'Peritos'
    'notificaciones-hub'         = 'Notifications'
}

function Convert-KebabToPascal {
    param([string]$kebab)
    ($kebab -split '-' | ForEach-Object {
        if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1) } else { '' }
    }) -join ''
}

function Get-StrykerProjectArgs {
    # Returns @('--project', 'Svc.Application.csproj', '--project', 'Svc.Domain.csproj')
    # or @() for full-solution (no filter). Reads $BoltScope from outer scope.
    if ($BoltScope -eq 'full') {
        Write-Info "Stryker scope: full solution (forced)"
        return @()
    }
    $serviceName = $BoltScope
    if (-not $serviceName) {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch -match '^feature/([^/]+)(/|$)') {
            $featureName = $Matches[1]
            $serviceName = if ($script:ServiceNameMap.ContainsKey($featureName)) {
                $script:ServiceNameMap[$featureName]
            } else {
                Convert-KebabToPascal $featureName
            }
        }
    }
    if (-not $serviceName) {
        Write-Info "Stryker scope: full solution (no branch scope detected; pass -BoltScope <name> to narrow)"
        return @()
    }
    Write-Info "Stryker scope: $serviceName (Application + Domain)"
    return @("--project", "$serviceName.Application.csproj", "--project", "$serviceName.Domain.csproj")
}

function Get-StrykerFeatureGlob {
    # Returns the Angular/TS feature folder glob for --mutate, or empty string for full-solution.
    if ($BoltScope -eq 'full') { return '' }
    $featureName = $BoltScope
    if (-not $featureName) {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch -match '^feature/([^/]+)(/|$)') { $featureName = $Matches[1] }
    }
    if (-not $featureName) { return '' }
    return "src/app/features/$featureName/**/*.ts"
}

# Detect project type
function Get-ProjectType {
    if (Test-Path "package.json") {
        if (Test-Path "tsconfig.json") { return "node-ts" }
        return "node"
    }
    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml") -or (Test-Path "setup.py")) { return "python" }
    if (Test-Path "go.mod") { return "go" }
    if (Test-Path "Cargo.toml") { return "rust" }
    if ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue) -or (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) { return "dotnet" }
    if (Test-Path "pom.xml") { return "java-maven" }
    if ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) { return "java-gradle" }
    return "unknown"
}

# Load thresholds from constitution
function Get-ConstitutionThresholds {
    $Script:CoverageThreshold = 80
    $Script:MutationThreshold = 60

    if (Test-Path ".boltf/memory/constitution.md") {
        Write-Info "Loading thresholds from constitution..."
        $content = Get-Content ".boltf/memory/constitution.md" -Raw

        if ($content -match "Coverage.*≥\s*(\d+)") {
            $Script:CoverageThreshold = [int]$Matches[1]
            Write-Info "  Coverage threshold: $($Script:CoverageThreshold)%"
        }
        if ($content -match "Mutation.*≥\s*(\d+)") {
            $Script:MutationThreshold = [int]$Matches[1]
            Write-Info "  Mutation threshold: $($Script:MutationThreshold)%"
        }
    }
}

$ProjectType = Get-ProjectType
Write-Info "Detected project type: $ProjectType"
Get-ConstitutionThresholds

# =============================================================================
# Quality Gate 1: Type Checking
# =============================================================================
Write-Section "Type Checking"

switch ($ProjectType) {
    "node-ts" {
        Invoke-Check "TypeScript" { npx tsc --noEmit }
    }
    "node" {
        Write-Info "JavaScript project - no type checking (consider adding TypeScript)"
    }
    "python" {
        if (Get-Command mypy -ErrorAction SilentlyContinue) {
            Invoke-Check "MyPy" { mypy src/ }
        } else {
            Write-Warning "mypy not installed. Run: pip install mypy"
        }
    }
    "dotnet" {
        Invoke-Check ".NET Build" { dotnet build --no-restore --verbosity quiet }
    }
    "java-maven" {
        Invoke-Check "Maven Compile" { mvn compile -q }
    }
    "java-gradle" {
        Invoke-Check "Gradle Compile" { gradle compileJava -q }
    }
    "go" {
        Invoke-Check "Go Vet" { go vet ./... }
    }
    "rust" {
        Invoke-Check "Cargo Check" { cargo check }
    }
    default {
        Write-Info "Type checking not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 2: Linting
# =============================================================================
Write-Section "Linting"

switch ($ProjectType) {
    { $_ -in "node", "node-ts" } {
        if ((Test-Path ".eslintrc.js") -or (Test-Path ".eslintrc.json") -or (Test-Path "eslint.config.js") -or (Test-Path "eslint.config.mjs")) {
            if ($Fix) {
                Invoke-Check "ESLint" { npx eslint . --fix }
            } else {
                Invoke-Check "ESLint" { npx eslint . }
            }
        } else {
            Write-Warning "No ESLint config found"
        }
    }
    "python" {
        if (Get-Command ruff -ErrorAction SilentlyContinue) {
            if ($Fix) {
                Invoke-Check "Ruff" { ruff check --fix . }
            } else {
                Invoke-Check "Ruff" { ruff check . }
            }
        } elseif (Get-Command flake8 -ErrorAction SilentlyContinue) {
            Invoke-Check "Flake8" { flake8 . }
        } else {
            Write-Warning "No Python linter found (install ruff or flake8)"
        }
    }
    "dotnet" {
        if ($Fix) {
            Invoke-Check ".NET Format" { dotnet format --verbosity quiet }
        } else {
            Invoke-Check ".NET Format Verify" { dotnet format --verify-no-changes --verbosity quiet }
        }
    }
    "java-maven" {
        $pomContent = Get-Content "pom.xml" -Raw -ErrorAction SilentlyContinue
        if ((Test-Path "checkstyle.xml") -or ($pomContent -match "checkstyle")) {
            Invoke-Check "Checkstyle" { mvn checkstyle:check -q }
        } else {
            Write-Info "Checkstyle not configured in pom.xml"
        }
        if ($pomContent -match "spotbugs") {
            Invoke-Check "SpotBugs" { mvn spotbugs:check -q }
        }
    }
    "java-gradle" {
        $gradleContent = Get-Content "build.gradle*" -Raw -ErrorAction SilentlyContinue
        if ($gradleContent -match "checkstyle") {
            Invoke-Check "Checkstyle" { gradle checkstyleMain -q }
        }
        if ($gradleContent -match "spotbugs") {
            Invoke-Check "SpotBugs" { gradle spotbugsMain -q }
        }
    }
    "go" {
        Invoke-Check "Go Vet" { go vet ./... }
        if (Get-Command golangci-lint -ErrorAction SilentlyContinue) {
            Invoke-Check "GolangCI-Lint" { golangci-lint run }
        }
    }
    "rust" {
        Invoke-Check "Clippy" { cargo clippy -- -D warnings }
    }
    default {
        Write-Info "Linting not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 3: Formatting
# =============================================================================
Write-Section "Formatting"

switch ($ProjectType) {
    { $_ -in "node", "node-ts" } {
        if ((Test-Path ".prettierrc") -or (Test-Path ".prettierrc.json") -or (Test-Path "prettier.config.js") -or (Test-Path "prettier.config.mjs")) {
            if ($Fix) {
                Invoke-Check "Prettier" { npx prettier --write . }
            } else {
                Invoke-Check "Prettier" { npx prettier --check . }
            }
        } else {
            Write-Info "Prettier not configured (optional)"
        }
    }
    "python" {
        if (Get-Command black -ErrorAction SilentlyContinue) {
            if ($Fix) {
                Invoke-Check "Black" { black . }
            } else {
                Invoke-Check "Black" { black --check . }
            }
        } elseif (Get-Command ruff -ErrorAction SilentlyContinue) {
            if ($Fix) {
                Invoke-Check "Ruff Format" { ruff format . }
            } else {
                Invoke-Check "Ruff Format" { ruff format --check . }
            }
        }
    }
    "dotnet" {
        Write-Info ".NET formatting handled by 'dotnet format' in linting gate"
    }
    "java-maven" {
        $pomContent = Get-Content "pom.xml" -Raw -ErrorAction SilentlyContinue
        if ($pomContent -match "fmt-maven-plugin|google-java-format") {
            if ($Fix) {
                Invoke-Check "Google Java Format" { mvn fmt:format -q }
            } else {
                Invoke-Check "Google Java Format" { mvn fmt:check -q }
            }
        } else {
            Write-Info "Java formatter not configured (consider google-java-format)"
        }
    }
    "java-gradle" {
        $gradleContent = Get-Content "build.gradle*" -Raw -ErrorAction SilentlyContinue
        if ($gradleContent -match "spotless|google-java-format") {
            if ($Fix) {
                Invoke-Check "Spotless" { gradle spotlessApply -q }
            } else {
                Invoke-Check "Spotless" { gradle spotlessCheck -q }
            }
        } else {
            Write-Info "Java formatter not configured (consider spotless plugin)"
        }
    }
    "go" {
        if ($Fix) {
            Invoke-Check "Go Fmt" { go fmt ./... }
        } else {
            Invoke-Check "Go Fmt Check" {
                $output = gofmt -l .
                if ($output) { throw "Files need formatting" }
            }
        }
    }
    "rust" {
        if ($Fix) {
            Invoke-Check "Rustfmt" { cargo fmt }
        } else {
            Invoke-Check "Rustfmt" { cargo fmt -- --check }
        }
    }
    default {
        Write-Info "Formatting not configured for $ProjectType"
    }
}
        Write-Info "Formatting not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 4: Unit Tests
# =============================================================================
Write-Section "Unit Tests"

switch ($ProjectType) {
    { $_ -in "node", "node-ts" } {
        $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($packageJson.scripts.test) {
            Invoke-Check "Jest/Vitest" { npm test -- --passWithNoTests }
        } else {
            Write-Warning "No test script in package.json"
        }
    }
    "python" {
        if (Get-Command pytest -ErrorAction SilentlyContinue) {
            Invoke-Check "Pytest" { pytest }
        } elseif (Test-Path "tests") {
            Invoke-Check "Unittest" { python -m unittest discover tests }
        } else {
            Write-Warning "No test framework detected"
        }
    }
    "dotnet" {
        Invoke-Check ".NET Tests" { dotnet test --no-build --verbosity quiet }
    }
    "java-maven" {
        Invoke-Check "Maven Tests" { mvn test -q }
    }
    "java-gradle" {
        Invoke-Check "Gradle Tests" { gradle test -q }
    }
    "go" {
        Invoke-Check "Go Test" { go test ./... }
    }
    "rust" {
        Invoke-Check "Cargo Test" { cargo test }
    }
    default {
        Write-Info "Testing not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 5: Coverage (MANDATORY - not optional)
# =============================================================================
Write-Section "Test Coverage"
Write-Info "Coverage threshold: $($Script:CoverageThreshold)%"

switch ($ProjectType) {
    { $_ -in "node", "node-ts" } {
        Invoke-Check "Coverage" { npm test -- --coverage --passWithNoTests }
    }
    "python" {
        if (Get-Command pytest -ErrorAction SilentlyContinue) {
            Invoke-Check "Coverage" { pytest --cov=src --cov-report=term-missing --cov-fail-under=$Script:CoverageThreshold }
        }
    }
    "dotnet" {
        Invoke-Check "Coverage" { dotnet test --collect:"XPlat Code Coverage" --verbosity quiet }
        Write-Info "Reports at: TestResults/*/coverage.cobertura.xml"
    }
    "java-maven" {
        $pomContent = Get-Content "pom.xml" -Raw -ErrorAction SilentlyContinue
        if ($pomContent -match "jacoco") {
            Invoke-Check "JaCoCo Coverage" { mvn jacoco:report -q }
            Write-Info "Reports at: target/site/jacoco/index.html"
        } else {
            Write-Warning "JaCoCo not configured in pom.xml"
        }
    }
    "java-gradle" {
        $gradleContent = Get-Content "build.gradle*" -Raw -ErrorAction SilentlyContinue
        if ($gradleContent -match "jacoco") {
            Invoke-Check "JaCoCo Coverage" { gradle jacocoTestReport -q }
            Write-Info "Reports at: build/reports/jacoco/"
        } else {
            Write-Warning "JaCoCo not configured in build.gradle"
        }
    }
    "go" {
        Invoke-Check "Coverage" { go test -coverprofile=coverage.out ./...; go tool cover -func=coverage.out }
    }
    "rust" {
        if (Get-Command cargo-tarpaulin -ErrorAction SilentlyContinue) {
            Invoke-Check "Tarpaulin Coverage" { cargo tarpaulin --ignore-tests }
        } else {
            Write-Warning "cargo-tarpaulin not installed. Run: cargo install cargo-tarpaulin"
        }
    }
    default {
        Write-Info "Coverage not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 6: Mutation Testing (MANDATORY)
# =============================================================================
Write-Section "Mutation Testing"
Write-Info "Mutation threshold: $($Script:MutationThreshold)%"

switch ($ProjectType) {
    { $_ -in "node", "node-ts" } {
        if ((Test-Path "stryker.conf.js") -or (Test-Path "stryker.conf.json") -or (Test-Path "stryker.config.mjs")) {
            $featureGlob = Get-StrykerFeatureGlob
            $strykerTsCmd = if ($featureGlob) {
                "npx stryker run --concurrency 2 --mutate `"$featureGlob`""
            } else {
                "npx stryker run --concurrency 2"
            }
            Invoke-Check "Stryker Mutation" ([scriptblock]::Create($strykerTsCmd))
        } else {
            Write-Warning "Stryker not configured. Run: npx stryker init"
            Write-Info "To install: npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner"
        }
    }
    "python" {
        if (Get-Command mutmut -ErrorAction SilentlyContinue) {
            Invoke-Check "Mutmut" { mutmut run --paths-to-mutate=src/ }
        } else {
            Write-Warning "mutmut not installed. Run: pip install mutmut"
        }
    }
    "dotnet" {
        if ((Get-Command dotnet-stryker -ErrorAction SilentlyContinue) -or (Test-Path "stryker-config.json")) {
            $projectArgs = Get-StrykerProjectArgs
            $strykerNetCmd = if ($projectArgs.Count -gt 0) {
                "dotnet stryker " + ($projectArgs -join ' ')
            } else {
                "dotnet stryker"
            }
            Invoke-Check "Stryker.NET" ([scriptblock]::Create($strykerNetCmd))
        } else {
            Write-Warning "Stryker.NET not configured"
            Write-Info "To install: dotnet tool install -g dotnet-stryker"
        }
    }
    "java-maven" {
        $pomContent = Get-Content "pom.xml" -Raw -ErrorAction SilentlyContinue
        if ($pomContent -match "pitest") {
            Invoke-Check "PITest Mutation" { mvn pitest:mutationCoverage -q }
        } else {
            Write-Warning "PITest not configured in pom.xml"
            Write-Info "Add: org.pitest:pitest-maven plugin"
        }
    }
    "java-gradle" {
        $gradleContent = Get-Content "build.gradle*" -Raw -ErrorAction SilentlyContinue
        if ($gradleContent -match "pitest") {
            Invoke-Check "PITest Mutation" { gradle pitest -q }
        } else {
            Write-Warning "PITest not configured in build.gradle"
            Write-Info "Add: info.solidsoft.pitest plugin"
        }
    }
    "go" {
        if (Get-Command go-mutesting -ErrorAction SilentlyContinue) {
            Invoke-Check "Go Mutesting" { go-mutesting ./... }
        } else {
            Write-Info "go-mutesting not installed (optional)"
        }
    }
    "rust" {
        Write-Info "Rust mutation testing: consider cargo-mutants (experimental)"
    }
    default {
        Write-Info "Mutation testing not configured for $ProjectType"
    }
}

# =============================================================================
# Quality Gate 7: Security Scan (if -Full)
# =============================================================================
if ($Full) {
    Write-Section "Security Scan"

    switch ($ProjectType) {
        { $_ -in "node", "node-ts" } {
            Invoke-Check "NPM Audit" { npm audit --audit-level=high }
        }
        "python" {
            if (Get-Command safety -ErrorAction SilentlyContinue) {
                Invoke-Check "Safety" { safety check }
            } elseif (Get-Command pip-audit -ErrorAction SilentlyContinue) {
                Invoke-Check "Pip Audit" { pip-audit }
            } elseif (Get-Command bandit -ErrorAction SilentlyContinue) {
                Invoke-Check "Bandit" { bandit -r src/ }
            } else {
                Write-Warning "No Python security scanner found (install safety, pip-audit, or bandit)"
            }
        }
        "dotnet" {
            Invoke-Check ".NET Vulnerability Check" { dotnet list package --vulnerable --include-transitive }
        }
        "java-maven" {
            $pomContent = Get-Content "pom.xml" -Raw -ErrorAction SilentlyContinue
            if ($pomContent -match "dependency-check") {
                Invoke-Check "OWASP Dependency Check" { mvn dependency-check:check -q }
            } else {
                Write-Info "OWASP dependency-check not configured (recommended)"
                Invoke-Check "Maven Dependency Tree" { mvn dependency:tree -q }
            }
        }
        "java-gradle" {
            $gradleContent = Get-Content "build.gradle*" -Raw -ErrorAction SilentlyContinue
            if ($gradleContent -match "dependency-check") {
                Invoke-Check "OWASP Dependency Check" { gradle dependencyCheckAnalyze -q }
            } else {
                Write-Info "OWASP dependency-check not configured (recommended)"
            }
        }
        "go" {
            if (Get-Command govulncheck -ErrorAction SilentlyContinue) {
                Invoke-Check "Govulncheck" { govulncheck ./... }
            } else {
                Write-Warning "govulncheck not installed. Run: go install golang.org/x/vuln/cmd/govulncheck@latest"
            }
        }
        "rust" {
            if (Get-Command cargo-audit -ErrorAction SilentlyContinue) {
                Invoke-Check "Cargo Audit" { cargo audit }
            } else {
                Write-Warning "cargo-audit not installed. Run: cargo install cargo-audit"
            }
        }
        default {
            Write-Info "Security scanning not configured for $ProjectType"
        }
    }
}

# =============================================================================
# Quality Gate 8: Architecture Gates (if -Full)
# =============================================================================
if ($Full) {
    Write-Section "Architecture Quality Gates"

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $archGates = Join-Path $scriptDir "Architecture-Gates.ps1"

    if (Test-Path $archGates) {
        Write-Info "Running architecture validation..."
        try {
            & $archGates -Check
            Write-Success "Architecture gates passed"
        } catch {
            Write-Warning "Architecture gates have issues (non-blocking)"
        }
    } else {
        Write-Warning "Architecture-Gates.ps1 not found"
        Write-Info "Expected at: $archGates"
    }
}

# =============================================================================
# Summary
# =============================================================================
Write-Section "Quality Gate Summary"

Write-Host ""
Write-Host "  Passed:   $Script:Passed" -ForegroundColor Green
Write-Host "  Failed:   $Script:Failed" -ForegroundColor Red
Write-Host "  Warnings: $Script:Warnings" -ForegroundColor Yellow
Write-Host ""

if ($Script:Failed -gt 0) {
    Write-Host "[ERROR] Quality gates FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run with -Fix to attempt automatic fixes"
    exit 1
} else {
    Write-Host "[SUCCESS] All quality gates PASSED" -ForegroundColor Green
    exit 0
}
