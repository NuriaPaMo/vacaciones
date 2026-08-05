# Provisioning System Improvements

## Fecha: 2026-02-24

## Resumen

Se ha mejorado el sistema de provisioning del agente `@Bolt Constitution` para asegurar que descarga y copia todos los recursos necesarios (skills, prompts, agentes, instructions) basándose en los scopes seleccionados.

## Cambios Realizados

### 1. Script PowerShell Mejorado

**Archivo**: `.boltf/scripts/powershell/Invoke-BoltSetupConstitution.ps1`

**Cambios**:

- ✅ Ahora detecta items con `source.type: context7` y `awesome_copilot`
- ✅ Los marca como "requires download" en lugar de fallar silenciosamente
- ✅ Delega la descarga externa al agente (que tiene acceso a MCP)
- ✅ Genera reporte indicando qué items necesitan descarga externa

**Código añadido**:

```powershell
switch ($sourceType) {
    'local_file' {
        # Copy from .boltf/scopes/...
    }
    'context7' {
        $requiresDownload = $true
        Write-Info "Item requires Context7 download (agent-handled)"
    }
    'awesome_copilot' {
        $requiresDownload = $true
        Write-Info "Item requires Awesome Copilot download (agent-handled)"
    }
}
```

### 2. Prompt de Provisioning Detallado

**Archivo Nuevo**: `.github/prompts/bolt-constitution-provisioning.prompt.md`

**Contenido**:

- ✅ **Workflow completo** de Phase 4 en pasos ejecutables
- ✅ **Instrucciones específicas** para descargar desde Context7 vía MCP
- ✅ **Instrucciones específicas** para descargar desde Awesome Copilot vía MCP
- ✅ **Manejo de errores** (MCP no disponible, download fallido, etc.)
- ✅ **Formato de frontmatter** para archivos descargados con metadata de source
- ✅ **Generación de reporte mejorado** con detalles de downloads

**Ejemplo de uso MCP Context7**:

```typescript
// 1. Load MCP tools
tool_search_tool_regex({ pattern: 'mcp_context7' });

// 2. Resolve library
mcp_context7_resolve - library - id({ libraryId: '/dotnet/aspnetcore.docs' });

// 3. Fetch documentation
mcp_context7_query -
  docs({
    libraryId: '/dotnet/aspnetcore.docs',
    query: 'Configure Minimal API with OpenAPI and Swagger',
  });

// 4. Save with frontmatter
create_file({
  filePath: '.github/prompts/backend-minimal-api-openapi.prompt.md',
  content: '---\nsource: context7\n...\n---\n\n[content]',
});
```

### 3. Agente Actualizado

**Archivo**: `.github/agents/bolt-constitution.agent.md`

**Cambios**:

- ✅ Añadida referencia al prompt de provisioning en la cabecera
- ✅ Phase 4 ahora delega al prompt detallado para ejecución
- ✅ Mantiene overview de alto nivel en el agente
- ✅ El agente ahorra tokens delegando la lógica detallada al prompt

**Referencia añadida**:

```markdown
**Provisioning Reference**: For Phase 4, reference
#file:.github/prompts/bolt-constitution-provisioning.prompt.md
for detailed step-by-step instructions.
```

### 4. Scripts de Inicialización (Init.ps1 / init.sh)

**Cambios**:

- ✅ Ahora preguntan por la herramienta de IaC cuando `cloud-platform` scope está activo
- ✅ Opciones: Bicep (recomendado), ARM Templates, Terraform, Pulumi
- ✅ La elección se guarda en `scopes.yaml` bajo `decisions.cicd.iac-tool`
- ✅ Aparece en el resumen final de inicialización

## Flujo de Provisioning (Phase 4)

### Paso 1: Análisis (Dry Run)

```powershell
Invoke-BoltSetupConstitution.ps1 -Provision -DryRun
```

- Identifica items con `enabled: true` en scope.yaml
- Clasifica por source type: local_file, context7, awesome_copilot
- Genera plan de provisioning

### Paso 2: Provisioning Local (Script PowerShell)

```powershell
Invoke-BoltSetupConstitution.ps1 -Provision
```

- Copia core skills desde `.boltf/available-skills/`
- Copia items con `source.type: local_file`
- Marca items externos como "requires download"

### Paso 3: Downloads Externos (Agente vía MCP)

**Context7 Items**:

