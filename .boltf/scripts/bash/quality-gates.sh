#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Quality Gates Script
# =============================================================================
# Runs quality checks including linting, testing, and security scanning.
#
# Usage:
#   ./quality-gates.sh [--check|--fix] [--full]
#
# Options:
#   --check   Run checks without fixing (default)
#   --fix     Attempt to auto-fix issues
#   --full    Run full suite including security scan
# =============================================================================

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
MODE="check"
FULL_SUITE=false
BOLT_SCOPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            MODE="check"
            shift
            ;;
        --fix)
            MODE="fix"
            shift
            ;;
        --full)
            FULL_SUITE=true
            shift
            ;;
        --bolt-scope)
            BOLT_SCOPE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

# Track results
PASSED=0
FAILED=0
WARNINGS=0

# Security analysis flag
SECURITY_ENABLED=false

run_check() {
    local name="$1"
    local command="$2"

    log_info "Running: ${name}"

    if eval "${command}"; then
        log_success "${name} passed"
        ((PASSED++))
        return 0
    else
        log_error "${name} failed"
        ((FAILED++))
        return 1
    fi
}

# ── Stryker scope helpers ──────────────────────────────────────────────────────────────────────────

# Service name overrides for names that don't follow kebab-case → PascalCase convention.
declare -A SERVICE_NAME_MAP=(
    ["autenticacion-autorizacion"]="Auth"
    ["gestion-adjuntos"]="Attachments"
    ["gestion-peritos"]="Peritos"
    ["notificaciones-hub"]="Notifications"
)

kebab_to_pascal() {
    local kebab="$1"
    local result=""
    IFS='-' read -ra parts <<< "$kebab"
    for part in "${parts[@]}"; do
        [[ -n "$part" ]] && result+="${part^}"
    done
    echo "$result"
}

get_stryker_project_args() {
    # Outputs "--project Svc.Application.csproj --project Svc.Domain.csproj" or empty string.
    if [ "$BOLT_SCOPE" = "full" ]; then
        log_info "Stryker scope: full solution (forced)"
        echo ""; return
    fi
    local service_name="$BOLT_SCOPE"
    if [ -z "$service_name" ]; then
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ "$branch" =~ ^feature/([^/]+)(/|$) ]]; then
            local feature_name="${BASH_REMATCH[1]}"
            if [ -n "${SERVICE_NAME_MAP[$feature_name]+_}" ]; then
                service_name="${SERVICE_NAME_MAP[$feature_name]}"
            else
                service_name=$(kebab_to_pascal "$feature_name")
            fi
        fi
    fi
    if [ -z "$service_name" ]; then
        log_info "Stryker scope: full solution (no branch scope; pass --bolt-scope <name> to narrow)"
        echo ""; return
    fi
    log_info "Stryker scope: $service_name (Application + Domain)"
    echo "--project ${service_name}.Application.csproj --project ${service_name}.Domain.csproj"
}

get_stryker_feature_glob() {
    # Outputs --mutate glob for Angular/TS or empty string for full-solution.
    if [ "$BOLT_SCOPE" = "full" ]; then echo ""; return; fi
    local feature_name="$BOLT_SCOPE"
    if [ -z "$feature_name" ]; then
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ "$branch" =~ ^feature/([^/]+)/ ]]; then
            feature_name="${BASH_REMATCH[1]}"
        fi
    fi
    if [ -z "$feature_name" ]; then echo ""; return; fi
    echo "src/app/features/${feature_name}/**/*.ts"
}
    elif ls *.csproj 1> /dev/null 2>&1 || ls *.sln 1> /dev/null 2>&1; then
        echo "dotnet"
    elif [ -f "pom.xml" ]; then
        echo "java-maven"
    elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "java-gradle"
    else
        echo "unknown"
    fi
}

