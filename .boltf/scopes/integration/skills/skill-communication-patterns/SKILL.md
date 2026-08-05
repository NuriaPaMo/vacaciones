---
name: skill-communication-patterns
description: Choose communication patterns (REST, gRPC, GraphQL, Service Bus, Event Hubs) for synchronous and asynchronous service integration. Use when designing APIs, implementing message brokers, choosing between sync vs async, or building background job processing with Hangfire or BullMQ. Foundational for distributed systems and microservices communication.
---

# Communication Patterns

> **Constitution Articles**: Integration IV §4.1-4.3 (Communication Style, Sync/Async)
> **Bundled Resources**: [Code Examples](references/code-examples.md) • [Microsoft Learn](references/microsoft-learn.md)

## When to Use This Skill

Communication patterns are among the hardest architectural decisions to reverse once your system is built. This skill helps you choose wisely upfront. Use this when:

- **Designing service-to-service communication** - because the sync vs async choice fundamentally affects failure modes, coupling, and how your system handles load
- **Choosing between REST, gRPC, or GraphQL** - because each pattern excels in different scenarios, and migrating an entire API surface later is expensive and risky
- **Implementing message brokers** - because Service Bus, Event Hubs, and Storage Queues solve different problems (commands vs events vs high-throughput streaming)
- **Integrating frontends with backends** - because over-fetching wastes bandwidth and battery on mobile devices, while under-fetching creates latency waterfalls
- **Adding background job processing** - because separating long-running tasks from HTTP request handling improves perceived responsiveness and system reliability
- **Building real-time features** - because polling wastes resources and adds unnecessary latency compared to streaming or push-based patterns

Communication choices ripple through your architecture, affecting latency characteristics, coupling between components, how failures propagate, and developer experience. Understanding the trade-offs prevents accumulating technical debt from mismatched patterns.

## Decision Framework

### Communication Pattern Selection

```text
What type of communication do you need?

┌─ Client ↔ Backend API
│   └─ Who are your clients?
│       ├─ Public web/mobile users
│       │   → REST + OpenAPI (universal browser support, HTTP caching)
│       ├─ Multiple client types with different data needs
│       │   → GraphQL (clients specify exact fields, reduces over-fetching)
│       └─ Internal admin tools
│           → REST (simplicity wins, familiar patterns)
│
├─ Service ↔ Service (Internal)
│   └─ What are your requirements?
│       ├─ High-frequency calls + low latency critical
│       │   → gRPC (binary Protobuf, 5-10x smaller payloads)
│       ├─ Need async decoupling + durability
│       │   → Service Bus (queues/topics, dead-letter handling)
│       ├─ High-throughput event streaming (millions/sec)
│       │   → Event Hubs (distributed log, replay capability)
│       └─ Occasional calls + mixed languages/legacy systems
│           → REST (good enough, widely supported)
│
└─ Background Processing
    └─ What's the workload pattern?
        ├─ Scheduled tasks (daily reports, cleanup jobs)
        │   → Hangfire / Durable Functions (cron-like scheduling)
        ├─ User-initiated long operations (video processing, report generation)
        │   → Background Jobs + Queue (decouples from HTTP request)
        └─ Fire-and-forget commands with retry logic
            → Service Bus Queue (durable, automatic retries)
```

### Scoring Model: Pattern Fit Analysis

This scoring helps evaluate which pattern fits your context. Rate each factor 0-10 (higher = better fit). Use this as a conversation starter with your team about what matters most, not as a rigid calculation:

| Factor                | REST    | gRPC     | GraphQL | Service Bus | Event Hubs |
| --------------------- | ------- | -------- | ------- | ----------- | ---------- |
| Browser compatibility | 10      | 3        | 10      | N/A         | N/A        |
| Latency sensitivity   | 5       | 10       | 5       | 2           | 3          |
| Payload efficiency    | 4       | 10       | 6       | 6           | 6          |
| Coupling tolerance    | 3       | 3        | 5       | 10          | 10         |
| Schema flexibility    | 6       | 4        | 10      | 6           | 6          |
| Throughput ceiling    | 50K RPS | 100K RPS | 30K RPS | 500K msg/s  | Millions/s |

