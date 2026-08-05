#!/bin/bash
# =============================================================================
# Get Next ADR Number - Bash Script
# =============================================================================
# Finds the next available ADR number by scanning existing ADR files.
#
# Usage:
#   ./get-next-adr-number.sh [adr-directory]
#
# Arguments:
#   adr-directory: Path to ADR directory (default: docs/adr)
#
# Output:
#   Prints the next ADR number in format NNNN (4 digits with leading zeros)
#
# Examples:
#   ./get-next-adr-number.sh
#   ./get-next-adr-number.sh docs/architecture/decisions
# =============================================================================

set -e

# Default ADR directory
ADR_DIR="${1:-docs/adr}"

# Find last ADR number
LAST=$(ls -1 "${ADR_DIR}"/ADR-*.md 2>/dev/null | sort -V | tail -1 | grep -oP 'ADR-\K[0-9]+' || echo "0")

# Calculate next number
NEXT=$((LAST + 1))

# Format with leading zeros (4 digits)
NUM=$(printf "%04d" $NEXT)

# Output the number
echo "$NUM"
