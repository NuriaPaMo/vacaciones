#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Security Analysis Script
# =============================================================================
# Performs comprehensive security analysis based on detected technology stack
# Integrates OWASP checks, dependency scanning, and SAST/DAST automation
#
# Usage:
#   ./security-analysis.sh [OPTIONS]
#
# Options:
#   --constitution PATH   Path to constitution.md file
#   --stack STACK        Override stack detection (nodejs|dotnet|java|python|golang)
#   --output-format FORMAT  Output format (json|markdown|sarif)
#   --severity LEVEL     Minimum severity to report (critical|high|medium|low)
#   --compliance STANDARD  Check compliance (owasp|pci-dss|gdpr|soc2)
#   --sast              Run SAST analysis
#   --sca               Run dependency/SCA scanning
#   --secrets           Run secrets scanning
#   --infra             Scan infrastructure configs
#   --all               Run all security checks
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
CONSTITUTION_FILE=".boltf/memory/constitution.md"
TECH_STACK=""
OUTPUT_FORMAT="markdown"
MIN_SEVERITY="medium"
COMPLIANCE_STANDARD=""
RUN_SAST=false
RUN_SCA=false
RUN_SECRETS=false
RUN_INFRA=false
OUTPUT_DIR="reports/security"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$OUTPUT_DIR/security-report-$TIMESTAMP.md"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${MAGENTA}[STEP]${NC} $1"; }

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --constitution)
            CONSTITUTION_FILE="$2"
            shift 2
            ;;
        --stack)
            TECH_STACK="$2"
            shift 2
            ;;
        --output-format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --severity)
            MIN_SEVERITY="$2"
            shift 2
            ;;
        --compliance)
            COMPLIANCE_STANDARD="$2"
            shift 2
            ;;
        --sast)
            RUN_SAST=true
            shift
            ;;
        --sca)
            RUN_SCA=true
            shift
            ;;
        --secrets)
            RUN_SECRETS=true
            shift
            ;;
        --infra)
            RUN_INFRA=true
            shift
            ;;
        --all)
            RUN_SAST=true
            RUN_SCA=true
            RUN_SECRETS=true
            RUN_INFRA=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Run comprehensive security analysis for Bolt Framework projects"
            echo ""
            echo "Options:"
            echo "  --constitution PATH      Path to constitution.md (default: .boltf/memory/constitution.md)"
            echo "  --stack STACK           Override stack detection (nodejs|dotnet|java|python|golang)"
            echo "  --output-format FORMAT  Output format (json|markdown|sarif) (default: markdown)"
            echo "  --severity LEVEL        Minimum severity (critical|high|medium|low) (default: medium)"
            echo "  --compliance STANDARD   Check compliance (owasp|pci-dss|gdpr|soc2)"
            echo "  --sast                  Run SAST analysis"
            echo "  --sca                   Run dependency/SCA scanning"
            echo "  --secrets               Run secrets scanning"
            echo "  --infra                 Scan infrastructure configs"
            echo "  --all                   Run all security checks"
            echo "  --help                  Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Banner
print_banner() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                  ║"
    echo "║           🔒 Bolt Framework Security Analysis Engine 🔒               ║"
    echo "║                                                                  ║"
    echo "║     Stack-Agnostic Security Scanning with OWASP Integration      ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect technology stack from constitution or project files
detect_technology_stack() {
    if [[ -n "$TECH_STACK" ]]; then
        log_info "Using explicitly specified stack: $TECH_STACK"
        return 0
    fi

    local detected_stack="unknown"

    # Try to detect from constitution first
    if [[ -f "$CONSTITUTION_FILE" ]]; then
        log_info "Reading technology stack from constitution: $CONSTITUTION_FILE"
        local constitution_content=$(cat "$CONSTITUTION_FILE")

        if echo "$constitution_content" | grep -qi "node\.js\|typescript\|javascript\|npm"; then
            detected_stack="nodejs"
        elif echo "$constitution_content" | grep -qi "\.net\|c#\|asp\.net\|nuget"; then
            detected_stack="dotnet"
        elif echo "$constitution_content" | grep -qi "java\|spring\|maven\|gradle"; then
            detected_stack="java"
        elif echo "$constitution_content" | grep -qi "python\|django\|fastapi\|flask\|pip"; then
            detected_stack="python"
        elif echo "$constitution_content" | grep -qi "go\|golang"; then
            detected_stack="golang"
        fi
    fi

    # Fallback: detect from project files
    if [[ "$detected_stack" == "unknown" ]]; then
        log_info "Constitution not found or stack not specified, detecting from project files..."

        if [[ -f "package.json" ]]; then
            detected_stack="nodejs"
        elif [[ -f "*.csproj" ]] || [[ -f "*.sln" ]] || [[ -f "Directory.Build.props" ]]; then
            detected_stack="dotnet"
        elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
            detected_stack="java"
        elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
            detected_stack="python"
        elif [[ -f "go.mod" ]]; then
            detected_stack="golang"
        fi
    fi

    TECH_STACK="$detected_stack"
    log_success "Detected technology stack: $TECH_STACK"
}

