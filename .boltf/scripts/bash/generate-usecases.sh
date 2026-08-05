#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Generate Use Cases Script
# =============================================================================
# Generates use case document structure from a feature specification.
#
# Usage:
#   ./generate-usecases.sh <feature-name>
#
# Example:
#   ./generate-usecases.sh user-authentication
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
    log_error "Feature name is required"
    echo "Usage: $0 <feature-name>"
    exit 1
fi

FEATURE_NAME="$1"
SPEC_DIR="specs/${FEATURE_NAME}"
UC_DIR="${SPEC_DIR}/use-cases"

# Check spec exists
if [ ! -f "${SPEC_DIR}/spec.md" ]; then
    log_error "Specification not found: ${SPEC_DIR}/spec.md"
    echo "Run /bolt.feature first to create the feature specification"
    exit 1
fi

log_info "Generating use cases for feature: ${FEATURE_NAME}"

# Create use-cases directory
mkdir -p "${UC_DIR}"

# Count user stories
US_COUNT=$(grep -c "^### US-" "${SPEC_DIR}/spec.md" 2>/dev/null || echo "0")
log_info "Found ${US_COUNT} user stories"

# Create README for use cases
cat > "${UC_DIR}/README.md" << EOF
# Use Cases: ${FEATURE_NAME}

This directory contains detailed use case specifications for the ${FEATURE_NAME} feature.

## Use Case Index

| UC ID | Title | User Story | Status |
|-------|-------|------------|--------|
| UC-001 | [Title] | US-001 | Draft |

## Structure

Each use case follows the Cockburn/UML format:
- Metadata
- Stakeholders and Interests
- Preconditions / Postconditions
- Main Success Scenario
- Extensions (Alternative Flows)
- Business Rules

## Generation

Generated from: \`${SPEC_DIR}/spec.md\`

## Traceability

- User Stories → Use Cases → Gherkin Scenarios → Tests
EOF

# Create template use case
cat > "${UC_DIR}/UC-001-template.md" << 'EOF'
# Use Case: [Use Case Title]

## Metadata

| Property | Value |
|----------|-------|
| UC ID | UC-001 |
| User Story | US-001 |
| Primary Actor | [Actor] |
| Scope | System |
| Level | User Goal |
| Status | Draft |

## Brief Description

[One paragraph summary]

## Preconditions

1. [Condition that must be true]

## Postconditions (Success Guarantees)

1. [State after completion]

## Triggers

- [Event that initiates]

## Main Success Scenario

| Step | Actor | System |
|------|-------|--------|
| 1 | [Action] | |
| 2 | | [Response] |
| 3 | [Action] | |
| 4 | | [Validates] |
| 5 | | [Confirms] |

## Extensions

### 2a. Validation Fails

| Step | Actor | System |
|------|-------|--------|
| 2a.1 | | Returns error |
| 2a.2 | Reviews error | |

## Business Rules Applied

| Rule ID | Description |
|---------|-------------|
| BR-001 | [Rule] |

## Related Use Cases

| UC ID | Relationship |
|-------|--------------|
| UC-002 | [Relationship] |
EOF

log_success "Use case structure created!"
echo ""
echo "Created:"
echo "  - ${UC_DIR}/README.md"
echo "  - ${UC_DIR}/UC-001-template.md"
echo ""
echo "Next steps:"
echo "  1. Edit UC-001-template.md with first use case"
echo "  2. Duplicate for additional use cases"
echo "  3. Run /bolt.gherkin to generate BDD scenarios"