# Load thresholds from constitution if available
load_constitution_thresholds() {
    COVERAGE_THRESHOLD=80
    MUTATION_THRESHOLD=60

    local constitution_file
    if [ -f ".boltf/memory/constitution.md" ]; then
        constitution_file=".boltf/memory/constitution.md"
    elif [ -f "memory/constitution.md" ]; then
        constitution_file="memory/constitution.md"
    fi

    if [ -n "$constitution_file" ]; then
        log_info "Loading thresholds from constitution (${constitution_file})..."
        local content
        content=$(cat "$constitution_file")

        # Extract coverage threshold
        local cov_match
        cov_match=$(echo "$content" | grep -oP 'Coverage.*≥\s*\K\d+' | head -1)
        if [ -n "$cov_match" ]; then
            COVERAGE_THRESHOLD=$cov_match
            log_info "  Coverage threshold: ${COVERAGE_THRESHOLD}%"
        fi

        # Extract mutation threshold
        local mut_match
        mut_match=$(echo "$content" | grep -oP 'Mutation.*≥\s*\K\d+' | head -1)
        if [ -n "$mut_match" ]; then
            MUTATION_THRESHOLD=$mut_match
            log_info "  Mutation threshold: ${MUTATION_THRESHOLD}%"
        fi
    fi
}

PROJECT_TYPE=$(detect_project)
log_info "Detected project type: ${PROJECT_TYPE}"
load_constitution_thresholds

# =============================================================================
# Quality Gate 1: Type Checking
# =============================================================================
log_section "Type Checking"

case $PROJECT_TYPE in
    node-ts)
        run_check "TypeScript" "npx tsc --noEmit" || true
        ;;
    node)
        log_info "JavaScript project - no type checking (consider adding TypeScript)"
        ;;
    python)
        if command -v mypy &> /dev/null; then
            run_check "MyPy" "mypy src/" || true
        else
            log_warning "mypy not installed. Run: pip install mypy"
            ((WARNINGS++))
        fi
        ;;
    dotnet)
        # .NET build includes type checking
        run_check ".NET Build" "dotnet build --no-restore --verbosity quiet" || true
        ;;
    java-maven)
        run_check "Maven Compile" "mvn compile -q" || true
        ;;
    java-gradle)
        run_check "Gradle Compile" "gradle compileJava -q" || true
        ;;
    go)
        run_check "Go Vet" "go vet ./..." || true
        ;;
    rust)
        run_check "Cargo Check" "cargo check" || true
        ;;
    *)
        log_info "Type checking not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 2: Linting
# =============================================================================
log_section "Linting"

case $PROJECT_TYPE in
    node|node-ts)
        if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
            if [ "$MODE" = "fix" ]; then
                run_check "ESLint" "npx eslint . --fix" || true
            else
                run_check "ESLint" "npx eslint ." || true
            fi
        else
            log_warning "No ESLint config found"
            ((WARNINGS++))
        fi
        ;;
    python)
        if command -v ruff &> /dev/null; then
            if [ "$MODE" = "fix" ]; then
                run_check "Ruff" "ruff check --fix ." || true
            else
                run_check "Ruff" "ruff check ." || true
            fi
        elif command -v flake8 &> /dev/null; then
            run_check "Flake8" "flake8 ." || true
        else
            log_warning "No Python linter found (install ruff or flake8)"
            ((WARNINGS++))
        fi
        ;;
    dotnet)
        if [ "$MODE" = "fix" ]; then
            run_check ".NET Format" "dotnet format --verbosity quiet" || true
        else
            run_check ".NET Format Verify" "dotnet format --verify-no-changes --verbosity quiet" || true
        fi
        ;;
    java-maven)
        if [ -f "checkstyle.xml" ] || grep -q "checkstyle" pom.xml 2>/dev/null; then
            run_check "Checkstyle" "mvn checkstyle:check -q" || true
        else
            log_info "Checkstyle not configured in pom.xml"
        fi
        if grep -q "spotbugs" pom.xml 2>/dev/null; then
            run_check "SpotBugs" "mvn spotbugs:check -q" || true
        fi
        ;;
    java-gradle)
        if grep -q "checkstyle" build.gradle* 2>/dev/null; then
            run_check "Checkstyle" "gradle checkstyleMain -q" || true
        fi
        if grep -q "spotbugs" build.gradle* 2>/dev/null; then
            run_check "SpotBugs" "gradle spotbugsMain -q" || true
        fi
        ;;
    go)
        run_check "Go Vet" "go vet ./..." || true
        if command -v golangci-lint &> /dev/null; then
            run_check "GolangCI-Lint" "golangci-lint run" || true
        elif command -v golint &> /dev/null; then
            run_check "Golint" "golint ./..." || true
        fi
        ;;
    rust)
        run_check "Clippy" "cargo clippy -- -D warnings" || true
        ;;
    *)
        log_info "Linting not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 3: Formatting
