# BOLT Framework Project Constitution — Scope: Integration

> **Extracted from**: `.boltf/memory/constitution.md`
> **Scope**: `integration` — Communication patterns, API management, legacy migration, and external system integration.
> Articles marked with 🔄 are **common to all scopes** and always present.
> Sections marked with 🆕 are **proposed additions** not present in the original constitution.

---

## Preamble 🔄

This Constitution establishes the governing principles, technology decisions, and standards for the **[PROJECT_NAME]** project. All AI agents, developers, and automated systems MUST adhere to this document.

**This document is the SINGLE SOURCE OF TRUTH.**

**Cloud Provider**: Microsoft Azure (mandatory for all deployments)

---

## Article IV: Communication

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 4.1: Communication Style 🔴 CRITICAL

> **🔴 CRITICAL**: Communication pattern (Sync vs Async vs Hybrid) fundamentally affects architecture

Select ONE:

- [ ] **Synchronous only** - REST, gRPC
- [ ] **Asynchronous only** - Messages, Events
- [ ] **Hybrid** - Both sync and async

### Section 4.2: Synchronous Communication 🟡 IMPORTANT

> **🟡 IMPORTANT**: API style affects development patterns but can coexist

- [ ] **REST API** - Enabled
- [ ] **gRPC** - Enabled
- [ ] **GraphQL** - [ ] None [ ] HotChocolate (.NET) [ ] Apollo (Node.js)

### Section 4.3: Asynchronous Communication 🔴 CRITICAL

> **🔴 CRITICAL**: Message broker choice (Service Bus vs Event Hubs) = different messaging patterns

Message Broker - Select ONE:

- [ ] **None**
- [ ] **Azure Service Bus** - Cloud-native, enterprise
- [ ] **Azure Event Hubs** - High-throughput streaming
- [ ] **RabbitMQ** - On-premises, flexible
- [ ] **Azure Storage Queues** - Simple, cost-effective

Background Processing - Select ONE or more:

- [ ] **None**
- [ ] **.NET BackgroundService** / **Node.js Worker Threads**
- [ ] **Azure Functions** - Serverless triggers
- [ ] **Hangfire** (.NET) / **BullMQ** (Node.js) - Persistent jobs

---

## Article X: Environments & Configuration 🔄

> **📋 Applies to**: ALL project types

### Section 10.1: Environment Strategy

| Environment | Purpose                      | Enabled | Auto-Deploy              |
| ----------- | ---------------------------- | ------- | ------------------------ |
| **dev**     | Development, rapid iteration | [ ] Yes | [ ] On commit to develop |
| **uat**     | User Acceptance Testing      | [ ] Yes | [ ] On PR merge          |
| **pre**     | Pre-production, staging      | [ ] Yes | [ ] Manual trigger       |
| **prod**    | Production                   | [ ] Yes | [ ] Manual approval      |

### Section 10.2: Configuration Management

Select strategy:

- [ ] **Azure App Configuration** - Centralized, feature flags (recommended)
- [ ] **Environment Variables** - Container/App Service config
- [ ] **appsettings.{Environment}.json** (.NET) / **.env files** (Node.js)
- [ ] **Combination** - App Config + Key Vault (recommended)

### Section 10.3: Secrets Management

| Secret Type        | Storage         |
| ------------------ | --------------- |
| Connection Strings | Azure Key Vault |
| API Keys           | Azure Key Vault |
| Certificates       | Azure Key Vault |

Local Development Secrets:

- [ ] **User Secrets** (.NET) - `dotnet user-secrets`
- [ ] **.env files** (Node.js) - gitignored
- [ ] **Local Key Vault** - Azure Key Vault dev instance

### Section 10.4: Feature Flags

Feature Flag Provider:

- [ ] **None**
- [ ] **Azure App Configuration** - Native integration
- [ ] **LaunchDarkly** - Enterprise features
- [ ] **Unleash** - Open-source

---

## Article XI: CI/CD Pipeline 🔄

> **📋 Applies to**: ALL project types

### Section 11.1: CI/CD Platform

Select ONE:

- [ ] **GitHub Actions** - GitHub-native
- [ ] **Azure DevOps Pipelines** - Azure-native

### Section 11.2: Pipeline Stages

#### For Application Development

| Stage                  | Enabled | Threshold                          |
| ---------------------- | ------- | ---------------------------------- |
| **Build**              | [ ] Yes | Warnings as errors: [ ] Yes [ ] No |
| **Lint/Format**        | [ ] Yes | -                                  |
| **Unit Tests**         | [ ] Yes | Coverage >= \_\_%                  |
| **Integration Tests**  | [ ] Yes | -                                  |
| **Architecture Tests** | [ ] Yes | -                                  |
| **Mutation Tests**     | [ ] Yes | Score >= \_\_%                     |
| **Security Scan**      | [ ] Yes | 0 Critical                         |
| **Container Build**    | [ ] Yes | -                                  |
| **Container Scan**     | [ ] Yes | 0 Critical                         |

#### Deployment Stages

| Stage           | Enabled | Trigger            |
| --------------- | ------- | ------------------ |
| **Deploy Dev**  | [ ] Yes | Auto on develop    |
| **Deploy UAT**  | [ ] Yes | Auto on release/\* |
| **Deploy Pre**  | [ ] Yes | Manual trigger     |
| **Deploy Prod** | [ ] Yes | Manual approval    |

### Section 11.3: Deployment Strategy

