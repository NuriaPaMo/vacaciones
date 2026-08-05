---
name: azdo-sync
description: Bidirectional sync between Bolt Framework specs/ and Azure DevOps work items including Features, User Stories, and Tasks. Use when syncing specifications to Azure DevOps backlog, pushing features to AzDO, or pulling work items to local specs. Triggers => "sync Azure DevOps", "push to AzDO", "backlog sync", "work item sync", "feature to Azure DevOps", "specs to work items", "AzDO integration", "import from AzDO", "bidirectional sync".
---

# Azure DevOps Sync

## When to Use

- Push feature specs from `specs/XXX/` to Azure DevOps backlog
- Pull task status updates from DevOps to BOLT
- Import existing DevOps work items into Bolt Framework format
- When creating or updating a feature manually or with @Bolt Feature, @Bolt Clarify or @Bolt Specify agents
- When creating the Technical Plan with @Bolt Plan agent
- When creating the Bolt tasks with @Bolt Bolt agent
- When creating or updating User Stories with @Bolt Use Case agent
- Whenever the user wantks to synchronize with Azure DevOps

## Setup

### Environment Variables

All scripts (PowerShell and Bash) rely on environment variables for configuration.
A template is provided at `.boltf/available-skills/azdo-sync/templates/template.env`.

```bash
# Copy the template to the project root
cp .boltf/available-skills/azdo-sync/templates/template.env .env
# Edit .env and set your PAT (NEVER commit this file)
```

| Variable                    | Required | Default                       | Description                          |
| --------------------------- | -------- | ----------------------------- | ------------------------------------ |
| `AZURE_DEVOPS_EXT_PAT`      | **Yes**  | —                             | Personal Access Token for DevOps CLI |
| `AZURE_DEVOPS_ORG`          | No       | `https://dev.azure.com/<org>` | Organization URL                     |
| `AZURE_DEVOPS_PROJECT`      | No       | `<project-name>`              | Project name                         |
| `AZURE_DEVOPS_AREA_PATH`    | No       | Same as project name          | Default Area Path                    |
| `AZURE_DEVOPS_ITERATION`    | No       | Same as project name          | Default root Iteration Path          |
| `AZURE_DEVOPS_REQUIRED_TAG` | No       | `Bolt Framework`              | Tag applied to ALL work items        |

Bash scripts auto-load `.env` via the shared `_env-loader.sh` helper.
PowerShell scripts read `AZURE_DEVOPS_EXT_PAT` from the environment; set it before running.

### Prerequisites

```powershell
# Windows — Install Azure CLI + DevOps extension
winget install -e --id Microsoft.AzureCLI
az extension add --name azure-devops
az devops configure --defaults organization=https://dev.azure.com/<your-org> project="<your-project>"
```

```bash
# Linux/macOS — Install Azure CLI + DevOps extension + jq
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash   # Debian/Ubuntu
az extension add --name azure-devops
sudo apt-get install -y jq   # or: brew install jq
az devops configure --defaults organization=https://dev.azure.com/<your-org> project="<your-project>"
```

## Mappings

| BOLT → DevOps     | Source                         | State Mapping                                          |
| ----------------- | ------------------------------ | ------------------------------------------------------ |
| Feature → Feature | `specs/XXX/feature.md`         | DISCOVERY=New, CONSTRUCTION=Active, PRODUCTION=Closed  |
| User Story → PBI  | `requirements/requirements.md` | not-started=New, in-progress=Committed, completed=Done |
| Task → Task       | `planning/tasks.md`            | `[ ]`=To Do, `[x]`=Done                                |

📘 See [mappings/](mappings/) for field mapping JSON files

## Usage

### PowerShell (Windows)

```powershell
# Push specs to DevOps
.\.boltf\available-skills\azdo-sync\scripts\powershell\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking"

# Pull status updates
.\.boltf\available-skills\azdo-sync\scripts\powershell\Sync-DevOpsStatus.ps1 -FeaturePath "specs/001-time-tracking"

# Import existing work item
.\.boltf\available-skills\azdo-sync\scripts\powershell\Import-DevOpsToBolt.ps1 -WorkItemId 12345 -OutputPath "specs/002-imported"

# Assign work items to a sprint
.\.boltf\available-skills\azdo-sync\scripts\powershell\Assign-WorkItemsToSprint.ps1 -StartId 31530 -EndId 31604 -SprintNumber 1

# Fix tags and parent-child relationships
.\.boltf\available-skills\azdo-sync\scripts\powershell\Fix-DevOpsWorkItems.ps1 -StartId 31530 -EndId 31604

# Verify parent-child link integrity
.\.boltf\available-skills\azdo-sync\scripts\powershell\Verify-ParentChildLinks.ps1
```

