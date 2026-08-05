#!/bin/bash
# =============================================================================
# Bolt Framework - Merge Refinement YAMLs
# =============================================================================
# Merge all scope refinement YAML files into a single merged-refinement.yaml
# =============================================================================

set -e

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Logging -----------------------------------------------------------------
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]  ${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERR] ${NC} $1"; }

# --- Variables ---------------------------------------------------------------
PROJECT_PATH="${1:-.}"
FORCE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [PROJECT_PATH] [--force]"
            echo ""
            echo "Arguments:"
            echo "  PROJECT_PATH    Path to Bolt Framework project (default: current directory)"
            echo "  --force, -f     Overwrite existing merged-refinement.yaml without prompting"
            echo ""
            exit 0
            ;;
    esac
done

# --- Main Script -------------------------------------------------------------

log_info "Bolt Framework - Merge Refinement YAMLs v1.0.0"
log_info "Project path: $PROJECT_PATH"
echo ""

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Project path does not exist: $PROJECT_PATH"
    exit 1
fi

REFINEMENT_DIR="$PROJECT_PATH/.boltf/memory/refinement-states"

if [[ ! -d "$REFINEMENT_DIR" ]]; then
    log_error "Refinement states directory not found: $REFINEMENT_DIR"
    log_error "Run constitution refinement first"
    exit 1
fi

# Find all scope refinement files (exclude merged-refinement.yaml)
mapfile -t REFINEMENT_FILES < <(find "$REFINEMENT_DIR" -maxdepth 1 -name "*-refinement.yaml" ! -name "merged-refinement.yaml")

if [[ ${#REFINEMENT_FILES[@]} -eq 0 ]]; then
    log_error "No refinement YAML files found in: $REFINEMENT_DIR"
    exit 1
fi

log_info "Found ${#REFINEMENT_FILES[@]} scope refinement file(s):"
for file in "${REFINEMENT_FILES[@]}"; do
    log_info "  • $(basename "$file")"
done
echo ""

# Check if merged file already exists
MERGED_PATH="$REFINEMENT_DIR/merged-refinement.yaml"
if [[ -f "$MERGED_PATH" ]] && [[ "$FORCE" != "true" ]]; then
    log_warn "merged-refinement.yaml already exists"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Merge cancelled"
        exit 0
    fi
fi

# --- Load and merge all refinement files -------------------------------------

log_info "Loading and merging refinement files..."

TOTAL_SCOPES=0
TOTAL_ARTICLES=0
TOTAL_DECISIONS=0
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CONFLICTS=()

declare -A ARTICLE_REGISTRY

SCOPE_ENTRIES=()

for file in "${REFINEMENT_FILES[@]}"; do
    SCOPE_NAME=$(basename "$file" | sed 's/-refinement\.yaml$//')
    log_info "Processing scope: $SCOPE_NAME"

    # Count articles (simple grep-based approach)
    ARTICLE_COUNT=$(grep -c "^  - article:" "$file" 2>/dev/null || echo "0")
    DECISION_COUNT=$(grep -c "decisions:" "$file" 2>/dev/null || echo "0")

    SCOPE_ENTRIES+=("$SCOPE_NAME:$ARTICLE_COUNT:$DECISION_COUNT")

    ((TOTAL_SCOPES++))
    ((TOTAL_ARTICLES+=ARTICLE_COUNT))
    ((TOTAL_DECISIONS+=DECISION_COUNT))

    # Extract article IDs for conflict detection
    while IFS= read -r line; do
        if [[ $line =~ article:[:space:]*\"?([^\"]+)\"? ]]; then
            ARTICLE_ID="${BASH_REMATCH[1]}"
            if [[ -n "${ARTICLE_REGISTRY[$ARTICLE_ID]}" ]]; then
                ARTICLE_REGISTRY[$ARTICLE_ID]="${ARTICLE_REGISTRY[$ARTICLE_ID]},$SCOPE_NAME"
            else
                ARTICLE_REGISTRY[$ARTICLE_ID]="$SCOPE_NAME"
            fi
        fi
    done < "$file"

    log_success "  Added $ARTICLE_COUNT articles, $DECISION_COUNT decisions"
done

# --- Detect conflicts --------------------------------------------------------

echo ""
log_info "Detecting conflicts..."

CONFLICT_COUNT=0
for article_id in "${!ARTICLE_REGISTRY[@]}"; do
    scopes="${ARTICLE_REGISTRY[$article_id]}"
    scope_count=$(echo "$scopes" | tr ',' '\n' | wc -l)

    if [[ $scope_count -gt 1 ]]; then
        CONFLICTS+=("$article_id:$scopes")
        ((CONFLICT_COUNT++))
        log_warn "  Conflict: $article_id appears in: $scopes"
    fi
done

if [[ $CONFLICT_COUNT -eq 0 ]]; then
    log_success "No conflicts detected"
fi

# --- Write merged YAML -------------------------------------------------------

echo ""
log_info "Writing merged-refinement.yaml..."

cat > "$MERGED_PATH" << EOF
# =============================================================================
# Bolt Framework - Merged Refinement State
# Generated: $TIMESTAMP
# =============================================================================
# This file contains the merged refinement decisions from all active scopes.
# Used by constitution generation phase to create the final constitution.md
# =============================================================================

# Summary Statistics
total_scopes: $TOTAL_SCOPES
total_articles: $TOTAL_ARTICLES
total_decisions: $TOTAL_DECISIONS
merge_timestamp: $TIMESTAMP
has_conflicts: $([ $CONFLICT_COUNT -gt 0 ] && echo "true" || echo "false")

# Scopes
scopes:
EOF

for entry in "${SCOPE_ENTRIES[@]}"; do
    IFS=':' read -r scope articles decisions <<< "$entry"
    cat >> "$MERGED_PATH" << EOF

  - scope: $scope
    articles_count: $articles
    decisions_count: $decisions
    source_file: $scope-refinement.yaml
EOF
done

if [[ $CONFLICT_COUNT -gt 0 ]]; then
    cat >> "$MERGED_PATH" << EOF

# Conflicts (articles appearing in multiple scopes)
conflicts:
EOF

    for conflict in "${CONFLICTS[@]}"; do
        IFS=':' read -r article scopes <<< "$conflict"
        # Convert comma-separated scopes to YAML array format
        scope_array=$(echo "$scopes" | sed 's/,/, /g')
        cat >> "$MERGED_PATH" << EOF
  - article: "$article"
    scopes: [$scope_array]
    resolution: pending
EOF
    done
fi

cat >> "$MERGED_PATH" << EOF

# =============================================================================
# Detailed Scope Data
# =============================================================================
# Each scope's full refinement data is preserved below for reference.
# The constitution generator will merge these based on the summary above.
# =============================================================================

scope_data:
EOF

for file in "${REFINEMENT_FILES[@]}"; do
    SCOPE_NAME=$(basename "$file" | sed 's/-refinement\.yaml$//')

    cat >> "$MERGED_PATH" << EOF

  # Scope: $SCOPE_NAME
  $SCOPE_NAME:
EOF

    # Indent the scope content (add 4 spaces to each line)
    sed 's/^/    /' "$file" >> "$MERGED_PATH"
done

log_success "Merged refinement file created: merged-refinement.yaml"
echo ""
log_info "Summary:"
log_info "  • Scopes merged: $TOTAL_SCOPES"
log_info "  • Total articles: $TOTAL_ARTICLES"
log_info "  • Total decisions: $TOTAL_DECISIONS"
log_info "  • Conflicts detected: $CONFLICT_COUNT"
echo ""
log_success "Merge complete!"
