---
name: skill-architecture-patterns
description: ALWAYS use when choosing backend architecture (microservices, modular monolith, serverless, event-driven) OR frontend architecture (micro-frontends, SPA, SSR, SSG). Triggers: architecture style, microservices vs monolith, modular monolith, serverless architecture, architecture patterns, service boundaries, deployment strategy, team organization, event-driven architecture, CQRS architecture, architecture decision, choose architecture, architecture comparison, micro-frontends, SPA vs SSR, architecture trade-offs, when to use microservices, monolith to microservices. This skill is MANDATORY for Article III (Backend/Frontend Architecture) decisions.
---

# Architecture Patterns Selection

> **Constitution Articles**: Backend III §3.1, Frontend III §3.2
> **Bundled Resources**: See `references/code-examples.md` for complete implementations, `references/microsoft-learn.md` for documentation

## When to Use This Skill

This skill helps you make architecture decisions that are difficult to reverse later. Understanding the trade-offs between patterns early prevents costly refactoring down the road. Use this skill when:

- Deciding on **backend architecture style** (Article III §3.1) - because the choice between monolith, microservices, or serverless affects your entire codebase structure
- Deciding on **frontend architecture style** (Article III §3.2) - because frontend architecture impacts team autonomy and deployment flexibility
- Evaluating microservices vs monolithic approaches - because this decision impacts team organization, operational complexity, and scaling patterns
- Planning migration from monolith to distributed systems - because understanding migration patterns reduces risk
- Choosing deployment topology and service boundaries - because these choices affect system resilience and team velocity
- Aligning architecture with team organization and scale requirements - because Conway's Law means your architecture tends to mirror your team structure

## Decision Framework

### Backend Architecture Decision Tree

```text
START → What is your team size and organizational structure?
│
├─ Small team (1-5 developers) OR tight coupling acceptable
│  └─→ What are your scaling requirements?
│      ├─ Low to moderate scale → **Modular Monolith**
│      ├─ Event-driven workloads → **Event-Driven Monolith**
│      └─ Unpredictable, bursty traffic → **Serverless**
│
└─ Multiple teams OR need independent deployment
   └─→ What is your deployment frequency?
       ├─ Frequent deployments per team → **Microservices**
       ├─ Mixed scale requirements → **Hybrid (Modular Monolith + Microservices)**
       └─ Short-lived tasks, background processing → **Serverless Functions**
```

### Scoring Model

The scoring model helps you evaluate which pattern best fits your context. Each factor is rated 0-10, where higher scores indicate a better fit for that pattern. Rather than rigidly following the highest total score, use this as a conversation starter with your team about what matters most:

| Factor                      | Microservices      | Modular Monolith | Serverless         | Event-Driven        |
| --------------------------- | ------------------ | ---------------- | ------------------ | ------------------- |
| **Team Size**               | >5 teams (10)      | 1-2 teams (10)   | Any (8)            | 2+ teams (8)        |
| **Deployment Independence** | Critical (10)      | Shared (3)       | Per-function (10)  | Per-service (9)     |
| **Scale Requirements**      | Heterogeneous (10) | Homogeneous (7)  | Unpredictable (10) | High throughput (9) |
| **Complexity Tolerance**    | High (4)           | Low (9)          | Medium (7)         | Medium (6)          |
| **Latency Sensitivity**     | Low (6)            | Very Low (10)    | Medium (6)         | Low-Medium (7)      |
| **Data Consistency**        | Eventual (6)       | Strong (10)      | Eventual (5)       | Eventual (8)        |

**Why this matters**: Different patterns excel in different contexts. Microservices shine when you need deployment independence but require operational maturity. Modular monoliths offer simplicity for smaller teams while maintaining clear boundaries for future evolution. Serverless optimizes for unpredictable workloads and cost efficiency. Event-driven architectures handle high throughput but introduce eventual consistency challenges.

Calculate your total score for each pattern, then discuss the results with your team, weighing factors by their importance to your specific context.

## Architecture Patterns Overview

> **For complete code examples**, read `references/code-examples.md`
> **For Microsoft Learn documentation**, read `references/microsoft-learn.md`

### 1. Modular Monolith

**What it is**: Single deployment unit with clear internal module boundaries, each representing a bounded context or subdomain.

**When to use**:

- Single team or small multiple teams (~3-10 developers)
- Strong consistency requirements
- Shared domain logic across modules
- Simpler deployment and debugging needs
- Lower operational complexity

**Key characteristics**:

- One process, one codebase
- Modules communicate via in-process calls
- Single database or logically separated schemas
- Scales horizontally by cloning entire app
- Can evolve to microservices incrementally

**Azure service mapping**:

- Azure App Service (Web Apps)
- Azure Container Apps (single container)
- Azure Kubernetes Service (single deployment)

> See `references/code-examples.md` for C#/.NET and Node.js/TypeScript project structures

---

### 2. Microservices

**What it is**: Distributed system where each service is independently deployable, owns its data, and communicates over the network.

**When to use**:

- Multiple autonomous teams (>5 teams)
- Need independent deployment and scaling per service
- Polyglot technology requirements (different languages/databases per service)
- Heterogeneous scale patterns (e.g., catalog service scales 10x more than checkout)
- High maturity in DevOps, observability, and distributed systems

**Key characteristics**:

- Multiple processes, multiple codebases
- Each service owns its database (database-per-service pattern)
- Network communication (REST, gRPC, messaging)
- Independent deployment lifecycle
- Requires API gateway, service discovery, distributed tracing

