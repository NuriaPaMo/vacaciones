# 🚧 Bolt Framework - Cosas Pendientes / Mejoras Propuestas

> **Documento de análisis**: Identificación de gaps y mejoras potenciales  
> **Fecha**: 2025-12-16  
> **Estado**: Borrador para revisión

---

## ✅ Scripts Bash vs PowerShell - ALINEADOS

Todos los scripts Bash ahora tienen sus equivalentes PowerShell correspondientes. Los 3 scripts faltantes han sido creados:

- ✅ `generate-project-structure.sh` → `Generate-ProjectStructure.ps1`
- ✅ `generate-tests.sh` → `Generate-Tests.ps1`
- ✅ `deploy.sh` → `Deploy.ps1`

**Estado actual**: 19 scripts Bash con 19 equivalentes PowerShell completos.

---

## ✅ `init.sh` - Problemas de Alineación RESUELTOS (Enfoque Agnóstico)

### Lo que hace `init.sh` (3287 líneas)

1. ✅ Wizard interactivo para configurar proyecto
2. ✅ **Agnóstico del stack** hasta leer constitution.md
3. ✅ Pre-rellena constitution.md con checkboxes
4. ✅ **Genera configuraciones específicas** SOLO después de conocer el stack
5. ✅ Soporta Landing Zone / Workload / Full-Stack
6. ✅ Auto-profiles para skip wizard
7. ✅ Copia agentes y prompts al proyecto destino

### Lo que se ARREGLÓ (Enfoque Correcto)

#### 1. ✅ **Architecture Quality Gates específicos del stack**

```bash
# Se copian SOLO para el stack detectado:
# Node.js/TypeScript → .dependency-cruiser.cjs + .spectral.yaml
# .NET → Directory.Build.props + Microsoft.CodeAnalysis.NetAnalyzers
# Java → ArchUnit + SpotBugs + PMD (placeholder)
# Python → pyproject.toml + import-linter + mypy + ruff
# Go → go.mod + go vet + golangci-lint + govulncheck
```

#### 2. ✅ **Scripts específicos del stack en configuración generada**

El `init.sh` ahora genera archivos específicos SOLO después de leer constitution:

- **Node.js**: `package.json` con `arch:check`, `circular:check`, `validate:openapi`
- **.NET**: `Directory.Build.props` con analyzers
- **Python**: `pyproject.toml` con herramientas de análisis
- **Go**: `go.mod` con configuración básica

#### 3. ✅ **Init.ps1 completamente agnóstico y alineado**

- ✅ PS1 ahora copia todos los agentes y prompts
- ✅ PS1 es agnóstico hasta leer constitution.md
- ✅ PS1 genera configuraciones específicas SOLO del stack detectado
- ✅ PS1 tiene referencias actualizadas a @Bolt agentes
- ✅ PS1 tiene paridad 100% con init.sh

#### 4. ✅ **Enfoque agnóstico por defecto**

Los scripts NO hardcodean tecnologías específicas:

- ✅ Si NO existe `constitution.md` → Wizard para preguntar stack
- ✅ Si existe `constitution.md` → Lee y detecta stack automáticamente
- ✅ Genera SOLO las configuraciones del stack detectado
- ✅ Soporta Node.js, .NET, Java, Python, Go

#### 5. ✅ **Referencias actualizadas a agentes**

El README generado por ambos scripts ahora usa:

```text
@Bolt Constitution
@Bolt Feature  
@Bolt Implement
```

En lugar de los comandos slash obsoletos.

---

## ✅ Acciones Inmediatas COMPLETADAS para `init.sh` / `Init.ps1`

### ✅ Prioridad 1: Actualizar README generado - RESUELTO

**Completado:** Referencias cambiadas de `/bolt.xxx` a `@Bolt Xxx` (agentes).

### ✅ Prioridad 2: Enfoque Agnóstico de Configuraciones - RESUELTO

**Completado:** Scripts adaptados por stack detectado:

- **Node.js/TypeScript**: `package.json` + dependency-cruiser + spectral
- **.NET**: `Directory.Build.props` + Microsoft.CodeAnalysis.NetAnalyzers  
- **Python**: `pyproject.toml` + import-linter + mypy + ruff
- **Java/Go**: Configuraciones básicas + placeholders

