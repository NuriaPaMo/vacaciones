# Sequence Diagrams

Sequence diagrams show interactions between actors and systems over time.

## Basic Syntax

```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>B: Hello Bob!
    B->>A: Hi Alice!
```

**Example**: `assets/examples/sequence/basic.mmd`

## Participants

- `participant` - For systems and components
- `actor` - For human users (shown with stick figure icon)

**Example**: `assets/examples/sequence/participants.mmd`

## Message Types

| Type          | Syntax | Use Case             |
| ------------- | ------ | -------------------- |
| Solid arrow   | `->>`  | Synchronous request  |
| Dotted arrow  | `-->>` | Response/return      |
| Async solid   | `-)`   | Asynchronous message |
| Async dotted  | `--)`  | Async response       |
| Solid with X  | `-x`   | Lost/failed message  |
| Dotted with X | `--x`  | Failed response      |

**Example**: `assets/examples/sequence/message-types.mmd`

## Activations

Use `+` to activate, `-` to deactivate:

```mermaid
sequenceDiagram
    Client->>+Server: Request
    Server->>+Database: Query
    Database-->>-Server: Data
    Server-->>-Client: Response
```

**Example**: `assets/examples/sequence/activations.mmd`

## Notes

```mermaid
sequenceDiagram
    Note left of A: Left note
    Note right of B: Right note
    Note over A: Note over A
    Note over A,B: Spanning note
```

**Example**: `assets/examples/sequence/notes.mmd`

## Control Flow

| Structure             | Purpose                            |
| --------------------- | ---------------------------------- |
| `loop`                | Repeated actions                   |
| `alt` / `else`        | Conditional branches               |
| `opt`                 | Optional flow                      |
| `par`                 | Parallel actions                   |
| `critical` / `option` | Critical regions with alternatives |

**Example**: `assets/examples/sequence/loops-conditionals.mmd`

## Common Patterns

Refer to example files for complete implementations:

- **REST API Call**: `assets/examples/sequence/rest-api.mmd` Complete login and data fetch flow with
  token authentication

- **Authentication Flow**: `assets/examples/sequence/authentication-flow.mmd` OAuth/authorization
  code flow with multiple participants

- **Error Handling**: `assets/examples/sequence/error-handling.mmd` Success and error scenarios with
  alt/else blocks

## Best Practices

- Use clear participant names (User, API, Database - not A, B, C)
- **Numera cada paso con `autonumber`** — añade trazabilidad y facilita la referencia en documentación
  y revisiones de código
- Show activation bars for long-running operations
- Use notes to explain complex logic
- Keep sequences focused - split complex flows into multiple diagrams
- Use `actor` for human users, `participant` for systems
- Label messages with meaningful descriptions
- Show both request and response messages
- **Evita `rect rgb()`** — solo admite relleno sólido opaco (sin transparencia ni bordes); genera
  ruido visual sobre las barras de activación. Para delimitar fases usa `Note over` abarcando todos
  los participantes

## Ejemplo completo

El siguiente diagrama combina **todas** las buenas prácticas anteriores: numeración automática,
actores vs. participantes, barras de activación, notas de fase y notas explicativas, flujo
condicional (`alt/else`), bucles (`loop`), y mensajes significativos con petición y respuesta.

```mermaid
sequenceDiagram
    autonumber

    actor Usuario as 👤 Usuario
    participant App   as Frontend App
    participant Auth  as Auth API
    participant API   as Backend API
    participant Cache as Redis Cache
    participant DB    as Base de Datos

    Note over Usuario, DB: Fase 1 — Autenticación

    Usuario ->>+ App: Introduce credenciales y pulsa "Iniciar sesión"
    App     ->>  Auth: POST /auth/login {email, password}
    activate Auth
    Auth    ->>+ DB: SELECT usuario WHERE email = ?
    DB      -->>- Auth: Registro de usuario
    Auth    -->>  Auth: Verifica hash de contraseña

    alt Credenciales válidas
        Auth -->> App: 200 OK {access_token, refresh_token}
        Note right of App: Token almacenado en memoria,\nrefresh en cookie HttpOnly
        App  -->> Usuario: Muestra panel principal
    else Credenciales inválidas
        Auth -->> App: 401 Unauthorized {error: "invalid_credentials"}
        App  -->> Usuario: Muestra mensaje de error
    end
    deactivate Auth
    deactivate App

    Note over Usuario, DB: Fase 2 — Carga de datos con caché

    Usuario ->>+ App: Solicita listado de encargos
    App     ->>+ API: GET /encargos (Authorization: Bearer <token>)
    API     ->>+ Auth: Valida token JWT
    Auth    -->>- API: Token válido {userId, tenantId}

    API     ->>  Cache: GET encargos:tenant:{tenantId}
    activate Cache

    alt Caché hit
        Cache -->> API: Datos cacheados
        Note right of Cache: TTL restante > 0
    else Caché miss
        Cache -->> API: null
        API   ->>+ DB: SELECT encargos WHERE tenant_id = ?
        DB    -->>- API: Lista de encargos

        loop Por cada página de resultados
            API ->> Cache: SET encargos:tenant:{tenantId} (TTL 5 min)
        end
    end
    deactivate Cache

    API -->>- App: 200 OK {encargos: [...]}
    App -->>- Usuario: Renderiza tabla de encargos
```

## Advanced Features

### Autonumber

Automatically number messages:

**Example**: `assets/examples/sequence/autonumber.mmd`

### Background Colors

Highlight regions with `rect`:

**Example**: `assets/examples/sequence/background-colors.mmd`

### Critical Regions

Mark critical sections:

**Example**: `assets/examples/sequence/critical-region.mmd`
