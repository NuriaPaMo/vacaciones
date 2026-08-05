# Available Skills - Specialized Knowledge for Bolt Framework projects

Este directorio contiene **skills especializados** organizados por tecnología. Estos skills se copian a `.claude/skills/` cuando el sistema de scopes detecta que son necesarios para el proyecto.

## 📁 Estructura Organizativa por Tecnología

Los skills están organizados en subcarpetas por dominio tecnológico:

```text
.boltf/available-skills/
├── angular/                 # Angular ecosystem
│   └── angular-primeng-frontend/
│
├── azdo/                    # Azure DevOps
│   ├── azdo-sync/          # Sincronización BOLT ↔ Azure DevOps
│   ├── skill-azdo-pipeline-templates/ # Templates de Azure DevOps Pipelines
│   └── azdo-wiki/          # Gestión de Azure DevOps Wiki
│
├── azure/                   # Azure Cloud
│   ├── architect-diagramer/
│   ├── azure-identity-dotnet/
│   ├── azure-resource-visualizer/
│   ├── azure-role-selector/
│   └── azure-usage/
│
├── bolt-framework/          # Bolt Framework (Bolt Framework)
│   ├── bolt-framework/     # Core methodology & lifecycle phases
│   └── bolt-adr/           # Architecture Decision Records (MADR)
│
├── functional-tests/        # Testing & QA
│   ├── gherkin-reqnroll/
│   └── playwright-e2e/
│
├── github/                  # GitHub ecosystem
│   ├── gh-fix-ci/
│   ├── github-actions-templates/
│   ├── github-issue-creator/
│   ├── github-issues/
│   └── github-workflows/
│
├── react/                   # React ecosystem
│
├── ui-common/               # Browser automation & UI testing
│   └── playwright-skill/   # Playwright browser automation
│
└── vue/                     # Vue.js ecosystem
    ├── vue-best-practices/
    ├── vue-debug-guides/
    ├── create-adaptable-composable/
    ├── vue-jsx-best-practices/
    ├── vue-options-api-best-practices/
    ├── vue-pinia-best-practices/
    ├── vue-router-best-practices/
    └── vue-testing-best-practices/
```

## 🎯 Cómo Funcionan los Available Skills

### 1. Almacenamiento en `.boltf/available-skills/`

Los skills especializados se mantienen aquí organizados por tecnología. **No se copian automáticamente** a `.claude/skills/`.

### 2. Activación por Scopes

Los **scopes** (en `.boltf/scopes/`) definen cuándo copiar skills:

```yaml
# Ejemplo: .boltf/scopes/frontend/scope.yaml
resources:
  - id: frontend-vue-best-practices-skill
    kind: skills
    enabled: true
    tags: ['frontend', 'vue']
    source:
      type: local_folder
      path: available-skills/vue/vue-best-practices
    destination:
      folder: .claude/skills
      name: vue-best-practices
```

### 3. Copia a `.claude/skills/`

Cuando se activa un scope:

- El skill se copia desde `.boltf/available-skills/<tech>/<skill>`
- Se coloca en `.claude/skills/<skill>/`
- GitHub Copilot lo detecta automáticamente

> **⚠️ IMPORTANTE**: Los skills se copian en **estructura plana** (flat) directamente bajo `.claude/skills/`.
> Las carpetas de categoría (`github/`, `azure/`, `vue/`, etc.) **NO** se copian, solo los skills individuales.
>
> **✅ Correcto**:
>
> - `.boltf/available-skills/github/gh-fix-ci/` → `.claude/skills/gh-fix-ci/`
> - `.boltf/available-skills/azure/azure-identity-dotnet/` → `.claude/skills/azure-identity-dotnet/`
>
> **❌ Incorrecto**:
>
> - `.boltf/available-skills/github/` → `.claude/skills/github/` ← NUNCA hacer esto

## 📦 Skills por Tecnología

### Angular (`angular/`)

| Skill                                                         | Descripción                  | Cuándo Usar                                  |
| ------------------------------------------------------------- | ---------------------------- | -------------------------------------------- |
| [angular-primeng-frontend](angular/angular-primeng-frontend/) | Frontend Angular con PrimeNG | Desarrollo de interfaces Angular con PrimeNG |

### Azure DevOps (`azdo/`)

| [azdo-sync](azdo/azdo-sync/) | Sincronización bidireccional BOLT ↔ Azure DevOps | Gestión de work items, sprints, tracking |
| [skill-azdo-pipeline-templates](azdo/skill-azdo-pipeline-templates/) | Templates y patrones de Azure DevOps Pipelines | CI/CD cuando Article XI selecciona Azure DevOps |
| [azdo-wiki](azdo/azdo-wiki/) | Publicación automática en Azure DevOps Wiki | Documentación, diagramas Mermaid |

### Azure Cloud (`azure/`)

| Skill                                                         | Descripción                     | Cuándo Usar                        |
| ------------------------------------------------------------- | ------------------------------- | ---------------------------------- |
| [architect-diagramer](azure/architect-diagramer/)             | Diagramas de arquitectura Azure | Documentación de arquitectura      |
| [azure-identity-dotnet](azure/azure-identity-dotnet/)         | Azure Identity para .NET        | Autenticación y autorización Azure |
| [azure-resource-visualizer](azure/azure-resource-visualizer/) | Visualización de recursos Azure | Exploración de infraestructura     |
| [azure-role-selector](azure/azure-role-selector/)             | Selección de roles RBAC         | Gestión de permisos Azure          |
| [azure-usage](azure/azure-usage/)                             | Análisis de uso Azure           | Monitoreo y optimización de costos |

