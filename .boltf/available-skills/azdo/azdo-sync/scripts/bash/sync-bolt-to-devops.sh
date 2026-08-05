#!/usr/bin/env bash
# =============================================================================
# sync-bolt-to-devops.sh
# Synchronize Bolt feature specifications to Azure DevOps work items
#
# Reads Bolt specs from specs/ folder and creates/updates corresponding
# work items in Azure DevOps (Features, User Stories, Tasks).
# Maintains traceability through .metadata/devops-sync.json
#
# Usage:
#   ./sync-bolt-to-devops.sh -f "specs/001-time-tracking" [-m incremental] [-d] [--force]
#
# Parameters:
#   -f, --feature-path   Path to the Bolt feature folder (required)
#   -m, --mode           Sync mode: full | incremental (default: incremental)
#   -d, --dry-run        Preview changes without creating work items
#   --force              Skip confirmation prompts
#
# Examples:
#   ./sync-bolt-to-devops.sh -f "specs/001-time-tracking" -d
#   ./sync-bolt-to-devops.sh -f "specs/001-time-tracking" -m full
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
MODE="incremental"
DRY_RUN=false
FORCE=false

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
    -f|--feature-path) FEATURE_PATH="$2"; shift 2 ;;
    -m|--mode)         MODE="$2"; shift 2 ;;
    -d|--dry-run)      DRY_RUN=true; shift ;;
    --force)           FORCE=true; shift ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$FEATURE_PATH" ]]; then
  error "Feature path is required (use -f <path>)"
  exit 1
fi

if [[ ! -d "$FEATURE_PATH" ]]; then
  error "Feature path does not exist: $FEATURE_PATH"
  exit 1
fi

MODE=$(echo "$MODE" | tr '[:upper:]' '[:lower:]')
if [[ "$MODE" != "full" && "$MODE" != "incremental" ]]; then
  error "Mode must be 'full' or 'incremental'"
  exit 1
fi

# =============================================================================
# Auth check
# =============================================================================

check_auth() {
  info "Verifying Azure DevOps authentication..."

  if [[ -z "${AZURE_DEVOPS_EXT_PAT:-}" ]]; then
    error "AZURE_DEVOPS_EXT_PAT environment variable not set"
    echo ""
    echo "Please configure authentication:"
    echo "  export AZURE_DEVOPS_EXT_PAT=\"your-pat-token\""
    echo "  az devops configure --defaults organization=$ORG project=\"$PROJECT\""
    return 1
  fi

  if ! az devops project show --project "$PROJECT" --query "name" -o tsv &>/dev/null; then
    error "Failed to connect to Azure DevOps project"
    return 1
  fi

  success "Authentication successful"
}

# =============================================================================
# Metadata helpers
# =============================================================================

get_metadata() {
  local meta_path="$FEATURE_PATH/.metadata/devops-sync.json"
  if [[ -f "$meta_path" ]]; then
    cat "$meta_path"
  else
    local feature_id
    feature_id=$(basename "$FEATURE_PATH")
    cat <<EOF
{
  "version": "1.0.0",
  "boltFeatureId": "$feature_id",
  "azureDevOps": {
    "organization": "$ORG",
    "project": "$PROJECT",
    "featureWorkItemId": null,
    "userStories": [],
    "tasks": []
  },
  "lastSync": null,
  "syncDirection": "bidirectional"
}
EOF
  fi
}

save_metadata() {
  local metadata="$1"
  local meta_dir="$FEATURE_PATH/.metadata"
  mkdir -p "$meta_dir"

  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  metadata=$(echo "$metadata" | jq --arg ts "$ts" '.lastSync = $ts')

  echo "$metadata" | jq '.' > "$meta_dir/devops-sync.json"
  success "Metadata saved to $meta_dir/devops-sync.json"
}

# =============================================================================
# Markdown reading
# =============================================================================

