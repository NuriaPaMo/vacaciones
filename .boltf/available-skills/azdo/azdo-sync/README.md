# Azure DevOps Sync Skill

> **Bidirectional synchronization between Bolt Framework and Azure DevOps**

## Overview

This skill enables seamless integration between Bolt Framework Methodology artifacts and Azure DevOps work items, ensuring development teams can leverage both the structured BOLT approach and Azure DevOps Boards for project tracking.

## What This Skill Provides

### ✅ Capabilities

- **Push Sync**: Convert `specs/` folders → Azure DevOps Features/User Stories/Tasks
- **Pull Sync**: Import existing DevOps work items → Bolt Framework spec structure
- **Status Sync**: Update task completion states from DevOps → `planning/tasks.md`
- **Metadata Tracking**: Maintain bidirectional traceability with `.metadata/devops-sync.json`
- **Git Integration**: Link commits to work items using `AB#{id}` convention
- **Conflict Detection**: Identify simultaneous edits requiring manual resolution

### 📋 Artifact Mappings

| BOLT Artifact                    | Azure DevOps Work Item | Relationship     |
| -------------------------------- | ---------------------- | ---------------- |
| `specs/XXX-feature-name/`        | **Feature** (or Epic)  | 1:1              |
| User Story in `requirements.md`  | **User Story**         | N:1 (to Feature) |
| Bolt task in `planning/tasks.md` | **Task**               | N:1 (to Story)   |

## Quick Start

### 1. Setup Authentication

```powershell
# Install Azure DevOps CLI
winget install -e --id Microsoft.AzureCLI
az extension add --name azure-devops

# Create PAT at: https://dev.azure.com/<your-org>/_usersSettings/tokens
# Scopes: Work Items (Read, Write, & Manage)

# Configure
$env:AZURE_DEVOPS_EXT_PAT = "your-pat-token"
az devops configure --defaults organization=https://dev.azure.com/<your-org> project="<your-project>"

# Verify
az devops project show --project "<your-project>"
```

### 2. Push Bolt Feature to DevOps

```powershell
# After creating a feature with @Bolt Feature
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -DryRun

# If preview looks good, execute:
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking"
```

**Result**: Creates Feature work item with child User Stories and Tasks, generates `.metadata/devops-sync.json`

### 3. Pull Status Updates from DevOps

```powershell
# Sync task completion states (run in CI/CD or manually)
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-DevOpsStatus.ps1 -FeaturePath "specs/001-time-tracking"

# Auto-commit changes
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-DevOpsStatus.ps1 -AutoCommit
```

**Result**: Updates checkboxes in `planning/tasks.md` based on DevOps task states

### 4. Import Existing DevOps Backlog

```powershell
# Find existing Features
az boards work-item query `
  --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Feature'" `
  --output table

# Import Feature #12345
.\.claude\skills\azure-devops-sync\scripts\powershell\Import-DevOpsToBolt.ps1 `
  -WorkItemId 12345 `
  -OutputPath "specs/001-time-tracking" `
  -IncludeChildren
```

**Result**: Generates Bolt Framework spec folder from existing DevOps work items

## File Structure

After sync, each feature will have:

```text
specs/001-time-tracking/
├── feature.md                    # Feature description
├── requirements/
│   └── requirements.md           # User stories
├── planning/
│   ├── plan.md                   # Implementation plan
│   └── tasks.md                  # Bolt tasks with status
└── .metadata/
    └── devops-sync.json          # Sync metadata ⭐
```

**devops-sync.json** example:

```json
{
  "version": "1.0.0",
  "boltFeatureId": "001-time-tracking",
  "azureDevOps": {
    "organization": "https://dev.azure.com/<your-org>",
    "project": "<your-project>",
    "featureWorkItemId": 12345,
    "userStories": [
      {
        "workItemId": 12346,
        "boltStoryId": "US-001",
        "title": "Log daily hours",
        "state": "Active"
      }
    ],
    "tasks": [
      {
        "workItemId": 12347,
        "boltTaskId": "001-time-tracking-001",
        "title": "Implement TimeEntry aggregate",
        "state": "Completed"
      }
    ]
  },
  "lastSync": "2026-02-13T22:45:00Z",
  "syncDirection": "bidirectional"
}
```

## Scripts Reference

### Sync-BoltToDevOps.ps1

**Purpose**: Push Bolt Framework specs → Azure DevOps

**Parameters**:

- `-FeaturePath` (required): Path to feature folder
- `-Mode` (Full|Incremental): Sync mode (default: Incremental)
- `-DryRun`: Preview changes without creating work items
- `-Force`: Skip confirmation prompts

**Example**:

```powershell
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-BoltToDevOps.ps1 `
  -FeaturePath "specs/001-time-tracking" `
  -Mode Incremental `
  -DryRun