Select ONE:

- [ ] **Rolling Update** - Gradual replacement
- [ ] **Blue-Green** - Azure Deployment Slots / K8s
- [ ] **Canary** - Gradual traffic shift
- [ ] **Feature Flags** - Deploy dark, enable via flags

### Section 11.4: Branch Strategy

Select ONE:

- [ ] **GitFlow** - feature/, develop, release/, main
- [ ] **GitHub Flow** - feature/, main
- [ ] **Trunk-Based** - Short-lived branches, main

---

## Article XII: Observability 🔄

> **📋 Applies to**: ALL project types

### Section 12.1: Observability Strategy

Select ONE:

- [ ] **Azure-Native** - Azure Monitor + Application Insights
- [ ] **OpenTelemetry → Azure** - OTel SDK → Azure Monitor Exporter
- [ ] **OpenTelemetry → Grafana Stack** - Self-hosted Grafana/Loki/Tempo

### Section 12.2: Health Checks

```text
/health       - Full health check
/health/ready - Readiness probe
/health/live  - Liveness probe
```

---

## Article XVI: Security Policies 🔄

> **📋 Applies to**: ALL project types

### Section 16.1: Network Security

| Component                | Configuration                     |
| ------------------------ | --------------------------------- |
| Virtual Network          | [ ] Azure VNet [ ] None           |
| Private Endpoints        | [ ] Enabled [ ] Disabled          |
| Web Application Firewall | [ ] Azure Front Door WAF [ ] None |

### Section 16.2: Data Protection

| Policy                | Value                                                 |
| --------------------- | ----------------------------------------------------- |
| Encryption at Rest    | [ ] Azure-managed keys [ ] Customer-managed keys      |
| Encryption in Transit | TLS 1.2+ (mandatory)                                  |
| PII Handling          | [ ] Anonymization [ ] Pseudonymization [ ] Encryption |

### Section 16.3: Compliance Requirements

| Standard | Required       |
| -------- | -------------- |
| GDPR     | [ ] Yes [ ] No |
| HIPAA    | [ ] Yes [ ] No |
| SOC 2    | [ ] Yes [ ] No |
| PCI-DSS  | [ ] Yes [ ] No |

---

## Article XVII: Legacy & Migration

> **📋 Applies to**: Application Development, Full Stack (if migrating)
> **⏭️ Skip if**: Greenfield Infrastructure Only

### Section 17.1: Migration Context

Select ONE:

- [ ] **Greenfield** - New project, no legacy
- [ ] **Brownfield** - Existing codebase enhancement
- [ ] **Legacy Migration** - Full rewrite/refactor
- [ ] **Strangler Fig** - Incremental replacement

### Section 17.2: Migration Strategy (if applicable)

Select ONE:

- [ ] **Big Bang** - Full rewrite, cutover
- [ ] **Strangler Fig** - Incremental replacement
- [ ] **Branch by Abstraction** - Parallel implementations

---

## Article XVIII: API Management

> **📋 Applies to**: Application Development, Full Stack
> **⏭️ Skip if**: Infrastructure Only

### Section 18.1: API Gateway

Select ONE:

- [ ] **None** - Direct service access
- [ ] **Azure API Management (APIM)** - Full-featured
- [ ] **Azure Front Door** - Global routing + WAF
- [ ] **YARP** - .NET reverse proxy

### Section 18.2: API Features

| Feature        | Enabled        | Configuration                |
| -------------- | -------------- | ---------------------------- |
| Rate Limiting  | [ ] Yes [ ] No | \_\_\_ requests/minute       |
| API Versioning | [ ] Yes [ ] No | Strategy: [ ] URL [ ] Header |

### Section 18.3: API Documentation

| Type         | Tool              | Enabled        |
| ------------ | ----------------- | -------------- |
| REST API     | OpenAPI / Swagger | [ ] Yes        |
| Async Events | AsyncAPI          | [ ] Yes [ ] No |

---

## Article XVIII-A: Event-Driven Architecture & Messaging Patterns

> **📋 Applies to**: Application Development, Full Stack (service-to-service communication)
> **⏭️ Skip if**: Infrastructure Only, synchronous-only applications
> **References**: [Azure messaging services (Microsoft)](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)

**Event-Driven Architecture (EDA)** enables loosely coupled services to communicate through events, improving scalability, resilience, and independent deployment.

### Section 18A.1: Messaging Service Selection

**Azure provides 3 messaging services**:

| Service                  | Use Case                              | Message Size | Throughput                | Ordering         | Sessions             |
| ------------------------ | ------------------------------------- | ------------ | ------------------------- | ---------------- | -------------------- |
| **Azure Service Bus**    | Enterprise messaging, complex routing | Up to 100 MB | Moderate (1,000s msg/sec) | ✅ FIFO queues   | ✅ Stateful sessions |
| **Azure Event Hubs**     | Big data streaming, telemetry         | Up to 1 MB   | Very high (millions/sec)  | ✅ Partitions    | ❌ No                |
| **Azure Event Grid**     | Reactive event routing, webhooks      | Up to 1 MB   | High (10M events/sec)     | ⚠️ At-least-once | ❌ No                |
| **Azure Storage Queues** | Simple async tasks                    | Up to 64 KB  | Low-moderate              | ❌ No            | ❌ No                |

**Decision Matrix**:

- **Complex routing, dead-letter, transactions** → Azure Service Bus
- **High-volume telemetry, log streaming** → Azure Event Hubs
- **Event notifications, pub/sub fan-out** → Azure Event Grid
- **Simple queue, low cost** → Azure Storage Queues

### Section 18A.2: Messaging Patterns

#### Pattern 1: Point-to-Point (Queue)

**Use Case**: Task distribution, load leveling, decoupling producers/consumers

**Azure Implementation**: Service Bus Queue, Storage Queue

```csharp
// Producer: Send order to queue
var client = new ServiceBusClient(connectionString);
var sender = client.CreateSender("orders-queue");
await sender.SendMessageAsync(new ServiceBusMessage(JsonSerializer.Serialize(order)));

// Consumer: Process order
var receiver = client.CreateReceiver("orders-queue");
await foreach (var message in receiver.ReceiveMessagesAsync()) {
    var order = JsonSerializer.Deserialize<Order>(message.Body);
    await ProcessOrder(order);
    await receiver.CompleteMessageAsync(message); // Acknowledge
}
```

**Characteristics**:

- Single consumer per message
- Load balancing across multiple consumers
- Dead-letter queue for failed messages

#### Pattern 2: Publish/Subscribe (Topic)

**Use Case**: Event broadcasting, multiple subscribers for same event

**Azure Implementation**: Service Bus Topic + Subscriptions, Event Grid

```csharp
// Publisher: Broadcast order-created event
var sender = client.CreateSender("orders-topic");
await sender.SendMessageAsync(new ServiceBusMessage(JsonSerializer.Serialize(orderCreatedEvent)) {
    Subject = "order.created",
    ApplicationProperties = { ["OrderId"] = order.Id }
});

// Subscriber 1: Inventory service (filter: all orders)
var inventoryReceiver = client.CreateReceiver("orders-topic", "inventory-subscription");

// Subscriber 2: Notification service (filter: orders > $1000)
var notificationReceiver = client.CreateReceiver("orders-topic", "high-value-subscription");
// Subscription filter: "OrderTotal > 1000"
```

**Characteristics**:

- Multiple subscribers per message
- Subscription filters (SQL-like expressions)
- Independent consumer processing

#### Pattern 3: Event Streaming (Partition-based)

**Use Case**: Time-series data, log aggregation, IoT telemetry

**Azure Implementation**: Event Hubs

```csharp
// Producer: Stream telemetry events
var producer = new EventHubProducerClient(connectionString, eventHubName);
await producer.SendAsync(new[] {
    new EventData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(telemetryEvent1))),
    new EventData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(telemetryEvent2)))
});

// Consumer: Process stream (partition-based)
var consumer = new EventHubConsumerClient(consumerGroup, connectionString, eventHubName);
await foreach (var partition in consumer.ReadEventsAsync()) {
    var telemetry = JsonSerializer.Deserialize<TelemetryEvent>(partition.Data.Body);
    await StoreTelemetry(telemetry);
}
```

**Characteristics**:

- Ordered per partition (not globally)
- Replay capability (retain events 1-90 days)
- Consumer groups (independent read positions)

#### Pattern 4: Request-Reply (Async RPC)

**Use Case**: Asynchronous request-response over messaging

**Azure Implementation**: Service Bus with correlation ID + reply-to queue

```csharp
// Requestor
var replyQueue = "reply-queue";
var request = new ServiceBusMessage(JsonSerializer.Serialize(orderQuery)) {
    ReplyTo = replyQueue,
    CorrelationId = Guid.NewGuid().ToString()
};
await sender.SendMessageAsync(request);

var replyReceiver = client.CreateReceiver(replyQueue);
var reply = await replyReceiver.ReceiveMessageAsync();
// match reply.CorrelationId == request.CorrelationId

// Responder
var requestReceiver = client.CreateReceiver("query-queue");
var requestMsg = await requestReceiver.ReceiveMessageAsync();
var response = await ProcessQuery(requestMsg.Body);
await sender.SendMessageAsync(new ServiceBusMessage(response) {
    CorrelationId = requestMsg.CorrelationId,
    To = requestMsg.ReplyTo
});
```

### Section 18A.3: Message Delivery Guarantees

| Guarantee         | Service Bus             | Event Hubs              | Event Grid              | Storage Queues          |
| ----------------- | ----------------------- | ----------------------- | ----------------------- | ----------------------- |
| **At-most-once**  | ⚠️ PeekLock disabled    | ❌ Not supported        | ❌ Not supported        | ⚠️ Manual only          |
| **At-least-once** | ✅ PeekLock (default)   | ✅ Checkpoint-based     | ✅ Default              | ✅ Default              |
| **Exactly-once**  | ⚠️ Idempotency required | ⚠️ Idempotency required | ⚠️ Idempotency required | ⚠️ Idempotency required |

**Idempotency Strategy** (for exactly-once semantics):

```csharp
// Store message ID in database to prevent duplicate processing
public async Task<bool> ProcessMessageIdempotent(string messageId, ProcessedMessage message) {
    await using var transaction = await _db.Database.BeginTransactionAsync();

    // Check if already processed
    if (await _db.ProcessedMessages.AnyAsync(m => m.MessageId == messageId)) {
        return false; // Skip duplicate
    }

    // Process + record message ID atomically
    await ProcessOrder(message);
    await _db.ProcessedMessages.AddAsync(new ProcessedMessageRecord { MessageId = messageId });
    await _db.SaveChangesAsync();
    await transaction.CommitAsync();
    return true;
}
```

