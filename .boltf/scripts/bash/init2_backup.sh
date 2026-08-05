#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Project Initialization Script
# =============================================================================
# Initializes a new project workspace with all necessary Bolt Framework structure
# for either Brownfield (existing code migration) or Greenfield (new project).
#
# This script will:
# 1. Ask key questions about your project configuration
# 2. Pre-fill the constitution.md based on your answers
# 3. Generate the correct project structure for your tech stack
# 4. Set up all Bolt Framework commands and agents
#
# Usage:
#   ./init.sh <output-directory> <project-type> [source-directory]
#
# Parameters:
#   output-directory  : Where to create the project structure
#   project-type      : "brown" for Brownfield, "green" for Greenfield
#   source-directory  : (Required for brown) Directory containing existing code/docs
#
# Examples:
#   ./init.sh ~/projects/my-new-app green
#   ./init.sh ~/projects/legacy-migration brown ~/legacy-code
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

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTITUTION CONFIGURATION VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════
PROJECT_SCOPE=""           # infra-only, app-only, full-stack
INFRA_SCOPE=""             # landing-zone, workload, both
BACKEND_LANGUAGE=""
BACKEND_VERSION=""
BACKEND_FRAMEWORK=""
ARCHITECTURE=""
FRONTEND_FRAMEWORK=""
CQRS_ENABLED=""
DOCKER_ENABLED=""
ORCHESTRATION=""
IAC_TOOL=""
CICD_PLATFORM=""
DATABASE=""
DATA_ACCESS=""
ENVIRONMENTS=""
OBSERVABILITY=""

# Auto mode flag (for testing)
AUTO_MODE=false
AUTO_PROFILE=""  # app-dotnet, app-node, infra-landing, infra-workload, fullstack

# Banner
print_banner() {
    echo -e "${MAGENTA}"
    echo "╔═════════════════════════════════════════════════════════════╗"
    echo "║                                                             ║"
    echo "║       █████╗ ██╗   ██╗██████╗  ██████╗ ██████╗  █████╗      ║"
    echo "║      ██╔══██╗██║   ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗     ║"
    echo "║      ███████║██║   ██║██████╔╝██║   ██║██████╔╝███████║     ║"
    echo "║      ██╔══██║██║   ██║██╔══██╗██║   ██║██╔══██╗██╔══██║     ║"
    echo "║      ██║  ██║╚██████╔╝██║  ██║╚██████╔╝██║  ██║██║  ██║     ║"
    echo "║      ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ║"
    echo "║                                                             ║"
    echo "║              Interactive Project Setup v2.0                 ║"
    echo "╚═════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE MENU FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Generic selection menu
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local key=""
    
    echo -e "\n${CYAN}$prompt${NC}"
    echo -e "${WHITE}(Use ↑/↓ arrows and Enter to select)${NC}\n"
    
    # Hide cursor
    tput civis
    
    while true; do
        # Display options
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${GREEN}▶ ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        # Read key
        read -rsn1 key
        
        # Handle arrow keys
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') # Up arrow
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    [ $selected -ge ${#options[@]} ] && selected=0
                    ;;
            esac
        elif [[ $key == "" ]]; then # Enter
            break
        fi
        
        # Move cursor up to redraw
        tput cuu ${#options[@]}
    done
    
    # Show cursor
    tput cnorm
    
    echo -e "\n${GREEN}Selected: ${options[$selected]}${NC}"
    
    # Return the selected index
    return $selected
}

# Yes/No prompt
ask_yes_no() {
    local prompt="$1"
    local default="${2:-yes}"
    
    if [ "$default" = "yes" ]; then
        echo -e -n "\n${CYAN}$prompt${NC} ${WHITE}[Y/n]:${NC} "
    else
        echo -e -n "\n${CYAN}$prompt${NC} ${WHITE}[y/N]:${NC} "
    fi
    
    read -r response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    if [ -z "$response" ]; then
        [ "$default" = "yes" ] && return 0 || return 1
    fi
    
    [[ "$response" =~ ^(yes|y)$ ]] && return 0 || return 1
}

# Multi-select menu (checkboxes)
multi_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=()
    local current=0
    local key=""
    
    # Initialize all as unselected
    for i in "${!options[@]}"; do
        selected[$i]=0
    done
    
    echo -e "\n${CYAN}$prompt${NC}"
    echo -e "${WHITE}(Use ↑/↓ to move, Space to toggle, Enter to confirm)${NC}\n"
    
    tput civis
    
    while true; do
        for i in "${!options[@]}"; do
            local checkbox="[ ]"
            [ ${selected[$i]} -eq 1 ] && checkbox="[x]"
            
            if [ $i -eq $current ]; then
                echo -e "  ${GREEN}▶ $checkbox ${options[$i]}${NC}"
            else
                echo -e "    $checkbox ${options[$i]}"
            fi
        done
        
        read -rsn1 key
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') ((current--)); [ $current -lt 0 ] && current=$((${#options[@]} - 1)) ;;
                '[B') ((current++)); [ $current -ge ${#options[@]} ] && current=0 ;;
            esac
        elif [[ $key == " " ]]; then
            # Toggle selection
            [ ${selected[$current]} -eq 0 ] && selected[$current]=1 || selected[$current]=0
        elif [[ $key == "" ]]; then
            break
        fi
        
        tput cuu ${#options[@]}
    done
    
    tput cnorm
    
    # Build result string
    MULTI_SELECT_RESULT=""
    for i in "${!options[@]}"; do
        if [ ${selected[$i]} -eq 1 ]; then
            [ -n "$MULTI_SELECT_RESULT" ] && MULTI_SELECT_RESULT+=","
            MULTI_SELECT_RESULT+="${options[$i]}"
        fi
    done
    
    echo -e "\n${GREEN}Selected: $MULTI_SELECT_RESULT${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION WIZARD
# ═══════════════════════════════════════════════════════════════════════════════

run_configuration_wizard() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}                    📋 PROJECT CONFIGURATION WIZARD                     ${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Let's configure your project. Your answers will pre-fill the constitution.${NC}"
    echo -e "${WHITE}Cloud Provider: ${GREEN}Microsoft Azure${WHITE} (mandatory)${NC}"
    
    # ─────────────────────────────────────────────────────────────────────────
    # PROJECT SCOPE (FIRST QUESTION - determines which questions follow)
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  0/10: PROJECT SCOPE (determines which questions follow)              ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    select_option "What type of project is this?" \
        "🏗️  Infrastructure Only (Landing Zone / IaC / Platform)" \
        "💻 Application Development Only (code on existing infra)" \
        "🚀 Full Stack (App + Infrastructure together)"
    case $? in
        0) PROJECT_SCOPE="infra-only" ;;
        1) PROJECT_SCOPE="app-only" ;;
        2) PROJECT_SCOPE="full-stack" ;;
    esac
    
    # ─────────────────────────────────────────────────────────────────────────
    # INFRASTRUCTURE SCOPE (only for infra-only or full-stack)
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$PROJECT_SCOPE" = "infra-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  INFRASTRUCTURE SCOPE                                                ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "What infrastructure scope?" \
            "Landing Zone (Enterprise-scale foundation, Management Groups, Hub-Spoke)" \
            "Workload Infrastructure (App-specific resources on existing platform)" \
            "Both (Landing Zone + Workload)"
        case $? in
            0) INFRA_SCOPE="landing-zone" ;;
            1) INFRA_SCOPE="workload" ;;
            2) INFRA_SCOPE="both" ;;
        esac
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # APPLICATION QUESTIONS (only for app-only or full-stack)
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        
        # ─────────────────────────────────────────────────────────────────────────
        # BACKEND LANGUAGE
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  1/10: BACKEND LANGUAGE                                               ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "Select your backend language:" \
            "C# / .NET" \
            "Node.js / TypeScript"
        local lang_choice=$?
        
        if [ $lang_choice -eq 0 ]; then
            BACKEND_LANGUAGE="csharp"
            
            # .NET Version
            select_option "Select .NET version:" \
                ".NET 8 (LTS)" \
                ".NET 10"
            [ $? -eq 0 ] && BACKEND_VERSION="dotnet8" || BACKEND_VERSION="dotnet10"
            
            # API Style
            select_option "Select API style:" \
                "Minimal APIs (lightweight, modern)" \
                "Controllers/MVC (traditional, structured)" \
                "Azure Functions (serverless)"
            case $? in
                0) BACKEND_FRAMEWORK="minimal-api" ;;
                1) BACKEND_FRAMEWORK="controllers" ;;
                2) BACKEND_FRAMEWORK="azure-functions" ;;
            esac
        else
            BACKEND_LANGUAGE="nodejs"
            
            # Node.js Version
            select_option "Select Node.js version:" \
                "Node.js 20 LTS" \
                "Node.js 22"
            [ $? -eq 0 ] && BACKEND_VERSION="node20" || BACKEND_VERSION="node22"
            
            # Framework
            select_option "Select framework:" \
                "Express (minimal, flexible)" \
                "Fastify (high performance)" \
                "NestJS (enterprise, structured)" \
                "Azure Functions (serverless)"
            case $? in
                0) BACKEND_FRAMEWORK="express" ;;
                1) BACKEND_FRAMEWORK="fastify" ;;
                2) BACKEND_FRAMEWORK="nestjs" ;;
                3) BACKEND_FRAMEWORK="azure-functions" ;;
            esac
        fi
        
        # ─────────────────────────────────────────────────────────────────────────
        # ARCHITECTURE
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  2/10: ARCHITECTURE STYLE                                             ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "Select architecture style:" \
            "Modular Monolith (single deploy, clean modules)" \
            "Microservices (independent services)" \
            "Traditional Monolith (layered)" \
            "Serverless (Azure Functions)" \
            "Event-Driven / CQRS+ES"
        case $? in
            0) ARCHITECTURE="modular-monolith" ;;
            1) ARCHITECTURE="microservices" ;;
            2) ARCHITECTURE="monolith" ;;
            3) ARCHITECTURE="serverless" ;;
            4) ARCHITECTURE="event-driven" ;;
        esac
        
        # ─────────────────────────────────────────────────────────────────────────
        # CQRS
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  3/10: CQRS PATTERN                                                   ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ask_yes_no "Enable CQRS pattern? (Command/Query separation)" "yes"; then
            CQRS_ENABLED="true"
            if [ "$BACKEND_LANGUAGE" = "csharp" ]; then
                echo -e "${GREEN}ℹ️  CQRS will use native .NET interfaces (NO MediatR)${NC}"
            fi
        else
            CQRS_ENABLED="false"
        fi
        
        # ─────────────────────────────────────────────────────────────────────────
        # FRONTEND
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  4/10: FRONTEND FRAMEWORK                                             ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "Select frontend framework:" \
            "None (API only / headless)" \
            "Vue.js 3" \
            "React 18" \
            "Angular 19" \
            "Blazor Server" \
            "Blazor WebAssembly"
        case $? in
            0) FRONTEND_FRAMEWORK="none" ;;
            1) FRONTEND_FRAMEWORK="vue" ;;
            2) FRONTEND_FRAMEWORK="react" ;;
            3) FRONTEND_FRAMEWORK="angular" ;;
            4) FRONTEND_FRAMEWORK="blazor-server" ;;
            5) FRONTEND_FRAMEWORK="blazor-wasm" ;;
        esac
        
        # ─────────────────────────────────────────────────────────────────────────
        # DATABASE
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  5/10: DATABASE                                                       ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "Select primary database:" \
            "Azure SQL Database" \
            "SQL Server (on-premises)" \
            "PostgreSQL" \
            "Azure Cosmos DB" \
            "MongoDB"
        case $? in
            0) DATABASE="azure-sql" ;;
            1) DATABASE="sql-server" ;;
            2) DATABASE="postgresql" ;;
            3) DATABASE="cosmos-db" ;;
            4) DATABASE="mongodb" ;;
        esac
        
        # Data Access (depends on backend language)
        if [ "$BACKEND_LANGUAGE" = "csharp" ]; then
            select_option "Select data access pattern:" \
                "Entity Framework Core (full ORM)" \
                "Dapper (micro-ORM, performance)" \
                "EF Core + Dapper (EF writes, Dapper reads)"
            case $? in
                0) DATA_ACCESS="ef-core" ;;
                1) DATA_ACCESS="dapper" ;;
                2) DATA_ACCESS="ef-dapper" ;;
            esac
        else
            select_option "Select data access pattern:" \
                "Prisma (type-safe ORM)" \
                "TypeORM (Active Record / Data Mapper)" \
                "Drizzle (lightweight, SQL-like)" \
                "Knex.js (query builder)"
            case $? in
                0) DATA_ACCESS="prisma" ;;
                1) DATA_ACCESS="typeorm" ;;
                2) DATA_ACCESS="drizzle" ;;
                3) DATA_ACCESS="knex" ;;
            esac
        fi
        
        # ─────────────────────────────────────────────────────────────────────────
        # CONTAINERS & ORCHESTRATION
        # ─────────────────────────────────────────────────────────────────────────
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  6/10: CONTAINERS & ORCHESTRATION                                     ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ask_yes_no "Use Docker containers?" "yes"; then
            DOCKER_ENABLED="true"
            
            select_option "Select orchestration platform:" \
                "Azure Kubernetes Service (AKS)" \
                "Azure Container Apps (serverless containers)" \
                "Azure App Service (PaaS)" \
                "Docker Compose only (development)"
            case $? in
                0) ORCHESTRATION="aks" ;;
                1) ORCHESTRATION="container-apps" ;;
                2) ORCHESTRATION="app-service" ;;
                3) ORCHESTRATION="docker-compose" ;;
            esac
        else
            DOCKER_ENABLED="false"
            ORCHESTRATION="app-service"
        fi
        
    fi  # End of app-only or full-stack questions
    
    # ─────────────────────────────────────────────────────────────────────────
    # INFRASTRUCTURE AS CODE (for infra-only or full-stack)
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$PROJECT_SCOPE" = "infra-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  7/10: INFRASTRUCTURE AS CODE                                         ${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        select_option "Select IaC tool:" \
            "Bicep (Azure-native, recommended)" \
            "Terraform (multi-cloud)" \
            "Pulumi (programmatic)"
        case $? in
            0) IAC_TOOL="bicep" ;;
            1) IAC_TOOL="terraform" ;;
            2) IAC_TOOL="pulumi" ;;
        esac
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # CI/CD (for all project types)
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  8/10: CI/CD PLATFORM                                                 ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    select_option "Select CI/CD platform:" \
        "GitHub Actions" \
        "Azure DevOps Pipelines"
    [ $? -eq 0 ] && CICD_PLATFORM="github-actions" || CICD_PLATFORM="azure-devops"
    
    # ─────────────────────────────────────────────────────────────────────────
    # ENVIRONMENTS (for all project types)
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  9/10: ENVIRONMENTS                                                   ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    multi_select "Select environments to configure:" \
        "dev" \
        "uat" \
        "pre" \
        "prod"
    ENVIRONMENTS="$MULTI_SELECT_RESULT"
    
    # Default if nothing selected
    [ -z "$ENVIRONMENTS" ] && ENVIRONMENTS="dev,uat,pre,prod"
    
    # ─────────────────────────────────────────────────────────────────────────
    # OBSERVABILITY (for all project types)
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  10/10: OBSERVABILITY                                                 ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    select_option "Select observability strategy:" \
        "Azure-Native (Azure Monitor + App Insights)" \
        "OpenTelemetry → Azure Monitor" \
        "OpenTelemetry → Grafana Stack"
    case $? in
        0) OBSERVABILITY="azure-native" ;;
        1) OBSERVABILITY="otel-azure" ;;
        2) OBSERVABILITY="otel-grafana" ;;
    esac
    
    # ─────────────────────────────────────────────────────────────────────────
    # SUMMARY
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}                        📋 CONFIGURATION SUMMARY                        ${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Project Scope:${NC}  $PROJECT_SCOPE"
    if [ -n "$INFRA_SCOPE" ]; then
        echo -e "${WHITE}Infra Scope:${NC}    $INFRA_SCOPE"
    fi
    if [ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        echo -e "${WHITE}Backend:${NC}        $BACKEND_LANGUAGE ($BACKEND_VERSION) - $BACKEND_FRAMEWORK"
        echo -e "${WHITE}Architecture:${NC}   $ARCHITECTURE"
        echo -e "${WHITE}CQRS:${NC}           $CQRS_ENABLED"
        echo -e "${WHITE}Frontend:${NC}       $FRONTEND_FRAMEWORK"
        echo -e "${WHITE}Database:${NC}       $DATABASE ($DATA_ACCESS)"
        echo -e "${WHITE}Containers:${NC}     $DOCKER_ENABLED → $ORCHESTRATION"
    fi
    if [ "$PROJECT_SCOPE" = "infra-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        echo -e "${WHITE}IaC:${NC}            $IAC_TOOL"
    fi
    echo -e "${WHITE}CI/CD:${NC}          $CICD_PLATFORM"
    echo -e "${WHITE}Environments:${NC}   $ENVIRONMENTS"
    echo -e "${WHITE}Observability:${NC}  $OBSERVABILITY"
    echo ""
    
    if ! ask_yes_no "Proceed with this configuration?" "yes"; then
        echo -e "${YELLOW}Configuration cancelled. Run the script again to reconfigure.${NC}"
        exit 0
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# DYNAMIC PROJECT STRUCTURE GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

generate_project_structure() {
    # ─────────────────────────────────────────────────────────────────────────
    # INFRASTRUCTURE ONLY
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$PROJECT_SCOPE" = "infra-only" ]; then
        log_step "Generating infrastructure-only project structure..."
        generate_infrastructure_only_structure
        return
    fi
    
    log_step "Generating project structure for $BACKEND_LANGUAGE + $ARCHITECTURE..."
    
    # ─────────────────────────────────────────────────────────────────────────
    # C# / .NET STRUCTURES
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$BACKEND_LANGUAGE" = "csharp" ]; then
        case "$ARCHITECTURE" in
            "modular-monolith")
                generate_csharp_modular_monolith
                ;;
            "microservices")
                generate_csharp_microservices
                ;;
            "monolith")
                generate_csharp_monolith
                ;;
            "serverless")
                generate_csharp_serverless
                ;;
            "event-driven")
                generate_csharp_modular_monolith  # Uses modular + CQRS+ES
                ;;
        esac
        
        # Generate .NET solution files
        generate_dotnet_solution_files
        
    # ─────────────────────────────────────────────────────────────────────────
    # NODE.JS / TYPESCRIPT STRUCTURES
    # ─────────────────────────────────────────────────────────────────────────
    else
        case "$ARCHITECTURE" in
            "modular-monolith")
                generate_nodejs_modular_monolith
                ;;
            "microservices")
                generate_nodejs_microservices
                ;;
            "monolith")
                generate_nodejs_monolith
                ;;
            "serverless")
                generate_nodejs_serverless
                ;;
            "event-driven")
                generate_nodejs_modular_monolith  # Uses modular + CQRS+ES
                ;;
        esac
        
        # Stack-specific config files will be generated based on constitution
        log_info "Stack-specific configuration files will be generated after constitution setup"
    fi
    
    # ─────────────────────────────────────────────────────────────────────────
    # INFRASTRUCTURE (common)
    # ─────────────────────────────────────────────────────────────────────────
    generate_infrastructure_structure
    
    # ─────────────────────────────────────────────────────────────────────────
    # FRONTEND (if selected)
    # ─────────────────────────────────────────────────────────────────────────
    if [ "$FRONTEND_FRAMEWORK" != "none" ]; then
        generate_frontend_placeholder
    fi
    
    log_success "Project structure generated!"
}

