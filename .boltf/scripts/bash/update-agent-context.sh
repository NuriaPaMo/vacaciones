#!/bin/bash

# =============================================================================
# Bolt Framework / AI-DLC - Update Agent Context Script
# =============================================================================
# Validates and synchronizes relationships between:
# - Prompts (.github/prompts/)
# - Agents (.github/copilot/agents/)
# - Constitution (.boltf/memory/constitution.md)
#
# Usage:
#   ./update-agent-context.sh [--check|--report|--fix]
#
# Options:
#   --check   Validate all relationships (default)
#   --report  Generate detailed report
#   --fix     Attempt to fix issues (where possible)
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
PROMPTS_DIR=".github/prompts"
AGENTS_DIR=".github/copilot/agents"
CONSTITUTION=".boltf/memory/constitution.md"

# Counters
ERRORS=0
WARNINGS=0
PASSED=0

# Mode
MODE="${1:---check}"

# =============================================================================
# Helper Functions
# =============================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED++))
}

warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((WARNINGS++))
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    ((ERRORS++))
}

header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# Validation Functions
# =============================================================================

check_constitution_exists() {
    header "Checking Constitution"

    if [[ -f "$CONSTITUTION" ]]; then
        success "Constitution exists: $CONSTITUTION"

        # Check required sections
        local required_sections=("Tech Stack" "Architecture" "Standards" "Security")
        for section in "${required_sections[@]}"; do
            if grep -qi "$section" "$CONSTITUTION" 2>/dev/null; then
                success "Constitution has section: $section"
            else
                warning "Constitution missing section: $section"
            fi
        done
    else
        error "Constitution not found: $CONSTITUTION"
        echo "       Run: @Bolt Constitution to create it"
    fi
}

