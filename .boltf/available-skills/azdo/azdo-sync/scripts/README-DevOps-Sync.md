# Azure DevOps Synchronization Scripts

> Scripts para sincronizar Bolt Framework con Azure DevOps Boards

## Scripts Disponibles

| Script                    | Propósito                                       | Dirección               |
| ------------------------- | ----------------------------------------------- | ----------------------- |
| `Sync-BoltToDevOps.ps1`   | Crear work items desde specs Bolt Framework     | Bolt Framework → DevOps |
| `Import-DevOpsToBolt.ps1` | Importar work items existentes a Bolt Framework | DevOps → Bolt Framework |
| `Sync-DevOpsStatus.ps1`   | Actualizar estados de tareas                    | DevOps → Bolt Framework |

## Requisitos Previos

### 1. Instalar Azure DevOps CLI

```powershell
# Instalar Azure CLI
winget install -e --id Microsoft.AzureCLI

# Instalar extensión Azure DevOps
az extension add --name azure-devops

# Verificar instalación
az devops --version
```

### 2. Crear Personal Access Token (PAT)

1. Ir a: `https://dev.azure.com/<your-org>/_usersSettings/tokens`
2. Crear nuevo token con scopes:
   - ✅ **Work Items** (Read, Write, & Manage)
   - ✅ **Code** (Read) - para linkear commits
   - ✅ **Build** (Read) - para pipelines

### 3. Configurar Autenticación

```powershell
# Configurar PAT (solo para la sesión actual)
$env:AZURE_DEVOPS_EXT_PAT = "tu-pat-token-aqui"

# Configurar defaults
az devops configure --defaults `
  organization=https://dev.azure.com/<your-org> `
  project="<your-project>"

# Verificar conexión
az devops project show --project "<your-project>"
```

⚠️ **NUNCA comitear el PAT al repositorio**

## Uso

### Sync-BoltToDevOps.ps1

Crea work items en Azure DevOps desde una feature Bolt Framework.

**Sintaxis**:

```powershell
.\Sync-BoltToDevOps.ps1 -FeaturePath <ruta> [-Mode <Full|Incremental>] [-DryRun] [-Force]
```

**Ejemplos**:

```powershell
# Preview - ver qué se crearía sin ejecutar
.\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -DryRun

# Sync incremental (solo nuevos items)
.\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -Mode Incremental

# Sync completo (recrear todo)
.\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -Mode Full -Force
```

**Output**:

- Crea Feature work item
- Crea User Stories como hijos del Feature
- Crea Tasks como hijos de User Stories
- Genera `.metadata/devops-sync.json` con IDs de trabajo

### Import-DevOpsToBolt.ps1

Importa work items existentes de Azure DevOps a estructura Bolt Framework.

**Sintaxis**:

```powershell
.\Import-DevOpsToBolt.ps1 -WorkItemId <id> -OutputPath <ruta> [-IncludeChildren] [-Force]
```

**Ejemplos**:

```powershell
# Listar Features disponibles
az boards work-item query `
  --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Feature'" `
  --output table

# Importar Feature con User Stories y Tasks
.\Import-DevOpsToBolt.ps1 `
  -WorkItemId 12345 `
  -OutputPath "specs/001-time-tracking" `
  -IncludeChildren

# Importar solo Feature (sin hijos)
.\Import-DevOpsToBolt.ps1 `
  -WorkItemId 12345 `
  -OutputPath "specs/001-time-tracking" `
  -IncludeChildren:$false
```

**Output**:

- `specs/XXX-feature-name/feature.md`
- `specs/XXX-feature-name/requirements/requirements.md`
- `specs/XXX-feature-name/planning/tasks.md`
- `specs/XXX-feature-name/.metadata/devops-sync.json`

### Sync-DevOpsStatus.ps1

Actualiza estados de tareas desde Azure DevOps a Bolt Framework.

**Sintaxis**:

```powershell
.\Sync-DevOpsStatus.ps1 [-FeaturePath <ruta>] [-AutoCommit]
```

**Ejemplos**:

```powershell
# Sync una feature específica
.\Sync-DevOpsStatus.ps1 -FeaturePath "specs/001-time-tracking"