# ═══════════════════════════════════════════════════════════════════════════════
# C# / .NET STRUCTURE GENERATORS
# ═══════════════════════════════════════════════════════════════════════════════

generate_csharp_modular_monolith() {
    log_info "Creating C# Modular Monolith structure..."
    
    # Shared Kernel with CQRS
    mkdir -p "$OUTPUT_DIR/src/Shared/SharedKernel/CQRS"
    mkdir -p "$OUTPUT_DIR/src/Shared/SharedKernel/Domain"
    mkdir -p "$OUTPUT_DIR/src/Shared/SharedKernel/Results"
    mkdir -p "$OUTPUT_DIR/src/Shared/Contracts/IntegrationEvents"
    
    # Sample module structure
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Domain/Entities"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Domain/ValueObjects"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Domain/Events"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Domain/Repositories"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Application/Commands"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Application/Queries"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Application/EventHandlers"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Infrastructure/Persistence"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Infrastructure/Persistence/Configurations"
    mkdir -p "$OUTPUT_DIR/src/Modules/SampleModule/SampleModule.Api/Endpoints"
    
    # API Host (composition root)
    mkdir -p "$OUTPUT_DIR/src/Api.Host"
    
    # Tests
    mkdir -p "$OUTPUT_DIR/tests/SampleModule.UnitTests/Domain"
    mkdir -p "$OUTPUT_DIR/tests/SampleModule.UnitTests/Application"
    mkdir -p "$OUTPUT_DIR/tests/SampleModule.IntegrationTests"
    mkdir -p "$OUTPUT_DIR/tests/Architecture.Tests"
    mkdir -p "$OUTPUT_DIR/tests/Common.Tests/Fixtures"
    mkdir -p "$OUTPUT_DIR/tests/Common.Tests/Builders"
    
    # Generate CQRS interfaces if enabled
    if [ "$CQRS_ENABLED" = "true" ]; then
        generate_csharp_cqrs_interfaces
    fi
}

generate_csharp_microservices() {
    log_info "Creating C# Microservices structure..."
    
    # Building Blocks
    mkdir -p "$OUTPUT_DIR/src/BuildingBlocks/SharedKernel/CQRS"
    mkdir -p "$OUTPUT_DIR/src/BuildingBlocks/SharedKernel/Domain"
    mkdir -p "$OUTPUT_DIR/src/BuildingBlocks/EventBus"
    mkdir -p "$OUTPUT_DIR/src/BuildingBlocks/ServiceDiscovery"
    
    # API Gateway
    mkdir -p "$OUTPUT_DIR/src/ApiGateway"
    
    # Sample Service
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Api"
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Domain/Entities"
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Domain/ValueObjects"
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Application/Commands"
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Application/Queries"
    mkdir -p "$OUTPUT_DIR/src/Services/SampleService/SampleService.Infrastructure/Persistence"
    
    # Tests
    mkdir -p "$OUTPUT_DIR/tests/SampleService.UnitTests"
    mkdir -p "$OUTPUT_DIR/tests/SampleService.IntegrationTests"
    mkdir -p "$OUTPUT_DIR/tests/Architecture.Tests"
    
    # Docker compose for local dev
    touch "$OUTPUT_DIR/docker-compose.yml"
    touch "$OUTPUT_DIR/docker-compose.override.yml"
    
    if [ "$CQRS_ENABLED" = "true" ]; then
        generate_csharp_cqrs_interfaces "src/BuildingBlocks/SharedKernel/CQRS"
    fi
}

generate_csharp_monolith() {
    log_info "Creating C# Traditional Monolith structure..."
    
    # Layered structure
    mkdir -p "$OUTPUT_DIR/src/Domain/Entities"
    mkdir -p "$OUTPUT_DIR/src/Domain/ValueObjects"
    mkdir -p "$OUTPUT_DIR/src/Domain/Events"
    mkdir -p "$OUTPUT_DIR/src/Domain/Services"
    mkdir -p "$OUTPUT_DIR/src/Application/UseCases"
    mkdir -p "$OUTPUT_DIR/src/Application/DTOs"
    mkdir -p "$OUTPUT_DIR/src/Application/Interfaces"
    mkdir -p "$OUTPUT_DIR/src/Infrastructure/Persistence"
    mkdir -p "$OUTPUT_DIR/src/Infrastructure/External"
    mkdir -p "$OUTPUT_DIR/src/Presentation/Api"
    
    # Tests
    mkdir -p "$OUTPUT_DIR/tests/Unit"
    mkdir -p "$OUTPUT_DIR/tests/Integration"
    mkdir -p "$OUTPUT_DIR/tests/E2E"
}

generate_csharp_serverless() {
    log_info "Creating C# Serverless (Azure Functions) structure..."
    
    # Functions project
    mkdir -p "$OUTPUT_DIR/src/Functions/HttpTriggers"
    mkdir -p "$OUTPUT_DIR/src/Functions/QueueTriggers"
    mkdir -p "$OUTPUT_DIR/src/Functions/TimerTriggers"
    
    # Shared logic
    mkdir -p "$OUTPUT_DIR/src/Core/Domain"
    mkdir -p "$OUTPUT_DIR/src/Core/Application"
    mkdir -p "$OUTPUT_DIR/src/Core/Infrastructure"
    
    # Tests
    mkdir -p "$OUTPUT_DIR/tests/Functions.UnitTests"
    mkdir -p "$OUTPUT_DIR/tests/Functions.IntegrationTests"
}

generate_csharp_cqrs_interfaces() {
    local target_dir="${1:-src/Shared/SharedKernel/CQRS}"
    
    log_info "Generating native CQRS interfaces (NO MediatR)..."
    
    # ICommand.cs
    cat > "$OUTPUT_DIR/$target_dir/ICommand.cs" << 'EOF'
namespace SharedKernel.CQRS;

/// <summary>
/// Marker interface for commands (write operations)
/// </summary>
public interface ICommand { }

/// <summary>
/// Command handler without result
/// </summary>
public interface ICommandHandler<in TCommand> where TCommand : ICommand
{
    Task HandleAsync(TCommand command, CancellationToken ct = default);
}

/// <summary>
/// Command handler with result
/// </summary>
public interface ICommandHandler<in TCommand, TResult> where TCommand : ICommand
{
    Task<TResult> HandleAsync(TCommand command, CancellationToken ct = default);
}
EOF

    # IQuery.cs
    cat > "$OUTPUT_DIR/$target_dir/IQuery.cs" << 'EOF'
namespace SharedKernel.CQRS;

/// <summary>
/// Marker interface for queries (read operations)
/// </summary>
public interface IQuery<TResult> { }

/// <summary>
/// Query handler
/// </summary>
public interface IQueryHandler<in TQuery, TResult> where TQuery : IQuery<TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken ct = default);
}
EOF

    # IDispatcher.cs
    cat > "$OUTPUT_DIR/$target_dir/IDispatcher.cs" << 'EOF'