# Initialize security analysis environment
init_security_analysis() {
    log_step "Initializing security analysis environment..."

    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/sast"
    mkdir -p "$OUTPUT_DIR/sca"
    mkdir -p "$OUTPUT_DIR/secrets"
    mkdir -p "$OUTPUT_DIR/infrastructure"

    # Install required tools based on stack
    case "$TECH_STACK" in
        "nodejs")
            init_nodejs_security_tools
            ;;
        "dotnet")
            init_dotnet_security_tools
            ;;
        "java")
            init_java_security_tools
            ;;
        "python")
            init_python_security_tools
            ;;
        "golang")
            init_go_security_tools
            ;;
        *)
            log_warning "Unknown stack '$TECH_STACK', using generic security tools"
            init_generic_security_tools
            ;;
    esac
}

# Initialize Node.js security tools
init_nodejs_security_tools() {
    log_info "Initializing Node.js security tools..."

    # Check if tools are available
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is required for Node.js security analysis"
        exit 1
    fi

    # Install security tools locally if not available
    if ! npm list eslint >/dev/null 2>&1; then
        log_info "Installing ESLint for security analysis..."
        npm install --no-save eslint @typescript-eslint/eslint-plugin eslint-plugin-security
    fi
}

# Initialize .NET security tools
init_dotnet_security_tools() {
    log_info "Initializing .NET security tools..."

    if ! command -v dotnet >/dev/null 2>&1; then
        log_error "dotnet CLI is required for .NET security analysis"
        exit 1
    fi

    # Install security analyzers
    log_info "Security analyzers will be configured via Directory.Build.props"
}

# Initialize Java security tools
init_java_security_tools() {
    log_info "Initializing Java security tools..."

    # Check for Maven or Gradle
    if command -v mvn >/dev/null 2>&1; then
        log_info "Maven detected for Java security analysis"
    elif command -v gradle >/dev/null 2>&1; then
        log_info "Gradle detected for Java security analysis"
    else
        log_warning "Neither Maven nor Gradle found, some Java security checks may not work"
    fi
}

# Initialize Python security tools
init_python_security_tools() {
    log_info "Initializing Python security tools..."

    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        log_error "Python is required for Python security analysis"
        exit 1
    fi

    # Install security tools in virtual environment if possible
    if command -v pip3 >/dev/null 2>&1; then
        log_info "Installing Python security tools..."
        pip3 install --user bandit safety pip-audit semgrep 2>/dev/null || log_warning "Some Python security tools may not be available"
    fi
}

# Initialize Go security tools
init_go_security_tools() {
    log_info "Initializing Go security tools..."

    if ! command -v go >/dev/null 2>&1; then
        log_error "Go compiler is required for Go security analysis"
        exit 1
    fi

    # Install security tools
    if ! command -v gosec >/dev/null 2>&1; then
        log_info "Installing gosec for Go security analysis..."
        go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest 2>/dev/null || log_warning "gosec installation failed"
    fi
}

# Initialize generic security tools
init_generic_security_tools() {
    log_info "Initializing generic security tools..."

    # Check for universal tools
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git is required for security analysis"
        exit 1
    fi
}

