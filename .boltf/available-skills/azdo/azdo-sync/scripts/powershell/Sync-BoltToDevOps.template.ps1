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

# =============================================================================
# Configuration
# =============================================================================

$script:Config = @{
    Organization = "https://dev.azure.com/jdmveira"
    Project      = "Registro Horario"
    AreaPath     = "Registro Horario"
    Iteration    = "Registro Horario\Sprint 1"  # TODO: Read from constitution or parameter
    TagPrefix    = "Bolt Framework"
    MappingsPath = Join-Path $PSScriptRoot "..\mappings"  # Path to mapping files
}

# =============================================================================
# Mapping Functions
# =============================================================================

function Get-WorkItemMapping {
    <#
    .SYNOPSIS
        Load work item mapping configuration from JSON file
    .PARAMETER WorkItemType
        Type of work item (Epic, Feature, ProductBacklogItem, Task, Bug)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Epic", "Feature", "ProductBacklogItem", "Task", "Bug")]
        [string]$WorkItemType
    )

    $mappingFile = switch ($WorkItemType) {
        "Epic"               { "epic-mapping.json" }
        "Feature"            { "feature-mapping.json" }
        "ProductBacklogItem" { "pbi-mapping.json" }
        "Task"               { "task-mapping.json" }
        "Bug"                { "bug-mapping.json" }
    }

    $mappingPath = Join-Path $script:Config.MappingsPath $mappingFile

    if (-not (Test-Path $mappingPath)) {
        throw "Mapping file not found: $mappingPath"
    }

    $mapping = Get-Content $mappingPath -Raw | ConvertFrom-Json

    Write-Verbose "Loaded mapping for $WorkItemType from $mappingPath"

    return $mapping
}

function Get-FieldValueFromBolt {
    <#
    .SYNOPSIS
        Extract field value from Bolt Framework artifact based on mapping definition
    .PARAMETER FilePath
        Path to Bolt Framework artifact file
    .PARAMETER FieldMapping
        Field mapping configuration from mapping file
    .PARAMETER Context
        Additional context (e.g., current phase, parent work item)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FieldMapping,

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{}
    )

    $boltSource = $FieldMapping.boltfSource

    # Handle null/empty source
    if ([string]::IsNullOrWhiteSpace($boltSource)) {
        return $FieldMapping.defaultValue
    }

    # Handle computed values
    if ($boltSource -like "computed:*") {
        $computation = $boltSource -replace "^computed:", ""
        return Invoke-ComputedValue -Computation $computation -Context $Context
    }

    # Handle inherited values
    if ($boltSource -like "inherited:*") {
        $inheritSource = $boltSource -replace "^inherited:", ""
        return $Context[$inheritSource]
    }

    # Handle file-based extraction
    if ($boltSource -match "(.+?)#(.+)") {
        $fileName = $Matches[1]
        $fieldName = $Matches[2]

        $fullPath = if (Test-Path $FilePath -PathType Container) {
            Join-Path $FilePath $fileName
        } else {
            Join-Path (Split-Path $FilePath -Parent) $fileName
        }

        if (-not (Test-Path $fullPath)) {
            Write-Warning "Source file not found: $fullPath for field $fieldName"
            return $FieldMapping.defaultValue
        }

        $content = Get-Content $fullPath -Raw

        # Try to extract from YAML frontmatter
        if ($content -match "^---\s*\n(.*?)\n---" -and $fieldName -ne "description") {
            $yamlBlock = $Matches[1]
            if ($yamlBlock -match "$fieldName\s*:\s*(.+)") {
                $value = $Matches[1].Trim()
                return $value
            }
        }

        # Try extraction pattern if specified
        if ($FieldMapping.extractPattern) {
            if ($content -match $FieldMapping.extractPattern) {
                $value = $Matches[1]
                return Apply-Transformation -Value $value -Transformation $FieldMapping.transformation
            }
        }

        # Fallback: extract section content
        if ($content -match "##\s*$fieldName\s*\n(.*?)(?=\n##|\z)") {
            $value = $Matches[1].Trim()
            return Apply-Transformation -Value $value -Transformation $FieldMapping.transformation
        }
    }

    # Return default if extraction failed
    return $FieldMapping.defaultValue
}

function Apply-Transformation {
    <#
    .SYNOPSIS
        Apply transformation to extracted value
    #>
    param(
        [string]$Value,
        [string]$Transformation
    )

    if ([string]::IsNullOrWhiteSpace($Transformation)) {
        return $Value
    }

    switch ($Transformation) {
        "markdown-to-html" {
            # Simple markdown to HTML conversion
            # In production, use a proper markdown library
            $html = $Value -replace "\*\*(.+?)\*\*", "<strong>`$1</strong>"
            $html = $html -replace "\*(.+?)\*", "<em>`$1</em>"
            $html = $html -replace "`n`n", "</p><p>"
            $html = "<p>$html</p>"
            return $html
        }
        "markdown-to-html-list" {
            # Convert markdown list to HTML
            $lines = $Value -split "`n"
            $html = "<ul>"
            foreach ($line in $lines) {
                if ($line -match "^[\s-]*\*\s*(.+)") {
                    $html += "<li>$($Matches[1])</li>"
                }
            }
            $html += "</ul>"
            return $html
        }
        "html" {
            return $Value
        }
        "path" {
            # Ensure proper path format
            return $Value -replace "[\\/]", "\"
        }
        "semicolon-separated" {
            # Convert array or comma-separated to semicolon-separated
            if ($Value -is [array]) {
                return $Value -join ";"
            }
            return $Value -replace ",", ";"
        }
        default {
            return $Value
        }
    }
}

