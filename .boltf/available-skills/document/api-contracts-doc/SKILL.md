---
name: api-contracts-doc
description: >
  Documenta contratos de API REST extrayendo endpoints, schemas y ejemplos directamente desde
  controllers ASP.NET Core (.NET). SIEMPRE usar cuando el usuario mencione: documentar API,
  generar OpenAPI, crear docs de endpoints, API contracts, swagger docs, documentar controllers,
  generar especificación de API, request/response schemas. Produce archivos Markdown listos
  para `docs/api/` y puede generar YAML OpenAPI 3.0.
---

# API Contracts Documentation

Genera documentación de contratos de API REST desde código fuente .NET,
especificaciones de features y swagger existentes. Produce documentación
Markdown estructurada para `docs/api/` y ficheros OpenAPI 3.0 YAML.

## Cuándo Usar

- El agente Bolt Documentation necesita cubrir la sección `docs/api/`
- El usuario pide documentar endpoints, request/response schemas o ejemplos de uso
- Hay controllers ASP.NET Core que carecen de documentación externa
- Se quiere generar o actualizar el fichero `openapi.yml`

## Cuándo NO Usar

- Para documentación de arquitectura (usar `architect-diagramer`)
- Para generar los propios controllers (usar `dotnet-backend-patterns`)
- Para tests de API (usar `backend-testing-dotnet`)

---

## Workflow

### 1. Identificar Fuente

Determina de dónde vienen los contratos. Prioridad:

| Fuente | Cómo detectarla |
|--------|----------------|
| **Controllers .NET** | `src/backend/**/*Controller.cs` |
| **swagger-spec.json** | `swagger-spec.json` en raíz del proyecto |
| **Feature specs** | `specs/**/contracts/` |
| **Descripción libre** | El usuario describe los endpoints verbalmente |

### 2. Extraer Contratos

Para cada controller encontrado, extrae:

- Ruta base (`[Route]`)
- Método HTTP + ruta relativa (`[HttpGet]`, `[HttpPost]`, etc.)
- Parámetros de entrada (query, route, body) con tipos
- Respuestas posibles (`[ProducesResponseType]`) con códigos HTTP y schemas
- Descripción (`/// <summary>`)
- Atributos de autorización / roles

**Ejemplo de extracción C#:**

```csharp
/// <summary>Obtiene clientes con paginación</summary>
[HttpGet]
[ProducesResponseType(typeof(PagedResult<ClienteDto>), 200)]
[ProducesResponseType(typeof(ErrorResponse), 400)]
public async Task<IActionResult> GetClientes([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
```

Se convierte en → documentar campos: ruta, método, parámetros, respuestas, descripción.

### 3. Producir Documentación

Genera **dos artefactos**:

#### A. Markdown para `docs/api/{recurso}.md`

Carga y rellena [`templates/endpoint-doc.md`](templates/endpoint-doc.md).

#### B. OpenAPI 3.0 YAML para `docs/api/openapi.yml`

Carga y rellena [`templates/openapi.yml`](templates/openapi.yml). Si no existe el fichero destino, créalo desde cero. Si existe, añade/actualiza los paths afectados.

### 4. Guardar Ficheros

```text
docs/
└── api/
    ├── openapi.yml          ← especificación OpenAPI 3.0
    ├── {recurso-1}.md       ← documentación navegable por recurso
    └── {recurso-2}.md
```

---

## Plantillas

| Plantilla | Fichero | Cuándo cargarla |
|-----------|---------|------------------|
| Documentación Markdown por recurso | [`templates/endpoint-doc.md`](templates/endpoint-doc.md) | Paso 3A |
| Especificación OpenAPI 3.0 | [`templates/openapi.yml`](templates/openapi.yml) | Paso 3B |

---

## Convenciones del Proyecto

- Los controllers están en `src/backend/Services/**/Api/Controllers/`
- Los DTOs de respuesta están en `src/backend/Services/**/*.Application/`  
- La especificación swagger existente está en `swagger-spec.json` (raíz)
- La carpeta destino es siempre `docs/api/`
- Los schemas reutilizables van en `components/schemas` del OpenAPI
- Incluir siempre ejemplos de respuesta para códigos `200` y el error más común