### Bash (Linux / macOS / WSL / Git Bash)

All bash scripts auto-load `.env` from the project root via `_env-loader.sh`. Pass `-h` to any script for help.

```bash
# Push specs to DevOps
.boltf/available-skills/azdo-sync/scripts/bash/sync-bolt-to-devops.sh \
  -f "specs/001-time-tracking"

# Push specs (dry-run preview)
.boltf/available-skills/azdo-sync/scripts/bash/sync-bolt-to-devops.sh \
  -f "specs/001-time-tracking" -d

# Push specs (full sync, skip confirmation)
.boltf/available-skills/azdo-sync/scripts/bash/sync-bolt-to-devops.sh \
  -f "specs/001-time-tracking" -m full --force

# Pull status updates for one feature
.boltf/available-skills/azdo-sync/scripts/bash/sync-devops-status.sh \
  -f "specs/001-time-tracking"

# Pull status for ALL features and auto-commit
.boltf/available-skills/azdo-sync/scripts/bash/sync-devops-status.sh -c

# Import existing DevOps Feature into Bolt Framework format
.boltf/available-skills/azdo-sync/scripts/bash/import-devops-to-bolt.sh \
  -i 12345 -o "specs/002-imported"

# Import without children (Feature only)
.boltf/available-skills/azdo-sync/scripts/bash/import-devops-to-bolt.sh \
  -i 12345 -o "specs/002-imported" --no-children

# Assign work items to Sprint 1
.boltf/available-skills/azdo-sync/scripts/bash/assign-work-items-to-sprint.sh \
  -s 31530 -e 31604 -n 1

# Assign (dry-run preview)
.boltf/available-skills/azdo-sync/scripts/bash/assign-work-items-to-sprint.sh \
  -s 31530 -e 31604 -n 1 -d

# Fix tags and parent-child relationships
.boltf/available-skills/azdo-sync/scripts/bash/fix-devops-work-items.sh \
  -s 31530 -e 31604

# Fix (dry-run preview)
.boltf/available-skills/azdo-sync/scripts/bash/fix-devops-work-items.sh \
  -s 31530 -e 31604 -d

# Verify parent-child links (default range 31534-31604)
.boltf/available-skills/azdo-sync/scripts/bash/verify-parent-child-links.sh

# Verify with custom range
.boltf/available-skills/azdo-sync/scripts/bash/verify-parent-child-links.sh \
  -s 31534 -e 31604
```

## Git Integration

Link commits to work items:

```bash
git commit -m "feat(AB#12345): Implement core feature logic"
```

**Note:** Replace `AB#` with your organization's work item prefix (e.g., `WI#`, `ID#`, etc.)

## Work flow

