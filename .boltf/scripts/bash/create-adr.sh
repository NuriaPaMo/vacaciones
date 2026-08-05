#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Create ADR Script
# =============================================================================
# Creates a new Architectural Decision Record from template.
# Follows MADR format as defined in bolt-adr.
#
# Reference: .claude/skills/bolt-adr/SKILL.md
# Templates: .claude/skills/bolt-adr/templates/
#
# Usage:
#   ./create-adr.sh <adr-title>
#
# Example:
#   ./create-adr.sh "database-selection"
#   ./create-adr.sh "authentication-strategy"
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate arguments
if [ -z "$1" ]; then
    log_error "ADR title is required"
    echo "Usage: $0 <adr-title>"
    echo "Example: $0 database-selection"
    exit 1
fi

ADR_TITLE="$1"
ADR_DIR="docs/adr"
DATE=$(date +%Y-%m-%d)

# Create ADR directory if not exists
mkdir -p "${ADR_DIR}"

# Find next ADR number
LAST_ADR=$(ls -1 "${ADR_DIR}"/ADR-*.md 2>/dev/null | sort -V | tail -1 | grep -oP 'ADR-\K[0-9]+' || echo "0")
NEXT_NUM=$((LAST_ADR + 1))
ADR_NUM=$(printf "%04d" $NEXT_NUM)

# Create filename
ADR_SLUG=$(echo "${ADR_TITLE}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
ADR_FILE="${ADR_DIR}/ADR-${ADR_NUM}-${ADR_SLUG}.md"

# Convert title to display format
ADR_DISPLAY_TITLE=$(echo "${ADR_TITLE}" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

log_info "Creating ADR-${ADR_NUM}: ${ADR_DISPLAY_TITLE}"

# Create ADR file
cat > "${ADR_FILE}" << EOF
# ADR-${ADR_NUM}: ${ADR_DISPLAY_TITLE}

## Metadata

| Property | Value |
|----------|-------|
| ADR ID | ADR-${ADR_NUM} |
| Status | Proposed |
| Created | ${DATE} |
| Updated | ${DATE} |
| Deciders | [Names/Roles] |
| Consulted | [Stakeholders] |
| Related | |

## Context

### Background

[Describe the situation that led to this decision. What is the problem or opportunity?]

### Driving Forces

- [Force 1]: [Description]
- [Force 2]: [Description]

### Constraints from Constitution

Per \`.boltf/memory/constitution.md\`:
- Tech Stack: [Relevant constraints]
- Principles: [Relevant principles]
- Security: [Relevant requirements]

## Decision Drivers

| Priority | Driver | Description |
|----------|--------|-------------|
| Must | [Driver 1] | [Critical requirement] |
| Should | [Driver 2] | [Important preference] |
| Could | [Driver 3] | [Nice to have] |

## Options Considered

### Option 1: [Option Name]

**Description**: [Brief description]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Effort**: [Low/Medium/High]
**Risk**: [Low/Medium/High]

### Option 2: [Option Name]

**Description**: [Brief description]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Effort**: [Low/Medium/High]
**Risk**: [Low/Medium/High]

### Option 3: [Option Name]

**Description**: [Brief description]

**Pros**:
- [Pro 1]
- [Pro 2]

**Cons**:
- [Con 1]
- [Con 2]

**Effort**: [Low/Medium/High]
**Risk**: [Low/Medium/High]

## Decision Matrix

| Criterion | Weight | Option 1 | Option 2 | Option 3 |
|-----------|--------|----------|----------|----------|
| [Driver 1] | 5 | ? | ? | ? |
| [Driver 2] | 4 | ? | ? | ? |
| [Driver 3] | 3 | ? | ? | ? |
| **Total** | | **?** | **?** | **?** |

## Decision

**Selected Option**: [Option X] - [Option Name]

### Rationale

[Explain why this option was selected]

## Consequences

### Positive

- [Positive consequence 1]
- [Positive consequence 2]

### Negative

- [Negative consequence 1 - with mitigation]
- [Negative consequence 2 - with mitigation]

## Implementation Notes

### Actions Required

1. [ ] [Action 1]
2. [ ] [Action 2]
3. [ ] [Action 3]

## Compliance Check

| Requirement | Status | Notes |
|-------------|--------|-------|
| Constitution Tech Stack | ⬜ | |
| Constitution Principles | ⬜ | |
| Security Policy | ⬜ | |

## References

- [Reference 1]
- [Constitution: .boltf/memory/constitution.md]

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | ${DATE} | [Author] | Initial version |
EOF

# Create or update ADR index
INDEX_FILE="${ADR_DIR}/README.md"

if [ ! -f "${INDEX_FILE}" ]; then
    cat > "${INDEX_FILE}" << 'EOF'
# Architectural Decision Records

This directory contains all ADRs for the project.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
EOF
fi

# Add entry to index
echo "| [ADR-${ADR_NUM}](ADR-${ADR_NUM}-${ADR_SLUG}.md) | ${ADR_DISPLAY_TITLE} | Proposed | ${DATE} |" >> "${INDEX_FILE}"

log_success "ADR created successfully!"
echo ""
echo "Created:"
echo "  - ${ADR_FILE}"
echo "  - Updated ${INDEX_FILE}"
echo ""
echo "Next steps:"
echo "  1. Edit ${ADR_FILE} with decision details"
echo "  2. Fill in options and analysis"
echo "  3. Submit for review"
echo "  4. Update status to 'Accepted' after approval"