namespace SharedKernel.CQRS;

/// <summary>
/// Command dispatcher - resolves and executes command handlers via DI
/// </summary>
public interface ICommandDispatcher
{
    Task DispatchAsync<TCommand>(TCommand command, CancellationToken ct = default) 
        where TCommand : ICommand;
    
    Task<TResult> DispatchAsync<TCommand, TResult>(TCommand command, CancellationToken ct = default) 
        where TCommand : ICommand;
}

/// <summary>
/// Query dispatcher - resolves and executes query handlers via DI
/// </summary>
public interface IQueryDispatcher
{
    Task<TResult> DispatchAsync<TQuery, TResult>(TQuery query, CancellationToken ct = default) 
        where TQuery : IQuery<TResult>;
}
EOF

    # IDomainEvent.cs
    cat > "$OUTPUT_DIR/$target_dir/IDomainEvent.cs" << 'EOF'
namespace SharedKernel.CQRS;

/// <summary>
/// Domain event base interface
/// </summary>
public interface IDomainEvent
{
    Guid EventId { get; }
    DateTime OccurredOn { get; }
}

/// <summary>
/// Domain event handler
/// </summary>
public interface IDomainEventHandler<in TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent domainEvent, CancellationToken ct = default);
}

/// <summary>
/// Event dispatcher for publishing domain events
/// </summary>
public interface IEventDispatcher
{
    Task PublishAsync<TEvent>(TEvent domainEvent, CancellationToken ct = default) 
        where TEvent : IDomainEvent;
}
EOF

    log_success "CQRS interfaces generated (NO MediatR)"
}

generate_dotnet_solution_files() {
    log_info "Generating .NET solution files..."
    
    # Directory.Build.props
    cat > "$OUTPUT_DIR/Directory.Build.props" << EOF
<Project>
  <PropertyGroup>
    <TargetFramework>net${BACKEND_VERSION#dotnet}.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
EOF

    # Directory.Packages.props (Central Package Management)
    cat > "$OUTPUT_DIR/Directory.Packages.props" << 'EOF'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <!-- Testing -->
    <PackageVersion Include="xunit" Version="2.6.6" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="2.5.6" />
    <PackageVersion Include="FluentAssertions" Version="6.12.0" />
    <PackageVersion Include="NSubstitute" Version="5.1.0" />
    <PackageVersion Include="Testcontainers" Version="3.7.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.0" />
    
    <!-- Architecture Testing -->
    <PackageVersion Include="NetArchTest.Rules" Version="1.3.2" />
    
    <!-- Validation -->
    <PackageVersion Include="FluentValidation" Version="11.9.0" />
    
    <!-- EF Core (if used) -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
    
    <!-- Observability -->
    <PackageVersion Include="OpenTelemetry" Version="1.7.0" />
    <PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.7.0" />
  </ItemGroup>
</Project>
EOF

    # global.json
    cat > "$OUTPUT_DIR/global.json" << EOF
{
  "sdk": {
    "version": "${BACKEND_VERSION#dotnet}.0.100",
    "rollForward": "latestMinor"
  }
}
EOF

    # .editorconfig for C#
    cat > "$OUTPUT_DIR/.editorconfig" << 'EOF'
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.cs]
# Naming conventions
dotnet_naming_rule.private_fields_should_be_camel_case.severity = warning
dotnet_naming_rule.private_fields_should_be_camel_case.symbols = private_fields
dotnet_naming_rule.private_fields_should_be_camel_case.style = camel_case_underscore

dotnet_naming_symbols.private_fields.applicable_kinds = field
dotnet_naming_symbols.private_fields.applicable_accessibilities = private

dotnet_naming_style.camel_case_underscore.capitalization = camel_case
dotnet_naming_style.camel_case_underscore.required_prefix = _

# Code style
csharp_style_namespace_declarations = file_scoped:warning
csharp_prefer_braces = true:warning
csharp_style_var_for_built_in_types = false:suggestion
csharp_style_var_when_type_is_apparent = true:suggestion
csharp_style_var_elsewhere = false:suggestion

# Async
csharp_style_prefer_local_over_anonymous_function = true:suggestion
dotnet_style_prefer_auto_properties = true:suggestion
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# NODE.JS / TYPESCRIPT STRUCTURE GENERATORS
# ═══════════════════════════════════════════════════════════════════════════════

generate_nodejs_modular_monolith() {
    log_info "Creating Node.js Modular Monolith structure..."
    
    # Shared kernel
    mkdir -p "$OUTPUT_DIR/src/shared/kernel/cqrs"
    mkdir -p "$OUTPUT_DIR/src/shared/kernel/domain"
    mkdir -p "$OUTPUT_DIR/src/shared/kernel/results"
    mkdir -p "$OUTPUT_DIR/src/shared/contracts"
    
    # Sample module
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/domain/entities"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/domain/value-objects"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/domain/events"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/application/commands"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/application/queries"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/application/event-handlers"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/infrastructure/persistence"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/api"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/__tests__/unit"
    mkdir -p "$OUTPUT_DIR/src/modules/sample-module/__tests__/integration"
    
    # Entry point
    touch "$OUTPUT_DIR/src/main.ts"
    
    # Tests (global)
    mkdir -p "$OUTPUT_DIR/tests/e2e"
    mkdir -p "$OUTPUT_DIR/tests/architecture"
    mkdir -p "$OUTPUT_DIR/tests/fixtures"
    
    if [ "$CQRS_ENABLED" = "true" ]; then
        generate_nodejs_cqrs_interfaces
    fi
}

generate_nodejs_microservices() {
    log_info "Creating Node.js Microservices structure..."
    
    # Root for workspaces
    mkdir -p "$OUTPUT_DIR/packages/shared-kernel/src/cqrs"
    mkdir -p "$OUTPUT_DIR/packages/shared-kernel/src/domain"
    mkdir -p "$OUTPUT_DIR/packages/event-bus/src"
    
    # Sample service
    mkdir -p "$OUTPUT_DIR/services/sample-service/src/domain"
    mkdir -p "$OUTPUT_DIR/services/sample-service/src/application"
    mkdir -p "$OUTPUT_DIR/services/sample-service/src/infrastructure"
    mkdir -p "$OUTPUT_DIR/services/sample-service/src/api"
    mkdir -p "$OUTPUT_DIR/services/sample-service/tests"
    
    # Docker compose
    touch "$OUTPUT_DIR/docker-compose.yml"
    
    if [ "$CQRS_ENABLED" = "true" ]; then
        generate_nodejs_cqrs_interfaces "packages/shared-kernel/src/cqrs"
    fi
}

generate_nodejs_monolith() {
    log_info "Creating Node.js Traditional Monolith structure..."
    
    mkdir -p "$OUTPUT_DIR/src/domain/entities"
    mkdir -p "$OUTPUT_DIR/src/domain/value-objects"
    mkdir -p "$OUTPUT_DIR/src/domain/events"
    mkdir -p "$OUTPUT_DIR/src/application/use-cases"
    mkdir -p "$OUTPUT_DIR/src/application/dtos"
    mkdir -p "$OUTPUT_DIR/src/infrastructure/persistence"
    mkdir -p "$OUTPUT_DIR/src/infrastructure/external"
    mkdir -p "$OUTPUT_DIR/src/api/routes"
    mkdir -p "$OUTPUT_DIR/src/api/middleware"
    
    mkdir -p "$OUTPUT_DIR/tests/unit"
    mkdir -p "$OUTPUT_DIR/tests/integration"
    mkdir -p "$OUTPUT_DIR/tests/e2e"
}

generate_nodejs_serverless() {
    log_info "Creating Node.js Serverless (Azure Functions) structure..."
    
    mkdir -p "$OUTPUT_DIR/src/functions/http"
    mkdir -p "$OUTPUT_DIR/src/functions/queue"
    mkdir -p "$OUTPUT_DIR/src/functions/timer"
    mkdir -p "$OUTPUT_DIR/src/core/domain"
    mkdir -p "$OUTPUT_DIR/src/core/application"
    mkdir -p "$OUTPUT_DIR/src/core/infrastructure"
    
    mkdir -p "$OUTPUT_DIR/tests/functions"
}

generate_nodejs_cqrs_interfaces() {
    local target_dir="${1:-src/shared/kernel/cqrs}"
    
    log_info "Generating TypeScript CQRS interfaces..."
    
    # interfaces.ts
    cat > "$OUTPUT_DIR/$target_dir/interfaces.ts" << 'EOF'
// ============================================
// COMMANDS
// ============================================
export interface ICommand {}

export interface ICommandHandler<TCommand extends ICommand, TResult = void> {
  handle(command: TCommand): Promise<TResult>;
}

export interface ICommandBus {
  dispatch<TCommand extends ICommand>(command: TCommand): Promise<void>;
  dispatch<TCommand extends ICommand, TResult>(command: TCommand): Promise<TResult>;
}

// ============================================
// QUERIES
// ============================================
export interface IQuery<TResult> {}

export interface IQueryHandler<TQuery extends IQuery<TResult>, TResult> {
  handle(query: TQuery): Promise<TResult>;
}

export interface IQueryBus {
  dispatch<TQuery extends IQuery<TResult>, TResult>(query: TQuery): Promise<TResult>;
}

// ============================================
// DOMAIN EVENTS
// ============================================
export interface IDomainEvent {
  readonly eventId: string;
  readonly occurredOn: Date;
  readonly eventType: string;
}

export interface IDomainEventHandler<TEvent extends IDomainEvent> {
  handle(event: TEvent): Promise<void>;
}

export interface IEventBus {
  publish<TEvent extends IDomainEvent>(event: TEvent): Promise<void>;
  subscribe<TEvent extends IDomainEvent>(
    eventType: string,
    handler: IDomainEventHandler<TEvent>
  ): void;
}
EOF

    # index.ts
    cat > "$OUTPUT_DIR/$target_dir/index.ts" << 'EOF'
export * from './interfaces';
EOF

    log_success "TypeScript CQRS interfaces generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# STACK-SPECIFIC CONFIGURATION GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

generate_stack_specific_configs() {
    local constitution_path="$1"
    
    if [ ! -f "$constitution_path" ]; then
        log_warning "No constitution found. Stack-specific files will be generated after constitution is configured."
        return 0
    fi
    
    log_info "Reading technology stack from constitution..."
    local constitution_content=$(cat "$constitution_path")
    
    # Detect backend stack from constitution
    local backend_stack="unknown"
    if echo "$constitution_content" | grep -qi "node\.js\|typescript\|javascript"; then
        backend_stack="nodejs"
    elif echo "$constitution_content" | grep -qi "\.net\|c#\|asp\.net"; then
        backend_stack="dotnet"
    elif echo "$constitution_content" | grep -qi "java\|spring\|jvm"; then
        backend_stack="java"
    elif echo "$constitution_content" | grep -qi "python\|django\|fastapi\|flask"; then
        backend_stack="python"
    elif echo "$constitution_content" | grep -qi "go\|golang"; then
        backend_stack="golang"
    fi
    
    log_info "Detected backend stack: $backend_stack"
    
    case "$backend_stack" in
        "nodejs")
            generate_nodejs_config_files
            ;;
        "dotnet")
            generate_dotnet_config_files
            ;;
        "java")
            generate_java_config_files
            ;;
        "python")
            generate_python_config_files
            ;;
        "golang")
            generate_go_config_files
            ;;
        *)
            log_warning "Unknown or unsupported stack. Please configure manually."
            generate_generic_config_files
            ;;
    esac
}

generate_nodejs_config_files() {
    log_info "Generating Node.js/TypeScript configuration files..."
    
    # package.json
    local framework_deps=""
    case "$BACKEND_FRAMEWORK" in
        "express")
            framework_deps='"express": "^4.18.2", "@types/express": "^4.17.21",'
            ;;
        "fastify")
            framework_deps='"fastify": "^4.25.0", "@fastify/cors": "^8.5.0",'
            ;;
        "nestjs")
            framework_deps='"@nestjs/core": "^10.3.0", "@nestjs/common": "^10.3.0", "@nestjs/platform-express": "^10.3.0",'
            ;;
    esac
    
    cat > "$OUTPUT_DIR/package.json" << EOF
{
  "name": "$(basename "$OUTPUT_DIR")",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "echo 'Configure your build system based on constitution'",
    "start": "echo 'Configure your start command based on constitution'",
    "test": "echo 'Configure your test framework based on constitution'"
  },
  "dependencies": {
    $framework_deps
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "note": "Dependencies will be added based on your technology stack configuration in constitution.md"
  }
}
EOF

    # tsconfig.json
    cat > "$OUTPUT_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@shared/*": ["src/shared/*"],
      "@modules/*": ["src/modules/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
EOF

    # .editorconfig for Node.js
    cat > "$OUTPUT_DIR/.editorconfig" << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{ts,js,json}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
EOF

    # .prettierrc
    cat > "$OUTPUT_DIR/.prettierrc" << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 100,
  "tabWidth": 2
}
EOF

    # eslint.config.js
    cat > "$OUTPUT_DIR/eslint.config.js" << 'EOF'
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  }
);
EOF

    # Copy Node.js specific Architecture Gates
    if [ -f "$BOLT_ROOT/src/calculator-api/.dependency-cruiser.cjs" ]; then
        cp "$BOLT_ROOT/src/calculator-api/.dependency-cruiser.cjs" "$OUTPUT_DIR/" 2>/dev/null || true
        log_success "dependency-cruiser config copied"
    fi
    if [ -f "$BOLT_ROOT/src/calculator-api/.spectral.yaml" ]; then
        cp "$BOLT_ROOT/src/calculator-api/.spectral.yaml" "$OUTPUT_DIR/" 2>/dev/null || true
        log_success "Spectral OpenAPI linting config copied"
    fi
    
    log_success "Node.js/TypeScript configuration generated"
}