1. Check the current feature we are working on (e.g. check the current branch)
2. If the branch is a feature, check if there is a reference to a DevOps work item (e.g. AB#12345) in the commit messages
3. If there is a reference, check if the work item exists in DevOps
4. If it does not exist, create it based on the Bolt Framework documentation, link it to the commit and update the documentation with the new work item ID
5. If the branch is a bolt, check if there is any work item in the documentation.
6. If there is a reference, check if the work item exists in DevOps
7. If it does not exist, create it based on the Bolt Framework documentation, ensure its parent id is the feature, link it to the commit and update the documentation with the new work item ID
8. If it exists, ensure the parent id is correct, link it to the commit and update the documentation if needed

**IMPORTANT**

- This workflow assumes that the branch naming convention includes the feature name (e.g. `feature/time-tracking`) and that commits reference work items using the `AB#` syntax. Adjust as needed for your specific workflow.

## Relationships

- All work items MUST be created with the appropriate parent-child relationships to maintain a clear hierarchy and traceability between features, user stories, and tasks. This ensures that the work items are organized correctly and can be easily navigated within Azure DevOps.
- All work items MUST be updated with dependences using ['Predecessor-Successor'](https://learn.microsoft.com/en-us/azure/devops/boards/backlogs/add-link?view=azure-devops&tabs=browser#link-several-work-items) [link types](https://learn.microsoft.com/en-us/azure/devops/boards/queries/link-type-reference?view=azure-devops&source=recommendations) to ensure that the relationships between work items are accurately represented and can be easily tracked within Azure DevOps. This is crucial for effective project management and ensuring that all team members have a clear understanding of the dependencies between different pieces of work.

## Sprints

- All work items MUST be assigned to the correct sprint based on the current development phase and timeline. This ensures that the work is properly scheduled and can be tracked effectively within Azure DevOps, allowing for better planning and resource allocation throughout the project lifecycle.
- The synchronization process MUST review first which Sprints are already available in Azure DevOps and create any missing ones based on the BOLT documentation. This ensures that all work items are assigned to the correct sprint and that the project timeline is accurately reflected in Azure DevOps, facilitating better project management and tracking.

### Iteration Path Format (CRITICAL)

> **IMPORTANT**: The `System.IterationPath` field does **NOT** include the `\Iteration\` segment from the classification tree path.

| Context                                                  | Format              | Example                                           |
| -------------------------------------------------------- | ------------------- | ------------------------------------------------- |
| Classification tree (`az boards iteration project list`) | `\Project\Sprint N` | `\YourProject\Sprint 1`                           |
| `System.IterationPath` field value                       | `Project\Sprint N`  | `YourProject\Sprint 1`                            |
| `az boards work-item update --iteration`                 | `Project\Sprint N`  | `YourProject\Sprint 1`                            |
| WIQL queries                                             | `Project\Sprint N`  | `[System.IterationPath] = 'YourProject\Sprint 1'` |

```powershell
# CORRECT - works for both CLI and REST API
az boards work-item update --id 12345 --iteration "YourProject\Sprint 1"

# WRONG - causes TF401347 error
az boards work-item update --id 12345 --iteration "YourProject\Sprint 1"
az boards work-item update --id 12345 --iteration "\YourProject\Sprint 1"
az boards work-item update --id 12345 --iteration "Sprint 1"
```

## Areas

- All work items MUST be assigned to the correct area based on the project structure and team organization. This ensures that the work is properly categorized and can be easily filtered and managed within Azure DevOps, allowing for better organization and visibility of the work being done across different teams and components of the project.

## Commits and Status

- Any work item created MUST include the tag 'Bolt Framework' to ensure it is easily identifiable and can be managed appropriately within Azure DevOps.
- All commits that reference a work item MUST be linked to that work item in Azure DevOps to maintain traceability between code changes and the corresponding work items, facilitating better project management and tracking of progress.

## Scripts Inventory

Scripts are available in both **PowerShell** and **Bash**. Both versions are functionally equivalent.
All scripts load configuration from the project-root `.env` file via shared loaders:

- **PowerShell**: `_EnvLoader.ps1` — dot-sourced automatically, builds `$script:Config`, provides `Write-StatusMessage`
- **Bash**: `_env-loader.sh` — sourced automatically, exports `$ORG`, `$PROJECT`, etc.

### PowerShell (`scripts/powershell/`)

| Script                         | Purpose                                                             |
| ------------------------------ | ------------------------------------------------------------------- |
| `_EnvLoader.ps1`               | Shared helper: loads `.env`, builds `$script:Config`, validates PAT |
| `Sync-BoltToDevOps.ps1`        | Push Bolt Framework specs to Azure DevOps work items                |
| `Sync-DevOpsStatus.ps1`        | Pull task status from DevOps and update Bolt Framework specs        |
| `Import-DevOpsToBolt.ps1`      | Import existing DevOps work items into Bolt Framework format        |
| `Assign-WorkItemsToSprint.ps1` | Bulk assign work items to a sprint/iteration                        |
| `Fix-DevOpsWorkItems.ps1`      | Fix tags ("Bolt Framework") and parent-child relationships          |
| `Verify-ParentChildLinks.ps1`  | Verify parent-child link integrity for tasks                        |

Template versions of the core sync scripts are preserved as `*.template.ps1` for reference.

### Bash (`scripts/bash/`)

| Script                           | Purpose                                                      |
| -------------------------------- | ------------------------------------------------------------ |
| `_env-loader.sh`                 | Shared helper: loads `.env`, sets config vars, validates     |
| `sync-bolt-to-devops.sh`         | Push Bolt Framework specs to Azure DevOps work items         |
| `sync-devops-status.sh`          | Pull task status from DevOps and update Bolt Framework specs |
| `import-devops-to-bolt.sh`       | Import existing DevOps work items into Bolt Framework format |
| `assign-work-items-to-sprint.sh` | Bulk assign work items to a sprint/iteration                 |
| `fix-devops-work-items.sh`       | Fix tags ("Bolt Framework") and parent-child relationships   |
| `verify-parent-child-links.sh`   | Verify parent-child link integrity for tasks                 |

> See [`templates/template.env`](templates/template.env) for a documented list of all environment variables.

## References

- [Azure DevOps CLI Docs](https://learn.microsoft.com/en-us/cli/azure/devops)
- PowerShell scripts: `.claude/skills/azure-devops-sync/scripts/powershell/`
- Bash scripts: `.claude/skills/azure-devops-sync/scripts/bash/`
- Environment template: `.claude/skills/azure-devops-sync/templates/template.env`
- Mappings: `.claude/skills/azure-devops-sync/mappings/`
- [Link Types References](https://learn.microsoft.com/en-us/azure/devops/boards/queries/link-type-reference?view=azure-devops&source=recommendations)
