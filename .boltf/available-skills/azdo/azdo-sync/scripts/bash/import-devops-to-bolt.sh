#!/usr/bin/env bash
# =============================================================================
# import-devops-to-bolt.sh
# Import Azure DevOps work items into Bolt specification format
#
# Retrieves an existing Azure DevOps Feature and its children (User Stories,
# Tasks) and generates the corresponding Bolt spec structure in specs/.
#
# Usage:
#   ./import-devops-to-bolt.sh -i <work-item-id> -o <output-path> [--no-children] [--force]
#
# Parameters:
#   -i, --work-item-id   Feature work item ID to import (required)
#   -o, --output-path    Target spec path, e.g. "specs/002-imported" (required)
#   --no-children        Import only the Feature, skip User Stories/Tasks
#   --force              Overwrite existing spec folder
#
# Examples:
#   ./import-devops-to-bolt.sh -i 12345 -o "specs/001-time-tracking"
#   ./import-devops-to-bolt.sh -i 12345 -o "specs/001-time-tracking" --no-children
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

WORK_ITEM_ID=""
OUTPUT_PATH=""
INCLUDE_CHILDREN=true
FORCE=false

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
    -i|--work-item-id) WORK_ITEM_ID="$2"; shift 2 ;;
    -o|--output-path)  OUTPUT_PATH="$2"; shift 2 ;;
    --no-children)     INCLUDE_CHILDREN=false; shift ;;
    --force)           FORCE=true; shift ;;
    -h|--help)
      sed -n '2,/^# ====/{/^# ====/d;s/^# //;p}' "$0"
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$WORK_ITEM_ID" ]]; then
  error "Work item ID is required (use -i <id>)"
  exit 1
fi

if [[ -z "$OUTPUT_PATH" ]]; then
  error "Output path is required (use -o <path>)"
  exit 1
fi

# =============================================================================
# Helpers
# =============================================================================

get_work_item() {
  az boards work-item show --id "$1" --output json 2>/dev/null
}

get_children() {
  local parent_id="$1"
  az boards query \
    --wiql "SELECT [System.Id],[System.Title],[System.State],[System.WorkItemType] FROM WorkItems WHERE [System.Parent] = $parent_id" \
    --output json 2>/dev/null
}

html_to_md() {
  local text="${1:-}"
  [[ -z "$text" ]] && return
  text=$(echo "$text" | sed -e 's/<br[^>]*>/\n/g' -e 's/<p>/\n/g' -e 's/<\/p>/\n/g')
  text=$(echo "$text" | sed -e 's/<strong>\(.*\)<\/strong>/**\1**/g' -e 's/<b>\(.*\)<\/b>/**\1**/g')
  text=$(echo "$text" | sed -e 's/<em>\(.*\)<\/em>/*\1*/g' -e 's/<i>\(.*\)<\/i>/*\1*/g')
  text=$(echo "$text" | sed 's/<[^>]*>//g')
  echo "$text" | sed '/^$/d'
}

# =============================================================================
# Generate feature.md
# =============================================================================

generate_feature_md() {
  local wi_json="$1"

  local title description ac state created_date
  title=$(echo "$wi_json" | jq -r '.fields."System.Title"')
  description=$(html_to_md "$(echo "$wi_json" | jq -r '.fields."System.Description" // ""')")
  ac=$(html_to_md "$(echo "$wi_json" | jq -r '.fields."Microsoft.VSTS.Common.AcceptanceCriteria" // ""')")
  state=$(echo "$wi_json" | jq -r '.fields."System.State"')
  created_date=$(echo "$wi_json" | jq -r '.fields."System.CreatedDate"')
  local wi_id
  wi_id=$(echo "$wi_json" | jq -r '.id')

  cat > "$OUTPUT_PATH/feature.md" <<EOF
# $title

> **Imported from Azure DevOps**: Work Item #$wi_id
> **State**: $state
> **Created**: $created_date

## Description

$description

## Objectives

<!-- Define high-level objectives this feature aims to achieve -->

- [ ] Objective 1
- [ ] Objective 2

## Scope

### In Scope

- Items imported from Azure DevOps User Stories

### Out of Scope

- To be defined during Bolt Framework DISCOVERY phase

## Acceptance Criteria

$ac

## Dependencies

- [ ] Dependency 1 (if any)

## Risks & Assumptions

### Risks

- **Risk**: Describe potential risk
  - **Mitigation**: How to mitigate

### Assumptions

- Assumption 1
- Assumption 2

## Notes

Imported from Azure DevOps on $(date "+%Y-%m-%d %H:%M:%S")

Original work item: $ORG/$PROJECT/_workitems/edit/$wi_id

---

**Phase**: DISCOVERY
**Status**: Imported - Requires Bolt Framework refinement
EOF

  success "Created feature.md"
}

# =============================================================================
# Generate requirements/requirements.md
# =============================================================================

