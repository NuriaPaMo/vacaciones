#!/usr/bin/env bash
# =============================================================================
# fix-devops-work-items.sh
# Fix existing Azure DevOps work items to comply with Bolt Framework standards
#
# Updates work items to add:
#   - 'Bolt Framework' tag (REQUIRED for all work items)
#   - Feature → PBI parent-child relationships
#   - Task → PBI parent-child relationships
#
# Usage:
#   ./fix-devops-work-items.sh -s <start-id> -e <end-id> [-d]
#
# Parameters:
#   -s, --start-id   First work item ID (required)
#   -e, --end-id     Last work item ID (required)
#   -d, --dry-run    Preview changes without applying
#
# Examples:
#   ./fix-devops-work-items.sh -s 31530 -e 31604 -d    # Preview
#   ./fix-devops-work-items.sh -s 31530 -e 31604        # Apply fixes
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
    -s|--start-id) START_ID="$2"; shift 2 ;;
    -e|--end-id)   END_ID="$2"; shift 2 ;;
    -d|--dry-run)  DRY_RUN=true; shift ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

for var in START_ID END_ID; do
  if [[ -z "${!var}" ]]; then
    error "Missing required parameter: $var"
    exit 1
  fi
done

# =============================================================================
# Helpers
# =============================================================================

get_work_item() {
  az boards work-item show --id "$1" --output json 2>/dev/null
}

update_tags() {
  local id="$1"
  local tags_string="$2"

  if $DRY_RUN; then
    echo -e "\033[35m  [DRY RUN] Would set tags to: $tags_string\033[0m"
    return 0
  fi

  if az boards work-item update --id "$id" --fields "System.Tags=$tags_string" --output none 2>/dev/null; then
    return 0
  else
    error "Failed to update tags for #$id"
    return 1
  fi
}

add_parent_link() {
  local child_id="$1"
  local parent_id="$2"

  if $DRY_RUN; then
    echo -e "\033[35m  [DRY RUN] Would link #$child_id → Parent #$parent_id\033[0m"
    return 0
  fi

  if az boards work-item relation add \
    --id "$child_id" \
    --relation-type "parent" \
    --target-id "$parent_id" \
    --output none 2>/dev/null; then
    return 0
  else
    error "Failed to add parent link #$child_id → #$parent_id"
    return 1
  fi
}

# =============================================================================
# Main
# =============================================================================

echo -e "\033[36m"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║              Bolt Framework Work Items Compliance Fix                     ║"
echo "║                                                                           ║"
printf "║  Work Item Range: #%-5s - #%-5s%36s ║\n" "$START_ID" "$END_ID" ""
printf "║  Dry Run: %-66s ║\n" "$DRY_RUN"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Step 1: Retrieve all work items
info "Retrieving work items #$START_ID - #$END_ID..."

declare -A wi_types wi_tags wi_titles wi_has_parent
wi_ids=()

for (( id=START_ID; id<=END_ID; id++ )); do
  wi_json=$(get_work_item "$id") || { warn "Skipping non-existent work item #$id"; continue; }

  wi_ids+=("$id")
  wi_types[$id]=$(echo "$wi_json" | jq -r '.fields."System.WorkItemType"')
  wi_tags[$id]=$(echo "$wi_json" | jq -r '.fields."System.Tags" // ""')
  wi_titles[$id]=$(echo "$wi_json" | jq -r '.fields."System.Title"')

  # Check for parent link
  has_parent=$(echo "$wi_json" | jq '[.relations[]? | select(.rel == "System.LinkTypes.Hierarchy-Reverse")] | length')
  wi_has_parent[$id]=$has_parent
done

success "Retrieved ${#wi_ids[@]} work items"

# Categorize
pbi_ids=()
task_ids=()
for id in "${wi_ids[@]}"; do
  case "${wi_types[$id]}" in
    "Product Backlog Item") pbi_ids+=("$id") ;;
    "Task")                 task_ids+=("$id") ;;
  esac
done

info "Found ${#pbi_ids[@]} PBIs, ${#task_ids[@]} Tasks"

# Step 2: Fix tags
info "Fixing tags..."
tags_fixed=0

for id in "${wi_ids[@]}"; do
  current="${wi_tags[$id]}"

  if [[ "$current" != *"$REQUIRED_TAG"* ]]; then
    echo "  Work Item #$id: Adding '$REQUIRED_TAG' tag"

    if [[ -n "$current" ]]; then
      new_tags="$REQUIRED_TAG;$current"
    else
      new_tags="$REQUIRED_TAG"
    fi

    if update_tags "$id" "$new_tags"; then
      tags_fixed=$((tags_fixed + 1))
    fi
  else
    echo -e "  \033[90mWork Item #$id: Already has '$REQUIRED_TAG' tag\033[0m"
  fi
done

success "Fixed tags on $tags_fixed work items"

# Step 3: Ensure PBIs have Feature parent
info "Checking Feature parent for PBIs..."
feature_links=0

stories_without_feature=()
for id in "${pbi_ids[@]}"; do
  if [[ "${wi_has_parent[$id]}" -eq 0 ]]; then
    stories_without_feature+=("$id")
  fi
done

