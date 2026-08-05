#!/usr/bin/env bash
#
# alignment-analysis.sh - Bolt Framework Alignment & Gap Analysis
# Analyzes alignment between RFP, legacy code, requirements, and implementation
#
# Usage:
#   ./alignment-analysis.sh [options]
#
# Options:
#   --full          Complete alignment analysis
#   --rfp           RFP coverage analysis only
#   --legacy        Legacy code migration analysis
#   --methodology   Bolt Framework methodology compliance
#   --gaps          Gap analysis summary
#   --progress      Progress tracking over time
#   --baseline      Create baseline for future comparisons
#   --compare FILE  Compare with previous baseline
#   --json          Output in JSON format
#   --save          Save report to memory/analysis/
#   -h, --help      Show this help message
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
OUTPUT_FORMAT="markdown"
ANALYSIS_TYPE="summary"
BASELINE_MODE=false
COMPARE_FILE=""
SAVE_REPORT=false

# Analysis results
declare -A ALIGNMENT_SCORES
declare -A GAP_COUNTS
declare -a CRITICAL_GAPS
declare -a HIGH_GAPS
declare -a RECOMMENDATIONS

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}${BLUE}─── $1 ───${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

show_help() {
    cat << EOF
Bolt Framework Alignment & Gap Analysis

Usage: $(basename "$0") [options]

Options:
  --full          Complete alignment analysis (all dimensions)
  --rfp           RFP coverage analysis only
  --legacy        Legacy code migration analysis
  --methodology   Bolt Framework methodology compliance
  --gaps          Gap analysis summary
  --progress      Progress tracking over time
  --baseline      Create baseline for future comparisons
  --compare FILE  Compare with previous baseline
  --json          Output in JSON format
  --save          Save report to memory/analysis/
  -h, --help      Show this help message

Examples:
  $(basename "$0")                    # Executive summary
  $(basename "$0") --full             # Complete analysis
  $(basename "$0") --rfp              # RFP coverage only
  $(basename "$0") --legacy           # Legacy migration only
  $(basename "$0") --gaps             # Gap summary
  $(basename "$0") --baseline         # Create baseline
  $(basename "$0") --compare prev.json # Compare with baseline

EOF
}

get_progress_bar() {
    local percentage=$1
    local width=20
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] %d%%" "$percentage"
}

# ============================================================================
# Project Detection
# ============================================================================

detect_project_context() {
    local constitution="$PROJECT_ROOT/memory/constitution.md"
    
    PROJECT_TYPE="Greenfield"
    PROJECT_SCOPE="Application Development"
    MIGRATION_STRATEGY=""
    HAS_RFP=false
    HAS_LEGACY=false
    
    if [[ -f "$constitution" ]]; then
        local content
        content=$(cat "$constitution")
        
        # Detect project type
        if echo "$content" | grep -q "\[x\].*Greenfield"; then
            PROJECT_TYPE="Greenfield"
        elif echo "$content" | grep -q "\[x\].*Brownfield"; then
            PROJECT_TYPE="Brownfield"
        elif echo "$content" | grep -q "\[x\].*Legacy Migration\|Migration"; then
            PROJECT_TYPE="Migration"
        fi
        
        # Detect scope
        if echo "$content" | grep -q "\[x\].*Infrastructure Only"; then
            PROJECT_SCOPE="Infrastructure Only"
        elif echo "$content" | grep -q "\[x\].*Application Development"; then
            PROJECT_SCOPE="Application Development"
        elif echo "$content" | grep -q "\[x\].*Full Stack"; then
            PROJECT_SCOPE="Full Stack"
        fi
        
        # Detect migration strategy
        if echo "$content" | grep -q "\[x\].*Strangler"; then
            MIGRATION_STRATEGY="Strangler Fig"
        elif echo "$content" | grep -q "\[x\].*Big Bang"; then
            MIGRATION_STRATEGY="Big Bang"
        elif echo "$content" | grep -q "\[x\].*Branch by Abstraction"; then
            MIGRATION_STRATEGY="Branch by Abstraction"
        fi
    fi
    
    # Check for RFP materials
    if [[ -d "$PROJECT_ROOT/demo/from_rfp" ]]; then
        local rfp_count
        rfp_count=$(find "$PROJECT_ROOT/demo/from_rfp" -type f \( -name "*.md" -o -name "*.pdf" -o -name "*.docx" \) 2>/dev/null | wc -l)
        [[ $rfp_count -gt 0 ]] && HAS_RFP=true
    fi
    
    # Check for legacy code
    if [[ -d "$PROJECT_ROOT/demo/from_old_src" ]]; then
        local legacy_count
        legacy_count=$(find "$PROJECT_ROOT/demo/from_old_src" -type f 2>/dev/null | wc -l)
        [[ $legacy_count -gt 0 ]] && HAS_LEGACY=true
    fi
}

# ============================================================================
# RFP Analysis
# ============================================================================

