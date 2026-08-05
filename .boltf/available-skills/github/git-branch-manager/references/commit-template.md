# Commit Message Template - BOLT Peritec

## 📝 Formato Estándar

```text
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## 🎯 Tipos de Commit (Conventional Commits)

| Tipo       | Emoji | Descripción                  | Ejemplo                                               |
| ---------- | ----- | ---------------------------- | ----------------------------------------------------- |
| `feat`     | ✨    | Nueva funcionalidad          | `feat(auth): implement multi-tenant repositories`     |
| `fix`      | 🐛    | Corrección de bug            | `fix(tasks): update code block formatting`            |
| `docs`     | 📚    | Solo documentación           | `docs: add ADR-0007 for EF Core Global Query Filters` |
| `refactor` | ♻️    | Refactorización de código    | `refactor(auth): Remove RLS script - use filtering`   |
| `test`     | 🧪    | Añadir o modificar tests     | `test(auth): T025-T031-QG - Quality Gates PASSED ✅`  |
| `style`    | 🎨    | Formateo, espacios en blanco | `style: apply prettier formatting`                    |
| `chore`    | 🔧    | Tareas de mantenimiento      | `chore: update dependencies`                          |
| `perf`     | ⚡    | Mejoras de rendimiento       | `perf(api): optimize query performance`               |

## 🏷️ Scope (Alcance)

El scope identifica la parte del proyecto afectada:

**Por Dominio:**

- `auth` - Autenticación y multi-tenancy
- `encargos` - Gestión de encargos
- `peritos` - Gestión de peritos
- `companias` - Gestión de compañías
- `tarificadores` - Tarificadores
- `visitas` - Visitas

**Por Tipo:**

- `spec` - Especificaciones (ej: `auth-spec`)
- `tests` - Tests específicos
- `docs` - Documentación
- `ci` - CI/CD workflows

**Por Feature/BOLT:**

- Usar nombre descriptivo de la feature o tarea BOLT

## 📋 Subject (Asunto)

**Reglas:**

- ✅ Imperativo: "add" no "added" o "adds"
- ✅ Sin mayúscula inicial (lowercase)
- ✅ Sin punto final
- ✅ Máximo 72 caracteres
- ✅ Describe QUÉ hace el commit, no CÓMO

**Ejemplos Correctos:**

```text
feat(auth): implement database schema with EF Core configurations (#<issue id>)
fix: add missing newlines at end of files for consistency (#<issue id>)
docs(auth): T001-T016 verification - Setup & Domain COMPLETED ✅ (#<issue id>)
refactor(tests): move Authentication projects to /tests/ folder (#<issue id>)
```

## 🔗 Referencias a Issues

### En el Subject (para commits pequeños)

```text
feat(auth): implement multi-tenant repositories (#68)
```

### En el Footer (para commits detallados)

```text
feat(auth): implement BOLT-1 foundation with domain entities

- Created core domain entities: Tenant, Company, User
- Implemented TDD approach with comprehensive test coverage
- Added Value Objects for multi-tenant identifiers

Fixes #68
Part of #24
```

**Keywords de GitHub:**

- `Fixes #123` - Cierra el issue al mergear
- `Closes #123` - Cierra el issue al mergear
- `Resolves #123` - Cierra el issue al mergear
- `Part of #123` - Relacionado con el issue (no cierra)
- `Relates to #123` - Relacionado con el issue (no cierra)
- `Refs #123` - Referencia al issue (no cierra)

## 📊 Formato BOLT Framework (Tareas y BOLTs)

### Para Tareas Específicas

```text
feat(auth): T021-T024 - Enhance EF Core configurations

Complete tasks T021 through T024:
- ASP.NET Identity integration
- User store implementation
- Role-based security

Fixes #68
```

### Para BOLTs Completos

```text
feat(auth): BOLT-1 Foundation & Data Model - Authentication

✅ BOLT-1 COMPLETE - All tasks delivered:
- T001-T010: Domain entities with TDD
- T011-T020: EF Core migrations and schema
- T021-T030: Repository pattern implementation
- Quality Gates: ALL PASSED ✅

Fixes #68 (BOLT-1)
Part of #24 (Feature: Authentication & Multi-tenancy)
```

### Para Quality Gates

```text
test(auth): T025-T031-QG - Quality Gates PASSED ✅

All quality gates validated:
✅ Unit test coverage: 92% (target: 85%+)
✅ Architecture tests: 57/57 passing
✅ Performance: < 2s (target: < 30s)

Fixes #68
```

## 📝 Body (Cuerpo - Opcional)

**Cuándo usar:**

- Explicar el PORQUÉ del cambio, no el QUÉ (eso está en el subject)
- Detallar contexto o decisiones importantes
- Listar cambios cuando son múltiples
- Incluir breaking changes

**Formato:**

- Línea en blanco después del subject
- Máximo 72 caracteres por línea
- Usar bullets para listar cambios

**Ejemplo:**

```text
feat(auth): implement multi-tenant repository pattern

Implement generic repository with tenant isolation:
- Created IRepository<T> with tenant filtering
- Added Unit of Work pattern for transactions
- Integrated with EF Core Global Query Filters

This approach ensures data isolation without RLS complexity
and maintains testability through dependency injection.

Part of #68
```

## 🚨 Breaking Changes

Para cambios que rompen compatibilidad:

```text
feat(auth)!: migrate to new authentication API

BREAKING CHANGE: Authentication API v1 is deprecated.
All clients must update to use new OAuth 2.0 flow.

Migration guide: docs/migration-v2.md

Fixes #123
```

## ✅ Ejemplos Reales del Proyecto

### Commits de Features

```text
feat(auth): implement database schema with EF Core configurations (#68)
feat(auth): implement multi-tenant repositories with TDD (#68)
feat(architecture-tests): Implement Bolt 1 Foundation - Setup test project structure
```

### Commits de Fixes

```text
fix: add missing newlines at the end of several files for consistency
fix(tasks): update code block formatting in tasks.md for markdown compatibility
```

### Commits de Documentación

```text
docs: add ADR-0007 for EF Core Global Query Filters decision (#68)
docs(auth): T001-T016 verification - Setup & Domain COMPLETED ✅
docs: complete BOLT-4 documentation and Mermaid diagram conversion
```

### Commits de Refactoring

```text
refactor(auth): Remove RLS script - use application-layer filtering instead
refactor(tests): Move Authentication test projects to /tests/ + create ITenantProvider
refactor: Update markdownlint configuration and streamline Tailwind CSS class regex
```

### Commits de Tests

```text
test(auth): T025-T031-QG - Quality Gates PASSED ✅
```

## 🎯 Checklist Antes de Commit

- [ ] El tipo es correcto (feat, fix, docs, etc.)
- [ ] El scope identifica claramente el área afectada
- [ ] El subject es imperativo y < 72 caracteres
- [ ] Incluye referencia al issue (#123)
- [ ] Si es un BOLT/tarea, incluye el código (T001, BOLT-1)
- [ ] Body explica el PORQUÉ si es necesario
- [ ] Breaking changes están marcados con `!` y `BREAKING CHANGE:`

## 🔧 Configuración Git

Para usar este template automáticamente:

```bash
# Crear archivo template local
git config commit.template .claude/skills/git-branch-manager/references/commit-template.txt

# O global para todos los repos
git config --global commit.template ~/.gitmessage
```

---

**Basado en**: Conventional Commits 1.0.0 + Bolt Framework Methodology