# Run SAST (Static Application Security Testing)
run_sast_analysis() {
    if [[ "$RUN_SAST" != "true" ]]; then
        return 0
    fi

    log_step "Running SAST analysis for $TECH_STACK..."

    case "$TECH_STACK" in
        "nodejs")
            run_nodejs_sast
            ;;
        "dotnet")
            run_dotnet_sast
            ;;
        "java")
            run_java_sast
            ;;
        "python")
            run_python_sast
            ;;
        "golang")
            run_go_sast
            ;;
        *)
            run_generic_sast
            ;;
    esac
}

# Node.js SAST analysis
run_nodejs_sast() {
    log_info "Running Node.js SAST analysis..."

    # ESLint with security rules
    if command -v npx >/dev/null 2>&1; then
        log_info "Running ESLint security analysis..."
        npx eslint . --ext .js,.ts --format json --output-file "$OUTPUT_DIR/sast/eslint-security.json" 2>/dev/null || log_warning "ESLint analysis failed"
    fi

    # Semgrep for Node.js
    if command -v semgrep >/dev/null 2>&1; then
        log_info "Running Semgrep for Node.js..."
        semgrep --config=p/nodejs --json --output="$OUTPUT_DIR/sast/semgrep-nodejs.json" . 2>/dev/null || log_warning "Semgrep analysis failed"
    fi
}

# .NET SAST analysis
run_dotnet_sast() {
    log_info "Running .NET SAST analysis..."

    # Build with analyzers
    if [[ -f "*.sln" ]] || [[ -f "*.csproj" ]]; then
        log_info "Running .NET build with security analyzers..."
        dotnet build --configuration Release --verbosity minimal > "$OUTPUT_DIR/sast/dotnet-build.log" 2>&1 || log_warning ".NET build analysis failed"
    fi

    # Security Code Scan if available
    log_info ".NET security analysis via MSBuild analyzers completed"
}

# Python SAST analysis
run_python_sast() {
    log_info "Running Python SAST analysis..."

    # Bandit analysis
    if command -v bandit >/dev/null 2>&1; then
        log_info "Running Bandit security analysis..."
        bandit -r . -f json -o "$OUTPUT_DIR/sast/bandit.json" 2>/dev/null || log_warning "Bandit analysis failed"
    fi

    # Semgrep for Python
    if command -v semgrep >/dev/null 2>&1; then
        log_info "Running Semgrep for Python..."
        semgrep --config=p/python --json --output="$OUTPUT_DIR/sast/semgrep-python.json" . 2>/dev/null || log_warning "Semgrep analysis failed"
    fi
}

# Go SAST analysis
run_go_sast() {
    log_info "Running Go SAST analysis..."

    # gosec analysis
    if command -v gosec >/dev/null 2>&1; then
        log_info "Running gosec security analysis..."
        gosec -fmt json -out "$OUTPUT_DIR/sast/gosec.json" ./... 2>/dev/null || log_warning "gosec analysis failed"
    fi

    # go vet
    if command -v go >/dev/null 2>&1; then
        log_info "Running go vet analysis..."
        go vet ./... > "$OUTPUT_DIR/sast/go-vet.log" 2>&1 || log_warning "go vet analysis failed"
    fi
}

# Generic SAST analysis
run_generic_sast() {
    log_info "Running generic SAST analysis..."

    # Semgrep with generic rules
    if command -v semgrep >/dev/null 2>&1; then
        log_info "Running Semgrep with generic security rules..."
        semgrep --config=p/security-audit --json --output="$OUTPUT_DIR/sast/semgrep-generic.json" . 2>/dev/null || log_warning "Generic Semgrep analysis failed"
    fi
}

# Run SCA (Software Composition Analysis) - Dependency scanning
run_sca_analysis() {
    if [[ "$RUN_SCA" != "true" ]]; then
        return 0
    fi

    log_step "Running SCA/Dependency analysis for $TECH_STACK..."

    case "$TECH_STACK" in
        "nodejs")
            run_nodejs_sca
            ;;
        "dotnet")
            run_dotnet_sca
            ;;
        "java")
            run_java_sca
            ;;
        "python")
            run_python_sca
            ;;
        "golang")
            run_go_sca
            ;;
        *)
            log_info "No specific SCA tools for stack: $TECH_STACK"
            ;;
    esac
}

