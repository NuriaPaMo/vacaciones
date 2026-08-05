#!/bin/bash
# =============================================================================
# Bolt Framework / AI-DLC - Generate Gherkin Script
# =============================================================================
# Generates Gherkin feature file structure from specifications.
#
# Usage:
#   ./generate-gherkin.sh <feature-name>
#
# Example:
#   ./generate-gherkin.sh user-authentication
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
TEST_DIR="${SPEC_DIR}/tests/features"

# Check spec exists
if [ ! -f "${SPEC_DIR}/spec.md" ]; then
    log_error "Specification not found: ${SPEC_DIR}/spec.md"
    exit 1
fi

log_info "Generating Gherkin scenarios for: ${FEATURE_NAME}"

# Create test directory structure
mkdir -p "${TEST_DIR}/support"

# Detect testing framework from constitution
FRAMEWORK="cucumber"
if [ -f ".boltf/memory/constitution.md" ]; then
    if grep -qi "specflow" ".boltf/memory/constitution.md"; then
        FRAMEWORK="specflow"
    elif grep -qi "pytest-bdd" ".boltf/memory/constitution.md"; then
        FRAMEWORK="pytest-bdd"
    elif grep -qi "behave" ".boltf/memory/constitution.md"; then
        FRAMEWORK="behave"
    fi
fi

log_info "Detected framework: ${FRAMEWORK}"

# Convert feature name to title case
FEATURE_TITLE=$(echo "${FEATURE_NAME}" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

# Create feature file template
cat > "${TEST_DIR}/${FEATURE_NAME}.feature" << EOF
# language: en
@${FEATURE_NAME}
Feature: ${FEATURE_TITLE}
  As a [role from user story]
  I want [capability]
  So that [benefit]

  # Specification: ${SPEC_DIR}/spec.md
  # Generated: $(date +%Y-%m-%d)

  Background:
    Given the system is initialized
    And I am authenticated as a valid user

  # ============================================
  # User Story: US-001 - [Story Title]
  # ============================================

  @US-001 @AC-001.1 @happy-path
  Scenario: Successfully perform main action
    Given the required preconditions are met
    When I perform the main action
    Then the action should be completed successfully
    And I should see a confirmation message

  @US-001 @AC-001.2 @validation
  Scenario: Reject action with invalid input
    Given the required preconditions are met
    When I perform the action with invalid data
    Then I should see an error message
    And the action should not be completed

  @US-001 @AC-001.3 @edge-case
  Scenario Outline: Handle action with various inputs
    Given the required preconditions are met
    When I perform the action with <input>
    Then the result should be <expected>

    Examples:
      | input        | expected |
      | valid_min    | success  |
      | valid_max    | success  |
      | invalid      | error    |

  # ============================================
  # Add more scenarios for additional user stories
  # ============================================
EOF

# Create support README
cat > "${TEST_DIR}/support/README.md" << EOF
# Step Definitions

This directory contains step definition files for Gherkin scenarios.

## Framework: ${FRAMEWORK}

## File Structure

EOF

case $FRAMEWORK in
    specflow)
        cat >> "${TEST_DIR}/support/README.md" << 'EOF'
```
support/
├── Steps/
│   ├── CommonSteps.cs
│   └── [Feature]Steps.cs
└── Hooks/
    └── Hooks.cs
```

## Example Step Definition (C#)

```csharp
[Binding]
public class CommonSteps
{
    [Given(@"the system is initialized")]
    public void GivenTheSystemIsInitialized()
    {
        // Setup code
    }

    [When(@"I perform the main action")]
    public void WhenIPerformTheMainAction()
    {
        // Action code
    }

    [Then(@"the action should be completed successfully")]
    public void ThenTheActionShouldBeCompletedSuccessfully()
    {
        // Assertion code
    }
}
```
EOF
        ;;
    pytest-bdd)
        cat >> "${TEST_DIR}/support/README.md" << 'EOF'
```
support/
├── conftest.py
├── step_defs/
│   ├── __init__.py
│   ├── common_steps.py
│   └── [feature]_steps.py
└── fixtures.py
```

## Example Step Definition (Python)

```python
from pytest_bdd import given, when, then, parsers

@given("the system is initialized")
def system_initialized():
    # Setup code
    pass

@when("I perform the main action")
def perform_action():
    # Action code
    pass

@then("the action should be completed successfully")
def action_completed():
    # Assertion code
    pass
```
EOF
        ;;
    *)
        cat >> "${TEST_DIR}/support/README.md" << 'EOF'
```
support/
├── world.js
├── hooks.js
└── steps/
    ├── common.steps.js
    └── [feature].steps.js
```

## Example Step Definition (JavaScript)

```javascript
const { Given, When, Then } = require('@cucumber/cucumber');

Given('the system is initialized', async function() {
    // Setup code
});

When('I perform the main action', async function() {
    // Action code
});

Then('the action should be completed successfully', async function() {
    // Assertion code
});
```
EOF
        ;;
esac

# Create tests README
cat > "${SPEC_DIR}/tests/README.md" << EOF
# Tests: ${FEATURE_TITLE}

## Structure

\`\`\`
tests/
├── features/
│   ├── ${FEATURE_NAME}.feature    # BDD scenarios
│   └── support/                    # Step definitions
├── unit/                           # Unit tests
├── integration/                    # Integration tests
└── README.md
\`\`\`

## Running Tests

### BDD Tests
\`\`\`bash
# Run all feature tests
npm run test:bdd

# Run specific feature
npm run test:bdd -- --tags @${FEATURE_NAME}

# Run by priority
npm run test:bdd -- --tags @P1
\`\`\`

## Coverage

| Type | Target | Actual |
|------|--------|--------|
| Scenarios | 100% AC | TBD |
| Step Defs | 100% | TBD |

## Traceability

Scenarios are tagged with:
- \`@US-XXX\` - User story reference
- \`@AC-XXX.X\` - Acceptance criteria reference
- \`@happy-path\`, \`@validation\`, \`@edge-case\` - Test type
EOF

log_success "Gherkin structure created!"
echo ""
echo "Created:"
echo "  - ${TEST_DIR}/${FEATURE_NAME}.feature"
echo "  - ${TEST_DIR}/support/README.md"
echo "  - ${SPEC_DIR}/tests/README.md"
echo ""
echo "Framework detected: ${FRAMEWORK}"
echo ""
echo "Next steps:"
echo "  1. Edit ${FEATURE_NAME}.feature with specific scenarios"
echo "  2. Implement step definitions in support/"
echo "  3. Run tests: npm run test:bdd"
