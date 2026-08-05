<#
.SYNOPSIS
    Bolt Framework / AI-DLC - Validate Specifications Script

.DESCRIPTION
    Validates specification files for completeness and consistency.

.PARAMETER Check
    Run validation checks.

.PARAMETER BranchName
    Specific branch/feature to validate (optional).

.EXAMPLE
    .\Validate-Specs.ps1 -Check

.EXAMPLE
    .\Validate-Specs.ps1 -Check -BranchName "user-authentication"
#>

param(
    [switch]$Check,
    [string]$BranchName
)

# Track results
$Script:Errors = 0
$Script:Warnings = 0

# Helper functions
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Warn {
    Write-Host "[⚠] $args" -ForegroundColor Yellow
    $Script:Warnings++
}
function Write-Err {
    Write-Host "[✗] $args" -ForegroundColor Red
    $Script:Errors++
}
function Write-Section {
    Write-Host ""
    Write-Host "────────────────────────────────────────" -ForegroundColor Blue
    Write-Host "  $args" -ForegroundColor Blue
    Write-Host "────────────────────────────────────────" -ForegroundColor Blue
}

# Determine spec directories to check
if ($BranchName) {
    $SpecDirs = @("specs/$BranchName")
} else {
    $SpecDirs = Get-ChildItem -Path "specs" -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
}

Write-Info "Validating specifications..."

# =============================================================================
# Validate Constitution
# =============================================================================
Write-Section "Constitution"

if (Test-Path ".boltf/memory/constitution.md") {
    Write-Success "Constitution exists"

    $ConstitutionContent = Get-Content ".boltf/memory/constitution.md" -Raw

    $RequiredSections = @("Tech Stack", "Architectural Principles", "Development Standards")

    foreach ($section in $RequiredSections) {
        if ($ConstitutionContent -match $section) {
            Write-Success "Section found: $section"
        } else {
            Write-Warn "Section missing: $section"
        }
    }
} else {
    Write-Err "Constitution not found at .boltf/memory/constitution.md"
    Write-Info "Use @Bolt Setup or @Bolt Constitution to create it"
}