### ✅ Prioridad 3: Architecture Gates específicos del stack - RESUELTO

**Completado:** Se generan SOLO para el stack detectado desde constitution:

- ✅ **Node.js**: `.dependency-cruiser.cjs` + `.spectral.yaml`
- ✅ **.NET**: Analyzers integrados en `Directory.Build.props`
- ✅ **Python**: Herramientas en `pyproject.toml`
- ✅ Se crea directorio `reports/architecture/`

### ✅ Prioridad 4: Alinear `Init.ps1` con `init.sh` con enfoque agnóstico - RESUELTO

**Completado:** Ambos scripts ahora son completamente agnósticos:

- ✅ Detectan stack desde `constitution.md`
- ✅ Generan SOLO configuraciones del stack detectado
- ✅ Copia agentes, prompts, workflows, scripts  
- ✅ Paridad 100% Bash ↔ PowerShell
- ✅ Referencias actualizadas a @Bolt agentes

---

## 📋 Resumen Ejecutivo Original

Bolt Framework es un framework maduro con 29 agentes, 19 prompts, 36+ scripts y workflows de CI/CD. Sin embargo, hay áreas que podrían completarse o mejorarse.

---

## 🔴 Crítico / Falta

### 1. **Documentación de API para Agentes**

- [ ] No hay documentación de los parámetros que acepta cada agente
- [ ] No hay ejemplos de invocación completos con respuestas esperadas
- [ ] Falta un "cheatsheet" rápido de agentes vs casos de uso

### 2. **Testing del Framework**

- [ ] No hay tests para los scripts bash/powershell
- [ ] No hay tests para validar que los agentes funcionan correctamente
- [ ] No hay "smoke tests" del framework

### 3. **Validación de Constitution**

- [ ] No hay script que valide que `constitution.md` está completo
- [ ] No hay schema JSON/YAML para validar la estructura del constitution
- [ ] Las checkboxes del constitution no se validan automáticamente

### 4. **Versionado del Framework**

- [ ] El `package.json` del framework no existe (solo del proyecto demo)
- [ ] No hay forma de actualizar Bolt Framework cuando sale una nueva versión
- [ ] Falta mecanismo de "Bolt Framework update" o similar

---

## 🟡 Importante / Mejorable

### 5. **Templates de Proyecto por Stack**

- [ ] Solo hay templates genéricos, no específicos por stack
- [ ] Falta: template Node.js/NestJS pre-configurado
- [ ] Falta: template .NET 8 pre-configurado
- [ ] Falta: template Python/FastAPI pre-configurado
- [ ] Falta: template Go pre-configurado

### 6. **Agente de Seguridad Dedicado** ✅ COMPLETADO

- [x] ✅ `bolt-security.agent.md` creado con capacidades comprehensivas
- [x] ✅ Security gates consolidados en `scripts/bash/security-analysis.sh` y PowerShell equivalente
- [x] ✅ OWASP Top 10 checks integrados con mapeo automático
- [x] ✅ SAST/DAST automation con GitHub Actions workflow completo
- [x] ✅ Integración en quality gates (`quality-gates.sh --full`)
- [x] ✅ Stack-agnostic security analysis (Node.js, .NET, Java, Python, Go)
- [x] ✅ Constitution-driven security policies con template completo
- [x] ✅ Documentación completa con guía de uso y best practices

### 7. **Integración con Herramientas Externas**

- [ ] No hay integración con Jira/Azure DevOps para tracking
- [ ] No hay integración con Slack/Teams para notificaciones
- [ ] No hay integración con SonarQube/SonarCloud
- [ ] No hay integración con herramientas de diagramas (Miro, Lucidchart)

### 8. **Métricas y Observabilidad del Proceso**

- [ ] No hay tracking de tiempo por BOLT
- [ ] No hay métricas de velocidad del equipo
- [ ] No hay dashboard de estado del proyecto
- [ ] Falta: burndown/burnup por feature

### 9. **Gestión de Dependencias**

- [ ] `bolt-deps.agent.md` existe pero no tiene scripts asociados
- [ ] No hay `check-deps.sh` o `Update-Dependencies.ps1`
- [ ] Falta: Renovate/Dependabot config template

