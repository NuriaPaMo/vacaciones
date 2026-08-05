#!/usr/bin/env bash
# =============================================================================
# _env-loader.sh
# Shared environment variable loader for Azure DevOps sync scripts
#
# Sources .env file from project root and validates required variables.
# All scripts should source this file before using any configuration.
#
# Usage (from any script):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_env-loader.sh"
# =============================================================================

# Resolve project root (4 levels up from scripts/bash/)
_LOADER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$_LOADER_DIR/../../../.." && pwd)"

# Load .env file if it exists
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  # Export variables from .env (skip comments and blank lines)
  set -a
  # shellcheck disable=SC1091
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    # Only set if not already defined (CLI/env takes precedence)
    if [[ -z "${!key:-}" ]]; then
      export "$key=$value"
    fi
  done < "$PROJECT_ROOT/.env"
  set +a
fi

# =============================================================================
# Configuration with defaults (env vars override defaults)
# =============================================================================

export AZURE_DEVOPS_ORG="${AZURE_DEVOPS_ORG:-}"
export AZURE_DEVOPS_PROJECT="${AZURE_DEVOPS_PROJECT:-}"
export AZURE_DEVOPS_AREA_PATH="${AZURE_DEVOPS_AREA_PATH:-}"
export AZURE_DEVOPS_ITERATION="${AZURE_DEVOPS_ITERATION:-}"
export AZURE_DEVOPS_REQUIRED_TAG="${AZURE_DEVOPS_REQUIRED_TAG:-Bolt Framework}"

# Aliases used by scripts (short names)
ORG="$AZURE_DEVOPS_ORG"
PROJECT="$AZURE_DEVOPS_PROJECT"
AREA_PATH="$AZURE_DEVOPS_AREA_PATH"
ITERATION="$AZURE_DEVOPS_ITERATION"
REQUIRED_TAG="$AZURE_DEVOPS_REQUIRED_TAG"

# =============================================================================
# Validation
# =============================================================================

_validate_env() {
  local missing=()

  if [[ -z "${AZURE_DEVOPS_EXT_PAT:-}" ]]; then
    missing+=("AZURE_DEVOPS_EXT_PAT")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "\033[31m❌ Missing required environment variables:\033[0m" >&2
    for var in "${missing[@]}"; do
      echo -e "\033[31m   - $var\033[0m" >&2
    done
    echo "" >&2
    echo "Set them in .env at project root or export them:" >&2
    echo "  export AZURE_DEVOPS_EXT_PAT=\"your-pat-token\"" >&2
    echo "" >&2
    echo "See template: .claude/skills/azure-devops-sync/templates/template.env" >&2
    return 1
  fi
}

# Run validation immediately on source
_validate_env
