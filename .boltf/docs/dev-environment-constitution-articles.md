# Development Environment - Constitution Articles

Este documento define cómo añadir **Article XXIII: Development Environment** a los scope constitutions, documentando el entorno de desarrollo local seleccionado durante initialization.

## Ubicación

Cada scope constitution (`.boltf/scopes/{scope}/memory/constitution.md`) debe incluir una sección sobre el entorno de desarrollo relevante para ese scope.

---

## Article XXIII: Development Environment (Template)

### Para Scopes Multi-Service (backend, frontend, cloud-platform)

```markdown
## Article XXIII: Development Environment

### Local Development Stack

**Container Runtime**: {docker|podman|none}

- Docker Desktop: Standard container runtime with GUI management
- Podman: Rootless, daemonless alternative
- None: No containerization (native development)

**Service Orchestration**: {docker-compose|kubernetes|aspire|podman|none}

- Docker Compose: YAML-based multi-container orchestration
- Kubernetes: minikube/kind for local Kubernetes clusters
- .NET Aspire: Service discovery + dashboard (Apps & Infra)
- Podman Compose: Rootless alternative to Docker Compose
- None: Manual service startup

**Cloud Development**: {codespaces|devcontainers|both|none}

- GitHub Codespaces: Cloud-based VS Code environment
- Devcontainers: .devcontainer.json for local VS Code Remote
- Both: Supports Codespaces + Devcontainers
- None: Local development only

### Provisioned Configurations

Based on above selections, the following dev environment configs are provisioned:

- ✓ **Orchestration Files**: {docker-compose.yml | k8s manifests | AppHost project}
- ✓ **Devcontainer**: {.devcontainer/devcontainer.json} (if cloud dev enabled)
- ✓ **Runtime Tools**: {Docker CLI | Podman CLI | kubectl | Aspire CLI}

### Development Workflow

1. **Container Runtime Setup**
   - Docker Desktop installed and running
   - OR Podman configured (rootless mode recommended)

2. **Service Startup**
   - Docker Compose: `docker-compose up`
   - Kubernetes: `kubectl apply -f k8s/`
   - Aspire: `dotnet run --project AppHost`
   - Manual: Start each service individually

3. **IDE Configuration**
   - VS Code: .devcontainer auto-detected
   - GitHub Codespaces: Open in browser
   - JetBrains Rider: Docker/Kubernetes plugins

4. **Service Discovery**
   - Aspire: Automatic via AppHost (localhost:15888 dashboard)
   - Docker Compose: DNS resolution by service name
   - Kubernetes: Service DNS (ClusterIP)
   - Manual: Environment variables or hardcoded URLs

### Trade-offs

**Docker Compose**:

- ✅ Simple, widely adopted
- ✅ Fast startup
- ⚠️ Docker Desktop licensing (for enterprises)

**Kubernetes (local)**:

- ✅ Production parity
- ⚠️ Heavier resource usage
- ⚠️ Steeper learning curve

**.NET Aspire**:

- ✅ Automatic service discovery
- ✅ Built-in observability
- ⚠️ .NET ecosystem only

**Podman**:

- ✅ Rootless (better security)
- ✅ Open source (no licensing)
- ⚠️ Fewer GUI tools

### References

- Docker Compose: https://docs.docker.com/compose/
- Kubernetes (local): https://kubernetes.io/docs/setup/learning-environment/minikube/
- .NET Aspire: https://learn.microsoft.com/dotnet/aspire
- Podman: https://podman.io/getting-started/
- Devcontainers: https://containers.dev/
```

---

## Article XXIII: Frontend-Specific Additions

Para el scope **frontend**, añadir subsección sobre framework:

```markdown
### Frontend Framework

**Selected Framework**: {react|angular|vue|none}

**Provisioned Resources**:

- **React**:
  - ✓ Awesome Copilot instructions: reactjs.instructions.md
  - ✓ Patterns: Hooks, Context API, component composition
  - ✓ State management: Redux Toolkit / Zustand / Context

- **Angular**:
  - ✓ Awesome Copilot instructions: angular.instructions.md
  - ✓ Patterns: Standalone components, Signals, RxJS
  - ✓ State management: NgRx (recommended)

- **Vue.js**:
  - ✓ Awesome Copilot instructions: vuejs.instructions.md
  - ✓ Patterns: Composition API, Composables, Reactive refs
  - ✓ State management: Pinia (recommended)

**Development Server**:

- React: `npm run dev` (Vite) or `npm start` (CRA)
- Angular: `ng serve` (Angular CLI)
- Vue: `npm run dev` (Vite)

**Testing**:

- React: Jest + React Testing Library
- Angular: Jasmine + Karma (or Jest with ng-jest)
- Vue: Vitest + Vue Test Utils

**Build Tool**:

- Modern: Vite (React, Vue)
- Traditional: Webpack (CRA, Angular CLI)

### Rationale

**Why {selected-framework}?**

- Project requirements: {describe}
- Team expertise: {describe}
- Ecosystem maturity: {describe}
- Performance needs: {describe}

**Trade-offs**:

**React**:

- ✅ Largest ecosystem, most resources
- ✅ Flexible (functional components, hooks)
- ⚠️ No official state management (fragmentation)

**Angular**:

- ✅ Comprehensive framework (batteries included)
- ✅ TypeScript-first, strong typing
- ⚠️ Steeper learning curve

**Vue.js**:

- ✅ Progressive adoption (easy to start)
- ✅ Simple API (Composition API intuitive)
- ⚠️ Smaller ecosystem compared to React
```

---

## Article XXIII: Backend-Specific Additions

Para el scope **backend**, añadir subsección sobre containerization:

```markdown
### Backend Containerization

**Strategy**: {docker|podman|native}

**Dockerfile Location**: `{backend-service}/Dockerfile`

**Base Images**:

- .NET: `mcr.microsoft.com/dotnet/aspnet:10.0`
- Node.js: `node:20-alpine`
- Python: `python:3.12-slim`

**Multi-stage Build**: {yes|no}

- Build stage: Compile + restore dependencies
- Runtime stage: Minimal image with runtime only

**Container Registry**: {Azure CR|Docker Hub|GitHub CR|none}

**Development Workflow**:

1. Build image: `docker build -t backend-api .`
2. Run locally: `docker run -p 5000:5000 backend-api`
3. Debug: Volume mount source code for hot reload

**Production Build**:

- Optimized layers (dependencies cached)
- Non-root user for security
- Health checks configured
- Environment variables for config

### API Development Environment

**Hot Reload**: {enabled|disabled}

- .NET: `dotnet watch run` (file watcher)
- Node.js: `nodemon` (file watcher)
- Python: `uvicorn --reload` (auto-restart)

**Debug Configuration**:

- VS Code: `.vscode/launch.json` (attach to process)
- Docker: Debugger port exposed (5678 for Python, 9229 for Node)

**Database Connection**:

- Local: Docker Compose with database service
- Cloud: Connection string in .env file or User Secrets
```

---

## Article XXIII: Cloud-Platform-Specific Additions

Para el scope **cloud-platform**, añadir subsección sobre IaC local testing:

````markdown
### Infrastructure as Code - Local Testing

**IaC Tool**: {bicep|terraform|pulumi}

**Local Validation**:

- Bicep: `az bicep build main.bicep` (syntax check)
- Terraform: `terraform plan` (dry-run)
- Pulumi: `pulumi preview` (preview changes)

**Local Environment Emulation**:

- Azure Functions: Azure Functions Core Tools (`func start`)
- Azure Storage: Azurite (local emulator)
- Azure Cosmos DB: Cosmos DB Emulator
- Azure Service Bus: Service Bus Emulator (preview)

**Development Workflow**:

1. Write IaC templates in `/infrastructure`
2. Validate locally: `terraform validate` or `az bicep build`
3. Deploy to dev environment: `terraform apply -var-file=dev.tfvars`
4. Test deployment: Smoke tests on dev resources
5. Promote to higher environments: Manual approval gates