### Section 18A.4: Dead-Letter Queue Handling

**Dead-letter scenarios**:

- Message TTL expired
- Max delivery count exceeded (e.g., 10 retries)
- Explicit dead-letter by consumer (poisonous message)

**DLQ Monitoring & Recovery**:

```csharp
// Monitor DLQ for failed messages
var dlqReceiver = client.CreateReceiver("orders-queue", new ServiceBusReceiverOptions {
    SubQueue = SubQueue.DeadLetter
});

await foreach (var dlqMessage in dlqReceiver.ReceiveMessagesAsync()) {
    _logger.LogError($"DLQ: {dlqMessage.MessageId}, Reason: {dlqMessage.DeadLetterReason}");

    // Option 1: Manual intervention, fix & resubmit
    if (dlqMessage.DeadLetterReason == "ProcessingError") {
        await FixAndResubmit(dlqMessage);
    }

    // Option 2: Archive to storage for investigation
    await ArchiveToBlobStorage(dlqMessage);
    await dlqReceiver.CompleteMessageAsync(dlqMessage);
}
```

### Section 18A.5: Event Grid Routing Patterns

**Event Grid Topics** - Custom events for your application:

```csharp
// Publish custom event to Event Grid
var client = new EventGridPublisherClient(new Uri(topicEndpoint), new AzureKeyCredential(key));
await client.SendEventAsync(new EventGridEvent(
    subject: "orders/12345",
    eventType: "Order.Created",
    dataVersion: "1.0",
    data: new { OrderId = 12345, Total = 299.99 }
));
```

**System Topics** - Subscribe to Azure resource events:

- **Blob Storage**: `Microsoft.Storage.BlobCreated`, `Microsoft.Storage.BlobDeleted`
- **Azure Container Registry**: `Microsoft.ContainerRegistry.ImagePushed`
- **Resource Groups**: `Microsoft.Resources.ResourceWriteSuccess`

**Event Handlers**:

- Azure Functions (serverless)
- Logic Apps (workflow)
- Webhooks (custom HTTP endpoints)
- Event Hubs (forward to stream)
- Service Bus queues/topics (buffering)

---

## Article XVIII-B: Workflow Orchestration & Saga Patterns

