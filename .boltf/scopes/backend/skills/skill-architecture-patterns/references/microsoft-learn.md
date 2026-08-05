# Architecture Patterns - Microsoft Learn References

Curated Microsoft Learn documentation for architecture decision-making.

## Microservices Architecture

### Core Concepts

- [Microservices architecture style](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/microservices) - Overview of microservices principles, characteristics, and when to use them
- [Design a microservices architecture](https://learn.microsoft.com/azure/architecture/microservices/design/) - Comprehensive guide covering compute options, communication, API design, and data considerations
- [Design patterns for microservices](https://learn.microsoft.com/azure/architecture/microservices/design/patterns) - Ambassador, Bulkhead, Gateway patterns, Strangler Fig, and more

### Azure Implementation

- [Microservices architecture on Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-microservices/aks-microservices) - Reference architecture with ingress, networking, and service communication
- [Advanced Azure Kubernetes Service (AKS) microservices architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-microservices/aks-microservices-advanced) - Production-ready architecture with Cilium, observability, and security

### Domain-Driven Design

- [Use domain analysis to model microservices](https://learn.microsoft.com/azure/architecture/microservices/model/domain-analysis) - DDD approach to defining service boundaries
- [Use tactical DDD to design microservices](https://learn.microsoft.com/azure/architecture/microservices/model/tactical-domain-driven-design) - Aggregates, entities, domain events

---

## Modular Monolith Architecture

### Architecture Guidance

- [Common web application architectures](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) - Monolithic applications, N-layered architecture, Clean Architecture
- [What is a monolithic application?](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures#what-is-a-monolithic-application) - Definition, benefits, and when to use
- [Monolithic applications and containers](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures#monolithic-applications-and-containers) - Containerizing monoliths, scaling considerations

### .NET Implementation

- [Architect Modern Web Applications with ASP.NET Core and Azure](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/) - Complete guide to building modern monolithic web apps
- [All-in-one applications](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures#all-in-one-applications) - Single-project structure and folder organization

### Challenges and Evolution

- [Leveraging containers and orchestrators](https://learn.microsoft.com/dotnet/architecture/cloud-native/leverage-containers-orchestrators) - Challenges with monolithic deployments (deployment, scaling, coupling)
- [Containerizing monolithic applications](https://learn.microsoft.com/dotnet/architecture/microservices/architect-microservice-container-applications/containerize-monolithic-applications) - Container deployment model for monoliths

---

## Serverless Architecture

### Azure Functions

- [What is Azure Functions?](https://learn.microsoft.com/azure/azure-functions/functions-overview) - Serverless compute service overview, scenarios, triggers and bindings
- [Best practices for reliable Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-best-practices) - Maximize availability, reduce cold starts, performance optimization
- [Architecture best practices for Azure Functions](https://learn.microsoft.com/azure/well-architected/service-guides/azure-functions) - Well-Architected Framework guidance

### Patterns and Use Cases

- [Leveraging serverless functions](https://learn.microsoft.com/dotnet/architecture/cloud-native/leverage-serverless-functions) - What scenarios are appropriate, when to avoid serverless, cold start considerations
- [What scenarios are appropriate for serverless?](https://learn.microsoft.com/dotnet/architecture/cloud-native/leverage-serverless-functions#what-scenarios-are-appropriate-for-serverless) - Background tasks, queue processing, scheduled jobs

### Integration Scenarios

- [Integrate Event Hubs with serverless functions on Azure](https://learn.microsoft.com/azure/architecture/serverless/event-hubs-functions/event-hubs-functions) - Event-driven architectures with Functions and Event Hubs
- [Serverless database computing using Azure Cosmos DB and Azure Functions](https://learn.microsoft.com/azure/cosmos-db/serverless-computing-database) - Database triggers, bindings, connection management

---

## Event-Driven Architecture

### Patterns and Implementations

- [Patterns and implementations for a banking cloud transformation](https://learn.microsoft.com/industry/financial-services/architecture/patterns-and-implementations-content) - Saga pattern with orchestration using Durable Functions
- [Integration architecture design](https://learn.microsoft.com/azure/architecture/integration/integration-start-here) - Event Hubs, Logic Apps, Service Bus integration patterns

### Azure Services

- [Azure Event Hubs core concepts](https://learn.microsoft.com/azure/architecture/serverless/event-hubs-functions/event-hubs-functions#event-hubs-core-concepts) - Events, partitions, consumers, consumer groups
- [Performance and scale for Event Hubs and Azure Functions](https://learn.microsoft.com/azure/architecture/serverless/event-hubs-functions/performance-scale) - Partition management, checkpointing, scaling

---

## Migration Strategies

### Strangler Fig Pattern

- [Strangler Fig pattern](https://learn.microsoft.com/azure/architecture/patterns/strangler-fig) - Incremental migration from monolith to microservices
- [Migrate a web app using Azure APIM](https://learn.microsoft.com/azure/architecture/example-scenario/apps/apim-api-scenario) - Modernizing legacy stacks with API Management

### Containers and Orchestration

- [Choose an Azure compute service](https://learn.microsoft.com/azure/architecture/guide/technology-choices/compute-decision-tree) - Decision tree for compute options
- [Container orchestration](https://learn.microsoft.com/azure/architecture/microservices/design/orchestration) - Kubernetes, AKS, Container Apps comparison

---

## Cloud Design Patterns

### Essential Patterns for Distributed Systems

- [Cloud Design Patterns](https://learn.microsoft.com/azure/architecture/patterns/) - Complete catalog
- [Ambassador pattern](https://learn.microsoft.com/azure/architecture/patterns/ambassador) - Offload connectivity tasks
- [Anti-corruption layer](https://learn.microsoft.com/azure/architecture/patterns/anti-corruption-layer) - Facade between new and legacy systems
- [Backends for Frontends](https://learn.microsoft.com/azure/architecture/patterns/backends-for-frontends) - Separate backend per client type
- [Bulkhead pattern](https://learn.microsoft.com/azure/architecture/patterns/bulkhead) - Isolate critical resources
- [Gateway Aggregation](https://learn.microsoft.com/azure/architecture/patterns/gateway-aggregation) - Reduce chattiness
- [Gateway Routing](https://learn.microsoft.com/azure/architecture/patterns/gateway-routing) - Single endpoint for multiple services
- [Queue-Based Load Leveling](https://learn.microsoft.com/azure/architecture/patterns/queue-based-load-leveling) - Asynchronous task handling
- [Sidecar pattern](https://learn.microsoft.com/azure/architecture/patterns/sidecar) - Deploy helper components
- [Publisher-Subscriber pattern](https://learn.microsoft.com/azure/architecture/patterns/publisher-subscriber) - Decouple producers and consumers
- [Competing Consumers pattern](https://learn.microsoft.com/azure/architecture/patterns/competing-consumers) - Parallel message processing

---

## Code Samples

### Official Sample Applications

- [eShopOnContainers](https://github.com/dotnet-architecture/eShopOnContainers) - Microservices reference application (.NET)
- [eShopOnWeb](https://github.com/dotnet-architecture/eShopOnWeb) - Modular monolith reference application (.NET)
- [Azure Functions samples](https://github.com/Azure/azure-functions-samples) - Triggers, bindings, and integration patterns

---

## Architecture Books (Free eBooks)

- [.NET Microservices: Architecture for Containerized .NET Applications](https://learn.microsoft.com/dotnet/architecture/microservices/)
- [Architect Modern Web Applications with ASP.NET Core and Azure](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/)
- [Cloud Native .NET for Azure](https://learn.microsoft.com/dotnet/architecture/cloud-native/)
- [Enterprise Application Patterns Using .NET MAUI](https://learn.microsoft.com/dotnet/architecture/maui/)