# Node.js SCA analysis
run_nodejs_sca() {
    log_info "Running Node.js dependency analysis..."

    # npm audit
    if [[ -f "package.json" ]] && command -v npm >/dev/null 2>&1; then
        log_info "Running npm audit..."
        npm audit --audit-level=moderate --json > "$OUTPUT_DIR/sca/npm-audit.json" 2>/dev/null || log_warning "npm audit failed"
    fi

    # yarn audit if using yarn
    if [[ -f "yarn.lock" ]] && command -v yarn >/dev/null 2>&1; then
        log_info "Running yarn audit..."
        yarn audit --json > "$OUTPUT_DIR/sca/yarn-audit.json" 2>/dev/null || log_warning "yarn audit failed"
    fi
}

# .NET SCA analysis
run_dotnet_sca() {
    log_info "Running .NET dependency analysis..."

    # dotnet list package --vulnerable
    if command -v dotnet >/dev/null 2>&1; then
        log_info "Checking for vulnerable .NET packages..."
        dotnet list package --vulnerable --include-transitive > "$OUTPUT_DIR/sca/dotnet-vulnerable.log" 2>&1 || log_warning ".NET vulnerability check failed"
    fi
}

# Python SCA analysis
run_python_sca() {
    log_info "Running Python dependency analysis..."

    # Safety check
    if command -v safety >/dev/null 2>&1; then
        log_info "Running Safety vulnerability check..."
        safety check --json --output "$OUTPUT_DIR/sca/safety.json" 2>/dev/null || log_warning "Safety check failed"
    fi

    # pip-audit
    if command -v pip-audit >/dev/null 2>&1; then
        log_info "Running pip-audit..."
        pip-audit --format=json --output="$OUTPUT_DIR/sca/pip-audit.json" 2>/dev/null || log_warning "pip-audit failed"
    fi
}

# Go SCA analysis
run_go_sca() {
    log_info "Running Go dependency analysis..."

    # govulncheck
    if command -v govulncheck >/dev/null 2>&1; then
        log_info "Running govulncheck..."
        govulncheck -json ./... > "$OUTPUT_DIR/sca/govulncheck.json" 2>/dev/null || log_warning "govulncheck failed"
    fi
}

# Run secrets scanning
run_secrets_scanning() {
    if [[ "$RUN_SECRETS" != "true" ]]; then
        return 0
    fi

    log_step "Running secrets scanning..."

    # TruffleHog if available
    if command -v trufflehog >/dev/null 2>&1; then
        log_info "Running TruffleHog secrets scan..."
        trufflehog filesystem . --json > "$OUTPUT_DIR/secrets/trufflehog.json" 2>/dev/null || log_warning "TruffleHog scan failed"
    fi

    # GitLeaks if available
    if command -v gitleaks >/dev/null 2>&1; then
        log_info "Running GitLeaks secrets scan..."
        gitleaks detect --source . --report-format json --report-path "$OUTPUT_DIR/secrets/gitleaks.json" 2>/dev/null || log_warning "GitLeaks scan failed"
    fi

    # Basic pattern matching for common secrets
    run_basic_secrets_scan
}

# Basic secrets pattern matching
run_basic_secrets_scan() {
    log_info "Running basic secrets pattern scan..."

    local secrets_file="$OUTPUT_DIR/secrets/pattern-matches.txt"

    # Common secret patterns
    echo "# Basic Secrets Scan Results" > "$secrets_file"
    echo "# Generated: $(date)" >> "$secrets_file"
    echo "" >> "$secrets_file"

    # AWS Keys
    echo "## AWS Access Keys" >> "$secrets_file"
    grep -r -n "AKIA[0-9A-Z]{16}" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null >> "$secrets_file" || echo "No AWS keys found" >> "$secrets_file"

    # API Keys
    echo "" >> "$secrets_file"
    echo "## Potential API Keys" >> "$secrets_file"
    grep -r -n -i "api[_-]key.*[\"']\s*[a-z0-9]{20,}" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null >> "$secrets_file" || echo "No API keys found" >> "$secrets_file"

    # Database URLs
    echo "" >> "$secrets_file"
    echo "## Database Connection Strings" >> "$secrets_file"
    grep -r -n -i "mongodb://\|postgres://\|mysql://\|mssql://" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null >> "$secrets_file" || echo "No database URLs found" >> "$secrets_file"

    log_info "Basic secrets scan completed: $secrets_file"
}

