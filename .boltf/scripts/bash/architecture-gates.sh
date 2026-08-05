#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Architecture Quality Gates Script
# =============================================================================
# Validates architectural rules: dependency boundaries, contracts, complexity.
#
# Usage:
#   ./architecture-gates.sh [--check|--report] [--fix] [--ci-mode]
#
# Options:
#   --check     Run all architecture checks (default)
#   --report    Generate detailed HTML report
#   --fix       Auto-fix where possible (formatting, simple violations)
#   --ci-mode   Exit with error code on any failure (for CI pipelines)
#
# Quality Gates Covered:
#   1. Dependency Rules (layer enforcement)
#   2. Circular Dependencies Detection
#   3. Contract Validation (OpenAPI/AsyncAPI)
#   4. Complexity Metrics
#   5. Fitness Functions
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default options
MODE="check"
GENERATE_REPORT=false
FIX_MODE=false
CI_MODE=false

# Thresholds (can be overridden via constitution)
MAX_CYCLOMATIC_COMPLEXITY=10
MAX_COGNITIVE_COMPLEXITY=15
MAX_FUNCTION_LINES=50
MAX_FILE_LINES=400
MAX_FAN_OUT=10

# Track results
PASSED=0
FAILED=0
WARNINGS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            MODE="check"
            shift
            ;;
        --report)
            GENERATE_REPORT=true
            shift
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --ci-mode)
            CI_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./architecture-gates.sh [--check|--report] [--fix] [--ci-mode]"
            exit 1
            ;;
    esac
done

# Logging functions
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
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  🏗️  $1${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
}

# Run a check and track results
run_check() {
    local name="$1"
    local command="$2"
    local critical="${3:-true}"  # Default: critical failure

    log_info "Running: ${name}"

    if eval "${command}"; then
        log_success "${name} passed"
        ((PASSED++))
        return 0
    else
        if [ "$critical" = "true" ]; then
            log_error "${name} FAILED"
            ((FAILED++))
        else
            log_warning "${name} has warnings"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Detect project type
detect_project() {
    if [ -f "package.json" ]; then
        if grep -q "typescript" package.json 2>/dev/null; then
            echo "node-ts"
        else
            echo "node"
        fi
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "*.csproj" ] || [ -f "*.sln" ]; then
        echo "dotnet"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        echo "java"
    else
        echo "unknown"
    fi
}

# Load thresholds from constitution if available
load_constitution_thresholds() {
    local constitution=".boltf/memory/constitution.md"
    if [ -f "$constitution" ]; then
        log_info "Loading thresholds from constitution..."
        # Parse thresholds from constitution (simplified - could use yq/jq for YAML/JSON)
        local cc=$(grep -oP "Cyclomatic Complexity.*≤\s*\K\d+" "$constitution" 2>/dev/null || echo "")
        if [ -n "$cc" ]; then
            MAX_CYCLOMATIC_COMPLEXITY=$cc
            log_info "  Cyclomatic Complexity threshold: $cc"
        fi
    fi
}

PROJECT_TYPE=$(detect_project)
log_info "Detected project type: ${PROJECT_TYPE}"
load_constitution_thresholds

# =============================================================================
# GATE 1: Dependency Rules (Layer Enforcement)
# =============================================================================
log_section "Gate 1: Dependency Rules"

check_dependency_rules_node() {
    # Check if dependency-cruiser is available
    if [ -f ".dependency-cruiser.cjs" ] || [ -f ".dependency-cruiser.js" ]; then
        run_check "Dependency Cruiser" "npx depcruise --config .dependency-cruiser.cjs src --output-type err-long" || true
    elif command -v npx &> /dev/null && npm ls dependency-cruiser &>/dev/null 2>&1; then
        log_warning "dependency-cruiser installed but no config found"
        log_info "Creating default architecture rules..."
        create_default_depcruise_config
        run_check "Dependency Cruiser (default)" "npx depcruise --config .dependency-cruiser.cjs src --output-type err-long" "false" || true
    else
        log_warning "dependency-cruiser not installed"
        log_info "To install: npm install --save-dev dependency-cruiser"
        log_info "To init: npx depcruise --init"
        ((WARNINGS++))
    fi

    # Check eslint-plugin-boundaries if available
    if grep -q "eslint-plugin-boundaries" package.json 2>/dev/null; then
        log_info "eslint-plugin-boundaries detected - rules enforced via ESLint"
    fi
}

check_dependency_rules_dotnet() {
    # Check for NetArchTest or ArchUnitNET
    if find . -name "*ArchitectureTests*.cs" -o -name "*ArchTests*.cs" 2>/dev/null | grep -q .; then
        run_check "Architecture Tests (.NET)" "dotnet test --filter 'Category=Architecture|FullyQualifiedName~Architecture'" || true
    else
        log_warning "No architecture tests found"
        log_info "Consider adding NetArchTest: dotnet add package NetArchTest.Rules"
        log_info "Create tests in: tests/Architecture/ArchitectureTests.cs"
        ((WARNINGS++))
    fi
}

