<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Update Agent Context Script

.DESCRIPTION
    Validates and synchronizes relationships between:
    - Prompts (.github/prompts/)
    - Agents (.github/copilot/agents/)
    - Constitution (.boltf/memory/constitution.md)

.PARAMETER Mode
    Operation mode: Check, Report, or Fix

.EXAMPLE
    .\Update-AgentContext.ps1 -Mode Check
    .\Update-AgentContext.ps1 -Mode Report
    .\Update-AgentContext.ps1 -Mode Fix
#>

param(
    [Parameter()]
    [ValidateSet("Check", "Report", "Fix")]
    [string]$Mode = "Check"
)

# =============================================================================
# Configuration
# =============================================================================

$PromptsDir = ".github/prompts"
$AgentsDir = ".github/copilot/agents"
$Constitution = ".boltf/memory/constitution.md"

# Counters
$script:Errors = 0
$script:Warnings = 0
$script:Passed = 0

# =============================================================================
# Helper Functions
# =============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] " -ForegroundColor Green -NoNewline
    Write-Host $Message
    $script:Passed++
}

function Write-WarningCustom {
    param([string]$Message)
    Write-Host "[⚠] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
    $script:Warnings++
}

function Write-ErrorCustom {
    param([string]$Message)
    Write-Host "[✗] " -ForegroundColor Red -NoNewline
    Write-Host $Message
    $script:Errors++
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("━" * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("━" * 60) -ForegroundColor Cyan
}

# =============================================================================
# Validation Functions
# =============================================================================

function Test-ConstitutionExists {
    Write-Header "Checking Constitution"

    if (Test-Path $Constitution) {
        Write-Success "Constitution exists: $Constitution"

        $content = Get-Content $Constitution -Raw -ErrorAction SilentlyContinue

        # Check required sections
        $requiredSections = @("Tech Stack", "Architecture", "Standards", "Security")
        foreach ($section in $requiredSections) {
            if ($content -match $section) {
                Write-Success "Constitution has section: $section"
            } else {
                Write-WarningCustom "Constitution missing section: $section"
            }
        }
    } else {
        Write-ErrorCustom "Constitution not found: $Constitution"
        Write-Host "       Use: @Bolt Constitution to create it" -ForegroundColor Gray
    }
}

function Test-AgentsHaveConstitutionReference {
    Write-Header "Checking Agents → Constitution Reference"

    if (-not (Test-Path $AgentsDir)) {
        Write-ErrorCustom "Agents directory not found: $AgentsDir"
        return
    }

    $agentFiles = Get-ChildItem -Path $AgentsDir -Filter "*.md" |
                  Where-Object { $_.Name -ne "README.md" }

    foreach ($agentFile in $agentFiles) {
        $content = Get-Content $agentFile.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "Constitution Reference") {
            Write-Success "Agent has Constitution Reference: $($agentFile.Name)"
        } else {
            Write-ErrorCustom "Agent missing Constitution Reference: $($agentFile.Name)"
        }

        if ($content -match "memory/constitution\.md") {
            Write-Success "Agent references constitution path: $($agentFile.Name)"
        } else {
            Write-WarningCustom "Agent doesn't reference constitution path: $($agentFile.Name)"
        }
    }
}

