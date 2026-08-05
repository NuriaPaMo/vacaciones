#!/usr/bin/env bash
# =============================================================================
# verify-parent-child-links.sh
# Quick verification of parent-child link status for tasks
#
# Iterates through a range of task work items and checks whether each
# has a parent (Hierarchy-Reverse) relation.
#
# Usage:
#   ./verify-parent-child-links.sh [-s <start-id>] [-e <end-id>]
#
# Parameters:
#   -s, --start-id   First task ID (default: 31534)
#   -e, --end-id     Last task ID (default: 31604)
#
# Examples:
#   ./verify-parent-child-links.sh                      # Check default range
#   ./verify-parent-child-links.sh -s 31534 -e 31604    # Explicit range
#
# Requires:
#   - Azure DevOps CLI (az devops)
#   - AZURE_DEVOPS_EXT_PAT environment variable (or .env file)
#   - jq (JSON processor)
# =============================================================================

set -euo pipefail

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env-loader.sh"

# =============================================================================
# Defaults
# =============================================================================

START_ID=31534
END_ID=31604

# =============================================================================
# Argument parsing
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--start-id) START_ID="$2"; shift 2 ;;
    -e|--end-id)   END_ID="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) echo -e "\033[31m❌ Unknown option: $1\033[0m"; exit 1 ;;
  esac
done

# =============================================================================
# Main
# =============================================================================

echo -e "\033[36mVerificando estado de relaciones Parent-Child...\033[0m"
echo ""

tasks_with_parent=0
tasks_without_parent=0
total=$((END_ID - START_ID + 1))

for (( id=START_ID; id<=END_ID; id++ )); do
  wi_json=$(az boards work-item show --id "$id" --output json 2>/dev/null) || {
    echo -e "\033[33m⚠️  Task #$id no encontrada\033[0m"
    continue
  }

  has_parent=$(echo "$wi_json" | jq '[.relations[]? | select(.rel == "System.LinkTypes.Hierarchy-Reverse")] | length')

  if [[ "$has_parent" -gt 0 ]]; then
    tasks_with_parent=$((tasks_with_parent + 1))
  else
    tasks_without_parent=$((tasks_without_parent + 1))
    echo -e "\033[33mTask #$id sin parent\033[0m"
  fi
done

echo ""
echo -e "\033[36m📊 Resumen:\033[0m"

if [[ "$tasks_without_parent" -eq 0 ]]; then
  color="\033[32m"
else
  color="\033[33m"
fi

echo -e "  \033[32m✅ Tasks con parent: $tasks_with_parent/$total\033[0m"
echo -e "  ${color}❌ Tasks sin parent: $tasks_without_parent/$total\033[0m"