1. Carga tools: `tool_search_tool_regex({ pattern: "mcp_context7" })`
2. Descarga docs: `mcp_context7_query-docs(...)`
3. Guarda con frontmatter en destination.folder/destination.name

**Awesome Copilot Items**:

1. Carga tools: `tool_search_tool_regex({ pattern: "mcp_awesome_copil" })`
2. Load collection: `mcp_awesome_copil_load_collection(...)`
3. Load instruction: `mcp_awesome_copil_load_instruction(...)`
4. Guarda con frontmatter en destination.folder/destination.name

### Paso 4: Reporte Final

- Script genera `provision-report.md` con items locales
- Agente lo enriquece con metadata de downloads externos
- Incluye URLs, timestamps, licenses

## Ejemplo de Scope.yaml con Items

```yaml
items:
  # Item local (manejado por script PowerShell)
  - id: backend-testing-strategy
    kind: skills
    enabled: true
    source:
      type: local_file
      path: scopes/backend/skills/testing-strategy
    destination:
      folder: .claude/skills
      name: backend-testing-strategy

  # Item Context7 (manejado por agente vía MCP)
  - id: backend-minimal-api-openapi
    kind: prompts
    enabled: true
    source:
      type: context7
      library: /dotnet/aspnetcore.docs
      query: Configure Minimal API with OpenAPI and Swagger
    destination:
      folder: .github/prompts
      name: backend-minimal-api-openapi.prompt.md

  # Item Awesome Copilot (manejado por agente vía MCP)
  - id: backend-dotnet-architecture
    kind: instructions
    enabled: true
    source:
      type: awesome_copilot
      collection: csharp-dotnet-development
      item_path: instructions/dotnet-architecture-good-practices.instructions.md
    destination:
      folder: .github/instructions
      name: dotnet-architecture-good-practices.instructions.md
```

## Verificación

Para verificar que el provisioning funcionó correctamente:

```bash
# 1. Verificar core skills
ls .claude/skills/
# Debe incluir: bolt-framework, bolt-adr, new-skill, markdown-formatting

# 2. Verificar recursos de scopes
ls .github/prompts/
ls .github/instructions/
ls .claude/skills/

# 3. Ver reporte de provisioning
cat .boltf/memory/provision-report.md
# Debe incluir sección "External Downloads Completed" con detalles de Context7 y Awesome Copilot

# 4. Verificar frontmatter de archivos descargados
head -20 .github/prompts/backend-minimal-api-openapi.prompt.md
# Debe incluir:
# ---
# source: context7
# library: ...
# fetched: ...
# ---
```

## Beneficios

1. **Automatización completa**: Ya no es necesario copiar manualmente recursos
2. **Trazabilidad**: Cada archivo descargado incluye metadata de origen
3. **Flexibilidad**: Soporta múltiples fuentes (local, Context7, Awesome Copilot)
4. **Extensibilidad**: Fácil añadir nuevos source types (GitHub raw, npm packages, etc.)
5. **Reporte completo**: Inventory total de todos los recursos provisionados
6. **Manejo de errores**: Opciones claras cuando MCP no disponible o download falla

## Próximos Pasos Potenciales

- [ ] Añadir soporte para `source.type: github_raw` (descargar desde GitHub directamente)
- [ ] Añadir soporte para `source.type: npm_package` (instalar skills desde npm)
- [ ] Implementar cache de downloads para evitar re-fetch
- [ ] Añadir validación de content_hash para detectar cambios en source
- [ ] Implementar auto-update de outdated resources

## Testing Recomendado

1. Crear proyecto nuevo con `Init.ps1`
2. Seleccionar scope `backend` (tiene items de todos los tipos)
3. Habilitar algunos items en `.boltf/scopes/backend/scope.yaml` (cambiar `enabled: false` → `enabled: true`)
4. Invocar `@Bolt Constitution`
5. Completar Phase 1-3
6. En Phase 4, verificar que:
   - PowerShell copia archivos locales ✓
   - Agente descarga de Context7 ✓
   - Agente descarga de Awesome Copilot ✓
   - Reporte incluye todos los items ✓
   - Frontmatter es correcto ✓

## Referencias

- Agente: `.github/agents/bolt-constitution.agent.md`
- Prompt Provisioning: `.github/prompts/bolt-constitution-provisioning.prompt.md`
- Script PowerShell: `.boltf/scripts/powershell/Invoke-BoltSetupConstitution.ps1`
- Ejemplo de Scope: `.boltf/scopes/backend/scope.yaml`
