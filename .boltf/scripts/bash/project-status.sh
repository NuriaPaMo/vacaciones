#!/usr/bin/env bash
#
# project-status.sh - Bolt Framework Project Status Analyzer
# Analyzes project state and generates status report for continuity
#
# Usage:
#   ./project-status.sh [options]
#
# Options:
#   --full          Full analysis (all artifacts)
#   --features      Feature status only
#   --tasks         Tasks and Bolts status only
#   --infra         Infrastructure status only
#   --quality       Quality metrics only
#   --blockers      Blockers and pending decisions
#   --json          Output in JSON format
#   --feature NAME  Analyze specific feature
#   --save          Save report to memory/context/
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
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
OUTPUT_FORMAT="markdown"
REPORT_TYPE="summary"
SPECIFIC_FEATURE=""
SAVE_REPORT=false

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

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

show_help() {
    cat << EOF
Bolt Framework Project Status Analyzer

Usage: $(basename "$0") [options]

Options:
  --full          Full analysis (all artifacts)
  --features      Feature status only
  --tasks         Tasks and Bolts status only
  --infra         Infrastructure status only
  --quality       Quality metrics only
  --blockers      Blockers and pending decisions
  --json          Output in JSON format
  --feature NAME  Analyze specific feature
  --save          Save report to memory/context/
  -h, --help      Show this help message

Examples:
  $(basename "$0")                    # Executive summary
  $(basename "$0") --full             # Complete analysis
  $(basename "$0") --tasks            # Tasks only
  $(basename "$0") --feature 001-auth # Specific feature
  $(basename "$0") --json --save      # JSON output, saved to memory

EOF
}

# ============================================================================
# Analysis Functions
# ============================================================================

get_project_info() {
    local constitution="$PROJECT_ROOT/memory/constitution.md"

    if [[ -f "$constitution" ]]; then
        # Extract project name (look for filled-in value or placeholder)
        PROJECT_NAME=$(grep -m1 "PROJECT_NAME\|project.*name" "$constitution" 2>/dev/null | head -1 || echo "[PROJECT_NAME]")

        # Determine project scope
        if grep -q "\[x\].*Infrastructure Only" "$constitution" 2>/dev/null; then
            PROJECT_SCOPE="Infrastructure Only"
        elif grep -q "\[x\].*Application Development" "$constitution" 2>/dev/null; then
            PROJECT_SCOPE="Application Development"
        elif grep -q "\[x\].*Full Stack" "$constitution" 2>/dev/null; then
            PROJECT_SCOPE="Full Stack"
        else
            PROJECT_SCOPE="Not Configured"
        fi

        # Determine migration context
        if grep -q "\[x\].*Greenfield" "$constitution" 2>/dev/null; then
            PROJECT_TYPE="Greenfield"
        elif grep -q "\[x\].*Brownfield" "$constitution" 2>/dev/null; then
            PROJECT_TYPE="Brownfield"
        elif grep -q "\[x\].*Migration" "$constitution" 2>/dev/null; then
            PROJECT_TYPE="Migration"
        else
            PROJECT_TYPE="Not Specified"
        fi

        CONSTITUTION_STATUS="✅ Present"
    else
        PROJECT_NAME="[Unknown]"
        PROJECT_SCOPE="Not Configured"
        PROJECT_TYPE="Not Specified"
        CONSTITUTION_STATUS="❌ Missing"
    fi
}