# =============================================================================
log_section "Formatting"

case $PROJECT_TYPE in
    node|node-ts)
        if [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ] || [ -f "prettier.config.mjs" ]; then
            log_info "Running: Prettier"
            if [ "$MODE" = "fix" ]; then
                npx prettier --write . > /dev/null 2>&1 && log_success "Prettier fixed" || { log_warning "Prettier had issues"; ((WARNINGS++)); }
            else
                npx prettier --check . > /dev/null 2>&1 && log_success "Prettier passed" || { log_warning "Prettier formatting issues found (non-blocking)"; ((WARNINGS++)); }
            fi
        else
            log_info "Prettier not configured (optional)"
        fi
        ;;
    python)
        if command -v black &> /dev/null; then
            if [ "$MODE" = "fix" ]; then
                run_check "Black" "black ." || true
            else
                run_check "Black" "black --check ." || true
            fi
        elif command -v ruff &> /dev/null; then
            if [ "$MODE" = "fix" ]; then
                run_check "Ruff Format" "ruff format ." || true
            else
                run_check "Ruff Format" "ruff format --check ." || true
            fi
        fi
        ;;
    dotnet)
        # .NET format already handled in linting (same command)
        log_info ".NET formatting handled by 'dotnet format' in linting gate"
        ;;
    java-maven)
        if grep -q "fmt-maven-plugin\|google-java-format" pom.xml 2>/dev/null; then
            if [ "$MODE" = "fix" ]; then
                run_check "Google Java Format" "mvn fmt:format -q" || true
            else
                run_check "Google Java Format" "mvn fmt:check -q" || true
            fi
        else
            log_info "Java formatter not configured (consider google-java-format)"
        fi
        ;;
    java-gradle)
        if grep -q "spotless\|google-java-format" build.gradle* 2>/dev/null; then
            if [ "$MODE" = "fix" ]; then
                run_check "Spotless" "gradle spotlessApply -q" || true
            else
                run_check "Spotless" "gradle spotlessCheck -q" || true
            fi
        else
            log_info "Java formatter not configured (consider spotless plugin)"
        fi
        ;;
    go)
        if [ "$MODE" = "fix" ]; then
            run_check "Go Fmt" "go fmt ./..." || true
        else
            run_check "Go Fmt" "test -z \"\$(gofmt -l .)\"" || true
        fi
        ;;
    rust)
        if [ "$MODE" = "fix" ]; then
            run_check "Rustfmt" "cargo fmt" || true
        else
            run_check "Rustfmt" "cargo fmt -- --check" || true
        fi
        ;;
    *)
        log_info "Formatting not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 4: Unit Tests
# =============================================================================
log_section "Unit Tests"

case $PROJECT_TYPE in
    node|node-ts)
        if grep -q "\"test\"" package.json 2>/dev/null; then
            run_check "Jest/Vitest" "npm test -- --passWithNoTests" || true
        else
            log_warning "No test script in package.json"
            ((WARNINGS++))
        fi
        ;;
    python)
        if command -v pytest &> /dev/null; then
            run_check "Pytest" "pytest" || true
        elif [ -d "tests" ]; then
            run_check "Unittest" "python -m unittest discover tests" || true
        else
            log_warning "No test framework detected"
            ((WARNINGS++))
        fi
        ;;
    dotnet)
        run_check ".NET Tests" "dotnet test --no-build --verbosity quiet" || true
        ;;
    java-maven)
        run_check "Maven Tests" "mvn test -q" || true
        ;;
    java-gradle)
        run_check "Gradle Tests" "gradle test -q" || true
        ;;
    go)
        run_check "Go Test" "go test ./..." || true
        ;;
    rust)
        run_check "Cargo Test" "cargo test" || true
        ;;
    *)
        log_info "Testing not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 5: Coverage (MANDATORY - not optional)
# =============================================================================
log_section "Test Coverage"
log_info "Coverage threshold: ${COVERAGE_THRESHOLD}%"

