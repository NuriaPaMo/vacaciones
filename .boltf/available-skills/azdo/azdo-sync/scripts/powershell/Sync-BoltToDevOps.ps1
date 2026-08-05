<#
.SYNOPSIS
    Synchronize Bolt feature specifications to Azure DevOps work items

.DESCRIPTION
    This script reads Bolt specs from the specs/ folder and creates/updates
    corresponding work items in Azure DevOps (Features, User Stories, Tasks).

    It maintains bidirectional traceability through .metadata/devops-sync.json
    and tags all work items with Bolt for filtering.

.PARAMETER FeaturePath
    Path to the Bolt feature folder (e.g., "specs/001-time-tracking")

.PARAMETER Mode
    Sync mode: "Full" (recreate all), "Incremental" (new/changed only)

.PARAMETER DryRun
    Preview changes without creating work items

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -DryRun
    Preview what work items would be created

.EXAMPLE
    .\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -Mode Incremental
    Sync only new/changed items

.NOTES
    Requires:
    - Azure DevOps CLI (az devops)
    - AZURE_DEVOPS_EXT_PAT environment variable set
    - Constitution article XI configuration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$FeaturePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Full", "Incremental")]
    [string]$Mode = "Incremental",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Load shared environment (reads .env, builds $script:Config, validates PAT)
. "$PSScriptRoot\_EnvLoader.ps1"

# =============================================================================
# Helper Functions
# =============================================================================

function Test-AzureDevOpsAuth {
    Write-StatusMessage "Verifying Azure DevOps authentication..." -Type Info

    if (-not $env:AZURE_DEVOPS_EXT_PAT) {
        Write-StatusMessage "AZURE_DEVOPS_EXT_PAT environment variable not set" -Type Error
        Write-Host @"

Please configure authentication:

    `$env:AZURE_DEVOPS_EXT_PAT = "your-pat-token"
    az devops configure --defaults organization=$($script:Config.Organization) project="$($script:Config.Project)"

"@ -ForegroundColor Yellow
        return $false
    }

    try {
        $null = az devops project show --project $script:Config.Project --query "name" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Failed to connect to Azure DevOps project" -Type Error
            return $false
        }
        Write-StatusMessage "Authentication successful" -Type Success
        return $true
    }
    catch {
        Write-StatusMessage "Azure DevOps CLI error: $_" -Type Error
        return $false
    }
}

function Get-FeatureMetadata {
    param([string]$FeaturePath)

    $metadataPath = Join-Path $FeaturePath ".metadata\devops-sync.json"

    if (Test-Path $metadataPath) {
        return Get-Content $metadataPath -Raw | ConvertFrom-Json
    }

    # Return empty metadata structure
    return @{
        version          = "1.0.0"
        boltFeatureId  = (Split-Path $FeaturePath -Leaf)
        azureDevOps      = @{
            organization          = $script:Config.Organization
            project               = $script:Config.Project
            featureWorkItemId     = $null
            userStories           = @()
            tasks                 = @()
        }
        lastSync         = $null
        syncDirection    = "bidirectional"
    }
}

function Save-FeatureMetadata {
    param(
        [string]$FeaturePath,
        [object]$Metadata
    )

    $metadataDir = Join-Path $FeaturePath ".metadata"
    if (-not (Test-Path $metadataDir)) {
        New-Item -ItemType Directory -Path $metadataDir -Force | Out-Null
    }

    $metadataPath = Join-Path $metadataDir "devops-sync.json"
    $Metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")

    $Metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataPath -Encoding UTF8
    Write-StatusMessage "Metadata saved to $metadataPath" -Type Success
}

function Read-FeatureMarkdown {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-StatusMessage "Feature file not found: $Path" -Type Warning
        return $null
    }

    $content = Get-Content $Path -Raw

    # Extract title (first H1)
    $titleMatch = [regex]::Match($content, '(?m)^# (.+)$')
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { "Untitled Feature" }

    # Extract description (content between ## Description and next ##)
    $descMatch = [regex]::Match($content, '(?s)## Description\s*\n(.+?)(?=\n##|\z)')
    $description = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { "" }

    # Extract acceptance criteria
    $acMatch = [regex]::Match($content, '(?s)## Acceptance Criteria\s*\n(.+?)(?=\n##|\z)')
    $acceptanceCriteria = if ($acMatch.Success) { $acMatch.Groups[1].Value.Trim() } else { "" }

    return @{
        Title              = $title
        Description        = $description
        AcceptanceCriteria = $acceptanceCriteria
    }
}

function New-AzureDevOpsWorkItem {
    param(
        [string]$Type,
        [string]$Title,
        [string]$Description,
        [string]$AcceptanceCriteria = "",
        [string]$ParentId = "",
        [string[]]$Tags = @(),
        [int]$RemainingWork = 0
    )

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create $Type`: $Title" -ForegroundColor Magenta
        return @{ id = -1 }  # Mock ID for dry run
    }

    # CRITICAL: Always include 'Bolt Framework' tag
    $allTags = @($script:Config.RequiredTag) + $Tags | Select-Object -Unique

    $fields = @(
        "System.AreaPath=$($script:Config.AreaPath)",
        "System.IterationPath=$($script:Config.Iteration)",
        "System.Tags=$($allTags -join ';')"
    )

    if ($AcceptanceCriteria) {
        $fields += "Microsoft.VSTS.Common.AcceptanceCriteria=$AcceptanceCriteria"
    }

    if ($ParentId) {
        $fields += "System.Parent=$ParentId"
    }

    if ($RemainingWork -gt 0) {
        $fields += "Microsoft.VSTS.Scheduling.RemainingWork=$RemainingWork"
    }

    $fieldsArgs = $fields | ForEach-Object { "--fields", $_ }

    try {
        # Sanitize inputs - remove problematic quotes
        $cleanTitle = $Title.Replace('"', "'").Replace('`', "'")
        $cleanDescription = $Description.Replace('"', "'").Replace('`', "'")

        $fieldsArgs = $fields | ForEach-Object { "--fields"; $_ }

        $azArgs = @(
            'boards', 'work-item', 'create',
            '--type', $Type,
            '--title', $cleanTitle,
            '--description', $cleanDescription,
            '--project', $script:Config.Project,
            '--output', 'json'
        )

        $azArgs += $fieldsArgs

        $jsonOutput = & az @azArgs 2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            Write-StatusMessage "Azure CLI error creating $Type`: $jsonOutput" -Type Error
            return $null
        }

        try {
            $result = $jsonOutput | ConvertFrom-Json
        } catch {
            Write-StatusMessage "Failed to parse JSON response: $jsonOutput" -Type Error
            return $null
        }

        if (-not $result.id) {
            Write-StatusMessage "Failed to create $Type (no ID returned)" -Type Error
            return $null
        }

        Write-StatusMessage "Created $Type #$($result.id): $Title" -Type Success
        return $result
    }
    catch {
        Write-StatusMessage "Failed to create $Type`: $_" -Type Error
        throw
    }
}

