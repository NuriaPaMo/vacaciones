---
name: skill-aspire-orchestration
description: Orchestrate multi-service .NET applications with .NET Aspire (AppHost, ServiceDefaults, service discovery, OpenTelemetry integration). Use when building .NET distributed apps, implementing local development workflows, deploying to Azure Container Apps with azd, or integrating Azure services (Redis, PostgreSQL, Key Vault). Recommended for .NET-centric microservices prioritizing developer productivity.
---

# .NET Aspire Orchestration

---

## When to Use This Skill

Use this skill when you are:

1. **Building a new .NET distributed application or microservices architecture** — because .NET Aspire provides opinionated orchestration with AppHost, service discovery, and integrated observability that accelerates development for .NET teams, and understanding when Aspire's conventions outweigh direct Kubernetes or Container Apps deployment prevents unnecessary infrastructure complexity or premature abstraction.

2. **Evaluating whether .NET Aspire fits your distributed application needs** — because Aspire is optimized for .NET-centric microservices with Azure integrations (Service Bus, Key Vault, App Configuration), while polyglot architectures or non-Azure deployments may benefit more from direct Kubernetes or Container Apps, and choosing the right orchestration model affects developer experience, operational overhead, and deployment flexibility.

3. **Designing a local development environment for .NET microservices with multiple dependencies** — because Aspire provides containerized dependencies (Redis, PostgreSQL, messaging), unified dashboard for logs/traces/metrics, and hot-reload workflows that simplify inner-loop development compared to manual Docker Compose or local Kubernetes, and evaluating Aspire's local development experience guides tooling investment.

4. **Migrating an existing .NET application to cloud-native patterns** — because adding Aspire to existing ASP.NET Core apps provides service discovery, observability, and resource management without rewriting application code, and understanding Aspire's incremental adoption path (add service defaults, introduce AppHost orchestration, integrate Azure components) ensures smooth modernization without disruption.

5. **Implementing service discovery for .NET microservices** — because Aspire's service discovery integrates seamlessly with `IHttpClientFactory`, resolves service names via DNS, and works consistently across local development and Azure Container Apps deployment, and comparing Aspire's approach to manual Kubernetes service discovery or external service mesh (Istio) informs architecture decisions.

6. **Deploying .NET distributed applications to Azure Container Apps** — because Aspire provides `azd` workflows that generate Bicep infrastructure, configure container apps, and deploy with single commands, and understanding Aspire's deployment model compared to manual Bicep/Terraform and direct Container Apps provisioning affects CI/CD pipeline design and infrastructure-as-code strategy.

7. **Integrating Azure services (Service Bus, Key Vault, App Configuration) into .NET applications with consistent patterns** — because Aspire components provide standardized interfaces for Azure resources with automatic connection string management, dependency injection configuration, and local emulator support, and evaluating Aspire components versus direct Azure SDK usage determines consistency, testability, and maintainability of Azure integrations.

---

## Decision Framework: Selecting .NET Aspire vs. Direct Orchestration

Choosing .NET Aspire depends on your application stack, team preferences, deployment targets, and willingness to adopt Aspire's opinionated conventions. Use this framework to guide your selection:

```text
┌────────────────────────────────────────────────────────┐
│ Orchestrating a distributed .NET application?          │
└────────────────────────────────────────────────────────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
       ▼                   ▼                   ▼
   .NET-centric        Polyglot            Existing K8s
   microservices       architecture        expertise
       │                   │                   │
       ▼                   ▼                   ▼
   .NET Aspire         Direct AKS           Direct AKS
   • AppHost           or Container Apps    • Full control
   • Service discovery • Multi-language     • No abstractions
   • Dashboard         • Flexibility        • Kubernetes API
   • Azure components  • Custom infra       • Service mesh
       │
       │
       ▼
   Deployment target?
       │
   ┌───┴───┐
   │       │
   ▼       ▼
Azure     Kubernetes
Container Apps   (AKS)
   │       │
   ▼       ▼
azd       Aspire
workflow  manifest
• Bicep   • Generate YAML
• Single  • Manual deploy
  command • More control
```

**Key Questions to Guide Selection**:

- Is your application primarily .NET, or polyglot (Node.js, Python, Java)? (Aspire targets .NET)
- Do you prefer opinionated conventions or full control over infrastructure? (Aspire vs. direct K8s)
- Does your team prioritize rapid local development or production parity? (Aspire dashboard vs. K8s)
- Are you deploying to Azure Container Apps or other platforms? (Aspire azd excels for ACA)
- Do you have existing Kubernetes expertise or want simplified abstractions? (Affects learning curve trade-offs)

---

## Scoring Model: .NET Aspire vs. Direct Orchestration

| Orchestration Approach                    | Complexity | Productivity | Flexibility | Local Dev | Azure Integration | .NET Focus |
| ----------------------------------------- | ---------- | ------------ | ----------- | --------- | ----------------- | ---------- |
| **.NET Aspire**                           | Low        | Very High    | Medium      | Excellent | Native            | Exclusive  |
| **Direct Azure Container Apps**           | Low-Med    | Medium       | Medium      | Manual    | Good              | Agnostic   |
| **Direct Azure Kubernetes Service (AKS)** | High       | Low          | Very High   | Complex   | Good              | Agnostic   |

**Note**: This comparison is a conversation starter, not a rigid calculation. Context matters—**.NET Aspire** excels for .NET-centric teams wanting rapid development and Azure deployment, **Container Apps** suits serverless polyglot microservices with event-driven patterns, and **AKS** provides full Kubernetes control for complex multi-language architectures requiring service mesh and advanced networking.

---

## .NET Aspire Explained

### What it enables

**Opinionated orchestration stack** for building cloud-native distributed .NET applications with integrated service discovery, observability (OpenTelemetry), resource management, and Azure component integrations, optimized for developer productivity.

### When it fits

- **.NET-centric distributed applications**: Microservices, APIs, background workers primarily built with ASP.NET Core and .NET 8+
- **Teams prioritizing developer experience**: Rapid local development, unified observability dashboard, hot-reload workflows
- **Azure deployment targets**: Azure Container Apps via `azd` workflows with generated Bicep infrastructure
- **Azure service integrations**: Redis, PostgreSQL, Service Bus, Key Vault, App Configuration with standardized components
- **Greenfield projects or modernization**: New distributed apps or existing apps adding cloud-native patterns

### Key characteristics

**AppHost Orchestration**: Central `DistributedApplication` project defines all resources (projects, containers, Azure services) with dependency graphs. AppHost runs locally with dashboard, generates deployment manifests for production.

**Service Discovery**: Automatic DNS-based resolution of service names. HTTP clients configured with `AddServiceDiscovery()` resolve service endpoints without hardcoded URLs. Works consistently locally (dashboard proxy) and in production (Container Apps DNS).

**Service Defaults**: Shared library providing OpenTelemetry instrumentation (logs, metrics, traces), health checks (`/health`, `/alive`), and service discovery configuration. Applied to all projects for consistent observability.

**Aspire Components**: NuGet packages for Azure resources (Redis, PostgreSQL, Service Bus, Key Vault, App Configuration, Cosmos DB, OpenAI) with standardized interfaces, dependency injection, and connection string management. Components use local emulators for development, production Azure resources for deployment.

**Aspire Dashboard**: Real-time observability UI showing resources, console logs, distributed traces, and metrics. Automatically runs with AppHost, provides unified view of all services and dependencies during local development.

**Deployment via azd**: Azure Developer CLI integration generates Bicep infrastructure, provisions Azure Container Apps environment, deploys all projects as container apps, and configures service connections—all with `azd up` single command.

### Operational considerations

Aspire simplifies local development and Azure Container Apps deployment but introduces .NET-specific abstraction layer. Suitable when .NET productivity gains outweigh polyglot flexibility. Limited to Azure Container Apps and Kubernetes for production; does not abstract AWS or GCP. Requires .NET 8+ and Visual Studio 2022 17.9+ or VS Code with C# Dev Kit.

---

## .NET Aspire vs. Alternatives

### vs. Azure Container Apps (Direct Deployment)

**Aspire Advantage**: `azd` workflows automate Bicep generation, container app provisioning, and service connections. Service discovery, dashboard, and local development environment included. Ideal for .NET teams wanting rapid iteration.

**Direct Container Apps Advantage**: Polyglot support (any language), manual control over Bicep infrastructure, no abstraction layer. Suitable when Aspire's .NET focus is limiting or infrastructure customization is critical.

