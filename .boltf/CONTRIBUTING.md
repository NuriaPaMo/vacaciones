# Contributing to Bolt Framework

## Visión General

Bolt Framework se distribuye de dos formas:

1. **Proyectos nuevos**: Se crean desde el **GitHub template** del repositorio canónico,
   o ejecutando `Init.ps1` que copia los ficheros necesarios.
2. **Sincronización bidireccional**: Una vez creado, el proyecto establece una relación
   **git subtree** para recibir actualizaciones y contribuir cambios de vuelta.

**Repositorio canónico (template)**: `https://github.com/ava-group-iberiademos/bolt-framework`

---

## Modelo de Gobierno

### Roles

| Rol | Responsabilidad | Requisitos para aprobación |
|-----|----------------|---------------------------|
| **Framework Steward** | Breaking changes, schema de scope.yaml, releases MAJOR | 2 aprobaciones de stewards |
| **Scope Trusted Committer** | PRs de su scope, mantenimiento del changelog | 1 aprobación del TC del scope |
| **Skill Contributor** | Propone mejoras o nuevas skills | Cualquier desarrollador |
| **Release Manager** | Tags, release notes, validación CI | Rotativo mensual |

### Ownership (CODEOWNERS)

Cada directorio tiene un owner responsable de revisión (ver `.github/CODEOWNERS`
en el repositorio canónico; las rutas están prefijadas con `.boltf/`).
Sustituye `@your-org` por la organización real y crea los equipos antes de activar
la protección de ramas. Ejemplos:

- `/.boltf/scripts/`, `/.boltf/bolt-manifest.yaml` → `@your-org/bolt-core-team`
- `/.boltf/scopes/backend/`, `/.boltf/available-skills/dotnet-backend/` → `@your-org/bolt-backend-owners`
- `/.boltf/scopes/frontend/`, `/.boltf/available-skills/angular/` → `@your-org/bolt-frontend-owners`
- `/.boltf/scopes/cloud-platform/`, `/.boltf/available-skills/azure/` → `@your-org/bolt-platform-owners`
- `/.boltf/available-skills/bolt-framework/` → `@your-org/bolt-core-team`

---

## Cómo Contribuir

### Prerequisitos

1. Tener acceso push al repositorio canónico (o un fork con permisos)
2. Estar en la raíz de un proyecto consumidor con `.boltf/` presente
3. Cargar el módulo PowerShell:

   ```powershell
   Import-Module .boltf/scripts/powershell/BoltFramework.psm1
   ```

4. **Si es la primera vez** (proyecto creado via template o `Init.ps1`), establecer la relación subtree:

   ```powershell
   Initialize-BoltSubtree
   ```

   Esto añade el remote `bolt-upstream` y registra la versión base. Solo se ejecuta una vez.

### Flujo de Contribución

#### 1. Modificar el artefacto localmente

Trabaja en el artefacto desplegado (no directamente en `.boltf/`):

```text
.claude/skills/mi-skill/SKILL.md     ← Editas aquí
.github/agents/mi-agent.agent.md     ← O aquí
```

#### 2. Preparar la contribución

```powershell
New-BoltContribution -Type skill -Name "mi-skill" -Description "Añadir patrón X"
```

Esto:

- Crea branch `contrib/skill-mi-skill`
- Copia cambios de vuelta a `.boltf/available-skills/`
- Hace commit con mensaje convencional

#### 3. Enviar al upstream

```powershell
Push-BoltContribution -Branch "contrib/skill-mi-skill"
```

#### 4. Abrir Pull Request

Abre PR en `ava-group-iberiademos/bolt-framework`:

- **Branch**: `contrib/skill-mi-skill` → `main`
- **Título**: Sigue Conventional Commits (`feat(backend): ...`)
- **Body**: Describe el cambio, motivación y testing realizado

---

## Tipos de Contribución

| Tipo | Comando | Destino en .boltf/ |
|------|---------|-------------------|
| `skill` | `-Type skill -Name "x"` | `available-skills/<categoría>/x/` |
| `agent` | `-Type agent -Name "x"` | `available-skills/contributed/x/` |
| `scope` | `-Type scope -Name "x"` | Editar directamente en `scopes/x/` |
| `script` | `-Type script -Name "x"` | Editar directamente en `scripts/` |
| `docs` | `-Type docs -Name "x"` | Editar directamente en `docs/` o `memory/` |