**Azure service mapping**:

- Azure Kubernetes Service (AKS) with service mesh (Dapr, Linkerd)
- Azure Container Apps with Dapr
- Azure Service Fabric
- Azure API Management (API Gateway)
- Azure Service Bus / Event Hubs (inter-service messaging)

> See `references/code-examples.md` for C#/.NET and Node.js/TypeScript microservices implementations with Service Bus integration

---

### 3. Serverless

**What it is**: Event-driven, fully managed compute where you write stateless functions triggered by events (HTTP, queue, timer, blob changes).

**When to use**:

- Unpredictable, bursty traffic (zero to thousands of requests)
- Background processing tasks (image resizing, email sending, data transformations)
- Event-driven workflows (file uploads, database changes, scheduled jobs)
- Cost optimization (pay-per-execution, auto-scale to zero)
- Prototyping and MVPs with minimal infrastructure

**Key characteristics**:

- Stateless functions (ephemeral compute)
- Event-driven triggers (HTTP, queue, timer, blob, etc.)
- Auto-scaling (including scale-to-zero)
- Pay-per-execution billing
- Limited execution time (default 5 min, max 10 min for Consumption plan)

**Azure service mapping**:

- Azure Functions (Consumption, Premium, or Flex Consumption plans)
- Azure Event Grid (event routing)
- Azure Logic Apps (low-code workflows)
- Azure Durable Functions (stateful workflows)

> See `references/code-examples.md` for C#/.NET and Node.js/TypeScript Azure Functions with HTTP, Queue, Timer, and Blob triggers

---

### 4. Event-Driven Architecture (EDA)

**What it is**: Asynchronous communication pattern where services publish domain events to a message broker, and other services subscribe to react.

**When to use**:

- High throughput requirements (thousands of events per second)
- Need temporal decoupling (producer and consumer don't run at same time)
- Event sourcing requirements (audit trail, replay capability)
- Workflows spanning multiple services (saga pattern)
- Real-time data streaming (IoT, analytics pipelines)

**Key characteristics**:

- Asynchronous, message-driven communication
- Publishers and subscribers are decoupled
- Events represent facts (immutable, past tense)
- Requires message broker (Service Bus, Event Hubs, Kafka)
- Eventual consistency

**Azure service mapping**:

- Azure Service Bus (enterprise messaging, sessions, dead-letter queues)
- Azure Event Hubs (high-throughput streaming, Kafka-compatible)
- Azure Event Grid (event routing, serverless integration)

> See `references/code-examples.md` for C#/.NET and Node.js/TypeScript publisher-subscriber patterns with Azure Service Bus

---

## Frontend Architecture Patterns

### 1. Single Page Application (SPA)

**When to use**: Rich, interactive user experience, mobile-like responsiveness in browser, frequent client-side state updates, API-driven backend

**Technology stack**: React, Angular, Vue.js, Azure Static Web Apps, Azure App Service, Azure CDN for global distribution

---

### 2. Micro-Frontends

**When to use**: Multiple frontend teams working independently, different parts of UI evolve at different rates, technology diversity needed (React + Vue in same app)

**Implementation patterns**: Webpack Module Federation, iFrames (for legacy integration), Web Components

---

### 3. Server-Side Rendering (SSR)

**When to use**: SEO critical (e-commerce, blogs), time-to-first-byte matters, lower-powered client devices

**Technology stack**: Next.js (React), Nuxt.js (Vue), Angular Universal, Azure App Service, Azure Container Apps

---

## Migration Paths

### From Monolith to Microservices

**Strangler Fig Pattern**:

1. Identify bounded context to extract (e.g., "Catalog")
2. Create new microservice with same API contract
3. Use API Gateway to route % of traffic to new service
4. Gradually increase traffic percentage (10% → 50% → 100%)
5. Decommission monolith module once fully strangled

> See `references/code-examples.md` for Azure API Management routing policy example

---

## How to Proceed

**Start by understanding your constraints and goals**: Team size, deployment frequency, consistency requirements, and operational maturity all influence which pattern fits best. The decision tree and scoring model above help frame the conversation, but real-world architecture decisions often involve hybrid approaches.

**Recommended workflow**:

1. **Evaluate your context** using the scoring model above - this helps identify non-negotiable requirements and potential red flags
2. **Review pattern details** - read this skill for overview, then `references/code-examples.md` for concrete implementations in your tech stack
3. **Consult Microsoft Learn** - `references/microsoft-learn.md` contains authoritative documentation, reference architectures (eShopOnContainers, eShopOnWeb), and cloud design patterns
4. **Consider evolution paths** - starting with a modular monolith and evolving to microservices is often safer than building microservices prematurely. The Strangler Fig pattern enables incremental migration.
5. **Start implementation** - use code examples as templates for your project structure. Remember: architecture decisions should enable your team to deliver value, not constrain them with unnecessary complexity.

---

## References

### Bundled Resources (Read These for Details)

- `references/code-examples.md` - Complete C#/.NET and Node.js/TypeScript implementations
- `references/microsoft-learn.md` - Curated Microsoft Learn documentation

### Quick Links

- [Microservices architecture style](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/microservices)
- [Common web application architectures](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)
- [eShopOnContainers (Microservices)](https://github.com/dotnet-architecture/eShopOnContainers)
- [eShopOnWeb (Modular Monolith)](https://github.com/dotnet-architecture/eShopOnWeb)
