#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Validate Specifications Script
# =============================================================================
# Validates specification files for completeness and consistency.
#
# Usage:
#   ./validate-specs.sh [--check] [branch-name]
#
# Options:
#   --check       Run validation checks
#   branch-name   Specific branch/feature to validate (optional)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track results
ERRORS=0
WARNINGS=0

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((ERRORS++))
}

log_section() {
    echo ""
    echo -e "${BLUE}────────────────────────────────────────${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}────────────────────────────────────────${NC}"
}

# Parse arguments
CHECK_MODE=false
BRANCH_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK_MODE=true
            shift
            ;;
        *)
            BRANCH_NAME="$1"
            shift
            ;;
    esac
done

# Determine spec directories to check
if [ -n "$BRANCH_NAME" ]; then
    SPEC_DIRS=("specs/${BRANCH_NAME}")
else
    SPEC_DIRS=(specs/*)
fi

log_info "Validating specifications..."

# =============================================================================
# Validate Constitution
# =============================================================================
log_section "Constitution"

if [ -f ".boltf/memory/constitution.md" ]; then
    log_success "Constitution exists"

    # Check for required sections
    REQUIRED_SECTIONS=("Tech Stack" "Architectural Principles" "Development Standards")

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if grep -qi "$section" ".boltf/memory/constitution.md"; then
            log_success "Section found: ${section}"
        else
            log_warning "Section missing: ${section}"
        fi
    done
else
    log_error "Constitution not found at .boltf/memory/constitution.md"
    log_info "Run @Bolt Constitution to create it"
fi

# =============================================================================
# Validate Each Spec Directory
# =============================================================================
for SPEC_DIR in "${SPEC_DIRS[@]}"; do
    if [ ! -d "$SPEC_DIR" ]; then
        continue
    fi

    FEATURE_NAME=$(basename "$SPEC_DIR")
    log_section "Feature: ${FEATURE_NAME}"

    # Check spec.md
    if [ -f "${SPEC_DIR}/spec.md" ]; then
        log_success "spec.md exists"

        # Check for user stories
        US_COUNT=$(grep -c "^### US-" "${SPEC_DIR}/spec.md" 2>/dev/null || echo "0")
        if [ "$US_COUNT" -gt 0 ]; then
            log_success "User stories found: ${US_COUNT}"
        else
            log_warning "No user stories found (expected ### US-XXX format)"
        fi

        # Check for acceptance criteria
        AC_COUNT=$(grep -c "AC[0-9]*:" "${SPEC_DIR}/spec.md" 2>/dev/null || echo "0")
        if [ "$AC_COUNT" -gt 0 ]; then
            log_success "Acceptance criteria found: ${AC_COUNT}"
        else
            log_warning "No acceptance criteria found"
        fi

        # Check for unchecked open questions
        OPEN_QUESTIONS=$(grep -c "^\- \[ \]" "${SPEC_DIR}/spec.md" 2>/dev/null || echo "0")
        if [ "$OPEN_QUESTIONS" -gt 0 ]; then
            log_warning "Open questions remaining: ${OPEN_QUESTIONS}"
        fi
    else
        log_error "spec.md not found"
    fi

    # Check plan.md
    if [ -f "${SPEC_DIR}/plan.md" ]; then
        log_success "plan.md exists"

        # Check for bolts
        BOLT_COUNT=$(grep -c "^## Bolt" "${SPEC_DIR}/plan.md" 2>/dev/null || echo "0")
        if [ "$BOLT_COUNT" -gt 0 ]; then
            log_success "Bolts defined: ${BOLT_COUNT}"
        else
            log_warning "No bolts defined (expected ## Bolt X format)"
        fi
    else
        log_warning "plan.md not found (run @Bolt Plan)"
    fi

    # Check tasks.md
    if [ -f "${SPEC_DIR}/tasks.md" ]; then
        log_success "tasks.md exists"

        # Count tasks
        TOTAL_TASKS=$(grep -c "^\- \[" "${SPEC_DIR}/tasks.md" 2>/dev/null || echo "0")
        COMPLETED_TASKS=$(grep -c "^\- \[x\]" "${SPEC_DIR}/tasks.md" 2>/dev/null || echo "0")

        log_info "Task progress: ${COMPLETED_TASKS}/${TOTAL_TASKS}"
    else
        log_warning "tasks.md not found (run @Bolt Tasks)"
    fi

    # Check data-model.md
    if [ -f "${SPEC_DIR}/data-model.md" ]; then
        log_success "data-model.md exists"

        # Check for entities
        ENTITY_COUNT=$(grep -c "^### " "${SPEC_DIR}/data-model.md" 2>/dev/null || echo "0")
        if [ "$ENTITY_COUNT" -gt 0 ]; then
            log_success "Entities defined: ${ENTITY_COUNT}"
        fi
    fi

    # Check contracts directory
    if [ -d "${SPEC_DIR}/contracts" ]; then
        CONTRACT_COUNT=$(find "${SPEC_DIR}/contracts" -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l)
        if [ "$CONTRACT_COUNT" -gt 0 ]; then
            log_success "API contracts found: ${CONTRACT_COUNT}"
        else
            log_warning "contracts/ directory exists but no .yaml files"
        fi
    fi
done

# =============================================================================
# Cross-Reference Validation
# =============================================================================
log_section "Cross-Reference Check"

# Check if all user stories in specs have corresponding tasks
for SPEC_DIR in "${SPEC_DIRS[@]}"; do
    if [ ! -d "$SPEC_DIR" ]; then
        continue
    fi

    if [ -f "${SPEC_DIR}/spec.md" ] && [ -f "${SPEC_DIR}/tasks.md" ]; then
        # Extract user story IDs from spec
        US_IDS=$(grep -o "US-[0-9]*" "${SPEC_DIR}/spec.md" 2>/dev/null | sort -u)

        for US_ID in $US_IDS; do
            if grep -q "\[${US_ID}\]\|\[${US_ID/US-/US}\]" "${SPEC_DIR}/tasks.md" 2>/dev/null; then
                log_success "${US_ID} has corresponding tasks"
            else
                log_warning "${US_ID} has no corresponding tasks"
            fi
        done
    fi
done

# =============================================================================
# Summary
# =============================================================================
log_section "Validation Summary"

echo ""
echo -e "  ${RED}Errors:${NC}   ${ERRORS}"
echo -e "  ${YELLOW}Warnings:${NC} ${WARNINGS}"
echo ""

if [ $ERRORS -gt 0 ]; then
    log_error "Validation FAILED with ${ERRORS} error(s)"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    log_warning "Validation passed with ${WARNINGS} warning(s)"
    exit 0
else
    log_success "Validation PASSED"
    exit 0
fi
