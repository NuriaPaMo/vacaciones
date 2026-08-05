---
name: git-branch-manager
description: Manage Git and GitHub workflows using MCP tools. Create, delete, and manage branches following Bolt Framework naming conventions (feature/[name], feature/[name]/bolt-[N]). Handle commits, pull requests, labels, and merges. Use when creating branch, managing branches, git workflow, checkout, merge, rebase, push, pull, creating PR, merging PR, branch operations, Bolt branch pattern.
---

# Git Branch Manager

This skill enables creating, managing, and deleting Git branches, as well as working with commits
and pull requests.

## When to Use This Skill

Use this skill when you need to:

- Create a new branch for a spec or bolt.
- Manage existing branches (rename, delete, list).
- Work with commits (view history, create commits).
- Create and manage pull requests.
- Ensure that branches follow naming conventions consistently with BOLT framework.
- Ensure that a feature branch is properly merged in main after its spec is closed before being
  deleted.
- Ensure that a bolt branch is properly merged into it's feature branch when de bolt is closed and
  before being deleted.

## Prerequisites

- Git CLI installed.
- GitHub CLI installed.
- GitHub MCP tools available.

### 🌿 **Gestión de Ramas (Branches)**

| Herramienta                      | Descripción                                     |
| -------------------------------- | ----------------------------------------------- |
| `mcp_github_list_branches`       | Listar todas las ramas de un repositorio        |
| `mcp_github_create_branch`       | Crear una nueva rama                            |
| `mcp_github_get_repository_tree` | Ver el árbol de archivos de una rama específica |

### 📝 **Gestión de Commits**

| Herramienta               | Descripción                                             |
| ------------------------- | ------------------------------------------------------- |
| `mcp_github_list_commits` | Listar commits de un repositorio                        |
| `mcp_github_get_commit`   | Obtener detalles de un commit específico (incluye diff) |
| `mcp_github_get_tag`      | Obtener información de un tag/commit                    |
| `mcp_github_list_tags`    | Listar todos los tags del repositorio                   |

### 🔀 **Gestión de Pull Requests**

| Herramienta                                   | Descripción                                                                              |
| --------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `mcp_github_list_pull_requests`               | Listar PRs (con filtros por estado, base, head)                                          |
| `mcp_github_search_pull_requests`             | Buscar PRs con criterios avanzados                                                       |
| `mcp_github_pull_request_read`                | Leer detalles de un PR (get, get_diff, get_status, get_files, get_comments, get_reviews) |
| `mcp_github_create_pull_request`              | Crear un nuevo Pull Request                                                              |
| `mcp_github_create_pull_request_with_copilot` | Crear PR con ayuda de Copilot                                                            |
| `mcp_github_update_pull_request`              | Actualizar un PR existente                                                               |
| `mcp_github_merge_pull_request`               | Mergear un Pull Request                                                                  |
| `mcp_github_pull_request_review_write`        | Crear/enviar reviews en PRs                                                              |
| `mcp_github_request_copilot_review`           | Solicitar review automática de Copilot                                                   |
| `mcp_github_add_comment_to_pending_review`    | Añadir comentarios a review pendiente                                                    |
| `mcp_github_update_pull_request_branch`       | Actualizar rama del PR                                                                   |

### 🏷️ **Gestión de Labels**

| Herramienta              | Descripción                               |
| ------------------------ | ----------------------------------------- |
| `mcp_github_list_label`  | Listar todos los labels de un repositorio |
| `mcp_github_get_label`   | Obtener un label específico               |
| `mcp_github_label_write` | Crear, actualizar o eliminar labels       |

### 📜 **Histórico y Búsqueda**

| Herramienta                       | Descripción                             |
| --------------------------------- | --------------------------------------- |
| `mcp_github_list_commits`         | Historial de commits                    |
| `mcp_github_get_commit`           | Ver cambios de un commit (incluye diff) |
| `mcp_github_list_releases`        | Historial de releases                   |
| `mcp_github_get_latest_release`   | Obtener el último release               |
| `mcp_github_get_release_by_tag`   | Obtener release por tag                 |
| `mcp_github_search_code`          | Buscar código en todo GitHub            |
| `mcp_github_search_issues`        | Buscar issues con criterios avanzados   |
| `mcp_github_search_pull_requests` | Buscar PRs con criterios avanzados      |

### 📁 **Gestión de Archivos**

| Herramienta                        | Descripción                      |
| ---------------------------------- | -------------------------------- |
| `mcp_github_get_file_contents`     | Obtener contenido de archivos    |
| `mcp_github_create_or_update_file` | Crear o actualizar un archivo    |
| `mcp_github_delete_file`           | Eliminar un archivo              |
| `mcp_github_push_files`            | Hacer push de múltiples archivos |

## Core Capabilities

### 1. Crear ramas para specs y bolts

- Crear ramas siguiendo convenciones de nombres.
- Una spec siempre es una rama que se crea a partir de main.
  - Su nombre debe de ser feature/spec-<ID>-<descripción>.
- Un bolt siempre es una rama que se crea a partir de la rama de su spec correspondiente.
  - Su nombre debe de ser feature/bolt<Número Bolt>-<ID>-<descripción>.
- Asociar ramas a issues o PRs correspondientes.

### 2. Gestionar ramas existentes

- Listar todas las ramas en el repositorio.
- Renombrar ramas según convenciones de nombres.
- Eliminar ramas que ya no son necesarias.
- Ver el árbol de archivos de una rama específica.
- Verificar el estado de las ramas (actualizadas, desactualizadas).
- Sincronizar las ramas de acuerdo a la lógica de BOLT Framework.

### 3. Trabajar con commits

- Listar commits en una rama específica.
- Ver detalles de un commit específico, incluyendo el diff.
- Ser capaz de ver las diferencias entre commits.
- Crear nuevos commits en una rama asociándolos a issues o PRs.
- Usar como plantila
