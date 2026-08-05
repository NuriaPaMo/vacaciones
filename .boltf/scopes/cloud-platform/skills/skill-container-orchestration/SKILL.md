---
name: skill-container-orchestration
description: Choose container orchestration platform (AKS, Azure Container Apps, App Service) and configuration tool (Helm, Kustomize, KEDA, Dapr) for containerized workloads. Use when deploying containers to Azure, deciding Kubernetes vs serverless containers, implementing autoscaling, or configuring cloud-native patterns. Critical decision affecting operational complexity and cost.
---

# Container Orchestration Selection

---

## When to Use This Skill

Use this skill when you are:

1. **Selecting a container orchestration platform for a new microservices application** — because choosing between AKS, Container Apps, and local development tooling depends on application complexity, operational requirements, and whether you need full Kubernetes control or serverless simplicity, and this decision affects deployment workflows, scaling strategies, and operational overhead.

2. **Deciding between Azure Kubernetes Service (AKS) and Azure Container Apps for cloud deployment** — because AKS provides full Kubernetes control suitable for complex microservices architectures with advanced networking and service mesh requirements, while Container Apps offers serverless simplicity for event-driven applications that benefit from Dapr integration and scale-to-zero capabilities, and understanding these trade-offs prevents over-engineering or under-resourcing.

3. **Designing a local development environment for multi-container applications** — because Docker Compose provides simple YAML-based orchestration for local development with hot-reload and service dependencies, while more complex scenarios may require local Kubernetes clusters (Kind, Minikube) that mirror production AKS environments, and choosing the right local orchestration tool impacts developer experience and environment parity.

4. **Implementing a deployment strategy for containerized applications using Helm or Kustomize** — because Helm provides templated package management with versioned charts and dependency management suitable for reusable deployments, while Kustomize offers template-free configuration management with environment-specific overlays that preserve base YAML readability, and selecting the right tool affects deployment complexity and configuration maintainability.

5. **Architecting a scaling strategy for containerized microservices** — because different orchestration platforms support different autoscaling mechanisms (AKS with HPA and cluster autoscaler, Container Apps with KEDA event-driven rules, Kubernetes-native scaling) that affect cost, performance, and responsiveness to traffic patterns, and understanding these mechanisms guides infrastructure design and capacity planning.

6. **Evaluating service mesh integration for advanced networking requirements** — because service meshes like Istio or Linkerd on AKS provide traffic management, observability, and security features (mutual TLS, circuit breaking, distributed tracing) that are essential for complex microservices architectures but add operational complexity, and determining when service mesh benefits outweigh costs prevents premature optimization.

7. **Migrating from on-premises containers or legacy orchestration to Azure cloud-native platforms** — because migration strategies vary based on source platform (Docker Swarm, on-prem Kubernetes, VM-based containers) and target Azure services (lift-and-shift to AKS vs. refactor to Container Apps), and understanding migration paths and modernization opportunities ensures smooth transitions with minimal disruption.

---

## Decision Framework: Selecting Container Orchestration

Choosing the right container orchestration platform depends on your application architecture, operational requirements, team expertise, and cloud-native goals. Use this framework to guide your selection:

```text
┌─────────────────────────────────────────────────────────┐
│ What's your container orchestration need?              │
└─────────────────────────────────────────────────────────┘
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
       ▼                   ▼                   ▼
   Simple           Complex              Local
   Microservices    Microservices        Development
   No K8s expertise Full K8s control      Multi-container
       │                   │                   │
       ▼                   ▼                   ▼
   Azure               Azure                Docker
   Container Apps      Kubernetes           Compose
   • Serverless        Service (AKS)        • YAML-based
   • Dapr integration  • Service mesh       • Hot-reload
   • Event-driven      • Advanced network   • Dev-only
   • Scale-to-zero     • RBAC + policies    • Fast iteration
   • Simplified ops    • Full ecosystem

       │                   │
       │                   │
       ▼                   ▼
   Need package        Need environment
   management?         overlays?
       │                   │
       Yes                 Yes
       │                   │
       ▼                   ▼
   Helm                Kustomize
   • Templated charts  • Template-free
   • Versioning        • Overlays
   • Reusability       • Base + patches
   • Dependencies      • Native K8s
```

**Key Questions to Guide Selection**:

- Do you need full Kubernetes control or prefer serverless simplicity? (AKS vs. Container Apps)
- Is your team experienced with Kubernetes operations? (Affects learning curve)
- Do you require service mesh capabilities (Istio, Linkerd)? (AKS advantage)
- Do you need event-driven autoscaling or scale-to-zero? (Container Apps strength)
- Is local development parity with production critical? (Docker Compose + AKS vs. Container Apps emulation)
- Do you want reusable deployment templates or environment-specific overlays? (Helm vs. Kustomize)