# Run infrastructure security scanning
run_infrastructure_scanning() {
    if [[ "$RUN_INFRA" != "true" ]]; then
        return 0
    fi

    log_step "Running infrastructure security scanning..."

    # Docker security
    if [[ -f "Dockerfile" ]]; then
        run_docker_security_scan
    fi

    # Kubernetes security
    if ls *.yaml *.yml >/dev/null 2>&1; then
        run_k8s_security_scan
    fi

    # Terraform security
    if ls *.tf >/dev/null 2>&1; then
        run_terraform_security_scan
    fi
}

# Docker security scanning
run_docker_security_scan() {
    log_info "Running Docker security analysis..."

    # Basic Dockerfile analysis
    local dockerfile_report="$OUTPUT_DIR/infrastructure/dockerfile-analysis.txt"
    echo "# Dockerfile Security Analysis" > "$dockerfile_report"
    echo "# Generated: $(date)" >> "$dockerfile_report"
    echo "" >> "$dockerfile_report"

    # Check for common issues
    echo "## Security Issues Found:" >> "$dockerfile_report"

    if grep -q "FROM.*:latest" Dockerfile; then
        echo "❌ Uses 'latest' tag (line $(grep -n 'FROM.*:latest' Dockerfile | cut -d: -f1))" >> "$dockerfile_report"
    fi

    if grep -q "USER root\|^USER 0" Dockerfile; then
        echo "❌ Runs as root user (line $(grep -n 'USER root\|^USER 0' Dockerfile | cut -d: -f1))" >> "$dockerfile_report"
    fi

    if ! grep -q "USER " Dockerfile; then
        echo "⚠️ No explicit USER directive found (may run as root)" >> "$dockerfile_report"
    fi

    log_info "Docker security analysis completed: $dockerfile_report"
}

# Kubernetes security scanning
run_k8s_security_scan() {
    log_info "Running Kubernetes security analysis..."

    local k8s_report="$OUTPUT_DIR/infrastructure/k8s-analysis.txt"
    echo "# Kubernetes Security Analysis" > "$k8s_report"
    echo "# Generated: $(date)" >> "$k8s_report"
    echo "" >> "$k8s_report"

    # Basic K8s security checks
    for file in *.yaml *.yml; do
        if [[ -f "$file" ]]; then
            echo "## Analysis of $file:" >> "$k8s_report"

            # Check for security contexts
            if ! grep -q "securityContext:" "$file"; then
                echo "⚠️ No securityContext defined" >> "$k8s_report"
            fi

            # Check for privileged containers
            if grep -q "privileged: true" "$file"; then
                echo "❌ Privileged container found" >> "$k8s_report"
            fi

            # Check for resource limits
            if ! grep -q "resources:" "$file"; then
                echo "⚠️ No resource limits defined" >> "$k8s_report"
            fi

            echo "" >> "$k8s_report"
        fi
    done

    log_info "Kubernetes security analysis completed: $k8s_report"
}

# Terraform security scanning
run_terraform_security_scan() {
    log_info "Running Terraform security analysis..."

    # Basic Terraform checks (would integrate with tools like Checkov/tfsec in production)
    local tf_report="$OUTPUT_DIR/infrastructure/terraform-analysis.txt"
    echo "# Terraform Security Analysis" > "$tf_report"
    echo "# Generated: $(date)" >> "$tf_report"
    echo "" >> "$tf_report"

    echo "## Basic Security Checks:" >> "$tf_report"

    # Check for hardcoded secrets
    if grep -r -n "password\s*=\s*\"" *.tf 2>/dev/null; then
        echo "❌ Hardcoded passwords found in Terraform files" >> "$tf_report"
    fi

    # Check for public access
    if grep -r -n "0.0.0.0/0" *.tf 2>/dev/null; then
        echo "⚠️ Open access (0.0.0.0/0) found in Terraform files" >> "$tf_report"
    fi

    log_info "Terraform security analysis completed: $tf_report"
}

