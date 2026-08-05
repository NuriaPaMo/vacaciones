---
name: skill-cqrs-event-sourcing
description: Implement CQRS and Event Sourcing patterns with native code (no MediatR) using EventStoreDB or Cosmos DB. Use when building systems requiring complete audit trails, temporal queries, event replay, or separate read/write models. Critical for event-driven architectures - helps choose between full CQRS+ES, simple CQRS, or traditional CRUD.
---

# CQRS & Event Sourcing

> **Constitution Articles**: Backend III §3.3 (CQRS), Backend III §3.4 (Event Sourcing)
> **Bundled Resources**: See `references/code-examples.md` for implementations, `references/microsoft-learn.md` for documentation

## When to Use This Skill

CQRS and Event Sourcing are powerful but complex patterns that add significant architectural complexity. Understanding when they're worth the cost is crucial because they're difficult to remove once implemented. Use this skill when:

- **Implementing CQRS** (Article III §3.3) - because separating reads from writes enables independent scaling and optimization, but requires careful consideration of eventual consistency
- **Implementing Event Sourcing** (Article III §3.4) - because storing events instead of current state provides complete audit trails and temporal queries, but irreversibly changes how your system handles data
- **Building audit-critical systems** - because Event Sourcing captures every state change, making it invaluable for compliance, debugging, and audit trails
- **Need for temporal queries** - because Event Sourcing lets you reconstruct past states and answer "what was the customer's address on January 15th?"
- **Complex domain logic** - because CQRS clarifies intent (commands change state, queries don't), reducing cognitive load in complex domains

**Important context**: The constitution (Article III §3.3) **prohibits MediatR library**. All CQRS implementations must use native patterns (interfaces, dependency injection, handler registration).

## Decision Framework

### Should You Use CQRS?

CQRS isn't about technology—it's about recognizing that reads and writes often have different requirements:

```text
Do you have different scaling needs for reads vs writes?
├─ YES → CQRS helps (scale read replicas independently)
└─ NO → Keep evaluating

Do your queries need denormalized views or complex projections?
├─ YES → CQRS helps (optimize read models without affecting writes)
└─ NO → Keep evaluating

Is your domain logic complex with many business rules?
├─ YES → CQRS helps (commands capture intent clearly)
└─ NO → Simple CRUD might suffice

Can your team handle eventual consistency?
├─ YES → CQRS is viable
└─ NO → Reconsider or plan training
```

**Why this matters**: CQRS adds complexity (separate models, eventual consistency, synchronization). Use it when the benefits (performance, clarity, scalability) outweigh the costs.

### Should You Use Event Sourcing?

Event Sourcing is a fundamentally different way of thinking about data persistence:

```text
Do you need complete audit trails?
├─ YES (compliance, finance, healthcare) → Event Sourcing provides this naturally
└─ NO → Keep evaluating

Do you need temporal queries ("what was the state on date X")?
├─ YES → Event Sourcing makes this trivial
└─ NO → Keep evaluating

Do you need event replay for debugging or migration?
├─ YES → Event Sourcing enables replaying history
└─ NO → Keep evaluating

Can your team handle eventual consistency and event versioning?
├─ YES → Event Sourcing is viable
└─ NO → Event Sourcing will cause significant friction
```

**Why this matters**: Event Sourcing changes everything—you never update or delete data, only append events. This is powerful but irreversible. Your current state becomes a projection of events, not the source of truth.

### CQRS + Event Sourcing Decision Matrix

| Pattern                 | Complexity | Audit Trail | Temporal Queries | Eventual Consistency     | When to Use                                 |
| ----------------------- | ---------- | ----------- | ---------------- | ------------------------ | ------------------------------------------- |
| **CRUD**                | Low        | No          | No               | Strong                   | Simple domains, CRUD operations             |
| **CQRS Only**           | Medium     | No          | No               | Eventually (read side)   | Different read/write scale, complex queries |
| **Event Sourcing Only** | High       | Yes         | Yes              | Eventually (projections) | Audit requirements, rare writes             |
| **CQRS + ES**           | Very High  | Yes         | Yes              | Eventually (both sides)  | Complex domains + audit + temporal queries  |

**Recommendation**: Start with CRUD. Add CQRS when read/write patterns diverge. Add Event Sourcing only when audit trails or temporal queries are critical business requirements.

## Pattern Variants

> **For complete code examples**, read `references/code-examples.md`
> **For Microsoft Learn documentation**, read `references/microsoft-learn.md`

### 1. Native CQRS (No MediatR)

**What it is**: Separate command and query handlers using interfaces and dependency injection, without third-party libraries.

**Why use native implementation**: The constitution prohibits MediatR to avoid unnecessary abstractions. Native CQRS using interfaces is simpler, more explicit, and gives you full control over the pipeline.

**Key characteristics**:

- Commands: `ICommandHandler<TCommand>` interface
- Queries: `IQueryHandler<TQuery, TResult>` interface
- Registration via DI container (ASP.NET Core services)
- No magic, no reflection-based dispatch

**When to use**:

- CQRS benefits needed (separate optimization, clear intent)
- Want explicit control over command/query execution
- Constitution compliance (no MediatR)

> See `references/code-examples.md` for C#/.NET and Node.js/TypeScript native CQRS implementations

---

### 2. Event Sourcing Patterns

**What it is**: Store every state change as an immutable event in an append-only log. Current state is derived by replaying events.

**Why this changes everything**: Traditional systems store current state (UPDATE records). Event Sourcing stores history (INSERT events). You can always reconstruct any past state, but you can never "delete" history.

**Key characteristics**:

- Events are immutable (never updated or deleted)
- Current state = replay all events
- Aggregates (domain entities) apply events
- Snapshots optimize performance (cache state at event N)
- Event versioning handles schema evolution

**Event Store Options**:

| Store                   | Best For                                   | Append Performance | Query Performance       | Azure Service   |
| ----------------------- | ------------------------------------------ | ------------------ | ----------------------- | --------------- |
| **EventStoreDB**        | Pure event sourcing, high write throughput | Excellent          | Good (projections)      | VM/AKS          |
| **Cosmos DB**           | Azure-native, guaranteed SLA               | Very Good          | Excellent (change feed) | Azure Cosmos DB |
| **SQL Server**          | Existing SQL infrastructure                | Good               | Good (with indexing)    | Azure SQL       |
| **Azure Table Storage** | Cost-optimized, simple events              | Excellent          | Limited                 | Azure Storage   |

**When to use**:

- Audit trails are non-negotiable
- Temporal queries are business requirements
- Event replay for debugging/migration
- Event-driven architecture (publish domain events)

> See `references/code-examples.md` for EventStoreDB, Cosmos DB, and SQL implementations

---

### 3. Projections & Read Models

**What they are**: Denormalized views built from events to optimize queries. The event store is write-optimized; projections are read-optimized.

**Why they matter**: Event Sourcing optimizes writes (append events). Queries need different structures (joins, aggregations). Projections bridge this gap.

**Types of projections**:

- **Synchronous**: Update read model in same transaction (strong consistency, slower)
- **Asynchronous**: Update via event subscription (eventual consistency, faster)
- **Catch-up**: Replay historical events to rebuild projections

**When to use**:

- Event Sourcing + complex queries
- Different query patterns (list views, detail views, reports)
- Need query performance independent of event store

> See `references/code-examples.md` for projection patterns

---

### 4. Event Versioning

**What it is**: Strategy for evolving event schemas as your domain changes, without breaking existing events in the store.

**Why it's critical**: Events are immutable and permanent. When your domain changes, you can't rewrite history—you must handle multiple event versions.

**Versioning strategies**:

- **Upcasting**: Convert old events to new schema on replay
- **Multi-version handlers**: Support both old and new event versions
- **Weak schema**: Use flexible JSON without strict schema
- **Migration events**: Emit new events to represent historical data in new format

**When to use**:

- Your domain evolves (it will)
- You can't afford downtime for migration
- Long-lived systems with years of event history

> See `references/code-examples.md` for versioning patterns

---

## CQRS Without MediatR

The constitution forbids MediatR. Here's why native CQRS is better:

**Problems with MediatR**:

- Hides control flow (magic dispatch via reflection)
- Adds unnecessary complexity for simple command/query handling
- Couples to third-party library
- Makes debugging harder (opaque pipeline)

**Native CQRS advantages**:

- Explicit handler registration (clear, debuggable)
- Full control over pipeline (validation, logging, transactions)
- No external dependencies
- Simpler to understand and maintain

> See `references/code-examples.md` for native handler patterns (C# and TypeScript)

---

## How to Proceed

**Start simple, evolve as needed**:

1. **Evaluate complexity tolerance** - CQRS+ES adds significant complexity. Do the benefits justify the cost for your team and domain?

2. **Read pattern details** - Consult `references/code-examples.md` for concrete implementations. Native CQRS is simpler than you think; Event Sourcing requires careful design.

3. **Choose your event store** - If using Event Sourcing, decide between EventStoreDB (purpose-built), Cosmos DB (Azure-native), or SQL (existing infrastructure). See `references/microsoft-learn.md` for guidance.

4. **Plan for eventual consistency** - CQRS and ES both introduce eventual consistency. Design your UI and business processes to handle it (e.g., "Your order is being processed" instead of immediate confirmation).

5. **Implement incrementally** - Start with CQRS on one bounded context. Add Event Sourcing only where audit/temporal queries are essential. Don't boil the ocean.

**Remember**: These patterns solve real problems (audit, temporal queries, scale), but they're not free. Most systems don't need them. When you do need them, implement them deliberately and incrementally.

---

## References

### Bundled Resources (Read These for Details)

- `references/code-examples.md` - Complete native CQRS and Event Sourcing implementations (C#, Node.js)
- `references/microsoft-learn.md` - Curated Microsoft Learn documentation and patterns

### Quick Links

- [CQRS pattern](https://learn.microsoft.com/azure/architecture/patterns/cqrs)
- [Event Sourcing pattern](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing)
- [EventStoreDB documentation](https://www.eventstore.com/event-sourcing)