> **📋 Applies to**: Complex multi-step business processes, distributed transactions
> **⏭️ Skip if**: Simple CRUD applications, stateless services only
> **References**: [Durable Functions (Microsoft)](https://learn.microsoft.com/azure/azure-functions/durable/)

**Orchestration** coordinates multiple service calls into a coherent workflow. **Saga Pattern** manages distributed transactions across services without 2PC (two-phase commit).

### Section 18B.1: Orchestration Tool Selection

| Tool                                 | Complexity | Hosting                   | Use Case                                     |
| ------------------------------------ | ---------- | ------------------------- | -------------------------------------------- |
| **Azure Durable Functions**          | Medium     | Code-first, serverless    | Developer-friendly, complex workflows, sagas |
| **Azure Logic Apps (Standard)**      | Low        | Low-code, visual designer | Citizen integrator, pre-built connectors     |
| **Azure Service Bus + Choreography** | High       | Self-managed              | Decentralized, event-driven orchestration    |
| **MassTransit Sagas** (.NET)         | High       | Self-hosted               | Advanced saga patterns, distributed systems  |

**Recommendation**:

- **Durable Functions** for code-first, complex logic
- **Logic Apps (Standard)** for low-code, connector-heavy integrations

### Section 18B.2: Durable Functions Orchestration

#### Example: Order Processing Saga

```csharp
[FunctionName("OrderSaga")]
public static async Task<OrderResult> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context) {

    var order = context.GetInput<Order>();

    try {
        // Step 1: Reserve inventory (compensatable)
        await context.CallActivityAsync("ReserveInventory", order.Items);

        // Step 2: Authorize payment (compensatable)
        var paymentId = await context.CallActivityAsync<string>("AuthorizePayment", order.PaymentDetails);

        // Step 3: Create shipment
        await context.CallActivityAsync("CreateShipment", new { order.Id, paymentId });

        return new OrderResult { Success = true, OrderId = order.Id };

    } catch (Exception ex) {
        // Compensate: Rollback in reverse order
        await context.CallActivityAsync("CancelPayment", paymentId);
        await context.CallActivityAsync("ReleaseInventory", order.Items);
        return new OrderResult { Success = false, Error = ex.Message };
    }
}
```

**Durable Functions Patterns**:

1. **Function Chaining** - Sequential activities

   ```csharp
   var result1 = await context.CallActivityAsync<string>("Step1", input);
   var result2 = await context.CallActivityAsync<int>("Step2", result1);
   return await context.CallActivityAsync<bool>("Step3", result2);
   ```

2. **Fan-Out/Fan-In** - Parallel execution, wait for all

   ```csharp
   var tasks = orders.Select(o => context.CallActivityAsync("ProcessOrder", o));
   await Task.WhenAll(tasks); // Wait for all parallel activities
   ```

3. **Async HTTP APIs** - Long-running operations

   ```csharp
   var approvalEvent = context.WaitForExternalEvent<bool>("ApprovalEvent");
   var timeout = context.CreateTimer(context.CurrentUtcDateTime.AddHours(24), CancellationToken.None);
   var winner = await Task.WhenAny(approvalEvent, timeout);
   ```

4. **Monitor** - Polling with exponential backoff

```csharp
  while (!jobComplete) {
      var status = await context.CallActivityAsync<JobStatus>("CheckJobStatus", jobId);
      if (status.IsComplete) break;
      await context.CreateTimer(context.CurrentUtcDateTime.AddMinutes(5), CancellationToken.None);
  }
```

### Section 18B.3: Saga Pattern (Distributed Transaction)

**Saga Types**:

#### Orchestration-Based Saga (Centralized)

**Orchestrator** coordinates all steps:

```csharp
[FunctionName("TravelBookingSaga")]
public static async Task<BookingResult> RunSaga(
    [OrchestrationTrigger] IDurableOrchestrationContext context) {

    var booking = context.GetInput<TravelBooking>();
    var compensations = new List<Func<Task>>();

    try {
        // Step 1: Book flight
        var flightId = await context.CallActivityAsync<string>("BookFlight", booking.Flight);
        compensations.Add(() => context.CallActivityAsync("CancelFlight", flightId));

        // Step 2: Book hotel
        var hotelId = await context.CallActivityAsync<string>("BookHotel", booking.Hotel);
        compensations.Add(() => context.CallActivityAsync("CancelHotel", hotelId));

        // Step 3: Book car rental
        var carId = await context.CallActivityAsync<string>("BookCar", booking.Car);
        compensations.Add(() => context.CallActivityAsync("CancelCar", carId));

        return new BookingResult { Success = true, ConfirmationId = Guid.NewGuid() };

    } catch (Exception ex) {
        // Execute compensations in reverse order
        compensations.Reverse();
        foreach (var compensate in compensations) {
            await compensate();
        }
        return new BookingResult { Success = false, Error = ex.Message };
    }
}
```

#### Choreography-Based Saga (Decentralized)

**Events** coordinate services (no central orchestrator):

```text
Order Service: Publishes "OrderCreated" event
  ↓
Inventory Service: Subscribes → Reserves stock → Publishes "InventoryReserved"
  ↓
Payment Service: Subscribes → Charges card → Publishes "PaymentCompleted"
  ↓
Shipping Service: Subscribes → Creates shipment

If Payment fails → Publishes "PaymentFailed"
  ↓
Inventory Service: Subscribes → Releases stock → Publishes "InventoryReleased"
```

**Comparison**:

| Aspect               | Orchestration Saga              | Choreography Saga               |
| -------------------- | ------------------------------- | ------------------------------- |
| **Coordination**     | Central orchestrator            | Event-driven, distributed       |
| **Complexity**       | Easier to understand            | Harder to debug                 |
| **Coupling**         | Orchestrator knows all services | Services independent            |
| **Failure Handling** | Centralized compensation        | Distributed compensation events |
| **Tooling**          | Durable Functions, Logic Apps   | Service Bus + event handlers    |

**Recommendation**: Use **Orchestration** for complex business logic, **Choreography** for high autonomy.

### Section 18B.4: Logic Apps Standard Workflow

#### Example: Invoice Processing Workflow

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "actions": {
      "Parse_PDF_Invoice": {
        "type": "ApiConnection",
        "inputs": {
          "host": { "connection": { "name": "@parameters('$connections')['formrecognizer']" } },
          "method": "post",
          "path": "/formrecognizer/v2.1/prebuilt/invoice/analyze"
        }
      },
      "Check_Approval_Threshold": {
        "type": "If",
        "expression": { "greater": ["@body('Parse_PDF_Invoice')?['total']", 10000] },
        "actions": {
          "Send_Approval_Email": {
            "type": "ApiConnection",
            "inputs": {
              "host": { "connection": { "name": "@parameters('$connections')['office365']" } },
              "method": "post",
              "path": "/approvalmail"
            }
          }
        }
      },
      "Create_ERP_Invoice": {
        "type": "Http",
        "inputs": {
          "method": "POST",
          "uri": "https://erp.company.com/api/invoices",
          "body": "@body('Parse_PDF_Invoice')"
        }
      }
    },
    "triggers": {
      "When_a_blob_is_added": {
        "type": "ApiConnection",
        "inputs": {
          "host": { "connection": { "name": "@parameters('$connections')['azureblob']" } },
          "method": "get",
          "path": "/datasets/default/triggers/batch/onupdatedfile"
        }
      }
    }
  }
}
```

**Logic Apps Connectors** (400+ pre-built):

- **Azure**: Blob Storage, Service Bus, Cosmos DB, SQL Database
- **Microsoft 365**: Outlook, Teams, SharePoint, Excel
- **SAP**: SAP ERP, SAP S/4HANA
- **Salesforce, Dynamics 365, ServiceNow**

---

## Article XVIII-C: Schema Validation & Contract Testing

> **📋 Applies to**: Microservices, event-driven architectures, multi-team development
> **⏭️ Skip if**: Monolithic applications, single-team projects
> **References**: [Azure Schema Registry (Microsoft)](https://learn.microsoft.com/azure/event-hubs/schema-registry-overview)

**Schema Registry** ensures producers and consumers agree on message format, preventing breaking changes.

### Section 18C.1: Azure Schema Registry (Event Hubs)

**Supported Formats**:

- **Avro** - Binary, schema evolution, compact
- **JSON Schema** - Human-readable, JSON-based
- **Protobuf** - Google Protocol Buffers (future support)

**Schema Evolution Rules**:

| Change             | Compatible?            | Strategy                                         |
| ------------------ | ---------------------- | ------------------------------------------------ |
| Add optional field | ✅ Forward compatible  | Consumers ignore unknown fields                  |
| Remove field       | ⚠️ Backward compatible | Producers stop sending, consumers handle missing |
| Rename field       | ❌ Breaking change     | Deploy new schema version                        |
| Change field type  | ❌ Breaking change     | Deploy new schema version                        |

**Example: Avro Schema Registration**:

```csharp
// Register schema
var schemaRegistryClient = new SchemaRegistryClient(
    endpoint: "namespace.servicebus.windows.net",
    credential: new DefaultAzureCredential());

