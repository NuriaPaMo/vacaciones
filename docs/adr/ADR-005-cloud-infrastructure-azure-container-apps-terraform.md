# ADR-005: Deploy Workloads to Azure Container Apps Using Terraform IaC

## Status

Accepted

## Date

2026-08-05

## Context

The project requires a containerised deployment platform for the .NET 10 backend (ADR-001). The platform must balance operational simplicity with production-grade capabilities (auto-scaling, health probes, secrets management). Infrastructure must be provisioned as code (IaC) for repeatability and auditability.

Key requirements:
- **Containerised workloads**: Docker containers for the backend API
- **Managed scaling**: Auto-scale based on HTTP load without manual cluster management
- **Low operational overhead**: Avoid Kubernetes cluster management for a Modular Monolith
- **Infrastructure as Code**: All Azure resources defined in version-controlled IaC
- **Local development**: Developer experience for running multi-service scenarios locally
- **Azure-native**: Consistent with Azure-first strategy (ADR-001)

Key forces:
- Azure Kubernetes Service (AKS) provides the most control but requires significant ops expertise and cost for a single Modular Monolith container
- Azure Container Apps is a serverless container platform built on Kubernetes internally — provides K8s capabilities without cluster management
- Terraform is the dominant multi-cloud IaC tool with a mature Azure provider (`azurerm`)
- .NET Aspire provides a first-class local development orchestration experience with service discovery and OTel dashboard

## Decision Drivers

- MUST containerise the backend workload with Docker
- MUST auto-scale based on HTTP concurrency/requests
- MUST avoid AKS cluster management complexity for a Modular Monolith
- MUST define all Azure infrastructure as Terraform HCL
- MUST store Terraform remote state in Azure Storage (no local state files)
- MUST scope IaC to workloads only (no Landing Zone / hub-spoke network)
- SHOULD use .NET Aspire for local development orchestration
- SHOULD avoid Bicep in favour of Terraform for multi-tool ecosystem compatibility

## Considered Options

### Option 1: Azure Container Apps + Terraform + .NET Aspire ✅ (Chosen)

Azure Container Apps (ACA) is a serverless container platform that abstracts Kubernetes management. Terraform provisions all Azure resources. .NET Aspire orchestrates local development.

**Azure Container Apps:**
- Serverless: no node pools, no cluster upgrades, no node patching
- Built-in: HTTP scaling (KEDA), Dapr integration, secrets from Key Vault, managed identity, ingress TLS
- Supports Revisions for zero-downtime rolling deployments
- Natively integrates with Azure Container Registry, Key Vault, and Azure Monitor

**Terraform:**
- Declarative HCL with the `azurerm` provider covering all required Azure resources
- Remote state in Azure Storage Account + state locking via Azure Blob leases
- Plan/apply workflow integrates with Azure DevOps Pipelines (ADR-006)
- Reusable modules for Container Apps, SQL, Key Vault, Static Web Apps

**.NET Aspire:**
- Orchestrates local multi-service scenarios (API + SQL + Redis emulator) with a single `dotnet run`
- Built-in OpenTelemetry dashboard for local traces, logs, and metrics (no local Jaeger/Grafana setup)
- `AppHost` project generates Kubernetes/ACA manifests for deployment (Aspire manifest)
- Service discovery via environment variables — same code runs locally and in ACA

**Pros:**
- Eliminates K8s cluster management: no node pools, upgrades, or PodDisruptionBudgets to manage
- ACA scales to zero (cost optimisation for non-production environments)
- Terraform `azurerm` provider is the most complete Azure IaC option with full community support
- .NET Aspire significantly reduces local development friction for multi-service scenarios
- Remote state in Azure Storage prevents state drift and supports team collaboration
- Managed identity eliminates credential management for container-to-Azure-service communication

**Cons:**
- ACA is less flexible than AKS for advanced scenarios (custom ingress controllers, service meshes, custom operators)
- Terraform requires state management discipline (remote state, state locking, workspace hygiene)
- .NET Aspire local orchestration requires .NET 9+ SDK — team must keep SDK updated
- ACA cold-start latency when scaling from zero (mitigated: min-replicas = 1 in production)

### Option 2: Azure Kubernetes Service (AKS) + Helm + Terraform

