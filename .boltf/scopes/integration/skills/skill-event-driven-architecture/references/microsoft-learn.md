# Event-Driven Architecture - Microsoft Learn Resources

## Azure Event Hubs (High-Throughput Streaming)

- [Azure Event Hubs Documentation](https://learn.microsoft.com/azure/event-hubs/)
- [Event Hubs features and terminology](https://learn.microsoft.com/azure/event-hubs/event-hubs-features)
- [Partitions and consumer groups](https://learn.microsoft.com/azure/event-hubs/event-hubs-scalability#partitions)
- [Event Processor Host (checkpointing)](https://learn.microsoft.com/azure/event-hubs/event-hubs-event-processor-host)
- [Capture events to Data Lake/Blob Storage](https://learn.microsoft.com/azure/event-hubs/event-hubs-capture-overview)

## Azure Service Bus (Enterprise Messaging)

- [Azure Service Bus Documentation](https://learn.microsoft.com/azure/service-bus-messaging/)
- [Queues, topics, and subscriptions](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-queues-topics-subscriptions)
- [Message sessions (FIFO guarantee)](https://learn.microsoft.com/azure/service-bus-messaging/message-sessions)
- [Dead-letter queues](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-dead-letter-queues)
- [Duplicate detection](https://learn.microsoft.com/azure/service-bus-messaging/duplicate-detection)
- [Transaction support](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-transactions)

## Azure Event Grid (Event Routing)

- [Azure Event Grid Documentation](https://learn.microsoft.com/azure/event-grid/)
- [Event Grid concepts (topics, subscriptions, handlers)](https://learn.microsoft.com/azure/event-grid/concepts)
- [Event schema and filtering](https://learn.microsoft.com/azure/event-grid/event-schema)
- [System topics (built-in Azure events)](https://learn.microsoft.com/azure/event-grid/system-topics)
- [Custom topics for domain events](https://learn.microsoft.com/azure/event-grid/custom-topics)

## Event-Driven Architecture Patterns

- [Event-driven architecture style](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/event-driven)
- [Choose between messaging services (Event Hubs vs Service Bus vs Event Grid)](https://learn.microsoft.com/azure/event-grid/compare-messaging-services)
- [Event sourcing pattern](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing)
- [CQRS pattern](https://learn.microsoft.com/azure/architecture/patterns/cqrs)
- [Publisher-Subscriber pattern](https://learn.microsoft.com/azure/architecture/patterns/publisher-subscriber)
- [Competing Consumers pattern](https://learn.microsoft.com/azure/architecture/patterns/competing-consumers)
- [Saga pattern (distributed transactions)](https://learn.microsoft.com/azure/architecture/reference-architectures/saga/saga)

## Integration with Azure Services

- [Azure Functions Event Hub trigger](https://learn.microsoft.com/azure/azure-functions/functions-bindings-event-hubs-trigger)
- [Azure Functions Service Bus trigger](https://learn.microsoft.com/azure/azure-functions/functions-bindings-service-bus-trigger)
- [Azure Functions Event Grid trigger](https://learn.microsoft.com/azure/azure-functions/functions-bindings-event-grid-trigger)
- [Cosmos DB Change Feed](https://learn.microsoft.com/azure/cosmos-db/change-feed)
- [Logic Apps with messaging connectors](https://learn.microsoft.com/azure/logic-apps/logic-apps-enterprise-integration-overview)

## Dapr for Event-Driven Microservices

- [Dapr pub/sub building block](https://docs.dapr.io/developing-applications/building-blocks/pubsub/)
- [Dapr bindings (event triggers)](https://docs.dapr.io/developing-applications/building-blocks/bindings/)
- [Dapr workflows (saga pattern)](https://docs.dapr.io/developing-applications/building-blocks/workflow/)
- [Dapr actors (stateful event processors)](https://docs.dapr.io/developing-applications/building-blocks/actors/)

## Best Practices and Guidance

- [Asynchronous messaging primer](https://learn.microsoft.com/azure/architecture/best-practices/message-encode)
- [Idempotent message processing](https://learn.microsoft.com/azure/architecture/best-practices/retry-service-specific#service-bus)
- [Event-driven autoscaling](https://learn.microsoft.com/azure/architecture/best-practices/auto-scaling#event-driven-scaling)
- [Monitoring event-driven systems](https://learn.microsoft.com/azure/architecture/best-practices/monitoring)