### 10. **Configuración de IDEs**

- [ ] Solo VS Code está documentado
- [ ] Falta: configuración para JetBrains (IntelliJ, Rider, WebStorm)
- [ ] Falta: configuración para Neovim/Vim
- [ ] Falta: `.editorconfig` template

---

## 🟢 Nice to Have / Futuro

### 11. **CLI de Bolt Framework**

- [ ] No hay CLI propio (`Bolt Framework init`, `Bolt Feature`, `Bolt Framework bolt`)
- [ ] Los scripts bash/powershell son verbose
- [ ] Sería útil: `npx bolt-cli init`

### 12. **Modo Interactivo**

- [ ] Los scripts no tienen modo interactivo con menús
- [ ] Falta: wizard para crear constitution
- [ ] Falta: wizard para crear feature

### 13. **Localización / i18n**

- [ ] Todo está en inglés
- [ ] Los mensajes de los scripts no están externalizados
- [ ] Sería útil soporte para español (dado el contexto)

### 14. **Documentación Visual**

- [ ] No hay videos tutoriales
- [ ] No hay diagramas de flujo interactivos
- [ ] Falta: arquitectura del framework en C4/Mermaid

### 15. **Plugins/Extensiones**

- [ ] No hay mecanismo de plugins para extender Bolt Framework
- [ ] No se pueden añadir agentes custom fácilmente
- [ ] No hay marketplace de templates

### 16. **Playground / Sandbox**

- [ ] No hay entorno de pruebas online
- [ ] No hay proyecto de ejemplo completo funcionando
- [ ] El `demo/` está incompleto

### 17. **Generación de Código con IA**

- [ ] Los agentes guían pero no generan scaffolding completo
- [ ] Falta: generación de CRUD completo desde entidad
- [ ] Falta: generación de módulo NestJS/ASP.NET desde spec

### 18. **Multi-repo / Monorepo**

- [ ] No hay guidance para monorepos (Nx, Turborepo, Lerna)
- [ ] No hay guidance para multi-repo con specs compartidos
- [ ] Constitution es por proyecto, no por organización

---

## 📊 Matriz de Priorización

| ID | Mejora | Impacto | Esfuerzo | Prioridad |
|----|--------|---------|----------|-----------|
| 3 | Validación de Constitution | Alto | Medio | 🔴 P0 |
| 1 | Documentación API Agentes | Alto | Bajo | 🔴 P0 |
| 5 | Templates por Stack | Alto | Alto | 🟡 P1 |
| 6 | Agente de Seguridad | Alto | Medio | ✅ COMPLETADO |
| 9 | Gestión de Dependencias | Medio | Bajo | 🟡 P1 |
| 2 | Testing del Framework | Alto | Alto | 🟡 P1 |
| 11 | CLI de Bolt Framework | Alto | Alto | 🟢 P2 |
| 4 | Versionado del Framework | Medio | Medio | 🟢 P2 |
| 10 | Configuración IDEs | Bajo | Bajo | 🟢 P2 |
| 7 | Integraciones Externas | Medio | Alto | 🟢 P3 |

---

## 🔧 Archivos/Carpetas que Faltan

