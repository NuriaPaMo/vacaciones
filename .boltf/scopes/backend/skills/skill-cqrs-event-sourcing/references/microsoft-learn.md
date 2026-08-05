# CQRS & Event Sourcing - Microsoft Learn References

Curated Microsoft Learn documentation for CQRS and Event Sourcing patterns.

## CQRS Pattern

### Core Concepts

- [CQRS pattern](https://learn.microsoft.com/azure/architecture/patterns/cqrs) - Command and Query Responsibility Segregation pattern overview, when to use, and considerations
- [Materialized View pattern](https://learn.microsoft.com/azure/architecture/patterns/materialized-view) - Pre-compute data views for efficient queries (read model optimization)
- [Command and Query Responsibility Segregation (CQRS)](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/apply-simplified-microservice-cqrs-ddd-patterns) - Simplified CQRS in microservices with DDD

### Implementation Guidance

- [Design a CQRS architecture](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/cqrs) - Architectural guidance for implementing CQRS
- [Microservices with CQRS and Event Sourcing](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api) - Application layer with command/query handlers

---

## Event Sourcing Pattern

### Core Concepts

- [Event Sourcing pattern](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing) - Store events instead of state, benefits, and considerations
- [Append-only data stores](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing#context-and-problem) - Understanding immutable event logs
- [Domain events](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation) - Design and implementation in DDD

### Event Store Options

- [Azure Cosmos DB as event store](https://learn.microsoft.com/azure/cosmos-db/event-sourcing) - Using Cosmos DB for event sourcing with change feed
- [Azure SQL Database event store](https://learn.microsoft.com/azure/architecture/example-scenario/data/ecommerce-order-processing#event-sourcing) - SQL-based event store patterns
- [EventStoreDB](https://www.eventstore.com/event-sourcing) - Purpose-built event store database

---

## Projections & Read Models

- [Materialized View pattern](https://learn.microsoft.com/azure/architecture/patterns/materialized-view) - Generate pre-populated views over data when the source isn't suited to queries
- [Azure Cosmos DB Change Feed](https://learn.microsoft.com/azure/cosmos-db/change-feed) - Real-time event stream for building projections
- [Read model synchronization](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/cqrs-microservice-reads) - Implementing queries and read models

---

## Event Versioning

- [Versioning message contracts](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-versioning) - Strategies for evolving event schemas
- [Schema evolution with Azure Schema Registry](https://learn.microsoft.com/azure/event-hubs/schema-registry-overview) - Schema validation and evolution
- [Handling schema changes](https://www.eventstore.com/blog/event-versioning-patterns) - Event versioning patterns (external: EventStoreDB)

---

## Domain-Driven Design Integration

- [Implement the microservice application layer using Web API](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api) - Command handlers, domain events, integration events
- [Design and implement domain events](https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation) - Domain events as part of DDD aggregates
- [Tactical DDD patterns](https://learn.microsoft.com/azure/architecture/microservices/model/tactical-domain-driven-design) - Aggregates, entities, domain events

---

## Azure Services for CQRS + Event Sourcing

### Messaging & Event Streaming

- [Azure Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview) - Enterprise messaging for commands and events
- [Azure Event Hubs](https://learn.microsoft.com/azure/event-hubs/event-hubs-about) - Big data streaming and event ingestion
- [Azure Event Grid](https://learn.microsoft.com/azure/event-grid/overview) - Event routing and serverless event-driven architectures

### Storage Options

- [Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/introduction) - Multi-model NoSQL with change feed for event sourcing
- [Azure SQL Database](https://learn.microsoft.com/azure/azure-sql/database/sql-database-paas-overview) - Relational database for event store or read models
- [Azure Table Storage](https://learn.microsoft.com/azure/storage/tables/table-storage-overview) - Cost-effective NoSQL for simple event storage

---

## Reference Architectures

- [Event-driven architecture style](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/event-driven) - Overview of event-driven systems
- [Saga distributed transactions pattern](https://learn.microsoft.com/azure/architecture/reference-architectures/saga/saga) - Coordinate transactions across services using events
- [E-commerce event sourcing example](https://learn.microsoft.com/azure/architecture/example-scenario/data/ecommerce-order-processing) - Real-world event sourcing implementation

---

## Code Samples

- [eShopOnContainers](https://github.com/dotnet-architecture/eShopOnContainers) - Microservices reference app with CQRS, DDD, and Event Sourcing
- [Azure Cosmos DB event sourcing samples](https://github.com/Azure-Samples/cosmos-db-design-patterns/tree/main/event-sourcing)
- [EventStore samples](https://github.com/EventStore/samples) - EventStoreDB code samples

---

## Books (Free eBooks)

- [.NET Microservices: Architecture for Containerized .NET Applications](https://learn.microsoft.com/dotnet/architecture/microservices/) - Comprehensive guide covering CQRS, Event Sourcing, DDD
- [Cloud Native .NET for Azure](https://learn.microsoft.com/dotnet/architecture/cloud-native/) - Cloud-native patterns including event-driven architecture