var schemaContent = @"{
    ""type"": ""record"",
    ""name"": ""Order"",
    ""namespace"": ""com.example"",
    ""fields"": [
        {""name"": ""orderId"", ""type"": ""string""},
        {""name"": ""total"", ""type"": ""double""},
        {""name"": ""customerId"", ""type"": [""null"", ""string""], ""default"": null}
    ]
}";

var schemaProperties = await schemaRegistryClient.RegisterSchemaAsync(
    groupName: "orders-group",
    schemaName: "Order",
    schemaDefinition: schemaContent,
    format: SchemaFormat.Avro);

// Produce message with schema validation
var producer = new EventHubProducerClient(connectionString, eventHubName);
var encoder = new SchemaRegistryAvroSerializer(schemaRegistryClient);

var order = new Order { OrderId = "12345", Total = 299.99, CustomerId = "C001" };
var eventData = new EventData(await encoder.SerializeAsync(order, messageType: typeof(Order)));
eventData.ContentType = "avro/binary+schemaId";
await producer.SendAsync(new[] { eventData });

// Consumer with automatic deserialization
var consumer = new EventHubConsumerClient(consumerGroup, connectionString, eventHubName);
await foreach (var partitionEvent in consumer.ReadEventsAsync()) {
    var order = await encoder.DeserializeAsync<Order>(partitionEvent.Data.Body);
    Console.WriteLine($"Order {order.OrderId}: ${order.Total}");
}
```

### Section 18C.2: Consumer-Driven Contract Testing (Pact)

**Pact** validates that API providers (producers) meet consumer expectations.

**Consumer Test** (defines contract):

```csharp
[Fact]
public async Task GetOrder_ReturnsOrder() {
    // Arrange: Define expected interaction
    _pact
        .UponReceiving("A request for order 12345")
            .Given("Order 12345 exists")
            .WithRequest(HttpMethod.Get, "/api/orders/12345")
        .WillRespond()
            .WithStatus(HttpStatusCode.OK)
            .WithHeader("Content-Type", "application/json")
            .WithJsonBody(new {
                orderId = "12345",
                total = 299.99,
                status = "Completed"
            });

    // Act: Call mock provider
    await _pact.VerifyAsync(async ctx => {
        var client = new HttpClient { BaseAddress = ctx.MockServerUri };
        var response = await client.GetAsync("/api/orders/12345");
        var order = await response.Content.ReadFromJsonAsync<Order>();

        // Assert
        Assert.Equal("12345", order.OrderId);
        Assert.Equal(299.99, order.Total);
    });
}
```

**Provider Test** (validates producer honors contract):

```csharp
[Fact]
public void EnsureProviderHonorsContract() {
    var config = new PactVerifierConfig {
        ProviderName = "OrderService",
        PactUri = new Uri("https://pact-broker.company.com/pacts/provider/OrderService/consumer/FrontendApp/latest")
    };

    IPactVerifier verifier = new PactVerifier(config);
    verifier
        .ServiceProvider("OrderService", "https://localhost:5001")
        .HonoursPactWith("FrontendApp")
        .PactUri("pact-broker.company.com/pacts/.../latest")
        .Verify();
}
```

**Pact Workflow**:

1. Consumer writes contract test → Generates Pact file (JSON)
2. Upload Pact to Pact Broker
3. Provider CI pipeline pulls Pact → Runs verification
4. If verification fails → Provider must fix or negotiate new contract

### Section 18C.3: API Versioning Strategy

| Strategy                | Example                                   | Pros                   | Cons                 |
| ----------------------- | ----------------------------------------- | ---------------------- | -------------------- |
| **URL Path**            | `/api/v1/orders`, `/api/v2/orders`        | Explicit, easy routing | URL proliferation    |
| **Header**              | `Api-Version: 2.0`                        | Clean URLs             | Hidden from browsers |
| **Query String**        | `/api/orders?version=2`                   | Simple                 | Cache issues         |
| **Content Negotiation** | `Accept: application/vnd.company.v2+json` | RESTful                | Complex              |

**Azure API Management Versioning**:

```bicep
resource apiVersion 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  name: 'orders-api-versions'
  parent: apimService
  properties: {
    displayName: 'Orders API'
    versioningScheme: 'Segment' // URL path: /v1/orders, /v2/orders
  }
}