function Test-PromptsHaveAgentReference {
    Write-Header "Checking Prompts → Agent Reference"

    if (-not (Test-Path $PromptsDir)) {
        Write-ErrorCustom "Prompts directory not found: $PromptsDir"
        return
    }

    $promptFiles = Get-ChildItem -Path $PromptsDir -Filter "*.prompt.md"

    foreach ($promptFile in $promptFiles) {
        $content = Get-Content $promptFile.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "Agent Reference") {
            Write-Success "Prompt has Agent Reference: $($promptFile.Name)"
        } else {
            Write-ErrorCustom "Prompt missing Agent Reference: $($promptFile.Name)"
        }

        # Check if prompt links to an agent file
        if ($content -match "\.\./(copilot/)?agents/") {
            Write-Success "Prompt links to agent: $($promptFile.Name)"

            # Extract and verify agent links
            $agentLinks = [regex]::Matches($content, '\.\./(copilot/)?agents/([a-z-]+)\.md') |
                          ForEach-Object { $_.Groups[2].Value } |
                          Select-Object -Unique

            foreach ($agentLink in $agentLinks) {
                $agentPath = Join-Path $AgentsDir "$agentLink.md"
                if (Test-Path $agentPath) {
                    Write-Success "  → Linked agent exists: $agentLink.md"
                } else {
                    Write-ErrorCustom "  → Linked agent NOT FOUND: $agentLink.md"
                }
            }
        } else {
            Write-WarningCustom "Prompt doesn't link to any agent: $($promptFile.Name)"
        }

        # Check if prompt references Constitution
        if ($content -match "constitution\.md|Constitution") {
            Write-Success "Prompt references Constitution: $($promptFile.Name)"
        } else {
            Write-WarningCustom "Prompt doesn't reference Constitution: $($promptFile.Name)"
        }
    }
}

function Test-AgentPromptCoverage {
    Write-Header "Checking Agent ↔ Prompt Coverage"

    # Get list of agents (excluding README)
    $agents = Get-ChildItem -Path $AgentsDir -Filter "*.md" |
              Where-Object { $_.Name -ne "README.md" } |
              ForEach-Object { $_.BaseName }

    # Get list of prompts
    $prompts = Get-ChildItem -Path $PromptsDir -Filter "*.prompt.md" |
               ForEach-Object { $_.BaseName -replace '\.prompt$', '' }

    Write-Info "Found $($agents.Count) agents and $($prompts.Count) prompts"

    Write-Host ""
    Write-Info "Agent coverage analysis:"

    $coveredAgents = @()
    $uncoveredAgents = @()

    foreach ($agent in $agents) {
        $isCovered = $false

        $promptFiles = Get-ChildItem -Path $PromptsDir -Filter "*.prompt.md"
        foreach ($promptFile in $promptFiles) {
            $content = Get-Content $promptFile.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match "$agent\.md") {
                $isCovered = $true
                break
            }
        }

        if ($isCovered) {
            $coveredAgents += $agent
            Write-Success "Agent covered by prompt: $agent"
        } else {
            $uncoveredAgents += $agent
            Write-WarningCustom "Agent NOT covered by any prompt: $agent"
        }
    }

    Write-Host ""
    $coverage = [math]::Round(($coveredAgents.Count / $agents.Count) * 100)
    Write-Info "Coverage: $($coveredAgents.Count)/$($agents.Count) agents ($coverage%)"
}

function Get-MappingReport {
    Write-Header "Generating Prompt → Agent Mapping"

    Write-Host ""
    Write-Host ("{0,-35} {1,-40}" -f "PROMPT", "AGENT(S)")
    Write-Host ("─" * 75)

    $promptFiles = Get-ChildItem -Path $PromptsDir -Filter "*.prompt.md"

    foreach ($promptFile in $promptFiles) {
        $content = Get-Content $promptFile.FullName -Raw -ErrorAction SilentlyContinue
        $promptName = $promptFile.BaseName -replace '\.prompt$', ''

        $agentLinks = [regex]::Matches($content, '\.\./(copilot/)?agents/([a-z-]+)\.md') |
                      ForEach-Object { $_.Groups[2].Value } |
                      Select-Object -Unique

        if ($agentLinks) {
            $agentsStr = $agentLinks -join ", "
            Write-Host ("{0,-35} " -f $promptName) -NoNewline
            Write-Host $agentsStr -ForegroundColor Green
        } else {
            Write-Host ("{0,-35} " -f $promptName) -NoNewline
            Write-Host "(none)" -ForegroundColor Yellow
        }
    }
}