analyze_rfp_coverage() {
    local rfp_dir="$PROJECT_ROOT/demo/from_rfp"
    local specs_dir="$PROJECT_ROOT/specs"
    
    RFP_TOTAL_ITEMS=0
    RFP_COVERED_ITEMS=0
    RFP_PENDING_ITEMS=0
    RFP_DOCUMENTS=()
    RFP_UNCOVERED=()
    
    if [[ ! -d "$rfp_dir" ]]; then
        ALIGNMENT_SCORES[rfp]=0
        return
    fi
    
    # Analyze each RFP document
    for rfp_file in "$rfp_dir"/*.md "$rfp_dir"/*.txt; do
        [[ ! -f "$rfp_file" ]] && continue
        
        local filename
        filename=$(basename "$rfp_file")
        local content
        content=$(cat "$rfp_file")
        
        # Count requirement items (lines starting with - or numbered)
        local items
        items=$(echo "$content" | grep -cE "^[-*]|^[0-9]+\." 2>/dev/null || echo 0)
        
        # Count items that are referenced in specs
        local covered=0
        if [[ -d "$specs_dir" ]]; then
            # Check how many RFP items are mentioned in specs
            for spec_file in "$specs_dir"/*/requirements/*.md; do
                [[ ! -f "$spec_file" ]] && continue
                local spec_content
                spec_content=$(cat "$spec_file")
                
                # Simple heuristic: count matches
                local matches
                matches=$(echo "$spec_content" | grep -ciE "RFP|requirement|$(echo "$filename" | sed 's/.md//')" 2>/dev/null || echo 0)
                covered=$((covered + matches))
            done
        fi
        
        # Estimate coverage (simplified)
        if [[ $items -gt 0 ]]; then
            if [[ $covered -gt $items ]]; then
                covered=$items
            fi
        fi
        
        RFP_TOTAL_ITEMS=$((RFP_TOTAL_ITEMS + items))
        RFP_COVERED_ITEMS=$((RFP_COVERED_ITEMS + covered))
        
        local doc_coverage=0
        [[ $items -gt 0 ]] && doc_coverage=$((covered * 100 / items))
        
        RFP_DOCUMENTS+=("$filename|$items|$covered|$doc_coverage")
        
        # Track uncovered items
        local pending=$((items - covered))
        if [[ $pending -gt 0 ]]; then
            RFP_UNCOVERED+=("$filename: $pending items uncovered")
        fi
    done
    
    RFP_PENDING_ITEMS=$((RFP_TOTAL_ITEMS - RFP_COVERED_ITEMS))
    
    if [[ $RFP_TOTAL_ITEMS -gt 0 ]]; then
        ALIGNMENT_SCORES[rfp]=$((RFP_COVERED_ITEMS * 100 / RFP_TOTAL_ITEMS))
    else
        ALIGNMENT_SCORES[rfp]=0
    fi
}

# ============================================================================
# Legacy Code Analysis
# ============================================================================

analyze_legacy_migration() {
    local legacy_dir="$PROJECT_ROOT/demo/from_old_src"
    local src_dir="$PROJECT_ROOT/src"
    
    LEGACY_FILES=0
    LEGACY_LINES=0
    LEGACY_FUNCTIONS=0
    LEGACY_MIGRATED=0
    LEGACY_BY_LANG=()
    LEGACY_UNMIGRATED=()
    
    if [[ ! -d "$legacy_dir" ]]; then
        ALIGNMENT_SCORES[legacy]=0
        return
    fi
    
    # Analyze legacy files by extension
    declare -A lang_files
    declare -A lang_lines
    declare -A lang_funcs
    
    while IFS= read -r -d '' file; do
        LEGACY_FILES=$((LEGACY_FILES + 1))
        
        local ext="${file##*.}"
        local lines
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        LEGACY_LINES=$((LEGACY_LINES + lines))
        
        # Count functions (simplified heuristics)
        local funcs=0
        case "$ext" in
            cbl|cob|cobol)
                funcs=$(grep -ciE "PERFORM|SECTION|PARAGRAPH" "$file" 2>/dev/null || echo 0)
                lang_files[COBOL]=$((${lang_files[COBOL]:-0} + 1))
                lang_lines[COBOL]=$((${lang_lines[COBOL]:-0} + lines))
                lang_funcs[COBOL]=$((${lang_funcs[COBOL]:-0} + funcs))
                ;;
            vb|bas|frm)
                funcs=$(grep -ciE "Sub |Function |Property " "$file" 2>/dev/null || echo 0)
                lang_files[VB]=$((${lang_files[VB]:-0} + 1))
                lang_lines[VB]=$((${lang_lines[VB]:-0} + lines))
                lang_funcs[VB]=$((${lang_funcs[VB]:-0} + funcs))
                ;;
            java)
                funcs=$(grep -ciE "public |private |protected |void |static " "$file" 2>/dev/null || echo 0)
                lang_files[Java]=$((${lang_files[Java]:-0} + 1))
                lang_lines[Java]=$((${lang_lines[Java]:-0} + lines))
                lang_funcs[Java]=$((${lang_funcs[Java]:-0} + funcs))
                ;;
            sql)
                funcs=$(grep -ciE "CREATE PROCEDURE|CREATE FUNCTION|EXEC " "$file" 2>/dev/null || echo 0)
                lang_files[SQL]=$((${lang_files[SQL]:-0} + 1))
                lang_lines[SQL]=$((${lang_lines[SQL]:-0} + lines))
                lang_funcs[SQL]=$((${lang_funcs[SQL]:-0} + funcs))
                ;;
            *)
                lang_files[Other]=$((${lang_files[Other]:-0} + 1))
                lang_lines[Other]=$((${lang_lines[Other]:-0} + lines))
                ;;
        esac
        
        LEGACY_FUNCTIONS=$((LEGACY_FUNCTIONS + funcs))
        
    done < <(find "$legacy_dir" -type f -print0 2>/dev/null)
    
    # Store by language
    for lang in "${!lang_files[@]}"; do
        LEGACY_BY_LANG+=("$lang|${lang_files[$lang]}|${lang_lines[$lang]}|${lang_funcs[$lang]:-0}")
    done
    
    # Estimate migration (check if new src exists and has content)
    if [[ -d "$src_dir" ]]; then
        local new_files
        new_files=$(find "$src_dir" -type f \( -name "*.cs" -o -name "*.ts" -o -name "*.js" \) 2>/dev/null | wc -l)
        
        # Simple heuristic: assume each new file covers ~2 legacy functions
        LEGACY_MIGRATED=$((new_files * 2))
        if [[ $LEGACY_MIGRATED -gt $LEGACY_FUNCTIONS ]]; then
            LEGACY_MIGRATED=$LEGACY_FUNCTIONS
        fi
    fi
    
    if [[ $LEGACY_FUNCTIONS -gt 0 ]]; then
        ALIGNMENT_SCORES[legacy]=$((LEGACY_MIGRATED * 100 / LEGACY_FUNCTIONS))
    else
        ALIGNMENT_SCORES[legacy]=0
    fi
    
    # Track unmigrated
    local unmigrated=$((LEGACY_FUNCTIONS - LEGACY_MIGRATED))
    if [[ $unmigrated -gt 0 ]]; then
        LEGACY_UNMIGRATED+=("$unmigrated functions not yet migrated")
    fi
}

# ============================================================================
# Methodology Compliance
# ============================================================================

analyze_methodology_compliance() {
    local specs_dir="$PROJECT_ROOT/specs"
    local memory_dir="$PROJECT_ROOT/memory"
    local docs_dir="$PROJECT_ROOT/docs"
    
    METHOD_PHASE_SCORES=()
    METHOD_ARTIFACT_MATRIX=()
    METHOD_MISSING=()
    
    local total_score=0
    local phase_count=0
    
    # INCEPTION: Check constitution
    local inception_score=0
    if [[ -f "$memory_dir/constitution.md" ]]; then
        local const_lines
        const_lines=$(wc -l < "$memory_dir/constitution.md" 2>/dev/null || echo 0)
        [[ $const_lines -gt 100 ]] && inception_score=100
        [[ $const_lines -gt 50 && $const_lines -le 100 ]] && inception_score=70
        [[ $const_lines -le 50 ]] && inception_score=30
    fi
    METHOD_PHASE_SCORES+=("INCEPTION|constitution.md|$inception_score")
    total_score=$((total_score + inception_score))
    phase_count=$((phase_count + 1))
    
    # DISCOVERY: Check domain analysis
    local discovery_score=0
    local discovery_items=0
    [[ -d "$PROJECT_ROOT/demo/from_rfp" ]] && discovery_items=$((discovery_items + 30))
    [[ -d "$PROJECT_ROOT/demo/to_rfp" && -n "$(ls -A "$PROJECT_ROOT/demo/to_rfp" 2>/dev/null)" ]] && discovery_items=$((discovery_items + 40))
    [[ -f "$docs_dir/domain-model.md" || -d "$docs_dir/domain" ]] && discovery_items=$((discovery_items + 30))
    discovery_score=$discovery_items
    METHOD_PHASE_SCORES+=("DISCOVERY|domain analysis|$discovery_score")
    total_score=$((total_score + discovery_score))
    phase_count=$((phase_count + 1))
    
    # SPECIFY: Check requirements per feature
    local specify_score=0
    local features_with_reqs=0
    local total_features=0
    if [[ -d "$specs_dir" ]]; then
        for feature_dir in "$specs_dir"/*/; do
            [[ ! -d "$feature_dir" ]] && continue
            total_features=$((total_features + 1))
            [[ -f "$feature_dir/requirements/requirements.md" ]] && features_with_reqs=$((features_with_reqs + 1))
        done
    fi
    [[ $total_features -gt 0 ]] && specify_score=$((features_with_reqs * 100 / total_features))
    METHOD_PHASE_SCORES+=("SPECIFY|requirements.md|$specify_score")
    total_score=$((total_score + specify_score))
    phase_count=$((phase_count + 1))
    
    # PLAN: Check plans and tasks
    local plan_score=0
    local features_with_plan=0
    local features_with_tasks=0
    if [[ -d "$specs_dir" ]]; then
        for feature_dir in "$specs_dir"/*/; do
            [[ ! -d "$feature_dir" ]] && continue
            [[ -f "$feature_dir/planning/plan.md" ]] && features_with_plan=$((features_with_plan + 1))
            [[ -f "$feature_dir/planning/tasks.md" ]] && features_with_tasks=$((features_with_tasks + 1))
        done
    fi
    if [[ $total_features -gt 0 ]]; then
        plan_score=$(((features_with_plan + features_with_tasks) * 50 / total_features))
    fi
    METHOD_PHASE_SCORES+=("PLAN|plan.md, tasks.md|$plan_score")
    total_score=$((total_score + plan_score))
    phase_count=$((phase_count + 1))
    
    # EXECUTE: Check source code
    local execute_score=0
    if [[ -d "$PROJECT_ROOT/src" ]]; then
        local src_files
        src_files=$(find "$PROJECT_ROOT/src" -type f \( -name "*.cs" -o -name "*.ts" -o -name "*.js" -o -name "*.py" \) 2>/dev/null | wc -l)
        [[ $src_files -gt 0 ]] && execute_score=50
        [[ $src_files -gt 10 ]] && execute_score=75
        [[ $src_files -gt 50 ]] && execute_score=100
    fi
    METHOD_PHASE_SCORES+=("EXECUTE|src/ code|$execute_score")
    total_score=$((total_score + execute_score))
    phase_count=$((phase_count + 1))
    
    # VALIDATE: Check test coverage
    local validate_score=0
    if [[ -d "$PROJECT_ROOT/tests" || -d "$PROJECT_ROOT/src" ]]; then
        local test_files
        test_files=$(find "$PROJECT_ROOT" -type f \( -name "*.test.ts" -o -name "*.spec.ts" -o -name "*Tests.cs" -o -name "test_*.py" \) 2>/dev/null | wc -l)
        [[ $test_files -gt 0 ]] && validate_score=30
        [[ $test_files -gt 10 ]] && validate_score=60
        [[ -f "$PROJECT_ROOT/coverage/coverage-summary.json" ]] && validate_score=$((validate_score + 20))
        [[ -f "$PROJECT_ROOT/reports/mutation/mutation.json" ]] && validate_score=$((validate_score + 20))
    fi
    METHOD_PHASE_SCORES+=("VALIDATE|tests, coverage|$validate_score")
    total_score=$((total_score + validate_score))
    phase_count=$((phase_count + 1))
    
    # OPERATE: Check CI/CD and infra
    local operate_score=0
    [[ -f "$PROJECT_ROOT/.github/workflows"/*.yml ]] && operate_score=$((operate_score + 30)) 2>/dev/null
    [[ -d "$PROJECT_ROOT/infra" ]] && operate_score=$((operate_score + 35))
    [[ -f "$PROJECT_ROOT/docker-compose.yml" || -f "$PROJECT_ROOT/Dockerfile" ]] && operate_score=$((operate_score + 35))
    METHOD_PHASE_SCORES+=("OPERATE|CI/CD, infra|$operate_score")
    total_score=$((total_score + operate_score))
    phase_count=$((phase_count + 1))
    
    # Calculate overall methodology score
    if [[ $phase_count -gt 0 ]]; then
        ALIGNMENT_SCORES[methodology]=$((total_score / phase_count))
    else
        ALIGNMENT_SCORES[methodology]=0
    fi
    
    # Track missing items
    [[ $inception_score -lt 100 ]] && METHOD_MISSING+=("Constitution incomplete")
    [[ $discovery_score -lt 50 ]] && METHOD_MISSING+=("Domain analysis missing")
    [[ $specify_score -lt 50 ]] && METHOD_MISSING+=("Requirements incomplete")
    [[ $plan_score -lt 50 ]] && METHOD_MISSING+=("Planning incomplete")
    [[ $execute_score -lt 50 ]] && METHOD_MISSING+=("Implementation behind")
    [[ $validate_score -lt 50 ]] && METHOD_MISSING+=("Testing insufficient")
    [[ $operate_score -lt 50 ]] && METHOD_MISSING+=("CI/CD not configured")
}

# ============================================================================
# Testing & Documentation Analysis
# ============================================================================

analyze_testing() {
    TESTING_COVERAGE=0
    TESTING_FILES=0
    
    # Count test files
    TESTING_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*Tests.cs" -o -name "test_*.py" \) 2>/dev/null | wc -l)
    
    # Try to get coverage from reports
    if [[ -f "$PROJECT_ROOT/coverage/coverage-summary.json" ]]; then
        TESTING_COVERAGE=$(jq -r '.total.lines.pct // 0' "$PROJECT_ROOT/coverage/coverage-summary.json" 2>/dev/null | cut -d. -f1 || echo 0)
    elif [[ $TESTING_FILES -gt 0 ]]; then
        # Estimate based on file count
        TESTING_COVERAGE=$((TESTING_FILES * 5))
        [[ $TESTING_COVERAGE -gt 100 ]] && TESTING_COVERAGE=100
    fi
    
    ALIGNMENT_SCORES[testing]=$TESTING_COVERAGE
}

analyze_documentation() {
    DOC_SCORE=0
    local doc_count=0
    local max_docs=5
    
    # Check key documentation
    [[ -f "$PROJECT_ROOT/README.md" ]] && doc_count=$((doc_count + 1))
    [[ -f "$PROJECT_ROOT/memory/constitution.md" ]] && doc_count=$((doc_count + 1))
    [[ -d "$PROJECT_ROOT/docs" && -n "$(ls -A "$PROJECT_ROOT/docs" 2>/dev/null)" ]] && doc_count=$((doc_count + 1))
    [[ -d "$PROJECT_ROOT/docs/architecture/decisions" && -n "$(ls -A "$PROJECT_ROOT/docs/architecture/decisions" 2>/dev/null)" ]] && doc_count=$((doc_count + 1))
    [[ -f "$PROJECT_ROOT/CONTRIBUTING.md" || -f "$PROJECT_ROOT/CHANGELOG.md" ]] && doc_count=$((doc_count + 1))
    
    DOC_SCORE=$((doc_count * 100 / max_docs))
    ALIGNMENT_SCORES[documentation]=$DOC_SCORE
}

analyze_infrastructure() {
    INFRA_SCORE=0
    
    # Check infrastructure components
    local infra_items=0
    local max_items=5
    
    [[ -d "$PROJECT_ROOT/infra/bicep" || -d "$PROJECT_ROOT/infra/terraform" ]] && infra_items=$((infra_items + 1))
    [[ -f "$PROJECT_ROOT/Dockerfile" ]] && infra_items=$((infra_items + 1))
    [[ -f "$PROJECT_ROOT/docker-compose.yml" ]] && infra_items=$((infra_items + 1))
    [[ -d "$PROJECT_ROOT/.github/workflows" && -n "$(ls -A "$PROJECT_ROOT/.github/workflows" 2>/dev/null)" ]] && infra_items=$((infra_items + 1))
    [[ -d "$PROJECT_ROOT/k8s" || -d "$PROJECT_ROOT/infra/k8s" ]] && infra_items=$((infra_items + 1))
    
    INFRA_SCORE=$((infra_items * 100 / max_items))
    ALIGNMENT_SCORES[infrastructure]=$INFRA_SCORE
}

# ============================================================================
# Gap Analysis
# ============================================================================

analyze_gaps() {
    GAP_TOTAL=0
    GAP_CRITICAL=0
    GAP_HIGH=0
    GAP_MEDIUM=0
    GAP_LOW=0
    
    # RFP gaps
    if [[ ${ALIGNMENT_SCORES[rfp]:-0} -lt 100 ]]; then
        local rfp_gap=$((100 - ${ALIGNMENT_SCORES[rfp]:-0}))
        GAP_TOTAL=$((GAP_TOTAL + RFP_PENDING_ITEMS))
        if [[ $rfp_gap -gt 50 ]]; then
            GAP_CRITICAL=$((GAP_CRITICAL + 1))
            CRITICAL_GAPS+=("RFP coverage only ${ALIGNMENT_SCORES[rfp]:-0}%")
        elif [[ $rfp_gap -gt 30 ]]; then
            GAP_HIGH=$((GAP_HIGH + 1))
            HIGH_GAPS+=("RFP coverage at ${ALIGNMENT_SCORES[rfp]:-0}%")
        fi
    fi
    
    # Legacy migration gaps
    if [[ ${ALIGNMENT_SCORES[legacy]:-0} -lt 100 && $HAS_LEGACY == true ]]; then
        local legacy_gap=$((100 - ${ALIGNMENT_SCORES[legacy]:-0}))
        local unmigrated=$((LEGACY_FUNCTIONS - LEGACY_MIGRATED))
        GAP_TOTAL=$((GAP_TOTAL + unmigrated))
        if [[ $legacy_gap -gt 60 ]]; then
            GAP_CRITICAL=$((GAP_CRITICAL + 1))
            CRITICAL_GAPS+=("Legacy migration only ${ALIGNMENT_SCORES[legacy]:-0}%")
        elif [[ $legacy_gap -gt 30 ]]; then
            GAP_HIGH=$((GAP_HIGH + 1))
            HIGH_GAPS+=("Legacy migration at ${ALIGNMENT_SCORES[legacy]:-0}%")
        fi
    fi
    
    # Methodology gaps
    if [[ ${ALIGNMENT_SCORES[methodology]:-0} -lt 80 ]]; then
        GAP_TOTAL=$((GAP_TOTAL + ${#METHOD_MISSING[@]}))
        for missing in "${METHOD_MISSING[@]}"; do
            GAP_MEDIUM=$((GAP_MEDIUM + 1))
        done
    fi
    
    # Testing gaps
    if [[ ${ALIGNMENT_SCORES[testing]:-0} -lt 80 ]]; then
        GAP_HIGH=$((GAP_HIGH + 1))
        HIGH_GAPS+=("Test coverage at ${ALIGNMENT_SCORES[testing]:-0}% (target: 80%)")
    fi
    
    # Documentation gaps
    if [[ ${ALIGNMENT_SCORES[documentation]:-0} -lt 60 ]]; then
        GAP_LOW=$((GAP_LOW + 1))
    fi
    
    # Calculate overall alignment
    local score_sum=0
    local score_count=0
    for key in rfp legacy methodology testing documentation infrastructure; do
        if [[ -n "${ALIGNMENT_SCORES[$key]:-}" ]]; then
            score_sum=$((score_sum + ${ALIGNMENT_SCORES[$key]}))
            score_count=$((score_count + 1))
        fi
    done
    
    if [[ $score_count -gt 0 ]]; then
        ALIGNMENT_SCORES[overall]=$((score_sum / score_count))
    else
        ALIGNMENT_SCORES[overall]=0
    fi
    
    # Generate recommendations
    if [[ ${ALIGNMENT_SCORES[rfp]:-0} -lt 50 ]]; then
        RECOMMENDATIONS+=("Create feature specs for uncovered RFP items|/bolt.feature|High")
    fi
    if [[ ${ALIGNMENT_SCORES[legacy]:-0} -lt 50 && $HAS_LEGACY == true ]]; then
        RECOMMENDATIONS+=("Analyze and migrate legacy functions|/bolt.analyze|High")
    fi
    if [[ ${ALIGNMENT_SCORES[methodology]:-0} -lt 60 ]]; then
        RECOMMENDATIONS+=("Complete missing methodology artifacts|/bolt.specify|Medium")
    fi
    if [[ ${ALIGNMENT_SCORES[testing]:-0} -lt 80 ]]; then
        RECOMMENDATIONS+=("Improve test coverage|/bolt.test|High")
    fi
}

# ============================================================================
# Report Generation
# ============================================================================

generate_summary_report() {
    print_header "🎯 Bolt Framework Alignment Analysis"
    
    echo -e "${BOLD}Project Type:${NC} $PROJECT_TYPE | ${BOLD}Scope:${NC} $PROJECT_SCOPE"
    [[ -n "$MIGRATION_STRATEGY" ]] && echo -e "${BOLD}Migration Strategy:${NC} $MIGRATION_STRATEGY"
    echo -e "${BOLD}Has RFP:${NC} $HAS_RFP | ${BOLD}Has Legacy:${NC} $HAS_LEGACY"
    echo ""
    
    print_section "Overall Alignment: ${ALIGNMENT_SCORES[overall]:-0}%"
    
    echo "$(get_progress_bar ${ALIGNMENT_SCORES[overall]:-0})"
    echo ""
    
    echo "| Dimension | Score | Status |"
    echo "|-----------|-------|--------|"
    
    for key in rfp legacy methodology testing documentation infrastructure; do
        local score=${ALIGNMENT_SCORES[$key]:-0}
        local status="❌"
        [[ $score -ge 80 ]] && status="✅"
        [[ $score -ge 50 && $score -lt 80 ]] && status="⚠️"
        
        local label=""
        case $key in
            rfp) label="RFP Coverage" ;;
            legacy) label="Legacy Migration" ;;
            methodology) label="Bolt Framework Methodology" ;;
            testing) label="Testing" ;;
            documentation) label="Documentation" ;;
            infrastructure) label="Infrastructure" ;;
        esac
        
        # Only show relevant dimensions
        if [[ $key == "rfp" && $HAS_RFP == false ]]; then continue; fi
        if [[ $key == "legacy" && $HAS_LEGACY == false ]]; then continue; fi
        
        echo "| $label | $(get_progress_bar $score) | $status |"
    done
    
    echo ""
    
    print_section "Gap Summary"
    
    echo "| Priority | Count |"
    echo "|----------|-------|"
    echo "| 🔴 Critical | $GAP_CRITICAL |"
    echo "| 🟠 High | $GAP_HIGH |"
    echo "| 🟡 Medium | $GAP_MEDIUM |"
    echo "| 🟢 Low | $GAP_LOW |"
    echo "| **Total** | **$GAP_TOTAL** |"
    echo ""
    
    if [[ ${#CRITICAL_GAPS[@]} -gt 0 ]]; then
        print_section "🔴 Critical Gaps"
        for gap in "${CRITICAL_GAPS[@]}"; do
            echo "  - $gap"
        done
        echo ""
    fi
    
    if [[ ${#HIGH_GAPS[@]} -gt 0 ]]; then
        print_section "🟠 High Priority Gaps"
        for gap in "${HIGH_GAPS[@]}"; do
            echo "  - $gap"
        done
        echo ""
    fi
    
    print_section "🎯 Recommended Actions"
    
    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        echo "| Priority | Action | Command |"
        echo "|----------|--------|---------|"
        local i=1
        for rec in "${RECOMMENDATIONS[@]}"; do
            IFS='|' read -r action command priority <<< "$rec"
            echo "| $i. $priority | $action | \`$command\` |"
            i=$((i + 1))
        done
    else
        echo "No critical actions needed. Project is well-aligned!"
    fi
}

generate_full_report() {
    generate_summary_report
    
    if [[ $HAS_RFP == true ]]; then
        print_section "📄 RFP Coverage Detail"
        
        echo "| Document | Items | Covered | Coverage |"
        echo "|----------|-------|---------|----------|"
        for doc in "${RFP_DOCUMENTS[@]}"; do
            IFS='|' read -r name items covered coverage <<< "$doc"
            echo "| $name | $items | $covered | $coverage% |"
        done
        echo "| **TOTAL** | **$RFP_TOTAL_ITEMS** | **$RFP_COVERED_ITEMS** | **${ALIGNMENT_SCORES[rfp]:-0}%** |"
        echo ""
        
        if [[ ${#RFP_UNCOVERED[@]} -gt 0 ]]; then
            echo "**Uncovered Items:**"
            for item in "${RFP_UNCOVERED[@]}"; do
                echo "  - $item"
            done
            echo ""
        fi
    fi
    
    if [[ $HAS_LEGACY == true ]]; then
        print_section "📦 Legacy Code Migration"
        
        echo "| Language | Files | Lines | Functions | Migrated |"
        echo "|----------|-------|-------|-----------|----------|"
        for lang_data in "${LEGACY_BY_LANG[@]}"; do
            IFS='|' read -r lang files lines funcs <<< "$lang_data"
            echo "| $lang | $files | $lines | $funcs | - |"
        done
        echo "| **TOTAL** | **$LEGACY_FILES** | **$LEGACY_LINES** | **$LEGACY_FUNCTIONS** | **$LEGACY_MIGRATED** |"
        echo ""
        echo "**Migration Progress**: $(get_progress_bar ${ALIGNMENT_SCORES[legacy]:-0})"
        echo ""
    fi
    
    print_section "📋 Bolt Framework Methodology Compliance"
    
    echo "| Phase | Artifacts | Compliance |"
    echo "|-------|-----------|------------|"
    for phase_data in "${METHOD_PHASE_SCORES[@]}"; do
        IFS='|' read -r phase artifacts score <<< "$phase_data"
        local status="❌"
        [[ $score -ge 80 ]] && status="✅"
        [[ $score -ge 50 && $score -lt 80 ]] && status="⚠️"
        echo "| $phase | $artifacts | $score% $status |"
    done
    echo ""
    
    if [[ ${#METHOD_MISSING[@]} -gt 0 ]]; then
        echo "**Missing Elements:**"
        for missing in "${METHOD_MISSING[@]}"; do
            echo "  - $missing"
        done
    fi
}

generate_json_report() {
    cat << EOF
{
  "project": {
    "type": "$PROJECT_TYPE",
    "scope": "$PROJECT_SCOPE",
    "migrationStrategy": "$MIGRATION_STRATEGY",
    "hasRfp": $HAS_RFP,
    "hasLegacy": $HAS_LEGACY
  },
  "alignment": {
    "overall": ${ALIGNMENT_SCORES[overall]:-0},
    "rfp": ${ALIGNMENT_SCORES[rfp]:-0},
    "legacy": ${ALIGNMENT_SCORES[legacy]:-0},
    "methodology": ${ALIGNMENT_SCORES[methodology]:-0},
    "testing": ${ALIGNMENT_SCORES[testing]:-0},
    "documentation": ${ALIGNMENT_SCORES[documentation]:-0},
    "infrastructure": ${ALIGNMENT_SCORES[infrastructure]:-0}
  },
  "gaps": {
    "total": $GAP_TOTAL,
    "critical": $GAP_CRITICAL,
    "high": $GAP_HIGH,
    "medium": $GAP_MEDIUM,
    "low": $GAP_LOW
  },
  "rfp": {
    "totalItems": $RFP_TOTAL_ITEMS,
    "coveredItems": $RFP_COVERED_ITEMS,
    "pendingItems": $RFP_PENDING_ITEMS
  },
  "legacy": {
    "files": $LEGACY_FILES,
    "lines": $LEGACY_LINES,
    "functions": $LEGACY_FUNCTIONS,
    "migrated": $LEGACY_MIGRATED
  },
  "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

create_baseline() {
    local baseline_dir="$PROJECT_ROOT/memory/baselines"
    mkdir -p "$baseline_dir"
    
    local timestamp
    timestamp=$(date +"%Y-%m-%d")
    local baseline_file="$baseline_dir/alignment_$timestamp.json"
    
    generate_json_report > "$baseline_file"
    
    print_success "Baseline created: $baseline_file"
}

compare_baseline() {
    local baseline_file="$1"
    
    if [[ ! -f "$baseline_file" ]]; then
        print_error "Baseline file not found: $baseline_file"
        return 1
    fi
    
    local prev_overall prev_rfp prev_legacy prev_methodology prev_testing
    prev_overall=$(jq -r '.alignment.overall // 0' "$baseline_file")
    prev_rfp=$(jq -r '.alignment.rfp // 0' "$baseline_file")
    prev_legacy=$(jq -r '.alignment.legacy // 0' "$baseline_file")
    prev_methodology=$(jq -r '.alignment.methodology // 0' "$baseline_file")
    prev_testing=$(jq -r '.alignment.testing // 0' "$baseline_file")
    prev_date=$(jq -r '.generatedAt // "unknown"' "$baseline_file" | cut -dT -f1)
    
    print_header "📊 Alignment Comparison"
    
    echo -e "${BOLD}Comparing with baseline:${NC} $prev_date"
    echo ""
    
    echo "| Dimension | Previous | Current | Delta |"
    echo "|-----------|----------|---------|-------|"
    
    local delta=$((${ALIGNMENT_SCORES[overall]:-0} - prev_overall))
    local sign=""
    [[ $delta -gt 0 ]] && sign="+"
    echo "| Overall | $prev_overall% | ${ALIGNMENT_SCORES[overall]:-0}% | ${sign}${delta}% |"
    
    delta=$((${ALIGNMENT_SCORES[rfp]:-0} - prev_rfp))
    [[ $delta -gt 0 ]] && sign="+" || sign=""
    echo "| RFP Coverage | $prev_rfp% | ${ALIGNMENT_SCORES[rfp]:-0}% | ${sign}${delta}% |"
    
    delta=$((${ALIGNMENT_SCORES[legacy]:-0} - prev_legacy))
    [[ $delta -gt 0 ]] && sign="+" || sign=""
    echo "| Legacy Migration | $prev_legacy% | ${ALIGNMENT_SCORES[legacy]:-0}% | ${sign}${delta}% |"
    
    delta=$((${ALIGNMENT_SCORES[methodology]:-0} - prev_methodology))
    [[ $delta -gt 0 ]] && sign="+" || sign=""
    echo "| Methodology | $prev_methodology% | ${ALIGNMENT_SCORES[methodology]:-0}% | ${sign}${delta}% |"
    
    delta=$((${ALIGNMENT_SCORES[testing]:-0} - prev_testing))
    [[ $delta -gt 0 ]] && sign="+" || sign=""
    echo "| Testing | $prev_testing% | ${ALIGNMENT_SCORES[testing]:-0}% | ${sign}${delta}% |"
}

save_report() {
    local analysis_dir="$PROJECT_ROOT/memory/analysis"
    mkdir -p "$analysis_dir"
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$analysis_dir/alignment_$timestamp.md"
    
    {
        echo "# Alignment Analysis Report"
        echo ""
        echo "**Generated**: $(date)"
        echo ""
        generate_full_report
    } > "$report_file"
    
    print_success "Report saved: $report_file"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full) ANALYSIS_TYPE="full"; shift ;;
            --rfp) ANALYSIS_TYPE="rfp"; shift ;;
            --legacy) ANALYSIS_TYPE="legacy"; shift ;;
            --methodology) ANALYSIS_TYPE="methodology"; shift ;;
            --gaps) ANALYSIS_TYPE="gaps"; shift ;;
            --progress) ANALYSIS_TYPE="progress"; shift ;;
            --baseline) BASELINE_MODE=true; shift ;;
            --compare) COMPARE_FILE="$2"; shift 2 ;;
            --json) OUTPUT_FORMAT="json"; shift ;;
            --save) SAVE_REPORT=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) print_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
    
    # Run all analyses
    detect_project_context
    analyze_rfp_coverage
    analyze_legacy_migration
    analyze_methodology_compliance
    analyze_testing
    analyze_documentation
    analyze_infrastructure
    analyze_gaps
    
    # Handle special modes
    if [[ $BASELINE_MODE == true ]]; then
        create_baseline
        return
    fi
    
    if [[ -n "$COMPARE_FILE" ]]; then
        compare_baseline "$COMPARE_FILE"
        return
    fi
    
    # Generate output
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        generate_json_report
    else
        case $ANALYSIS_TYPE in
            full) generate_full_report ;;
            rfp)
                print_header "RFP Coverage Analysis"
                echo "Coverage: $(get_progress_bar ${ALIGNMENT_SCORES[rfp]:-0})"
                ;;
            legacy)
                print_header "Legacy Migration Analysis"
                echo "Progress: $(get_progress_bar ${ALIGNMENT_SCORES[legacy]:-0})"
                ;;
            methodology)
                print_header "Methodology Compliance"
                for phase_data in "${METHOD_PHASE_SCORES[@]}"; do
                    IFS='|' read -r phase artifacts score <<< "$phase_data"
                    echo "$phase: $score%"
                done
                ;;
            gaps)
                print_header "Gap Analysis"
                echo "Critical: $GAP_CRITICAL | High: $GAP_HIGH | Medium: $GAP_MEDIUM | Low: $GAP_LOW"
                ;;
            *) generate_summary_report ;;
        esac
    fi
    
    # Save if requested
    if [[ $SAVE_REPORT == true ]]; then
        save_report
    fi
}

main "$@"