**When to choose Aspire**: .NET-centric app, rapid Azure deployment, team prefers conventions over custom infrastructure.

**When to choose direct Container Apps**: Polyglot microservices, existing Bicep/Terraform workflows, infrastructure customization beyond Aspire's capabilities.

---

### vs. Azure Kubernetes Service (AKS)

**Aspire Advantage**: Significantly lower complexity—no Kubernetes expertise required. AppHost orchestration, service discovery, and dashboard vs. manual YAML manifests, ingress controllers, and Prometheus/Grafana setup. Faster time-to-production for .NET teams.

**AKS Advantage**: Full Kubernetes control, service mesh (Istio/Linkerd), advanced networking (CNI, network policies), polyglot ecosystem, CNCF tooling (Helm, Operators). Necessary for complex microservices architectures requiring Kubernetes primitives.

**When to choose Aspire**: .NET microservices, team lacks Kubernetes expertise, simplicity > control, Azure Container Apps deployment acceptable.

**When to choose AKS**: Complex microservices, service mesh required, polyglot architecture, existing Kubernetes investment, need full Kubernetes API access.

---

### vs. Docker Compose (Local Development)

**Aspire Advantage**: Service discovery, integrated observability (dashboard with traces/metrics), hot-reload for .NET projects, consistent local-to-production patterns. Docker Compose only orchestrates containers without observability or service discovery.

**Docker Compose Advantage**: Simpler YAML syntax, language-agnostic, no .NET dependency, widely understood.

**When to choose Aspire**: .NET distributed application, need observability dashboard, service discovery for local dev, production deployment to Azure.

**When to choose Docker Compose**: Polyglot local environment, simple container orchestration, no .NET requirement, no production orchestration plan.

---

## Aspire Components

**Redis Component**: Adds Redis cache with `AddRedis("cache")` in AppHost, `AddRedisClient("cache")` in projects. Local container for dev, Azure Redis for production. Includes distributed caching and output caching variants.

**PostgreSQL Component**: Adds PostgreSQL database with `AddPostgres("postgres").AddDatabase("mydb")`. Includes Entity Framework Core integration with `AddNpgsqlDbContext<T>("mydb")`. Local container, Azure Database for PostgreSQL in production.

**Azure Service Bus Component**: Adds messaging with `AddAzureServiceBus("messaging")`. Local emulator (Azurite) for dev, Azure Service Bus for production. Integrated with `ServiceBusClient` dependency injection.

**Azure Key Vault Component**: Adds secrets management with `AddAzureKeyVault("keyvault")`. Integrates as configuration provider, secrets loaded into `IConfiguration`. Uses `DefaultAzureCredential` for authentication.

**Azure App Configuration Component**: Adds centralized configuration with `AddAzureAppConfiguration("appconfig")`. Supports dynamic refresh, feature flags, and Key Vault references. Refresh middleware updates configuration without redeployment.

---

## Local Development Experience

**Unified Dashboard**: Aspire dashboard (`http://localhost:15888` by default) shows all resources, console logs (colored, filterable by log level), distributed traces (OpenTelemetry timeline), and metrics (HTTP requests, runtime stats). No manual Prometheus/Grafana setup.

**Containerized Dependencies**: AppHost provisions containers for Redis, PostgreSQL, messaging automatically. No manual Docker commands—dependencies start with `dotnet run --project AppHost`.

**Hot-Reload Workflows**: .NET hot-reload works with Aspire orchestration. Code changes reflect immediately without restarting entire application stack.

**Service Discovery Testing**: Local service-to-service calls use same service discovery pattern as production (HTTP clients resolve service names). Prevents "works locally, fails in production" scenarios.

---

## Production Deployment to Azure Container Apps

**azd Workflow**: `azd init` configures deployment, `azd provision` generates Bicep and provisions infrastructure, `azd deploy` builds containers and deploys to Container Apps, `azd up` combines provision + deploy.

**Generated Bicep Infrastructure**: Aspire generates Bicep templates for Container Apps environment, container apps for each project, managed identities, service connections (Key Vault references, Service Bus connections), and ingress configuration.

**Environment Variables**: Aspire configures connection strings, service endpoints, and managed identity client IDs automatically. No manual environment variable management.

**CI/CD Integration**: GitHub Actions or Azure Pipelines run `azd deploy` for automated deployments. Aspire manifest format (`manifest.json`) enables integration with custom CI/CD workflows.