function Invoke-ComputedValue {
    <#
    .SYNOPSIS
        Compute field value based on computation rule
    #>
    param(
        [string]$Computation,
        [hashtable]$Context
    )

    switch ($Computation) {
        "bolt-phase" {
            # Map Bolt Framework phase to DevOps state
            $phase = $Context["boltPhase"]
            $stateMapping = @{
                "DISCOVERY"    = "New"
                "PLANNING"     = "Active"
                "CONSTRUCTION" = "Active"
                "TRANSITION"   = "Resolved"
                "PRODUCTION"   = "Closed"
            }
            return $stateMapping[$phase] ?? "New"
        }
        "tags" {
            # Generate tags
            $tags = @($script:Config.TagPrefix)
            if ($Context["featureId"]) { $tags += $Context["featureId"] }
            if ($Context["phase"]) { $tags += $Context["phase"] }
            return $tags -join ";"
        }
        "area-path" {
            # Compute area path from constitution or feature location
            return $script:Config.AreaPath
        }
        default {
            Write-Warning "Unknown computation: $Computation"
            return $null
        }
    }
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

    $prefix = switch ($Type) {
        "Info"    { "ℹ️" }
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error"   { "❌" }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

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

    $fields = @(
        "System.AreaPath=$($script:Config.AreaPath)",
        "System.IterationPath=$($script:Config.Iteration)",
        "System.Tags=$($Tags -join ';')"
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
        $result = az boards work-item create `
            --type $Type `
            --title $Title `
            --description $Description `
            --project $script:Config.Project `
            @fieldsArgs `
            --output json | ConvertFrom-Json

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

    $featureMd = Join-Path $FeaturePath "feature.md"
    $featureData = Read-FeatureMarkdown -Path $featureMd

    if (-not $featureData) {
        Write-StatusMessage "Skipping feature creation (no feature.md found)" -Type Warning
        return $null
    }

    $featureId = Split-Path $FeaturePath -Leaf
    $tags = @($script:Config.TagPrefix, $featureId)

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
    $content = Get-Content $requirementsPath -Raw
    $storyPattern = '(?m)### (.+)\s*\n(?:.*?\n)*?(?:- \*\*As a\*\*|As a) (.+?),? I want (.+?),? (?:so that|to) (.+?)(?:\n|$)'
    $stories = [regex]::Matches($content, $storyPattern)

    $createdStories = @()

    foreach ($match in $stories) {
        $storyTitle = $match.Groups[1].Value.Trim()
        $role = $match.Groups[2].Value.Trim()
        $goal = $match.Groups[3].Value.Trim()
        $benefit = $match.Groups[4].Value.Trim()

        $fullTitle = "As a $role I want $goal"
        $description = "**So that**: $benefit"

        # Extract acceptance criteria (lines starting with - [ ] after the story)
        $acPattern = "(?s)### $storyTitle.+?\n((?:- \[ \].+?\n)+)"
        $acMatch = [regex]::Match($content, $acPattern)
        $ac = if ($acMatch.Success) { $acMatch.Groups[1].Value } else { "" }

        $tags = @($script:Config.TagPrefix, (Split-Path $FeaturePath -Leaf), "US-" + ($createdStories.Count + 1))

        Write-StatusMessage "  Creating User Story: $storyTitle" -Type Info

        $workItem = New-AzureDevOpsWorkItem `
            -Type "User Story" `
            -Title $fullTitle `
            -Description $description `
            -AcceptanceCriteria $ac `
            -ParentId $ParentFeatureId `
            -Tags $tags

        $createdStories += @{
            workItemId     = $workItem.id
            boltStoryId  = $tags[2]
            title          = $storyTitle
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
    $taskPattern = '(?m)^- \[([ x])\] (.+?)(?:\s*\((\d+)h\))?$'
    $tasks = [regex]::Matches($content, $taskPattern)

    $createdTasks = @()
    $taskIndex = 1

    # For simplicity, assign all tasks to first user story
    # In production, would need smarter mapping logic
    $defaultParent = if ($UserStories.Count -gt 0) { $UserStories[0].workItemId } else { $null }

    foreach ($match in $tasks) {
        $isCompleted = $match.Groups[1].Value -eq 'x'
        $taskTitle = $match.Groups[2].Value.Trim()
        $estimatedHours = if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 4 }

        if (-not $defaultParent) {
            Write-StatusMessage "  Skipping task (no parent user story): $taskTitle" -Type Warning
            continue
        }

        $featureId = Split-Path $FeaturePath -Leaf
        $tags = @($script:Config.TagPrefix, "bolt", "$featureId-$($taskIndex.ToString('000'))")

        Write-StatusMessage "    Creating Task: $taskTitle" -Type Info

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

if ($userStories.Count -gt 0) {
    $metadata.azureDevOps.userStories = $userStories
}

# Step 6: Sync Tasks
$tasks = Sync-Tasks `
    -FeaturePath $FeaturePath `
    -UserStories $userStories `
    -Metadata $metadata

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
