# Bolt Framework Structure Generator Prompt

> This prompt is called by init.sh to generate the correct project structure based on constitution selections.

You are an expert software architect. Based on the following project configuration, generate the exact folder and file structure following best practices for the selected technology stack.

## Input Configuration

```yaml
project_name: '{{PROJECT_NAME}}'
project_type: '{{PROJECT_TYPE}}' # green | brown

# Backend
backend_language: '{{BACKEND_LANGUAGE}}' # csharp | nodejs
backend_version: '{{BACKEND_VERSION}}' # dotnet8 | dotnet9 | node20 | node22
backend_framework: '{{BACKEND_FRAMEWORK}}' # minimal-api | controllers | express | fastify | nestjs | azure-functions
architecture: '{{ARCHITECTURE}}' # microservices | modular-monolith | monolith | serverless

# Frontend (optional)
frontend_framework: '{{FRONTEND_FRAMEWORK}}' # vue | react | angular | blazor-server | blazor-wasm | none
frontend_version: '{{FRONTEND_VERSION}}'

# Features
cqrs_enabled: '{{CQRS_ENABLED}}' # true | false
event_sourcing: '{{EVENT_SOURCING}}' # true | false
docker_enabled: '{{DOCKER_ENABLED}}' # true | false
kubernetes: '{{KUBERNETES}}' # aks | container-apps | app-service | none

# Infrastructure
iac_tool: '{{IAC_TOOL}}' # bicep | terraform | pulumi
cicd_platform: '{{CICD_PLATFORM}}' # github-actions | azure-devops

# Database
database: '{{DATABASE}}' # azure-sql | sql-server | postgresql | cosmos-db | mongodb
data_access: '{{DATA_ACCESS}}' # ef-core | dapper | ef-dapper | prisma | typeorm | drizzle

# Environments
environments: '{{ENVIRONMENTS}}' # dev,uat,pre,prod (comma-separated)
```

## Generation Rules

### For C# / .NET Projects

1. **Modular Monolith**:
   - Use `src/Modules/{ModuleName}/` structure
   - Each module: Domain, Application, Infrastructure, Api layers
   - Shared kernel in `src/Shared/SharedKernel/`
   - Native CQRS interfaces in `src/Shared/SharedKernel/CQRS/`
   - API host as composition root in `src/Api.Host/`

2. **Microservices**:
   - Use `src/Services/{ServiceName}/` structure
   - Each service is self-contained with all layers
   - Building blocks in `src/BuildingBlocks/`
   - API Gateway in `src/ApiGateway/`

3. **Traditional Monolith**:
   - Use layered structure: Domain, Application, Infrastructure, Presentation
   - Single solution with clear dependencies

4. **File Naming**: PascalCase for folders and files
5. **Projects**: `{ModuleName}.{Layer}.csproj`
6. **Tests**: Mirror src structure in `tests/`

### For Node.js / TypeScript Projects

1. **Modular Monolith**:
   - Use `src/modules/{module-name}/` structure (kebab-case)
   - Each module: domain, application, infrastructure, api folders
   - Shared kernel in `src/shared/kernel/`
   - Entry point in `src/main.ts`

2. **Microservices**:
   - Use `services/{service-name}/` structure
   - Each service has own `package.json`
   - Shared packages in `packages/`
   - Use npm/pnpm workspaces

3. **File Naming**: kebab-case for folders and files
4. **Tests**: Co-located in `__tests__/` or separate `tests/`

### Infrastructure

1. **Bicep**: `infra/bicep/` with modules and environments
2. **Terraform**: `infra/terraform/` with modules and tfvars
3. **Kubernetes**: `infra/k8s/` with helm or kustomize

### Common

1. Always include `specs/` for Bolt Framework specifications
2. Always include `.boltf/memory/constitution.md`
3. Always include `docs/adr/` for architecture decisions
4. Include `.github/` for Copilot agents and commands

## Output Format

Return ONLY a shell script that creates the directory structure. Example:

```bash
#!/bin/bash
# Generated structure for: {{PROJECT_NAME}}

mkdir -p src/Modules/Orders/Orders.Domain/Entities
mkdir -p src/Modules/Orders/Orders.Domain/ValueObjects
# ... more directories

# Create placeholder files
touch src/Modules/Orders/Orders.Domain/Entities/.gitkeep

# Create solution/project files
cat > "src/Api.Host/Program.cs" << 'EOF'
// Program.cs content
EOF
```

## Important Notes

- Generate REAL initial files, not just placeholders where possible
- Include proper `.gitkeep` files in empty directories
- For .NET: Include `Directory.Build.props` and `Directory.Packages.props`
- For Node.js: Include `package.json`, `tsconfig.json`
- Include `.editorconfig` and `.gitignore`
- Generate initial `README.md` for each module
