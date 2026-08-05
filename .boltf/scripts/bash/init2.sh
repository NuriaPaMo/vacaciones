#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Project Initialization Script v2.0
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

# Configuration variables
PROJECT_SCOPE=""
FRONTEND_FRAMEWORK=""
BACKEND_LANGUAGE=""
AUTO_MODE=false
AUTO_PROFILE=""
OUTPUT_DIR=""
PROJECT_TYPE=""
SOURCE_DIR=""
BOLT_ROOT=""

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

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
    echo "║            Interactive Project Setup v2.0 (NEW!)           ║"
    echo "╚═════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

validate_command_line_config() {
    [ -z "$PROJECT_SCOPE" ] && PROJECT_SCOPE="app-only"
    [ -z "$FRONTEND_FRAMEWORK" ] && FRONTEND_FRAMEWORK="none"
    [ -z "$BACKEND_LANGUAGE" ] && BACKEND_LANGUAGE="csharp"
    
    if [[ "$PROJECT_SCOPE" != "infra-only" && "$PROJECT_SCOPE" != "app-only" && "$PROJECT_SCOPE" != "full-stack" ]]; then
        log_error "Invalid --scope value: $PROJECT_SCOPE. Must be: infra-only, app-only, or full-stack"
        exit 1
    fi
    
    if [[ "$BACKEND_LANGUAGE" != "csharp" && "$BACKEND_LANGUAGE" != "nodejs" ]]; then
        log_error "Invalid --backend value: $BACKEND_LANGUAGE. Must be: csharp or nodejs"
        exit 1
    fi
    
    if [[ "$FRONTEND_FRAMEWORK" != "none" && "$FRONTEND_FRAMEWORK" != "react" && "$FRONTEND_FRAMEWORK" != "vue" && "$FRONTEND_FRAMEWORK" != "angular" && "$FRONTEND_FRAMEWORK" != "blazor" ]]; then
        log_error "Invalid --frontend value: $FRONTEND_FRAMEWORK. Must be: none, react, vue, angular, or blazor"
        exit 1
    fi
    
    log_success "Command-line configuration validated successfully"
}

apply_auto_profile() {
    local profile="$1"
    log_step "Applying auto profile: $profile"
    
    case "$profile" in
        "app-dotnet")
            PROJECT_SCOPE="app-only"
            BACKEND_LANGUAGE="csharp"
            FRONTEND_FRAMEWORK="none"
            ;;
        "app-node")
            PROJECT_SCOPE="app-only"
            BACKEND_LANGUAGE="nodejs"
            FRONTEND_FRAMEWORK="none"
            ;;
        "infra-landing"|\
        "infra-workload")
            PROJECT_SCOPE="infra-only"
            FRONTEND_FRAMEWORK="none"
            ;;
        "fullstack-react")
            PROJECT_SCOPE="full-stack"
            BACKEND_LANGUAGE="csharp"
            FRONTEND_FRAMEWORK="react"
            ;;
        "fullstack-vue")
            PROJECT_SCOPE="full-stack"
            BACKEND_LANGUAGE="csharp"
            FRONTEND_FRAMEWORK="vue"
            ;;
        *)
            log_error "Unknown auto profile: $profile"
            exit 1
            ;;
    esac
    
    log_success "Auto profile '$profile' applied successfully"
}

