# Ejemplo: Workflow de Review y Aprobación de ADR

Diagrama que muestra el proceso completo desde la creación de un ADR hasta su mantenimiento continuo.

## Caso de Uso

Documentar el flujo de trabajo estándar para proponer, revisar, aprobar e implementar decisiones arquitectónicas usando ADRs.

## Diagrama

```mermaid
graph LR
    A[1. DRAFT<br/>Create ADR<br/>Status: Proposed] --> B[2. REVIEW<br/>Team reviews<br/>Feedback]
    B --> C[3. DECISION<br/>Accept/Reject<br/>Update status]
    C --> D[4. IMPLEMENT<br/>Code changes<br/>Track in tasks]
    D --> E[5. VALIDATE<br/>Verify works<br/>Document]
    E --> F[6. MAINTAIN<br/>Update if needed<br/>Supersede if changed]

    classDef draft fill:#fff3cd
    classDef review fill:#cfe2ff
    classDef decision fill:#d1e7dd
    classDef implement fill:#f8d7da

    class A draft
    class B review
    class C decision
    class D,E,F implement
```

## Fases del Workflow

1. **DRAFT** - Creación inicial del ADR con status "Proposed"
2. **REVIEW** - Equipo técnico revisa y proporciona feedback
3. **DECISION** - Se acepta o rechaza la propuesta
4. **IMPLEMENT** - Se implementan los cambios en código
5. **VALIDATE** - Se verifica que la solución funciona
6. **MAINTAIN** - Mantenimiento continuo, updates o superseding

## Cuándo Usar

- ADRs sobre procesos de governance
- Documentar workflow de aprobación de decisiones
- Mostrar ciclo de vida de un ADR
- Sección de "Proceso" en guías arquitectónicas

## Variaciones

### Con Decisión de Rechazo

```mermaid
graph LR
    A[DRAFT] --> B[REVIEW]
    B --> C{DECISION}
    C -->|Accept| D[IMPLEMENT]
    C -->|Reject| R[REJECTED<br/>Document reasons]
    D --> E[VALIDATE]
    E --> F[MAINTAIN]

    classDef rejected fill:#f8d7da
    class R rejected
```

### Con Ciclo de Feedback

```mermaid
graph LR
    A[DRAFT] --> B[REVIEW]
    B --> C{Needs<br/>Changes?}
    C -->|Yes| A
    C -->|No| D[DECISION]
    D --> E[IMPLEMENT]
```

## Estados de ADR Asociados

| Fase del Workflow | Status ADR       |
| ----------------- | ---------------- |
| DRAFT             | Proposed         |
| REVIEW            | Proposed         |
| DECISION          | Accepted         |
| IMPLEMENT         | Accepted         |
| VALIDATE          | Accepted         |
| MAINTAIN          | Accepted         |
| Rechazado         | Rejected         |
| Obsoleto          | Deprecated       |
| Reemplazado       | Superseded by... |

## Referencias

- Ver SKILL.md sección "Workflow de Review y Aprobación"
- Ver templates/madr-standard.md campo "## Status"