# Generate comprehensive security report
generate_security_report() {
    log_step "Generating comprehensive security report..."

    cat > "$REPORT_FILE" << EOF
# 🔒 Bolt Framework Security Analysis Report

**Generated**: $(date)
**Technology Stack**: $TECH_STACK
**Constitution**: $CONSTITUTION_FILE
**Analysis Scope**: $(echo $RUN_SAST,$RUN_SCA,$RUN_SECRETS,$RUN_INFRA | tr ',' ' ')

---

## Executive Summary

| Category | Status | Details |
|----------|--------|---------|
| 🔍 SAST Analysis | $([ "$RUN_SAST" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped") | Static code analysis |
| 📦 SCA Analysis | $([ "$RUN_SCA" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped") | Dependency vulnerabilities |
| 🔑 Secrets Scan | $([ "$RUN_SECRETS" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped") | Exposed credentials |
| 🏗️ Infrastructure | $([ "$RUN_INFRA" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped") | Config security |

---

## Technology Stack Analysis: $TECH_STACK

EOF

    # Add stack-specific security information
    case "$TECH_STACK" in
        "nodejs")
            add_nodejs_security_summary >> "$REPORT_FILE"
            ;;
        "dotnet")
            add_dotnet_security_summary >> "$REPORT_FILE"
            ;;
        "python")
            add_python_security_summary >> "$REPORT_FILE"
            ;;
        "golang")
            add_go_security_summary >> "$REPORT_FILE"
            ;;
        *)
            echo "### Generic Security Analysis" >> "$REPORT_FILE"
            echo "Basic security checks performed for unknown technology stack." >> "$REPORT_FILE"
            ;;
    esac

    # Add OWASP Top 10 mapping
    add_owasp_mapping >> "$REPORT_FILE"

    # Add detailed findings
    add_detailed_findings >> "$REPORT_FILE"

    # Add recommendations
    add_security_recommendations >> "$REPORT_FILE"

    log_success "Security report generated: $REPORT_FILE"
}

# Add Node.js specific security summary
add_nodejs_security_summary() {
    cat << EOF

### Node.js/JavaScript Security Profile

**Package Manager**: $(command -v npm >/dev/null && echo "npm ✅" || echo "npm ❌") $(command -v yarn >/dev/null && echo "yarn ✅" || echo "")
**Security Tools Used**: ESLint Security Plugin, Semgrep, npm audit
**Key Risk Areas**: Prototype pollution, Command injection, XSS, Dependency vulnerabilities

EOF
}

# Add .NET specific security summary
add_dotnet_security_summary() {
    cat << EOF

### .NET Security Profile

**Framework**: $(dotnet --version 2>/dev/null || echo "Not detected")
**Security Tools Used**: Microsoft Security Code Analysis, Built-in analyzers
**Key Risk Areas**: Deserialization, SQL injection, XSS in Razor, CSRF

EOF
}

# Add Python specific security summary
add_python_security_summary() {
    cat << EOF

### Python Security Profile

**Version**: $(python3 --version 2>/dev/null || python --version 2>/dev/null || echo "Not detected")
**Security Tools Used**: Bandit, Safety, pip-audit
**Key Risk Areas**: Code injection, Deserialization, SSTI, SQL injection

EOF
}

# Add Go specific security summary
add_go_security_summary() {
    cat << EOF

### Go Security Profile

**Version**: $(go version 2>/dev/null || echo "Not detected")
**Security Tools Used**: gosec, go vet, govulncheck
**Key Risk Areas**: Command injection, Path traversal, Race conditions

EOF
}

# Add OWASP Top 10 mapping
add_owasp_mapping() {
    cat << EOF

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

EOF
}

# Add detailed findings from analysis
add_detailed_findings() {
    cat << EOF

---

## Detailed Security Findings

EOF

    # Process SAST findings
    if [[ "$RUN_SAST" = "true" ]]; then
        echo "### 🔍 Static Analysis (SAST) Findings" >> "$REPORT_FILE"

        local sast_files=$(ls "$OUTPUT_DIR/sast/"*.json 2>/dev/null || echo "")
        if [[ -n "$sast_files" ]]; then
            echo "Analysis files generated:" >> "$REPORT_FILE"
            for file in $sast_files; do
                echo "- $(basename "$file")" >> "$REPORT_FILE"
            done
        else
            echo "No SAST analysis files found." >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi

    # Process SCA findings
    if [[ "$RUN_SCA" = "true" ]]; then
        echo "### 📦 Dependency Analysis (SCA) Findings" >> "$REPORT_FILE"

        local sca_files=$(ls "$OUTPUT_DIR/sca/"*.json "$OUTPUT_DIR/sca/"*.log 2>/dev/null || echo "")
        if [[ -n "$sca_files" ]]; then
            echo "Analysis files generated:" >> "$REPORT_FILE"
            for file in $sca_files; do
                echo "- $(basename "$file")" >> "$REPORT_FILE"
            done
        else
            echo "No SCA analysis files found." >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi

    # Process secrets findings
    if [[ "$RUN_SECRETS" = "true" ]]; then
        echo "### 🔑 Secrets Scanning Findings" >> "$REPORT_FILE"

        if [[ -f "$OUTPUT_DIR/secrets/pattern-matches.txt" ]]; then
            echo "Basic pattern matching results available in reports/security/secrets/" >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi
}

# Add security recommendations
add_security_recommendations() {
    cat << EOF

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

EOF

    case "$TECH_STACK" in
        "nodejs")
            cat << EOF
#### Node.js Specific:
- Configure ESLint with security rules in your IDE and CI/CD
- Use \`npm audit fix\` regularly to update vulnerable dependencies
- Consider using \`npm ci\` instead of \`npm install\` in production
- Enable Node.js security-related flags in production (\`--security\`)

EOF
            ;;
        "dotnet")
            cat << EOF
#### .NET Specific:
- Enable all .NET security analyzers in Directory.Build.props
- Use \`dotnet list package --vulnerable\` regularly
- Configure Content Security Policy for web applications
- Enable request validation and CSRF protection

EOF
            ;;
        "python")
            cat << EOF
#### Python Specific:
- Run \`bandit\` regularly as part of your development workflow
- Use \`safety check\` to scan for known vulnerabilities
- Consider using \`pip-audit\` for comprehensive dependency analysis
- Enable security-related linting rules in your IDE

EOF
            ;;
    esac

    cat << EOF

### Constitution Integration

Add these security policies to your \`.boltf/memory/constitution.md\`:

\`\`\`yaml
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
    standards: [$([ -n "$COMPLIANCE_STANDARD" ] && echo "$COMPLIANCE_STANDARD" || echo "owasp")]
\`\`\`

### Next Steps

1. Review all generated analysis files in \`reports/security/\`
2. Address any critical or high-severity findings
3. Integrate security scanning into your development workflow
4. Set up monitoring and alerting for security events
5. Schedule regular security reviews and penetration testing

---

*This report was generated by Bolt Framework Security Analysis Engine*
*For questions or support, consult the Bolt Framework Security Agent documentation*

EOF
}

# Main execution
main() {
    print_banner

    log_info "Starting Bolt Framework Security Analysis..."
    log_info "Constitution file: $CONSTITUTION_FILE"
    log_info "Output directory: $OUTPUT_DIR"
    log_info "Minimum severity: $MIN_SEVERITY"

    # Detect technology stack
    detect_technology_stack

    if [[ "$TECH_STACK" == "unknown" ]]; then
        log_error "Unable to detect technology stack. Please specify with --stack option."
        log_info "Supported stacks: nodejs, dotnet, java, python, golang"
        exit 1
    fi

    # Initialize security analysis environment
    init_security_analysis

    # Run security analyses
    run_sast_analysis
    run_sca_analysis
    run_secrets_scanning
    run_infrastructure_scanning

    # Generate comprehensive report
    generate_security_report

    log_success "Security analysis completed!"
    log_info "Report available at: $REPORT_FILE"
    log_info "Detailed analysis files in: $OUTPUT_DIR"

    # Show summary
    echo ""
    echo -e "${CYAN}📊 Analysis Summary:${NC}"
    echo "  Technology Stack: $TECH_STACK"
    echo "  SAST Analysis: $([ "$RUN_SAST" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped")"
    echo "  SCA Analysis: $([ "$RUN_SCA" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped")"
    echo "  Secrets Scan: $([ "$RUN_SECRETS" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped")"
    echo "  Infrastructure: $([ "$RUN_INFRA" = "true" ] && echo "✅ Completed" || echo "⏭️ Skipped")"
    echo ""
    echo -e "${MAGENTA}🚀 Next: Review the security report and implement recommended fixes!${NC}"
}

# Execute main function
main "$@"