---

## Scoring Model: Container Orchestration Comparison

| Orchestration Platform             | Complexity | Cost        | Scaling             | Operations    | Ecosystem  | Control        |
| ---------------------------------- | ---------- | ----------- | ------------------- | ------------- | ---------- | -------------- |
| **Azure Kubernetes Service (AKS)** | High       | Medium      | Advanced (HPA, CA)  | High overhead | Rich       | Full           |
| **Azure Container Apps**           | Low        | Low-Med     | Event-driven (KEDA) | Minimal       | Growing    | Limited        |
| **Docker Compose**                 | Very Low   | Free        | None                | Dev-only      | Basic      | Local-only     |
| **Helm (on AKS)**                  | Medium     | Same as AKS | Inherits AKS        | Medium        | Very Rich  | Template-based |
| **Kustomize (on AKS)**             | Low-Med    | Same as AKS | Inherits AKS        | Low-Med       | Native K8s | Overlay-based  |

**Note**: This comparison is a conversation starter, not a rigid calculation. Context matters—**AKS** suits complex microservices needing full Kubernetes control and service mesh, **Container Apps** fits serverless event-driven scenarios with simplified operations, **Docker Compose** excels for local development, **Helm** provides templated package management, and **Kustomize** offers template-free configuration overlays.

---

## Orchestration Platforms Explained

### Azure Kubernetes Service (AKS)

**What it enables**: Full-featured managed Kubernetes for complex microservices architectures requiring advanced networking, service mesh integration, granular RBAC, and complete control over cluster configuration.

**When it fits**:

- Complex microservices architectures with multiple teams and services
- Requirements for service mesh (Istio, Linkerd) for traffic management and observability
- Advanced networking needs (network policies, custom CNI, multiple node pools)
- Enterprise-grade requirements (strict RBAC, Azure Policy integration, compliance)
- Team has Kubernetes expertise or invests in learning curve

**Key characteristics**:

- **Full Kubernetes API**: Complete access to Kubernetes primitives (Deployments, StatefulSets, DaemonSets, Jobs).
- **Service Mesh Support**: Native integration with Istio, Linkerd for mutual TLS, circuit breaking, distributed tracing.
- **Advanced Networking**: Azure CNI, network policies, multiple ingress controllers (NGINX, Application Gateway).
- **Rich Ecosystem**: Helm charts, Operators, extensive CNCF tooling (Prometheus, Grafana, Fluentd).
- **Granular Control**: Custom node pools, spot instances, GPU nodes, Windows containers, hybrid deployments.
- **Operational Complexity**: Requires Kubernetes expertise, cluster upgrades, node pool management, higher operational overhead.

**Operational considerations**: Requires managing cluster lifecycle (upgrades, node pool scaling), monitoring (Prometheus, Container Insights), security (network policies, pod security standards), and cost optimization (spot nodes, autoscaling). Suitable when control and flexibility outweigh operational complexity.

---

### Azure Container Apps

**What it enables**: Serverless container platform with simplified operations, Dapr integration, event-driven autoscaling, and scale-to-zero capabilities for microservices that don't require full Kubernetes control.

**When it fits**:

- Simple to moderate microservices architectures prioritizing developer productivity
- Event-driven applications (HTTP, queues, timers, custom KEDA scalers)
- Applications benefiting from Dapr's building blocks (pub/sub, state management, service invocation)
- Teams wanting serverless model with automatic scaling and minimal infrastructure management
- Cost-sensitive workloads leveraging scale-to-zero during idle periods

**Key characteristics**:

- **Serverless Model**: No cluster management, automatic scaling, pay-per-use consumption model.
- **Dapr Integration**: Built-in Dapr sidecar for microservices patterns (pub/sub, state stores, service mesh).
- **Event-Driven Autoscaling**: KEDA-powered scaling rules (HTTP, queues, cron, custom metrics) with scale-to-zero.
- **Simplified Networking**: Managed ingress, automatic service discovery, built-in load balancing.
- **Revisions & Traffic Splitting**: Blue-green deployments, canary releases, traffic management without additional tooling.
- **Limited Control**: No access to underlying Kubernetes, constrained customization compared to AKS.

**Operational considerations**: Ideal for teams wanting to focus on application code rather than infrastructure. Limited customization (no custom ingress controllers, no privileged containers, no direct Kubernetes API access). Suitable when simplicity and rapid deployment outweigh need for Kubernetes control.

---

### Docker Compose