---

## Convenciones de Commit

```text
<tipo>(<scope>): <descripción>

[cuerpo opcional]

[footer opcional]
```

**Tipos**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
**Scopes válidos**: nombre del skill, nombre del scope, `scripts`, `manifest`, `ci`

**Ejemplos**:

```text
feat(backend): añadir skill de health check
fix(scripts): corregir parsing YAML en Invoke-BoltSetupConstitution
docs(common): actualizar guía de seguridad OWASP
chore(manifest): bump version a 1.2.0
```

---

## Proceso de Review

### Skills y Agents (MINOR)

1. PR abierto por contributor
2. CI ejecuta validaciones automáticas (lint YAML, paths, markdownlint)
3. Scope Trusted Committer revisa:
   - ¿El skill sigue el estándar Agent Skills? (frontmatter, triggers, sections)
   - ¿La documentación es clara?
   - ¿Se incluyen ejemplos?
4. 1 aprobación → merge

### Scripts y Schema (MAJOR potencial)

1. PR abierto con label `breaking-change` si aplica
2. CI valida que `bolt-manifest.yaml` tiene version bump
3. Framework Steward revisa impacto en proyectos consumidores
4. 2 aprobaciones → merge

### Docs (PATCH)

1. PR abierto
2. Cualquier miembro del equipo puede aprobar
3. 1 aprobación → merge

---

## Recibir Actualizaciones (Downstream Pull)

### Verificar estado

```powershell
Import-Module .boltf/scripts/powershell/BoltFramework.psm1
Get-BoltStatus
```

### Previsualizar cambios

```powershell
Compare-BoltVersions -To v1.1.0
```

### Aplicar actualización

```powershell
Update-BoltFramework -Version v1.1.0
```

### Resolver conflictos (si los hay)

Si `git subtree pull` produce conflictos:

1. Resolver con merge markers estándar de Git
2. `git add .` + `git commit`
3. Ejecutar `Invoke-BoltSetupConstitution -Provision` para desplegar nuevos items

### Adopción selectiva

Tras pull, los nuevos items aparecen en `scope.yaml` con `enabled: false`.
Activa solo los que necesites y ejecuta provisioning.

Para items que NUNCA deben sobreescribirse:

```yaml
- id: mi-skill-personalizado
  pin: true  # Upstream no sobreescribirá este item
```

---

## Versionado

El framework sigue **Semantic Versioning** (semver):

| Tipo | Cuándo | Ejemplo |
|------|--------|---------|
| MAJOR | Breaking change en schema, eliminación de skills | v2.0.0 |
| MINOR | Nuevas skills, nuevos scopes, nuevos agents | v1.1.0 |
| PATCH | Correcciones, typos, mejoras doc | v1.0.1 |

La versión vive en `bolt-manifest.yaml` y se refleja como tag de Git.

---

## Estructura de un Skill

```text
available-skills/<categoría>/<nombre>/
  SKILL.md              # Definición del skill (Agent Skills standard)
  examples/             # Código de ejemplo (opcional)
  templates/            # Plantillas reutilizables (opcional)
  assets/               # Snippets de código (opcional)
```

**Frontmatter obligatorio en SKILL.md**:

```yaml
---
name: nombre-del-skill
description: Descripción en una línea
version: 1.0.0
triggers:
  - patron1
  - patron2
---
```

---

## Checklist antes de abrir PR

- [ ] El skill/agent funciona correctamente en el proyecto local
- [ ] SKILL.md tiene frontmatter completo (name, description, version, triggers)
- [ ] Si es un skill nuevo, está categorizado correctamente en `available-skills/<categoría>/`
- [ ] El commit message sigue Conventional Commits
- [ ] No se incluyen ficheros específicos del proyecto (paths absolutos, secrets, etc.)
- [ ] Si cambia scope.yaml schema → label `breaking-change` + version MAJOR

---

## Comunicación

- **Issues**: Usar GitHub Issues en `ava-group-iberiademos/bolt-framework` para bugs y feature requests
- **Discusiones**: GitHub Discussions para propuestas de cambios grandes (RFCs)
- **Changelog**: Cada release tiene notas automáticas basadas en commits convencionales
