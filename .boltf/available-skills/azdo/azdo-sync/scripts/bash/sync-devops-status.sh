#!/usr/bin/env bash
# =============================================================================
# sync-devops-status.sh
# Synchronize work item status updates from Azure DevOps to Bolt Framework specs
#
# Queries Azure DevOps for task status changes and updates the corresponding
# planning/tasks.md file in Bolt Framework specs.
#
# Usage:
#   ./sync-devops-status.sh [-f "specs/001-time-tracking"] [-c]
#
# Parameters:
#   -f, --feature-path   Path to the Bolt Framework feature (optional; syncs all if omitted)
#   -c, --auto-commit    Automatically commit changes to git
#
# Examples:
#   ./sync-devops-status.sh -f "specs/001-time-tracking"
#   ./sync-devops-status.sh                    # Sync all features
#   ./sync-devops-status.sh -c                 # Sync all and auto-commit
#
# Requires:
#   - Azure DevOps CLI (az devops)
#   - AZURE_DEVOPS_EXT_PAT environment variable
#   - jq (JSON processor)
# =============================================================================

set -euo pipefail

# Load environment (reads .env, sets ORG, PROJECT, AREA_PATH, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env-loader.sh"

# =============================================================================
# Defaults
# =============================================================================

FEATURE_PATH=""
AUTO_COMMIT=false

# =============================================================================
# Color helpers
# =============================================================================

info()    { echo -e "\033[36m[Info] $*\033[0m"; }
success() { echo -e "\033[32m[Success] $*\033[0m"; }
warn()    { echo -e "\033[33m[Warning] $*\033[0m"; }
error()   { echo -e "\033[31m[Error] $*\033[0m"; }

# =============================================================================
# Argument parsing
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--feature-path) FEATURE_PATH="$2"; shift 2 ;;
    -c|--auto-commit)  AUTO_COMMIT=true; shift ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# =============================================================================
# Get all synced features
# =============================================================================

get_all_features() {
  local specs_dir="specs"
  if [[ ! -d "$specs_dir" ]]; then
    warn "No specs/ folder found"
    return
  fi

  for dir in "$specs_dir"/*/; do
    if [[ -f "${dir}.metadata/devops-sync.json" ]]; then
      echo "${dir%/}"
    fi
  done
}

# =============================================================================
# Sync a single feature
# =============================================================================

sync_feature_status() {
  local path="$1"
  local feature_id
  feature_id=$(basename "$path")
  info "Syncing $feature_id..."

  local meta_path="$path/.metadata/devops-sync.json"
  if [[ ! -f "$meta_path" ]]; then
    warn "No sync metadata found, skipping"
    return 1
  fi

  local metadata
  metadata=$(cat "$meta_path")

  local task_count
  task_count=$(echo "$metadata" | jq '.azureDevOps.tasks | length')

  if [[ "$task_count" -eq 0 ]]; then
    warn "No tasks to sync"
    return 1
  fi

  local updates=()
  local updated_metadata="$metadata"

  for i in $(seq 0 $((task_count - 1))); do
    local wi_id bolt_id old_state title
    wi_id=$(echo "$metadata" | jq -r ".azureDevOps.tasks[$i].workItemId")
    bolt_id=$(echo "$metadata" | jq -r ".azureDevOps.tasks[$i].boltfBoltId")
    old_state=$(echo "$metadata" | jq -r ".azureDevOps.tasks[$i].state")
    title=$(echo "$metadata" | jq -r ".azureDevOps.tasks[$i].title")

    local current_state
    current_state=$(az boards work-item show --id "$wi_id" --output json 2>/dev/null | jq -r '.fields."System.State"') || {
      warn "  Failed to query task #$wi_id"
      continue
    }

    if [[ "$current_state" != "$old_state" ]]; then
      info "  Task #$wi_id: $old_state → $current_state"
      updates+=("$title|$old_state|$current_state")

      # Update metadata in-memory
      updated_metadata=$(echo "$updated_metadata" | jq \
        --arg state "$current_state" \
        --argjson idx "$i" \
        '.azureDevOps.tasks[$idx].state = $state')
    fi
  done

  if [[ ${#updates[@]} -eq 0 ]]; then
    success "  No status changes detected"
    return 1
  fi

  # Update tasks.md
  local tasks_path="$path/planning/tasks.md"
  if [[ ! -f "$tasks_path" ]]; then
    warn "  No tasks.md found"
    return 1
  fi

  local content
  content=$(cat "$tasks_path")
  local modified=false

  for update in "${updates[@]}"; do
    local u_title u_old u_new
    u_title=$(echo "$update" | cut -d'|' -f1)
    u_old=$(echo "$update" | cut -d'|' -f2)
    u_new=$(echo "$update" | cut -d'|' -f3)

    local new_checkbox="[ ]"
    if [[ "$u_new" == "Completed" || "$u_new" == "Closed" ]]; then
      new_checkbox="[x]"
    fi

    # Escape title for sed
    local escaped_title
    escaped_title=$(printf '%s' "$u_title" | sed 's/[][\\/.^$*+?(){}|]/\\&/g')

    if echo "$content" | grep -q "- \[.\] .*${u_title}"; then
      content=$(echo "$content" | sed "s/- \[.\] \(.*${escaped_title}\)/- ${new_checkbox} \1/")
      modified=true
      success "    Updated: $u_title"
    fi
  done

  if $modified; then
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    content="${content}

<!-- Last synced with Azure DevOps: $timestamp -->"

    echo "$content" > "$tasks_path"

    # Update metadata file
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    updated_metadata=$(echo "$updated_metadata" | jq --arg ts "$ts" '.lastSync = $ts')
    echo "$updated_metadata" | jq '.' > "$meta_path"

    success "  Updated ${#updates[@]} task(s)"
    return 0
  fi

  return 1
}

# =============================================================================
# Main
# =============================================================================

echo -e "\033[36m"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║             Azure DevOps Status → Bolt Framework Sync                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

any_changes=false

if [[ -n "$FEATURE_PATH" ]]; then
  # Sync single feature
  if [[ ! -d "$FEATURE_PATH" ]]; then
    error "Feature path not found: $FEATURE_PATH"
    exit 1
  fi

  if sync_feature_status "$FEATURE_PATH"; then
    any_changes=true
  fi
else
  # Sync all features
  features=()
  while IFS= read -r f; do
    [[ -n "$f" ]] && features+=("$f")
  done < <(get_all_features)

  if [[ ${#features[@]} -eq 0 ]]; then
    warn "No features with sync metadata found"
    exit 0
  fi

  info "Found ${#features[@]} synced feature(s)"

  for feature in "${features[@]}"; do
    if sync_feature_status "$feature"; then
      any_changes=true
    fi
  done
fi

# Auto-commit if requested
if $any_changes && $AUTO_COMMIT; then
  info "Committing changes..."

  git add specs/
  if git commit -m "chore: Sync task statuses from Azure DevOps

Automated sync at $(date '+%Y-%m-%d %H:%M:%S')
Updated task completion states from Azure DevOps Boards"; then
    success "Changes committed successfully"
  else
    error "Git commit failed"
  fi
elif $any_changes; then
  echo ""
  echo -e "\033[33mChanges detected but not committed. Run with -c to commit automatically.\033[0m"
  echo "Or manually commit:"
  echo -e "\033[36m  git add specs/"
  echo "  git commit -m \"chore: Sync task statuses from Azure DevOps\"\033[0m"
else
  success "No status changes detected - specs are up to date"
fi
