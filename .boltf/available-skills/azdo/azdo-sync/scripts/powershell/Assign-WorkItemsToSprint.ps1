<#
.SYNOPSIS
    Assign work items to a specific sprint/iteration

.DESCRIPTION
    This script assigns a range of work items to a specified iteration path in Azure DevOps.
    It handles the correct iteration path format required by Azure DevOps.

.PARAMETER StartId
    First work item ID to process

.PARAMETER EndId
    Last work item ID to process

.PARAMETER SprintNumber
    Sprint number (0, 1, 2, etc.)

.PARAMETER DryRun
    Preview changes without applying them

.EXAMPLE
    .\Assign-WorkItemsToSprint.ps1 -StartId 31530 -EndId 31604 -SprintNumber 1 -DryRun
    Preview sprint assignment for Feature 008

.EXAMPLE
    .\Assign-WorkItemsToSprint.ps1 -StartId 31530 -EndId 31604 -SprintNumber 1
    Assign Feature 008 work items to Sprint 1

.NOTES
    Requires:
    - Azure DevOps CLI (az devops)
    - AZURE_DEVOPS_EXT_PAT environment variable set
    - Iteration/Sprint must exist in Azure DevOps
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$StartId,

    [Parameter(Mandatory = $true)]
    [int]$EndId,

    [Parameter(Mandatory = $true)]
    [int]$SprintNumber,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load shared environment (reads .env, builds $script:Config, validates PAT)
. "$PSScriptRoot\_EnvLoader.ps1"

# =============================================================================
# Helper Functions
# =============================================================================

function Get-IterationPath {
    param([int]$SprintNum)
    
    # Construct iteration path based on Azure DevOps project structure
    # IMPORTANT: System.IterationPath does NOT include the \Iteration\ segment.
    # The classification tree path is "\Project\Iteration\Sprint N" but the field value is "Project\Sprint N"
    # Correct: "Registro Horario\Sprint N"
    # Wrong:   "Registro Horario\Iteration\Sprint N" (causes TF401347)
    $iterationPath = "$($script:Config.Project)\Sprint $SprintNum"
    
    Write-StatusMessage "Using iteration path: $iterationPath" -Type Info
    
    # Verify the iteration exists by querying
    try {
        Write-Host "  Verifying Sprint $SprintNum exists..." -ForegroundColor Gray
        
        $iterations = az boards iteration project list --project $script:Config.Project --output json 2>&1
        if ($LASTEXITCODE -eq 0) {
            $iterationsObj = $iterations | ConvertFrom-Json
            $sprint = $iterationsObj | Where-Object { $_.name -eq "Sprint $SprintNum" }
            
            if ($sprint) {
                Write-StatusMessage "Sprint $SprintNum verified (ID: $($sprint.id))" -Type Success
            } else {
                Write-StatusMessage "Warning: Could not verify Sprint $SprintNum exists" -Type Warning
                Write-Host "  Continuing anyway with path: $iterationPath" -ForegroundColor Yellow
            }
        } else {
            Write-StatusMessage "Warning: Could not query iterations to verify" -Type Warning
            Write-Host "  Continuing anyway with path: $iterationPath" -ForegroundColor Yellow
        }
    }
    catch {
        Write-StatusMessage "Warning: Verification failed: $($_.Exception.Message)" -Type Warning
        Write-Host "  Continuing anyway with path: $iterationPath" -ForegroundColor Yellow
    }
    
    return $iterationPath
}

function Set-WorkItemIteration {
    param(
        [int]$Id,
        [string]$IterationPath
    )
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would assign #$Id to: $IterationPath" -ForegroundColor Magenta
        return $true
    }
    
    try {
        $result = az boards work-item update `
            --id $Id `
            --iteration $IterationPath `
            --output none 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Failed to assign #$Id to iteration (Exit code: $LASTEXITCODE)" -Type Error
            if ($result) {
                Write-Host "  Error: $result" -ForegroundColor DarkRed
            }
            return $false
        }
        
        return $true
    }
    catch {
        Write-StatusMessage "Exception assigning #${Id} to iteration: $($_.Exception.Message)" -Type Error
        return $false
    }
}

# =============================================================================
# Main Processing
# =============================================================================

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║                   Assign Work Items to Sprint                             ║
║                                                                           ║
║  Work Item Range: #$($StartId.ToString().PadLeft(5)) - #$($EndId.ToString().PadLeft(5))$(' ' * 36) ║
║  Sprint:          $($SprintNumber.ToString().PadRight(60)) ║
║  Dry Run:         $($DryRun.ToString().PadRight(60)) ║
╚═══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Step 1: Get the correct iteration path
$iterationPath = Get-IterationPath -SprintNum $SprintNumber

Write-Host ""

# Step 2: Assign all work items
Write-StatusMessage "Assigning work items to '$iterationPath'..." -Type Info
Write-Host ""

$assigned = 0
$failed = 0
$total = $EndId - $StartId + 1

for ($id = $StartId; $id -le $EndId; $id++) {
    $progress = [math]::Round((($id - $StartId + 1) / $total) * 100, 1)
    
    Write-Progress -Activity "Assigning work items to Sprint $SprintNumber" `
        -Status "Processing #$id ($progress%)" `
        -PercentComplete $progress
    
    if (Set-WorkItemIteration -Id $id -IterationPath $iterationPath) {
        Write-Host "  ✅ Work Item #$id assigned to Sprint $SprintNumber" -ForegroundColor Green
        $assigned++
    } else {
        Write-Host "  ❌ Work Item #$id FAILED" -ForegroundColor Red
        $failed++
    }
    
    # Throttle to avoid API rate limits
    Start-Sleep -Milliseconds 300
}

Write-Progress -Activity "Assigning work items" -Completed

# Step 3: Verification
Write-Host "`n" -NoNewline
Write-StatusMessage "Verifying assignment..." -Type Info

$verifiedCount = 0
$verifyQuery = az boards query --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Id] >= $StartId AND [System.Id] <= $EndId AND [System.IterationPath] UNDER '$iterationPath'" --output json 2>$null

if ($verifyQuery -and $LASTEXITCODE -eq 0) {
    $verifiedCount = ($verifyQuery | ConvertFrom-Json).Count
    Write-StatusMessage "Verified: $verifiedCount/$total work items assigned to Sprint $SprintNumber" -Type Success
} else {
    Write-StatusMessage "Verification query failed (may be expected if DryRun)" -Type Warning
}

# Step 4: Summary
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                       Assignment Complete                                ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Total Work Items:      $($total.ToString().PadRight(50)) ║" -ForegroundColor Green
Write-Host "║  Successfully Assigned: $($assigned.ToString().PadRight(50)) ║" -ForegroundColor Green
Write-Host "║  Failed:                $($failed.ToString().PadRight(50)) ║" -ForegroundColor Green
if ($verifiedCount -gt 0) {
    Write-Host "║  Verified in Query:     $($verifiedCount.ToString().PadRight(50)) ║" -ForegroundColor Green
}
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN - No changes were made to Azure DevOps" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
} elseif ($failed -gt 0) {
    Write-Host "`n⚠️  Some work items failed to assign" -ForegroundColor Yellow
    Write-Host "Check the output above for details" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n🎉 All work items successfully assigned to Sprint $SprintNumber!" -ForegroundColor Green
}
