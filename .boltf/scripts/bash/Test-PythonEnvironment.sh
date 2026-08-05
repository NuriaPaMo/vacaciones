#!/usr/bin/env bash
# =============================================================================
# Bolt Framework - Python Environment Test (Bash)
# =============================================================================
# Validates that Python environment is correctly setup
# =============================================================================

set -e

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Configuration ───────────────────────────────────────────────────────────
# Navigate to project root (3 levels up from .boltf/scripts/bash/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
VENV_PATH="$PROJECT_ROOT/.bolt-venv"
PYTHON_EXE="$VENV_PATH/bin/python"

# ─── Helpers ─────────────────────────────────────────────────────────────────
test_result() {
    local test_name=$1
    local passed=$2
    local details=${3:-}

    if [[ "$passed" == "true" ]]; then
        echo -e "${GREEN}✅ $test_name${NC}"
    else
        echo -e "${RED}❌ $test_name${NC}"
    fi

    if [[ -n "$details" ]]; then
        echo -e "   ${NC}$details"
    fi
}

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Bolt Framework - Python Environment Verification         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ─── Test 1: Check Python Command ───────────────────────────────────────────
echo -e "${CYAN}[1/5] Checking system Python...${NC}"
if command -v python3 &> /dev/null; then
    version=$(python3 --version 2>&1)
    test_result "System Python: $version" "true"
else
    test_result "System Python" "false" "Not found in PATH"
fi

# ─── Test 2: Check Virtual Environment Exists ───────────────────────────────
echo ""
echo -e "${CYAN}[2/5] Checking virtual environment...${NC}"
if [[ -d "$VENV_PATH" ]]; then
    test_result "Virtual environment exists at .bolt-venv/" "true"
else
    test_result "Virtual environment exists" "false"
    echo ""
    echo -e "${YELLOW}⚠️  Virtual environment not found. Run:${NC}"
    echo -e "   source .boltf/scripts/bash/Bootstrap-Python.sh"
    echo ""
    exit 1
fi

# ─── Test 3: Check Python Executable ─────────────────────────────────────────
echo ""
echo -e "${CYAN}[3/5] Checking Python executable...${NC}"
if [[ -f "$PYTHON_EXE" ]]; then
    test_result "Python executable exists" "true"
else
    test_result "Python executable exists" "false"
    echo ""
    echo -e "${YELLOW}⚠️  Python executable not found. Recreate venv:${NC}"
    echo -e "   rm -rf .bolt-venv"
    echo -e "   source .boltf/scripts/bash/Bootstrap-Python.sh"
    echo ""
    exit 1
fi

# ─── Test 4: Check Required Packages ─────────────────────────────────────────
echo ""
echo -e "${CYAN}[4/5] Checking installed packages...${NC}"
if "$PYTHON_EXE" -c "import anthropic" 2>/dev/null; then
    version=$("$PYTHON_EXE" -c "import anthropic; print(anthropic.__version__)")
    test_result "anthropic v$version" "true"
else
    test_result "anthropic" "false" "Missing - needed for AI SDK"
fi

if "$PYTHON_EXE" -c "import yaml" 2>/dev/null; then
    test_result "pyyaml" "true"
else
    test_result "pyyaml" "false" "Missing - needed for YAML parsing"
fi

# ─── Test 5: Test Python Import ──────────────────────────────────────────────
echo ""
echo -e "${CYAN}[5/5] Testing Python imports...${NC}"
if "$PYTHON_EXE" -c "import anthropic, yaml, json; from pathlib import Path; from concurrent.futures import ProcessPoolExecutor" 2>/dev/null; then
    test_result "Import test" "true"
else
    test_result "Import test" "false"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Test Summary                                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "📍 Virtual Environment: .bolt-venv/"
echo -e "📍 Python Executable:   $PYTHON_EXE"
version=$("$PYTHON_EXE" --version 2>&1)
echo -e "📍 Python Version:      $version"

echo ""
echo -e "${GREEN}✅ Python environment is ready for use!${NC}"
echo ""

echo -e "${CYAN}Try these commands:${NC}"
echo -e "  source .bolt-venv/bin/activate"
echo -e "  python .claude/skills/skill-creator/scripts/quick_validate.py .claude/skills/skill-creator/"
echo ""