if [[ ${#stories_without_feature[@]} -gt 0 ]]; then
  warn "Found ${#stories_without_feature[@]} PBIs without Feature parent"

  # Try to find feature tag (e.g., 008-infra-observabilidad)
  feature_tag=""
  for id in "${wi_ids[@]}"; do
    tag=$(echo "${wi_tags[$id]}" | tr ';' '\n' | grep -m1 '^[0-9]\{3\}-' | tr -d ' ') || true
    if [[ -n "$tag" ]]; then
      feature_tag="$tag"
      break
    fi
  done

  feature_wi_id=""

  if [[ -n "$feature_tag" ]]; then
    info "Searching for Feature with tag '$feature_tag'..."
    query_result=$(az boards query \
      --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Feature' AND [System.Tags] CONTAINS '$feature_tag'" \
      --output json 2>/dev/null) || true

    if [[ -n "$query_result" ]]; then
      feature_wi_id=$(echo "$query_result" | jq -r '.[0].id // empty')
      if [[ -n "$feature_wi_id" ]]; then
        success "Found existing Feature #$feature_wi_id"
      fi
    fi
  fi

  if [[ -z "$feature_wi_id" ]]; then
    info "No Feature found. Creating one from spec..."

    feature_title="Feature: ${feature_tag:-unknown}"

    # Try to read title from spec files
    if [[ -n "$feature_tag" && -d "specs/$feature_tag" ]]; then
      for sf in feature.md spec.md; do
        spec_file="specs/$feature_tag/$sf"
        if [[ -f "$spec_file" ]]; then
          title_line=$(grep -m1 '^# ' "$spec_file" | sed 's/^# //')
          [[ -n "$title_line" ]] && feature_title="$title_line"
          break
        fi
      done
    fi

    if $DRY_RUN; then
      echo -e "\033[35m  [DRY RUN] Would create Feature: $feature_title\033[0m"
    else
      local_tags="$REQUIRED_TAG"
      [[ -n "$feature_tag" ]] && local_tags="$REQUIRED_TAG;$feature_tag"

      result=$(az boards work-item create \
        --type "Feature" \
        --title "$feature_title" \
        --project "$PROJECT" \
        --fields "System.AreaPath=$AREA_PATH" "System.Tags=$local_tags" \
        --output json 2>&1) || { error "Failed to create Feature: $result"; }

      feature_wi_id=$(echo "$result" | jq -r '.id // empty')
      if [[ -n "$feature_wi_id" ]]; then
        success "Created Feature #$feature_wi_id: $feature_title"
      fi
    fi
  fi

  # Link PBIs to Feature
  if [[ -n "$feature_wi_id" ]]; then
    for pbi_id in "${stories_without_feature[@]}"; do
      echo -e "  \033[33mLinking PBI #$pbi_id → Feature #$feature_wi_id\033[0m"
      if add_parent_link "$pbi_id" "$feature_wi_id"; then
        echo -e "    \033[32m✅ Linked PBI #$pbi_id → Feature #$feature_wi_id\033[0m"
        feature_links=$((feature_links + 1))
      fi
    done
  fi
else
  success "All PBIs already have a Feature parent"
fi

# Step 4: Create Task → PBI links
info "Creating Task → PBI parent-child relationships..."

# Feature 008 hardcoded mapping (same as PowerShell version)
declare -A parent_mapping
parent_mapping[31530]="31534 31535 31536 31537 31538 31539 31540 31541 31542 31543 31544 31545 31546 31547 31548 31549 31550"
parent_mapping[31531]="31551 31552 31553 31554 31555 31556 31557 31558 31559 31560 31561 31562 31563 31564 31565 31566 31567 31568 31569 31570 31571 31572 31573 31574 31575 31576 31577 31578"
parent_mapping[31532]="31579 31580 31581 31582 31583 31584 31585 31586 31587 31588 31589"
parent_mapping[31533]="31590 31591 31592 31593 31594 31595 31596 31597 31598 31599 31600 31601 31602 31603 31604"

links_created=0

for parent_id in "${!parent_mapping[@]}"; do
  # Check parent is in our set
  if [[ -z "${wi_types[$parent_id]:-}" ]]; then
    warn "Parent PBI #$parent_id not found, skipping children"
    continue
  fi

  echo ""
  echo -e "  \033[33mParent: #$parent_id - ${wi_titles[$parent_id]}\033[0m"

  for child_id in ${parent_mapping[$parent_id]}; do
    if [[ -z "${wi_types[$child_id]:-}" ]]; then
      warn "    Child task #$child_id not found"
      continue
    fi

    if [[ "${wi_has_parent[$child_id]}" -gt 0 ]]; then
      echo -e "    \033[90mTask #$child_id already linked to parent\033[0m"
      continue
    fi

    if add_parent_link "$child_id" "$parent_id"; then
      echo -e "    \033[32m✅ Linked Task #$child_id → Parent #$parent_id\033[0m"
      links_created=$((links_created + 1))
    fi
  done
done

success "Created $links_created task parent-child links"
success "Created $feature_links feature-to-story links"

# Summary
echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                          Fix Complete                                     ║"
echo "╠═══════════════════════════════════════════════════════════════════════════╣"
printf "║  Tags Fixed:          %-52s ║\n" "$tags_fixed"
printf "║  Feature→PBI Links:   %-52s ║\n" "$feature_links"
printf "║  Task→PBI Links:      %-52s ║\n" "$links_created"
printf "║  Total Work Items:    %-52s ║\n" "${#wi_ids[@]}"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

if $DRY_RUN; then
  echo -e "\033[33m⚠️  DRY RUN - No changes were made to Azure DevOps\033[0m"
  echo "Run without -d to apply changes"
fi