function Get-ConstitutionTechStack {
    Write-Header "Checking Constitution Tech Stack"

    if (-not (Test-Path $Constitution)) {
        Write-WarningCustom "Cannot check tech stack - Constitution not found"
        return
    }

    Write-Info "Tech stack defined in Constitution:"

    $content = Get-Content $Constitution -Raw -ErrorAction SilentlyContinue

    $techs = @("\.NET", "React", "Angular", "Vue", "Node", "Python", "Go", "Java", "TypeScript",
               "PostgreSQL", "MySQL", "MongoDB", "Redis", "Azure", "AWS", "GCP", "Kubernetes", "Docker")

    foreach ($tech in $techs) {
        if ($content -match $tech) {
            $displayTech = $tech -replace '\\', ''
            Write-Host "  • $displayTech" -ForegroundColor Green
        }
    }
}

# =============================================================================
# Fix Functions
# =============================================================================

function Repair-MissingConstitutionReference {
    Write-Header "Fixing Missing Constitution References"

    $agentFiles = Get-ChildItem -Path $AgentsDir -Filter "*.md" |
                  Where-Object { $_.Name -ne "README.md" }

    foreach ($agentFile in $agentFiles) {
        $content = Get-Content $agentFile.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -notmatch "Constitution Reference") {
            Write-WarningCustom "Would add Constitution Reference to: $($agentFile.Name)"
        }
    }

    Write-Info "Fix mode shows what would be changed. Manual review recommended."
}

# =============================================================================
# Summary
# =============================================================================

function Write-Summary {
    Write-Header "Summary"

    Write-Host ""
    Write-Host "  Passed:   " -NoNewline
    Write-Host $script:Passed -ForegroundColor Green
    Write-Host "  Warnings: " -NoNewline
    Write-Host $script:Warnings -ForegroundColor Yellow
    Write-Host "  Errors:   " -NoNewline
    Write-Host $script:Errors -ForegroundColor Red
    Write-Host ""

    if ($script:Errors -gt 0) {
        Write-Host ("━" * 60) -ForegroundColor Red
        Write-Host "  VALIDATION FAILED - Please fix errors above" -ForegroundColor Red
        Write-Host ("━" * 60) -ForegroundColor Red
        exit 1
    } elseif ($script:Warnings -gt 0) {
        Write-Host ("━" * 60) -ForegroundColor Yellow
        Write-Host "  VALIDATION PASSED WITH WARNINGS" -ForegroundColor Yellow
        Write-Host ("━" * 60) -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host ("━" * 60) -ForegroundColor Green
        Write-Host "  ALL VALIDATIONS PASSED" -ForegroundColor Green
        Write-Host ("━" * 60) -ForegroundColor Green
        exit 0
    }
}

# =============================================================================
# Main
# =============================================================================

function Main {
    Write-Host ""
    Write-Host ("╔" + ("═" * 62) + "╗") -ForegroundColor Cyan
    Write-Host "║     Bolt Framework / AI-DLC - Agent Context Validator       ║" -ForegroundColor Cyan
    Write-Host ("║     Mode: $Mode" + (" " * (51 - $Mode.Length)) + "║") -ForegroundColor Cyan
    Write-Host ("╚" + ("═" * 62) + "╝") -ForegroundColor Cyan

    switch ($Mode) {
        "Check" {
            Test-ConstitutionExists
            Test-AgentsHaveConstitutionReference
            Test-PromptsHaveAgentReference
            Test-AgentPromptCoverage
        }
        "Report" {
            Test-ConstitutionExists
            Get-ConstitutionTechStack
            Test-AgentsHaveConstitutionReference
            Test-PromptsHaveAgentReference
            Test-AgentPromptCoverage
            Get-MappingReport
        }
        "Fix" {
            Test-ConstitutionExists
            Test-AgentsHaveConstitutionReference
            Repair-MissingConstitutionReference
            Test-PromptsHaveAgentReference
        }
    }

    Write-Summary
}

Main