create_project_structure() {
    log_step "Creating new project structure..."
    
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/docs"
    
    if [ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        mkdir -p "$OUTPUT_DIR/src/backend"
        log_info "Created src/backend/ directory (PROJECT_SCOPE: $PROJECT_SCOPE)"
    fi
    
    if [ "$FRONTEND_FRAMEWORK" != "none" ] && ([ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]); then
        mkdir -p "$OUTPUT_DIR/src/frontend"
        log_info "Created src/frontend/ directory (FRONTEND_FRAMEWORK: $FRONTEND_FRAMEWORK)"
    fi
    
    if [ "$PROJECT_SCOPE" = "infra-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        mkdir -p "$OUTPUT_DIR/infra"
        log_info "Created infra/ directory (PROJECT_SCOPE: $PROJECT_SCOPE)"
    fi
    
    if [ "$PROJECT_TYPE" = "brown" ]; then
        mkdir -p "$OUTPUT_DIR/legacy"
        log_info "Created legacy/ directory for brownfield project"
    else
        mkdir -p "$OUTPUT_DIR/origin"
        log_info "Created origin/ directory for greenfield project"
    fi
    
    log_success "Project structure created successfully"
}

copy_legacy_source() {
    if [ "$PROJECT_TYPE" = "brown" ] && [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        log_step "Copying legacy source files to legacy/ directory..."
        cp -r "$SOURCE_DIR/"* "$OUTPUT_DIR/legacy/" 2>/dev/null || true
        log_success "Legacy source copied to legacy/"
    fi
}

copy_bolt_framework() {
    log_step "Copying complete Bolt Framework framework..."
    
    BOLT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    log_info "Bolt Framework root detected: $BOLT_ROOT"
    
    log_info "Copying complete .github directory..."
    if [ -d "$BOLT_ROOT/.github" ]; then
        rm -rf "$OUTPUT_DIR/.github" 2>/dev/null || true
        cp -r "$BOLT_ROOT/.github" "$OUTPUT_DIR/" 2>/dev/null || true
        log_success "Complete .github directory copied successfully"
    fi
    
    log_info "Copying complete .boltf directory..."
    if [ -d "$BOLT_ROOT/.boltf" ]; then
        rm -rf "$OUTPUT_DIR/.boltf" 2>/dev/null || true
        cp -r "$BOLT_ROOT/.boltf" "$OUTPUT_DIR/" 2>/dev/null || true
        log_success ".boltf directory copied"
    fi
    
    # Copy framework documentation files from .boltf to project root
    log_info "Copying Bolt Framework framework documentation..."
    if [ -f "$BOLT_ROOT/.boltf/README.md" ]; then
        cp "$BOLT_ROOT/.boltf/README.md" "$OUTPUT_DIR/" 2>/dev/null || true
        log_info "README.md copied to project root"
    fi
    if [ -f "$BOLT_ROOT/.boltf/CHANGELOG.md" ]; then
        cp "$BOLT_ROOT/.boltf/CHANGELOG.md" "$OUTPUT_DIR/" 2>/dev/null || true
        log_info "CHANGELOG.md copied to project root"
    fi
    if [ -f "$BOLT_ROOT/.boltf/CONTRIBUTING.md" ]; then
        cp "$BOLT_ROOT/.boltf/CONTRIBUTING.md" "$OUTPUT_DIR/" 2>/dev/null || true
        log_info "CONTRIBUTING.md copied to project root"
    fi
    if [ -f "$BOLT_ROOT/.boltf/LICENSE" ]; then
        cp "$BOLT_ROOT/.boltf/LICENSE" "$OUTPUT_DIR/" 2>/dev/null || true
        log_info "LICENSE copied to project root"
    fi
    if [ -f "$BOLT_ROOT/.boltf/PENDIENTES.md" ]; then
        cp "$BOLT_ROOT/.boltf/PENDIENTES.md" "$OUTPUT_DIR/" 2>/dev/null || true
        log_info "PENDIENTES.md copied to project root"
    fi
    
    log_success "Bolt Framework framework copied successfully"
}

show_usage() {
    echo "Usage: $0 <output-directory> <project-type> [source-directory] [OPTIONS]"
    echo ""
    echo "Parameters:"
    echo "  output-directory  : Where to create the project structure"
    echo "  project-type      : 'brown' for Brownfield, 'green' for Greenfield"
    echo "  source-directory  : (Required for brown) Directory with existing code/docs"
    echo ""
    echo "Options:"
    echo "  --auto <profile>     : Use predefined configuration profile"
    echo "  --scope <scope>      : Project scope (infra-only, app-only, full-stack)"
    echo "  --backend <lang>     : Backend language (csharp, nodejs)"
    echo "  --frontend <fw>      : Frontend framework (none, react, vue, angular, blazor)"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects/my-app green --scope app-only --backend csharp --frontend react"
    echo "  $0 ~/projects/legacy brown ~/legacy-code --scope app-only --frontend vue"
    exit 1
}

# Parse arguments
if [ $# -lt 2 ]; then
    log_error "Missing required arguments"
    show_usage
fi

OUTPUT_DIR="$1"
PROJECT_TYPE="$2"
shift 2

# Parse source directory (positional argument before flags)
if [ -n "$1" ] && [[ "$1" != --* ]]; then
    SOURCE_DIR="$1"
    shift
fi

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=true
            AUTO_PROFILE="$2"
            shift 2
            ;;
        --scope)
            PROJECT_SCOPE="$2"
            shift 2
            ;;
        --backend)
            BACKEND_LANGUAGE="$2"
            shift 2
            ;;
        --frontend)
            FRONTEND_FRAMEWORK="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate arguments
if [ "$PROJECT_TYPE" != "green" ] && [ "$PROJECT_TYPE" != "brown" ]; then
    log_error "project-type must be 'green' or 'brown'"
    show_usage
fi

if [ "$PROJECT_TYPE" = "brown" ] && [ -z "$SOURCE_DIR" ]; then
    log_error "source-directory is required for brownfield projects"
    show_usage
fi

if [ "$PROJECT_TYPE" = "brown" ] && [ ! -d "$SOURCE_DIR" ]; then
    log_error "source-directory '$SOURCE_DIR' does not exist"
    exit 1
fi

main() {
    print_banner
    
    log_info "Initializing Bolt Framework project..."
    log_info "  Output Directory: $OUTPUT_DIR"
    if [ "$PROJECT_TYPE" = "green" ]; then
        log_info "  Project Type: $PROJECT_TYPE - Greenfield New Project"
    else
        log_info "  Project Type: $PROJECT_TYPE - Brownfield Legacy Migration"
    fi
    [ -n "$SOURCE_DIR" ] && log_info "  Source Directory: $SOURCE_DIR"
    
    # Determine configuration method
    if [ "$AUTO_MODE" = true ]; then
        apply_auto_profile "$AUTO_PROFILE"
    elif [ -n "$PROJECT_SCOPE" ] || [ -n "$BACKEND_LANGUAGE" ] || [ -n "$FRONTEND_FRAMEWORK" ]; then
        log_info "Using command-line configuration"
        validate_command_line_config
    else
        # Set default values for brownfield or simple configuration
        PROJECT_SCOPE="app-only"
        FRONTEND_FRAMEWORK="react"
        BACKEND_LANGUAGE="csharp"
        log_info "Using default configuration: app-only, React, C#/.NET"
    fi
    
    # Create directory structure
    create_project_structure
    
    # Copy Bolt Framework framework
    copy_bolt_framework
    
    # Copy legacy source if brownfield
    copy_legacy_source
    
    log_success "Bolt Framework project initialization completed!"
    log_info "Project created in: $OUTPUT_DIR"
    log_info ""
    log_info "Configuration used:"
    log_info "  - Project Scope: $PROJECT_SCOPE"
    [ "$PROJECT_SCOPE" != "infra-only" ] && log_info "  - Backend Language: $BACKEND_LANGUAGE"
    [ "$FRONTEND_FRAMEWORK" != "none" ] && log_info "  - Frontend Framework: $FRONTEND_FRAMEWORK"
    log_info ""
    log_info "Next steps:"
    log_info "1. cd $OUTPUT_DIR"
    log_info "2. Review and configure .boltf/memory/constitution.md"
    if [ "$PROJECT_SCOPE" = "app-only" ] || [ "$PROJECT_SCOPE" = "full-stack" ]; then
        [ -d "$OUTPUT_DIR/src/backend" ] && log_info "3. Start backend development in src/backend/"
        [ -d "$OUTPUT_DIR/src/frontend" ] && log_info "4. Start frontend development in src/frontend/"
    fi
    if [ "$PROJECT_TYPE" = "brown" ]; then
        log_info "5. Analyze legacy code in legacy/ directory"
    else
        log_info "5. Place RFP, emails, initial docs in origin/ directory"
    fi
    log_info "6. Use Bolt Framework scripts from .boltf/scripts/"
}

# Run main function
main "$@"