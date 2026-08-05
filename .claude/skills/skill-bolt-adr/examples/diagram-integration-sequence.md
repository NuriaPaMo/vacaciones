# Ejemplo: Diagrama de Secuencia para Integraciones

Ejemplo de cómo documentar flujos de integración entre servicios usando diagramas de secuencia Mermaid.

## Caso de Uso

ADR que define el flujo de comunicación entre servicios, especialmente útil para decisiones sobre:

- Protocolos de comunicación (REST vs GraphQL vs gRPC)
- Patrones de mensajería (sync vs async)
- Manejo de eventos
- Integraciones con sistemas externos

## Diagrama - Flujo Síncrono con Queue Asíncrono

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as API
    participant D as Database
    participant Q as Queue

    C->>A: Request
    A->>D: Query
    D-->>A: Data
    A->>Q: Publish Event
    A-->>C: Response
```

## Descripción del Flujo

1. **Cliente → API**: Request inicial (HTTP POST/GET)
2. **API → Database**: Query sincrónico para obtener datos
3. **Database → API**: Respuesta con datos solicitados
4. **API → Queue**: Publicación asíncrona de evento (fire-and-forget)
5. **API → Cliente**: Respuesta HTTP con resultado

## Variaciones Comunes

### Flujo con Autenticación

```mermaid
sequenceDiagram
    participant C as Cliente
    participant G as API Gateway
    participant Auth as Auth Service
    participant US as User Service
    participant DB as Database

    C->>G: Request + Token
    G->>Auth: Validate Token
    Auth-->>G: Token Valid
    G->>US: Get User Data
    US->>DB: Query User
    DB-->>US: User Data
    US-->>G: Response
    G-->>C: Final Response
```

### Flujo con Error Handling

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as API
    participant S as Service
    participant DB as Database

    C->>A: Request
    A->>S: Process
    S->>DB: Query
    DB-->>S: Error (Connection Timeout)
    S-->>A: Error Response
    A->>A: Log Error
    A-->>C: 500 Internal Server Error
```

### Flujo Asíncrono con Callbacks

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as API
    participant Q as Queue
    participant W as Worker
    participant CB as Callback

    C->>A: Long Running Request
    A->>Q: Enqueue Job
    A-->>C: 202 Accepted (Job ID)

    Q->>W: Process Job
    W->>W: Execute (30s)
    W->>CB: POST Result
    CB->>C: Webhook Notification
```

## Cuándo Usar Diagramas de Secuencia

| Tipo de ADR             | Escenario                                       |
| ----------------------- | ----------------------------------------------- |
| **INT** - Integración   | Flujo entre servicios, APIs externas            |
| **SEC** - Seguridad     | Flujos de autenticación/autorización            |
| **ARCH** - Arquitectura | Patrones de comunicación (CQRS, Event Sourcing) |
| **DATA** - Datos        | Sincronización, replicación, ETL                |

## Elementos de Mermaid Sequence Diagram

```mermaid
sequenceDiagram
    participant A as Actor A
    participant B as Actor B

    Note over A: Anotación sobre A
    Note over A,B: Anotación sobre ambos

    A->>B: Síncrono (espera respuesta)
    A-->>B: Respuesta (línea punteada)
    A-)B: Asíncrono (no espera)

    alt Condición exitosa
        B-->>A: Respuesta OK
    else Condición de error
        B-->>A: Error
    end

    loop Cada N segundos
        A->>B: Poll
        B-->>A: Status
    end
```

## Tips para Diagramas de Secuencia

1. **De izquierda a derecha**: Actores externos primero, internos después
2. **Nombres claros**: Usar alias descriptivos (`as Cliente` vs `as C`)
3. **Flechas apropiadas**: `->>` para sync, `-)` para async, `-->>` para returns
4. **Agrupar con alt/opt/loop**: Para mostrar condiciones y repeticiones
5. **Notes para aclaraciones**: Explicar decisiones clave en el flujo

## Referencias

- [Mermaid Sequence Diagram Docs](https://mermaid.js.org/syntax/sequenceDiagram.html)
- Usado en: `bolt-adr/SKILL.md`
- Tipo: Decisiones de Integración (INT)
