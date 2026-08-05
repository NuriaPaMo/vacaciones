#!/bin/bash

#
# sort-constitution-by-criticality.sh
#
# Sorts constitution articles by criticality (high, medium, low)
#
# Usage:
#   ./sort-constitution-by-criticality.sh <input-file> [output-file]
#
# Example:
#   ./sort-constitution-by-criticality.sh refinement-state.yaml
#   ./sort-constitution-by-criticality.sh state.yaml sorted.yaml
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is not installed${NC}"
    echo -e "${YELLOW}Install with: brew install yq (macOS) or snap install yq (Linux)${NC}"
    echo -e "${YELLOW}Or download from: https://github.com/mikefarah/yq${NC}"
    exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing input file${NC}"
    echo "Usage: $0 <input-file> [output-file]"
    exit 1
fi

INPUT_FILE="$1"

# Verify input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT_FILE${NC}"
    exit 1
fi

# Determine output file
if [ $# -ge 2 ]; then
    OUTPUT_FILE="$2"
else
    BASE_NAME=$(basename "$INPUT_FILE" .yaml)
    DIR_NAME=$(dirname "$INPUT_FILE")
    OUTPUT_FILE="$DIR_NAME/${BASE_NAME}.sorted.yaml"
fi

echo -e "${CYAN}Reading YAML from: $INPUT_FILE${NC}"

# Create temporary files for sorting
TEMP_DIR=$(mktemp -d)
HIGH_FILE="$TEMP_DIR/high.yaml"
MEDIUM_FILE="$TEMP_DIR/medium.yaml"
LOW_FILE="$TEMP_DIR/low.yaml"
OTHER_FILE="$TEMP_DIR/other.yaml"
HEADER_FILE="$TEMP_DIR/header.yaml"

# Check if constitution.articles exists
ARTICLE_COUNT=$(yq eval '.constitution.articles | length' "$INPUT_FILE")

if [ "$ARTICLE_COUNT" == "null" ] || [ "$ARTICLE_COUNT" == "0" ]; then
    echo -e "${YELLOW}Warning: No articles found in constitution${NC}"
    cp "$INPUT_FILE" "$OUTPUT_FILE"
    echo -e "${GREEN}Output written to: $OUTPUT_FILE${NC}"
    exit 0
fi

echo -e "${CYAN}Sorting $ARTICLE_COUNT articles by criticality...${NC}"

# Extract non-article parts of constitution
yq eval 'del(.constitution.articles)' "$INPUT_FILE" > "$HEADER_FILE"

# Separate articles by criticality
yq eval '.constitution.articles[] | select(.criticallity == "high")' "$INPUT_FILE" > "$HIGH_FILE" || touch "$HIGH_FILE"
yq eval '.constitution.articles[] | select(.criticallity == "medium")' "$INPUT_FILE" > "$MEDIUM_FILE" || touch "$MEDIUM_FILE"
yq eval '.constitution.articles[] | select(.criticallity == "low")' "$INPUT_FILE" > "$LOW_FILE" || touch "$LOW_FILE"
yq eval '.constitution.articles[] | select(.criticallity != "high" and .criticallity != "medium" and .criticallity != "low")' "$INPUT_FILE" > "$OTHER_FILE" || touch "$OTHER_FILE"

# Count articles in each category
HIGH_COUNT=$(yq eval '. | select(. != null)' "$HIGH_FILE" | grep -c "^article:" || echo "0")
MEDIUM_COUNT=$(yq eval '. | select(. != null)' "$MEDIUM_FILE" | grep -c "^article:" || echo "0")
LOW_COUNT=$(yq eval '. | select(. != null)' "$LOW_FILE" | grep -c "^article:" || echo "0")
OTHER_COUNT=$(yq eval '. | select(. != null)' "$OTHER_FILE" | grep -c "^article:" || echo "0")

# Build the sorted YAML
{
    # Add the header (constitution metadata without articles)
    cat "$HEADER_FILE"

    # Add articles array
    echo "  articles:"

    # Add high criticality articles
    if [ -s "$HIGH_FILE" ]; then
        yq eval '[.] | .[]' "$HIGH_FILE" | sed 's/^/    /'
    fi

    # Add medium criticality articles
    if [ -s "$MEDIUM_FILE" ]; then
        yq eval '[.] | .[]' "$MEDIUM_FILE" | sed 's/^/    /'
    fi

    # Add low criticality articles
    if [ -s "$LOW_FILE" ]; then
        yq eval '[.] | .[]' "$LOW_FILE" | sed 's/^/    /'
    fi

    # Add other articles (unknown criticality)
    if [ -s "$OTHER_FILE" ]; then
        yq eval '[.] | .[]' "$OTHER_FILE" | sed 's/^/    /'
    fi

} > "$OUTPUT_FILE"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo -e "${CYAN}Writing sorted YAML to: $OUTPUT_FILE${NC}"

# Summary
echo -e "\n${GREEN}Sorting complete!${NC}"
echo -e "  ${RED}High:    $HIGH_COUNT articles${NC}"
echo -e "  ${YELLOW}Medium:  $MEDIUM_COUNT articles${NC}"
echo -e "  ${GRAY}Low:     $LOW_COUNT articles${NC}"
if [ "$OTHER_COUNT" -gt 0 ]; then
    echo -e "  ${MAGENTA}Unknown: $OTHER_COUNT articles${NC}"
fi
echo -e "\n${GREEN}Output file: $OUTPUT_FILE${NC}"