analyze_features() {
    local specs_dir="$PROJECT_ROOT/specs"
    local feature_count=0
    local complete_count=0
    local in_progress_count=0
    local pending_count=0

    FEATURES_DATA=""

    if [[ -d "$specs_dir" ]]; then
        for feature_dir in "$specs_dir"/*/; do
            if [[ -d "$feature_dir" ]]; then
                feature_count=$((feature_count + 1))
                local feature_name=$(basename "$feature_dir")
                local req_file="$feature_dir/requirements/requirements.md"
                local plan_file="$feature_dir/planning/plan.md"
                local tasks_file="$feature_dir/planning/tasks.md"

                local req_status="❌"
                local plan_status="❌"
                local tasks_status="❌"
                local feature_status="⏳ Pending"

                [[ -f "$req_file" ]] && req_status="✅"
                [[ -f "$plan_file" ]] && plan_status="✅"
                [[ -f "$tasks_file" ]] && tasks_status="✅"

                # Determine feature status
                if [[ "$req_status" == "✅" && "$plan_status" == "✅" && "$tasks_status" == "✅" ]]; then
                    # Check if tasks are complete
                    if [[ -f "$tasks_file" ]]; then
                        local total_tasks=$(grep -c "^\- \[" "$tasks_file" 2>/dev/null || echo "0")
                        local done_tasks=$(grep -c "^\- \[x\]" "$tasks_file" 2>/dev/null || echo "0")

                        if [[ "$total_tasks" -gt 0 && "$done_tasks" -eq "$total_tasks" ]]; then
                            feature_status="✅ Complete"
                            complete_count=$((complete_count + 1))
                        elif [[ "$done_tasks" -gt 0 ]]; then
                            feature_status="🔄 In Progress"
                            in_progress_count=$((in_progress_count + 1))
                        else
                            feature_status="⏳ Ready"
                            pending_count=$((pending_count + 1))
                        fi
                    fi
                elif [[ "$req_status" == "✅" ]]; then
                    feature_status="🔄 Planning"
                    in_progress_count=$((in_progress_count + 1))
                else
                    pending_count=$((pending_count + 1))
                fi

                FEATURES_DATA+="| $feature_name | $req_status | $plan_status | $tasks_status | $feature_status |\n"
            fi
        done
    fi

    TOTAL_FEATURES=$feature_count
    COMPLETE_FEATURES=$complete_count
    IN_PROGRESS_FEATURES=$in_progress_count
    PENDING_FEATURES=$pending_count
}

analyze_tasks() {
    local specs_dir="$PROJECT_ROOT/specs"
    local total_tasks=0
    local done_tasks=0
    local in_progress_tasks=0
    local pending_tasks=0
    local blocked_tasks=0

    TASKS_DATA=""
    CURRENT_BOLT=""
    CURRENT_TASKS=""

    if [[ -d "$specs_dir" ]]; then
        for tasks_file in "$specs_dir"/*/planning/tasks.md; do
            if [[ -f "$tasks_file" ]]; then
                local feature_name=$(basename "$(dirname "$(dirname "$tasks_file")")")

                # Count tasks by status
                local file_total=$(grep -c "^\- \[" "$tasks_file" 2>/dev/null || echo "0")
                local file_done=$(grep -c "^\- \[x\]" "$tasks_file" 2>/dev/null || echo "0")
                local file_pending=$((file_total - file_done))

                total_tasks=$((total_tasks + file_total))
                done_tasks=$((done_tasks + file_done))
                pending_tasks=$((pending_tasks + file_pending))

                # Find current bolt (first incomplete section)
                if [[ -z "$CURRENT_BOLT" ]]; then
                    CURRENT_BOLT=$(grep -m1 "^## Bolt [0-9]" "$tasks_file" 2>/dev/null | sed 's/^## //' || echo "")

                    # Get current incomplete tasks
                    CURRENT_TASKS=$(grep "^\- \[ \]" "$tasks_file" 2>/dev/null | head -5 || echo "")
                fi

                TASKS_DATA+="| $feature_name | $file_total | $file_done | $file_pending |\n"
            fi
        done
    fi

    TOTAL_TASKS=$total_tasks
    DONE_TASKS=$done_tasks
    IN_PROGRESS_TASKS=$in_progress_tasks
    PENDING_TASKS=$pending_tasks
    BLOCKED_TASKS=$blocked_tasks

    if [[ $total_tasks -gt 0 ]]; then
        TASKS_PERCENTAGE=$((done_tasks * 100 / total_tasks))
    else
        TASKS_PERCENTAGE=0
    fi
}

analyze_quality() {
    COVERAGE_LINE="N/A"
    COVERAGE_BRANCH="N/A"
    MUTATION_SCORE="N/A"
    LINT_STATUS="Not checked"

    # Check for coverage reports
    local coverage_file=""
    if [[ -f "$PROJECT_ROOT/coverage/coverage-summary.json" ]]; then
        coverage_file="$PROJECT_ROOT/coverage/coverage-summary.json"
    elif [[ -f "$PROJECT_ROOT/coverage/lcov.info" ]]; then
        coverage_file="$PROJECT_ROOT/coverage/lcov.info"
    fi

    if [[ -n "$coverage_file" && -f "$coverage_file" ]]; then
        if [[ "$coverage_file" == *".json" ]]; then
            COVERAGE_LINE=$(jq -r '.total.lines.pct // "N/A"' "$coverage_file" 2>/dev/null || echo "N/A")
            COVERAGE_BRANCH=$(jq -r '.total.branches.pct // "N/A"' "$coverage_file" 2>/dev/null || echo "N/A")
        fi
    fi

    # Check for mutation reports
    if [[ -f "$PROJECT_ROOT/reports/mutation/mutation.json" ]]; then
        MUTATION_SCORE=$(jq -r '.mutationScore // "N/A"' "$PROJECT_ROOT/reports/mutation/mutation.json" 2>/dev/null || echo "N/A")
    fi

    # Determine quality status
    if [[ "$COVERAGE_LINE" != "N/A" ]]; then
        if (( $(echo "$COVERAGE_LINE >= 80" | bc -l 2>/dev/null || echo 0) )); then
            QUALITY_STATUS="✅ Good"
        elif (( $(echo "$COVERAGE_LINE >= 60" | bc -l 2>/dev/null || echo 0) )); then
            QUALITY_STATUS="⚠️ Below Target"
        else
            QUALITY_STATUS="❌ Critical"
        fi
    else
        QUALITY_STATUS="❓ Not Measured"
    fi
}