**Example scenario - Mobile app backend:**
REST scores 10 (browser), 5 (latency), 4 (payload) = Acceptable
GraphQL scores 10 (browser), 5 (latency), 6 (payload), 10 (flexibility) = Better fit
gRPC scores 3 (browser) = Poor fit without gRPC-Web complexity

## Core Patterns

### REST APIs

REST's universality makes it the safest default. Every language has HTTP clients, browsers support it natively, and HTTP caching headers reduce server load. OpenAPI/Swagger specifications generate type-safe clients across languages and provide interactive documentation.

REST works well for public-facing APIs, CRUD operations, and browser-based SPAs. However, limitations emerge with high-frequency service-to-service calls where JSON parsing overhead becomes measurable at scale. When clients need different subsets of data (mobile vs desktop), REST either over-fetches (wasting bandwidth) or under-fetches (requiring multiple round trips).

**Why the constitution mandates OpenAPI/Swagger:** Without API contracts, breaking changes reach production silently. OpenAPI enables client code generation, contract testing, and API versioning strategies.

See bundled [REST API implementation examples](references/code-examples.md#rest-api-examples).

### gRPC

gRPC delivers 5-10x smaller payloads through binary Protocol Buffers serialization compared to JSON. The `.proto` schema generates strongly-typed clients in C#, Java, Go, Python, and Node.js, catching breaking changes at compile time. HTTP/2 multiplexing enables bidirectional streaming for scenarios where traditional request-response falls short (real-time telemetry, chat, live updates).

The trade-offs: Browser support requires gRPC-Web middleware (adding complexity and latency), debugging binary payloads is harder than inspecting JSON, and some corporate firewalls/proxies struggle with HTTP/2. Use gRPC for internal service meshes where performance matters and you control both ends; prefer REST for public APIs where universality wins.

**Why the constitution mandates gRPC internally:** JSON parsing consumes measurable CPU at scale. In microservices with thousands of internal calls per second, gRPC's binary efficiency translates directly to infrastructure cost savings.

See bundled [gRPC service examples](references/code-examples.md#grpc-examples).

### GraphQL

GraphQL solves the over-fetching/under-fetching problem by letting clients specify exactly which fields they need. A single `/graphql` endpoint aggregates data from multiple backend services. Mobile apps benefit most - they request only required fields over bandwidth-constrained networks, reducing both latency and data usage.

The trade-offs: Complexity compared to REST for simple CRUD, HTTP caching semantics don't apply (everything is POST to `/graphql`), and backends need resolver logic for every field. Query complexity limits (nested depth, cost analysis) prevent abuse scenarios where clients request deeply nested data graphs.

**Why the constitution mandates HotChocolate:** It provides first-class .NET integration, automatic schema generation from C# types, and built-in DataLoader patterns to prevent N+1 query problems.

See bundled [GraphQL implementation examples](references/code-examples.md#graphql-examples).

### Azure Service Bus

Service Bus provides durable message queues and pub/sub topics. Queues deliver point-to-point commands (exactly one consumer processes each message), while topics broadcast events to multiple subscribers. Built-in features include sessions for FIFO ordering, dead-letter queues for poison messages, duplicate detection for idempotency, and transactional sends.

Use Service Bus when you need to decouple sender from receiver, implement distributed workflows with compensation (saga patterns), or guarantee reliable async processing with automatic retries. Typical latency is 50-200ms per message. Throughput scales to hundreds of thousands of messages per second per namespace.

**Why messaging decouples:** When Order Service sends an order via Service Bus, it doesn't care if Inventory Service or Shipping Service are temporarily down. Messages wait in queues until consumers are ready, preventing cascading failures.

See bundled [Service Bus patterns](references/code-examples.md#service-bus-examples).

### Azure Event Hubs

Event Hubs provides distributed streaming logs with partitions enabling parallel consumption. Designed for telemetry ingestion at massive scale (millions of events per second), event sourcing persistence (append-only log with replay), and real-time analytics pipelines.

Event Hubs differs from Service Bus: no message deletion (retention-based like Kafka), ordering guaranteed only per partition (not globally), no dead-letter queue (failed processing requires custom handling), optimized for throughput over latency. Checkpointing in Azure Storage tracks consumer progress for resuming after failures.

Use Event Hubs for IoT telemetry from millions of devices, event sourcing event stores (immutable log), and streaming data to analytics systems (Stream Analytics, Databricks). Typical latency is 100-500ms, acceptable when trading latency for extreme throughput.

**Why Event Hubs for event sourcing:** The ability to replay events from any point in time enables rebuilding read models, debugging production issues by replaying events, and creating new projections from historical data.

See bundled [Event Hubs streaming examples](references/code-examples.md#event-hubs-examples).

### Background Jobs

Background jobs separate long-running operations from HTTP requests, improving perceived responsiveness and reliability (jobs persist through app restarts). Hangfire (for .NET monoliths) and Azure Durable Functions (serverless) provide persistent job tracking, automatic retries with exponential backoff, and cron-style scheduling.

Typical patterns: scheduled tasks (daily reports, cleanup jobs), fire-and-forget operations (send email after user registration), delayed execution (reminder notifications after 1 hour), and workflow orchestration (multi-step processes with compensation).

**Why background jobs matter:** When a user uploads a video, processing shouldn't block the HTTP request. Queue the job, return 202 Accepted immediately, and process asynchronously while the user continues using your app.

See bundled [background job patterns](references/code-examples.md#background-jobs-examples).

## Pattern Combinations

Modern architectures combine patterns appropriately rather than forcing one pattern everywhere. Example e-commerce platform:

- **REST API** - Public product catalog (universal client support, HTTP caching)
- **gRPC** - Internal inventory/pricing services (high-frequency, low-latency)
- **GraphQL** - Mobile app BFF (flexible queries reduce bandwidth)
- **Service Bus** - Order commands and fulfillment events (reliability, decoupling)
- **Event Hubs** - User behavior telemetry streaming to analytics (scale)
- **Hangfire** - Daily sales reports and abandoned cart cleanup (scheduling)

Don't force one pattern for all communication. Match the pattern to each specific use case.

## Quick Reference

| Need                    | Pattern          | Why                                                    |
| ----------------------- | ---------------- | ------------------------------------------------------ |
| Public API              | REST + OpenAPI   | Universal compatibility, HTTP caching, API contracts   |
| Internal high-frequency | gRPC             | Binary efficiency (5-10x smaller), compile-time safety |
| Flexible client queries | GraphQL          | Client specifies fields, reduces over-fetching         |
| Decouple services       | Service Bus      | Async + durability + dead-letter handling              |
| High-volume telemetry   | Event Hubs       | Distributed log, millions/sec, replay                  |
| Scheduled tasks         | Hangfire/Durable | Persistent jobs, cron scheduling, retries              |

## Common Anti-Patterns

**Polling when push available** - Wastes resources checking for updates. Use Event Hubs, SignalR, or Server-Sent Events for real-time push.

**Synchronous chains (A→B→C→D)** - Creates cascading failures when any service is slow. Use messaging to decouple and add retry logic.

**Large payloads over REST** - JSON parsing overhead grows with payload size. Consider gRPC's binary efficiency or chunked uploads for large files.

**GraphQL for everything** - Overkill for internal backend-to-backend communication. REST or gRPC are simpler and faster when there's no flexible query requirement.

**One pattern for all** - This is normal and expected. Mixing patterns based on use case is better than forcing uniformity.

## Bundled Resources

This skill includes supplemental resources with complete, production-ready implementations:

- **[Code Examples](references/code-examples.md)** - Full implementations for REST, gRPC, GraphQL, Service Bus, Event Hubs, background jobs in C#/.NET and TypeScript/Node.js
- **[Microsoft Learn Resources](references/microsoft-learn.md)** - Curated official documentation, best practices guides, tutorials, and architecture patterns

These resources provide copy-paste starting points aligned with constitution mandates. Reference them when implementing your chosen communication pattern.
