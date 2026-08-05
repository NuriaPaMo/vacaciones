
<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Generate Gherkin Script

.DESCRIPTION
    Generates Gherkin feature file structure from specifications.

.PARAMETER FeatureName
    The name of the feature to generate Gherkin scenarios for.

.EXAMPLE
    .\Generate-Gherkin.ps1 -FeatureName "user-authentication"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureName
)

# Helper functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

$SpecDir = "specs/$FeatureName"
$TestDir = "$SpecDir/tests/features"

# Check spec exists
if (-not (Test-Path "$SpecDir/spec.md")) {
    Write-Error "Specification not found: $SpecDir/spec.md"
    exit 1
}

Write-Info "Generating Gherkin scenarios for: $FeatureName"

# Create test directory structure
New-Item -ItemType Directory -Path "$TestDir/support" -Force | Out-Null

# Detect testing framework from constitution
$Framework = "cucumber"
if (Test-Path ".boltf/memory/constitution.md") {
    $ConstitutionContent = Get-Content ".boltf/memory/constitution.md" -Raw
    if ($ConstitutionContent -match "specflow") { $Framework = "specflow" }
    elseif ($ConstitutionContent -match "pytest-bdd") { $Framework = "pytest-bdd" }
    elseif ($ConstitutionContent -match "behave") { $Framework = "behave" }
}

Write-Info "Detected framework: $Framework"

# Convert feature name to title
$FeatureTitle = (Get-Culture).TextInfo.ToTitleCase($FeatureName -replace '-', ' ')
$Date = Get-Date -Format "yyyy-MM-dd"

# Create feature file
$FeatureContent = @"
# language: en
@$FeatureName
Feature: $FeatureTitle
  As a [role from user story]
  I want [capability]
  So that [benefit]

  # Specification: $SpecDir/spec.md
  # Generated: $Date

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
"@
Set-Content -Path "$TestDir/$FeatureName.feature" -Value $FeatureContent

# Create support README based on framework
$SupportReadme = @"
# Step Definitions

This directory contains step definition files for Gherkin scenarios.

## Framework: $Framework

## File Structure

"@

switch ($Framework) {
    "specflow" {
        $SupportReadme += @'

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
'@
    }
    "pytest-bdd" {
        $SupportReadme += @'

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
    pass

@when("I perform the main action")
def perform_action():
    pass

@then("the action should be completed successfully")
def action_completed():
    pass
```
'@
    }
    default {
        $SupportReadme += @'

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
'@
    }
}

Set-Content -Path "$TestDir/support/README.md" -Value $SupportReadme

# Create tests README
$TestsReadme = @"
# Tests: $FeatureTitle

## Structure

``````
tests/
├── features/
│   ├── $FeatureName.feature    # BDD scenarios
│   └── support/                    # Step definitions
├── unit/                           # Unit tests
├── integration/                    # Integration tests
└── README.md
``````

## Running Tests

### BDD Tests
``````bash
# Run all feature tests
npm run test:bdd

# Run specific feature
npm run test:bdd -- --tags @$FeatureName

# Run by priority
npm run test:bdd -- --tags @P1
``````

## Traceability

Scenarios are tagged with:
- ``@US-XXX`` - User story reference
- ``@AC-XXX.X`` - Acceptance criteria reference
"@
Set-Content -Path "$SpecDir/tests/README.md" -Value $TestsReadme

Write-Success "Gherkin structure created!"
Write-Host ""
Write-Host "Created:"
Write-Host "  - $TestDir/$FeatureName.feature"
Write-Host "  - $TestDir/support/README.md"
Write-Host "  - $SpecDir/tests/README.md"
Write-Host ""
Write-Host "Framework detected: $Framework"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit $FeatureName.feature with specific scenarios"
Write-Host "  2. Implement step definitions in support/"
Write-Host "  3. Run tests"