**Pros:**
- Maximum control over networking, scheduling, and workload isolation
- Full Kubernetes ecosystem (Istio, KEDA, ArgoCD, custom operators)
- Industry-standard for large-scale containerised workloads

**Cons:**
- Significant operational overhead: cluster version upgrades, node pool management, CNI configuration
- Overkill for a single Modular Monolith container that does not need per-module scaling
- Higher baseline cost (node VMs running 24/7 even at low traffic)
- Helm chart management adds another abstraction layer on top of Kubernetes YAML
- Not justified for this project's scale and team size

### Option 3: Azure App Service (Containers) + Terraform

**Pros:**
- Simple PaaS, well-understood by .NET teams
- Built-in deployment slots for blue/green deployments
- No container orchestration concepts required

**Cons:**
- App Service does not scale to zero (always-on pricing)
- Less aligned with the container-first, cloud-native direction
- Less flexible for future multi-container scenarios (sidecars, background workers)
- ACA provides a superset of App Service capabilities for containerised workloads

### Option 4: Azure Container Apps + Bicep

**Pros:**
- Bicep is Azure-native and deeply integrated with Azure Resource Manager
- No state management required (ARM is the state)

**Cons:**
- Bicep is Azure-only — Terraform modules are reusable across providers (e.g., for DNS, GitHub Actions secrets)
- Terraform ecosystem has broader tooling (Checkov, Terratest, Infracost)
- Team preference and community familiarity favour Terraform for multi-cloud-ready IaC
- ARM/Bicep drift detection is weaker than Terraform plan output

## Decision Outcome

**Chosen option: Azure Container Apps + Terraform (remote state in Azure Storage) + .NET Aspire for local dev**

Rationale: Azure Container Apps eliminates K8s cluster management while providing production-grade auto-scaling, managed identity, and ingress. Terraform provides the most complete, reusable, and well-tooled IaC experience for Azure. .NET Aspire dramatically improves local developer experience with built-in OTel dashboard and service discovery. The combination is well-suited to the project's scale, team size, and Azure-first strategy.

### Infrastructure Scope

| Resource | Tool | Notes |
|----------|------|-------|
| Azure Container Apps Environment | Terraform | Shared environment for all ACA apps |
| Azure Container Apps (backend API) | Terraform | Min 1 replica in prod, scales on HTTP |
| Azure Container Registry | Terraform | Private registry for Docker images |
| Azure SQL Database | Terraform | See ADR-003 |
| Azure Static Web Apps | Terraform | See ADR-004 |
| Azure Key Vault | Terraform | Secrets for DB connection strings, API keys |
| Azure Storage Account | Terraform | Terraform remote state backend |
| Azure Log Analytics Workspace | Terraform | OTel → Azure Monitor destination |
| Application Insights | Terraform | Frontend + backend telemetry (ADR-006) |

### Terraform State Strategy

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate<suffix>"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}
```

### Positive Consequences

- No Kubernetes cluster management overhead — ACA handles node provisioning, upgrades, and scaling
- Scale to zero in non-production environments reduces infrastructure cost
- Terraform plan output provides explicit change preview before apply — safe infrastructure changes
- Remote state enables collaborative IaC workflows without state conflicts
- .NET Aspire OTel dashboard provides local observability without running Jaeger, Prometheus, or Grafana locally
- Managed identity for ACA → Azure SQL / Key Vault / Container Registry eliminates stored credentials

### Negative Consequences

- ACA is less flexible than AKS for advanced network topologies (no custom CNI, no pod-level networking)
- Terraform state file contains sensitive outputs — Azure Storage encryption + access control required
- .NET Aspire adds AppHost project to solution — minor solution complexity increase
- ACA cold-start from zero replicas adds latency in non-production environments — acceptable trade-off

## Compliance

- Security: Managed identity, Key Vault secrets, TLS via ACA managed certificates (ADR-006)
- CI/CD: `terraform plan` / `terraform apply` integrated into Azure DevOps Pipelines (ADR-006)
- Observability: Log Analytics Workspace and Application Insights provisioned via Terraform (ADR-006)

## Links

- [Azure Container Apps documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Terraform azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [.NET Aspire documentation](https://learn.microsoft.com/en-us/dotnet/aspire/)
- [Terraform remote state — Azure Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- ADR-001: Backend Technology Stack
- ADR-003: Data Storage and Access Strategy
- ADR-006: CI/CD, Observability, and Security Baseline
