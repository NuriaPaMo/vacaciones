# Ejemplo: Diagrama de Arquitectura Básica

Este es un ejemplo básico de cómo representar una arquitectura simple con servicios y bases de datos usando Mermaid.

## Caso de Uso

Documentar una arquitectura típica de aplicación web con API Gateway, servicios de autenticación y usuarios.

## Diagrama

```mermaid
graph TB
    Client[Cliente] --> API[API Gateway]
    API --> Auth[Servicio Auth]
    API --> Users[Servicio Usuarios]
    Users --> DB[(Base de Datos)]
    Auth --> Cache[(Cache Redis)]
```

## Cuándo Usar

- Decisiones sobre arquitectura de servicios
- Mostrar flujo básico de datos
- Documentar componentes principales del sistema
- ADRs sobre patrones arquitectónicos

## Variaciones

### Con Subgrafos (Capas)

```mermaid
graph TB
    subgraph "Frontend"
        Client[Cliente Web]
    end

    subgraph "API Layer"
        API[API Gateway]
    end

    subgraph "Services"
        Auth[Servicio Auth]
        Users[Servicio Usuarios]
    end

    subgraph "Data Layer"
        DB[(Base de Datos)]
        Cache[(Cache Redis)]
    end

    Client --> API
    API --> Auth
    API --> Users
    Users --> DB
    Auth --> Cache
```

### Con Estilos (Colores)

```mermaid
graph TB
    Client[Cliente] --> API[API Gateway]
    API --> Auth[Servicio Auth]
    API --> Users[Servicio Usuarios]
    Users --> DB[(Base de Datos)]
    Auth --> Cache[(Cache Redis)]

    classDef frontend fill:#e3f2fd
    classDef api fill:#fff3e0
    classDef service fill:#e8f5e9
    classDef data fill:#f3e5f5

    class Client frontend
    class API api
    class Auth,Users service
    class DB,Cache data
```

## Referencias

- [Mermaid Flowchart Docs](https://mermaid.js.org/syntax/flowchart.html)
- Usado en: `bolt-adr/SKILL.md`
