#!/usr/bin/env bash
# =============================================================================
# assign-work-items-to-sprint.sh
# Assign a range of work items to a specific sprint/iteration
#
# Handles the correct iteration path format required by Azure DevOps.
#
# Usage:
#   ./assign-work-items-to-sprint.sh -s <start-id> -e <end-id> -n <sprint-number> [-d]
#
# Parameters:
#   -s, --start-id       First work item ID (required)
#   -e, --end-id         Last work item ID (required)
#   -n, --sprint-number  Sprint number (0, 1, 2, ...) (required)
#   -d, --dry-run        Preview changes without applying
#
# Examples:
#   ./assign-work-items-to-sprint.sh -s 31530 -e 31604 -n 1 -d
#   ./assign-work-items-to-sprint.sh -s 31530 -e 31604 -n 1
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

START_ID=""
END_ID=""
SPRINT_NUMBER=""
DRY_RUN=false

# =============================================================================
# Color helpers
# =============================================================================

info()    { echo -e "\033[36mℹ️  $*\033[0m"; }
success() { echo -e "\033[32m✅ $*\033[0m"; }
warn()    { echo -e "\033[33m⚠️  $*\033[0m"; }
error()   { echo -e "\033[31m❌ $*\033[0m"; }

# =============================================================================
# Argument parsing
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--start-id)      START_ID="$2"; shift 2 ;;
    -e|--end-id)        END_ID="$2"; shift 2 ;;
    -n|--sprint-number) SPRINT_NUMBER="$2"; shift 2 ;;
    -d|--dry-run)       DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

for var in START_ID END_ID SPRINT_NUMBER; do
  if [[ -z "${!var}" ]]; then
    error "Missing required parameter: $var"
    exit 1
  fi
done

# =============================================================================
# Iteration path
# =============================================================================

get_iteration_path() {
  local sprint_num="$1"

  # IMPORTANT: System.IterationPath does NOT include the \Iteration\ segment.
  # Correct: "Registro Horario\Sprint N"
  # Wrong:   "Registro Horario\Iteration\Sprint N" (causes TF401347)
  local iter_path="${PROJECT}\\Sprint ${sprint_num}"

  info "Using iteration path: $iter_path"

  # Verify sprint exists
  local iterations
  if iterations=$(az boards iteration project list --project "$PROJECT" --output json 2>/dev/null); then
    local sprint_name="Sprint $sprint_num"
    if echo "$iterations" | jq -e --arg n "$sprint_name" '.[] | select(.name == $n)' &>/dev/null; then
      success "Sprint $sprint_num verified"
    else
      warn "Could not verify Sprint $sprint_num exists — continuing anyway"
    fi
  else
    warn "Could not query iterations to verify — continuing anyway"
  fi

  echo "$iter_path"
}

set_work_item_iteration() {
  local id="$1"
  local iter_path="$2"

  if $DRY_RUN; then
    echo -e "\033[35m  [DRY RUN] Would assign #$id to: $iter_path\033[0m"
    return 0
  fi

  if az boards work-item update --id "$id" --iteration "$iter_path" --output none 2>/dev/null; then
    return 0
  else
    error "Failed to assign #$id to iteration"
    return 1
  fi
}

# =============================================================================
# Main
# =============================================================================

TOTAL=$(( END_ID - START_ID + 1 ))

echo -e "\033[36m"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                   Assign Work Items to Sprint                             ║"
echo "║                                                                           ║"
printf "║  Work Item Range: #%-5s - #%-5s%36s ║\n" "$START_ID" "$END_ID" ""
printf "║  Sprint:          %-60s ║\n" "$SPRINT_NUMBER"
printf "║  Dry Run:         %-60s ║\n" "$DRY_RUN"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Step 1: Get iteration path
iteration_path=$(get_iteration_path "$SPRINT_NUMBER")
echo ""

# Step 2: Assign
info "Assigning work items to '$iteration_path'..."
echo ""

assigned=0
failed=0

for (( id=START_ID; id<=END_ID; id++ )); do
  if set_work_item_iteration "$id" "$iteration_path"; then
    echo -e "  \033[32m✅ Work Item #$id assigned to Sprint $SPRINT_NUMBER\033[0m"
    assigned=$((assigned + 1))
  else
    echo -e "  \033[31m❌ Work Item #$id FAILED\033[0m"
    failed=$((failed + 1))
  fi

  # Throttle to avoid API rate limits
  sleep 0.3
done

# Step 3: Verification
echo ""
info "Verifying assignment..."

verified_count=0
verify_result=$(az boards query \
  --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Id] >= $START_ID AND [System.Id] <= $END_ID AND [System.IterationPath] UNDER '$iteration_path'" \
  --output json 2>/dev/null) || true

if [[ -n "$verify_result" ]]; then
  verified_count=$(echo "$verify_result" | jq 'length')
  success "Verified: $verified_count/$TOTAL work items assigned to Sprint $SPRINT_NUMBER"
else
  warn "Verification query failed (may be expected if DryRun)"
fi

# Step 4: Summary
echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                       Assignment Complete                                 ║"
echo "╠═══════════════════════════════════════════════════════════════════════════╣"
printf "║  Total Work Items:      %-50s ║\n" "$TOTAL"
printf "║  Successfully Assigned: %-50s ║\n" "$assigned"
printf "║  Failed:                %-50s ║\n" "$failed"
[[ "$verified_count" -gt 0 ]] && printf "║  Verified in Query:     %-50s ║\n" "$verified_count"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

if $DRY_RUN; then
  echo -e "\033[33m⚠️  DRY RUN - No changes were made to Azure DevOps\033[0m"
  echo "Run without -d to apply changes"
elif [[ "$failed" -gt 0 ]]; then
  echo -e "\033[33m⚠️  Some work items failed to assign\033[0m"
  exit 1
else
  echo -e "\033[32m🎉 All work items successfully assigned to Sprint $SPRINT_NUMBER!\033[0m"
fi