check_dependency_rules_java() {
    # Check for ArchUnit
    if find . -name "*ArchitectureTest*.java" -o -name "*ArchTest*.java" 2>/dev/null | grep -q .; then
        run_check "ArchUnit Tests" "mvn test -Dtest=*ArchTest* || gradle test --tests '*ArchTest*'" || true
    else
        log_warning "No ArchUnit tests found"
        log_info "Consider adding ArchUnit: com.tngtech.archunit:archunit-junit5"
        ((WARNINGS++))
    fi
}

create_default_depcruise_config() {
    cat > .dependency-cruiser.cjs << 'EOF'
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    // Domain layer cannot depend on infrastructure or presentation
    {
      name: 'domain-no-infra',
      comment: 'Domain layer must not depend on infrastructure',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/infrastructure' }
    },
    {
      name: 'domain-no-presentation',
      comment: 'Domain layer must not depend on presentation',
      severity: 'error',
      from: { path: '^src/domain' },
      to: { path: '^src/presentation|^src/api|^src/controllers' }
    },
    // Application layer cannot depend on presentation
    {
      name: 'application-no-presentation',
      comment: 'Application layer must not depend on presentation',
      severity: 'error',
      from: { path: '^src/application' },
      to: { path: '^src/presentation|^src/api|^src/controllers' }
    },
    // No circular dependencies
    {
      name: 'no-circular',
      comment: 'No circular dependencies allowed',
      severity: 'error',
      from: {},
      to: { circular: true }
    },
    // No orphan modules
    {
      name: 'no-orphans',
      comment: 'No orphan modules (unreachable code)',
      severity: 'warn',
      from: { orphan: true, pathNot: '\\.d\\.ts$|__tests__|__mocks__|spec\\.ts$' },
      to: {}
    }
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default']
    },
    reporterOptions: {
      dot: { collapsePattern: 'node_modules/[^/]+' },
      archi: { collapsePattern: '^(node_modules|packages)/[^/]+' }
    }
  }
};
EOF
    log_success "Created default .dependency-cruiser.cjs"
}

case $PROJECT_TYPE in
    node|node-ts)
        check_dependency_rules_node
        ;;
    dotnet)
        check_dependency_rules_dotnet
        ;;
    java)
        check_dependency_rules_java
        ;;
    python)
        # Python: check with import-linter or pydeps
        if command -v lint-imports &> /dev/null; then
            run_check "Import Linter" "lint-imports" || true
        else
            log_warning "import-linter not installed (pip install import-linter)"
            ((WARNINGS++))
        fi
        ;;
    *)
        log_info "Dependency rules not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# GATE 2: Circular Dependencies
# =============================================================================
log_section "Gate 2: Circular Dependencies"

check_circular_deps_node() {
    if command -v npx &> /dev/null; then
        # Try madge first (visual + detection)
        if npm ls madge &>/dev/null 2>&1 || command -v madge &> /dev/null; then
            if [ "$GENERATE_REPORT" = true ]; then
                log_info "Generating dependency graph..."
                npx madge --image reports/dependency-graph.svg src 2>/dev/null || true
            fi
            run_check "Circular Dependencies (madge)" "npx madge --circular src" || true
        else
            log_info "madge not installed - using dependency-cruiser for cycle detection"
            # Already checked in Gate 1 if depcruise is configured
        fi
    fi
}

case $PROJECT_TYPE in
    node|node-ts)
        check_circular_deps_node
        ;;
    dotnet)
        log_info "Circular dependencies checked via NetArchTest in Gate 1"
        ;;
    java)
        log_info "Circular dependencies checked via ArchUnit in Gate 1"
        ;;
    *)
        log_info "Circular dependency check not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# GATE 3: Contract Validation (OpenAPI / AsyncAPI)
# =============================================================================
log_section "Gate 3: Contract Validation"

check_openapi_contracts() {
    local openapi_files=$(find specs -name "openapi.yaml" -o -name "openapi.json" 2>/dev/null)

    if [ -n "$openapi_files" ]; then
        log_info "Found OpenAPI specs: $openapi_files"

        # Validate OpenAPI syntax with Spectral
        if command -v spectral &> /dev/null || npm ls @stoplight/spectral-cli &>/dev/null 2>&1; then
            for spec in $openapi_files; do
                run_check "OpenAPI Lint: $spec" "npx @stoplight/spectral-cli lint $spec" "false" || true
            done
        else
            log_warning "Spectral not installed for OpenAPI validation"
            log_info "To install: npm install --save-dev @stoplight/spectral-cli"
            ((WARNINGS++))
        fi

        # Check if implementation matches spec (with openapi-diff or similar)
        # This requires running the actual API and comparing
    else
        log_info "No OpenAPI specs found in specs/"
    fi
}