function Sync-Feature {
    param(
        [string]$FeaturePath,
        [object]$Metadata
    )

    # Check if Feature already synced
    if ($Metadata.azureDevOps.featureWorkItemId -and $Mode -eq "Incremental") {
        Write-StatusMessage "Using existing Feature #$($Metadata.azureDevOps.featureWorkItemId)" -Type Info
        return $Metadata.azureDevOps.featureWorkItemId
    }

    # Look for feature definition in feature.md or spec.md (fallback)
    $featureMd = Join-Path $FeaturePath "feature.md"
    $specMd = Join-Path $FeaturePath "spec.md"

    $featureData = Read-FeatureMarkdown -Path $featureMd

    if (-not $featureData -and (Test-Path $specMd)) {
        Write-StatusMessage "No feature.md found, using spec.md as fallback" -Type Warning
        $featureData = Read-FeatureMarkdown -Path $specMd
    }

    if (-not $featureData) {
        Write-StatusMessage "Skipping feature creation (no feature.md or spec.md found)" -Type Warning
        return $null
    }

    $featureId = Split-Path $FeaturePath -Leaf
    $tags = @($featureId, "feature")

    Write-StatusMessage "Syncing Feature: $($featureData.Title)" -Type Info

    $workItem = New-AzureDevOpsWorkItem `
        -Type "Feature" `
        -Title $featureData.Title `
        -Description $featureData.Description `
        -AcceptanceCriteria $featureData.AcceptanceCriteria `
        -Tags $tags

    return $workItem.id
}

function Sync-UserStories {
    param(
        [string]$FeaturePath,
        [string]$ParentFeatureId,
        [object]$Metadata
    )

    $requirementsPath = Join-Path $FeaturePath "requirements\requirements.md"
    if (-not (Test-Path $requirementsPath)) {
        Write-StatusMessage "No requirements.md found, skipping user stories" -Type Warning
        return @()
    }

    # Simple parsing: Look for user stories in format "As a ... I want ... so that ..."
    # Supports both single-line and multi-line formats
    $content = Get-Content $requirementsPath -Raw

    # Pattern for multi-line format:
    # ### US-XXX: Title
    # **As a** role
    # **I want** goal
    # **So that** benefit
    $storyPattern = '(?s)### (US-[\d.]+):\s*(.+?)\s*\n\s*\*\*As a\*\*\s+(.+?)\s*\n\s*\*\*I want\*\*\s+(.+?)\s*\n\s*\*\*So that\*\*\s+(.+?)(?=\n\s*\*\*|\n\n|$)'
    $stories = [regex]::Matches($content, $storyPattern)

    if ($stories.Count -eq 0) {
        Write-StatusMessage "No user stories found in requirements.md" -Type Warning
        return @()
    }

    Write-StatusMessage "Found $($stories.Count) user stories" -Type Info

    $createdStories = @()

    foreach ($match in $stories) {
        $storyId = $match.Groups[1].Value.Trim()  # US-XXX
        $storyTitle = $match.Groups[2].Value.Trim()  # Title after US-XXX:
        $role = $match.Groups[3].Value.Trim()
        $goal = $match.Groups[4].Value.Trim()
        $benefit = $match.Groups[5].Value.Trim()

        $fullTitle = "As a $role I want $goal"
        $description = "**So that**: $benefit`n`n**Feature**: $storyId - $storyTitle"

        # Extract acceptance criteria (table format after story)
        $acPattern = "(?s)### $storyId.+?#### Acceptance Criteria\s*\n(.+?)(?=\n####|\n###|\z)"
        $acMatch = [regex]::Match($content, $acPattern)
        $ac = if ($acMatch.Success) { $acMatch.Groups[1].Value } else { "" }

        $tags = @((Split-Path $FeaturePath -Leaf), $storyId, "user-story")

        Write-StatusMessage "  Creating User Story: $storyTitle" -Type Info

        $workItem = New-AzureDevOpsWorkItem `
            -Type "Product Backlog Item" `
            -Title $fullTitle `
            -Description $description `
            -AcceptanceCriteria $ac `
            -ParentId $ParentFeatureId `
            -Tags $tags

        $createdStories += @{
            workItemId     = $workItem.id
            boltStoryId  = $storyId
            title          = "$storyId - $storyTitle"
            state          = "New"
        }
    }

    return $createdStories
}

function Sync-Tasks {
    param(
        [string]$FeaturePath,
        [array]$UserStories,
        [object]$Metadata
    )

    $tasksPath = Join-Path $FeaturePath "planning\tasks.md"
    if (-not (Test-Path $tasksPath)) {
        Write-StatusMessage "No tasks.md found, skipping tasks" -Type Warning
        return @()
    }

    # Simple parsing: Look for task items (lines starting with - [ ] or - [x])
    $content = Get-Content $tasksPath -Raw

    # Enhanced pattern to capture task ID (e.g., **008-infra-001**)
    $taskPattern = '(?m)^- \[([ x])\].*?\*\*(\d{3}-[\w-]+)\*\*\s+(.+?)(?:\s*\((\d+\.?\d*)(?:h|min)\))?$'
    $tasks = [regex]::Matches($content, $taskPattern)

    if ($tasks.Count -eq 0) {
        # Fallback to simpler pattern if no task IDs found
        Write-StatusMessage "  Using fallback task pattern (no task IDs detected)" -Type Warning
        $taskPattern = '(?m)^- \[([ x])\] (.+?)(?:\s*\((\d+)h\))?$'
        $tasks = [regex]::Matches($content, $taskPattern)
    }

    $createdTasks = @()
    $taskIndex = 1

    # Smart parent assignment: Map tasks to user stories based on Bolt sections
    # For now, default to first user story if mapping not clear
    $defaultParent = if ($UserStories.Count -gt 0) { $UserStories[0].workItemId } else { $null }

    foreach ($match in $tasks) {
        $isCompleted = $match.Groups[1].Value -eq 'x'

        # Check if we have task IDs (enhanced pattern) or simple pattern
        if ($match.Groups.Count -ge 5 -and $match.Groups[2].Success) {
            # Enhanced pattern with task IDs
            $taskId = $match.Groups[2].Value.Trim()
            $taskTitle = $match.Groups[3].Value.Trim()
            $estimatedValue = if ($match.Groups[4].Success) { $match.Groups[4].Value } else { "4" }

            # Convert minutes to hours (e.g., "45min" -> 0.75h)
            if ($taskTitle -match '\((\d+)min\)$') {
                $minutes = [int]$Matches[1]
                $estimatedHours = [math]::Round($minutes / 60, 2)
            } else {
                $estimatedHours = [double]$estimatedValue
            }
        } else {
            # Simple pattern fallback
            $taskId = "task-$($taskIndex.ToString('000'))"
            $taskTitle = $match.Groups[2].Value.Trim()
            $estimatedHours = if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 4 }
        }

        if (-not $defaultParent) {
            Write-StatusMessage "  Skipping task $taskId (no parent user story)" -Type Warning
            continue
        }

        $featureId = Split-Path $FeaturePath -Leaf
        $tags = @($featureId, $taskId, "bolt-task")

        Write-StatusMessage "    Creating Task: $taskId - $taskTitle" -Type Info

        $workItem = New-AzureDevOpsWorkItem `
            -Type "Task" `
            -Title $taskTitle `
            -Description "Bolt Framework Bolt task from $FeaturePath/planning/tasks.md" `
            -ParentId $defaultParent `
            -Tags $tags `
            -RemainingWork $estimatedHours

        $createdTasks += @{
            workItemId   = $workItem.id
            boltBoltId = $tags[2]
            title        = $taskTitle
            state        = if ($isCompleted) { "Completed" } else { "To Do" }
        }

        $taskIndex++
    }

    return $createdTasks
}

# =============================================================================
# Main Script
# =============================================================================

Write-Host @"
╔═══════════════════════════════════════════════════════════════════════════╗
║                 Bolt Framework → Azure DevOps Synchronization                    ║
║                                                                           ║
║  Feature Path: $($FeaturePath.PadRight(58)) ║
║  Mode: $($Mode.PadRight(68)) ║
║  Dry Run: $($DryRun.ToString().PadRight(66)) ║
╚═══════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Step 1: Validate authentication
if (-not (Test-AzureDevOpsAuth)) {
    exit 1
}

# Step 2: Load existing metadata
$metadata = Get-FeatureMetadata -FeaturePath $FeaturePath
Write-StatusMessage "Feature ID: $($metadata.boltfFeatureId)" -Type Info

# Step 3: Check sync mode
if ($Mode -eq "Incremental" -and $metadata.azureDevOps.featureWorkItemId) {
    Write-StatusMessage "Feature already synced (ID: $($metadata.azureDevOps.featureWorkItemId))" -Type Info

    if (-not $Force) {
        $response = Read-Host "Feature already exists in DevOps. Continue? (y/n)"
        if ($response -ne 'y') {
            Write-StatusMessage "Sync cancelled by user" -Type Warning
            exit 0
        }
    }
}

# Step 4: Sync Feature
$featureWorkItemId = Sync-Feature -FeaturePath $FeaturePath -Metadata $metadata
if ($featureWorkItemId -and $featureWorkItemId -gt 0) {
    $metadata.azureDevOps.featureWorkItemId = $featureWorkItemId
}

# Step 5: Sync User Stories
$userStories = Sync-UserStories `
    -FeaturePath $FeaturePath `
    -ParentFeatureId $featureWorkItemId `
    -Metadata $metadata

# Ensure $userStories is always an array
if ($null -eq $userStories) { $userStories = @() }
if ($userStories.Count -gt 0) {
    $metadata.azureDevOps.userStories = $userStories
}

# Step 6: Sync Tasks
$tasks = Sync-Tasks `
    -FeaturePath $FeaturePath `
    -UserStories $userStories `
    -Metadata $metadata

# Ensure $tasks is always an array
if ($null -eq $tasks) { $tasks = @() }
if ($tasks.Count -gt 0) {
    $metadata.azureDevOps.tasks = $tasks
}

# Step 7: Save metadata
if (-not $DryRun) {
    Save-FeatureMetadata -FeaturePath $FeaturePath -Metadata $metadata
}

# Step 8: Summary
Write-Host "`n" -NoNewline
Write-Host "╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                          Sync Complete                                    ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Feature:       Work Item #$($featureWorkItemId.ToString().PadRight(49)) ║" -ForegroundColor Green
Write-Host "║  User Stories:  $($userStories.Count.ToString().PadRight(60)) ║" -ForegroundColor Green
Write-Host "║  Tasks:         $($tasks.Count.ToString().PadRight(60)) ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  View in Azure DevOps:                                                    ║" -ForegroundColor Green
Write-Host "║  $($script:Config.Organization)/$($script:Config.Project)/_workitems/edit/$featureWorkItemId" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️  DRY RUN - No changes were made to Azure DevOps" -ForegroundColor Yellow
}