### Kubernetes Development

**If Kubernetes selected**:

**Local Cluster**: {minikube|kind|Docker Desktop Kubernetes}

**Setup**:

1. Install cluster: `minikube start` or `kind create cluster`
2. Deploy manifests: `kubectl apply -f k8s/`
3. Port forward: `kubectl port-forward svc/backend 8080:80`

**Development Workflow**:

- Build image: `docker build -t backend:v1 .`
- Load to cluster: `minikube image load backend:v1`
- Deploy: `kubectl apply -f k8s/deployment.yaml`
- Watch logs: `kubectl logs -f deployment/backend`

**Tools**:

- Helm: Package manager for Kubernetes
- Skaffold: CI/CD for Kubernetes (hot reload)
- Tilt: Multi-service development environment

### Aspire Integration (if enabled)

**If Aspire orchestration selected**:

**AppHost Project**: `{SolutionName}.AppHost`

**Service References**:

```csharp
var backend = builder.AddProject<Projects.BackendApi>("backend");
var frontend = builder.AddProject<Projects.Frontend>("frontend")
    .WithReference(backend);
```
````

**Dashboard**: <http://localhost:15888>

- Distributed tracing (OpenTelemetry)
- Logs aggregation
- Metrics visualization
- Service health checks

**Deployment**:

- Local: `dotnet run --project AppHost`
- Azure: `azd up` (provisions + deploys)

````text

---

## Actualización de Scopes Existentes

### Paso 1: Añadir Article XXIII a cada scope

```bash
# backend/memory/constitution.md
# frontend/memory/constitution.md
# cloud-platform/memory/constitution.md
# data/memory/constitution.md
# integration/memory/constitution.md
# ai/memory/constitution.md
````

### Paso 2: Personalizar por Scope

- **backend**: Containerization + API dev environment
- **frontend**: Framework-specific + build tools
- **cloud-platform**: IaC testing + Kubernetes/Aspire
- **data**: Database tools + data pipeline local testing
- **integration**: Message broker emulators + API mocking
- **ai**: ML model serving + Jupyter notebooks + GPU setup

### Paso 3: Merge en Constitution Principal

Cuando `Invoke-BoltSetupConstitution.ps1` ejecuta Phase 1 (Constitution Merge), Article XXIII de cada scope se añade al constitution principal en `.boltf/memory/constitution.md`.

**Resultado esperado**:

```markdown
# Project Constitution

...

## Article XXIII: Development Environment

### Backend Development

**Container Runtime**: Docker Desktop
**Orchestration**: Docker Compose

...

### Frontend Development

**Framework**: React
**Hot Reload**: Enabled (Vite dev server)

...

### Infrastructure Development

**IaC Tool**: Bicep
**Local Testing**: Azure Functions Core Tools + Azurite

...
```

---

## Beneficios

### Para Desarrolladores

- ✅ **Documentación centralizada**: Todo el stack de dev en un lugar
- ✅ **Onboarding rápido**: Nuevos devs ven qué herramientas necesitan
- ✅ **Decisiones explicadas**: Rationale para cada herramienta seleccionada

### Para Bolt Framework

- ✅ **Configuration-driven**: Article XXIII generado desde scopes.yaml
- ✅ **Consistency**: Todas las decisiones documentadas estructuradamente
- ✅ **Extensibility**: Añadir nuevas herramientas es trivial

### Para AI-DLC

- ✅ **Context para agentes**: Agentes saben qué herramientas están disponibles
- ✅ **Comandos específicos**: Agentes pueden sugerir comandos correctos (docker vs podman)
- ✅ **Troubleshooting**: Article XXIII provee referencias para common issues

---

## Referencias

- Init.ps1: Step 1.7 - Development Environment Configuration
- scopes.yaml: project.local-orchestration, project.frontend-framework, etc.
- Smart Enablement Logic: `.boltf/docs/smart-enablement-logic.md`

---

*Development Environment Constitution Articles v1.0 - Bolt Framework*