read_feature_markdown() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    return 1
  fi

  local content
  content=$(cat "$path")

  local title
  title=$(echo "$content" | grep -m1 '^# ' | sed 's/^# //')
  title=${title:-"Untitled Feature"}

  local description=""
  if echo "$content" | grep -q '## Description'; then
    description=$(echo "$content" | sed -n '/^## Description/,/^## /{ /^## /d; p; }' | sed '/^$/d' | head -20)
  fi

  local ac=""
  if echo "$content" | grep -q '## Acceptance Criteria'; then
    ac=$(echo "$content" | sed -n '/^## Acceptance Criteria/,/^## /{ /^## /d; p; }' | sed '/^$/d' | head -20)
  fi

  echo "$title"
  echo "---SEPARATOR---"
  echo "$description"
  echo "---SEPARATOR---"
  echo "$ac"
}

# =============================================================================
# Work item creation
# =============================================================================

create_work_item() {
  local wi_type="$1"
  local title="$2"
  local description="${3:-}"
  local ac="${4:-}"
  local parent_id="${5:-}"
  local tags="${6:-}"
  local remaining_work="${7:-0}"

  if $DRY_RUN; then
    echo -e "\033[35m  [DRY RUN] Would create $wi_type: $title\033[0m"
    echo "-1"
    return
  fi

  # Always include 'Bolt Framework' tag
  if [[ -n "$tags" ]]; then
    # Deduplicate
    if [[ "$tags" != *"$REQUIRED_TAG"* ]]; then
      tags="$REQUIRED_TAG;$tags"
    fi
  else
    tags="$REQUIRED_TAG"
  fi

  # Sanitize inputs
  title=$(echo "$title" | tr '"`' "''")
  description=$(echo "$description" | tr '"`' "''")

  local fields=(
    "System.AreaPath=$AREA_PATH"
    "System.IterationPath=$ITERATION"
    "System.Tags=$tags"
  )

  if [[ -n "$ac" ]]; then
    fields+=("Microsoft.VSTS.Common.AcceptanceCriteria=$ac")
  fi

  if [[ -n "$parent_id" && "$parent_id" != "null" ]]; then
    fields+=("System.Parent=$parent_id")
  fi

  if [[ "$remaining_work" != "0" && -n "$remaining_work" ]]; then
    fields+=("Microsoft.VSTS.Scheduling.RemainingWork=$remaining_work")
  fi

  local fields_args=()
  for f in "${fields[@]}"; do
    fields_args+=("--fields" "$f")
  done

  local result
  result=$(az boards work-item create \
    --type "$wi_type" \
    --title "$title" \
    --description "$description" \
    --project "$PROJECT" \
    --output json \
    "${fields_args[@]}" 2>&1) || {
      error "Azure CLI error creating $wi_type: $result"
      echo ""
      return 1
    }

  local wi_id
  wi_id=$(echo "$result" | jq -r '.id // empty')

  if [[ -z "$wi_id" ]]; then
    error "Failed to create $wi_type (no ID returned)"
    echo ""
    return 1
  fi

  success "Created $wi_type #$wi_id: $title"
  echo "$wi_id"
}

# =============================================================================
# Sync Feature
# =============================================================================

sync_feature() {
  local metadata="$1"
  local existing_id
  existing_id=$(echo "$metadata" | jq -r '.azureDevOps.featureWorkItemId // empty')

  if [[ -n "$existing_id" && "$existing_id" != "null" && "$MODE" == "incremental" ]]; then
    info "Using existing Feature #$existing_id"
    echo "$existing_id"
    return
  fi

  # Look for feature.md or spec.md
  local feature_file="$FEATURE_PATH/feature.md"
  local spec_file="$FEATURE_PATH/spec.md"
  local md_file=""

  if [[ -f "$feature_file" ]]; then
    md_file="$feature_file"
  elif [[ -f "$spec_file" ]]; then
    warn "No feature.md found, using spec.md as fallback"
    md_file="$spec_file"
  else
    warn "Skipping feature creation (no feature.md or spec.md found)"
    echo ""
    return
  fi

  local raw
  raw=$(read_feature_markdown "$md_file")

  local title description ac
  title=$(echo "$raw" | sed -n '1p')
  description=$(echo "$raw" | sed -n '/---SEPARATOR---/,/---SEPARATOR---/{//!p;}' | head -n -0)
  # Actually parse three sections
  title=$(echo "$raw" | awk '/---SEPARATOR---/{n++;next} n==0{print}')
  description=$(echo "$raw" | awk '/---SEPARATOR---/{n++;next} n==1{print}')
  ac=$(echo "$raw" | awk '/---SEPARATOR---/{n++;next} n==2{print}')

  local feature_id
  feature_id=$(basename "$FEATURE_PATH")
  local tags="$feature_id;feature"

  info "Syncing Feature: $title"

  local wi_id
  wi_id=$(create_work_item "Feature" "$title" "$description" "$ac" "" "$tags")

  echo "$wi_id"
}