generate_dotnet_config_files() {
    log_info "Generating .NET configuration files..."
    
    # Directory.Build.props for .NET
    cat > "$OUTPUT_DIR/Directory.Build.props" << 'EOF'
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <AnalysisLevel>latest</AnalysisLevel>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <RunAnalyzersDuringBuild>true</RunAnalyzersDuringBuild>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" Version="3.3.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
EOF

    log_success ".NET architecture analysis configuration generated"
}

generate_java_config_files() {
    log_info "Generating Java configuration files..."
    log_warning "Java configuration generation not fully implemented. Please configure manually."
}

generate_python_config_files() {
    log_info "Generating Python configuration files..."
    
    # pyproject.toml
    cat > "$OUTPUT_DIR/pyproject.toml" << EOF
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "$(basename "$OUTPUT_DIR")"
version = "0.1.0"
description = "Generated by Bolt Framework"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "mypy>=1.0.0", 
    "ruff>=0.1.0",
    "black>=23.0.0",
    "import-linter>=1.0.0"
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]

[tool.mypy]
python_version = "3.11"
strict = true

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.black]
line-length = 88
target-version = ['py311']
EOF

    log_success "Python architecture analysis configuration generated"
}

generate_go_config_files() {
    log_info "Generating Go configuration files..."
    
    # go.mod
    cat > "$OUTPUT_DIR/go.mod" << EOF
module $(basename "$OUTPUT_DIR")

go 1.21

require ()
EOF

    log_success "Go architecture analysis configuration generated"
}

generate_generic_config_files() {
    log_info "Generating generic configuration placeholder..."
    # The STACK-CONFIGURATION.md is already created above
}

# ═══════════════════════════════════════════════════════════════════════════════
# INFRASTRUCTURE STRUCTURE GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# INFRASTRUCTURE ONLY STRUCTURE (Landing Zone / Workload)
# ═══════════════════════════════════════════════════════════════════════════════

generate_infrastructure_only_structure() {
    log_info "Generating infrastructure-only structure ($IAC_TOOL - $INFRA_SCOPE)..."
    
    case "$INFRA_SCOPE" in
        "landing-zone"|"both")
            generate_landing_zone_structure
            ;;
    esac
    
    case "$INFRA_SCOPE" in
        "workload"|"both")
            generate_workload_infra_structure
            ;;
    esac
    
    # Common: CI/CD pipelines for infra
    generate_infra_pipelines
    
    # Common: Tests for infra
    generate_infra_tests
    
    # Docs
    mkdir -p "$OUTPUT_DIR/docs/architecture"
    mkdir -p "$OUTPUT_DIR/docs/runbooks"
    touch "$OUTPUT_DIR/docs/architecture/README.md"
}

generate_landing_zone_structure() {
    log_info "Generating Landing Zone structure..."
    
    case "$IAC_TOOL" in
        "bicep")
            # Platform
            mkdir -p "$OUTPUT_DIR/platform/management-groups/modules"
            touch "$OUTPUT_DIR/platform/management-groups/main.bicep"
            
            # Policies
            mkdir -p "$OUTPUT_DIR/platform/policies/initiatives"
            mkdir -p "$OUTPUT_DIR/platform/policies/definitions"
            mkdir -p "$OUTPUT_DIR/platform/policies/assignments"
            touch "$OUTPUT_DIR/platform/policies/initiatives/security.bicep"
            touch "$OUTPUT_DIR/platform/policies/initiatives/tagging.bicep"
            
            # Connectivity (Hub-Spoke)
            mkdir -p "$OUTPUT_DIR/platform/connectivity/hub-network"
            touch "$OUTPUT_DIR/platform/connectivity/hub-network/main.bicep"
            touch "$OUTPUT_DIR/platform/connectivity/hub-network/firewall.bicep"
            touch "$OUTPUT_DIR/platform/connectivity/hub-network/bastion.bicep"
            mkdir -p "$OUTPUT_DIR/platform/connectivity/dns"
            touch "$OUTPUT_DIR/platform/connectivity/dns/private-dns-zones.bicep"
            mkdir -p "$OUTPUT_DIR/platform/connectivity/vwan"  # If Virtual WAN
            
            # Identity
            mkdir -p "$OUTPUT_DIR/platform/identity"
            touch "$OUTPUT_DIR/platform/identity/main.bicep"
            touch "$OUTPUT_DIR/platform/identity/rbac-assignments.bicep"
            
            # Management
            mkdir -p "$OUTPUT_DIR/platform/management"
            touch "$OUTPUT_DIR/platform/management/log-analytics.bicep"
            touch "$OUTPUT_DIR/platform/management/automation.bicep"
            touch "$OUTPUT_DIR/platform/management/defender.bicep"
            
            # Landing Zone Templates
            mkdir -p "$OUTPUT_DIR/landing-zones/templates/corp-workload/parameters"
            touch "$OUTPUT_DIR/landing-zones/templates/corp-workload/main.bicep"
            mkdir -p "$OUTPUT_DIR/landing-zones/templates/online-workload/parameters"
            touch "$OUTPUT_DIR/landing-zones/templates/online-workload/main.bicep"
            mkdir -p "$OUTPUT_DIR/landing-zones/subscriptions"
            touch "$OUTPUT_DIR/landing-zones/subscriptions/README.md"
            
            # Shared modules
            mkdir -p "$OUTPUT_DIR/modules/networking"
            mkdir -p "$OUTPUT_DIR/modules/security"
            mkdir -p "$OUTPUT_DIR/modules/compute"
            mkdir -p "$OUTPUT_DIR/modules/data"
            ;;
            
        "terraform")
            # Platform
            mkdir -p "$OUTPUT_DIR/platform/management-groups"
            touch "$OUTPUT_DIR/platform/management-groups/main.tf"
            touch "$OUTPUT_DIR/platform/management-groups/variables.tf"
            
            # Policies
            mkdir -p "$OUTPUT_DIR/platform/policies"
            touch "$OUTPUT_DIR/platform/policies/main.tf"
            
            # Connectivity
            mkdir -p "$OUTPUT_DIR/platform/connectivity/hub-network"
            touch "$OUTPUT_DIR/platform/connectivity/hub-network/main.tf"
            mkdir -p "$OUTPUT_DIR/platform/connectivity/dns"
            
            # Identity
            mkdir -p "$OUTPUT_DIR/platform/identity"
            touch "$OUTPUT_DIR/platform/identity/main.tf"
            
            # Management
            mkdir -p "$OUTPUT_DIR/platform/management"
            touch "$OUTPUT_DIR/platform/management/main.tf"
            
            # Landing Zone Templates
            mkdir -p "$OUTPUT_DIR/landing-zones/templates/corp-workload"
            mkdir -p "$OUTPUT_DIR/landing-zones/templates/online-workload"
            mkdir -p "$OUTPUT_DIR/landing-zones/subscriptions"
            
            # Modules
            mkdir -p "$OUTPUT_DIR/modules"
            ;;
            
        "pulumi")
            mkdir -p "$OUTPUT_DIR/platform"
            mkdir -p "$OUTPUT_DIR/landing-zones"
            mkdir -p "$OUTPUT_DIR/modules"
            touch "$OUTPUT_DIR/Pulumi.yaml"
            ;;
    esac
}

generate_workload_infra_structure() {
    log_info "Generating Workload infrastructure structure..."
    
    case "$IAC_TOOL" in
        "bicep")
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/networking"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/compute"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/data"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/security"
            mkdir -p "$OUTPUT_DIR/infra/bicep/environments"
            
            touch "$OUTPUT_DIR/infra/bicep/modules/networking/vnet.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/networking/nsg.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/compute/aks.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/compute/container-apps.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/data/sql.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/data/cosmos.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/security/keyvault.bicep"
            touch "$OUTPUT_DIR/infra/bicep/modules/security/managed-identity.bicep"
            
            IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
            for env in "${ENVS[@]}"; do
                touch "$OUTPUT_DIR/infra/bicep/environments/${env}.bicepparam"
            done
            
            touch "$OUTPUT_DIR/infra/bicep/main.bicep"
            ;;
            
        "terraform")
            mkdir -p "$OUTPUT_DIR/infra/terraform/modules/networking"
            mkdir -p "$OUTPUT_DIR/infra/terraform/modules/compute"
            mkdir -p "$OUTPUT_DIR/infra/terraform/modules/data"
            mkdir -p "$OUTPUT_DIR/infra/terraform/modules/security"
            mkdir -p "$OUTPUT_DIR/infra/terraform/environments"
            
            IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
            for env in "${ENVS[@]}"; do
                touch "$OUTPUT_DIR/infra/terraform/environments/${env}.tfvars"
            done
            
            touch "$OUTPUT_DIR/infra/terraform/main.tf"
            touch "$OUTPUT_DIR/infra/terraform/variables.tf"
            touch "$OUTPUT_DIR/infra/terraform/outputs.tf"
            touch "$OUTPUT_DIR/infra/terraform/providers.tf"
            ;;
            
        "pulumi")
            mkdir -p "$OUTPUT_DIR/infra/pulumi"
            touch "$OUTPUT_DIR/infra/pulumi/Pulumi.yaml"
            ;;
    esac
    
    # Kubernetes manifests if needed
    mkdir -p "$OUTPUT_DIR/infra/k8s/helm"
    mkdir -p "$OUTPUT_DIR/infra/k8s/kustomize/base"
    IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
    for env in "${ENVS[@]}"; do
        mkdir -p "$OUTPUT_DIR/infra/k8s/kustomize/overlays/${env}"
    done
}

generate_infra_pipelines() {
    log_info "Generating infrastructure pipelines..."
    
    mkdir -p "$OUTPUT_DIR/pipelines"
    
    case "$CICD_PLATFORM" in
        "github-actions")
            mkdir -p "$OUTPUT_DIR/.github/workflows"
            if [ "$INFRA_SCOPE" = "landing-zone" ] || [ "$INFRA_SCOPE" = "both" ]; then
                touch "$OUTPUT_DIR/.github/workflows/platform-deploy.yml"
                touch "$OUTPUT_DIR/.github/workflows/landing-zone-deploy.yml"
            fi
            if [ "$INFRA_SCOPE" = "workload" ] || [ "$INFRA_SCOPE" = "both" ]; then
                touch "$OUTPUT_DIR/.github/workflows/infra-deploy.yml"
            fi
            ;;
        "azure-devops")
            if [ "$INFRA_SCOPE" = "landing-zone" ] || [ "$INFRA_SCOPE" = "both" ]; then
                touch "$OUTPUT_DIR/pipelines/platform-deploy.yml"
                touch "$OUTPUT_DIR/pipelines/landing-zone-deploy.yml"
            fi
            if [ "$INFRA_SCOPE" = "workload" ] || [ "$INFRA_SCOPE" = "both" ]; then
                touch "$OUTPUT_DIR/pipelines/infra-deploy.yml"
            fi
            ;;
    esac
}

generate_infra_tests() {
    log_info "Generating infrastructure tests..."
    
    mkdir -p "$OUTPUT_DIR/tests/bicep-lint"
    mkdir -p "$OUTPUT_DIR/tests/security"
    mkdir -p "$OUTPUT_DIR/tests/policy-compliance"
    mkdir -p "$OUTPUT_DIR/tests/post-deploy"
    
    touch "$OUTPUT_DIR/tests/README.md"
}

# ═══════════════════════════════════════════════════════════════════════════════
# WORKLOAD INFRASTRUCTURE STRUCTURE (for Full Stack)
# ═══════════════════════════════════════════════════════════════════════════════

generate_infrastructure_structure() {
    log_info "Generating infrastructure structure ($IAC_TOOL)..."
    
    case "$IAC_TOOL" in
        "bicep")
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/networking"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/compute"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/data"
            mkdir -p "$OUTPUT_DIR/infra/bicep/modules/security"
            mkdir -p "$OUTPUT_DIR/infra/bicep/environments"
            
            # Create environment files based on selection
            IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
            for env in "${ENVS[@]}"; do
                touch "$OUTPUT_DIR/infra/bicep/environments/${env}.bicepparam"
            done
            
            touch "$OUTPUT_DIR/infra/bicep/main.bicep"
            ;;
        "terraform")
            mkdir -p "$OUTPUT_DIR/infra/terraform/modules"
            mkdir -p "$OUTPUT_DIR/infra/terraform/environments"
            
            IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
            for env in "${ENVS[@]}"; do
                touch "$OUTPUT_DIR/infra/terraform/environments/${env}.tfvars"
            done
            
            touch "$OUTPUT_DIR/infra/terraform/main.tf"
            touch "$OUTPUT_DIR/infra/terraform/variables.tf"
            touch "$OUTPUT_DIR/infra/terraform/outputs.tf"
            ;;
        "pulumi")
            mkdir -p "$OUTPUT_DIR/infra/pulumi"
            touch "$OUTPUT_DIR/infra/pulumi/Pulumi.yaml"
            ;;
    esac
    
    # Kubernetes if AKS
    if [ "$ORCHESTRATION" = "aks" ]; then
        mkdir -p "$OUTPUT_DIR/infra/k8s/helm/charts"
        mkdir -p "$OUTPUT_DIR/infra/k8s/kustomize/base"
        
        IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
        for env in "${ENVS[@]}"; do
            mkdir -p "$OUTPUT_DIR/infra/k8s/kustomize/overlays/${env}"
        done
        
        mkdir -p "$OUTPUT_DIR/infra/k8s/keda"
    fi
    
    # Scripts
    mkdir -p "$OUTPUT_DIR/infra/scripts"
}

