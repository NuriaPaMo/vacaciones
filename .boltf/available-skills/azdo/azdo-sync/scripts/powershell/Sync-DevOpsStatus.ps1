<#
.SYNOPSIS
    Synchronize work item status updates from Azure DevOps to Bolt Framework specs

.DESCRIPTION
    Queries Azure DevOps for task status changes and updates the corresponding
    planning/tasks.md file in Bolt Framework specs. Maintains bidirectional sync by
    pulling DevOps as source of truth for status.

.PARAMETER FeaturePath
    Path to the Bolt Framework feature (e.g., "specs/001-time-tracking")
    If omitted, syncs all features in specs/ folder

.PARAMETER AutoCommit
    Automatically commit changes to git with sync message

.EXAMPLE
    .\Sync-DevOpsStatus.ps1 -FeaturePath "specs/001-time-tracking"
    Sync status for single feature

.EXAMPLE
    .\Sync-DevOpsStatus.ps1
    Sync all features

.EXAMPLE
    .\Sync-DevOpsStatus.ps1 -AutoCommit
    Sync all features and commit changes

.NOTES
    Intended for CI/CD pipeline or scheduled execution
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$FeaturePath = "",

    [Parameter(Mandatory = $false)]
    [switch]$AutoCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load shared environment (reads .env, builds $script:Config, validates PAT)
. "$PSScriptRoot\_EnvLoader.ps1"

# =============================================================================
# Helper Functions
# =============================================================================

function Get-AllFeatures {
    $specsPath = "specs"
    if (-not (Test-Path $specsPath)) {
        Write-StatusMessage "No specs/ folder found" -Type Warning
        return @()
    }
    
    return Get-ChildItem -Path $specsPath -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName ".metadata\devops-sync.json")
    }
}

function Sync-FeatureStatus {
    param([string]$Path)
    
    $featureId = Split-Path $Path -Leaf
    Write-StatusMessage "Syncing $featureId..." -Type Info
    
    # Load metadata
    $metadataPath = Join-Path $Path ".metadata\devops-sync.json"
    if (-not (Test-Path $metadataPath)) {
        Write-StatusMessage "No sync metadata found, skipping" -Type Warning
        return $false
    }
    
    $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
    
    if (-not $metadata.azureDevOps.tasks -or $metadata.azureDevOps.tasks.Count -eq 0) {
        Write-StatusMessage "No tasks to sync" -Type Warning
        return $false
    }
    
    # Query task states from DevOps
    $updates = @()
    
    foreach ($task in $metadata.azureDevOps.tasks) {
        try {
            $workItem = az boards work-item show --id $task.workItemId --output json | ConvertFrom-Json
            $currentState = $workItem.fields.'System.State'
            
            if ($currentState -ne $task.state) {
                Write-StatusMessage "  Task #$($task.workItemId): $($task.state) → $currentState" -Type Info
                $updates += @{
                    BoltId   = $task.boltfBoltId
                    OldState = $task.state
                    NewState = $currentState
                    Title    = $task.title
                }
                
                # Update metadata
                $task.state = $currentState
            }
        }
        catch {
            Write-StatusMessage "  Failed to query task #$($task.workItemId): $_" -Type Warning
        }
    }
    
    if ($updates.Count -eq 0) {
        Write-StatusMessage "  No status changes detected" -Type Success
        return $false
    }
    
    # Update tasks.md
    $tasksPath = Join-Path $Path "planning\tasks.md"
    if (-not (Test-Path $tasksPath)) {
        Write-StatusMessage "  No tasks.md found" -Type Warning
        return $false
    }
    
    $content = Get-Content $tasksPath -Raw
    $modified = $false
    
    foreach ($update in $updates) {
        # Update checkbox state based on Azure DevOps state
        $newCheckbox = if ($update.NewState -in @('Completed', 'Closed')) { '[x]' } else { '[ ]' }
        
        # Pattern: - [x] or - [ ] followed by task title
        $escapedTitle = [regex]::Escape($update.Title)
        $pattern = "(?m)^- \[([ x])\] ($escapedTitle.*?)$"
        
        if ($content -match $pattern) {
            $oldCheckbox = $matches[1]
            $fullLine = $matches[0]
            
            # Only update if checkbox state changed
            if (($oldCheckbox -eq ' ' -and $newCheckbox -eq '[x]') -or 
                ($oldCheckbox -eq 'x' -and $newCheckbox -eq '[ ]')) {
                
                $newLine = $fullLine -replace '- \[([ x])\]', "- $newCheckbox"
                $content = $content -replace [regex]::Escape($fullLine), $newLine
                $modified = $true
                
                Write-StatusMessage "    Updated: $($update.Title)" -Type Success
            }
        }
    }
    
    if ($modified) {
        # Add sync timestamp comment
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $content += "`n`n<!-- Last synced with Azure DevOps: $timestamp -->`n"
        
        $content | Set-Content $tasksPath -Encoding UTF8 -NoNewline
        
        # Update metadata timestamp
        $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
        $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
        
        Write-StatusMessage "  Updated $($updates.Count) task(s)" -Type Success
        return $true
    }
    
    return $false
}

# =============================================================================
# Main Script
# =============================================================================

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║             Azure DevOps Status → Bolt Framework Sync                             ║
╚═══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

$anyChanges = $false

if ($FeaturePath) {
    # Sync single feature
    if (-not (Test-Path $FeaturePath)) {
        Write-StatusMessage "Feature path not found: $FeaturePath" -Type Error
        exit 1
    }
    
    $changed = Sync-FeatureStatus -Path $FeaturePath
    $anyChanges = $changed
}
else {
    # Sync all features
    $features = Get-AllFeatures
    
    if ($features.Count -eq 0) {
        Write-StatusMessage "No features with sync metadata found" -Type Warning
        exit 0
    }
    
    Write-StatusMessage "Found $($features.Count) synced feature(s)" -Type Info
    
    foreach ($feature in $features) {
        $changed = Sync-FeatureStatus -Path $feature.FullName
        $anyChanges = $anyChanges -or $changed
    }
}

# Auto-commit if requested
if ($anyChanges -and $AutoCommit) {
    Write-StatusMessage "`nCommitting changes..." -Type Info
    
    git add specs/
    git commit -m "chore: Sync task statuses from Azure DevOps

Automated sync at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Updated task completion states from Azure DevOps Boards"
    
    if ($LASTEXITCODE -eq 0) {
        Write-StatusMessage "Changes committed successfully" -Type Success
    }
    else {
        Write-StatusMessage "Git commit failed" -Type Error
    }
}
elseif ($anyChanges) {
    Write-Host "`nChanges detected but not committed. Run with -AutoCommit to commit automatically." -ForegroundColor Yellow
    Write-Host "Or manually commit:" -ForegroundColor White
    Write-Host "  git add specs/" -ForegroundColor Cyan
    Write-Host "  git commit -m `"chore: Sync task statuses from Azure DevOps`"" -ForegroundColor Cyan
}
else {
    Write-StatusMessage "`nNo status changes detected - specs are up to date" -Type Success
}
