#!/usr/bin/env bash
# =============================================================================
# Bolt Framework - Python Environment Bootstrap (Bash)
# =============================================================================
# Ensures Python is available and dependencies are installed in a virtual env
# =============================================================================

set -e

# ─── Configuration ───────────────────────────────────────────────────────────
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
VENV_PATH="$PROJECT_ROOT/.bolt-venv"
FORCE=false
SKIP_INSTALL=false

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; }

# ─── Parse Arguments ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --project-root)
            PROJECT_ROOT="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ─── Check Python ────────────────────────────────────────────────────────────
info "Checking Python installation..."

PYTHON_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | grep -oP 'Python \K[0-9]+\.[0-9]+')
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [[ $major -ge 3 && $minor -ge 9 ]]; then
            PYTHON_CMD="$cmd"
            success "Found: Python $version"
            break
        fi
    fi
done

if [[ -z "$PYTHON_CMD" ]]; then
    error "Python 3.9+ not found in PATH"
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║  Python 3.9+ is required for advanced Bolt Framework features           ║"
    echo "║                                                                          ║"
    echo "║  Install on Ubuntu/Debian: sudo apt install python3 python3-venv        ║"
    echo "║  Install on macOS:         brew install python@3.11                     ║"
    echo "║  Install on RHEL/Fedora:   sudo dnf install python3                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    exit 1
fi

# ─── Create/Activate Virtual Environment ────────────────────────────────────
if [[ -d "$VENV_PATH" ]]; then
    if [[ "$FORCE" == "true" ]]; then
        warn "Removing existing virtual environment..."
        rm -rf "$VENV_PATH"
    else
        info "Virtual environment already exists: $VENV_PATH"
    fi
fi

if [[ ! -d "$VENV_PATH" ]]; then
    info "Creating virtual environment at: $VENV_PATH"
    "$PYTHON_CMD" -m venv "$VENV_PATH"
    success "Virtual environment created"
fi

# ─── Activate Virtual Environment ───────────────────────────────────────────
info "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# ─── Install Dependencies ────────────────────────────────────────────────────
if [[ "$SKIP_INSTALL" != "true" ]]; then
    REQUIREMENTS_FILES=(
        ".claude/skills/skill-creator/requirements.txt"
        ".claude/skills/skill-bolt-setup-constitution/requirements.txt"
    )

    INSTALLED=false
    for req_file in "${REQUIREMENTS_FILES[@]}"; do
        full_path="$PROJECT_ROOT/$req_file"
        if [[ -f "$full_path" ]]; then
            info "Installing dependencies from: $req_file"
            python -m pip install --quiet --upgrade pip
            python -m pip install --quiet -r "$full_path"
            success "Dependencies installed from $req_file"
            INSTALLED=true
        fi
    done

    if [[ "$INSTALLED" != "true" ]]; then
        warn "No requirements.txt files found"
    fi
fi

# ─── Verification ────────────────────────────────────────────────────────────
info "Verifying installation..."
if python -c "import anthropic, yaml" 2>/dev/null; then
    success "All required packages installed"
else
    warn "Some packages may not be installed"
fi

# ─── Usage Instructions ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  Python environment ready!                                               ║"
echo "║                                                                          ║"
echo "║  Location: $VENV_PATH"
echo "║                                                                          ║"
echo "║  To use Python scripts in this project:                                 ║"
echo "║    1. Activate: source .bolt-venv/bin/activate                          ║"
echo "║    2. Run script: python .claude/skills/skill-creator/scripts/...       ║"
echo "║    3. Deactivate: deactivate                                            ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