**What it enables**: YAML-based multi-container orchestration for local development environments, providing simple service definitions, dependency management, and hot-reload workflows.

**When it fits**:

- Local development requiring multiple services (app, database, cache, message queue)
- Integration testing with ephemeral container stacks
- Quick prototyping and experimentation with multi-container architectures
- Teams needing fast inner-loop development without Kubernetes complexity

**Key characteristics**:

- **YAML Simplicity**: Single file defining services, networks, volumes with minimal configuration.
- **Fast Iteration**: Quick startup, hot-reload, easy debugging with `docker-compose up` and `logs`.
- **Service Dependencies**: `depends_on` directive ensures correct startup order.
- **Environment Parity**: Mirrors production multi-container setups locally (within Docker Compose constraints).
- **Dev-Only**: Not suitable for production; lacks high availability, scaling, health checks, advanced networking.

**Operational considerations**: Excellent for local development but not for production. Use Docker Compose for inner-loop development, then deploy to AKS or Container Apps for production environments. Bridge gap with local Kubernetes (Kind, Minikube) if production parity is critical.

---

### Helm

**What it enables**: Kubernetes package manager providing templated charts for reusable deployments, versioning, and dependency management across environments.

**When it fits**:

- Deploying complex applications with multiple Kubernetes resources (Deployments, Services, Ingress, ConfigMaps)
- Reusable templates across multiple environments (dev, staging, production) with values files
- Managing application versions and rollback capabilities
- Leveraging community charts from Artifact Hub for common services (databases, monitoring)

**Key characteristics**:

- **Templated Charts**: Go templates generating Kubernetes YAML from values, enabling reusability and parameterization.
- **Versioning & Rollback**: Helm releases track deployment history, enabling easy rollback to previous versions.
- **Dependency Management**: Charts can depend on other charts (e.g., web app depends on PostgreSQL chart).
- **Community Ecosystem**: Artifact Hub hosts thousands of pre-built charts for common services.
- **Learning Curve**: Requires understanding Helm templating syntax, values precedence, and release management.

**Operational considerations**: Powerful for complex deployments but adds templating layer over Kubernetes YAML. Best when reusability and versioning outweigh template complexity. Use Helm for application packaging; use Kustomize for environment-specific configuration.

---

### Kustomize

**What it enables**: Native Kubernetes configuration management using overlay pattern, allowing environment-specific modifications without templating.

**When it fits**:

- Managing Kubernetes YAML across environments (dev, staging, production) with minimal duplication
- Preserving base YAML readability without introducing template syntax
- Teams preferring declarative patches over templating
- Native integration with `kubectl apply -k` without additional tooling

**Key characteristics**:

- **Template-Free**: Uses YAML-native patching (strategic merge, JSON patch) instead of templating language.
- **Base + Overlays**: Define base resources once, apply environment-specific patches (replicas, images, resources).
- **Kubectl Integration**: Built into kubectl (`kubectl apply -k`), no separate tool installation required.
- **Composability**: Multiple overlays can reference same base, enabling multi-environment deployments from single source.
- **Learning Curve**: Simpler than Helm for teams familiar with Kubernetes YAML, steeper for complex patching logic.

**Operational considerations**: Best for environment-specific configuration management without templating complexity. Combine Kustomize overlays with Helm for complex applications (Helm for templating, Kustomize for environment customization).

---

## Container Patterns

**Sidecar Pattern**: Helper container runs alongside main application container in same pod (e.g., logging agent, service mesh proxy, configuration watcher). Sidecar shares pod lifecycle, network namespace, and volumes with main container.

**Ambassador Pattern**: Proxy container simplifies connectivity to external services (e.g., database proxy, API gateway, protocol translation). Application connects to localhost, ambassador handles external routing.

**Adapter Pattern**: Container transforms application output to standardized format (e.g., log formatting, metrics normalization). Adapter decouples application from external systems' expected formats.

**Init Containers**: Containers run to completion before application containers start (e.g., database migrations, configuration setup, secret fetching). Ensures prerequisites are met before application launch.

---

## Scaling Strategies

**Horizontal Pod Autoscaler (HPA)** on AKS: Automatically scales pod replicas based on CPU, memory, or custom metrics. Configure target utilization percentages; HPA adjusts replicas to maintain targets. Requires metrics-server installed in cluster.

**Cluster Autoscaler** on AKS: Automatically scales AKS node pools when pods can't be scheduled due to resource constraints. Adds nodes when pending pods exist, removes nodes when underutilized. Configure min/max node counts per node pool.

**KEDA Event-Driven Autoscaling** on AKS: Scales deployments based on external event sources (Azure Service Bus, Storage Queues, Kafka, custom metrics). KEDA bridges event sources to HPA, enabling scale-to-zero.