# =============================================================================
# Sync User Stories
# =============================================================================

sync_user_stories() {
  local feature_wi_id="$1"
  local metadata="$2"

  local req_path="$FEATURE_PATH/requirements/requirements.md"
  if [[ ! -f "$req_path" ]]; then
    warn "No requirements.md found, skipping user stories"
    echo "[]"
    return
  fi

  local content
  content=$(cat "$req_path")

  # Extract user stories using grep/sed
  local stories_json="[]"
  local story_count=0

  # Parse multi-line user story format
  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+(US-[0-9.]+):[[:space:]]+(.+)$ ]]; then
      local story_id="${BASH_REMATCH[1]}"
      local story_title="${BASH_REMATCH[2]}"

      # Read next lines for role/goal/benefit
      local role="" goal="" benefit=""
      while IFS= read -r next_line; do
        if [[ "$next_line" =~ ^\*\*As\ a\*\*[[:space:]]+(.+)$ ]]; then
          role="${BASH_REMATCH[1]}"
        elif [[ "$next_line" =~ ^\*\*I\ want\*\*[[:space:]]+(.+)$ ]]; then
          goal="${BASH_REMATCH[1]}"
        elif [[ "$next_line" =~ ^\*\*So\ that\*\*[[:space:]]+(.+)$ ]]; then
          benefit="${BASH_REMATCH[1]}"
          break
        elif [[ "$next_line" =~ ^### ]]; then
          break
        fi
      done < <(sed -n "/### $story_id/,/### US-/p" "$req_path" | tail -n +2)

      local full_title="As a $role I want $goal"
      local desc="**So that**: $benefit\n\n**Feature**: $story_id - $story_title"
      local feature_id
      feature_id=$(basename "$FEATURE_PATH")
      local tags="$feature_id;$story_id;user-story"

      info "  Creating User Story: $story_title"

      local wi_id
      wi_id=$(create_work_item "Product Backlog Item" "$full_title" "$desc" "" "$feature_wi_id" "$tags")

      stories_json=$(echo "$stories_json" | jq \
        --arg id "${wi_id:-0}" \
        --arg sid "$story_id" \
        --arg title "$story_id - $story_title" \
        '. + [{"workItemId": ($id | tonumber), "boltStoryId": $sid, "title": $title, "state": "New"}]')

      story_count=$((story_count + 1))
    fi
  done < "$req_path"

  info "Found $story_count user stories"
  echo "$stories_json"
}

# =============================================================================
# Sync Tasks
# =============================================================================

sync_tasks() {
  local stories_json="$1"
  local metadata="$2"

  local tasks_path="$FEATURE_PATH/planning/tasks.md"
  if [[ ! -f "$tasks_path" ]]; then
    warn "No tasks.md found, skipping tasks"
    echo "[]"
    return
  fi

  local content
  content=$(cat "$tasks_path")

  # Default parent = first user story
  local default_parent
  default_parent=$(echo "$stories_json" | jq -r '.[0].workItemId // empty')

  if [[ -z "$default_parent" || "$default_parent" == "null" ]]; then
    warn "No parent user story available for tasks"
    echo "[]"
    return
  fi

  local tasks_json="[]"
  local feature_id
  feature_id=$(basename "$FEATURE_PATH")

  # Parse task lines: - [ ] or - [x] with optional **task-id** prefix
  while IFS= read -r line; do
    if [[ "$line" =~ ^-[[:space:]]\[([ x])\].*\*\*([0-9]{3}-[a-zA-Z0-9-]+)\*\*[[:space:]]+(.+)$ ]]; then
      local is_done="${BASH_REMATCH[1]}"
      local task_id="${BASH_REMATCH[2]}"
      local task_title="${BASH_REMATCH[3]}"

      # Extract hours if present
      local hours=4
      if [[ "$task_title" =~ \(([0-9.]+)h\)$ ]]; then
        hours="${BASH_REMATCH[1]}"
        task_title=$(echo "$task_title" | sed 's/ *([0-9.]*h)$//')
      elif [[ "$task_title" =~ \(([0-9]+)min\)$ ]]; then
        local mins="${BASH_REMATCH[1]}"
        hours=$(echo "scale=2; $mins / 60" | bc)
        task_title=$(echo "$task_title" | sed 's/ *([0-9]*min)$//')
      fi

      local tags="$feature_id;$task_id;bolt-task"

      info "    Creating Task: $task_id - $task_title"

      local wi_id
      wi_id=$(create_work_item "Task" "$task_title" \
        "Bolt Framework Bolt task from $FEATURE_PATH/planning/tasks.md" "" \
        "$default_parent" "$tags" "$hours")

      local state="To Do"
      [[ "$is_done" == "x" ]] && state="Completed"

      tasks_json=$(echo "$tasks_json" | jq \
        --arg id "${wi_id:-0}" \
        --arg bid "$task_id" \
        --arg title "$task_title" \
        --arg state "$state" \
        '. + [{"workItemId": ($id | tonumber), "boltBoltId": $bid, "title": $title, "state": $state}]')
    fi
  done < "$tasks_path"

  local task_count
  task_count=$(echo "$tasks_json" | jq length)
  info "Created $task_count tasks"
  echo "$tasks_json"
}

# =============================================================================
# Main
# =============================================================================

echo -e "\033[36m"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                 Bolt Framework → Azure DevOps Synchronization                    ║"
echo "║                                                                           ║"
printf "║  Feature Path: %-58s ║\n" "$FEATURE_PATH"
printf "║  Mode: %-68s ║\n" "$MODE"
printf "║  Dry Run: %-66s ║\n" "$DRY_RUN"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Step 1: Auth
check_auth || exit 1

# Step 2: Load metadata
metadata=$(get_metadata)
feature_bolt_id=$(echo "$metadata" | jq -r '.boltfFeatureId')
info "Feature ID: $feature_bolt_id"

# Step 3: Check sync mode
existing_feature_id=$(echo "$metadata" | jq -r '.azureDevOps.featureWorkItemId // empty')
if [[ "$MODE" == "incremental" && -n "$existing_feature_id" && "$existing_feature_id" != "null" ]]; then
  info "Feature already synced (ID: $existing_feature_id)"
  if ! $FORCE; then
    read -rp "Feature already exists in DevOps. Continue? (y/n) " response
    [[ "$response" != "y" ]] && { warn "Sync cancelled by user"; exit 0; }
  fi
fi

# Step 4: Sync Feature
feature_wi_id=$(sync_feature "$metadata")
if [[ -n "$feature_wi_id" && "$feature_wi_id" != "-1" && "$feature_wi_id" != "null" ]]; then
  metadata=$(echo "$metadata" | jq --arg id "$feature_wi_id" '.azureDevOps.featureWorkItemId = ($id | tonumber)')
fi

# Step 5: Sync User Stories
stories_json=$(sync_user_stories "${feature_wi_id:-}" "$metadata")
story_count=$(echo "$stories_json" | jq 'length')
if [[ "$story_count" -gt 0 ]]; then
  metadata=$(echo "$metadata" | jq --argjson stories "$stories_json" '.azureDevOps.userStories = $stories')
fi

# Step 6: Sync Tasks
tasks_json=$(sync_tasks "$stories_json" "$metadata")
task_count=$(echo "$tasks_json" | jq 'length')
if [[ "$task_count" -gt 0 ]]; then
  metadata=$(echo "$metadata" | jq --argjson tasks "$tasks_json" '.azureDevOps.tasks = $tasks')
fi

# Step 7: Save metadata
if ! $DRY_RUN; then
  save_metadata "$metadata"
fi

# Step 8: Summary
echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                          Sync Complete                                    ║"
echo "╠═══════════════════════════════════════════════════════════════════════════╣"
printf "║  Feature:       Work Item #%-49s ║\n" "${feature_wi_id:--}"
printf "║  User Stories:  %-60s ║\n" "$story_count"
printf "║  Tasks:         %-60s ║\n" "$task_count"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

if $DRY_RUN; then
  echo -e "\033[33m⚠️  DRY RUN - No changes were made to Azure DevOps\033[0m"
fi
