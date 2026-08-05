# Azure DevOps Skills

Skills especializados para integración con Azure DevOps.

## Skills Disponibles

### azdo-sync

#### Sincronización bidireccional BOLT ↔ Azure DevOps

- Exporta features BOLT a Azure DevOps (Epic/Features/PBIs/Tasks)
- Importa work items existentes de Azure DevOps
- Sincroniza estados y actualizaciones
- Asigna work items a sprints
- Gestiona jerarquías parent-child

**Cuándo usar**: Proyectos que usan Azure DevOps Boards para gestión de trabajo.

📁 **Contenido**: Scripts PowerShell/Bash, mappings JSON, templates.

[Ver documentación completa](azdo-sync/README.md)

---

### azdo-wiki

#### Publicación automática en Azure DevOps Wiki

- Sincroniza documentación Markdown a Wiki
- Convierte diagramas Mermaid a SVG
- Gestiona attachments y assets
- Mantiene estructura de carpetas

**Cuándo usar**: Proyectos que documentan en Azure DevOps Wiki.

📁 **Contenido**: Scripts PowerShell, conversores Mermaid, templates.

[Ver documentación completa](azdo-wiki/README.md)

---

## Activación

Estos skills se activan desde los siguientes scopes:

- `.boltf/scopes/integration/scope.yaml` - Integraciones generales
- `.boltf/scopes/work-management/scope.yaml` - Gestión de trabajo

Para activar, editar el scope y cambiar `enabled: true`:

```yaml
- id: integration-azure-devops-sync-skill
  kind: skills
  enabled: true # Cambiar aquí
  tags: ['integration', 'azure-devops']
  source:
    type: local_folder
    path: available-skills/azdo/azdo-sync
  destination:
    folder: .claude/skills
    name: azdo-sync
```

## Requisitos

- Azure DevOps Personal Access Token (PAT)
- Azure CLI con extensión azure-devops
- PowerShell 7+ o Bash

## Referencias

- [Azure DevOps REST API](https://learn.microsoft.com/rest/api/azure/devops)
- [Azure DevOps CLI](https://learn.microsoft.com/azure/devops/cli/)
