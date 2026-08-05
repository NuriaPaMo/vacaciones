<#
.SYNOPSIS
    Fix existing Azure DevOps work items to comply with Bolt Framework standards

.DESCRIPTION
    This script updates existing work items to add:
    - 'Bolt Framework' tag (REQUIRED)
    - Parent-Child relationships (Feature → User Stories → Tasks)
    - Correct Area Path and Iteration
    
.PARAMETER StartId
    First work item ID to process

.PARAMETER EndId
    Last work item ID to process

.PARAMETER DryRun
    Preview changes without applying them

.EXAMPLE
    .\Fix-DevOpsWorkItems.ps1 -StartId 31530 -EndId 31604 -DryRun
    Preview all changes for Feature 008

.EXAMPLE
    .\Fix-DevOpsWorkItems.ps1 -StartId 31530 -EndId 31604
    Apply all fixes to Feature 008 work items

.NOTES
    Requires:
    - Azure DevOps CLI (az devops)
    - AZURE_DEVOPS_EXT_PAT environment variable set
    - Work items must exist in Azure DevOps
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$StartId,

    [Parameter(Mandatory = $true)]
    [int]$EndId,

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

function Get-WorkItem {
    param([int]$Id)
    
    try {
        $json = az boards work-item show --id $Id --output json 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Failed to retrieve work item #$Id" -Type Error
            return $null
        }
        return $json | ConvertFrom-Json
    }
    catch {
        Write-StatusMessage "Exception getting work item #${Id}: $($_.Exception.Message)" -Type Error
        return $null
    }
}

function Update-WorkItemTags {
    param(
        [int]$Id,
        [string[]]$ExistingTags
    )
    
    # Ensure 'Bolt Framework' tag is present
    $allTags = @($script:Config.RequiredTag) + $ExistingTags | Select-Object -Unique
    $tagsString = $allTags -join ';'
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would set tags to: $tagsString" -ForegroundColor Magenta
        return $true
    }
    
    try {
        $null = az boards work-item update --id $Id --fields "System.Tags=$tagsString" --output none 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Failed to update tags for #$Id" -Type Error
            return $false
        }
        return $true
    }
    catch {
        Write-StatusMessage "Exception updating tags for #${Id}: $($_.Exception.Message)" -Type Error
        return $false
    }
}

function Add-ParentLink {
    param(
        [int]$ChildId,
        [int]$ParentId
    )
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would link #$ChildId → Parent #$ParentId" -ForegroundColor Magenta
        return $true
    }
    
    try {
        $null = az boards work-item relation add `
            --id $ChildId `
            --relation-type "parent" `
            --target-id $ParentId `
            --output none 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Failed to add parent link #$ChildId → #$ParentId" -Type Error
            return $false
        }
        return $true
    }
    catch {
        Write-StatusMessage "Exception adding parent link #${ChildId} to #${ParentId}: $($_.Exception.Message)" -Type Error
        return $false
    }
}

# =============================================================================
# Main Processing
# =============================================================================

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║              Bolt Framework Work Items Compliance Fix                    ║
║                                                                           ║
║  Work Item Range: #$($StartId.ToString().PadRight(57)) ║
║                   #$($EndId.ToString().PadRight(57)) ║
║  Dry Run: $($DryRun.ToString().PadRight(66)) ║
╚═══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Step 1: Retrieve all work items
Write-StatusMessage "Retrieving work items #$StartId - #$EndId..." -Type Info

$workItems = @()
for ($id = $StartId; $id -le $EndId; $id++) {
    $wi = Get-WorkItem -Id $id
    if ($wi) {
        $workItems += $wi
    } else {
        Write-StatusMessage "Skipping non-existent work item #$id" -Type Warning
    }
}

Write-StatusMessage "Retrieved $($workItems.Count) work items" -Type Success

# Step 2: Categorize work items
$userStories = $workItems | Where-Object { $_.fields.'System.WorkItemType' -eq 'Product Backlog Item' }
$tasks = $workItems | Where-Object { $_.fields.'System.WorkItemType' -eq 'Task' }