analyze_infrastructure() {
    INFRA_STATUS="Not present"
    INFRA_TOOL=""
    INFRA_MODULES=0

    if [[ -d "$PROJECT_ROOT/infra/bicep" ]]; then
        INFRA_TOOL="Bicep"
        INFRA_STATUS="✅ Present"
        INFRA_MODULES=$(find "$PROJECT_ROOT/infra/bicep" -name "*.bicep" 2>/dev/null | wc -l)
    elif [[ -d "$PROJECT_ROOT/infra/terraform" ]]; then
        INFRA_TOOL="Terraform"
        INFRA_STATUS="✅ Present"
        INFRA_MODULES=$(find "$PROJECT_ROOT/infra/terraform" -name "*.tf" 2>/dev/null | wc -l)
    elif [[ -d "$PROJECT_ROOT/platform" ]]; then
        INFRA_TOOL="Landing Zone"
        INFRA_STATUS="✅ Present"
        INFRA_MODULES=$(find "$PROJECT_ROOT/platform" -name "*.bicep" -o -name "*.tf" 2>/dev/null | wc -l)
    fi
}

analyze_blockers() {
    BLOCKERS=""
    PENDING_DECISIONS=""

    # Search for blockers in task files
    for tasks_file in "$PROJECT_ROOT"/specs/*/planning/tasks.md; do
        if [[ -f "$tasks_file" ]]; then
            local blocked=$(grep -i "blocked\|blocker" "$tasks_file" 2>/dev/null || true)
            if [[ -n "$blocked" ]]; then
                local feature_name=$(basename "$(dirname "$(dirname "$tasks_file")")")
                BLOCKERS+="- [$feature_name] $blocked\n"
            fi
        fi
    done

    # Search for pending decisions in ADRs or decision logs
    if [[ -d "$PROJECT_ROOT/docs/architecture/decisions" ]]; then
        local pending_adrs=$(grep -l "Status.*Proposed\|Status.*Pending" "$PROJECT_ROOT"/docs/architecture/decisions/*.md 2>/dev/null || true)
        for adr in $pending_adrs; do
            if [[ -f "$adr" ]]; then
                local adr_name=$(basename "$adr")
                PENDING_DECISIONS+="- $adr_name (Pending approval)\n"
            fi
        done
    fi

    # Check memory/decisions if exists
    if [[ -d "$PROJECT_ROOT/memory/decisions" ]]; then
        for decision in "$PROJECT_ROOT"/memory/decisions/*.md; do
            if [[ -f "$decision" ]]; then
                if grep -q "Status.*Pending\|Status.*Open" "$decision" 2>/dev/null; then
                    local dec_name=$(basename "$decision")
                    PENDING_DECISIONS+="- $dec_name\n"
                fi
            fi
        done
    fi
}

get_last_activity() {
    # Get last commit info
    if command -v git &> /dev/null && [[ -d "$PROJECT_ROOT/.git" ]]; then
        LAST_COMMIT=$(git -C "$PROJECT_ROOT" log -1 --format="%h - %s (%cr)" 2>/dev/null || echo "N/A")
        LAST_COMMIT_DATE=$(git -C "$PROJECT_ROOT" log -1 --format="%ci" 2>/dev/null || echo "N/A")
        CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "N/A")
        UNCOMMITTED_CHANGES=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l || echo "0")
    else
        LAST_COMMIT="N/A"
        LAST_COMMIT_DATE="N/A"
        CURRENT_BRANCH="N/A"
        UNCOMMITTED_CHANGES="0"
    fi
}

# ============================================================================
# Report Generation
# ============================================================================

generate_progress_bar() {
    local percentage=$1
    local width=20
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%%" "$percentage"
}

generate_summary_report() {
    print_header "🚀 Bolt Framework Project Status"

    echo -e "${BOLD}Project:${NC} $PROJECT_NAME"
    echo -e "${BOLD}Type:${NC} $PROJECT_TYPE | ${BOLD}Scope:${NC} $PROJECT_SCOPE"
    echo -e "${BOLD}Branch:${NC} $CURRENT_BRANCH"
    echo -e "${BOLD}Last Activity:${NC} $LAST_COMMIT"
    echo ""

    print_section "Quick Stats"

    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Constitution | $CONSTITUTION_STATUS |"
    echo "| Features | $COMPLETE_FEATURES/$TOTAL_FEATURES complete |"
    echo "| Tasks | $(generate_progress_bar $TASKS_PERCENTAGE) |"
    echo "| Quality | $QUALITY_STATUS |"
    echo "| Uncommitted | $UNCOMMITTED_CHANGES files |"
    echo ""

    print_section "🎯 Resume Work"

    if [[ -n "$CURRENT_BOLT" ]]; then
        echo -e "${BOLD}Current Bolt:${NC} $CURRENT_BOLT"
        echo ""
        echo "Next tasks to complete:"
        echo "$CURRENT_TASKS" | head -3 | while read -r task; do
            if [[ -n "$task" ]]; then
                echo "  $task"
            fi
        done
    else
        echo "No active tasks found. Run @Bolt Feature to start a new feature."
    fi
    echo ""

    if [[ -n "$BLOCKERS" ]]; then
        print_section "⚠️ Blockers"
        echo -e "$BLOCKERS"
    fi

    if [[ -n "$PENDING_DECISIONS" ]]; then
        print_section "❓ Pending Decisions"
        echo -e "$PENDING_DECISIONS"
    fi

    print_section "Recommended Actions"

    if [[ "$CONSTITUTION_STATUS" == "❌ Missing" ]]; then
        echo "🔴 HIGH: Create project constitution with @Bolt Constitution"
    fi

    if [[ -n "$BLOCKERS" ]]; then
        echo "🔴 HIGH: Resolve blockers with @Bolt Clarify"
    fi

    if [[ -n "$CURRENT_TASKS" ]]; then
        local next_task=$(echo "$CURRENT_TASKS" | head -1 | grep -oP 'T\d+' || echo "")
        if [[ -n "$next_task" ]]; then
            echo "🟡 MEDIUM: Continue with $next_task using @Bolt Implement"
        fi
    fi

    if [[ "$QUALITY_STATUS" == "⚠️ Below Target" || "$QUALITY_STATUS" == "❌ Critical" ]]; then
        echo "🟡 MEDIUM: Improve test coverage with @Bolt Testing"
    fi
}

generate_full_report() {
    generate_summary_report

    print_section "📋 Features Detail"

    if [[ -n "$FEATURES_DATA" ]]; then
        echo "| Feature | Requirements | Plan | Tasks | Status |"
        echo "|---------|--------------|------|-------|--------|"
        echo -e "$FEATURES_DATA"
    else
        echo "No features found in specs/ directory."
    fi

    print_section "📊 Tasks Detail"

    if [[ -n "$TASKS_DATA" ]]; then
        echo "| Feature | Total | Done | Pending |"
        echo "|---------|-------|------|---------|"
        echo -e "$TASKS_DATA"
    fi

    echo ""
    echo "**Total Progress**: $DONE_TASKS/$TOTAL_TASKS tasks complete ($TASKS_PERCENTAGE%)"

    print_section "🧪 Quality Metrics"

    echo "| Metric | Target | Current | Status |"
    echo "|--------|--------|---------|--------|"
    echo "| Line Coverage | ≥80% | $COVERAGE_LINE% | $(if [[ "$COVERAGE_LINE" != "N/A" ]] && (( $(echo "$COVERAGE_LINE >= 80" | bc -l 2>/dev/null || echo 0) )); then echo "✅"; else echo "⚠️"; fi) |"
    echo "| Branch Coverage | ≥75% | $COVERAGE_BRANCH% | $(if [[ "$COVERAGE_BRANCH" != "N/A" ]] && (( $(echo "$COVERAGE_BRANCH >= 75" | bc -l 2>/dev/null || echo 0) )); then echo "✅"; else echo "⚠️"; fi) |"
    echo "| Mutation Score | ≥70% | $MUTATION_SCORE% | $(if [[ "$MUTATION_SCORE" != "N/A" ]] && (( $(echo "$MUTATION_SCORE >= 70" | bc -l 2>/dev/null || echo 0) )); then echo "✅"; else echo "⚠️"; fi) |"

    if [[ "$PROJECT_SCOPE" == "Infrastructure Only" || "$PROJECT_SCOPE" == "Full Stack" ]]; then
        print_section "🏗️ Infrastructure"

        echo "| Component | Status |"
        echo "|-----------|--------|"
        echo "| IaC Tool | $INFRA_TOOL |"
        echo "| Status | $INFRA_STATUS |"
        echo "| Modules | $INFRA_MODULES files |"
    fi
}

generate_json_report() {
    cat << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "type": "$PROJECT_TYPE",
    "scope": "$PROJECT_SCOPE",
    "constitution": "$CONSTITUTION_STATUS",
    "branch": "$CURRENT_BRANCH"
  },
  "features": {
    "total": $TOTAL_FEATURES,
    "complete": $COMPLETE_FEATURES,
    "inProgress": $IN_PROGRESS_FEATURES,
    "pending": $PENDING_FEATURES
  },
  "tasks": {
    "total": $TOTAL_TASKS,
    "done": $DONE_TASKS,
    "pending": $PENDING_TASKS,
    "blocked": $BLOCKED_TASKS,
    "percentage": $TASKS_PERCENTAGE
  },
  "quality": {
    "lineCoverage": "$COVERAGE_LINE",
    "branchCoverage": "$COVERAGE_BRANCH",
    "mutationScore": "$MUTATION_SCORE",
    "status": "$QUALITY_STATUS"
  },
  "git": {
    "lastCommit": "$LAST_COMMIT",
    "uncommittedChanges": $UNCOMMITTED_CHANGES
  },
  "currentWork": {
    "bolt": "$CURRENT_BOLT",
    "hasBlockers": $(if [[ -n "$BLOCKERS" ]]; then echo "true"; else echo "false"; fi),
    "hasPendingDecisions": $(if [[ -n "$PENDING_DECISIONS" ]]; then echo "true"; else echo "false"; fi)
  },
  "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

save_report() {
    local context_dir="$PROJECT_ROOT/memory/context"
    mkdir -p "$context_dir"

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$context_dir/status_$timestamp.md"
    local latest_file="$context_dir/last-session.md"

    # Generate and save report
    {
        echo "# Project Status Report"
        echo ""
        echo "**Generated**: $(date)"
        echo ""
        generate_full_report
    } > "$report_file"

    # Update last-session symlink/copy
    cp "$report_file" "$latest_file"

    print_success "Report saved to: $report_file"
    print_info "Latest session: $latest_file"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                REPORT_TYPE="full"
                shift
                ;;
            --features)
                REPORT_TYPE="features"
                shift
                ;;
            --tasks)
                REPORT_TYPE="tasks"
                shift
                ;;
            --infra)
                REPORT_TYPE="infra"
                shift
                ;;
            --quality)
                REPORT_TYPE="quality"
                shift
                ;;
            --blockers)
                REPORT_TYPE="blockers"
                shift
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --feature)
                SPECIFIC_FEATURE="$2"
                shift 2
                ;;
            --save)
                SAVE_REPORT=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Run analysis
    get_project_info
    analyze_features
    analyze_tasks
    analyze_quality
    analyze_infrastructure
    analyze_blockers
    get_last_activity

    # Generate output
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        generate_json_report
    else
        case $REPORT_TYPE in
            full)
                generate_full_report
                ;;
            features)
                print_header "Features Status"
                echo -e "$FEATURES_DATA"
                ;;
            tasks)
                print_header "Tasks Status"
                echo -e "$TASKS_DATA"
                echo ""
                echo "Current: $CURRENT_BOLT"
                ;;
            quality)
                print_header "Quality Metrics"
                echo "Line Coverage: $COVERAGE_LINE%"
                echo "Branch Coverage: $COVERAGE_BRANCH%"
                echo "Mutation Score: $MUTATION_SCORE%"
                ;;
            blockers)
                print_header "Blockers & Decisions"
                echo -e "Blockers:\n$BLOCKERS"
                echo -e "Pending Decisions:\n$PENDING_DECISIONS"
                ;;
            *)
                generate_summary_report
                ;;
        esac
    fi

    # Save if requested
    if [[ "$SAVE_REPORT" == true ]]; then
        save_report
    fi
}

main "$@"
