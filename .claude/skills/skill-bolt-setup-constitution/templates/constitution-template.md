# Constitution Template

> Project DNA — defines tech stack, standards, and constraints.
> Location: `.boltf/memory/constitution.md`

---

## 📋 Project Identity

| Field            | Value                     |
| ---------------- | ------------------------- |
| **Project Name** | [PROJECT_NAME]            |
| **Project Type** | [greenfield / brownfield] |
| **Created**      | [DATE]                    |
| **Version**      | 1.0.0                     |
| **Status**       | ⬜ Draft / ✅ Ratified    |

## 🎯 Project Purpose

[Brief description of what this project does and why it exists]

## 🏗️ Technology Stack

### Languages & Frameworks

| Layer        | Technology                               | Version   |
| ------------ | ---------------------------------------- | --------- |
| **Frontend** | [React / Angular / Vue / None]           | [version] |
| **Backend**  | [.NET / Node.js / Python / Java]         | [version] |
| **Database** | [PostgreSQL / SQL Server / MongoDB]      | [version] |
| **ORM**      | [Entity Framework / Prisma / SQLAlchemy] | [version] |
| **Testing**  | [Jest / xUnit / pytest]                  | [version] |

### Infrastructure

| Component         | Technology                                |
| ----------------- | ----------------------------------------- |
| **Hosting**       | [Azure / AWS / GCP / On-Premise]          |
| **CI/CD**         | [GitHub Actions / Azure DevOps / Jenkins] |
| **Container**     | [Docker / Podman / None]                  |
| **Orchestration** | [Kubernetes / Docker Compose / None]      |

## 📐 Architecture

### Pattern

[Clean Architecture / Hexagonal / Layered / Microservices / Monolith]

### Layer Structure

```text
src/
├── domain/          # Entities, Value Objects, Domain Services
├── application/     # Use Cases, Ports, DTOs
├── infrastructure/  # Repository Implementations, External Services
└── presentation/    # API Controllers, UI Components
```

### Layer Rules

- Domain MUST NOT depend on any other layer
- Application depends only on Domain
- Infrastructure implements Application ports
- Presentation depends on Application

## 📝 Coding Standards

### Naming Conventions

| Element   | Convention                | Example                              |
| --------- | ------------------------- | ------------------------------------ |
| Files     | [kebab-case / PascalCase] | `user-service.ts` / `UserService.cs` |
| Classes   | PascalCase                | `UserService`                        |
| Methods   | [camelCase / PascalCase]  | `getUser()` / `GetUser()`            |
| Variables | camelCase                 | `userName`                           |
| Constants | UPPER_SNAKE               | `MAX_RETRIES`                        |

### Code Quality

| Rule                | Standard                       |
| ------------------- | ------------------------------ |
| Max file length     | [300 lines recommended]        |
| Max function length | [30 lines recommended]         |
| Max parameters      | [4 recommended]                |
| Comments            | [JSDoc / XML Doc / docstrings] |

## 🧪 Testing Requirements

| Metric          | Minimum | Target |
| --------------- | ------- | ------ |
| Line Coverage   | ≥ 80%   | ≥ 90%  |
| Branch Coverage | ≥ 75%   | ≥ 85%  |
| Mutation Score  | ≥ 70%   | ≥ 80%  |

### Testing Strategy

- Unit tests for domain and application layers
- Integration tests for infrastructure
- E2E tests for critical paths
- [TDD / BDD / Coverage-first] approach

## 🔒 Security

| Requirement         | Standard                 |
| ------------------- | ------------------------ |
| Authentication      | [JWT / OAuth2 / Session] |
| Authorization       | [RBAC / ABAC / Claims]   |
| Input Validation    | [All inputs validated]   |
| OWASP Compliance    | [Top 10 addressed]       |
| Dependency Scanning | [Enabled in CI]          |

## 📦 Versioning

| Aspect              | Standard                               |
| ------------------- | -------------------------------------- |
| **Versioning**      | Semantic Versioning (semver)           |
| **Branch Strategy** | [Git Flow / GitHub Flow / Trunk-Based] |
| **Commit Format**   | [Conventional Commits]                 |

## 📋 Quality Gates

All must pass before merge:

- [ ] Linting (0 errors)
- [ ] Unit tests (all passing)
- [ ] Coverage thresholds met
- [ ] No security vulnerabilities (critical/high)
- [ ] Architecture compliance (0 layer violations)
- [ ] Documentation updated

---

**Constitution Status**: ⬜ Draft — Ratify by reviewing and changing status to ✅ Ratified.
