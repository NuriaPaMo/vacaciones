---
name: skill-event-driven-architecture
description: Implement event-driven patterns with Azure messaging services (Service Bus, Event Hubs, Event Grid, Cosmos DB Change Feed). Use when choosing between queue vs pub/sub vs streaming, implementing event sourcing or CQRS, handling distributed transactions with saga, ensuring message delivery guarantees, or implementing dead-letter queues and idempotency. Fundamental for distributed systems and microservices.
---

# Event-Driven Architecture

## When to Use This Skill

Use this skill when designing **asynchronous, loosely-coupled systems** with messaging or events, because synchronous coupling creates bottlenecks and tight dependencies:

- **Decoupling microservices with asynchronous communication** → Services don't wait for each other (higher availability, independent scaling)
- **Choosing between Event Hubs, Service Bus, and Event Grid** → Each has different guarantees (throughput vs ordering vs routing); wrong choice causes performance or reliability issues
- **Implementing event sourcing and CQRS patterns** → Immutable event log enables time travel, audit trails, and separate read/write models
- **Handling distributed transactions with saga pattern** → Microservices can't use two-phase commit; sagas coordinate with compensating transactions
- **Scaling message processing with competing consumers** → Multiple instances process queue in parallel (horizontal scalability)
- **Reacting to system events (blob created, database change)** → Event Grid routes Azure resource events to functions, webhooks, or services
- **Guaranteeing message delivery and ordering** → At-least-once vs exactly-once vs FIFO tradeoffs depend on platform and pattern

## Decision Framework

```text
What's your event-driven need?

├─ High-throughput streaming (millions events/sec, telemetry)?
│  └─ Event Hubs (partitioned, checkpointing, Kafka-compatible)
│
├─ Reliable messaging with queues (FIFO, dead-letter)?
│  ├─ Point-to-point (single consumer)?
│  │  └─ Service Bus Queue (sessions for ordered processing)
│  └─ Pub/sub (multiple consumers)?
│     └─ Service Bus Topic (subscriptions with filters)
│
├─ Reactive event routing (Azure resource events)?
│  └─ Event Grid (domains: storage, cosmos, custom topics)
│
├─ Event sourcing with change data capture?
│  └─ Cosmos DB Change Feed (append-only event log)
│
└─ Saga orchestration (distributed transactions)?
   └─ Dapr Workflow or Durable Functions (compensating transactions)
```

## Scoring Model

Use this as a **conversation starter** to evaluate messaging platforms against your specific requirements:

| Factor          | Event Hubs          | Service Bus Queue           | Service Bus Topic  | Event Grid                | Cosmos DB Change Feed        |
| --------------- | ------------------- | --------------------------- | ------------------ | ------------------------- | ---------------------------- |
| **Throughput**  | Millions events/sec | 1000s msg/sec               | 1000s msg/sec      | 10M events/sec            | 100K ops/sec (per partition) |
| **Ordering**    | Per partition (key) | FIFO with sessions          | FIFO with sessions | No guarantee              | Per partition key            |
| **Delivery**    | At-least-once       | At-least-once               | At-least-once      | At-least-once (retry 24h) | At-least-once                |
| **Dead-Letter** | Manual              | Built-in DLQ                | Built-in DLQ       | No (webhook retries)      | Manual                       |
| **Filtering**   | Consumer-side       | SQL filters (subscriptions) | SQL filters        | Advanced (subject, data)  | Manual (query)               |
| **Best For**    | IoT telemetry, logs | Task queues, commands       | Pub/sub, fan-out   | Azure events, webhooks    | Event sourcing, CQRS         |

## Event-Driven Architecture Patterns

### 1. Event Hubs (High-Throughput Streaming)

**What**: Managed event streaming for millions of events per second with partitioning and Kafka compatibility.

**How it works**: Producers send events to partitions (sharding for parallelism). Consumers read from partitions via consumer groups (multiple apps, each gets all events). Checkpointing tracks progress (resume on failure). Capture to Data Lake for cold storage. Compatible with Kafka protocol (migrate Kafka apps).

**When to use**: IoT telemetry (temperature sensors), application logs (centralized logging), clickstream analytics (user behavior tracking). Example: 100K IoT devices sending temperature readings every 5 seconds = 20K events/sec sustained, peaks at 1M/sec.