# Sync todas las features
.\Sync-DevOpsStatus.ps1

# Sync todas y auto-commit cambios
.\Sync-DevOpsStatus.ps1 -AutoCommit
```

**Output**:

- Actualiza checkboxes en `planning/tasks.md`
- Actualiza timestamps en `.metadata/devops-sync.json`
- Opcionalmente comitea cambios a git

## Flujo de Trabajo Típico

### Escenario 1: Nueva Feature Bolt Framework → DevOps

```powershell
# 1. Crear feature con @Bolt Feature
# @Bolt Feature create time tracking feature

# 2. Preview sync
.\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking" -DryRun

# 3. Ejecutar sync
.\Sync-BoltToDevOps.ps1 -FeaturePath "specs/001-time-tracking"

# 4. Verificar en Azure DevOps
# https://dev.azure.com/<your-org>/<your-project>/_backlogs
```

### Escenario 2: Importar Backlog Existente

```powershell
# 1. Listar features en DevOps
az boards work-item query `
  --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Feature'" `
  --output table

# 2. Importar Feature #10025
.\Import-DevOpsToBolt.ps1 -WorkItemId 10025 -OutputPath "specs/002-user-management"

# 3. Refinar con Bolt Framework agents
# @Bolt Feature review specs/002-user-management
```

### Escenario 3: Sync Diario de Estados (CI/CD)

```powershell
# Ejecutar en pipeline o tarea programada
.\Sync-DevOpsStatus.ps1 -AutoCommit
```

## Metadata de Sync

Cada feature sincronizada tiene `.metadata/devops-sync.json`:

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
  "lastSync": "2026-02-14T10:30:00Z",
  "syncDirection": "bidirectional"
}
```

## Integración CI/CD

### Azure DevOps Pipeline

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
      AZURE_DEVOPS_EXT_PAT: $(DevOpsPAT) # Variable segura en pipeline

  - task: PowerShell@2
    displayName: 'Push New Features to DevOps'
    inputs:
      targetType: 'filePath'
      filePath: '.claude/skills/azure-devops-sync/scripts/powershell/Sync-BoltToDevOps.ps1'
      arguments: '-Mode Incremental'
    env:
      AZURE_DEVOPS_EXT_PAT: $(DevOpsPAT)
```

## Convenciones

### Tags en Work Items

Todos los work items sincronizados tienen tags:

- `BOLT` - Identifica items gestionados por Bolt Framework
- `001-time-tracking` - Feature ID
- `US-001` - User Story ID (para stories)
- `bolt` - Identifica Bolt tasks

### Commits Vinculados

Usar `AB#{WorkItemId}` en commits para linkear:

```bash
git commit -m "AB#12347 Implement TimeEntry aggregate

- Created aggregate root with business rules
- Added domain events

Related: specs/001-time-tracking/"
```

## Troubleshooting

### Error: "Failed to connect to Azure DevOps"

**Solución**:

```powershell
# Verificar PAT
if (-not $env:AZURE_DEVOPS_EXT_PAT) {
    Write-Host "PAT no configurado. Ejecutar:"
    Write-Host '  $env:AZURE_DEVOPS_EXT_PAT = "tu-token"'
}

# Re-autenticar
az devops login --organization https://dev.azure.com/<your-org>
```

### Error: "Work item already exists"

**Solución**: Verificar `.metadata/devops-sync.json` - el item ya fue sincronizado. Usar `-Mode Incremental`.

### Cambios No Detectados

**Solución**: Verificar timestamp `lastSync` en metadata vs `System.ChangedDate` del work item.

## Referencias

- **Skill Completo**: [.claude/skills/azure-devops-sync/SKILL.md](../../.claude/skills/azure-devops-sync/SKILL.md)
- **Agente**: [@bolt-az-devops-sync](../../.github/agents/bolt-az-devops-sync.agent.md)
- **Constitution**: [.boltf/memory/constitution.md](../../.boltf/memory/constitution.md) - Article XI (CI/CD)
- **Azure DevOps CLI Docs**: <https://learn.microsoft.com/en-us/cli/azure/devops>

---

**Versión**: 1.0.0
**Última actualización**: 2026-02-14
