<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Generate Use Cases Script

.DESCRIPTION
    Generates use case document structure from a feature specification.

.PARAMETER FeatureName
    The name of the feature to generate use cases for.

.EXAMPLE
    .\Generate-UseCases.ps1 -FeatureName "user-authentication"
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
$UCDir = "$SpecDir/use-cases"

# Check spec exists
if (-not (Test-Path "$SpecDir/spec.md")) {
    Write-Error "Specification not found: $SpecDir/spec.md"
    Write-Host "Run @Bolt Feature first to create the feature specification"
    exit 1
}

Write-Info "Generating use cases for feature: $FeatureName"

# Create use-cases directory
New-Item -ItemType Directory -Path $UCDir -Force | Out-Null

# Create README
$ReadmeContent = @"
# Use Cases: $FeatureName

This directory contains detailed use case specifications for the $FeatureName feature.

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

Generated from: ``$SpecDir/spec.md``

## Traceability

- User Stories → Use Cases → Gherkin Scenarios → Tests
"@
Set-Content -Path "$UCDir/README.md" -Value $ReadmeContent

# Create template
$TemplateContent = @'
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
'@
Set-Content -Path "$UCDir/UC-001-template.md" -Value $TemplateContent

Write-Success "Use case structure created!"
Write-Host ""
Write-Host "Created:"
Write-Host "  - $UCDir/README.md"
Write-Host "  - $UCDir/UC-001-template.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit UC-001-template.md with first use case"
Write-Host "  2. Duplicate for additional use cases"
Write-Host "  3. Run @Bolt Gherkin to generate BDD scenarios"