generate_frontend_placeholder() {
    log_info "Creating frontend placeholder for $FRONTEND_FRAMEWORK..."
    
    mkdir -p "$OUTPUT_DIR/frontend"
    
    cat > "$OUTPUT_DIR/frontend/README.md" << EOF
# Frontend - $FRONTEND_FRAMEWORK

> **Note**: This is a placeholder. Generate the actual frontend using:

## Vue.js
\`\`\`bash
cd frontend && npm create vue@latest .
\`\`\`

## React
\`\`\`bash
cd frontend && npm create vite@latest . -- --template react-ts
\`\`\`

## Angular
\`\`\`bash
cd frontend && npx @angular/cli new app --directory .
\`\`\`

## Blazor
\`\`\`bash
cd frontend && dotnet new blazorserver  # or blazorwasm
\`\`\`
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTITUTION PRE-FILL
# ═══════════════════════════════════════════════════════════════════════════════

prefill_constitution() {
    log_step "Pre-filling constitution with your configuration..."
    
    local constitution_file="$OUTPUT_DIR/memory/constitution.md"
    
    if [ -f "$constitution_file" ]; then
        # ─────────────────────────────────────────────────────────────────────────
        # PROJECT SCOPE
        # ─────────────────────────────────────────────────────────────────────────
        case "$PROJECT_SCOPE" in
            "infra-only")
                sed -i 's/- \[ \] \*\*🏗️ Infrastructure Only\*\*/- [x] **🏗️ Infrastructure Only**/' "$constitution_file"
                ;;
            "app-only")
                sed -i 's/- \[ \] \*\*💻 Application Development Only\*\*/- [x] **💻 Application Development Only**/' "$constitution_file"
                ;;
            "full-stack")
                sed -i 's/- \[ \] \*\*🚀 Full Stack (App + Infrastructure)\*\*/- [x] **🚀 Full Stack (App + Infrastructure)**/' "$constitution_file"
                ;;
        esac
        
        # Infrastructure scope
        if [ -n "$INFRA_SCOPE" ]; then
            case "$INFRA_SCOPE" in
                "landing-zone")
                    sed -i 's/- \[ \] \*\*Landing Zone\*\*/- [x] **Landing Zone**/' "$constitution_file"
                    ;;
                "workload")
                    sed -i 's/- \[ \] \*\*Workload Infrastructure\*\*/- [x] **Workload Infrastructure**/' "$constitution_file"
                    ;;
                "both")
                    sed -i 's/- \[ \] \*\*Both\*\* - Landing Zone + Workload/- [x] **Both** - Landing Zone + Workload/' "$constitution_file"
                    ;;
            esac
        fi
        
        # ─────────────────────────────────────────────────────────────────────────
        # APPLICATION CONFIGURATION (only for app-only or full-stack)
        # ─────────────────────────────────────────────────────────────────────────
        if [ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
            # Backend language selection
            if [ "$BACKEND_LANGUAGE" = "csharp" ]; then
                sed -i 's/- \[ \] \*\*C# \/ \.NET\*\*/- [x] **C# \/ .NET**/' "$constitution_file"
                
                # Version
                if [ "$BACKEND_VERSION" = "dotnet8" ]; then
                    sed -i 's/Version: \[ \] \.NET 8/Version: [x] .NET 8/' "$constitution_file"
                else
                    sed -i 's/Version: \[ \] \.NET 10/Version: [x] .NET 10/' "$constitution_file"
                fi
                
                # Framework
                case "$BACKEND_FRAMEWORK" in
                    "minimal-api") sed -i 's/API Style: \[ \] Minimal APIs/API Style: [x] Minimal APIs/' "$constitution_file" ;;
                    "controllers") sed -i 's/API Style: \[ \] Controllers/API Style: [x] Controllers/' "$constitution_file" ;;
                    "azure-functions") sed -i 's/API Style: \[ \] Azure Functions/API Style: [x] Azure Functions/' "$constitution_file" ;;
                esac
            elif [ "$BACKEND_LANGUAGE" = "nodejs" ]; then
                sed -i 's/- \[ \] \*\*Node\.js \/ TypeScript\*\*/- [x] **Node.js \/ TypeScript**/' "$constitution_file"
                
                # Version
                if [ "$BACKEND_VERSION" = "node20" ]; then
                    sed -i 's/Version: \[ \] Node\.js 20 LTS/Version: [x] Node.js 20 LTS/' "$constitution_file"
                else
                    sed -i 's/Version: \[ \] Node\.js 22/Version: [x] Node.js 22/' "$constitution_file"
                fi
                
                # Framework
                case "$BACKEND_FRAMEWORK" in
                    "express") sed -i 's/Framework: \[ \] Express/Framework: [x] Express/' "$constitution_file" ;;
                    "fastify") sed -i 's/Framework: \[ \] Fastify/Framework: [x] Fastify/' "$constitution_file" ;;
                    "nestjs") sed -i 's/Framework: \[ \] NestJS/Framework: [x] NestJS/' "$constitution_file" ;;
                esac
            fi
            
            # Architecture
            case "$ARCHITECTURE" in
                "modular-monolith") sed -i 's/- \[ \] \*\*Modular Monolith\*\*/- [x] **Modular Monolith**/' "$constitution_file" ;;
                "microservices") sed -i 's/- \[ \] \*\*Microservices\*\*/- [x] **Microservices**/' "$constitution_file" ;;
                "monolith") sed -i 's/- \[ \] \*\*Traditional Monolith\*\*/- [x] **Traditional Monolith**/' "$constitution_file" ;;
                "serverless") sed -i 's/- \[ \] \*\*Serverless\*\*/- [x] **Serverless**/' "$constitution_file" ;;
                "event-driven") sed -i 's/- \[ \] \*\*Event-Driven \/ CQRS+ES\*\*/- [x] **Event-Driven \/ CQRS+ES**/' "$constitution_file" ;;
            esac
            
            # CQRS
            if [ "$CQRS_ENABLED" = "true" ]; then
                sed -i 's/CQRS Enabled: \[ \] Yes/CQRS Enabled: [x] Yes/' "$constitution_file"
            else
                sed -i 's/CQRS Enabled: \[ \] No/CQRS Enabled: [x] No/' "$constitution_file"
            fi
            
            # Frontend
            case "$FRONTEND_FRAMEWORK" in
                "none") sed -i 's/- \[ \] \*\*None\*\* - API only/- [x] **None** - API only/' "$constitution_file" ;;
                "vue") sed -i 's/- \[ \] \*\*Vue\.js\*\*/- [x] **Vue.js**/' "$constitution_file" ;;
                "react") sed -i 's/- \[ \] \*\*React\*\*/- [x] **React**/' "$constitution_file" ;;
                "angular") sed -i 's/- \[ \] \*\*Angular\*\*/- [x] **Angular**/' "$constitution_file" ;;
                "blazor-server") sed -i 's/- \[ \] \*\*Blazor\*\* - Type: \[ \] Server/- [x] **Blazor** - Type: [x] Server/' "$constitution_file" ;;
                "blazor-wasm") sed -i 's/- \[ \] \*\*Blazor\*\* - Type: \[ \] WebAssembly/- [x] **Blazor** - Type: [x] WebAssembly/' "$constitution_file" ;;
            esac
            
            # Database
            case "$DATABASE" in
                "azure-sql") sed -i 's/- \[ \] \*\*Azure SQL Database\*\*/- [x] **Azure SQL Database**/' "$constitution_file" ;;
                "sql-server") sed -i 's/- \[ \] \*\*SQL Server\*\*/- [x] **SQL Server**/' "$constitution_file" ;;
                "postgresql") sed -i 's/- \[ \] \*\*PostgreSQL\*\*/- [x] **PostgreSQL**/' "$constitution_file" ;;
                "cosmos-db") sed -i 's/- \[ \] \*\*Azure Cosmos DB\*\*/- [x] **Azure Cosmos DB**/' "$constitution_file" ;;
                "mongodb") sed -i 's/- \[ \] \*\*MongoDB\*\*/- [x] **MongoDB**/' "$constitution_file" ;;
            esac
            
            # Docker
            if [ "$DOCKER_ENABLED" = "true" ]; then
                sed -i 's/- \[ \] \*\*Docker\*\* - Standard containers/- [x] **Docker** - Standard containers/' "$constitution_file"
            fi
            
            # Orchestration
            case "$ORCHESTRATION" in
                "aks") sed -i 's/- \[ \] \*\*Azure Kubernetes Service (AKS)\*\*/- [x] **Azure Kubernetes Service (AKS)**/' "$constitution_file" ;;
                "container-apps") sed -i 's/- \[ \] \*\*Azure Container Apps\*\*/- [x] **Azure Container Apps**/' "$constitution_file" ;;
                "app-service") sed -i 's/- \[ \] \*\*Azure App Service\*\*/- [x] **Azure App Service**/' "$constitution_file" ;;
            esac
        fi  # End of app-only or full-stack configuration
        
        # ─────────────────────────────────────────────────────────────────────────
        # COMMON CONFIGURATION (for all project types)
        # ─────────────────────────────────────────────────────────────────────────
        
        # IaC (for infra-only or full-stack)
        if [ "$PROJECT_SCOPE" = "infra-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
            case "$IAC_TOOL" in
                "bicep") sed -i 's/- \[ \] \*\*Bicep\*\*/- [x] **Bicep**/' "$constitution_file" ;;
                "terraform") sed -i 's/- \[ \] \*\*Terraform\*\*/- [x] **Terraform**/' "$constitution_file" ;;
                "pulumi") sed -i 's/- \[ \] \*\*Pulumi\*\*/- [x] **Pulumi**/' "$constitution_file" ;;
            esac
        fi
        
        # CI/CD
        case "$CICD_PLATFORM" in
            "github-actions") sed -i 's/- \[ \] \*\*GitHub Actions\*\*/- [x] **GitHub Actions**/' "$constitution_file" ;;
            "azure-devops") sed -i 's/- \[ \] \*\*Azure DevOps Pipelines\*\*/- [x] **Azure DevOps Pipelines**/' "$constitution_file" ;;
        esac
        
        # Observability
        case "$OBSERVABILITY" in
            "azure-native") sed -i 's/- \[ \] \*\*Azure-Native\*\*/- [x] **Azure-Native**/' "$constitution_file" ;;
            "otel-azure") sed -i 's/- \[ \] \*\*OpenTelemetry → Azure\*\*/- [x] **OpenTelemetry → Azure**/' "$constitution_file" ;;
            "otel-grafana") sed -i 's/- \[ \] \*\*OpenTelemetry → Grafana Stack\*\*/- [x] **OpenTelemetry → Grafana Stack**/' "$constitution_file" ;;
        esac
        
        # Environments - mark selected ones
        IFS=',' read -ra ENVS <<< "$ENVIRONMENTS"
        for env in "${ENVS[@]}"; do
            sed -i "s/| \*\*${env}\*\* |.*| \[ \] Yes/| **${env}** | ... | [x] Yes/" "$constitution_file"
        done
        
        # ─────────────────────────────────────────────────────────────────────────
        # MIGRATION CONTEXT (Article XVII) - Based on script parameter
        # ─────────────────────────────────────────────────────────────────────────
        if [ "$PROJECT_TYPE" = "green" ]; then
            sed -i 's/- \[ \] \*\*Greenfield\*\* - New project, no legacy/- [x] **Greenfield** - New project, no legacy/' "$constitution_file"
        elif [ "$PROJECT_TYPE" = "brown" ]; then
            sed -i 's/- \[ \] \*\*Brownfield\*\* - Existing codebase enhancement/- [x] **Brownfield** - Existing codebase enhancement/' "$constitution_file"
        fi
        
        log_success "Constitution pre-filled with your configuration"
    fi
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Print usage
usage() {
    echo "Usage: $0 <output-directory> <project-type> [source-directory] [--auto <profile>]"
    echo ""
    echo "Parameters:"
    echo "  output-directory  : Where to create the project structure"
    echo "  project-type      : 'brown' for Brownfield, 'green' for Greenfield"
    echo "  source-directory  : (Required for brown) Directory with existing code/docs"
    echo ""
    echo "Options:"
    echo "  --auto <profile>  : Skip wizard with predefined configuration"
    echo ""
    echo "Auto Profiles (for --auto):"
    echo "  app-dotnet        : App-only, C#/.NET 10, Minimal APIs, Modular Monolith"
    echo "  app-node          : App-only, Node.js 22, NestJS, Modular Monolith"
    echo "  infra-landing     : Infrastructure-only, Landing Zone, Bicep"
    echo "  infra-workload    : Infrastructure-only, Workload, Bicep"
    echo "  fullstack-dotnet  : Full Stack, C#/.NET 10, Bicep"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects/my-new-app green"
    echo "  $0 ~/projects/my-new-app green --auto app-dotnet"
    echo "  $0 ~/projects/legacy-migration brown ~/legacy-code"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Validate arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    log_error "Missing required arguments"
    usage
    exit 1
fi

OUTPUT_DIR="$1"
PROJECT_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:]')
SOURCE_DIR=""

# Parse remaining arguments
shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)
            AUTO_MODE=true
            AUTO_PROFILE="$2"
            shift 2
            ;;
        *)
            # If not an option, it's the source directory (for brownfield)
            if [ -z "$SOURCE_DIR" ]; then
                SOURCE_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Validate project type
if [ "$PROJECT_TYPE" != "brown" ] && [ "$PROJECT_TYPE" != "green" ]; then
    log_error "Invalid project type: $PROJECT_TYPE"
    log_error "Must be 'brown' (Brownfield) or 'green' (Greenfield)"
    exit 1
fi

# Validate source directory for brownfield
if [ "$PROJECT_TYPE" = "brown" ] && [ -z "$SOURCE_DIR" ]; then
    log_error "Source directory is required for Brownfield projects"
    usage
    exit 1
fi

if [ "$PROJECT_TYPE" = "brown" ] && [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# AUTO-CONFIGURATION PROFILES
# ═══════════════════════════════════════════════════════════════════════════════
apply_auto_profile() {
    local profile="$1"
    
    case "$profile" in
        "app-dotnet")
            PROJECT_SCOPE="app-only"
            BACKEND_LANGUAGE="csharp"
            BACKEND_VERSION="dotnet10"
            BACKEND_FRAMEWORK="minimal-api"
            ARCHITECTURE="modular-monolith"
            CQRS_ENABLED="false"
            FRONTEND_FRAMEWORK="none"
            DATABASE="azure-sql"
            DOCKER_ENABLED="true"
            ORCHESTRATION="container-apps"
            CICD_PLATFORM="github-actions"
            ENVIRONMENTS="dev,uat,pre,prod"
            OBSERVABILITY="azure-native"
            ;;
        "app-node")
            PROJECT_SCOPE="app-only"
            BACKEND_LANGUAGE="nodejs"
            BACKEND_VERSION="node22"
            BACKEND_FRAMEWORK="nestjs"
            ARCHITECTURE="modular-monolith"
            CQRS_ENABLED="false"
            FRONTEND_FRAMEWORK="none"
            DATABASE="azure-sql"
            DOCKER_ENABLED="true"
            ORCHESTRATION="container-apps"
            CICD_PLATFORM="github-actions"
            ENVIRONMENTS="dev,uat,pre,prod"
            OBSERVABILITY="azure-native"
            ;;
        "infra-landing")
            PROJECT_SCOPE="infra-only"
            INFRA_SCOPE="landing-zone"
            IAC_TOOL="bicep"
            CICD_PLATFORM="github-actions"
            ENVIRONMENTS="dev,uat,pre,prod"
            OBSERVABILITY="azure-native"
            ;;
        "infra-workload")
            PROJECT_SCOPE="infra-only"
            INFRA_SCOPE="workload"
            IAC_TOOL="bicep"
            CICD_PLATFORM="github-actions"
            ENVIRONMENTS="dev,uat,pre,prod"
            OBSERVABILITY="azure-native"
            ;;
        "fullstack-dotnet")
            PROJECT_SCOPE="full-stack"
            INFRA_SCOPE="workload"
            BACKEND_LANGUAGE="csharp"
            BACKEND_VERSION="dotnet10"
            BACKEND_FRAMEWORK="minimal-api"
            ARCHITECTURE="modular-monolith"
            CQRS_ENABLED="false"
            FRONTEND_FRAMEWORK="vue"
            DATABASE="azure-sql"
            DOCKER_ENABLED="true"
            ORCHESTRATION="container-apps"
            IAC_TOOL="bicep"
            CICD_PLATFORM="github-actions"
            ENVIRONMENTS="dev,uat,pre,prod"
            OBSERVABILITY="azure-native"
            ;;
        *)
            log_error "Unknown auto profile: $profile"
            log_error "Valid profiles: app-dotnet, app-node, infra-landing, infra-workload, fullstack-dotnet"
            exit 1
            ;;
    esac
    
    log_info "  Auto Profile: $profile"
}

# Print banner
print_banner

# Start initialization
log_info "Initializing Bolt Framework project..."
log_info "  Output Directory: $OUTPUT_DIR"
log_info "  Project Type: $PROJECT_TYPE ($([ "$PROJECT_TYPE" = "brown" ] && echo "Brownfield - Migration" || echo "Greenfield - New Project"))"
[ -n "$SOURCE_DIR" ] && log_info "  Source Directory: $SOURCE_DIR"
[ "$AUTO_MODE" = true ] && log_info "  Auto Mode: enabled"

# ═══════════════════════════════════════════════════════════════════════════════
# RUN CONFIGURATION WIZARD (for Greenfield projects)
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$PROJECT_TYPE" = "green" ]; then
    if [ "$AUTO_MODE" = true ]; then
        apply_auto_profile "$AUTO_PROFILE"
    else
        run_configuration_wizard
    fi
fi

# Create output directory
log_step "Creating output directory structure..."
mkdir -p "$OUTPUT_DIR"

# Create main folder structure
mkdir -p "$OUTPUT_DIR/.github/copilot/agents"
mkdir -p "$OUTPUT_DIR/.github/commands"
mkdir -p "$OUTPUT_DIR/.github/prompts"
mkdir -p "$OUTPUT_DIR/.github/workflows"
mkdir -p "$OUTPUT_DIR/memory"
# Specs structure: specs/XXX-feature-name/{contracts,requirements,tests,planning}
mkdir -p "$OUTPUT_DIR/specs/.template/contracts"
mkdir -p "$OUTPUT_DIR/specs/.template/requirements"
mkdir -p "$OUTPUT_DIR/specs/.template/tests"
mkdir -p "$OUTPUT_DIR/specs/.template/planning"
mkdir -p "$OUTPUT_DIR/docs/adr"
mkdir -p "$OUTPUT_DIR/docs/architecture"
mkdir -p "$OUTPUT_DIR/scripts/bash"
mkdir -p "$OUTPUT_DIR/scripts/powershell"

# Brownfield-specific directories
if [ "$PROJECT_TYPE" = "brown" ]; then
    mkdir -p "$OUTPUT_DIR/legacy/analysis"
    mkdir -p "$OUTPUT_DIR/legacy/source"
    mkdir -p "$OUTPUT_DIR/legacy/documentation"
    mkdir -p "$OUTPUT_DIR/migration/plan"
    mkdir -p "$OUTPUT_DIR/migration/mappings"
fi

# Greenfield-specific directories - DYNAMIC based on configuration
if [ "$PROJECT_TYPE" = "green" ]; then
    log_step "Creating src structure based on configuration..."
    generate_project_structure
fi

# Create specs template files
log_step "Creating specs template files..."

# Template README for specs
cat > "$OUTPUT_DIR/specs/README.md" << 'SPECS_README'
# Feature Specifications

This directory contains all feature specifications organized by feature.

## Structure

```
specs/
├── .template/              # Template for new features (copy this)
│   ├── contracts/          # OpenAPI, JSON schemas, API contracts
│   ├── requirements/       # User stories, acceptance criteria
│   ├── tests/              # Gherkin feature files (.feature)
│   └── planning/           # Implementation planning artifacts
└── XXX-feature-name/       # Actual feature specifications
    ├── contracts/
    │   └── openapi.yaml
    ├── requirements/
    │   └── requirements.md
    ├── tests/
    │   └── feature.feature
    └── planning/
        ├── plan.md         # Implementation plan
        └── tasks.md        # Bolt task breakdown
```

## Creating a New Feature Spec

1. Copy the `.template` folder:
   ```bash
   cp -r specs/.template specs/001-my-feature-name
   ```

2. Update the files in your new feature folder:
   - `contracts/openapi.yaml` - Define your API contract
   - `requirements/requirements.md` - Document user stories and acceptance criteria
   - `tests/*.feature` - Write Gherkin scenarios
   - `planning/plan.md` - Create implementation plan
   - `planning/tasks.md` - Break down into Bolt tasks

## Naming Convention

Use the pattern: `XXX-feature-name`
- `XXX` = Sequential number (001, 002, 003...)
- `feature-name` = Kebab-case descriptive name

Examples:
- `001-core-calculator-engine`
- `002-user-authentication`
- `003-payment-processing`
SPECS_README

# Template OpenAPI contract
cat > "$OUTPUT_DIR/specs/.template/contracts/openapi.yaml" << 'OPENAPI_TEMPLATE'
openapi: 3.0.3
info:
  title: Feature API
  description: |
    API contract for this feature.
    
    Replace this description with your feature's API documentation.
  version: 0.1.0
  contact:
    name: Development Team

servers:
  - url: http://localhost:3000
    description: Local development

paths:
  /api/v1/example:
    get:
      summary: Example endpoint
      description: Replace with your endpoint description
      operationId: getExample
      tags:
        - Example
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ExampleResponse'
        '400':
          description: Bad request
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'

components:
  schemas:
    ExampleResponse:
      type: object
      required:
        - success
        - data
      properties:
        success:
          type: boolean
          example: true
        data:
          type: object
          description: Response data
    
    ErrorResponse:
      type: object
      required:
        - success
        - error
      properties:
        success:
          type: boolean
          example: false
        error:
          type: object
          properties:
            code:
              type: string
              example: VALIDATION_ERROR
            message:
              type: string
              example: Invalid input provided
OPENAPI_TEMPLATE

# Template requirements
cat > "$OUTPUT_DIR/specs/.template/requirements/requirements.md" << 'REQUIREMENTS_TEMPLATE'
# Feature Requirements: [Feature Name]

> Replace [Feature Name] with your actual feature name

## Overview

Brief description of what this feature does and why it's needed.

## User Stories

### US-001: [Story Title]
**As a** [type of user]  
**I want** [goal/desire]  
**So that** [benefit/value]

#### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### US-002: [Story Title]
**As a** [type of user]  
**I want** [goal/desire]  
**So that** [benefit/value]

#### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Non-Functional Requirements

### Performance
- Response time: < 200ms for 95th percentile
- Throughput: Support 1000 requests/second

### Security
- All endpoints require authentication
- Input validation on all parameters

### Scalability
- Stateless design for horizontal scaling

## API Contract

See `contracts/openapi.yaml` for the full API specification.

## Test Scenarios

See `tests/*.feature` for Gherkin test scenarios.

## Dependencies

List any dependencies on other features or external systems:
- Dependency 1
- Dependency 2

## Open Questions

- [ ] Question 1 that needs clarification
- [ ] Question 2 that needs decision
REQUIREMENTS_TEMPLATE

# Template Gherkin feature file
cat > "$OUTPUT_DIR/specs/.template/tests/feature.feature" << 'GHERKIN_TEMPLATE'
@feature-name
Feature: [Feature Name]
  As a [type of user]
  I want [goal/desire]
  So that [benefit/value]

  Background:
    Given the system is initialized
    And I am an authenticated user

  # ════════════════════════════════════════════════════════════════════════════
  # Happy Path Scenarios
  # ════════════════════════════════════════════════════════════════════════════

  @happy-path
  Scenario: Successfully perform the main action
    Given I have valid input data
    When I perform the action
    Then the operation should succeed
    And I should receive a valid response

  @happy-path
  Scenario Outline: Perform action with different inputs
    Given I have value "<input>"
    When I perform the action
    Then the result should be "<expected>"

    Examples:
      | input  | expected |
      | value1 | result1  |
      | value2 | result2  |
      | value3 | result3  |

  # ════════════════════════════════════════════════════════════════════════════
  # Error Scenarios
  # ════════════════════════════════════════════════════════════════════════════

  @error-handling
  Scenario: Handle invalid input
    Given I have invalid input data
    When I attempt to perform the action
    Then the operation should fail
    And I should receive an error message

  @error-handling
  Scenario: Handle missing required fields
    Given I am missing required fields
    When I attempt to perform the action
    Then I should receive a validation error

  # ════════════════════════════════════════════════════════════════════════════
  # Edge Cases
  # ════════════════════════════════════════════════════════════════════════════

  @edge-case
  Scenario: Handle boundary values
    Given I have a boundary value
    When I perform the action
    Then the system should handle it correctly
GHERKIN_TEMPLATE

# Template plan.md for planning
cat > "$OUTPUT_DIR/specs/.template/planning/plan.md" << 'PLAN_TEMPLATE'
# Implementation Plan: [Feature Name]

> Replace [Feature Name] with your actual feature name

## 📋 Overview

Brief description of the implementation approach.

## 🎯 Goals

- [ ] Goal 1
- [ ] Goal 2
- [ ] Goal 3

## 🏗️ Architecture Approach

### Domain Layer
- Entities to create/modify
- Value Objects needed
- Domain Events

### Application Layer
- Use Cases to implement
- DTOs required
- Port interfaces

### Infrastructure Layer
- Repository implementations
- External service adapters
- Messaging handlers

### Presentation Layer
- API endpoints
- Request/Response models

## 📦 Dependencies

### Internal Dependencies
- Feature/module dependencies within the project

### External Dependencies
- Libraries, packages, or services required

## ⚠️ Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High/Medium/Low | Mitigation strategy |

## 📅 Milestones

1. **Milestone 1**: Description - Target: [date]
2. **Milestone 2**: Description - Target: [date]

## 🔗 Related Documents

- Requirements: `../requirements/requirements.md`
- API Contract: `../contracts/openapi.yaml`
- Test Scenarios: `../tests/*.feature`
- Tasks: `./tasks.md`
PLAN_TEMPLATE

# Template tasks.md for Bolt breakdown
cat > "$OUTPUT_DIR/specs/.template/planning/tasks.md" << 'TASKS_TEMPLATE'
# Bolt Tasks: [Feature Name]

> Replace [Feature Name] with your actual feature name
> Each Bolt is a micro-iteration (15-30 min) with clear deliverables

## 📊 Progress Tracker

| Bolt | Status | Description |
|------|--------|-------------|
| 1 | ⬜ Pending | Domain entities and value objects |
| 2 | ⬜ Pending | Domain services and events |
| 3 | ⬜ Pending | Application use cases |
| 4 | ⬜ Pending | Infrastructure adapters |
| 5 | ⬜ Pending | API endpoints |
| 6 | ⬜ Pending | Integration and E2E tests |

Status: ⬜ Pending | 🔄 In Progress | ✅ Complete | ❌ Blocked

---

## ⚡ Bolt 1: Domain Entities and Value Objects

**Objective**: Create core domain model

**Deliverables**:
- [ ] Entity: `EntityName`
- [ ] Value Object: `ValueObjectName`
- [ ] Unit tests for domain objects

**Acceptance Criteria**:
- All domain invariants enforced
- 100% test coverage on domain layer

---

## ⚡ Bolt 2: Domain Services and Events

**Objective**: Implement domain logic

**Deliverables**:
- [ ] Domain Service: `ServiceName`
- [ ] Domain Event: `EventName`
- [ ] Unit tests

**Acceptance Criteria**:
- Business rules correctly implemented
- Events properly raised

---

## ⚡ Bolt 3: Application Use Cases

**Objective**: Implement application layer

**Deliverables**:
- [ ] Use Case: `UseCaseName`
- [ ] DTOs: Request/Response
- [ ] Port interfaces
- [ ] Unit tests with mocks

**Acceptance Criteria**:
- Use cases orchestrate domain correctly
- Proper error handling

---

## ⚡ Bolt 4: Infrastructure Adapters

**Objective**: Implement infrastructure layer

**Deliverables**:
- [ ] Repository implementation
- [ ] External service adapters
- [ ] Integration tests

**Acceptance Criteria**:
- Adapters implement ports correctly
- Integration tests pass

---

## ⚡ Bolt 5: API Endpoints

**Objective**: Implement presentation layer

**Deliverables**:
- [ ] API Controller/Handler
- [ ] Request validation
- [ ] Response mapping
- [ ] API tests

**Acceptance Criteria**:
- Endpoints match OpenAPI contract
- Proper HTTP status codes

---

## ⚡ Bolt 6: Integration and E2E Tests

**Objective**: Validate complete feature

**Deliverables**:
- [ ] Integration test suite
- [ ] E2E test scenarios
- [ ] Performance validation

**Acceptance Criteria**:
- All Gherkin scenarios pass
- Performance within SLAs

---

## 📝 Notes

Add any implementation notes, decisions, or learnings here.
TASKS_TEMPLATE

log_success "Specs template files created"

log_success "Directory structure created"

# Copy Bolt Framework assets
log_step "Copying Bolt Framework assets..."

# Copy memory constitution template
if [ -f "$BOLT_ROOT/memory/constitution.md" ]; then
    cp "$BOLT_ROOT/memory/constitution.md" "$OUTPUT_DIR/memory/constitution.md"
    log_success "Constitution template copied"
    
    # Pre-fill constitution with wizard selections
    prefill_constitution
fi

# Copy .github/copilot/agents (AI Agents)
if [ -d "$BOLT_ROOT/.github/copilot/agents" ]; then
    cp -r "$BOLT_ROOT/.github/copilot/agents/"* "$OUTPUT_DIR/.github/copilot/agents/" 2>/dev/null || true
    log_success "AI Agents copied (.github/copilot/agents/)"
fi

# Copy .github/commands (Slash Commands)
if [ -d "$BOLT_ROOT/.github/commands" ]; then
    cp -r "$BOLT_ROOT/.github/commands/"* "$OUTPUT_DIR/.github/commands/" 2>/dev/null || true
    log_success "Slash Commands copied (.github/commands/)"
fi

# Copy .github/prompts (Context Prompts)
if [ -d "$BOLT_ROOT/.github/prompts" ]; then
    cp -r "$BOLT_ROOT/.github/prompts/"* "$OUTPUT_DIR/.github/prompts/" 2>/dev/null || true
    log_success "Context Prompts copied (.github/prompts/)"
fi

# Copy .github/workflows (CI/CD Pipelines)
if [ -d "$BOLT_ROOT/.github/workflows" ]; then
    cp -r "$BOLT_ROOT/.github/workflows/"* "$OUTPUT_DIR/.github/workflows/" 2>/dev/null || true
    log_success "CI/CD Workflows copied (.github/workflows/)"
fi

# Copy scripts (excluding init scripts - they are only needed in the template repo)
if [ -d "$BOLT_ROOT/scripts/bash" ]; then
    for script in "$BOLT_ROOT/scripts/bash/"*.sh; do
        script_name=$(basename "$script")
        if [ "$script_name" != "init.sh" ]; then
            cp "$script" "$OUTPUT_DIR/scripts/bash/" 2>/dev/null || true
        fi
    done
fi
if [ -d "$BOLT_ROOT/scripts/powershell" ]; then
    for script in "$BOLT_ROOT/scripts/powershell/"*.ps1; do
        script_name=$(basename "$script")
        if [ "$script_name" != "Init.ps1" ]; then
            cp "$script" "$OUTPUT_DIR/scripts/powershell/" 2>/dev/null || true
        fi
    done
fi
log_success "Scripts copied (init scripts excluded)"

# Architecture Quality Gates will be generated based on constitution stack
log_step "Architecture Quality Gates will be configured based on your technology stack..."
mkdir -p "$OUTPUT_DIR/reports/architecture"

# Create placeholder for stack-specific configuration
cat > "$OUTPUT_DIR/STACK-CONFIGURATION.md" << 'EOF'
# Technology Stack Configuration

Please configure based on your chosen technology stack.
After configuring constitution.md, re-run initialization to generate stack-specific files.

## Supported Stacks:
- Node.js/TypeScript
- .NET/C#  
- Java/Spring
- Python
- Go

## Next Steps:
1. Edit memory/constitution.md
2. Re-run initialization to generate stack-specific files

## Architecture Quality Gates by Stack:
- **Node.js/TypeScript**: dependency-cruiser, madge, spectral
- **.NET**: Microsoft.CodeAnalysis.NetAnalyzers, ArchUnitNET
- **Java**: ArchUnit, SpotBugs, PMD
- **Python**: import-linter, mypy, ruff
- **Go**: go vet, golangci-lint, govulncheck
EOF

# For Brownfield: Copy source files
if [ "$PROJECT_TYPE" = "brown" ]; then
    log_step "Copying legacy source files for analysis..."
    cp -r "$SOURCE_DIR/"* "$OUTPUT_DIR/legacy/source/" 2>/dev/null || true
    log_success "Legacy source copied to legacy/source/"
fi

# Create the main README.md
log_step "Creating project README..."
PROJECT_NAME=$(basename "$OUTPUT_DIR")
CURRENT_DATE=$(date +%Y-%m-%d)

if [ "$PROJECT_TYPE" = "green" ]; then
    cat > "$OUTPUT_DIR/README.md" << EOF
# $PROJECT_NAME

> 🌅 Project initialized with **Bolt Framework + AI-DLC** methodology
> 
> **Type**: 🌱 Greenfield (New Project)  
> **Created**: $CURRENT_DATE

---

## 🚀 Quick Start Guide

Follow these steps to set up your project with Bolt Framework:

### Step 1: Define Your Technology Stack 🔧

First, you need to configure your **Memory Constitution** - the single source of truth for your project.

\`\`\`bash
# Open the constitution template
code memory/constitution.md
\`\`\`

**Or use the Bolt Framework agent in GitHub Copilot Chat:**

\`\`\`
@Bolt Framework Constitution
\`\`\`

The constitution defines:
- ✅ Frontend/Backend technology stack
- ✅ Architecture principles
- ✅ Code standards and conventions
- ✅ Quality gates and testing requirements
- ✅ Security policies
- ✅ Infrastructure configuration

### Step 2: Create Your First Feature 📋

\`\`\`
@Bolt Framework Feature
\`\`\`

### Step 3: Plan the Implementation 📝

\`\`\`
@Bolt Framework Plan
\`\`\`

### Step 4: Generate Tasks (Bolts) ⚡

\`\`\`
@Bolt Framework Tasks
\`\`\`

### Step 5: Start Implementation 🔨

\`\`\`
@Bolt Framework Implement
\`\`\`

### Step 6: Security Analysis 🔒

Run comprehensive security analysis with OWASP compliance:

\`\`\`
@Bolt Framework Security --analyze --all --compliance owasp
\`\`\`

Or use the security analysis script directly:

\`\`\`bash
./scripts/bash/security-analysis.sh --all --severity medium
\`\`\`

---

## 📁 Project Structure

\`\`\`
$PROJECT_NAME/
├── .github/
│   ├── copilot/agents/   # AI Agent configurations
│   ├── commands/         # Slash Commands (/bolt.*)
│   ├── prompts/          # Context prompts
│   └── workflows/        # CI/CD pipelines
├── memory/
│   └── constitution.md   # 📜 PROJECT CONSTITUTION (Start Here!)
├── specs/                # Feature specifications
│   └── XXX-feature-name/ # Each feature has its own folder
│       ├── contracts/    # OpenAPI, JSON schemas, API contracts
│       ├── requirements/ # User stories, acceptance criteria
│       ├── tests/        # Gherkin feature files (.feature)
│       └── planning/     # Implementation plan and tasks
├── docs/
│   ├── adr/              # Architecture Decision Records
│   └── architecture/     # Architecture documentation
├── src/
│   ├── domain/           # Domain layer (DDD)
│   ├── application/      # Application layer (Use Cases)
│   ├── infrastructure/   # Infrastructure layer (Adapters)
│   └── presentation/     # Presentation layer (API/UI)
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── scripts/              # Automation scripts
\`\`\`

---

## 🌅 Bolt Framework Workflow

\`\`\`
┌─────────────────────────────────────────────────────────────────────┐
│                    🌅 Bolt Framework WORKFLOW                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ① CONSTITUTION ──→ Define project DNA (memory/constitution.md)   │
│           │                                                         │
│           ▼                                                         │
│   ② FEATURE      ──→ Specify what to build                         │
│           │                                                         │
│           ▼                                                         │
│   ③ PLAN         ──→ Design how to build it                        │
│           │                                                         │
│           ▼                                                         │
│   ④ TASKS        ──→ Break into Bolts (micro-iterations)           │
│           │                                                         │
│           ▼                                                         │
│   ⑤ IMPLEMENT    ──→ Execute with AI assistance                    │
│           │                                                         │
│           ▼                                                         │
│   ⑥ VALIDATE     ──→ Test and review                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
\`\`\`

---

## 📜 Constitution Quick Reference

The \`memory/constitution.md\` file contains:

| Article | Content |
|---------|---------|
| **Article I** | Technology Stack (Frontend, Backend, Data, Infrastructure) |
| **Article II** | Architecture Principles |
| **Article III** | Code Standards (Naming, File Organization, Documentation) |
| **Article IV** | Quality Gates (Testing, Static Analysis, Performance) |
| **Article V** | Security Policies |
| **Article VI** | Infrastructure Policies |
| **Article VII** | Governance |
| **Article VIII** | AI Agent Compliance |

**👉 Action Required:** Edit \`memory/constitution.md\` to fill in the \`[PLACEHOLDER]\` values with your project's specific technology choices.

---

## 🤖 Available Bolt Framework Commands

| Command | Purpose | Phase |
|---------|---------|-------|
| \`/bolt.constitution\` | Define project governance & tech stack | Foundation |
| \`/bolt.feature [name]\` | Create new feature specification | Discovery |
| \`/bolt.specify\` | Define detailed requirements | Discovery |
| \`/bolt.clarify\` | Resolve ambiguous requirements | Discovery |
| \`/bolt.usecase\` | Generate use cases | Discovery |
| \`/bolt.gherkin\` | Generate BDD scenarios | Discovery |
| \`/bolt.plan\` | Create implementation plan | Design |
| \`/bolt.adr [title]\` | Create Architecture Decision Record | Design |
| \`/bolt.tasks\` | Generate Bolt task lists | Construction |
| \`/bolt.implement\` | Execute implementation | Construction |
| \`/bolt.test\` | Generate test suites | Construction |
| \`/bolt.analyze\` | Validate consistency | Validation |
| \`/bolt.review\` | Perform code review | Validation |

---

## 📖 Next Steps

1. **📜 Fill in the Constitution** → Edit \`memory/constitution.md\`
2. **🎯 Define First Feature** → \`@Bolt Framework Feature\`
3. **📝 Plan Implementation** → \`@Bolt Framework Plan\`
4. **⚡ Start Coding** → \`@Bolt Framework Implement\`

---

*Generated by Bolt Framework Init Script v1.0.0*
EOF
else
    # Brownfield README
    cat > "$OUTPUT_DIR/README.md" << EOF
# $PROJECT_NAME

> 🌅 Project initialized with **Bolt Framework + AI-DLC** methodology
> 
> **Type**: 🏗️ Brownfield (Migration Project)  
> **Created**: $CURRENT_DATE  
> **Source**: \`$SOURCE_DIR\`

---

## 🚀 Brownfield Migration Quick Start Guide

This project has been set up to migrate existing code using the Bolt Framework methodology.

### Step 1: Analyze Legacy Code 🔍

Your source code has been copied to:
\`\`\`
legacy/source/
\`\`\`

First, analyze the existing codebase to understand:
- Current technology stack
- Code patterns and architecture
- Dependencies and integrations
- Business logic and rules

### Step 2: Define Your TARGET Technology Stack 🔧

Configure your **Memory Constitution** with the TARGET technology choices:

\`\`\`bash
code memory/constitution.md
\`\`\`

**Or use the Bolt Framework command:**

\`\`\`
/bolt.constitution
\`\`\`

**Important for Brownfield:**
- Document the CURRENT stack in the comments
- Define the TARGET stack in the placeholders
- Note any migration constraints

### Step 3: Create Migration Mapping 🗺️

Document the mapping between legacy and new architecture:

\`\`\`bash
code migration/mappings/technology-mapping.md
\`\`\`

### Step 4: Define Migration Features 📋

Create features for each migration chunk:

\`\`\`
/bolt.feature migrate-[component-name]
\`\`\`

### Step 5: Plan Migration Phases 📝

\`\`\`
/bolt.plan
\`\`\`

---

## 📁 Project Structure

\`\`\`
$PROJECT_NAME/
├── .github/
│   ├── copilot/agents/   # AI Agent configurations
│   ├── commands/         # Slash Commands (/bolt.*)
│   └── prompts/          # Context prompts
├── memory/
│   └── constitution.md   # 📜 TARGET CONSTITUTION (Define Target Stack!)
├── legacy/
│   ├── source/           # 📂 LEGACY SOURCE CODE (Read-Only Reference)
│   ├── analysis/         # Legacy code analysis documents
│   └── documentation/    # Existing documentation
├── migration/
│   ├── plan/             # Migration plan documents
│   └── mappings/         # Legacy → New mappings
├── specs/                # New feature specifications
│   └── XXX-feature-name/ # Each feature has its own folder
│       ├── contracts/    # OpenAPI, JSON schemas, API contracts
│       ├── requirements/ # User stories, acceptance criteria
│       ├── tests/        # Gherkin feature files (.feature)
│       └── planning/     # Implementation plan and tasks
├── docs/
│   ├── adr/              # Architecture Decision Records
│   └── architecture/     # New architecture documentation
└── scripts/              # Automation scripts
\`\`\`

---

## 🏗️ Brownfield Migration Workflow

\`\`\`
┌─────────────────────────────────────────────────────────────────────┐
│                🏗️ BROWNFIELD MIGRATION WORKFLOW                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ① ANALYZE      ──→ Understand legacy code (legacy/source/)       │
│           │                                                         │
│           ▼                                                         │
│   ② CONSTITUTION ──→ Define TARGET stack (memory/constitution.md)  │
│           │                                                         │
│           ▼                                                         │
│   ③ MAP          ──→ Create legacy → new mappings                  │
│           │                                                         │
│           ▼                                                         │
│   ④ FEATURE      ──→ Define migration features                     │
│           │                                                         │
│           ▼                                                         │
│   ⑤ PLAN         ──→ Create migration plan                         │
│           │                                                         │
│           ▼                                                         │
│   ⑥ MIGRATE      ──→ Execute migration in Bolts                    │
│           │                                                         │
│           ▼                                                         │
│   ⑦ VALIDATE     ──→ Test equivalence with legacy                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
\`\`\`

---

## 📜 Constitution for Migration

When filling the constitution for a migration project:

| Article | Brownfield Considerations |
|---------|---------------------------|
| **Article I** | Define TARGET stack; comment current stack for reference |
| **Article II** | Design new architecture; document migration patterns |
| **Article III** | New standards; migration code may have temporary exceptions |
| **Article IV** | Include legacy equivalence tests |
| **Article V** | Security improvements over legacy |
| **Article VI** | Target infrastructure |

---

## 🗂️ Legacy Source Reference

Your legacy source has been copied to \`legacy/source/\`:

\`\`\`bash
ls -la legacy/source/
\`\`\`

**⚠️ Important:** 
- Treat \`legacy/source/\` as **READ-ONLY** reference
- All new code goes in \`src/\`
- Document discoveries in \`legacy/analysis/\`

---

## 🤖 Available Bolt Framework Commands

| Command | Purpose | Phase |
|---------|---------|-------|
| \`/bolt.constitution\` | Define project governance & tech stack | Foundation |
| \`/bolt.feature [name]\` | Create new feature specification | Discovery |
| \`/bolt.specify\` | Define detailed requirements | Discovery |
| \`/bolt.clarify\` | Resolve ambiguous requirements | Discovery |
| \`/bolt.usecase\` | Generate use cases | Discovery |
| \`/bolt.gherkin\` | Generate BDD scenarios | Discovery |
| \`/bolt.plan\` | Create implementation plan | Design |
| \`/bolt.adr [title]\` | Create Architecture Decision Record | Design |
| \`/bolt.tasks\` | Generate Bolt task lists | Construction |
| \`/bolt.implement\` | Execute implementation | Construction |
| \`/bolt.test\` | Generate test suites | Construction |
| \`/bolt.analyze\` | Validate consistency | Validation |
| \`/bolt.review\` | Perform code review | Validation |

---

## 📖 Migration Steps

1. **🔍 Analyze Legacy** → Review \`legacy/source/\`, document in \`legacy/analysis/\`
2. **📜 Define Target Constitution** → Edit \`memory/constitution.md\`
3. **🗺️ Create Mappings** → Document in \`migration/mappings/\`
4. **📋 Define Features** → \`/bolt.feature migrate-xxx\`
5. **📝 Plan Migration** → \`/bolt.plan\`
6. **⚡ Migrate** → \`/bolt.implement\`
7. **✅ Validate** → \`/bolt.test\`

---

## 📂 Files Copied from Source

The following source location was copied:
- **Source**: \`$SOURCE_DIR\`
- **Destination**: \`legacy/source/\`

---

*Generated by Bolt Framework Init Script v1.0.0*
EOF
fi

log_success "README.md created"

# Create initial constitution prompt for AI
log_step "Creating constitution setup prompt..."

if [ "$PROJECT_TYPE" = "green" ]; then
    cat > "$OUTPUT_DIR/memory/SETUP-CONSTITUTION.md" << EOF
# 🔧 Constitution Setup Guide

## Your First Step

Open \`constitution.md\` and replace the \`[PLACEHOLDER]\` values with your project decisions.

## Quick Setup Checklist

### Frontend (if applicable)
- [ ] Choose framework (React, Vue, Angular, Next.js, etc.)
- [ ] Choose styling solution (Tailwind, CSS Modules, Styled Components, etc.)
- [ ] Choose state management (Redux, Zustand, Pinia, etc.)

### Backend
- [ ] Choose runtime (Node.js, Python, Java, .NET, Go, etc.)
- [ ] Choose framework (Express, FastAPI, Spring Boot, etc.)
- [ ] Choose API style (REST, GraphQL, gRPC, etc.)

### Database
- [ ] Choose primary database (PostgreSQL, MongoDB, MySQL, etc.)
- [ ] Choose cache (Redis, Memcached, etc.)

### Infrastructure
- [ ] Choose cloud provider (AWS, Azure, GCP, etc.)
- [ ] Choose container strategy (Docker, Kubernetes, etc.)
- [ ] Choose CI/CD (GitHub Actions, GitLab CI, etc.)

## AI Assistance

Use GitHub Copilot Chat with:
\`\`\`
/bolt.constitution
\`\`\`

The AI will help you fill in the constitution interactively!
EOF
else
    cat > "$OUTPUT_DIR/memory/SETUP-CONSTITUTION.md" << EOF
# 🔧 Brownfield Constitution Setup Guide

## Migration-Specific Setup

For brownfield projects, you need to:
1. **Analyze** the legacy code in \`legacy/source/\`
2. **Document** current technologies (as comments)
3. **Define** target technologies (in placeholders)

## Quick Setup Checklist

### Step 1: Analyze Legacy
- [ ] Identify current programming languages
- [ ] Identify current frameworks and libraries
- [ ] Document current architecture patterns
- [ ] List external dependencies and integrations

### Step 2: Define Target Stack
Fill the constitution with your TARGET technologies:

### Frontend (if migrating/modernizing)
- [ ] Current: _______________
- [ ] Target: [FRONTEND_FRAMEWORK]

### Backend (if migrating/modernizing)
- [ ] Current: _______________
- [ ] Target: [BACKEND_FRAMEWORK]

### Database (if migrating)
- [ ] Current: _______________
- [ ] Target: [PRIMARY_DATABASE]

## Migration Documentation

Create these mapping documents:
- \`migration/mappings/technology-mapping.md\` - Old → New tech
- \`migration/mappings/code-mapping.md\` - Old → New code patterns
- \`migration/plan/phases.md\` - Migration phases

## AI Assistance

Use GitHub Copilot Chat with:
\`\`\`
/bolt.constitution
\`\`\`

Tell the AI about your legacy stack and target stack!
EOF
fi

log_success "Constitution setup guide created"

# Create .gitignore
log_step "Creating .gitignore..."
cat > "$OUTPUT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/

# Build outputs
dist/
build/
out/
*.egg-info/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Test coverage
coverage/
.nyc_output/
htmlcov/

# Temporary
tmp/
temp/
*.tmp
EOF

log_success ".gitignore created"

# Initialize git repository
log_step "Initializing Git repository..."
cd "$OUTPUT_DIR"
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "🌅 Initial Bolt Framework project setup

- Project type: $([ "$PROJECT_TYPE" = "brown" ] && echo "Brownfield (Migration)" || echo "Greenfield (New Project)")
- Initialized with Bolt Framework + AI-DLC methodology
- Constitution template ready for configuration

Next steps:
1. Edit memory/constitution.md
2. Run /bolt.constitution in Copilot Chat
"
    log_success "Git repository initialized with initial commit"
else
    log_warning "Git repository already exists"
fi

# Final summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    ✅ Bolt Framework Project Initialized!                   ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📁 Project Location:${NC} $OUTPUT_DIR"
echo -e "${CYAN}📋 Project Type:${NC} $([ "$PROJECT_TYPE" = "brown" ] && echo "🏗️ Brownfield (Migration)" || echo "🌱 Greenfield (New Project)")"

# Show configuration for greenfield
if [ "$PROJECT_TYPE" = "green" ]; then
    echo ""
    echo -e "${CYAN}⚙️  Configuration Applied:${NC}"
    echo "   Backend:      $BACKEND_LANGUAGE ($BACKEND_VERSION) - $BACKEND_FRAMEWORK"
    echo "   Architecture: $ARCHITECTURE"
    echo "   CQRS:         $CQRS_ENABLED"
    echo "   Frontend:     $FRONTEND_FRAMEWORK"
    echo "   Database:     $DATABASE ($DATA_ACCESS)"
    echo "   Container:    $ORCHESTRATION"
    echo "   IaC:          $IAC_TOOL"
    echo "   CI/CD:        $CICD_PLATFORM"
fi

# Generate stack-specific configuration files based on constitution
log_step "Generating stack-specific configuration files..."
generate_stack_specific_configs "$OUTPUT_DIR/memory/constitution.md"

echo ""
echo -e "${YELLOW}📌 Next Steps:${NC}"
echo "   1. cd $OUTPUT_DIR"
if [ "$PROJECT_TYPE" = "green" ]; then
    echo "   2. Review memory/constitution.md (already pre-filled!)"
    echo "   3. Complete any remaining configuration sections"
    echo "   4. Start with: /bolt.feature [your-first-feature]"
else
    echo "   2. Open memory/constitution.md"
    echo "   3. Fill in your technology choices"
    echo "   4. Or use: /bolt.constitution in GitHub Copilot Chat"
fi
echo ""
if [ "$PROJECT_TYPE" = "brown" ]; then
    echo -e "${YELLOW}📂 Legacy Source:${NC}"
    echo "   Your source code is in: legacy/source/"
    echo "   Analyze it and document findings in: legacy/analysis/"
    echo ""
fi
echo -e "${MAGENTA}🌅 Happy coding with Bolt Framework!${NC}"
echo ""
