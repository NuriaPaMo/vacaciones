# Smart Enablement Logic - Habilitación Inteligente de Items

## Resumen

Este documento define la **lógica de habilitación inteligente** que analiza las decisiones del usuario (almacenadas en `scopes.yaml`) y habilita/deshabilita automáticamente items en los `scope.yaml` files antes de la provisión.

## Objetivos

- ✅ **Automatización**: Habilitar items relevantes sin intervención manual
- ✅ **Contexto-driven**: Decisiones basadas en `use-aspire`, `work-management-tool`, `frontend-framework`, etc.
- ✅ **Transparencia**: Reportar qué se habilitó y por qué en el provision report
- ✅ **Idempotencia**: Ejecutable múltiples veces sin efectos secundarios

## Arquitectura

### Flujo de Ejecución

```text
1. Init.ps1 (Step 1.7)
   ├─ User answers dev environment questions
   └─ Saves decisions to scopes.yaml (project section)

2. @Bolt Constitution agent invoked
   ├─ Calls Invoke-BoltSetupConstitution.ps1
   └─ Script execution phases:

3. Phase 0: Smart Enablement (NEW)
   ├─ Read scopes.yaml (project metadata)
   ├─ For each active scope:
   │   ├─ Read scope.yaml
   │   ├─ Apply enablement rules
   │   └─ Update enabled/auto_provision flags in memory
   └─ Log changes (what was enabled/disabled and why)

4. Phase 1-5: Standard Provisioning
   ├─ Use updated scope.yaml data
   ├─ Copy files (only enabled + auto_provision: true)
   └─ Generate provision report
```

### Ubicación de la Lógica

**Opción Elegida**: Implementar en `Invoke-BoltSetupConstitution.ps1` como **Phase 0**

**Razones**:

- ✅ Contexto completo disponible (scopes.yaml ya generado)
- ✅ Centraliza lógica de provisión en 1 script
- ✅ Permite dry-run para preview de habilitaciones
- ✅ No complica Init.ps1 (mantiene simplicidad)

---

## Reglas de Habilitación

### 1. Aspire Orchestration (`use-aspire: true`)

**Objetivo**: Habilitar observabilidad frontend cuando Aspire está activo

**Items afectados**:

```yaml
# frontend/scope.yaml
- id: frontend-aspire-opentelemetry
  enabled: false → true # ENABLED if use-aspire: true
  auto_provision: false → true
```

**Lógica**:

```powershell
if ($projectMetadata.UseAspire -eq "true") {
    Enable-Item -ScopeId "frontend" -ItemId "frontend-aspire-opentelemetry" `
        -Reason "Aspire orchestration enabled (E2E tracing)"
}
```

---

### 2. Work Management Tool

**Objetivo**: Habilitar skills/prompts específicos según la herramienta seleccionada

**Items afectados**:

```yaml
# work-management/scope.yaml

# Azure Boards
- id: work-management-azure-devops-sync-skill
  enabled: false → true # ENABLED if work-management-tool: azure-boards

- id: work-management-azure-boards-context7
  enabled: false → true # ENABLED if work-management-tool: azure-boards

# GitHub Projects
- id: work-management-github-projects-context7
  enabled: false → true # ENABLED if work-management-tool: github-projects

# integration/scope.yaml
- id: integration-azure-devops-sync-skill
  enabled: false → true # ENABLED if work-management-tool: azure-boards
```

**Lógica**:

```powershell
switch ($projectMetadata.WorkManagementTool) {
    "azure-boards" {
        Enable-Item -ScopeId "work-management" `
            -ItemId "work-management-azure-devops-sync-skill" `
            -Reason "Azure Boards integration enabled"

        Enable-Item -ScopeId "work-management" `
            -ItemId "work-management-azure-boards-context7" `
            -Reason "Azure Boards prompts enabled"

        Enable-Item -ScopeId "integration" `
            -ItemId "integration-azure-devops-sync-skill" `
            -Reason "Azure DevOps sync capability enabled"
    }

    "github-projects" {
        Enable-Item -ScopeId "work-management" `
            -ItemId "work-management-github-projects-context7" `
            -Reason "GitHub Projects prompts enabled"
    }

    "jira" {
        # Future: Jira-specific items
        Write-Verbose "Jira integration not yet implemented"
    }
}
```

---

### 3. Frontend Framework

**Objetivo**: Habilitar instructions específicas del framework seleccionado

**Items afectados**:

```yaml
# frontend/scope.yaml

