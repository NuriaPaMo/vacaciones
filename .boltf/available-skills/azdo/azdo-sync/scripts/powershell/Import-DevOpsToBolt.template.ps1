<#
.SYNOPSIS
    Import Azure DevOps work items into Bolt Framework specification format

.DESCRIPTION
    Retrieves an existing Azure DevOps Feature and its children (User Stories, Tasks)
    and generates the corresponding Bolt Framework spec structure in specs/ folder.

    Useful for retroactively converting existing DevOps backlog to Bolt Framework methodology.

.PARAMETER WorkItemId
    The ID of the Feature work item to import

.PARAMETER OutputPath
    Target path for the Bolt Framework spec (e.g., "specs/002-imported-feature")

.PARAMETER IncludeChildren
    Import child User Stories and Tasks (default: true)

.PARAMETER Force
    Overwrite existing spec folder if it exists

.EXAMPLE
    .\Import-DevOpsToBolt.ps1 -WorkItemId 12345 -OutputPath "specs/001-time-tracking"
    Import Feature 12345 with all children

.EXAMPLE
    .\Import-DevOpsToBolt.ps1 -WorkItemId 12345 -OutputPath "specs/001-time-tracking" -IncludeChildren:$false
    Import only the Feature (no User Stories/Tasks)

.NOTES
    Requires:
    - Azure DevOps CLI (az devops)
    - AZURE_DEVOPS_EXT_PAT environment variable
    - Work item must be of type "Feature"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$WorkItemId,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeChildren = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$script:Config = @{
    Organization = "https://dev.azure.com/jdmveira"
    Project      = "Registro Horario"
}

# =============================================================================
# Helper Functions
# =============================================================================

function Write-StatusMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info"    { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
    }

    Write-Host "[$Type] $Message" -ForegroundColor $color
}

function Get-WorkItem {
    param([int]$Id)

    try {
        $json = az boards work-item show --id $Id --output json
        return $json | ConvertFrom-Json
    }
    catch {
        Write-StatusMessage "Failed to retrieve work item $Id`: $_" -Type Error
        throw
    }
}

function Get-ChildWorkItems {
    param([int]$ParentId)

    try {
        $query = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.Parent] = $ParentId"
        $json = az boards query --wiql $query --output json
        $result = $json | ConvertFrom-Json
        return $result
    }
    catch {
        Write-StatusMessage "Failed to query children of $ParentId`: $_" -Type Error
        return @()
    }
}

function ConvertTo-MarkdownSafe {
    param([string]$Text)

    if (-not $Text) { return "" }

    # Basic HTML to Markdown conversion
    $text = $Text -replace '<br\s*/?>', "`n"
    $text = $text -replace '<p>', "`n"
    $text = $text -replace '</p>', "`n"
    $text = $text -replace '<strong>(.+?)</strong>', '**$1**'
    $text = $text -replace '<b>(.+?)</b>', '**$1**'
    $text = $text -replace '<em>(.+?)</em>', '*$1*'
    $text = $text -replace '<i>(.+?)</i>', '*$1*'
    $text = $text -replace '<[^>]+>', ''  # Remove remaining tags

    return $text.Trim()
}

function New-FeatureMarkdown {
    param(
        [object]$WorkItem,
        [string]$OutputPath
    )

    $title = $WorkItem.fields.'System.Title'
    $description = ConvertTo-MarkdownSafe -Text $WorkItem.fields.'System.Description'
    $acceptanceCriteria = ConvertTo-MarkdownSafe -Text $WorkItem.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
    $state = $WorkItem.fields.'System.State'
    $createdDate = $WorkItem.fields.'System.CreatedDate'

    $content = @"
# $title

> **Imported from Azure DevOps**: Work Item #$($WorkItem.id)
> **State**: $state
> **Created**: $createdDate

## Description

$description

## Objectives

<!-- Define high-level objectives this feature aims to achieve -->

- [ ] Objective 1
- [ ] Objective 2

## Scope

### In Scope

- Items imported from Azure DevOps User Stories

### Out of Scope

- To be defined during Bolt Framework DISCOVERY phase

## Acceptance Criteria

$acceptanceCriteria

## Dependencies

- [ ] Dependency 1 (if any)

## Risks & Assumptions

### Risks

- **Risk**: Describe potential risk
  - **Mitigation**: How to mitigate

### Assumptions

- Assumption 1
- Assumption 2

## Notes

Imported from Azure DevOps on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Original work item: $($script:Config.Organization)/$($script:Config.Project)/_workitems/edit/$($WorkItem.id)

---

**Phase**: DISCOVERY
**Status**: Imported - Requires Bolt Framework refinement
"@

    $featurePath = Join-Path $OutputPath "feature.md"
    $content | Set-Content $featurePath -Encoding UTF8

    Write-StatusMessage "Created feature.md" -Type Success
}