Write-StatusMessage "Found $($userStories.Count) User Stories, $($tasks.Count) Tasks" -Type Info

# Step 3: Fix tags for all work items
Write-StatusMessage "`nFixing tags..." -Type Info
$tagsFixed = 0

foreach ($wi in $workItems) {
    $currentTags = if ($wi.fields.'System.Tags') { 
        $wi.fields.'System.Tags' -split ';' | Where-Object { $_ -and $_.Trim() }
    } else { 
        @() 
    }
    
    if ($currentTags -notcontains $script:Config.RequiredTag) {
        Write-Host "  Work Item #$($wi.id): Adding '$($script:Config.RequiredTag)' tag"
        
        if (Update-WorkItemTags -Id $wi.id -ExistingTags $currentTags) {
            $tagsFixed++
        }
    } else {
        Write-Host "  Work Item #$($wi.id): Already has '$($script:Config.RequiredTag)' tag" -ForegroundColor DarkGray
    }
}

Write-StatusMessage "Fixed tags on $tagsFixed work items" -Type Success

# Step 4: Ensure Feature exists and link User Stories to Feature
Write-StatusMessage "`nChecking Feature parent for User Stories..." -Type Info

# Detect if any User Story lacks a Feature parent
$storiesWithoutFeature = @()
foreach ($us in $userStories) {
    $hasFeatureParent = $us.relations -and ($us.relations | Where-Object {
        $_.rel -eq 'System.LinkTypes.Hierarchy-Reverse'
    })
    if (-not $hasFeatureParent) {
        $storiesWithoutFeature += $us
    }
}