### Bolt Framework (`bolt-framework/`)

| Skill                                            | Descripción                                                       | Cuándo Usar                                      |
| ------------------------------------------------ | ----------------------------------------------------------------- | ------------------------------------------------ |
| [bolt-framework](bolt-framework/bolt-framework/) | **CORE** metodología Bolt Framework con 6 fases del ciclo de vida | Orquestación de proyectos, Bolt micro-iterations |
| [bolt-adr](bolt-framework/bolt-adr/)             | Architecture Decision Records formato MADR                        | Documentar decisiones arquitectónicas            |

### Functional Tests (`functional-tests/`)

| Skill                                                  | Descripción                | Cuándo Usar                   |
| ------------------------------------------------------ | -------------------------- | ----------------------------- |
| [gherkin-reqnroll](functional-tests/gherkin-reqnroll/) | BDD con Gherkin y Reqnroll | Testing funcional con Gherkin |
| [playwright-e2e](functional-tests/playwright-e2e/)     | E2E testing con Playwright | Tests end-to-end              |

### GitHub (`github/`)

| Skill                                                        | Descripción                   | Cuándo Usar            |
| ------------------------------------------------------------ | ----------------------------- | ---------------------- |
| [gh-fix-ci](github/gh-fix-ci/)                               | Reparación de CI/CD GitHub    | Debugging de workflows |
| [github-actions-templates](github/github-actions-templates/) | Templates para GitHub Actions | Creación de workflows  |
| [github-issue-creator](github/github-issue-creator/)         | Creación de issues GitHub     | Gestión de issues      |
| [github-issues](github/github-issues/)                       | Gestión de issues GitHub      | Work item tracking     |
| [github-workflows](github/github-workflows/)                 | Workflows GitHub Actions      | CI/CD con GitHub       |

### React (`react/`)

**Estado**: Carpeta preparada para skills de React - actualmente sin skills.

### UI Common (`ui-common/`)

| Skill                                           | Descripción                                | Cuándo Usar                            |
| ----------------------------------------------- | ------------------------------------------ | -------------------------------------- |
| [playwright-skill](ui-common/playwright-skill/) | Automatización de navegador con Playwright | Testing UI, E2E, automation de browser |

### Vue.js (`vue/`)

| Skill                                                                 | Descripción                                                         | Cuándo Usar                     |
| --------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------------------------- |
| [vue-best-practices](vue/vue-best-practices/)                         | **OBLIGATORIO** para proyectos Vue.js. Composition API + TypeScript | Cualquier tarea Vue.js          |
| [vue-debug-guides](vue/vue-debug-guides/)                             | Debugging, errores runtime, warnings, SSR                           | Diagnosticar/arreglar bugs Vue  |
| [vue-pinia-best-practices](vue/vue-pinia-best-practices/)             | Stores, state management, reactivity                                | Gestión de estado con Pinia     |
| [vue-router-best-practices](vue/vue-router-best-practices/)           | Navegación, guards, lifecycle                                       | Routing con Vue Router          |
| [vue-testing-best-practices](vue/vue-testing-best-practices/)         | Tests con Vitest, Vue Test Utils, Playwright                        | Testing de componentes Vue      |
| [create-adaptable-composable](vue/create-adaptable-composable/)       | Composables reusables con MaybeRef/MaybeRefOrGetter                 | Crear composables de librería   |
| [vue-jsx-best-practices](vue/vue-jsx-best-practices/)                 | Sintaxis JSX en Vue                                                 | Proyectos Vue con JSX           |
| [vue-options-api-best-practices](vue/vue-options-api-best-practices/) | Options API (legacy)                                                | Proyectos Vue 3 con Options API |

## 🔧 Agregar Nuevos Skills

### 1. Crear el Skill

```bash
# Crear directorio para nueva tecnología (si no existe)
mkdir -p .boltf/available-skills/<technology>

# Crear skill
mkdir -p .boltf/available-skills/<technology>/<skill-name>

# Crear SKILL.md
code .boltf/available-skills/<technology>/<skill-name>/SKILL.md
```

### 2. Configurar en un Scope

Editar `.boltf/scopes/<scope>/scope.yaml`:

```yaml
resources:
  - id: <scope>-<skill-name>-skill
    kind: skills
    enabled: false # Cambiar a true cuando se necesite
    tags: ['<technology>']
    source:
      type: local_folder
      path: available-skills/<technology>/<skill-name>
    destination:
      folder: .claude/skills
      name: <skill-name>
```

### 3. Activar el Skill

Cuando el proyecto necesite esa tecnología:

- Cambiar `enabled: true` en el scope
- Ejecutar script de aprovisionamiento de scopes
- El skill se copiará automáticamente a `.claude/skills/`

## 📚 Referencias

- **Scopes**: `.boltf/scopes/README.md`
- **Skills activos**: `.claude/skills/README.md`
- **Bolt Framework**: `.claude/skills/bolt-framework/SKILL.md`

---

**Nota**: Los skills en `available-skills/` son un **repositorio** de conocimiento especializado. Solo se activan cuando el proyecto los necesita, evitando saturar GitHub Copilot con contexto innecesario.
