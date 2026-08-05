#!/bin/bash

# ==============================================================================
# analyze-improvements.sh - Code Analysis and Improvement Backlog Generator
# Part of Bolt Framework / AI-DLC methodology
# Phase: Block 7 - Evolution
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Helpers
step() { echo -e "\n${CYAN}📋 $1${NC}"; }
success() { echo -e "  ${GREEN}✅ $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
err() { echo -e "  ${RED}❌ $1${NC}"; }

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --code          Analyze code metrics"
    echo "  -d, --deps          Analyze dependencies"
    echo "  -g, --generate      Generate backlog files"
    echo "  -a, --all           Run all analyses"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --all"
    echo "  $0 --code --deps"
    echo "  $0 --generate"
}

# Analyze code metrics
analyze_code() {
    step "Analyzing code metrics..."
    
    local total_files=0
    local total_lines=0
    local large_files=()
    
    # Find code files
    for ext in "cs" "ts" "js" "py" "go" "java"; do
        while IFS= read -r file; do
            if [[ "$file" == *"node_modules"* ]] || [[ "$file" == *"/bin/"* ]] || [[ "$file" == *"/obj/"* ]] || [[ "$file" == *"/.git/"* ]]; then
                continue
            fi
            
            ((total_files++)) || true
            local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
            lines=$(echo "$lines" | tr -d ' ')
            total_lines=$((total_lines + lines))
            
            if [ "$lines" -gt 500 ]; then
                large_files+=("$file:$lines")
            fi
        done < <(find . -name "*.$ext" -type f 2>/dev/null)
    done
    
    info "Total code files: $total_files"
    info "Total lines: $total_lines"
    info "Large files (>500 lines): ${#large_files[@]}"
    
    if [ ${#large_files[@]} -gt 0 ]; then
        echo ""
        for file_info in "${large_files[@]}"; do
            local file="${file_info%:*}"
            local lines="${file_info#*:}"
            warn "  $file ($lines lines)"
        done
    fi
    
    # Export for backlog generation
    TOTAL_FILES=$total_files
    TOTAL_LINES=$total_lines
    LARGE_FILES=("${large_files[@]}")
}

# Analyze dependencies
analyze_dependencies() {
    step "Analyzing dependencies..."
    
    local npm_count=0
    local dotnet_count=0
    
    # Check npm
    if [ -f "package.json" ]; then
        npm_count=$(grep -c '"[^"]*":' package.json 2>/dev/null | head -1 || echo 0)
        info "npm packages found: ~$npm_count entries"
        
        if command -v npm &> /dev/null; then
            info "Run 'npm outdated' to check for updates"
        fi
    fi
    
    # Check .NET
    local csproj_count=$(find . -name "*.csproj" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$csproj_count" -gt 0 ]; then
        for csproj in $(find . -name "*.csproj" 2>/dev/null | head -5); do
            local pkg_count=$(grep -c "PackageReference" "$csproj" 2>/dev/null || echo 0)
            dotnet_count=$((dotnet_count + pkg_count))
        done
        info ".NET PackageReferences found: $dotnet_count"
        info "Run 'dotnet list package --outdated' to check for updates"
    fi
    
    # Check Python
    if [ -f "requirements.txt" ]; then
        local py_count=$(wc -l < requirements.txt | tr -d ' ')
        info "Python requirements: $py_count"
    fi
    
    # Export for backlog generation
    NPM_COUNT=$npm_count
    DOTNET_COUNT=$dotnet_count
    TOTAL_DEPS=$((npm_count + dotnet_count))
}

# Analyze test coverage
analyze_tests() {
    step "Checking test coverage..."
    
    local test_count=0
    
    # Find test files
    for pattern in "*Test*.cs" "*test*.ts" "*test*.js" "*_test.py" "*_test.go" "*.spec.ts" "*.spec.js"; do
        local count=$(find . -name "$pattern" 2>/dev/null | grep -v "node_modules" | wc -l | tr -d ' ')
        test_count=$((test_count + count))
    done
    
    if [ "$test_count" -gt 0 ]; then
        success "Test files found: $test_count"
    else
        warn "No test files found"
    fi
    
    TEST_COUNT=$test_count
}

# Generate refactor backlog
generate_refactor_backlog() {
    local date=$(date +%Y-%m-%d)
    
    local backlog_dir="docs/improvement"
    mkdir -p "$backlog_dir"
    
    local backlog_path="$backlog_dir/refactor_backlog.md"
    
    cat > "$backlog_path" << EOF
# Refactoring Backlog

## Document Info

| Property | Value |
|----------|-------|
| Last Updated | $date |
| Analysis Period | Last 30 days |
| Next Review | $(date -d "+30 days" +%Y-%m-%d 2>/dev/null || date -v+30d +%Y-%m-%d 2>/dev/null || echo "TBD") |

---

## Executive Summary

| Category | Count |
|----------|-------|
| Code Files Analyzed | ${TOTAL_FILES:-0} |
| Total Lines of Code | ${TOTAL_LINES:-0} |
| Large Files (>500 lines) | ${#LARGE_FILES[@]} |
| Test Files | ${TEST_COUNT:-0} |
| Dependencies | ${TOTAL_DEPS:-0} |

---

## Backlog Items

EOF

    # Add items for large files
    local item_id=1
    if [ ${#LARGE_FILES[@]} -gt 0 ]; then
        for file_info in "${LARGE_FILES[@]}"; do
            local file="${file_info%:*}"
            local lines="${file_info#*:}"
            
            cat >> "$backlog_path" << EOF

### RB-$(printf "%03d" $item_id): Refactor large file

| Property | Value |
|----------|-------|
| **File** | \`$file\` |
| **Lines** | $lines |
| **Priority** | $([ "$lines" -gt 1000 ] && echo "High" || echo "Medium") |
| **Category** | Code Quality |

**Issue**: File exceeds 500 line threshold, reducing maintainability.

**Proposed Solution**: 
- Consider splitting into smaller modules
- Extract helper functions/classes
- Apply single responsibility principle

---
EOF
            ((item_id++)) || true
        done
    else
        cat >> "$backlog_path" << EOF

*No immediate refactoring items identified.*

Consider running more detailed analysis with:
- Static code analysis tools (SonarQube, ESLint, etc.)
- Security scanners
- Performance profilers

EOF
    fi

    cat >> "$backlog_path" << EOF

## Dependency Review

| Type | Count | Action |
|------|-------|--------|
| npm | ${NPM_COUNT:-0} | Run \`npm outdated\` |
| .NET | ${DOTNET_COUNT:-0} | Run \`dotnet list package --outdated\` |

---

*Generated by Bolt Framework Improve Command*
EOF

    success "Refactor backlog: $backlog_path"
}

# Generate new intents backlog
generate_intents_backlog() {
    local date=$(date +%Y-%m-%d)
    
    local backlog_dir="docs/improvement"
    mkdir -p "$backlog_dir"
    
    local intents_path="$backlog_dir/new_intents.md"
    
    if [ -f "$intents_path" ]; then
        info "New intents backlog already exists, skipping"
        return 0
    fi
    
    cat > "$intents_path" << EOF
# New Feature Intents Backlog

## Document Info

| Property | Value |
|----------|-------|
| Last Updated | $date |
| Review Cycle | Weekly |
| Owner | [Product Owner] |

---

## Intent Pipeline

| Stage | Count |
|-------|-------|
| 💡 Ideation | 0 |
| 🔍 Validation | 0 |
| 📋 Ready for Spec | 0 |
| 🚀 In Development | 0 |

---

## How to Add New Intents

When you identify a potential new feature from:
- User feedback
- Support tickets
- Analytics insights
- Stakeholder requests
- Operational learnings

Add it using this template:

\`\`\`markdown
### NI-XXX: [Feature Idea Title]

| Property | Value |
|----------|-------|
| **Source** | [Where this idea came from] |
| **Submitted** | [Date] |

**Problem**: [What problem does this solve?]
**Proposed Solution**: [High-level description]
**Estimated Complexity**: S / M / L / XL
\`\`\`

---

## 💡 Ideation Stage

*No items yet. Add new feature ideas here.*

---

## 🔍 Validation Stage

*No items yet.*

---

## 📋 Ready for Specification

*No items yet. Run /bolt.feature for these.*

---

*Generated by Bolt Framework Improve Command*
EOF

    success "New intents backlog: $intents_path"
}

# Main
main() {
    echo -e "\n${MAGENTA}📊 Bolt Framework Improvement Analyzer${NC}"
    echo -e "${MAGENTA}====================================${NC}\n"
    
    local analyze_code_flag=false
    local analyze_deps_flag=false
    local generate_flag=false
    local all_flag=false
    
    # Initialize variables
    TOTAL_FILES=0
    TOTAL_LINES=0
    LARGE_FILES=()
    NPM_COUNT=0
    DOTNET_COUNT=0
    TOTAL_DEPS=0
    TEST_COUNT=0
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--code) analyze_code_flag=true; shift ;;
            -d|--deps) analyze_deps_flag=true; shift ;;
            -g|--generate) generate_flag=true; shift ;;
            -a|--all) all_flag=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    
    # Default to all if nothing specified
    if ! $analyze_code_flag && ! $analyze_deps_flag && ! $generate_flag && ! $all_flag; then
        all_flag=true
    fi
    
    if $all_flag || $analyze_code_flag; then
        analyze_code
        analyze_tests
    fi
    
    if $all_flag || $analyze_deps_flag; then
        analyze_dependencies
    fi
    
    if $all_flag || $generate_flag; then
        step "Generating improvement backlogs..."
        generate_refactor_backlog
        generate_intents_backlog
    fi
    
    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Improvement analysis complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}📋 Summary:${NC}"
    echo "  Code files: ${TOTAL_FILES:-0}"
    echo "  Large files: ${#LARGE_FILES[@]}"
    echo "  Dependencies: ${TOTAL_DEPS:-0}"
    
    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Review docs/improvement/refactor_backlog.md"
    echo "  2. Prioritize items with team"
    echo "  3. Add new ideas to new_intents.md"
    echo "  4. Run /bolt.plan for high-priority items"
    echo ""
}

main "$@"