```

### Import-DevOpsToBolt.ps1

**Purpose**: Pull Azure DevOps work items → Bolt Framework specs

**Parameters**:

- `-WorkItemId` (required): Feature work item ID
- `-OutputPath` (required): Target spec folder path
- `-IncludeChildren`: Import User Stories and Tasks (default: true)
- `-Force`: Overwrite existing folder

**Example**:

```powershell
.\.claude\skills\azure-devops-sync\scripts\powershell\Import-DevOpsToBolt.ps1 `
  -WorkItemId 12345 `
  -OutputPath "specs/001-time-tracking" `
  -IncludeChildren
```

### Sync-DevOpsStatus.ps1

**Purpose**: Update task statuses from Azure DevOps

**Parameters**:

- `-FeaturePath` (optional): Specific feature (omit for all)
- `-AutoCommit`: Automatically commit changes to git

**Example**:

```powershell
# Sync all features
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-DevOpsStatus.ps1 -AutoCommit

# Sync specific feature
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-DevOpsStatus.ps1 -FeaturePath "specs/001-time-tracking"
```

## Best Practices

### 1. Tagging Convention

Always tag work items with `BOLT` for filtering:

```powershell
# Query all BOLT work items
az boards work-item query `
  --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.Tags] CONTAINS 'BOLT'" `
  --output table
```

### 2. Commit Message Convention

Link commits to work items:

```bash
git commit -m "AB#12347 Implement TimeEntry aggregate

- Created TimeEntry aggregate root
- Added business rule validation

Related: specs/001-time-tracking/"
```

### 3. Sync Frequency

| Phase        | Recommended Frequency         |
| ------------ | ----------------------------- |
| DISCOVERY    | Once per planning session     |
| CONSTRUCTION | Twice daily (automated CI/CD) |
| TRANSITION   | Hourly during release         |
| PRODUCTION   | Daily for operational items   |

### 4. Dry Run First

**Always preview changes before bulk operations:**

```powershell
# Preview
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -DryRun

# Review output, then execute if correct
.\.claude\skills\azure-devops-sync\scripts\powershell\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking"
```

## CI/CD Integration

Add to Azure DevOps Pipeline:

```yaml
# azure-pipelines.yml

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - specs/**

pool:
  vmImage: 'windows-latest'

steps:
  - task: PowerShell@2
    displayName: 'Sync Task Statuses from DevOps'
    inputs:
      targetType: 'filePath'
      filePath: '.claude/skills/azure-devops-sync/scripts/powershell/Sync-DevOpsStatus.ps1'
      arguments: '-AutoCommit'
    env:
      AZURE_DEVOPS_EXT_PAT: $(DevOpsPAT) # Secure variable

  - task: PowerShell@2
    displayName: 'Push New Features to DevOps'
    inputs:
      targetType: 'filePath'
      filePath: '.claude/skills/azure-devops-sync/scripts/powershell/Sync-BoltToDevOps.ps1'
      arguments: '-Mode Incremental'
    env:
      AZURE_DEVOPS_EXT_PAT: $(DevOpsPAT)
```

## Troubleshooting

### Authentication Errors

```text
ERROR: Failed to connect to Azure DevOps
```

**Solution**:

```powershell
# Verify PAT is set
$env:AZURE_DEVOPS_EXT_PAT | Out-Null
if (-not $?) { Write-Host "PAT not set!" }

# Verify defaults
az devops configure --list

# Re-authenticate
az devops login --organization https://dev.azure.com/<your-org>
```

### Duplicate Work Items

```text
Work item already exists (ID: 12345)
```

**Solution**: Use `-Mode Incremental` to skip existing items, or check `.metadata/devops-sync.json` for tracking.

### Sync Conflicts

```text
Both BOLT and DevOps modified simultaneously
```

**Solution**: Manual merge required. Review both sources and decide which has correct information.

## Security Notes

⚠️ **NEVER commit PAT to git repository**

✅ **Secure PAT storage options**:

- Azure Key Vault
- GitHub Secrets (for Actions)
- Azure DevOps Variable Groups (secure variables)
- 1Password / LastPass

✅ **PAT Scope**: Minimum required = `Work Items (Read, Write, & Manage)`

✅ **Rotation**: Set PAT expiration to 90 days maximum

## References

- [SKILL.md](.claude/skills/azure-devops-sync/SKILL.md) - Complete documentation
- [Constitution Article XI](.boltf/memory/constitution.md#article-xi-cicd) - DevOps configuration
- [Azure DevOps CLI Docs](https://learn.microsoft.com/en-us/cli/azure/devops)
- [Work Items REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items)

---

**Skill Version**: 1.0.0
**Last Updated**: 2026-02-13
**BOLT Compatibility**: 1.0.0+
