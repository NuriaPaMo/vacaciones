<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Create ADR Script

.DESCRIPTION
    Creates a new Architectural Decision Record from template.
    Follows MADR format as defined in skill-bolt-adr.

    Reference: .claude/skills/skill-bolt-adr/SKILL.md
    Templates: .claude/skills/skill-bolt-adr/templates/
    The title of the ADR decision.

.EXAMPLE
    .\Create-ADR.ps1 -Title "database-selection"
    .\Create-ADR.ps1 -Title "authentication-strategy"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Title
)

# Helper functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

$ADRDir = "docs/adr"
$Date = Get-Date -Format "yyyy-MM-dd"

# Create ADR directory if not exists
New-Item -ItemType Directory -Path $ADRDir -Force | Out-Null

# Find next ADR number
$ExistingADRs = Get-ChildItem -Path $ADRDir -Filter "ADR-*.md" -ErrorAction SilentlyContinue
$LastNum = 0
foreach ($adr in $ExistingADRs) {
    if ($adr.Name -match "ADR-(\d+)") {
        $num = [int]$Matches[1]
        if ($num -gt $LastNum) { $LastNum = $num }
    }
}
$NextNum = $LastNum + 1
$ADRNum = "{0:D4}" -f $NextNum

# Create slug and filename
$ADRSlug = $Title.ToLower() -replace ' ', '-' -replace '[^a-z0-9-]', ''
$ADRFile = "$ADRDir/ADR-$ADRNum-$ADRSlug.md"

# Convert title to display format
$ADRDisplayTitle = (Get-Culture).TextInfo.ToTitleCase($Title -replace '-', ' ')

Write-Info "Creating ADR-$ADRNum`: $ADRDisplayTitle"

# Create ADR content
$ADRContent = @"
# ADR-$ADRNum`: $ADRDisplayTitle

## Metadata

| Property | Value |
|----------|-------|
| ADR ID | ADR-$ADRNum |
| Status | Proposed |
| Created | $Date |
| Updated | $Date |
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

Per ```.boltf/memory/constitution.md```:
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
| Constitution Tech Stack | :white_large_square: | |
| Constitution Principles | :white_large_square: | |
| Security Policy | :white_large_square: | |

## References

- [Reference 1]
- [Constitution: .boltf/memory/constitution.md]

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | $Date | [Author] | Initial version |
"@

Set-Content -Path $ADRFile -Value $ADRContent

# Create or update index
$IndexFile = "$ADRDir/README.md"

if (-not (Test-Path $IndexFile)) {
    $IndexContent = @"
# Architectural Decision Records

This directory contains all ADRs for the project.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
"@
    Set-Content -Path $IndexFile -Value $IndexContent
}

# Add entry to index
Add-Content -Path $IndexFile -Value "| [ADR-$ADRNum](ADR-$ADRNum-$ADRSlug.md) | $ADRDisplayTitle | Proposed | $Date |"

Write-Success "ADR created successfully!"
Write-Host ""
Write-Host "Created:"
Write-Host "  - $ADRFile"
Write-Host "  - Updated $IndexFile"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit $ADRFile with decision details"
Write-Host "  2. Fill in options and analysis"
Write-Host "  3. Submit for review"
Write-Host "  4. Update status to 'Accepted' after approval"
