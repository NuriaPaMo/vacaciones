# Estructura de Proyecto Bolt Framework

> Directorios estándar para proyectos gestionados con Bolt Framework.
> Referenciado desde `SKILL.md § File Structure`.

## Greenfield (nuevo proyecto)

```text
project/
├── .boltf/
│   ├── memory/
│   │   ├── constitution.md          # Project DNA
│   │   └── provision-report.md      # Provisioning log
│   ├── scopes.yaml                  # Active scopes config
│   └── scopes/                      # Scope definitions
│       ├── backend/
│       ├── frontend/
│       └── cloud-platform/
├── specs/
│   └── XXX-feature-name/
│       ├── feature.md
│       ├── requirements/
│       │   └── requirements.md
│       ├── planning/
│       │   ├── plan.md
│       │   └── tasks.md             # BOLT tasks
│       └── contracts/
├── src/                             # Source code
├── .github/
│   ├── agents/                      # Bolt agents (30+)
│   └── skills/                      # Provisioned skills
└── docs/
    └── adr/                         # Architecture Decision Records
```

## Brownfield (proyecto heredado)

```text
project/
├── legacy/                          # Análisis de código legacy
│   ├── analysis/
│   └── migration-plan.md
├── .boltf/
│   └── memory/
│       └── constitution.md
├── specs/
│   └── XXX-migration-feature/
└── src/
    ├── new/                         # Nuevo código
    └── legacy/                      # Código en migración
```

## Artefactos por fase

| Fase         | Artefacto principal                       |
| ------------ | ----------------------------------------- |
| INCEPTION    | `.boltf/memory/constitution.md`           |
| DISCOVERY    | `specs/XXX-feature/feature.md`            |
| CONSTRUCTION | `specs/XXX-feature/planning/tasks.md`     |
| TRANSITION   | `CHANGELOG.md`, tag semántico             |
| PRODUCTION   | Dashboards de observabilidad              |
| RETIREMENT   | `docs/postmortem-*.md`                    |