check_agents_have_constitution_reference() {
    header "Checking Agents → Constitution Reference"

    if [[ ! -d "$AGENTS_DIR" ]]; then
        error "Agents directory not found: $AGENTS_DIR"
        return
    fi

    for agent_file in "$AGENTS_DIR"/*.md; do
        [[ -f "$agent_file" ]] || continue
        [[ "$(basename "$agent_file")" == "README.md" ]] && continue

        local agent_name=$(basename "$agent_file")

        if grep -q "Constitution Reference" "$agent_file" 2>/dev/null; then
            success "Agent has Constitution Reference: $agent_name"
        else
            error "Agent missing Constitution Reference: $agent_name"
        fi

        # Check if agent references memory/constitution.md
        if grep -q "memory/constitution.md" "$agent_file" 2>/dev/null; then
            success "Agent references constitution path: $agent_name"
        else
            warning "Agent doesn't reference constitution path: $agent_name"
        fi
    done
}

check_prompts_have_agent_reference() {
    header "Checking Prompts → Agent Reference"

    if [[ ! -d "$PROMPTS_DIR" ]]; then
        error "Prompts directory not found: $PROMPTS_DIR"
        return
    fi

    for prompt_file in "$PROMPTS_DIR"/*.prompt.md; do
        [[ -f "$prompt_file" ]] || continue

        local prompt_name=$(basename "$prompt_file")

        if grep -q "Agent Reference" "$prompt_file" 2>/dev/null; then
            success "Prompt has Agent Reference: $prompt_name"
        else
            error "Prompt missing Agent Reference: $prompt_name"
        fi

        # Check if prompt links to an agent file
        if grep -q "../copilot/agents/" "$prompt_file" 2>/dev/null; then
            success "Prompt links to agent: $prompt_name"

            # Extract and verify agent links
            local agent_links=$(grep -oP '\.\./(copilot/)?agents/[a-z-]+\.md' "$prompt_file" 2>/dev/null | sort -u)
            for agent_link in $agent_links; do
                local agent_path="$AGENTS_DIR/$(basename "$agent_link")"
                if [[ -f "$agent_path" ]]; then
                    success "  → Linked agent exists: $(basename "$agent_link")"
                else
                    error "  → Linked agent NOT FOUND: $(basename "$agent_link")"
                fi
            done
        else
            warning "Prompt doesn't link to any agent: $prompt_name"
        fi

        # Check if prompt references Constitution
        if grep -q "constitution.md\|Constitution" "$prompt_file" 2>/dev/null; then
            success "Prompt references Constitution: $prompt_name"
        else
            warning "Prompt doesn't reference Constitution: $prompt_name"
        fi
    done
}

check_agent_prompt_coverage() {
    header "Checking Agent ↔ Prompt Coverage"

    # Get list of agents (excluding README)
    local agents=()
    for agent_file in "$AGENTS_DIR"/*.md; do
        [[ -f "$agent_file" ]] || continue
        [[ "$(basename "$agent_file")" == "README.md" ]] && continue
        agents+=("$(basename "$agent_file" .md)")
    done

    # Get list of prompts
    local prompts=()
    for prompt_file in "$PROMPTS_DIR"/*.prompt.md; do
        [[ -f "$prompt_file" ]] || continue
        prompts+=("$(basename "$prompt_file" .prompt.md)")
    done

    info "Found ${#agents[@]} agents and ${#prompts[@]} prompts"

    # Check which agents are referenced by prompts
    echo ""
    info "Agent coverage analysis:"

    local covered_agents=()
    local uncovered_agents=()

    for agent in "${agents[@]}"; do
        local is_covered=false
        for prompt_file in "$PROMPTS_DIR"/*.prompt.md; do
            if grep -q "${agent}.md" "$prompt_file" 2>/dev/null; then
                is_covered=true
                break
            fi
        done

        if $is_covered; then
            covered_agents+=("$agent")
            success "Agent covered by prompt: $agent"
        else
            uncovered_agents+=("$agent")
            warning "Agent NOT covered by any prompt: $agent"
        fi
    done

    echo ""
    info "Coverage: ${#covered_agents[@]}/${#agents[@]} agents ($(( ${#covered_agents[@]} * 100 / ${#agents[@]} ))%)"
}

generate_mapping_report() {
    header "Generating Prompt → Agent Mapping"

    echo ""
    printf "%-35s %-40s\n" "PROMPT" "AGENT(S)"
    echo "─────────────────────────────────────────────────────────────────────────"

    for prompt_file in "$PROMPTS_DIR"/*.prompt.md; do
        [[ -f "$prompt_file" ]] || continue

        local prompt_name=$(basename "$prompt_file" .prompt.md)
        local agents=$(grep -oP '\.\./(copilot/)?agents/[a-z-]+\.md' "$prompt_file" 2>/dev/null |
                       sed 's|../copilot/agents/||g; s|../agents/||g; s|\.md||g' |
                       tr '\n' ', ' | sed 's/,$//')

        if [[ -z "$agents" ]]; then
            agents="${YELLOW}(none)${NC}"
        fi

        printf "%-35s ${GREEN}%s${NC}\n" "$prompt_name" "$agents"
    done
}

check_constitution_tech_stack() {
    header "Checking Constitution Tech Stack"

    if [[ ! -f "$CONSTITUTION" ]]; then
        warning "Cannot check tech stack - Constitution not found"
        return
    fi

    # Extract tech stack section
    info "Tech stack defined in Constitution:"

    # Look for common technology patterns
    local techs=("\.NET" "React" "Angular" "Vue" "Node" "Python" "Go" "Java" "TypeScript" \
                 "PostgreSQL" "MySQL" "MongoDB" "Redis" "Azure" "AWS" "GCP" "Kubernetes" "Docker")

    for tech in "${techs[@]}"; do
        if grep -qi "$tech" "$CONSTITUTION" 2>/dev/null; then
            echo -e "  ${GREEN}•${NC} $tech"
        fi
    done
}

# =============================================================================
# Fix Functions
# =============================================================================

fix_missing_constitution_reference() {
    header "Fixing Missing Constitution References"

    local constitution_section='
## Constitution Reference

**IMPORTANT**: Before generating any output, read `.boltf/memory/constitution.md` for:
- **Tech Stack**: Use exact technologies specified (not examples in this document)
- **Patterns**: Follow architectural patterns from Constitution
- **Standards**: Apply coding standards and conventions defined
- **Policies**: Respect security, compliance, and quality policies

The Constitution is the **single source of truth**. Examples in this agent file are illustrative only.
'

    for agent_file in "$AGENTS_DIR"/*.md; do
        [[ -f "$agent_file" ]] || continue
        [[ "$(basename "$agent_file")" == "README.md" ]] && continue

        if ! grep -q "Constitution Reference" "$agent_file" 2>/dev/null; then
            local agent_name=$(basename "$agent_file")
            warning "Would add Constitution Reference to: $agent_name"
            # Note: Actual file modification would require more complex logic
            # to insert at the right location
        fi
    done

    info "Fix mode shows what would be changed. Manual review recommended."
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    header "Summary"

    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $PASSED"
    echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "  ${RED}Errors:${NC}   $ERRORS"
    echo ""

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  VALIDATION FAILED - Please fix errors above${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  VALIDATION PASSED WITH WARNINGS${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    else
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  ALL VALIDATIONS PASSED${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Bolt Framework / AI-DLC - Agent Context Validator            ║${NC}"
    echo -e "${CYAN}║     Mode: $MODE                                              ${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

    case "$MODE" in
        --check)
            check_constitution_exists
            check_agents_have_constitution_reference
            check_prompts_have_agent_reference
            check_agent_prompt_coverage
            ;;
        --report)
            check_constitution_exists
            check_constitution_tech_stack
            check_agents_have_constitution_reference
            check_prompts_have_agent_reference
            check_agent_prompt_coverage
            generate_mapping_report
            ;;
        --fix)
            check_constitution_exists
            check_agents_have_constitution_reference
            fix_missing_constitution_reference
            check_prompts_have_agent_reference
            ;;
        *)
            echo "Usage: $0 [--check|--report|--fix]"
            echo ""
            echo "Options:"
            echo "  --check   Validate all relationships (default)"
            echo "  --report  Generate detailed report"
            echo "  --fix     Attempt to fix issues (where possible)"
            exit 1
            ;;
    esac

    print_summary
}

main "$@"