check_asyncapi_contracts() {
    local asyncapi_files=$(find specs -name "asyncapi.yaml" -o -name "asyncapi.json" 2>/dev/null)

    if [ -n "$asyncapi_files" ]; then
        log_info "Found AsyncAPI specs: $asyncapi_files"

        if command -v asyncapi &> /dev/null; then
            for spec in $asyncapi_files; do
                run_check "AsyncAPI Validate: $spec" "asyncapi validate $spec" "false" || true
            done
        else
            log_warning "AsyncAPI CLI not installed"
            log_info "To install: npm install -g @asyncapi/cli"
            ((WARNINGS++))
        fi
    fi
}

check_pact_contracts() {
    # Check for Pact contract tests
    if [ -d "pacts" ] || find . -name "*.pact.json" -o -name "*Pact*Test*" 2>/dev/null | grep -q .; then
        log_info "Pact contracts detected"
        case $PROJECT_TYPE in
            node|node-ts)
                run_check "Pact Verification" "npm run test:pact 2>/dev/null || npx jest --testPathPattern=pact" "false" || true
                ;;
            dotnet)
                run_check "Pact Verification" "dotnet test --filter 'Category=Pact'" "false" || true
                ;;
        esac
    else
        log_info "No Pact contracts found"
    fi
}

check_openapi_contracts
check_asyncapi_contracts
check_pact_contracts

# =============================================================================
# GATE 4: Complexity Metrics
# =============================================================================
log_section "Gate 4: Complexity Metrics"

check_complexity_node() {
    # ESLint complexity rules
    if [ -f "eslint.config.mjs" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
        log_info "Checking ESLint complexity rules..."
        # Check if complexity rules are configured
        if grep -q "complexity" eslint.config.mjs .eslintrc.* 2>/dev/null; then
            log_success "ESLint complexity rules configured"
        else
            log_warning "Consider adding complexity rules to ESLint:"
            log_info "  'complexity': ['error', { max: $MAX_CYCLOMATIC_COMPLEXITY }]"
            log_info "  'max-lines-per-function': ['error', { max: $MAX_FUNCTION_LINES }]"
            log_info "  'max-lines': ['error', { max: $MAX_FILE_LINES }]"
        fi
    fi

    # SonarQube/SonarCloud analysis
    if [ -f "sonar-project.properties" ]; then
        log_info "SonarQube configured - complexity metrics available in dashboard"
    fi

    # ts-complexity-report
    if npm ls ts-complexity-report &>/dev/null 2>&1; then
        run_check "TypeScript Complexity" "npx ts-complexity-report" "false" || true
    fi
}

check_complexity_dotnet() {
    # Check for Roslyn analyzers
    if grep -q "Microsoft.CodeAnalysis" *.csproj 2>/dev/null; then
        log_success "Roslyn analyzers configured"
    else
        log_warning "Consider adding Roslyn analyzers for complexity metrics"
        log_info "  dotnet add package Microsoft.CodeAnalysis.NetAnalyzers"
    fi

    # Check .editorconfig for complexity rules
    if [ -f ".editorconfig" ] && grep -q "dotnet_code_quality" .editorconfig; then
        log_success "Code quality rules in .editorconfig"
    fi
}

case $PROJECT_TYPE in
    node|node-ts)
        check_complexity_node
        ;;
    dotnet)
        check_complexity_dotnet
        ;;
    java)
        # Check for SpotBugs, PMD, Checkstyle
        if [ -f "pmd-ruleset.xml" ] || grep -q "pmd" pom.xml 2>/dev/null; then
            log_success "PMD configured for complexity analysis"
        fi
        ;;
    python)
        # radon for complexity
        if command -v radon &> /dev/null; then
            run_check "Radon Complexity" "radon cc src -a -nc" "false" || true
        else
            log_warning "radon not installed (pip install radon)"
            ((WARNINGS++))
        fi
        ;;
    *)
        log_info "Complexity metrics not configured for ${PROJECT_TYPE}"
        ;;
esac

# =============================================================================
# GATE 5: Fitness Functions
# =============================================================================
log_section "Gate 5: Fitness Functions"

# 5.1 Build time check
check_build_time() {
    log_info "Checking build time..."
    local start_time=$(date +%s)

    case $PROJECT_TYPE in
        node|node-ts)
            npm run build &>/dev/null 2>&1 || true
            ;;
        dotnet)
            dotnet build --no-restore &>/dev/null 2>&1 || true
            ;;
    esac

    local end_time=$(date +%s)
    local build_time=$((end_time - start_time))

    if [ $build_time -lt 300 ]; then  # 5 minutes
        log_success "Build time: ${build_time}s (< 5min threshold)"
    else
        log_warning "Build time: ${build_time}s (exceeds 5min threshold)"
        ((WARNINGS++))
    fi
}