case $PROJECT_TYPE in
    node|node-ts)
        # Check if test script exists before running
        if grep -q "\"test\"" package.json 2>/dev/null; then
            run_check "Coverage" "npm test -- --coverage --passWithNoTests" || true
        else
            log_warning "No test script in package.json - skipping coverage"
            ((WARNINGS++))
        fi
        ;;
    python)
        if command -v pytest &> /dev/null; then
            run_check "Coverage" "pytest --cov=src --cov-report=term-missing --cov-fail-under=${COVERAGE_THRESHOLD}" || true
        fi
        ;;
    dotnet)
        # Requires coverlet.collector package
        run_check "Coverage" "dotnet test --collect:\"XPlat Code Coverage\" --verbosity quiet" || true
        log_info "Reports at: TestResults/*/coverage.cobertura.xml"
        ;;
    java-maven)
        if grep -q "jacoco" pom.xml 2>/dev/null; then
            run_check "JaCoCo Coverage" "mvn jacoco:report -q" || true
            log_info "Reports at: target/site/jacoco/index.html"
        else
            log_warning "JaCoCo not configured in pom.xml"
            ((WARNINGS++))
        fi
        ;;
    java-gradle)
        if grep -q "jacoco" build.gradle* 2>/dev/null; then
            run_check "JaCoCo Coverage" "gradle jacocoTestReport -q" || true
            log_info "Reports at: build/reports/jacoco/"
        else
            log_warning "JaCoCo not configured in build.gradle"
            ((WARNINGS++))
        fi
        ;;
    go)
        run_check "Coverage" "go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out" || true
        ;;
    rust)
        if command -v cargo-tarpaulin &> /dev/null; then
            run_check "Tarpaulin Coverage" "cargo tarpaulin --ignore-tests" || true
        else
            log_warning "cargo-tarpaulin not installed. Run: cargo install cargo-tarpaulin"
            ((WARNINGS++))
        fi
        ;;
    *)
        log_info "Coverage not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 6: Mutation Testing (MANDATORY)
# =============================================================================
log_section "Mutation Testing"
log_info "Mutation threshold: ${MUTATION_THRESHOLD}%"

case $PROJECT_TYPE in
    node|node-ts)
        if [ -f "stryker.conf.js" ] || [ -f "stryker.conf.json" ] || [ -f "stryker.config.mjs" ]; then
            FEATURE_GLOB=$(get_stryker_feature_glob)
            if [ -n "$FEATURE_GLOB" ]; then
                run_check "Stryker Mutation" "npx stryker run --concurrency 2 --mutate \"$FEATURE_GLOB\"" || true
            else
                run_check "Stryker Mutation" "npx stryker run --concurrency 2" || true
            fi
        else
            log_warning "Stryker not configured. Run: npx stryker init"
            log_info "To install: npm install --save-dev @stryker-mutator/core @stryker-mutator/jest-runner"
            ((WARNINGS++))
        fi
        ;;
    python)
        if command -v mutmut &> /dev/null; then
            run_check "Mutmut" "mutmut run --paths-to-mutate=src/" || true
        else
            log_warning "mutmut not installed. Run: pip install mutmut"
            ((WARNINGS++))
        fi
        ;;
    dotnet)
        if command -v dotnet-stryker &> /dev/null || [ -f "stryker-config.json" ]; then
            PROJECT_ARGS=$(get_stryker_project_args)
            if [ -n "$PROJECT_ARGS" ]; then
                run_check "Stryker.NET" "dotnet stryker $PROJECT_ARGS" || true
            else
                run_check "Stryker.NET" "dotnet stryker" || true
            fi
        else
            log_warning "Stryker.NET not configured"
            log_info "To install: dotnet tool install -g dotnet-stryker"
            ((WARNINGS++))
        fi
        ;;
    java-maven)
        if grep -q "pitest" pom.xml 2>/dev/null; then
            run_check "PITest Mutation" "mvn pitest:mutationCoverage -q" || true
        else
            log_warning "PITest not configured in pom.xml"
            log_info "Add: org.pitest:pitest-maven plugin"
            ((WARNINGS++))
        fi
        ;;
    java-gradle)
        if grep -q "pitest" build.gradle* 2>/dev/null; then
            run_check "PITest Mutation" "gradle pitest -q" || true
        else
            log_warning "PITest not configured in build.gradle"
            log_info "Add: info.solidsoft.pitest plugin"
            ((WARNINGS++))
        fi
        ;;
    go)
        if command -v go-mutesting &> /dev/null; then
            run_check "Go Mutesting" "go-mutesting ./..." || true
        else
            log_info "go-mutesting not installed (optional)"
        fi
        ;;
    rust)
        log_info "Rust mutation testing: consider cargo-mutants (experimental)"
        ;;
    *)
        log_info "Mutation testing not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# Quality Gate 7: Security Analysis (Bolt Framework Security Agent)
