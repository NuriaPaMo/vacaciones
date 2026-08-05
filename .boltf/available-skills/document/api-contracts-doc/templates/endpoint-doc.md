# API: {{ NombreRecurso }}

Base path: `{{ /api/ruta-base }}`

## Endpoints

### GET {{ /ruta }}

**Descripción**: {{ descripción breve }}

**Autorización**: {{ roles requeridos o "Ninguna" }}

**Query Parameters**:

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `page`    | int  | No (def: 1) | Número de página |
| `pageSize`| int  | No (def: 10) | Tamaño de página |

**Respuestas**:

| Código | Descripción | Schema |
|--------|-------------|--------|
| 200 | Éxito | `PagedResult<{{ Dto }}>` |
| 400 | Petición inválida | `ErrorResponse` |
| 401 | No autorizado | — |

**Ejemplo de respuesta 200**:

```json
{
  "items": [],
  "totalCount": 0,
  "page": 1,
  "pageSize": 10
}
```

---

### POST {{ /ruta }}

**Descripción**: {{ descripción breve }}

**Autorización**: {{ roles requeridos o "Ninguna" }}

**Request Body** (`application/json`):

```json
{
  "{{ campo }}": "{{ tipo/ejemplo }}"
}
```

**Respuestas**:

| Código | Descripción | Schema |
|--------|-------------|--------|
| 201 | Creado | `{{ Dto }}` |
| 400 | Validación fallida | `ErrorResponse` |
| 401 | No autorizado | — |
| 409 | Conflicto | `ErrorResponse` |

---

### PUT {{ /ruta/{id} }}

**Descripción**: {{ descripción breve }}

**Parámetros de ruta**:

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | Guid | Identificador del recurso |

**Request Body** (`application/json`):

```json
{
  "{{ campo }}": "{{ tipo/ejemplo }}"
}
```

**Respuestas**:

| Código | Descripción | Schema |
|--------|-------------|--------|
| 200 | Actualizado | `{{ Dto }}` |
| 400 | Validación fallida | `ErrorResponse` |
| 404 | No encontrado | `ErrorResponse` |

---

### DELETE {{ /ruta/{id} }}

**Descripción**: {{ descripción breve }}

**Parámetros de ruta**:

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `id` | Guid | Identificador del recurso |

**Respuestas**:

| Código | Descripción |
|--------|-------------|
| 204 | Eliminado |
| 404 | No encontrado |