# 5.2 Bundle size (frontend)
check_bundle_size() {
    if [ -f "package.json" ] && grep -q "webpack\|vite\|rollup" package.json 2>/dev/null; then
        if npm ls webpack-bundle-analyzer &>/dev/null 2>&1; then
            log_info "webpack-bundle-analyzer available - run 'npm run analyze' for details"
        fi

        # Check dist folder size
        if [ -d "dist" ]; then
            local size=$(du -sm dist 2>/dev/null | cut -f1)
            if [ -n "$size" ]; then
                if [ "$size" -lt 5 ]; then  # 5MB threshold
                    log_success "Bundle size: ${size}MB (< 5MB threshold)"
                else
                    log_warning "Bundle size: ${size}MB (consider optimization)"
                    ((WARNINGS++))
                fi
            fi
        fi
    fi
}

# 5.3 Test count and mock ratio
check_test_quality() {
    log_info "Analyzing test quality..."

    case $PROJECT_TYPE in
        node|node-ts)
            local test_count=$(find src -name "*.spec.ts" -o -name "*.test.ts" 2>/dev/null | wc -l)
            local mock_count=$(grep -r "jest.mock\|vi.mock\|mock\(" src --include="*.spec.ts" --include="*.test.ts" 2>/dev/null | wc -l)

            if [ "$test_count" -gt 0 ]; then
                local mock_ratio=$((mock_count * 100 / test_count))
                log_info "Test files: $test_count, Mock usages: $mock_count"

                if [ "$mock_ratio" -gt 300 ]; then  # More than 3 mocks per test file avg
                    log_warning "High mock ratio ($mock_ratio%) - consider improving architecture"
                    ((WARNINGS++))
                else
                    log_success "Mock ratio acceptable ($mock_ratio%)"
                fi
            fi
            ;;
    esac
}

# Run fitness functions if not in quick mode
if [ "$CI_MODE" = false ]; then
    check_build_time
fi
check_bundle_size
check_test_quality

# =============================================================================
# Generate Report (if requested)
# =============================================================================
if [ "$GENERATE_REPORT" = true ]; then
    log_section "Generating Architecture Report"

    mkdir -p reports/architecture

    case $PROJECT_TYPE in
        node|node-ts)
            # Generate dependency graph
            if command -v npx &> /dev/null && npm ls madge &>/dev/null 2>&1; then
                npx madge --image reports/architecture/dependency-graph.svg src 2>/dev/null || true
                log_success "Generated: reports/architecture/dependency-graph.svg"
            fi

            # Generate dependency-cruiser report
            if [ -f ".dependency-cruiser.cjs" ]; then
                npx depcruise --config .dependency-cruiser.cjs src --output-type html > reports/architecture/dependencies.html 2>/dev/null || true
                log_success "Generated: reports/architecture/dependencies.html"
            fi
            ;;
    esac

    # Generate summary
    cat > reports/architecture/summary.md << EOF
# Architecture Quality Report

**Generated:** $(date)
**Project Type:** $PROJECT_TYPE

## Summary

| Gate | Passed | Failed | Warnings |
|------|--------|--------|----------|
| Dependency Rules | - | - | - |
| Circular Dependencies | - | - | - |
| Contract Validation | - | - | - |
| Complexity Metrics | - | - | - |
| Fitness Functions | - | - | - |

## Totals

- ✅ Passed: $PASSED
- ❌ Failed: $FAILED
- ⚠️ Warnings: $WARNINGS

## Recommendations

_See detailed reports in this folder._
EOF
    log_success "Generated: reports/architecture/summary.md"
fi

# =============================================================================
# Summary
# =============================================================================
log_section "Architecture Gates Summary"

echo ""
echo -e "  ${GREEN}Passed:${NC}   ${PASSED}"
echo -e "  ${RED}Failed:${NC}   ${FAILED}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARNINGS}"
echo ""

if [ $FAILED -gt 0 ]; then
    log_error "Architecture gates FAILED"
    echo ""
    echo "Common fixes:"
    echo "  1. Review dependency rules in .dependency-cruiser.cjs"
    echo "  2. Check for circular imports with 'npx madge --circular src'"
    echo "  3. Validate OpenAPI specs with 'npx spectral lint specs/*/contracts/openapi.yaml'"
    echo ""

    if [ "$CI_MODE" = true ]; then
        exit 1
    fi
else
    if [ $WARNINGS -gt 0 ]; then
        log_warning "Architecture gates PASSED with warnings"
        echo ""
        echo "Consider addressing warnings to improve architecture quality."
    else
        log_success "All architecture gates PASSED"
    fi
    exit 0
fi