generate_requirements_md() {
  local stories_json="$1"
  local count
  count=$(echo "$stories_json" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    warn "No user stories to import"
    return
  fi

  mkdir -p "$OUTPUT_PATH/requirements"

  {
    echo "# Requirements"
    echo ""
    echo "> Imported from Azure DevOps User Stories"
    echo ""
    echo "## User Stories"
    echo ""

    for i in $(seq 0 $((count - 1))); do
      local story_id
      story_id=$(echo "$stories_json" | jq -r ".[$i].id")
      local detail
      detail=$(get_work_item "$story_id")

      local s_title s_desc s_ac s_state
      s_title=$(echo "$detail" | jq -r '.fields."System.Title"')
      s_desc=$(html_to_md "$(echo "$detail" | jq -r '.fields."System.Description" // ""')")
      s_ac=$(html_to_md "$(echo "$detail" | jq -r '.fields."Microsoft.VSTS.Common.AcceptanceCriteria" // ""')")
      s_state=$(echo "$detail" | jq -r '.fields."System.State"')

      local idx
      idx=$(printf "%03d" $((i + 1)))

      echo "### US-$idx: $s_title"
      echo ""
      echo "**State**: $s_state"
      echo "**Azure DevOps**: [Work Item #$story_id]($ORG/$PROJECT/_workitems/edit/$story_id)"
      echo ""
      echo "**Description**:"
      echo ""
      echo "$s_desc"
      echo ""
      echo "**Acceptance Criteria**:"
      echo ""
      echo "$s_ac"
      echo ""
    done

    echo "---"
    echo ""
    echo "**Last Updated**: $(date "+%Y-%m-%d")"
    echo "**Source**: Azure DevOps import"
  } > "$OUTPUT_PATH/requirements/requirements.md"

  success "Created requirements/requirements.md with $count user stories"
}

# =============================================================================
# Generate planning/tasks.md
# =============================================================================

generate_tasks_md() {
  local tasks_json="$1"
  local count
  count=$(echo "$tasks_json" | jq 'length')

  if [[ "$count" -eq 0 ]]; then
    warn "No tasks to import"
    return
  fi

  mkdir -p "$OUTPUT_PATH/planning"

  {
    echo "# Bolt Tasks"
    echo ""
    echo "> Imported from Azure DevOps Tasks"
    echo ""
    echo "## Implementation Tasks"
    echo ""

    local completed=0

    for i in $(seq 0 $((count - 1))); do
      local task_id
      task_id=$(echo "$tasks_json" | jq -r ".[$i].id")
      local detail
      detail=$(get_work_item "$task_id")

      local t_title t_state remaining completed_work hours checkbox hours_text
      t_title=$(echo "$detail" | jq -r '.fields."System.Title"')
      t_state=$(echo "$detail" | jq -r '.fields."System.State"')
      remaining=$(echo "$detail" | jq -r '.fields."Microsoft.VSTS.Scheduling.RemainingWork" // 0')
      completed_work=$(echo "$detail" | jq -r '.fields."Microsoft.VSTS.Scheduling.CompletedWork" // 0')

      if [[ "$remaining" != "0" && "$remaining" != "null" ]]; then
        hours="$remaining"
      elif [[ "$completed_work" != "0" && "$completed_work" != "null" ]]; then
        hours="$completed_work"
      else
        hours="0"
      fi

      checkbox="[ ]"
      if [[ "$t_state" == "Completed" || "$t_state" == "Closed" ]]; then
        checkbox="[x]"
        completed=$((completed + 1))
      fi

      hours_text=""
      [[ "$hours" != "0" ]] && hours_text=" (${hours}h)"

      echo "- $checkbox $t_title$hours_text"
      echo "  - **State**: $t_state"
      echo "  - **Azure DevOps**: [#$task_id]($ORG/$PROJECT/_workitems/edit/$task_id)"
      echo ""
    done

    echo "---"
    echo ""
    echo "**Total Tasks**: $count"
    echo "**Completed**: $completed"
    echo "**Last Updated**: $(date "+%Y-%m-%d")"
  } > "$OUTPUT_PATH/planning/tasks.md"

  success "Created planning/tasks.md with $count tasks"
}

# =============================================================================
# Generate .metadata/devops-sync.json
# =============================================================================

generate_metadata() {
  local feature_json="$1"
  local stories_json="$2"
  local tasks_json="$3"

  local feature_id
  feature_id=$(basename "$OUTPUT_PATH")
  local wi_id
  wi_id=$(echo "$feature_json" | jq -r '.id')

  mkdir -p "$OUTPUT_PATH/.metadata"

  local story_arr task_arr
  story_arr=$(echo "$stories_json" | jq --arg fid "$feature_id" '
    [to_entries[] | {
      workItemId: .value.id,
      boltStoryId: ("US-" + ((.key + 1) | tostring | if length < 3 then "0" * (3 - length) + . else . end)),
      title: .value.fields."System.Title",
      state: .value.fields."System.State"
    }]')

  task_arr=$(echo "$tasks_json" | jq --arg fid "$feature_id" '
    [to_entries[] | {
      workItemId: .value.id,
      boltBoltId: ($fid + "-" + ((.key + 1) | tostring | if length < 3 then "0" * (3 - length) + . else . end)),
      title: .value.fields."System.Title",
      state: .value.fields."System.State"
    }]')

  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq -n \
    --arg ver "1.0.0" \
    --arg fid "$feature_id" \
    --arg org "$ORG" \
    --arg proj "$PROJECT" \
    --argjson wid "$wi_id" \
    --argjson stories "$story_arr" \
    --argjson tasks "$task_arr" \
    --arg ts "$ts" \
    --arg imp "Azure DevOps on $(date '+%Y-%m-%d %H:%M:%S')" \
    '{
      version: $ver,
      boltFeatureId: $fid,
      azureDevOps: {
        organization: $org,
        project: $proj,
        featureWorkItemId: $wid,
        userStories: $stories,
        tasks: $tasks
      },
      lastSync: $ts,
      syncDirection: "bidirectional",
      importedFrom: $imp
    }' > "$OUTPUT_PATH/.metadata/devops-sync.json"

  success "Created .metadata/devops-sync.json"
}

# =============================================================================
# Main
# =============================================================================

echo -e "\033[36m"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║             Azure DevOps → Bolt Framework Import                                  ║"
echo "║                                                                           ║"
printf "║  Work Item ID: %-58s ║\n" "$WORK_ITEM_ID"
printf "║  Output Path:  %-58s ║\n" "$OUTPUT_PATH"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Step 1: Check output path
if [[ -d "$OUTPUT_PATH" ]] && ! $FORCE; then
  error "Output path already exists: $OUTPUT_PATH"
  warn "Use --force to overwrite"
  exit 1
fi

# Step 2: Retrieve Feature work item
info "Retrieving work item #$WORK_ITEM_ID..."
feature_json=$(get_work_item "$WORK_ITEM_ID")

wi_type=$(echo "$feature_json" | jq -r '.fields."System.WorkItemType"')
if [[ "$wi_type" != "Feature" ]]; then
  error "Work item is type '$wi_type', expected 'Feature'"
  warn "Only Feature work items can be imported as Bolt Framework specs"
  exit 1
fi

feature_title=$(echo "$feature_json" | jq -r '.fields."System.Title"')
success "Found Feature: $feature_title"

# Step 3: Create output directory
mkdir -p "$OUTPUT_PATH"

# Step 4: Generate feature.md
generate_feature_md "$feature_json"

# Step 5: Import children
user_stories="[]"
all_tasks="[]"

if $INCLUDE_CHILDREN; then
  info "Importing child work items..."

  children=$(get_children "$WORK_ITEM_ID")

  user_stories=$(echo "$children" | jq '[.[] | select(.fields."System.WorkItemType" == "User Story")]')
  story_count=$(echo "$user_stories" | jq 'length')
  info "Found $story_count User Stories"

  if [[ "$story_count" -gt 0 ]]; then
    generate_requirements_md "$user_stories"

    # Get tasks (children of user stories)
    for i in $(seq 0 $((story_count - 1))); do
      story_id=$(echo "$user_stories" | jq -r ".[$i].id")
      story_tasks=$(get_children "$story_id")
      tasks_only=$(echo "$story_tasks" | jq '[.[] | select(.fields."System.WorkItemType" == "Task")]')
      all_tasks=$(echo "$all_tasks" "$tasks_only" | jq -s '.[0] + .[1]')
    done

    task_count=$(echo "$all_tasks" | jq 'length')
    info "Found $task_count Tasks across all User Stories"

    if [[ "$task_count" -gt 0 ]]; then
      generate_tasks_md "$all_tasks"
    fi
  fi
fi

# Step 6: Generate sync metadata
generate_metadata "$feature_json" "$user_stories" "$all_tasks"

# Step 7: Summary
echo ""
echo -e "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                          Import Complete                                  ║"
echo "╠═══════════════════════════════════════════════════════════════════════════╣"
printf "║  Feature:       Work Item #%-49s ║\n" "$WORK_ITEM_ID"
printf "║  User Stories:  %-60s ║\n" "$(echo "$user_stories" | jq 'length')"
printf "║  Tasks:         %-60s ║\n" "$(echo "$all_tasks" | jq 'length')"
printf "║  Output:        %-60s ║\n" "$OUTPUT_PATH"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

echo -e "\033[33mNext steps:\033[0m"
echo "  1. Review generated spec in $OUTPUT_PATH"
echo "  2. Refine with Bolt Framework agents:"
echo -e "     \033[36m@Bolt Framework Feature review $OUTPUT_PATH\033[0m"
echo -e "     \033[36m@Bolt Framework Plan verify implementation plan\033[0m"
echo "  3. Verify constitution compliance"