**Container Apps Autoscaling Rules**: Built-in KEDA integration with HTTP traffic rules, queue length rules, cron rules, and custom scalers. Configure scale-to-zero for cost optimization during idle periods.

---

## Networking Patterns

**Service Mesh** (Istio, Linkerd on AKS): Provides traffic management (canary deployments, circuit breaking, retries), observability (distributed tracing, metrics), and security (mutual TLS, authorization policies). Adds operational complexity but essential for complex microservices requiring advanced networking.

**Ingress Controllers** (NGINX, Application Gateway on AKS): Route external HTTP/HTTPS traffic to services within cluster. Application Gateway Ingress Controller integrates with Azure Application Gateway for WAF, SSL termination, and Azure-native features.

**Container Apps Ingress**: Managed ingress with automatic HTTPS, custom domains, traffic splitting for blue-green/canary deployments. No manual ingress controller configuration required.

**Service Discovery**: Kubernetes services provide DNS-based discovery (service-name.namespace.svc.cluster.local). Container Apps use Dapr service invocation or direct HTTP calls via internal ingress.

---

## Quick Reference: Orchestration Selection

| Scenario                            | Recommended Orchestration | Reason                                                |
| ----------------------------------- | ------------------------- | ----------------------------------------------------- |
| Complex microservices, service mesh | AKS                       | Full Kubernetes control, Istio/Linkerd support        |
| Event-driven, scale-to-zero         | Azure Container Apps      | KEDA autoscaling, serverless cost model               |
| Local development                   | Docker Compose            | Fast iteration, simple YAML, hot-reload               |
| Reusable deployment templates       | Helm (on AKS)             | Templated charts, versioning, community ecosystem     |
| Environment-specific config         | Kustomize (on AKS)        | Template-free overlays, native kubectl integration    |
| Simple microservices, Dapr          | Azure Container Apps      | Built-in Dapr, simplified operations, managed ingress |
| GPU workloads, Windows containers   | AKS                       | Node pool customization, specialized hardware support |
| CI/CD packaging                     | Helm                      | Versioned releases, rollback capabilities             |

---

## Common Pitfalls

**Over-engineering with Kubernetes when Container Apps suffices**: Choosing AKS for simple microservices adds operational complexity without benefit. Evaluate whether you need full Kubernetes control or prefer serverless simplicity. Use Container Apps unless you require service mesh, custom ingress controllers, or specialized node pools.

**Missing resource limits and requests in Kubernetes manifests**: Pods without resource limits can starve other workloads; pods without requests prevent effective scheduling and autoscaling. Always define CPU and memory limits/requests. Use `LimitRange` and `ResourceQuota` for namespace-level constraints.

**Ignoring health checks (liveness, readiness, startup probes)**: Missing probes cause traffic routing to unhealthy pods and unnecessary pod restarts. Configure readiness probes (removes pod from service endpoints when unhealthy), liveness probes (restarts pod when unhealthy), and startup probes (delays health checks during slow startup).

**Using Docker Compose in production**: Docker Compose lacks high availability, orchestration, scaling, and health checks needed for production. Use Compose for local development only; deploy to AKS or Container Apps for production environments.

**Inconsistent configuration across environments**: Hardcoded values in Kubernetes YAML lead to configuration drift. Use Helm values files or Kustomize overlays for environment-specific configuration. Store secrets in Azure Key Vault, not in YAML or environment variables.

**Not leveraging scale-to-zero in Container Apps**: Paying for idle containers wastes budget. Configure scale-to-zero for workloads with intermittent traffic (webhooks, scheduled jobs, dev environments). Set `minReplicas: 0` in scaling rules.

**Premature service mesh adoption**: Service mesh adds significant operational complexity (sidecar overhead, configuration management, learning curve). Adopt service mesh when you need advanced traffic management, mutual TLS, or distributed tracing across dozens of services, not for simple architectures.

---

## Bundled Resources

This skill references:

- **[references/code-examples.md](references/code-examples.md)**: AKS Kubernetes YAML deployments, Container Apps Bicep templates, Docker Compose stacks, Helm charts, Kustomize overlays, service mesh integration, multi-container patterns, and sidecar examples demonstrating container orchestration across platforms.
- **[references/microsoft-learn.md](references/microsoft-learn.md)**: Curated documentation for AKS (networking, security, best practices), Azure Container Apps (Dapr integration, autoscaling, ingress), Kubernetes fundamentals (pods, deployments, services, storage), Helm (chart development, best practices), Docker Compose, monitoring, CI/CD, and migration strategies with official Microsoft Learn resources and reference architectures.