# =============================================================================
run_security_analysis() {
    if [[ "$FULL_SUITE" == "true" ]] && [[ -f ".boltf/scripts/bash/security-analysis.sh" ]]; then
        log_section "Security Analysis (Bolt Framework Security Agent)"

        chmod +x .boltf/scripts/bash/security-analysis.sh

        if [[ "$MODE" == "fix" ]]; then
            run_check "SAST Analysis" "./.boltf/scripts/bash/security-analysis.sh --sast --severity medium"
            run_check "Dependency Scan" "./.boltf/scripts/bash/security-analysis.sh --sca"
            run_check "Secrets Detection" "./.boltf/scripts/bash/security-analysis.sh --secrets"
        else
            run_check "Security Analysis" "./.boltf/scripts/bash/security-analysis.sh --sast --sca --secrets --severity high"
        fi

        SECURITY_ENABLED=true
    elif [[ "$FULL_SUITE" == "true" ]]; then
        log_section "Fallback Security Scan"

        # Fallback to basic security checks if Bolt Framework Security Agent not available
        case $PROJECT_TYPE in
            node|node-ts)
                # NPM audit with non-blocking warnings
                log_info "Running: NPM Audit"
                npm audit --audit-level=moderate 2>&1 | tee /tmp/npm-audit.log || true
                ((WARNINGS++))
                ;;
            python)
                if command -v safety &> /dev/null; then
                    run_check "Safety" "safety check" || true
                elif command -v pip-audit &> /dev/null; then
                    run_check "Pip Audit" "pip-audit" || true
                elif command -v bandit &> /dev/null; then
                    run_check "Bandit" "bandit -r src/" || true
                else
                    log_warning "No Python security scanner found (install safety, pip-audit, or bandit)"
                    ((WARNINGS++))
                fi
                ;;
            dotnet)
                run_check ".NET Vulnerability Check" "dotnet list package --vulnerable --include-transitive" || true
                ;;
            java-maven)
                if grep -q "dependency-check" pom.xml 2>/dev/null; then
                    run_check "OWASP Dependency Check" "mvn dependency-check:check -q" || true
                else
                    log_info "OWASP dependency-check not configured (recommended)"
                    run_check "Maven Dependency Tree" "mvn dependency:tree -q" || true
                fi
                ;;
            java-gradle)
                if grep -q "dependency-check" build.gradle* 2>/dev/null; then
                    run_check "OWASP Dependency Check" "gradle dependencyCheckAnalyze -q" || true
                else
                    log_info "OWASP dependency-check not configured (recommended)"
            fi
            ;;
        go)
            if command -v govulncheck &> /dev/null; then
                run_check "Govulncheck" "govulncheck ./..." || true
            else
                log_warning "govulncheck not installed. Run: go install golang.org/x/vuln/cmd/govulncheck@latest"
                ((WARNINGS++))
            fi
            ;;
        rust)
            if command -v cargo-audit &> /dev/null; then
                run_check "Cargo Audit" "cargo audit" || true
            else
                log_warning "cargo-audit not installed. Run: cargo install cargo-audit"
                ((WARNINGS++))
            fi
            ;;
        *)
            log_info "Security scanning not configured for ${PROJECT_TYPE}"
            ;;
    esac
    fi
}
run_security_analysis

# =============================================================================
# Summary
# =============================================================================
log_section "Quality Gate Summary"

echo ""
echo -e "  ${GREEN}Passed:${NC}   ${PASSED}"
echo -e "  ${RED}Failed:${NC}   ${FAILED}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARNINGS}"
if [[ "$SECURITY_ENABLED" == "true" ]]; then
    echo -e "  ${BLUE}Security:${NC} Bolt Framework Security Agent executed"
fi
echo ""

if [ $FAILED -gt 0 ]; then
    log_error "Quality gates FAILED"
    echo ""
    echo "Run with --fix to attempt automatic fixes"
    exit 1
else
    log_success "All quality gates PASSED"
    exit 0
fi