resource apiV1 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  name: 'orders-api-v1'
  parent: apimService
  properties: {
    displayName: 'Orders API v1'
    apiVersion: '1.0'
    apiVersionSetId: apiVersion.id
    path: 'orders'
  }
}
```

---

## Article XVIII-D: Hybrid Integration & Connectivity

> **📋 Applies to**: Hybrid cloud, on-premises connectivity, multi-cloud integration
> **⏭️ Skip if**: Cloud-only applications
> **References**: [Azure Arc (Microsoft)](https://learn.microsoft.com/azure/azure-arc/overview)

**Hybrid Integration** connects Azure services with on-premises systems without exposing them to the internet.

### Section 18D.1: Connectivity Options

| Service                | Use Case                                  | Direction                           | Latency             | Throughput     |
| ---------------------- | ----------------------------------------- | ----------------------------------- | ------------------- | -------------- |
| **Azure Relay**        | Expose on-prem HTTP/WS endpoints to Azure | Outbound only (no firewall changes) | Low                 | Low-moderate   |
| **Azure VPN Gateway**  | Site-to-site VPN                          | Bidirectional                       | Moderate (internet) | Up to 10 Gbps  |
| **Azure ExpressRoute** | Private connection (no internet)          | Bidirectional                       | Very low            | Up to 100 Gbps |
| **Azure Arc**          | Manage on-prem resources from Azure       | Control plane only                  | N/A                 | N/A            |

### Section 18D.2: Azure Relay Hybrid Connections

**Use Case**: Call on-premises HTTP API from Azure Logic App/Function without VPN

```csharp
// On-premises listener (behind corporate firewall)
var listener = new HybridConnectionListener(new Uri(hybridConnectionUri), tokenProvider);
listener.RequestHandler = async (context) => {
    // Receive request from Azure
    var requestBody = await new StreamReader(context.Request.InputStream).ReadToEndAsync();

    // Call internal API (on-premises)
    var internalResponse = await CallInternalApi(requestBody);

    // Send response back to Azure
    context.Response.StatusCode = HttpStatusCode.OK;
    await context.Response.OutputStream.WriteAsync(Encoding.UTF8.GetBytes(internalResponse));
    context.Response.Close();
};
await listener.OpenAsync();

// Azure Logic App (cloud)
{
  "actions": {
    "Call_OnPrem_API": {
      "type": "Http",
      "inputs": {
        "method": "POST",
        "uri": "https://namespace.servicebus.windows.net/hybrid-connection-name",
        "body": "@triggerBody()",
        "authentication": {
          "type": "ManagedServiceIdentity"
        }
      }
    }
  }
}
```

**Benefits**:

- No inbound firewall rules required
- No public IP exposure
- TLS encrypted tunnel

### Section 18D.3: Azure API Management Self-Hosted Gateway

**Use Case**: Deploy API Management gateway on-premises to cache responses, apply policies locally

```bash
# Deploy self-hosted gateway in Kubernetes
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apim-gateway
spec:
  replicas: 3
  selector:
    matchLabels:
      app: apim-gateway
  template:
    metadata:
      labels:
        app: apim-gateway
    spec:
      containers:
      - name: apim-gateway
        image: mcr.microsoft.com/azure-api-management/gateway:2.6
        env:
        - name: config.service.endpoint
          value: "apim-instance.configuration.azure-api.net/subscriptions/.../gateways/onprem-gateway"
        - name: config.service.auth
          valueFrom:
            secretKeyRef:
              name: apim-gateway-token
              key: value
EOF
```

**Capabilities**:

- Local policy enforcement (rate limiting, JWT validation)
- Response caching (reduce latency)
- Sync configuration from Azure APIM portal

### Section 18D.4: Azure Arc-enabled Services

**Arc-enabled Kubernetes**: Manage on-prem K8s clusters from Azure

```bash
# Connect on-premises Kubernetes cluster to Azure Arc
az connectedk8s connect \
  --name onprem-k8s-cluster \
  --resource-group rg-arc \
  --location eastus

# Deploy GitOps config to on-prem cluster from Azure
az k8s-configuration flux create \
  --cluster-name onprem-k8s-cluster \
  --resource-group rg-arc \
  --name nginx-ingress \
  --namespace cluster-config \
  --scope cluster \
  --url https://github.com/company/k8s-config \
  --branch main \
  --kustomization name=nginx path=./kustomizations/nginx
```

**Arc-enabled Data Services**: Run Azure SQL Managed Instance on-premises

- Azure portal management for on-prem databases
- Azure Monitor/Log Analytics integration
- Elastic scaling on-premises

---

## Article XVIII-E: Integration Observability & Distributed Tracing

> **📋 Applies to**: Microservices, event-driven architectures, multi-service workflows
> **⏭️ Skip if**: Monolithic applications
> **References**: [Distributed tracing (Microsoft)](https://learn.microsoft.com/azure/azure-monitor/app/distributed-tracing-telemetry-correlation)

**Distributed Tracing** tracks requests across service boundaries, enabling root cause analysis in complex systems.

### Section 18E.1: W3C Trace Context Standard

**HTTP Headers** propagate trace context:

```text
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             ^^  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^  ^^
             ver trace-id (32 hex)                 span-id (16 hex)  flags
```

**Implementation** (.NET):

```csharp
// Automatically propagated by Application Insights SDK
public async Task<IActionResult> PlaceOrder([FromBody] Order order) {
    // Current trace context automatically available
    var activity = Activity.Current;
    _logger.LogInformation($"Processing order {order.Id}, TraceId: {activity?.TraceId}");

    // HTTP call to Inventory Service → traceparent header auto-injected
    var inventoryResponse = await _httpClient.PostAsync("https://inventory/api/reserve", ...);

    // Publish message to Service Bus → Diagnostic-Id property auto-added
    await _serviceBusSender.SendMessageAsync(new ServiceBusMessage(...));

    return Ok();
}
```

**Node.js (OpenTelemetry)**:

```javascript
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const { AzureMonitorTraceExporter } = require('@azure/monitor-opentelemetry-exporter');

