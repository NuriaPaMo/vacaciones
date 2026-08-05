# Communication Patterns – Microsoft Learn Resources

Curated Microsoft Learn documentation for each communication pattern. These resources provide official guidance, best practices, and deep dives into implementation details.

---

## REST APIs

### Core Documentation

- **[Tutorial: Create a minimal API with ASP.NET Core](https://learn.microsoft.com/aspnet/core/tutorials/min-web-api)**
  Step-by-step guide to building REST APIs with minimal APIs pattern

- **[OpenAPI support in ASP.NET Core APIs](https://learn.microsoft.com/aspnet/core/web-api/microsoft.aspnetcore.openapi)**
  Generate OpenAPI specifications (Swagger) for your REST endpoints

- **[API versioning in ASP.NET Core](https://learn.microsoft.com/aspnet/core/web-api/advanced/versioning)**
  Strategies for versioning REST APIs (URL, query string, header-based)

- **[Handle errors in ASP.NET Core web APIs](https://learn.microsoft.com/aspnet/core/web-api/handle-errors)**
  Best practices for error handling and problem details (RFC 7807)

- **[Response compression in ASP.NET Core](https://learn.microsoft.com/aspnet/core/performance/response-compression)**
  Optimize payload sizes for REST responses

### REST Best Practices

- **[Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/Guidelines.md)**
  Official Microsoft conventions for REST API design

- **[Azure REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md)**
  Azure-specific REST patterns (resource naming, pagination, async operations)

---

## gRPC

### Core Documentation

- **[Introduction to gRPC on .NET](https://learn.microsoft.com/aspnet/core/grpc/)**
  Overview of gRPC services in ASP.NET Core

- **[Tutorial: Create a gRPC client and server in ASP.NET Core](https://learn.microsoft.com/aspnet/core/tutorials/grpc/grpc-start)**
  End-to-end walkthrough of building gRPC services

- **[gRPC services with C#](https://learn.microsoft.com/aspnet/core/grpc/basics)**
  Protobuf contracts, service implementation, and code generation

- **[Call gRPC services with the .NET client](https://learn.microsoft.com/aspnet/core/grpc/client)**
  Client-side gRPC patterns, channels, and interceptors

- **[gRPC on browser clients](https://learn.microsoft.com/aspnet/core/grpc/browser)**
  gRPC-Web for browser compatibility

### gRPC Advanced Patterns

- **[Code-first gRPC services and clients with .NET](https://learn.microsoft.com/aspnet/core/grpc/code-first)**
  Skip .proto files with protobuf-net.Grpc (constitution prefers standard .proto approach)

- **[gRPC performance best practices](https://learn.microsoft.com/aspnet/core/grpc/performance)**
  Connection reuse, streaming, compression, benchmarks

- **[gRPC interceptors in C#](https://learn.microsoft.com/aspnet/core/grpc/interceptors)**
  Logging, authentication, error handling cross-cutting concerns

- **[Health checks in gRPC](https://learn.microsoft.com/aspnet/core/grpc/health-checks)**
  Implement gRPC health checking protocol for Kubernetes/load balancers

---

## GraphQL

### Core Documentation

- **[Introduction to GraphQL on ASP.NET Core](https://learn.microsoft.com/training/modules/graphql-dotnet-intro/)**
  Microsoft Learn module on GraphQL fundamentals with HotChocolate

- **[HotChocolate Documentation](https://chillicream.com/docs/hotchocolate/v14)**
  Official HotChocolate documentation (mandated GraphQL library per constitution)

- **[Build a GraphQL API with HotChocolate](https://chillicream.com/docs/hotchocolate/v14/get-started)**
  Quick start guide for HotChocolate in ASP.NET Core

### GraphQL Advanced Patterns

- **[DataLoader pattern for N+1 problem](https://chillicream.com/docs/hotchocolate/v14/fetching-data/dataloader)**
  Batch and cache database queries to optimize performance

- **[Projections in HotChocolate](https://chillicream.com/docs/hotchocolate/v14/fetching-data/projections)**
  Map GraphQL selections to database queries (IQueryable integration)

- **[Authorization in HotChocolate](https://chillicream.com/docs/hotchocolate/v14/security/authorization)**
  Field-level and type-level authorization

- **[GraphQL subscriptions](https://chillicream.com/docs/hotchocolate/v14/subscriptions)**
  Real-time push notifications over WebSockets

---

## Azure Service Bus

### Core Documentation

- **[What is Azure Service Bus?](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-messaging-overview)**
  Overview of Service Bus capabilities (queues, topics, subscriptions)

- **[Quickstart: Send and receive messages from Azure Service Bus queue (.NET)](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues)**
  C# SDK basics for Service Bus queues

- **[Service Bus topics and subscriptions](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-queues-topics-subscriptions#topics-and-subscriptions)**
  Pub/sub pattern with topic filters and correlation rules

- **[Message sessions in Azure Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/message-sessions)**
  Guaranteed FIFO ordering for related messages

### Service Bus Advanced Patterns

- **[Dead-letter queues in Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-dead-letter-queues)**
  Handle poison messages and message expiration

- **[Duplicate detection in Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/duplicate-detection)**
  Automatic idempotency with MessageId deduplication

- **[Service Bus auto-forwarding](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-auto-forwarding)**
  Chain queues and topics for complex routing

- **[Transactions and atomicity in Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-transactions)**
  Multi-message atomic operations

- **[Service Bus performance best practices](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-performance-improvements)**
  Batching, prefetch count, connection pooling

### Integration Patterns

- **[Using Service Bus with Entity Framework (Outbox Pattern)](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-transactions#transactions-and-send-via)**
  Transactional consistency between database writes and messaging

- **[Azure Service Bus bindings for Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-bindings-service-bus)**
  Serverless message processing with Functions

---

## Azure Event Hubs

### Core Documentation

- **[What is Azure Event Hubs?](https://learn.microsoft.com/azure/event-hubs/event-hubs-about)**
  Big data streaming platform and event ingestion service

- **[Quickstart: Send and receive events using C#](https://learn.microsoft.com/azure/event-hubs/event-hubs-dotnet-standard-getstarted-send)**
  Producer and consumer basics with Azure.Messaging.EventHubs SDK

- **[Event Hubs partitions and consumer groups](https://learn.microsoft.com/azure/event-hubs/event-hubs-features#partitions)**
  Scaling model and parallel processing

- **[Checkpointing and replaying events](https://learn.microsoft.com/azure/event-hubs/event-hubs-features#checkpointing)**
  Durable progress tracking with Azure Blob Storage

### Event Hubs Advanced Patterns

- **[Event Hubs Capture](https://learn.microsoft.com/azure/event-hubs/event-hubs-capture-overview)**
  Automatically archive events to Azure Blob Storage or Data Lake

- **[Schema Registry in Event Hubs](https://learn.microsoft.com/azure/event-hubs/schema-registry-overview)**
  Apache Avro schema management for event evolution

- **[Event Hubs for Apache Kafka](https://learn.microsoft.com/azure/event-hubs/event-hubs-for-kafka-ecosystem-overview)**
  Kafka protocol compatibility for migration scenarios

- **[Scaling with Event Hubs](https://learn.microsoft.com/azure/event-hubs/event-hubs-scalability)**
  Throughput units, processing units, auto-inflate

### Integration Patterns

- **[Stream Analytics with Event Hubs](https://learn.microsoft.com/azure/stream-analytics/stream-analytics-introduction)**
  Real-time analytics queries over event streams

- **[Azure Functions Event Hubs trigger](https://learn.microsoft.com/azure/azure-functions/functions-bindings-event-hubs-trigger)**
  Serverless event processing at scale

- **[Event sourcing with Event Hubs](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing)**
  Using Event Hubs as immutable event store

---

## Background Jobs

### Hangfire Documentation

- **[Hangfire Official Documentation](https://docs.hangfire.io/)**
  Persistent background job framework for .NET (mandated per constitution Article III.4)

- **[Hangfire Background Methods](https://docs.hangfire.io/background-methods/index.html)**
  Fire-and-forget, delayed, recurring, and continuation jobs

- **[Hangfire Dashboard](https://docs.hangfire.io/dashboard/index.html)**
  Web-based monitoring UI for job status and retries

### Azure Functions Alternative

- **[Azure Functions Timer trigger](https://learn.microsoft.com/azure/azure-functions/functions-bindings-timer)**
  Scheduled serverless execution (CRON expressions)

- **[Durable Functions overview](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)**
  Stateful workflows, fan-out/fan-in, human interaction patterns

- **[Durable Functions patterns](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview#application-patterns)**
  Function chaining, fan-out/fan-in, async HTTP APIs, monitoring, human interaction

---

## Cross-Cutting Concerns

### Authentication & Authorization

- **[Authenticate Azure-hosted apps with Azure services](https://learn.microsoft.com/azure/developer/intro/passwordless-overview)**
  DefaultAzureCredential and managed identity for Service Bus/Event Hubs

- **[Azure AD authentication for ASP.NET Core](https://learn.microsoft.com/aspnet/core/security/authentication/azure-active-directory/)**
  Protect REST/gRPC/GraphQL APIs with Entra ID

### Observability

- **[Application Insights for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/asp-net-core)**
  Distributed tracing for REST, gRPC, and messaging patterns

- **[Distributed tracing with Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/distributed-tracing)**
  Correlate requests across service boundaries

### Resilience

- **[Implement resilient applications](https://learn.microsoft.com/dotnet/architecture/microservices/implement-resilient-applications/)**
  Retry policies, circuit breakers, bulkheads

- **[Polly documentation](https://www.thepollyproject.org/)**
  .NET resilience library for transient fault handling (mandated per constitution)

---

## Architecture Guidance

- **[API design guidance](https://learn.microsoft.com/azure/architecture/best-practices/api-design)**
  Azure Architecture Center guidance on API patterns

- **[Asynchronous messaging patterns](https://learn.microsoft.com/azure/architecture/patterns/category/messaging)**
  Patterns: Competing Consumers, Priority Queue, Claim Check, Choreography, Publisher-Subscriber

- **[Microservices communication](https://learn.microsoft.com/dotnet/architecture/microservices/architect-microservice-container-applications/communication-in-microservice-architecture)**
  Synchronous vs asynchronous, service mesh, API gateways

- **[Choose between Azure messaging services](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)**
  Decision matrix: Service Bus vs Event Hubs vs Event Grid vs Storage Queues

---

## Related Skills

- **[skill-event-driven-architecture](../../skill-event-driven-architecture/)** – Event-driven patterns, event storming, choreography vs orchestration
- **[skill-saga-workflow-orchestration](../../skill-saga-workflow-orchestration/)** – Distributed transactions, compensation, Durable Functions sagas
- **[skill-frontend-framework-selection](../../../frontend/skills/skill-frontend-framework-selection/)** – Frontend communication needs (REST vs GraphQL)