function New-RequirementsMarkdown {
    param(
        [array]$UserStories,
        [string]$OutputPath
    )

    if ($UserStories.Count -eq 0) {
        Write-StatusMessage "No user stories to import" -Type Warning
        return
    }

    $content = @"
# Requirements

> Imported from Azure DevOps User Stories

## User Stories

"@

    $storyIndex = 1
    foreach ($story in $UserStories) {
        $details = Get-WorkItem -Id $story.id
        $title = $details.fields.'System.Title'
        $description = ConvertTo-MarkdownSafe -Text $details.fields.'System.Description'
        $ac = ConvertTo-MarkdownSafe -Text $details.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
        $state = $details.fields.'System.State'

        $content += @"

### US-$($storyIndex.ToString('000')): $title

**State**: $state
**Azure DevOps**: [Work Item #$($story.id)]($($script:Config.Organization)/$($script:Config.Project)/_workitems/edit/$($story.id))

**Description**:

$description

**Acceptance Criteria**:

$ac

"@
        $storyIndex++
    }

    $content += @"

---

**Last Updated**: $(Get-Date -Format "yyyy-MM-dd")
**Source**: Azure DevOps import
"@

    $requirementsDir = Join-Path $OutputPath "requirements"
    if (-not (Test-Path $requirementsDir)) {
        New-Item -ItemType Directory -Path $requirementsDir -Force | Out-Null
    }

    $requirementsPath = Join-Path $requirementsDir "requirements.md"
    $content | Set-Content $requirementsPath -Encoding UTF8

    Write-StatusMessage "Created requirements/requirements.md with $($UserStories.Count) user stories" -Type Success
}

function New-TasksMarkdown {
    param(
        [array]$Tasks,
        [string]$OutputPath
    )

    if ($Tasks.Count -eq 0) {
        Write-StatusMessage "No tasks to import" -Type Warning
        return
    }

    $content = @"
# Bolt Tasks

> Imported from Azure DevOps Tasks

## Implementation Tasks

"@

    foreach ($task in $Tasks) {
        $details = Get-WorkItem -Id $task.id
        $title = $details.fields.'System.Title'
        $state = $details.fields.'System.State'
        $remainingWork = $details.fields.'Microsoft.VSTS.Scheduling.RemainingWork'
        $completedWork = $details.fields.'Microsoft.VSTS.Scheduling.CompletedWork'

        # Determine checkbox state
        $checkbox = if ($state -eq "Completed" -or $state -eq "Closed") { "[x]" } else { "[ ]" }

        # Estimate hours
        $hours = if ($remainingWork) { $remainingWork } elseif ($completedWork) { $completedWork } else { 0 }
        $hoursText = if ($hours -gt 0) { " ($($hours)h)" } else { "" }

        $content += "- $checkbox $title$hoursText`n"
        $content += "  - **State**: $state`n"
        $content += "  - **Azure DevOps**: [#$($task.id)]($($script:Config.Organization)/$($script:Config.Project)/_workitems/edit/$($task.id))`n`n"
    }

    $content += @"

---

**Total Tasks**: $($Tasks.Count)
**Completed**: $(($Tasks | Where-Object { $_.fields.'System.State' -in @('Completed', 'Closed') }).Count)
**Last Updated**: $(Get-Date -Format "yyyy-MM-dd")
"@

    $planningDir = Join-Path $OutputPath "planning"
    if (-not (Test-Path $planningDir)) {
        New-Item -ItemType Directory -Path $planningDir -Force | Out-Null
    }

    $tasksPath = Join-Path $planningDir "tasks.md"
    $content | Set-Content $tasksPath -Encoding UTF8

    Write-StatusMessage "Created planning/tasks.md with $($Tasks.Count) tasks" -Type Success
}

function New-SyncMetadata {
    param(
        [object]$Feature,
        [array]$UserStories,
        [array]$Tasks,
        [string]$OutputPath
    )

    $featureId = Split-Path $OutputPath -Leaf

    $metadata = @{
        version         = "1.0.0"
        boltFeatureId = $featureId
        azureDevOps     = @{
            organization          = $script:Config.Organization
            project               = $script:Config.Project
            featureWorkItemId     = $Feature.id
            userStories           = @($UserStories | ForEach-Object {
                @{
                    workItemId    = $_.id
                    boltStoryId = "US-$((1 + $UserStories.IndexOf($_)).ToString('000'))"
                    title         = $_.fields.'System.Title'
                    state         = $_.fields.'System.State'
                }
            })
            tasks                 = @($Tasks | ForEach-Object {
                @{
                    workItemId   = $_.id
                    boltTaskId = "$featureId-$((1 + $Tasks.IndexOf($_)).ToString('000'))"
                    title        = $_.fields.'System.Title'
                    state        = $_.fields.'System.State'
                }
            })
        }
        lastSync        = (Get-Date).ToUniversalTime().ToString("o")
        syncDirection   = "bidirectional"
        importedFrom    = "Azure DevOps on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }

    $metadataDir = Join-Path $OutputPath ".metadata"
    if (-not (Test-Path $metadataDir)) {
        New-Item -ItemType Directory -Path $metadataDir -Force | Out-Null
    }

    $metadataPath = Join-Path $metadataDir "devops-sync.json"
    $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8

    Write-StatusMessage "Created .metadata/devops-sync.json" -Type Success
}

# =============================================================================
# Main Script
# =============================================================================

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║             Azure DevOps → Bolt Framework Import                                  ║
║                                                                           ║
║  Work Item ID: $($WorkItemId.ToString().PadRight(58)) ║
║  Output Path: $($OutputPath.PadRight(59)) ║
╚═══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Step 1: Check if output path exists
if ((Test-Path $OutputPath) -and -not $Force) {
    Write-StatusMessage "Output path already exists: $OutputPath" -Type Error
    Write-StatusMessage "Use -Force to overwrite" -Type Warning
    exit 1
}

# Step 2: Retrieve Feature work item
Write-StatusMessage "Retrieving work item #$WorkItemId..." -Type Info
$feature = Get-WorkItem -Id $WorkItemId

$workItemType = $feature.fields.'System.WorkItemType'
if ($workItemType -ne "Feature") {
    Write-StatusMessage "Work item is type '$workItemType', expected 'Feature'" -Type Error
    Write-StatusMessage "Only Feature work items can be imported as Bolt Framework specs" -Type Warning
    exit 1
}

Write-StatusMessage "Found Feature: $($feature.fields.'System.Title')" -Type Success

# Step 3: Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Step 4: Generate feature.md
New-FeatureMarkdown -WorkItem $feature -OutputPath $OutputPath

# Step 5: Import children (if requested)
$userStories = @()
$tasks = @()

if ($IncludeChildren) {
    Write-StatusMessage "Importing child work items..." -Type Info

    $children = Get-ChildWorkItems -ParentId $WorkItemId

    $userStories = @($children | Where-Object { $_.fields.'System.WorkItemType' -eq 'User Story' })
    Write-StatusMessage "Found $($userStories.Count) User Stories" -Type Info

    if ($userStories.Count -gt 0) {
        New-RequirementsMarkdown -UserStories $userStories -OutputPath $OutputPath

        # Get tasks (children of user stories)
        foreach ($story in $userStories) {
            $storyTasks = Get-ChildWorkItems -ParentId $story.id
            $tasks += @($storyTasks | Where-Object { $_.fields.'System.WorkItemType' -eq 'Task' })
        }

        Write-StatusMessage "Found $($tasks.Count) Tasks across all User Stories" -Type Info

        if ($tasks.Count -gt 0) {
            New-TasksMarkdown -Tasks $tasks -OutputPath $OutputPath
        }
    }
}

# Step 6: Generate sync metadata
New-SyncMetadata -Feature $feature -UserStories $userStories -Tasks $tasks -OutputPath $OutputPath

# Step 7: Summary
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                          Import Complete                                  ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Feature:       Work Item #$($WorkItemId.ToString().PadRight(49)) ║" -ForegroundColor Green
Write-Host "║  User Stories:  $($userStories.Count.ToString().PadRight(60)) ║" -ForegroundColor Green
Write-Host "║  Tasks:         $($tasks.Count.ToString().PadRight(60)) ║" -ForegroundColor Green
Write-Host "║                                                                           ║" -ForegroundColor Green
Write-Host "║  Output: $($OutputPath.PadRight(65)) ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Review generated spec in $OutputPath" -ForegroundColor White
Write-Host "  2. Refine with Bolt Framework agents:" -ForegroundColor White
Write-Host "     @Bolt Feature review $OutputPath" -ForegroundColor Cyan
Write-Host "     @Bolt Plan verify implementation plan" -ForegroundColor Cyan
Write-Host "  3. Verify constitution compliance" -ForegroundColor White