---

## Production Deployment to Kubernetes (AKS)

**Manifest Generation**: `dotnet run --project AppHost --publisher manifest` generates `manifest.json` defining all resources and dependencies. Tools like [aspirate](https://github.com/prom3theu5/aspirate) convert manifest to Kubernetes YAML.

**Manual Configuration**: Requires creating Deployments, Services, Ingress manifests manually or via manifest conversion tools. Service discovery translates to Kubernetes DNS (service-name.namespace.svc.cluster.local).

**Observability Integration**: OpenTelemetry traces/metrics export to Prometheus/Grafana or Application Insights. Dashboard not available in production; use external observability tools.

---

## Quick Reference: When to Use .NET Aspire

| Scenario                                          | Use .NET Aspire? | Reason                                                   |
| ------------------------------------------------- | ---------------- | -------------------------------------------------------- |
| .NET distributed app, Azure deployment            | ✅ Yes           | Optimized for .NET + Azure with azd workflows            |
| Polyglot microservices                            | ❌ No            | Aspire is .NET-exclusive; use AKS or Container Apps      |
| Rapid local development needed                    | ✅ Yes           | Dashboard, containerized deps, service discovery         |
| Existing Kubernetes expertise, complex networking | ❌ No            | Use AKS for full control and service mesh                |
| Greenfield .NET microservices                     | ✅ Yes           | Aspire accelerates development with conventions          |
| Migrating .NET monolith to cloud-native           | ✅ Yes           | Incremental adoption—add service defaults, then AppHost  |
| Deploying to AWS or GCP                           | ❌ No            | Aspire targets Azure; use Kubernetes for multi-cloud     |
| Need full Bicep/Terraform control                 | ❌ Maybe         | Use direct Container Apps if Aspire's Bicep insufficient |

---

## Common Pitfalls

**Using Aspire for polyglot architectures**: Aspire is .NET-exclusive. Polyglot microservices (Node.js, Python, Java) cannot use Aspire components or AppHost orchestration. Use AKS, Container Apps, or Docker Compose for multi-language stacks.

**Expecting production deployment to non-Azure platforms**: Aspire targets Azure Container Apps and AKS. Deploying to AWS ECS, GCP Cloud Run, or on-premises Kubernetes requires manual manifest conversion and loses azd workflow benefits. Use Aspire only if Azure is deployment target.

**Over-relying on Aspire abstractions for complex infrastructure**: Aspire generates Bicep but may not support advanced scenarios (custom networking, complex RBAC, multi-region). Evaluate whether Aspire's generated infrastructure meets requirements or requires custom Bicep/Terraform.

**Not configuring service defaults in all projects**: Skipping `builder.AddServiceDefaults()` in projects breaks observability, health checks, and service discovery. Always apply service defaults to every Aspire project for consistent behavior.

**Assuming Aspire dashboard is available in production**: Dashboard runs locally only. Production deployments require Application Insights, Prometheus/Grafana, or Azure Monitor for observability. Plan production telemetry export during app design.

**Using Aspire for non-.NET workloads in same solution**: Aspire cannot orchestrate non-.NET containers (e.g., Python worker, Node.js frontend) in AppHost. Hybrid architectures need direct Container Apps or AKS for non-.NET components, with manual service connections.

**Ignoring Aspire versioning and .NET updates**: Aspire is early-stage (preview/GA recently). Requires .NET 8+, frequent updates. Ensure tooling (Visual Studio, azd CLI) and SDKs stay current to avoid compatibility issues.

---

## Bundled Resources

This skill references:

- **[references/code-examples.md](references/code-examples.md)**: .NET Aspire AppHost configuration, service defaults implementation, Redis/PostgreSQL/Service Bus integrations, Azure Key Vault and App Configuration components, dashboard usage, multi-environment patterns, and resource dependency orchestration demonstrating Aspire's opinionated conventions and Azure integrations.
- **[references/microsoft-learn.md](references/microsoft-learn.md)**: Curated documentation for .NET Aspire overview, AppHost orchestration, service discovery, built-in components (caching, databases, messaging, Azure integrations), dashboard usage, deployment to Azure Container Apps and Kubernetes, observability with OpenTelemetry, testing strategies, migration guides, and community resources with official Microsoft Learn references and sample repositories.