# =============================================================================
# Validate Each Spec Directory
# =============================================================================
foreach ($SpecDir in $SpecDirs) {
    if (-not (Test-Path $SpecDir)) {
        continue
    }

    $FeatureName = Split-Path $SpecDir -Leaf
    Write-Section "Feature: $FeatureName"

    # Check spec.md
    $SpecFile = Join-Path $SpecDir "spec.md"
    if (Test-Path $SpecFile) {
        Write-Success "spec.md exists"

        $SpecContent = Get-Content $SpecFile -Raw

        # Check for user stories
        $USMatches = [regex]::Matches($SpecContent, "^### US-", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $USCount = $USMatches.Count
        if ($USCount -gt 0) {
            Write-Success "User stories found: $USCount"
        } else {
            Write-Warn "No user stories found (expected ### US-XXX format)"
        }

        # Check for acceptance criteria
        $ACMatches = [regex]::Matches($SpecContent, "AC\d+:")
        $ACCount = $ACMatches.Count
        if ($ACCount -gt 0) {
            Write-Success "Acceptance criteria found: $ACCount"
        } else {
            Write-Warn "No acceptance criteria found"
        }

        # Check for unchecked open questions
        $OpenQuestions = [regex]::Matches($SpecContent, "^- \[ \]", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($OpenQuestions.Count -gt 0) {
            Write-Warn "Open questions remaining: $($OpenQuestions.Count)"
        }
    } else {
        Write-Err "spec.md not found"
    }

    # Check plan.md
    $PlanFile = Join-Path $SpecDir "plan.md"
    if (Test-Path $PlanFile) {
        Write-Success "plan.md exists"

        $PlanContent = Get-Content $PlanFile -Raw

        # Check for bolts
        $BoltMatches = [regex]::Matches($PlanContent, "^## Bolt", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $BoltCount = $BoltMatches.Count
        if ($BoltCount -gt 0) {
            Write-Success "Bolts defined: $BoltCount"
        } else {
            Write-Warn "No bolts defined (expected ## Bolt X format)"
        }
    } else {
        Write-Warn "plan.md not found (use @Bolt Plan)"
    }

    # Check tasks.md
    $TasksFile = Join-Path $SpecDir "tasks.md"
    if (Test-Path $TasksFile) {
        Write-Success "tasks.md exists"

        $TasksContent = Get-Content $TasksFile -Raw

        # Count tasks
        $TotalTasks = [regex]::Matches($TasksContent, "^- \[", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $CompletedTasks = [regex]::Matches($TasksContent, "^- \[x\]", [System.Text.RegularExpressions.RegexOptions]::Multiline)

        Write-Info "Task progress: $($CompletedTasks.Count)/$($TotalTasks.Count)"
    } else {
        Write-Warn "tasks.md not found (use @Bolt Tasks)"
    }

    # Check data-model.md
    $DataModelFile = Join-Path $SpecDir "data-model.md"
    if (Test-Path $DataModelFile) {
        Write-Success "data-model.md exists"

        $DataModelContent = Get-Content $DataModelFile -Raw

        # Check for entities
        $EntityMatches = [regex]::Matches($DataModelContent, "^### ", [System.Text.RegularExpressions.RegexOptions]::Multiline)
        if ($EntityMatches.Count -gt 0) {
            Write-Success "Entities defined: $($EntityMatches.Count)"
        }
    }

    # Check contracts directory
    $ContractsDir = Join-Path $SpecDir "contracts"
    if (Test-Path $ContractsDir) {
        $Contracts = Get-ChildItem -Path $ContractsDir -Filter "*.yaml" -ErrorAction SilentlyContinue
        $Contracts += Get-ChildItem -Path $ContractsDir -Filter "*.yml" -ErrorAction SilentlyContinue

        if ($Contracts.Count -gt 0) {
            Write-Success "API contracts found: $($Contracts.Count)"
        } else {
            Write-Warn "contracts/ directory exists but no .yaml files"
        }
    }
}

# =============================================================================
# Cross-Reference Validation
# =============================================================================
Write-Section "Cross-Reference Check"

foreach ($SpecDir in $SpecDirs) {
    if (-not (Test-Path $SpecDir)) {
        continue
    }

    $SpecFile = Join-Path $SpecDir "spec.md"
    $TasksFile = Join-Path $SpecDir "tasks.md"

    if ((Test-Path $SpecFile) -and (Test-Path $TasksFile)) {
        $SpecContent = Get-Content $SpecFile -Raw
        $TasksContent = Get-Content $TasksFile -Raw

        # Extract user story IDs from spec
        $USMatches = [regex]::Matches($SpecContent, "US-\d+")
        $USIds = $USMatches.Value | Select-Object -Unique

        foreach ($USId in $USIds) {
            if ($TasksContent -match "\[$USId\]") {
                Write-Success "$USId has corresponding tasks"
            } else {
                Write-Warn "$USId has no corresponding tasks"
            }
        }
    }
}

# =============================================================================
# Summary
# =============================================================================
Write-Section "Validation Summary"

Write-Host ""
Write-Host "  Errors:   $Script:Errors" -ForegroundColor Red
Write-Host "  Warnings: $Script:Warnings" -ForegroundColor Yellow
Write-Host ""

if ($Script:Errors -gt 0) {
    Write-Host "[ERROR] Validation FAILED with $Script:Errors error(s)" -ForegroundColor Red
    exit 1
} elseif ($Script:Warnings -gt 0) {
    Write-Host "[WARNING] Validation passed with $Script:Warnings warning(s)" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "[SUCCESS] Validation PASSED" -ForegroundColor Green
    exit 0
}