const provider = new NodeTracerProvider();
provider.addSpanProcessor(
  new BatchSpanProcessor(
    new AzureMonitorTraceExporter({
      connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
    })
  )
);
provider.register();

registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation(), // Auto-instrument HTTP calls
  ],
});
```

### Section 18E.2: Application Insights Application Map

**Automatically visualizes** service dependencies:

```text
   [Frontend]
       │
       ├─> [Order API] ──┐
       │       │         │
       │       ├─> [SQL Database]
       │       │
       │       └─> [Service Bus: orders-queue]
       │                   │
       │                   └─> [Inventory API]
       │                           │
       │                           └─> [Inventory DB]
       │
       └─> [Payment API]
               │
               └─> [External Payment Gateway]
```

**Configuration** (automatic with Application Insights SDK):

```json
// appsettings.json
{
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=...;IngestionEndpoint=https://.../"
  }
}
```

### Section 18E.3: End-to-End Transaction Tracking

**Correlation across messaging** (Service Bus):

```csharp
// Producer: Set CorrelationId
await sender.SendMessageAsync(new ServiceBusMessage(body) {
    CorrelationId = Activity.Current?.Id, // W3C trace context
    ApplicationProperties = {
        ["ParentSpanId"] = Activity.Current?.SpanId.ToString()
    }
});

// Consumer: Continue trace context
var receiver = client.CreateReceiver("orders-queue");
await foreach (var message in receiver.ReceiveMessagesAsync()) {
    // Restore trace context from message
    var parentSpanId = message.ApplicationProperties["ParentSpanId"]?.ToString();
    using var activity = new Activity("ProcessOrder")
        .SetParentId(ActivityTraceId.CreateFromString(message.CorrelationId), ActivitySpanId.CreateFromString(parentSpanId));
    activity.Start();

    await ProcessOrder(message.Body);
    activity.Stop();
}
```

### Section 18E.4: KQL Queries for Integration Monitoring

**Find slow dependencies**:

```kusto
dependencies
| where timestamp > ago(1h)
| where duration > 1000  // > 1 second
| summarize
    Count = count(),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99)
    by target, name
| order by P95 desc
```

**Trace request across services**:

```kusto
let traceId = "4bf92f3577b34da6a3ce929d0e0e4736";
union requests, dependencies
| where operation_Id == traceId
| project
    timestamp,
    itemType,
    name,
    target,
    duration,
    success,
    resultCode
| order by timestamp asc
```

**Message processing lag** (Event Hubs):

```kusto
customMetrics
| where name == "EventHub.ProcessingLag"
| summarize AvgLag = avg(value) by bin(timestamp, 5m), cloud_RoleName
| render timechart
```

### Section 18E.5: Integration Health Checks

**Custom health check** (ASP.NET Core):

```csharp
public class ServiceBusHealthCheck : IHealthCheck {
    private readonly ServiceBusClient _client;

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context) {
        try {
            var receiver = _client.CreateReceiver("orders-queue");
            await receiver.PeekMessageAsync(); // Test connectivity
            return HealthCheckResult.Healthy("Service Bus reachable");
        } catch (Exception ex) {
            return HealthCheckResult.Unhealthy("Service Bus unreachable", ex);
        }
    }
}

// Startup.cs
services.AddHealthChecks()
    .AddCheck<ServiceBusHealthCheck>("servicebus")
    .AddCheck<EventHubHealthCheck>("eventhub")
    .AddCheck<CosmosDbHealthCheck>("cosmosdb");

app.MapHealthChecks("/health", new HealthCheckOptions {
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse // JSON response
});
```

---

## Article XIX: Governance 🔄

> **📋 Applies to**: ALL project types

### Section 19.1: Constitution Amendments

1. **Proposal**: Any team member may propose amendments
2. **Review**: Tech Lead + Architect review required
3. **Approval**: Majority approval from signatories
4. **Implementation**: Update constitution + notify AI agents
5. **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)

### Section 19.2: AI Agent Compliance

All AI agents operating in this project MUST:

1. **Read** this constitution before any operation
2. **Validate** all decisions against constitution principles
3. **FAIL** operations that violate constitution
4. **Request** amendment for justified exceptions
5. **Log** all constitution checks for audit

---

## Signatories

| Role         | Name   | Date   | Signature |
| ------------ | ------ | ------ | --------- |
| Project Lead | [NAME] | [DATE] |           |
| Tech Lead    | [NAME] | [DATE] |           |
| Architect    | [NAME] | [DATE] |           |

---

## Revision History

| Version | Date       | Author              | Changes                                                                                                                                                                                                                                                               |
| ------- | ---------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.0.0   | 2026-02-27 | Bolt Framework Team | Added Article XVIII-A (Event-Driven Architecture), XVIII-B (Workflow Orchestration & Sagas), XVIII-C (Schema Validation & Contract Testing), XVIII-D (Hybrid Integration), XVIII-E (Integration Observability) with comprehensive Azure Integration Services coverage |
| 2.1.0   | [DATE]     | [AUTHOR]            | Added Project Scope (App/Infra/Full Stack), Landing Zone templates, Infrastructure testing                                                                                                                                                                            |
| 2.0.0   | [DATE]     | [AUTHOR]            | Complete rewrite with C#/Node.js options                                                                                                                                                                                                                              |
| 1.0.0   | [DATE]     | [AUTHOR]            | Initial constitution                                                                                                                                                                                                                                                  |