- id: frontend-react-awesome
  enabled: false → true # ENABLED if frontend-framework: react

- id: frontend-angular-awesome
  enabled: false → true # ENABLED if frontend-framework: angular

- id: frontend-vue-awesome
  enabled: false → true # ENABLED if frontend-framework: vue
```

**Lógica**:

```powershell
switch ($projectMetadata.FrontendFramework) {
    "react" {
        Enable-Item -ScopeId "frontend" -ItemId "frontend-react-awesome" `
            -Reason "React framework selected"
    }
    "angular" {
        Enable-Item -ScopeId "frontend" -ItemId "frontend-angular-awesome" `
            -Reason "Angular framework selected"
    }
    "vue" {
        Enable-Item -ScopeId "frontend" -ItemId "frontend-vue-awesome" `
            -Reason "Vue.js framework selected"
    }
    "none" {
        Write-Verbose "No frontend framework selected — manual provisioning"
    }
}
```

---

### 4. Local Orchestration

**Objetivo**: Habilitar templates de orquestación según la herramienta elegida

**Items afectados** (futuro):

```yaml
# cloud-platform/scope.yaml

- id: cloud-platform-docker-compose-template
  enabled: false → true # ENABLED if local-orchestration: docker-compose

- id: cloud-platform-kubernetes-local-template
  enabled: false → true # ENABLED if local-orchestration: kubernetes

- id: cloud-platform-podman-compose-template
  enabled: false → true # ENABLED if local-orchestration: podman
```

**Lógica**:

```powershell
switch ($projectMetadata.LocalOrchestration) {
    "docker-compose" {
        Enable-Item -ScopeId "cloud-platform" `
            -ItemId "cloud-platform-docker-compose-template" `
            -Reason "Docker Compose orchestration selected"
    }
    "kubernetes" {
        Enable-Item -ScopeId "cloud-platform" `
            -ItemId "cloud-platform-kubernetes-local-template" `
            -Reason "Kubernetes local dev (minikube/kind)"
    }
    "podman" {
        Enable-Item -ScopeId "cloud-platform" `
            -ItemId "cloud-platform-podman-compose-template" `
            -Reason "Podman Compose orchestration"
    }
    "aspire" {
        # Already handled by use-aspire flag
        Write-Verbose "Aspire orchestration already provisioned"
    }
}
```

---

### 5. Cloud Development Environment

**Objetivo**: Provisionar devcontainer.json y GitHub Codespaces configs

**Items afectados** (futuro):

```yaml
# common/scope.yaml

- id: common-devcontainer-template
  enabled: false → true # ENABLED if cloud-dev-environment: devcontainers | both

- id: common-codespaces-config
  enabled: false → true # ENABLED if cloud-dev-environment: codespaces | both
```

**Lógica**:

```powershell
if ($projectMetadata.CloudDevEnvironment -in @("devcontainers", "both")) {
    Enable-Item -ScopeId "common" -ItemId "common-devcontainer-template" `
        -Reason "Devcontainers enabled"
}

if ($projectMetadata.CloudDevEnvironment -in @("codespaces", "both")) {
    Enable-Item -ScopeId "common" -ItemId "common-codespaces-config" `
        -Reason "GitHub Codespaces configuration enabled"
}
```

---

## Implementación en PowerShell

### Función: `Enable-ConditionalItems`

```powershell
<#
.SYNOPSIS
Smart enablement of scope items based on project metadata

.DESCRIPTION
Reads project decisions from scopes.yaml and enables/disables items in scope.yaml
files based on context (use-aspire, work-management-tool, frontend-framework, etc.)

.PARAMETER ProjectMetadata
Hashtable with project metadata from scopes.yaml

.PARAMETER Scopes
Array of scope objects (parsed from scope.yaml files)

.OUTPUTS
Array of enablement changes (for reporting)
#>
function Enable-ConditionalItems {
    param(
        [hashtable]$ProjectMetadata,
        [array]$Scopes
    )

    $changes = @()

    # ─────────────────────────────────────────────────────────────────────────
    # RULE 1: Aspire Orchestration
    # ─────────────────────────────────────────────────────────────────────────
    if ($ProjectMetadata.UseAspire -eq "true") {
        $change = Enable-Item -Scopes $Scopes `
            -ScopeId "frontend" `
            -ItemId "frontend-aspire-opentelemetry" `
            -Reason "Aspire orchestration enabled (E2E tracing)"

        if ($change) { $changes += $change }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # RULE 2: Work Management Tool
    # ─────────────────────────────────────────────────────────────────────────
    switch ($ProjectMetadata.WorkManagementTool) {
        "azure-boards" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "work-management" `
                -ItemId "work-management-azure-devops-sync-skill" `
                -Reason "Azure Boards integration enabled"
            if ($change) { $changes += $change }

            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "work-management" `
                -ItemId "work-management-azure-boards-context7" `
                -Reason "Azure Boards prompts enabled"
            if ($change) { $changes += $change }

            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "integration" `
                -ItemId "integration-azure-devops-sync-skill" `
                -Reason "Azure DevOps sync capability enabled"
            if ($change) { $changes += $change }
        }

        "github-projects" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "work-management" `
                -ItemId "work-management-github-projects-context7" `
                -Reason "GitHub Projects prompts enabled"
            if ($change) { $changes += $change }
        }

        "jira" {
            Write-Verbose "Jira integration not yet implemented (future)"
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # RULE 3: Frontend Framework
    # ─────────────────────────────────────────────────────────────────────────
    switch ($ProjectMetadata.FrontendFramework) {
        "react" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "frontend" `
                -ItemId "frontend-react-awesome" `
                -Reason "React framework selected"
            if ($change) { $changes += $change }
        }

        "angular" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "frontend" `
                -ItemId "frontend-angular-awesome" `
                -Reason "Angular framework selected"
            if ($change) { $changes += $change }
        }

        "vue" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "frontend" `
                -ItemId "frontend-vue-awesome" `
                -Reason "Vue.js framework selected"
            if ($change) { $changes += $change }
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # RULE 4: Local Orchestration
    # ─────────────────────────────────────────────────────────────────────────
    switch ($ProjectMetadata.LocalOrchestration) {
        "docker-compose" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "cloud-platform" `
                -ItemId "cloud-platform-docker-compose-template" `
                -Reason "Docker Compose orchestration selected"
            if ($change) { $changes += $change }
        }

        "kubernetes" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "cloud-platform" `
                -ItemId "cloud-platform-kubernetes-local-template" `
                -Reason "Kubernetes local dev (minikube/kind)"
            if ($change) { $changes += $change }
        }

        "podman" {
            $change = Enable-Item -Scopes $Scopes `
                -ScopeId "cloud-platform" `
                -ItemId "cloud-platform-podman-compose-template" `
                -Reason "Podman Compose orchestration"
            if ($change) { $changes += $change }
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # RULE 5: Cloud Development Environment
    # ─────────────────────────────────────────────────────────────────────────
    if ($ProjectMetadata.CloudDevEnvironment -in @("devcontainers", "both")) {
        $change = Enable-Item -Scopes $Scopes `
            -ScopeId "common" `
            -ItemId "common-devcontainer-template" `
            -Reason "Devcontainers enabled"
        if ($change) { $changes += $change }
    }

    if ($ProjectMetadata.CloudDevEnvironment -in @("codespaces", "both")) {
        $change = Enable-Item -Scopes $Scopes `
            -ScopeId "common" `
            -ItemId "common-codespaces-config" `
            -Reason "GitHub Codespaces configuration enabled"
        if ($change) { $changes += $change }
    }

    return $changes
}

<#
.SYNOPSIS
Enable a specific item in a scope

.DESCRIPTION
Finds item in scope and sets enabled: true, auto_provision: true
Returns change object if modification was made

.OUTPUTS
PSCustomObject with change details or $null if item not found/already enabled
#>
function Enable-Item {
    param(
        [array]$Scopes,
        [string]$ScopeId,
        [string]$ItemId,
        [string]$Reason
    )

    $scope = $Scopes | Where-Object { $_.Id -eq $ScopeId }
    if (-not $scope) {
        Write-Warning "Scope not found: $ScopeId"
        return $null
    }

    $item = $scope.Items | Where-Object { $_.Id -eq $ItemId }
    if (-not $item) {
        Write-Verbose "Item not found: $ItemId (skipping)"
        return $null
    }

    # Check if already enabled
    $wasEnabled = $item.Enabled -eq $true
    $wasAutoProvision = $item.AutoProvision -eq $true

    if ($wasEnabled -and $wasAutoProvision) {
        Write-Verbose "Item already enabled: $ItemId"
        return $null
    }

    # Enable item
    $item.Enabled = $true
    $item.AutoProvision = $true

    Write-Host "  ✓ Enabled: " -NoNewline -ForegroundColor Green
    Write-Host "$ScopeId/$ItemId " -NoNewline -ForegroundColor Cyan
    Write-Host "($Reason)" -ForegroundColor DarkGray

    return [PSCustomObject]@{
        Scope = $ScopeId
        ItemId = $ItemId
        PreviousState = @{
            Enabled = $wasEnabled
            AutoProvision = $wasAutoProvision
        }
        NewState = @{
            Enabled = $true
            AutoProvision = $true
        }
        Reason = $Reason
    }
}
```

---

## Integración con Invoke-BoltSetupConstitution.ps1

### Estructura del Script

```powershell
<#
.SYNOPSIS
Bolt Setup Constitution - Intelligent Provisioning Engine

.DESCRIPTION
Provisions Bolt Framework project based on constitution and active scopes.
Includes smart enablement of conditional items based on project metadata.
#>

param(
    [string]$ConstitutionPath = ".boltf/memory/constitution.md",
    [string]$ScopesConfigPath = "memory/scopes.yaml",
    [switch]$DryRun,
    [switch]$Verbose
)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 0: SMART ENABLEMENT (NEW)
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Phase 0: Smart Enablement Analysis" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. Read project metadata
$projectMetadata = Read-ProjectMetadata -Path $ScopesConfigPath

Write-Host "Project Configuration:" -ForegroundColor Yellow
Write-Host "  • Practice: $($projectMetadata.Practice)"
Write-Host "  • Aspire: $($projectMetadata.UseAspire)"
Write-Host "  • Work Tool: $($projectMetadata.WorkManagementTool)"
Write-Host "  • Frontend: $($projectMetadata.FrontendFramework)"
Write-Host "  • Orchestration: $($projectMetadata.LocalOrchestration)"
Write-Host "  • Cloud Dev: $($projectMetadata.CloudDevEnvironment)"
Write-Host ""

# 2. Read all scope.yaml files (in-memory)
$scopes = Read-AllScopes -ActiveScopes $projectMetadata.ActiveScopes

# 3. Apply smart enablement rules
Write-Host "Applying enablement rules..." -ForegroundColor Yellow
$enablementChanges = Enable-ConditionalItems `
    -ProjectMetadata $projectMetadata `
    -Scopes $scopes

if ($enablementChanges.Count -gt 0) {
    Write-Host ""
    Write-Success "Smart enablement: $($enablementChanges.Count) items modified"
} else {
    Write-Info "No conditional items to enable based on current configuration"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 1-5: STANDARD PROVISIONING (EXISTING)
# ═════════════════════════════════════════════════════════════════════════════

# Continue with standard provisioning using updated $scopes data...
```

---

## Provision Report - Sección de Smart Enablement

El provision report debe incluir una nueva sección que documente las habilitaciones:

```markdown
# Provision Report

**Date**: 2026-02-27 15:30:00
**Practice**: Apps & Infra
**Scopes**: backend, frontend, cloud-platform

## Smart Enablement

✅ Conditional items enabled based on project configuration

**Configuration Context**:

- ✓ Aspire: enabled (use-aspire: true)
- ✓ Work Tool: Azure Boards (azure-boards)
- ✓ Frontend: React (react)
- ✓ Orchestration: Aspire (aspire)
- ✓ Cloud Dev: Devcontainers (devcontainers)

**Items Enabled** (5 total):

1. ✓ `frontend/frontend-aspire-opentelemetry`
   - **Reason**: Aspire orchestration enabled (E2E tracing)
   - **State**: disabled → enabled + auto_provision

2. ✓ `work-management/work-management-azure-devops-sync-skill`
   - **Reason**: Azure Boards integration enabled
   - **State**: disabled → enabled + auto_provision

3. ✓ `work-management/work-management-azure-boards-context7`
   - **Reason**: Azure Boards prompts enabled
   - **State**: disabled → enabled + auto_provision

4. ✓ `frontend/frontend-react-awesome`
   - **Reason**: React framework selected
   - **State**: disabled → enabled + auto_provision

5. ✓ `common/common-devcontainer-template`
   - **Reason**: Devcontainers enabled
   - **State**: disabled → enabled + auto_provision

## Constitution Merge

✓ Merged 18 articles from 4 scopes (including common)

...
```

---

## Testing

### Test 1: Aspire Enablement

```powershell
# Setup: Init with Aspire enabled
.\Init.ps1
# Select: Apps & Infra
# Aspire: Yes
# Frontend: React

# Run provisioning
& .boltf\scripts\Invoke-BoltSetupConstitution.ps1 -Verbose

# Verify:
# - frontend-aspire-opentelemetry skill copied
# - Provision report shows "Aspire orchestration enabled"
```

### Test 2: Work Management - Azure Boards

```powershell
# Setup: Init with Azure Boards
.\Init.ps1
# Select: Data & AI
# Work Tool: Azure Boards

# Run provisioning
& .boltf\scripts\Invoke-BoltSetupConstitution.ps1

# Verify:
# - work-management-azure-devops-sync-skill copied
# - work-management-azure-boards-context7 prompt copied
# - integration-azure-devops-sync-skill copied
```

### Test 3: Frontend Framework - Angular

```powershell
# Setup: Init with Angular
.\Init.ps1
# Select: Apps & Infra
# Frontend: Angular

# Run provisioning
& .boltf\scripts\Invoke-BoltSetupConstitution.ps1

# Verify:
# - frontend-angular-awesome instructions copied
# - frontend-react-awesome NOT copied
# - frontend-vue-awesome NOT copied
```

### Test 4: Dry Run Mode

```powershell
& .boltf\scripts\Invoke-BoltSetupConstitution.ps1 -DryRun

# Expected output:
# [DRY RUN] Would enable:
#   - frontend/frontend-react-awesome (React framework selected)
#   - work-management/work-management-azure-boards-context7 (Azure Boards enabled)
#
# NO files modified
```

---

## Beneficios

### Para Desarrolladores

- ✅ **Automatización**: No requiere habilitar items manualmente en scope.yaml
- ✅ **Relevancia**: Solo se provisiona lo que realmente se usará
- ✅ **Transparencia**: Provision report explica por qué se habilitó cada item
- ✅ **Flexibilidad**: Re-ejecutar provisioning si cambian decisiones

### Para Bolt Framework

- ✅ **Inteligencia**: Decisiones contextuales basadas en metadata
- ✅ **Mantenibilidad**: Reglas centralizadas en 1 función
- ✅ **Extensibilidad**: Añadir nuevas reglas es trivial
- ✅ **Testability**: Cada regla testeable independientemente

### Para AI-DLC

- ✅ **Efficiency**: Menos items irrelevantes en contexto de agentes
- ✅ **Configuration-driven**: Todo basado en scopes.yaml (single source of truth)
- ✅ **Idempotencia**: Re-provisioning seguro y predecible

---

## Próximos Pasos

1. ⬜ **Implementar `Invoke-BoltSetupConstitution.ps1`** con Phase 0 (Smart Enablement)
2. ⬜ **Crear función `Enable-ConditionalItems`** con las 5 reglas definidas
3. ⬜ **Añadir items nuevos a scope.yaml files** (docker-compose, kubernetes, devcontainers templates)
4. ⬜ **Testing manual** de cada regla de habilitación
5. ⬜ **Actualizar provision report** para incluir sección de Smart Enablement
6. ⬜ **Documentar en README** el flujo de smart enablement

---

## Referencias

- Init.ps1: Step 1.7 - Development Environment Configuration
- scopes.yaml: project metadata (use-aspire, work-management-tool, frontend-framework, etc.)
- scope.yaml files: items con enabled/auto_provision flags
- Provision Report: memory/provision-report.md

---

*Smart Enablement Logic v1.0 - Bolt Framework*
