# Saga & Workflow Orchestration - Microsoft Documentation

## Azure Durable Functions

### Core Concepts

- [Durable Functions overview](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview)
- [Durable orchestrations](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-orchestrations)
- [Activity functions](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-types-features-overview#activity-functions)
- [Durable Functions error handling](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-error-handling)

### Application Patterns

- [Function chaining](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-sequence)
- [Fan-out/fan-in pattern](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-cloud-backup)
- [Human interaction pattern](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-phone-verification)
- [Eternal orchestrations (recurring processes)](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-eternal-orchestrations)

### State Management & Monitoring

- [Instance management](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-instance-management)
- [Orchestration history and checkpointing](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-checkpointing-and-replay)
- [Performance and scale](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-perf-and-scale)

---

## Dapr Workflow

### Getting Started

- [Dapr Workflow overview](https://docs.dapr.io/developing-applications/building-blocks/workflow/workflow-overview/)
- [Workflow patterns](https://docs.dapr.io/developing-applications/building-blocks/workflow/workflow-patterns/)
- [Workflow authoring](https://docs.dapr.io/developing-applications/building-blocks/workflow/howto-author-workflow/)

### Features

- [Workflow management](https://docs.dapr.io/developing-applications/building-blocks/workflow/howto-manage-workflow/)
- [Sub-workflows](https://docs.dapr.io/developing-applications/building-blocks/workflow/workflow-patterns/#sub-workflows)
- [Dapr workflow with Python SDK](https://docs.dapr.io/developing-applications/sdks/python/python-workflow/)
- [Dapr workflow with .NET SDK](https://docs.dapr.io/developing-applications/sdks/dotnet/dotnet-workflow/)

---

## Azure Logic Apps

### Standard Workflows

- [Logic Apps Standard overview](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview)
- [Stateful vs stateless workflows](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview#stateful-and-stateless-workflows)
- [Built-in connectors](https://learn.microsoft.com/en-us/azure/connectors/built-in)
- [Approval workflows](https://learn.microsoft.com/en-us/azure/logic-apps/tutorial-process-email-attachments-workflow)

### Enterprise Features

- [Long-running workflows](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-enterprise-integration-overview)
- [Error handling and retries](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-exception-handling)
- [Monitoring and diagnostics](https://learn.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps)

---

## Saga Pattern

### Pattern Documentation

- [Saga design pattern (Azure Architecture Center)](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga)
- [Compensating Transaction pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction)
- [Choreography-based saga](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga#choreography-based-saga)
- [Orchestration-based saga](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga#orchestration-based-saga)

### Implementation Guidance

- [Saga pattern implementation (microservices)](https://learn.microsoft.com/en-us/azure/architecture/microservices/design/patterns#saga-pattern)
- [Distributed transactions in cloud-native apps](https://learn.microsoft.com/en-us/dotnet/architecture/cloud-native/distributed-data#distributed-transactions)
- [Event-driven architecture patterns](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/event-driven)

---

## Azure Service Bus (Choreography)

### Messaging Patterns

- [Service Bus messaging overview](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
- [Topics and subscriptions](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-queues-topics-subscriptions#topics-and-subscriptions)
- [Message sessions (correlation)](https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-sessions)
- [Dead-letter queues](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues)

### Advanced Features

- [Message ordering and timestamps](https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-sequencing)
- [Duplicate detection](https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection)
- [Service Bus SDK (.NET)](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dotnet-get-started-with-queues)