```text
Bolt Framework/
├── .editorconfig                    # ❌ No existe
├── .nvmrc                           # ❌ No existe (Node version)
├── bolt.json                      # ❌ Config del framework
├── package.json                     # ❌ Del framework (no demo)
│
├── .github/
│   ├── agents/
│   │   └── bolt-security.agent.md # ✅ Creado y completamente integrado
│   └── ISSUE_TEMPLATE/              # ❌ Templates de issues
│       ├── bug_report.md
│       ├── feature_request.md
│       └── bolt_task.md
│
├── cli/                             # ❌ CLI del framework
│   ├── package.json
│   ├── src/
│   │   ├── commands/
│   │   └── index.ts
│   └── bin/Bolt Framework
│
├── docs/
│   ├── getting-started/             # ❌ Guía paso a paso
│   │   ├── 01-installation.md
│   │   ├── 02-first-project.md
│   │   ├── 03-first-feature.md
│   │   └── 04-first-bolt.md
│   ├── reference/                   # ❌ Referencia de API
│   │   ├── agents.md
│   │   ├── prompts.md
│   │   ├── scripts.md
│   │   └── constitution-schema.md
│   ├── examples/                    # ❌ Ejemplos completos
│   │   ├── node-nestjs/
│   │   ├── dotnet-api/
│   │   └── python-fastapi/
│   └── diagrams/                    # ❌ Diagramas del framework
│       ├── bolt-flow.mmd
│       ├── agent-interactions.mmd
│       └── bolt-lifecycle.mmd
│
├── schemas/                         # ❌ Schemas de validación
│   ├── constitution.schema.json
│   ├── feature.schema.json
│   └── tasks.schema.json
│
├── scripts/
│   ├── bash/
│   │   ├── check-deps.sh            # ❌ Check dependencies
│   │   ├── validate-constitution.sh # ❌ Validar constitution
│   │   └── bolt-doctor.sh         # ❌ Diagnóstico del setup
│   └── powershell/
│       ├── Check-Dependencies.ps1   # ❌
│       ├── Validate-Constitution.ps1# ❌
│       └── Get-BoltDiagnostics.ps1# ❌
│
├── templates/                       # ❌ Templates por stack
│   ├── node-nestjs/
│   │   ├── src/
│   │   ├── package.json
│   │   └── .dependency-cruiser.cjs
│   ├── dotnet-api/
│   │   ├── src/
│   │   └── *.csproj
│   └── python-fastapi/
│       ├── src/
│       └── pyproject.toml
│
└── tests/                           # ❌ Tests del framework
    ├── scripts/
    │   ├── test-quality-gates.sh
    │   └── test-create-feature.sh
    └── agents/
        └── test-agent-responses.md
```

---

## 🎯 Próximos Pasos Recomendados

### Fase 1: Fundamentos (1-2 semanas)

1. Crear `schemas/constitution.schema.json` para validación
2. Crear `scripts/bash/validate-constitution.sh`
3. Crear `bolt-security.agent.md`
4. Añadir `.editorconfig` y `.nvmrc`

### Fase 2: Documentación (2-3 semanas)

5. Crear `docs/getting-started/` con tutorial paso a paso
2. Crear `docs/reference/agents.md` con API de cada agente
3. Crear ejemplos completos en `docs/examples/`

### Fase 3: Templates (2-4 semanas)

8. Crear `templates/node-nestjs/` con proyecto base
2. Crear `templates/dotnet-api/` con proyecto base
3. Integrar templates en `init.sh` / `Init.ps1`

### Fase 4: CLI (4-6 semanas)

11. Diseñar CLI commands
2. Implementar `Bolt Framework init`
3. Implementar `Bolt Feature create`
4. Implementar `Bolt Framework bolt run`

---

## 📝 Notas

- Este documento es un análisis inicial, no una roadmap oficial
- Las prioridades pueden cambiar según feedback
- Algunas mejoras pueden ser "community contributions"

---

## 🔒 Actualización: Bolt Security Agent COMPLETADO

**Fecha de finalización**: 2024-12-17  
**Implementación completa**:

- ✅ Bolt Security Agent (`.github/copilot/agents/bolt-security.agent.md`) - 500+ líneas
- ✅ Scripts de seguridad multiplataforma:
  - `scripts/bash/security-analysis.sh` (3,287+ líneas)
  - `scripts/powershell/Security-Analysis.ps1` (equivalente completo)
- ✅ GitHub Actions workflow (`.github/workflows/security-analysis.yml`)
- ✅ Setup Action (`.github/actions/setup-stack/action.yml`)
- ✅ Template de configuración (`.boltf/docs/templates/constitution-security-template.yml`)
- ✅ Documentación completa (`.boltf/docs/templates/bolt-security-complete-guide.md`)
- ✅ Integración en quality gates y scripts de inicialización
- ✅ Referencias actualizadas en README y documentación del framework

**Características implementadas**:

- Stack-agnostic security analysis (Node.js, .NET, Java, Python, Go)
- OWASP Top 10 2021 compliance mapping completo
- SAST, SCA, secrets scanning, infrastructure security
- Constitution-driven security policies
- Automated CI/CD integration
- Comprehensive reporting with actionable recommendations

---

*Generado por análisis de Bolt Framework v2.2.0*
