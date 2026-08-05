#!/bin/bash

# ==============================================================================
# plan-retirement.sh - System Retirement Planning Tool
# Part of Bolt Framework / AI-DLC methodology
# Phase: Block 8 - Retirement
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
    echo "  -n, --name NAME       System/feature name to retire"
    echo "  -d, --date DATE       Target retirement date (YYYY-MM-DD)"
    echo "  -l, --list-consumers  List potential consumers"
    echo "  -g, --generate        Generate retirement plan"
    echo "  -i, --interactive     Interactive mode"
    echo "  -h, --help            Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --interactive"
    echo "  $0 --name 'Legacy API' --date 2024-12-31 --generate"
    echo "  $0 --name 'Old Module' --list-consumers"
}

# Read user input with default
read_input() {
    local prompt=$1
    local default=$2
    local result

    if [ -n "$default" ]; then
        echo -en "${YELLOW}$prompt [$default]: ${NC}"
    else
        echo -en "${YELLOW}$prompt: ${NC}"
    fi

    read result

    if [ -z "$result" ]; then
        echo "$default"
    else
        echo "$result"
    fi
}

# Find potential consumers
find_consumers() {
    local system_name=$1

    step "Analyzing potential consumers of '$system_name'..."

    CONSUMERS=()

    # Create search pattern from system name
    local pattern=$(echo "$system_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /[-_ ]*/g')

    # Search in various file types
    for ext in "cs" "ts" "js" "json" "yaml" "yml" "xml" "md"; do
        while IFS= read -r file; do
            if [[ "$file" == *"node_modules"* ]] || [[ "$file" == *"/.git/"* ]]; then
                continue
            fi

            if grep -qi "$pattern" "$file" 2>/dev/null; then
                CONSUMERS+=("$file")
            fi
        done < <(find . -name "*.$ext" -type f 2>/dev/null)
    done

    # Remove duplicates
    CONSUMERS=($(printf "%s\n" "${CONSUMERS[@]}" | sort -u))

    info "Found ${#CONSUMERS[@]} potential consumer references"

    if [ ${#CONSUMERS[@]} -gt 0 ]; then
        echo ""
        local count=0
        for consumer in "${CONSUMERS[@]}"; do
            echo "    • $consumer"
            ((count++)) || true
            if [ $count -ge 10 ]; then
                echo "    ... and $((${#CONSUMERS[@]} - 10)) more"
                break
            fi
        done
    fi
}

# Interactive mode
interactive_mode() {
    step "Interactive Retirement Planning"

    SYSTEM_NAME=$(read_input "System/Feature name to retire")
    if [ -z "$SYSTEM_NAME" ]; then
        err "System name is required"
        exit 1
    fi

    TARGET_DATE=$(read_input "Target retirement date (YYYY-MM-DD)" "$(date -d "+6 months" +%Y-%m-%d 2>/dev/null || date -v+6m +%Y-%m-%d 2>/dev/null || echo "TBD")")
    REASON=$(read_input "Reason for retirement" "System being replaced with modern alternative")
    BUSINESS_REASON=$(read_input "Business reason" "Cost reduction and improved capabilities")
    TECHNICAL_REASON=$(read_input "Technical reason" "Legacy technology, maintenance burden")
    REPLACEMENT=$(read_input "What replaces this system?" "New system TBD")

    # Ask about consumer analysis
    local analyze=$(read_input "Analyze codebase for consumers? (y/n)" "y")
    if [ "$analyze" = "y" ]; then
        find_consumers "$SYSTEM_NAME"
    fi
}

# Generate retirement plan
generate_retirement_plan() {
    local date_created=$(date +%Y-%m-%d)
    local timestamp=$(date +%Y%m%d-%H%M%S)

    step "Generating retirement plan..."

    local retirement_dir="docs/retirement"
    mkdir -p "$retirement_dir"

    local safe_name=$(echo "$SYSTEM_NAME" | tr ' ' '-' | tr -cd '[:alnum:]-')
    local filename="$retirement_dir/${safe_name}-retirement-plan.md"

    # Calculate days remaining
    local days_remaining="N/A"
    if [ -n "$TARGET_DATE" ] && [ "$TARGET_DATE" != "TBD" ]; then
        local target_epoch=$(date -d "$TARGET_DATE" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$TARGET_DATE" +%s 2>/dev/null || echo 0)
        local now_epoch=$(date +%s)
        if [ "$target_epoch" -gt 0 ]; then
            days_remaining=$(( (target_epoch - now_epoch) / 86400 ))
        fi
    fi

    cat > "$filename" << EOF
# Retirement Plan: ${SYSTEM_NAME}

## Document Info

| Property | Value |
|----------|-------|
| Document ID | RET-$timestamp |
| Created | $date_created |
| Status | 📝 Draft |
| System/Feature | ${SYSTEM_NAME} |
| Target Retirement Date | ${TARGET_DATE:-TBD} |
| Days Remaining | $days_remaining |

---

## Executive Summary

${REASON:-System scheduled for retirement.}

---

## Retirement Justification

### Business Rationale

${BUSINESS_REASON:-Business requirements have changed.}

### Technical Rationale

${TECHNICAL_REASON:-Technical debt and maintenance burden.}

### Cost Analysis

| Category | Current Cost | Post-Retirement Savings |
|----------|--------------|------------------------|
| Infrastructure | [TBD] | [TBD] |
| Maintenance | [TBD] | [TBD] |
| Support | [TBD] | [TBD] |

---

## Impact Assessment

### Known Consumers

| Consumer | Type | Impact | Migration Required |
|----------|------|--------|-------------------|
EOF

    if [ ${#CONSUMERS[@]} -gt 0 ]; then
        local count=0
        for consumer in "${CONSUMERS[@]}"; do
            echo "| \`$consumer\` | Code Reference | Medium | Yes |" >> "$filename"
            ((count++)) || true
            if [ $count -ge 20 ]; then
                break
            fi
        done
    else
        echo "| *No consumers identified* | - | - | - |" >> "$filename"
    fi

    cat >> "$filename" << EOF

---

## Migration Strategy

### Replacement System

${REPLACEMENT:-To be determined.}

### Migration Approach

- [ ] Big Bang: Complete migration on single date
- [x] Phased: Gradual migration by consumer
- [ ] Parallel Run: Both systems active during transition

### Migration Steps

1. **Phase 1: Preparation** (Weeks 1-2)
   - [ ] Complete consumer inventory
   - [ ] Document integration points
   - [ ] Create migration runbooks

2. **Phase 2: Development** (Weeks 3-6)
   - [ ] Configure replacement system
   - [ ] Create migration scripts
   - [ ] Develop testing strategy

3. **Phase 3: Testing** (Weeks 7-8)
   - [ ] Integration testing
   - [ ] Performance testing
   - [ ] User acceptance testing

4. **Phase 4: Migration** (Weeks 9-10)
   - [ ] Execute per-consumer migration
   - [ ] Validate each migration
   - [ ] Monitor for issues

5. **Phase 5: Retirement** (Weeks 11-12)
   - [ ] Final data backup
   - [ ] Decommission system
   - [ ] Archive documentation

---

## Communication Plan

| Date | Milestone | Audience |
|------|-----------|----------|
| $date_created | Plan created | Team |
| [+1 week] | Consumer notification | Stakeholders |
| [Target -30 days] | Final warning | All consumers |
| ${TARGET_DATE:-TBD} | System retired | Everyone |

---

## Rollback Plan

If retirement needs to be reversed:

1. Restore from backup
2. Reconfigure routing
3. Notify consumers
4. Update status to "Deferred"

---

## Pre-Retirement Checklist

- [ ] All consumers identified and notified
- [ ] Migration plan per consumer documented
- [ ] Replacement system ready
- [ ] Rollback plan tested
- [ ] Final backup completed
- [ ] Stakeholder sign-offs obtained

## Retirement Day Checklist

- [ ] Final monitoring check
- [ ] Execute decommission
- [ ] Verify system unreachable
- [ ] Update DNS/routing
- [ ] Notify stakeholders

## Post-Retirement Checklist

- [ ] Archive documentation
- [ ] Release resources
- [ ] Close support tickets
- [ ] Update architecture diagrams
- [ ] Conduct lessons learned

---

## Revision History

| Date | Changes | Author |
|------|---------|--------|
| $date_created | Initial plan | Bolt Framework |

---

*Generated by Bolt Framework Retire Command*
EOF

    success "Retirement plan created: $filename"
    echo "$filename"
}

# Main
main() {
    echo -e "\n${MAGENTA}🏚️ Bolt Framework Retirement Planner${NC}"
    echo -e "${MAGENTA}==================================${NC}\n"

    # Initialize variables
    SYSTEM_NAME=""
    TARGET_DATE=""
    REASON=""
    BUSINESS_REASON=""
    TECHNICAL_REASON=""
    REPLACEMENT=""
    CONSUMERS=()

    local list_consumers=false
    local generate=false
    local interactive=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name) SYSTEM_NAME="$2"; shift 2 ;;
            -d|--date) TARGET_DATE="$2"; shift 2 ;;
            -l|--list-consumers) list_consumers=true; shift ;;
            -g|--generate) generate=true; shift ;;
            -i|--interactive) interactive=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    # Default to interactive if no name provided
    if [ -z "$SYSTEM_NAME" ] && ! $interactive; then
        interactive=true
    fi

    if $interactive; then
        interactive_mode
        generate=true
    fi

    # Validate
    if [ -z "$SYSTEM_NAME" ]; then
        err "System name is required"
        usage
        exit 1
    fi

    # Set defaults for non-interactive mode
    if [ -z "$TARGET_DATE" ]; then
        TARGET_DATE=$(date -d "+6 months" +%Y-%m-%d 2>/dev/null || date -v+6m +%Y-%m-%d 2>/dev/null || echo "TBD")
    fi

    if $list_consumers; then
        find_consumers "$SYSTEM_NAME"
        if ! $generate; then
            echo -e "\n${YELLOW}Use --generate to create a full retirement plan${NC}\n"
            exit 0
        fi
    fi

    if $generate; then
        if [ ${#CONSUMERS[@]} -eq 0 ]; then
            find_consumers "$SYSTEM_NAME"
        fi
        generate_retirement_plan
    fi

    # Summary
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Retirement planning complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Review and complete the retirement plan"
    echo "  2. Identify and notify all consumers"
    echo "  3. Schedule migration workshops"
    echo "  4. Set up monitoring for migration progress"
    echo ""
}

main "$@"