$featureLinksCreated = 0
if ($storiesWithoutFeature.Count -gt 0) {
    Write-StatusMessage "Found $($storiesWithoutFeature.Count) User Stories without Feature parent" -Type Warning
    
    # Look for existing Feature with matching tags in the project
    $featureTag = ($workItems[0].fields.'System.Tags' -split ';' | Where-Object { $_ -match '^\d{3}-' } | Select-Object -First 1)?.Trim()
    $featureWI = $null
    
    if ($featureTag) {
        Write-StatusMessage "Searching for Feature with tag '$featureTag'..." -Type Info
        $query = az boards query --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.WorkItemType] = 'Feature' AND [System.Tags] CONTAINS '$featureTag'" --output json 2>$null
        if ($LASTEXITCODE -eq 0 -and $query) {
            $features = $query | ConvertFrom-Json
            if ($features.Count -gt 0) {
                $featureWI = $features[0]
                Write-StatusMessage "Found existing Feature #$($featureWI.id)" -Type Success
            }
        }
    }
    
    if (-not $featureWI) {
        Write-StatusMessage "No Feature found. Creating one from spec..." -Type Info
        
        # Try to find feature title from spec folder
        $specFolder = Get-ChildItem -Path "specs" -Filter "$featureTag" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        $featureTitle = "Feature: $featureTag"
        
        if ($specFolder) {
            # Read title from spec.md or feature.md
            $specFiles = @("feature.md", "spec.md")
            foreach ($sf in $specFiles) {
                $specFile = Join-Path $specFolder.FullName $sf
                if (Test-Path $specFile) {
                    $specContent = Get-Content $specFile -Raw
                    $titleMatch = [regex]::Match($specContent, '(?m)^# (.+)$')
                    if ($titleMatch.Success) {
                        $featureTitle = $titleMatch.Groups[1].Value
                    }
                    break
                }
            }
        }
        
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would create Feature: $featureTitle" -ForegroundColor Magenta
        } else {
            $tags = @($script:Config.RequiredTag)
            if ($featureTag) { $tags += $featureTag }
            $tagsStr = $tags -join ';'
            
            $featureJson = az boards work-item create `
                --type "Feature" `
                --title $featureTitle `
                --project $script:Config.Project `
                --fields "System.AreaPath=$($script:Config.AreaPath)" "System.Tags=$tagsStr" `
                --output json 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $featureWI = $featureJson | ConvertFrom-Json
                Write-StatusMessage "Created Feature #$($featureWI.id): $featureTitle" -Type Success
            } else {
                Write-StatusMessage "Failed to create Feature: $featureJson" -Type Error
            }
        }
    }
    
    # Link User Stories to Feature
    if ($featureWI) {
        foreach ($us in $storiesWithoutFeature) {
            Write-Host "  Linking PBI #$($us.id) → Feature #$($featureWI.id)" -ForegroundColor Yellow
            if (Add-ParentLink -ChildId $us.id -ParentId $featureWI.id) {
                Write-Host "    ✅ Linked PBI #$($us.id) → Feature #$($featureWI.id)" -ForegroundColor Green
                $featureLinksCreated++
            }
        }
    }
} else {
    Write-StatusMessage "All User Stories already have a Feature parent" -Type Success
}

# Step 5: Create Task → User Story Parent-Child links
Write-StatusMessage "`nCreating Task Parent-Child relationships..." -Type Info

# Define the mapping based on Feature 008 structure
# User Stories: #31530-31533 (4 User Stories)
# Tasks: #31534-31604 (71 tasks)

$parentMapping = @{
    # US-008.1: Aspire Setup (Bolt 1-2: tasks 001-017)
    31530 = 31534..31550  # Tasks 008-infra-001 to 008-infra-017
    
    # US-008.2: Backend OpenTelemetry (Bolts 3-6: tasks 018-045)
    31531 = 31551..31578  # Tasks 008-infra-018 to 008-infra-045
    
    # US-008.3: Frontend RUM (Bolts 7-8: tasks 046-056)
    31532 = 31579..31589  # Tasks 008-infra-046 to 008-infra-056
    
    # US-008.4: Dashboards (Bolts 9-10: tasks 057-071)
    31533 = 31590..31604  # Tasks 008-infra-057 to 008-infra-071
}

$linksCreated = 0

foreach ($parentId in $parentMapping.Keys) {
    $childIds = $parentMapping[$parentId]
    
    $parentWI = $userStories | Where-Object { $_.id -eq $parentId }
    if (-not $parentWI) {
        Write-StatusMessage "Parent User Story #$parentId not found, skipping children" -Type Warning
        continue
    }
    
    Write-Host "`n  Parent: #$parentId - $($parentWI.fields.'System.Title')" -ForegroundColor Yellow
    
    foreach ($childId in $childIds) {
        $childWI = $tasks | Where-Object { $_.id -eq $childId }
        if (-not $childWI) {
            Write-StatusMessage "    Child task #$childId not found" -Type Warning
            continue
        }
        
        # Check if parent link already exists
        $hasParent = $childWI.relations -and ($childWI.relations | Where-Object { 
            $_.rel -eq 'System.LinkTypes.Hierarchy-Reverse' -and $_.url -match "/$parentId$"
        })
        
        if ($hasParent) {
            Write-Host "    Task #$childId already linked to parent" -ForegroundColor DarkGray
            continue
        }
        
        # Add parent link
        if (Add-ParentLink -ChildId $childId -ParentId $parentId) {
            Write-Host "    ✅ Linked Task #$childId → Parent #$parentId"
            $linksCreated++
        }
    }
}

Write-StatusMessage "`nCreated $linksCreated task parent-child links" -Type Success
Write-StatusMessage "Created $featureLinksCreated feature-to-story links" -Type Success

# Step 7: Summary
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                          Fix Complete                                     ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Tags Fixed:          $($tagsFixed.ToString().PadRight(52)) ║" -ForegroundColor Green
Write-Host "║  Feature→PBI Links:   $($featureLinksCreated.ToString().PadRight(52)) ║" -ForegroundColor Green
Write-Host "║  Task→PBI Links:      $($linksCreated.ToString().PadRight(52)) ║" -ForegroundColor Green
Write-Host "║  Total Work Items:    $($workItems.Count.ToString().PadRight(52)) ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN - No changes were made to Azure DevOps" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}
