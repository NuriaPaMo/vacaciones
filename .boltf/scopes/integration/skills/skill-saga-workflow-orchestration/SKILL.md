---
name: skill-saga-workflow-orchestration
description: Implement saga patterns and distributed transactions with Azure Durable Functions, Dapr Workflow, Logic Apps, or choreography. Use when implementing multi-step business processes, distributed transactions, compensation logic, or long-running workflows requiring rollback capabilities. Critical for ensuring data consistency across microservices without distributed locks.
---

# Saga & Workflow Orchestration

## When to Use This Skill

Use this skill when your project requires:

- **Multi-step business processes** spanning multiple services (e.g., order fulfillment: reserve inventory → charge payment → ship)
- **Distributed transactions** without two-phase commit (2PC)
- **Compensation logic** for automatic rollback when steps fail mid-process
- **Long-running workflows** (approval processes, human-in-the-loop scenarios lasting hours/days/weeks)
- **Orchestration vs choreography** decision for coordinating microservices

**This skill is critical** because saga pattern choice (orchestration vs choreography) and tooling (Durable Functions, Dapr, Logic Apps, Service Bus) fundamentally affect workflow complexity, monitoring, and operational overhead.

---

## Decision Framework: Orchestration vs Choreography

### Orchestration-Based Saga (Centralized Coordinator)

**Tools**: Azure Durable Functions, Dapr Workflow, Logic Apps Standard

**Best For**:

- Workflows with clear sequential or parallel steps
- Need centralized monitoring and observability
- Human-in-the-loop approvals or wait operations
- Complex compensation logic
- Teams preferring imperative programming

**Pattern**: Central orchestrator (Durable Function, Dapr workflow, Logic App) calls activities/services, handles failures, executes compensations.

**Trade-offs**:

- ✅ Pros: Simple to understand, easy debugging, centralized monitoring, automatic state persistence
- ❌ Cons: Orchestrator knows all services (coupling), potential bottleneck for high-scale scenarios

---

### Choreography-Based Saga (Event-Driven)

**Tools**: Azure Service Bus, Event Hubs, Event Grid

**Best For**:

- Event-driven microservices with autonomous teams
- High scalability requirements (no central bottleneck)
- Services already publish domain events
- Loose coupling between services
- Teams experienced with eventual consistency

**Pattern**: No central coordinator. Each service listens for events, performs actions, publishes new events. Correlation ID tracks saga across services.

**Trade-offs**:

- ✅ Pros: Loose coupling, high scalability, no single point of failure, service autonomy
- ❌ Cons: Hard to monitor (distributed across services), complex debugging, eventual consistency complexity

---

## Orchestration Tool Selection

### Azure Durable Functions

**When to use**: .NET or Node.js applications, need retry policies, fan-out/fan-in patterns, eternal orchestrations.

**Patterns**: Function Chaining, Fan-Out/Fan-In, Human Interaction, Eternal Orchestrations, Monitor

**State Persistence**: Azure Storage (Tables, Blobs), SQL Server, Azure Data Explorer

**See**: `references/code-examples.md` Examples 1-3

---

### Dapr Workflow

**When to use**: Multi-language support (Python, .NET, Java, Go), Kubernetes/Container Apps, modular sub-workflows, need vendor-neutral workflow engine.

**Patterns**: Sequential activities, parallel activities, sub-workflows, external events

**State Persistence**: Configurable state store (Redis, Cosmos DB, SQL Server)

**See**: `references/code-examples.md` Examples 4-5

---

### Logic Apps Standard (Stateful Workflows)

**When to use**: Visual workflow design, built-in connectors (Office 365, Salesforce, SAP), low-code/no-code, long-running approvals (days/weeks).

**Patterns**: Connectors (300+ built-in), approval flows, scheduled triggers, webhook triggers

**State Persistence**: Internal state store (single-tenant Standard plan)

**See**: `references/code-examples.md` Example 6

---

### Service Bus Choreography

**When to use**: Event-driven microservices, need service autonomy, avoid central orchestrator bottleneck.

**Patterns**: Publish/subscribe, message sessions (correlation), dead-letter queues, duplicate detection

**See**: `references/code-examples.md` Example 7

---

## How to Proceed

1. **Assess workflow complexity**: Simple sequential → Orchestration (Durable Functions). Event-driven distributed → Choreography (Service Bus).

2. **Evaluate long-running requirements**: Approvals/waits lasting days/weeks → Logic Apps. Minutes/hours → Durable Functions/Dapr.

3. **Check language/platform**: .NET-heavy → Durable Functions. Multi-language → Dapr. Visual designer needed → Logic Apps.

4. **Review compensation needs**: Complex rollback logic → Orchestration (easier to manage). Simple compensations → Choreography.

5. **Consider monitoring**: Need centralized monitoring → Orchestration. Distributed tracing okay → Choreography.

6. **Review bundled code examples** in `references/code-examples.md` (8 patterns: Function Chaining, Fan-Out/Fan-In, Compensation, Dapr workflows, Logic Apps, Choreography, State Machine).

7. **Consult Microsoft documentation** in `references/microsoft-learn.md` for implementation guidance (Durable Functions, Dapr, Logic Apps, Service Bus).