**Considerations**: Partition count fixed at creation (1-32 partitions, cannot change). Partition key determines routing (poor key causes hot partitions). Consumer groups limited to 20 per hub. Retention 1-90 days (default 7 days). Cost ~$11/mo per throughput unit (1 MB/sec ingress, 2 MB/sec egress).

### 2. Service Bus (Enterprise Messaging)

**What**: Reliable message broker with FIFO, transactions, dead-letter queues, and duplicate detection.

**How it works**: Queues for point-to-point (one consumer). Topics for pub/sub (multiple subscriptions with SQL filters). Sessions for ordered processing (all messages with same session ID processed sequentially). Peek-lock pattern (message locked 60s during processing, abandon/complete/dead-letter). Transactions for atomic operations across multiple queues.

**When to use**: Commands requiring guaranteed delivery (process order, send email), workflows with retries (payment processing), pub/sub with filtering (order-events → email/inventory/analytics subscriptions). Example: E-commerce order queue with 10K orders/day, each message processed exactly once with dead-letter for payment failures.

**Considerations**: Throughput lower than Event Hubs (~1000 msg/sec per queue). Premium tier for higher throughput (1M msg/sec) and VNet integration. Session ID required for FIFO within session (all customers' orders sequential per customer). Dead-letter queue manually monitored (set up alerts). Cost ~$10/mo Basic (no topics), ~$700/mo Premium.

### 3. Event Grid (Event Routing)

**What**: Reactive pub/sub for Azure resource events and custom domain events with filtering and fan-out.

**How it works**: System topics (built-in Azure events: blob created, VM started). Custom topics (application events: order placed, user registered). Subscriptions route to webhooks, functions, service bus, event hubs. Filters on event type, subject, or data fields (advanced: OR/AND operators). Retries for 24 hours on webhook failure.

**When to use**: Reacting to Azure resource changes (process uploaded blob, index Cosmos DB document), loosely-coupled microservices (order-service publishes, email/inventory subscribe), serverless workflows (event triggers function, function triggers next event). Example: Blob upload → Event Grid → Azure Function (OCR processing) → Cosmos DB insert → Change Feed → Event Grid → Search indexing function.

**Considerations**: Pull delivery (webhook must be reachable). No ordering guarantee (use sessions in Service Bus if FIFO required). No dead-letter queue (monitor failed delivery attempts via metrics). No message body persistence (transient routing). Cost ~$0.60 per 1M operations (very cheap for reactive systems).

### 4. Event Sourcing with Cosmos DB Change Feed

**What**: Append-only event log pattern where state derived from replaying events (audit trail, time travel, CQRS).

**How it works**: Store events as immutable documents (OrderPlaced, PaymentProcessed, OrderShipped). Partition by aggregate ID (OrderId) for sequential read. Rebuild aggregate by querying events ordered by version. Change Feed triggers projections (update read models: order summary, customer order history). CQRS: write to event log, read from projections.

**When to use**: Audit requirements (banking, healthcare), debugging production (replay events to reproduce), temporal queries (what was customer address in January?), CQRS (optimize reads separately from writes). Example: Order aggregate with 5 years of events (100M orders × 5 events/order = 500M events), projections in separate containers for fast queries.

**Considerations**: Eventual consistency (projections lag behind events by seconds). Storage grows unbounded (archive old events to blob storage). Snapshot aggregates every N events to avoid replaying millions. Cosmos DB cost ~$24/mo per 100 RU/s (400 RU/s minimum = ~$96/mo). Change Feed requires lease container (coordination across processors).

### 5. Saga Pattern (Distributed Transactions)

**What**: Coordinate multi-service transactions with compensating actions (rollback without two-phase commit).

**How it works**: Orchestration (central coordinator calls services sequentially, triggers compensation on failure) or choreography (services publish events, others react). Compensating transactions undo previous steps (CancelReservation, RefundPayment). Idempotent operations (same command twice = same result). Dapr Workflow or Durable Functions for orchestration state management.

**When to use**: Multi-service workflows (order → reserve inventory → charge payment → ship → update loyalty points), each service autonomous. Example: Travel booking saga (book flight, book hotel, book car rental; if hotel fails, cancel flight reservation and refund flight).

**Considerations**: Eventual consistency (order in "pending" state during saga). Compensation logic must be implemented (not all operations compensatable: sent email, physical shipment). Timeout handling (saga stuck if service unresponsive). Monitor saga state (metrics, alerts for long-running). Dapr Workflow preferred for Azure (built-in state management, retries).

### 6. Competing Consumers (Parallel Processing)

**What**: Multiple instances process messages from queue concurrently for horizontal scalability.

**How it works**: Service Bus distributes messages across instances (load balancing). Each message locked to one consumer (peek-lock). Configure MaxConcurrentCalls per instance (10-100 concurrent). Scale out instances based on queue length (KEDA, Container Apps scale rules, App Service autoscale).

**When to use**: High message volume requiring throughput (1000s msg/sec), CPU-intensive processing (image resizing, video encoding), bursty workloads (autoscale on queue depth). Example: Image upload queue with 10K images/hour, 3-minute processing per image → need 5 instances × 10 concurrent = 50 workers to keep up.

**Considerations**: Idempotent processing (message delivered twice if processor crashes before complete). Order not guaranteed across instances (use sessions for FIFO). Poison messages move to dead-letter after max delivery count (default 10 attempts). Monitor queue length and processing time (scale rules: queue length > 100 → add instance, < 10 → remove).

## Quick Reference

| Pattern                   | Platform                          | Use Case                                                   |
| ------------------------- | --------------------------------- | ---------------------------------------------------------- |
| High-throughput streaming | Event Hubs                        | IoT telemetry, logs (millions events/sec)                  |
| Reliable queues (FIFO)    | Service Bus Queue                 | Commands, task processing (guaranteed delivery)            |
| Pub/sub with filtering    | Service Bus Topic                 | Fan-out to multiple services (email, inventory, analytics) |
| Reactive event routing    | Event Grid                        | Azure resource events, webhooks (cheap, no buffer)         |
| Event sourcing            | Cosmos DB Change Feed             | Audit trail, CQRS, time travel queries                     |
| Saga orchestration        | Dapr Workflow, Durable Functions  | Multi-service transactions with compensation               |
| Parallel processing       | Service Bus + competing consumers | Scale out workers on queue depth                           |

## Common Pitfalls

- **Using synchronous HTTP when async messaging better** → Service A waits for B waits for C = cascading failures (one timeout breaks all). Use Service Bus queues for commands, Event Grid for coordination. Example: Order API → Service Bus → background workers (API returns 202 Accepted immediately).

- **Not handling duplicate messages (at-least-once delivery)** → Message processors must be idempotent (process same message twice = same result). Check messageId in database, skip if already processed. Example: "Add 100 points to loyalty account" executed twice = 200 points instead of 100 (use idempotency key).

- **Ignoring dead-letter queues** → Failed messages accumulate, no alerts → data loss. Monitor DLQ depth (alert if > 0), process manually or retry with backoff. Example: Payment timeout → 10 retries → dead-letter → investigate payment gateway issue.

- **Choosing wrong partition strategy** → Hot partitions (all events to one partition) kill throughput. Event Hubs: use high-cardinality partition key (deviceId, not region). Cosmos DB: partition by aggregate ID (OrderId), not by date (all writes go to "today" partition).

- **Not implementing circuit breaker for external dependencies** → Saga calls payment gateway (down 5 min) → thousands of failed sagas → dead-letter queue explodes. Use Polly or Dapr resiliency (circuit breaker stops calls after N failures, retry with backoff).

- **Mixing ordered and unordered workloads incorrectly** → Service Bus sessions for FIFO adds overhead. Use sessions only when order matters (process customer's orders sequentially). Use standard queue for independent messages (parallelize for throughput).

## Bundled Resources

- **Code Examples**: See `references/code-examples.md` for working implementations of Event Hubs producer/consumer with checkpointing, Service Bus queues/topics with dead-letter handling, Event Grid custom topics, event sourcing with Cosmos DB, saga pattern with Dapr Workflow, and competing consumers scaling.
- **Microsoft Learn**: See `references/microsoft-learn.md` for curated documentation on Azure messaging services comparison, event-driven patterns (pub/sub, saga, CQRS), Dapr building blocks, and best practices for idempotent processing and monitoring.
