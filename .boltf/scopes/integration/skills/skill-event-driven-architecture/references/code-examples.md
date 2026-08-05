# Event-Driven Architecture - Code Examples

## 1. Azure Event Hubs - High-Throughput Event Streaming (C#)

```csharp
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;

// Producer: Send events at high throughput (millions/sec)
var producerClient = new EventHubProducerClient(connectionString, eventHubName);

using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

for (int i = 0; i < 1000; i++)
{
    var eventData = new EventData($"{{\"sensorId\": {i}, \"temperature\": {20 + i % 10}, \"timestamp\": \"{DateTime.UtcNow:o}\"}}");

    if (!eventBatch.TryAdd(eventData))
    {
        // Batch full, send current batch and create new one
        await producerClient.SendAsync(eventBatch);
        eventBatch.Dispose();
        eventBatch = await producerClient.CreateBatchAsync();
        eventBatch.TryAdd(eventData);
    }
}

await producerClient.SendAsync(eventBatch);

// Consumer: Process events with checkpointing (Event Processor Host)
var storageClient = new BlobContainerClient(storageConnectionString, "eventhub-checkpoints");
var processor = new EventProcessorClient(storageClient, consumerGroup, connectionString, eventHubName);

processor.ProcessEventAsync += async (args) =>
{
    string eventBody = args.Data.EventBody.ToString();
    Console.WriteLine($"Partition {args.Partition.PartitionId}: {eventBody}");

    // Process event (idempotent handling for at-least-once delivery)
    await ProcessEventAsync(eventBody);

    // Checkpoint: save progress (allows recovery on failure)
    await args.UpdateCheckpointAsync();
};

processor.ProcessErrorAsync += (args) =>
{
    Console.WriteLine($"Error on partition {args.PartitionId}: {args.Exception.Message}");
    return Task.CompletedTask;
};

await processor.StartProcessingAsync();
await Task.Delay(TimeSpan.FromMinutes(5));  // Process for 5 minutes
await processor.StopProcessingAsync();
```

## 2. Azure Service Bus - Reliable Messaging with Queues (Python)

```python
from azure.servicebus import ServiceBusClient, ServiceBusMessage
from azure.servicebus import ServiceBusReceiveMode
import json
import time

# Send message to queue (FIFO with deduplication)
with ServiceBusClient.from_connection_string(connection_string) as client:
    with client.get_queue_sender(queue_name="orders") as sender:
        message = ServiceBusMessage(
            body=json.dumps({
                "orderId": "12345",
                "customerId": "C-001",
                "amount": 599.99,
                "items": [{"productId": "P-101", "quantity": 2}]
            }),
            message_id="order-12345",  # Deduplication ID
            session_id="customer-C-001",  # Session for ordered processing
            time_to_live=timedelta(hours=24)  # Expire after 24h
        )

        # Custom properties for filtering
        message.application_properties = {
            "priority": "high",
            "region": "us-west"
        }

        sender.send_messages(message)
        print("Message sent to queue")

# Receive and process messages (peek-lock pattern)
with ServiceBusClient.from_connection_string(connection_string) as client:
    with client.get_queue_receiver(
        queue_name="orders",
        receive_mode=ServiceBusReceiveMode.PEEK_LOCK,  # Lock message during processing
        max_wait_time=30
    ) as receiver:

        for message in receiver:
            try:
                body = json.loads(str(message))
                print(f"Processing order: {body['orderId']}")

                # Process order (may take time, message locked for 60s)
                process_order(body)

                # Complete message (removes from queue)
                receiver.complete_message(message)

            except Exception as e:
                print(f"Error processing: {e}")
                # Abandon message (returns to queue, increments delivery count)
                receiver.abandon_message(message)

                # Alternative: Dead-letter message (requires admin investigation)
                # receiver.dead_letter_message(message, reason="ProcessingError", error_description=str(e))

# Dead-letter queue processing (handle failed messages)
with ServiceBusClient.from_connection_string(connection_string) as client:
    with client.get_queue_receiver(
        queue_name="orders/$deadletterqueue"  # Built-in DLQ
    ) as dlq_receiver:
        for message in dlq_receiver:
            print(f"Dead-letter: {message} | Reason: {message.dead_letter_reason}")
            # Log, alert, or retry with backoff
            dlq_receiver.complete_message(message)
```

## 3. Service Bus Topics and Subscriptions - Pub/Sub Pattern (C#)

```csharp
using Azure.Messaging.ServiceBus;

var client = new ServiceBusClient(connectionString);

// Publisher: Send to topic (one message, multiple subscribers)
var sender = client.CreateSender("order-events");

var message = new ServiceBusMessage(new BinaryData(JsonSerializer.Serialize(new
{
    EventType = "OrderPlaced",
    OrderId = "12345",
    CustomerId = "C-001",
    Amount = 599.99,
    Timestamp = DateTime.UtcNow
})))
{
    Subject = "OrderPlaced",  // For subscription filtering
    ApplicationProperties =
    {
        ["region"] = "us-west",
        ["priority"] = "high"
    }
};

await sender.SendMessageAsync(message);

// Subscriber 1: Email service (filter by event type)
// Subscription created with SQL filter: "Subject = 'OrderPlaced'"
var emailReceiver = client.CreateProcessor("order-events", "email-subscription");

emailReceiver.ProcessMessageAsync += async args =>
{
    var order = JsonSerializer.Deserialize<OrderEvent>(args.Message.Body);
    Console.WriteLine($"📧 Sending confirmation email for order {order.OrderId}");
    await SendEmailAsync(order.CustomerId, order.OrderId);
    await args.CompleteMessageAsync(args.Message);
};

await emailReceiver.StartProcessingAsync();

// Subscriber 2: Analytics service (filter by region)
// Subscription created with SQL filter: "region = 'us-west'"
var analyticsReceiver = client.CreateProcessor("order-events", "analytics-subscription");

analyticsReceiver.ProcessMessageAsync += async args =>
{
    var order = JsonSerializer.Deserialize<OrderEvent>(args.Message.Body);
    Console.WriteLine($"📊 Logging order {order.OrderId} to analytics");
    await LogToAnalyticsAsync(order);
    await args.CompleteMessageAsync(args.Message);
};

await analyticsReceiver.StartProcessingAsync();

// Subscriber 3: Inventory service (all messages)
var inventoryReceiver = client.CreateProcessor("order-events", "inventory-subscription");

inventoryReceiver.ProcessMessageAsync += async args =>
{
    var order = JsonSerializer.Deserialize<OrderEvent>(args.Message.Body);
    Console.WriteLine($"📦 Updating inventory for order {order.OrderId}");
    await UpdateInventoryAsync(order.Items);
    await args.CompleteMessageAsync(args.Message);
};

await inventoryReceiver.StartProcessingAsync();
```

## 4. Azure Event Grid - Reactive Event Routing (Python)

```python
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from azure.core.credentials import AzureKeyCredential

# Publisher: Send domain events
endpoint = "https://my-eventgrid-topic.westus-1.eventgrid.azure.net/api/events"
credential = AzureKeyCredential(access_key)
client = EventGridPublisherClient(endpoint, credential)

events = [
    EventGridEvent(
        event_type="Contoso.BlobStorage.BlobCreated",
        data={
            "api": "PutBlob",
            "requestId": "abc-123",
            "contentType": "application/pdf",
            "url": "https://mystorage.blob.core.windows.net/documents/invoice.pdf",
            "size": 12345
        },
        subject="/documents/invoice.pdf",
        data_version="1.0"
    ),
    EventGridEvent(
        event_type="Contoso.Orders.OrderShipped",
        data={
            "orderId": "12345",
            "trackingNumber": "1Z999AA10123456784",
            "carrier": "UPS",
            "estimatedDelivery": "2024-03-15"
        },
        subject="/orders/12345",
        data_version="2.0"
    )
]

client.send(events)
print("Events published to Event Grid")

# Subscriber: Azure Function triggered by Event Grid
# Function.json subscription filter:
{
  "bindings": [
    {
      "type": "eventGridTrigger",
      "name": "eventGridEvent",
      "direction": "in"
    }
  ]
}

# Function code (Python):
import logging
import json
import azure.functions as func

def main(eventGridEvent: func.EventGridEvent):
    event_data = eventGridEvent.get_json()

    if eventGridEvent.event_type == "Contoso.BlobStorage.BlobCreated":
        logging.info(f"New blob: {event_data['url']}, size: {event_data['size']}")
        # Process document (OCR, indexing, etc.)
        process_document(event_data['url'])

    elif eventGridEvent.event_type == "Contoso.Orders.OrderShipped":
        logging.info(f"Order {event_data['orderId']} shipped via {event_data['carrier']}")
        # Send notification to customer
        notify_customer(event_data['orderId'], event_data['trackingNumber'])
```

## 5. Event Sourcing Pattern with Cosmos DB (C#)

```csharp
using Microsoft.Azure.Cosmos;

// Event store: immutable append-only log
public record OrderEvent(
    string EventId,
    string AggregateId,  // Order ID
    string EventType,
    DateTime Timestamp,
    int Version,  // For optimistic concurrency
    object Data
);

// Append event (never update, only insert)
public async Task AppendEventAsync(OrderEvent @event)
{
    var container = cosmosClient.GetContainer("EventStore", "Orders");

    // Partition by AggregateId for sequential read of order history
    await container.CreateItemAsync(@event, new PartitionKey(@event.AggregateId));
}

// Example events
await AppendEventAsync(new OrderEvent(
    Guid.NewGuid().ToString(),
    "order-12345",
    "OrderPlaced",
    DateTime.UtcNow,
    1,
    new { CustomerId = "C-001", TotalAmount = 599.99 }
));

await AppendEventAsync(new OrderEvent(
    Guid.NewGuid().ToString(),
    "order-12345",
    "PaymentProcessed",
    DateTime.UtcNow,
    2,
    new { PaymentMethod = "CreditCard", TransactionId = "txn-999" }
));

await AppendEventAsync(new OrderEvent(
    Guid.NewGuid().ToString(),
    "order-12345",
    "OrderShipped",
    DateTime.UtcNow,
    3,
    new { TrackingNumber = "1Z999AA10123456784", Carrier = "UPS" }
));

// Rebuild aggregate from events (event sourcing)
public async Task<Order> RehydrateOrderAsync(string orderId)
{
    var container = cosmosClient.GetContainer("EventStore", "Orders");

    var query = new QueryDefinition("SELECT * FROM c WHERE c.AggregateId = @orderId ORDER BY c.Version")
        .WithParameter("@orderId", orderId);

    var order = new Order { OrderId = orderId };

    using var iterator = container.GetItemQueryIterator<OrderEvent>(query, requestOptions: new QueryRequestOptions
    {
        PartitionKey = new PartitionKey(orderId)
    });

    while (iterator.HasMoreResults)
    {
        foreach (var @event in await iterator.ReadNextAsync())
        {
            // Apply event to rebuild state
            order = @event.EventType switch
            {
                "OrderPlaced" => order with { Status = "Placed", TotalAmount = ((dynamic)@event.Data).TotalAmount },
                "PaymentProcessed" => order with { Status = "Paid" },
                "OrderShipped" => order with { Status = "Shipped", TrackingNumber = ((dynamic)@event.Data).TrackingNumber },
                _ => order
            };
        }
    }

    return order;
}

// Read model (projection) updated via Change Feed
var processor = container.GetChangeFeedProcessorBuilder<OrderEvent>("order-projections", async (changes, cancellationToken) =>
{
    foreach (var @event in changes)
    {
        // Update read-optimized views (CQRS)
        await UpdateOrderSummaryAsync(@event);
        await UpdateCustomerOrderHistoryAsync(@event);
    }
})
.WithInstanceName("order-processor-1")
.WithLeaseContainer(leaseContainer)
.Build();

await processor.StartAsync();
```

## 6. Saga Pattern with Dapr Workflow (Python)

```python
from dapr.ext.workflow import WorkflowRuntime, DaprWorkflowContext, WorkflowActivityContext
from dapr.clients import DaprClient

# Saga activities (compensating transactions)
def reserve_inventory(ctx: WorkflowActivityContext, order_id: str):
    print(f"Reserving inventory for {order_id}")
    # Call inventory service API
    return {"reservationId": "inv-123", "orderId": order_id}

def charge_payment(ctx: WorkflowActivityContext, payment_info: dict):
    print(f"Charging payment for order {payment_info['orderId']}")
    # Call payment service API
    return {"transactionId": "txn-456", "orderId": payment_info['orderId']}

def ship_order(ctx: WorkflowActivityContext, order_id: str):
    print(f"Shipping order {order_id}")
    # Call shipping service API
    return {"trackingNumber": "1Z999AA", "orderId": order_id}

# Compensating activities (rollback)
def cancel_reservation(ctx: WorkflowActivityContext, reservation_id: str):
    print(f"Canceling reservation {reservation_id}")
    # Undo inventory reservation

def refund_payment(ctx: WorkflowActivityContext, transaction_id: str):
    print(f"Refunding payment {transaction_id}")
    # Undo payment charge

# Saga workflow (orchestration with compensation)
def order_saga(ctx: DaprWorkflowContext, order: dict):
    reservation_id = None
    transaction_id = None

    try:
        # Step 1: Reserve inventory
        reservation = yield ctx.call_activity(reserve_inventory, input=order['orderId'])
        reservation_id = reservation['reservationId']

        # Step 2: Charge payment
        payment = yield ctx.call_activity(charge_payment, input=order)
        transaction_id = payment['transactionId']

        # Step 3: Ship order
        shipment = yield ctx.call_activity(ship_order, input=order['orderId'])

        return {"status": "Success", "trackingNumber": shipment['trackingNumber']}

    except Exception as e:
        # Compensation: rollback in reverse order
        if transaction_id:
            yield ctx.call_activity(refund_payment, input=transaction_id)
        if reservation_id:
            yield ctx.call_activity(cancel_reservation, input=reservation_id)

        return {"status": "Failed", "error": str(e)}

# Start workflow
with DaprClient() as client:
    instance_id = client.start_workflow(
        workflow_component="dapr",
        workflow_name="order_saga",
        input={"orderId": "12345", "amount": 599.99}
    )

    # Wait for completion
    result = client.wait_for_workflow_completion(instance_id)
    print(f"Workflow {instance_id} completed: {result}")
```

## 7. Azure Functions with Event Hub Trigger (JavaScript)

```javascript
// Function.json
{
  "bindings": [
    {
      "type": "eventHubTrigger",
      "name": "eventHubMessages",
      "direction": "in",
      "eventHubName": "telemetry",
      "connection": "EventHubConnectionString",
      "cardinality": "many",
      "consumerGroup": "$Default"
    },
    {
      "type": "cosmosDB",
      "name": "outputDocument",
      "direction": "out",
      "databaseName": "TelemetryDB",
      "collectionName": "ProcessedEvents",
      "connectionStringSetting": "CosmosDBConnectionString"
    }
  ]
}

// index.js
module.exports = async function (context, eventHubMessages) {
    context.log(`Processing ${eventHubMessages.length} events`);

    const processedData = eventHubMessages.map(event => {
        const telemetry = JSON.parse(event);

        return {
            id: telemetry.sensorId + "-" + Date.now(),
            sensorId: telemetry.sensorId,
            temperature: telemetry.temperature,
            timestamp: telemetry.timestamp,
            processedAt: new Date().toISOString(),
            alert: telemetry.temperature > 80 ? "HIGH_TEMP" : null
        };
    });

    // Output binding writes to Cosmos DB
    context.bindings.outputDocument = processedData;

    // Send alerts for high temperature
    const alerts = processedData.filter(d => d.alert === "HIGH_TEMP");
    if (alerts.length > 0) {
        context.log(`⚠️ ${alerts.length} high temperature alerts`);
        // Trigger alert notification (Service Bus, SignalR, etc.)
    }
};
```

## 8. Competing Consumers Pattern (C#)

```csharp
// Multiple instances processing messages from queue in parallel
// Azure Service Bus handles load distribution automatically

public class OrderProcessorWorker : BackgroundService
{
    private readonly ServiceBusProcessor _processor;

    public OrderProcessorWorker(IConfiguration config)
    {
        var client = new ServiceBusClient(config["ServiceBus:ConnectionString"]);
        _processor = client.CreateProcessor("orders", new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 10,  // Process 10 messages concurrently per instance
            AutoCompleteMessages = false,
            PrefetchCount = 20  // Pre-fetch for throughput
        });

        _processor.ProcessMessageAsync += ProcessMessageAsync;
        _processor.ProcessErrorAsync += ErrorHandlerAsync;
    }

    private async Task ProcessMessageAsync(ProcessMessageEventArgs args)
    {
        var orderId = args.Message.Body.ToString();
        var lockToken = args.Message.LockToken;

        try
        {
            // Simulate processing (5-10 seconds)
            Console.WriteLine($"[Worker {Environment.MachineName}] Processing {orderId}");
            await Task.Delay(TimeSpan.FromSeconds(Random.Shared.Next(5, 10)));

            // Complete message (remove from queue)
            await args.CompleteMessageAsync(args.Message);
            Console.WriteLine($"[Worker {Environment.MachineName}] Completed {orderId}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Worker {Environment.MachineName}] Failed {orderId}: {ex.Message}");

            // Abandon: message returns to queue (retry)
            await args.AbandonMessageAsync(args.Message);
        }
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _processor.StartProcessingAsync(stoppingToken);
        await Task.Delay(Timeout.Infinite, stoppingToken);
    }
}

// Deploy multiple instances (scale out):
// - Azure App Service: scale to 5 instances = 50 concurrent messages (10 per instance)
// - Azure Container Apps: scale rule on queue length (0-100 instances)
// - Azure Kubernetes: HPA based on Service Bus queue metrics
```

---

**Key Patterns:**

- **High-throughput streaming**: Event Hubs (millions events/sec, partitioned)
- **Reliable messaging**: Service Bus queues/topics (FIFO, deduplication, dead-letter)
- **Reactive routing**: Event Grid (pub/sub, filter, fan-out)
- **Event sourcing**: Cosmos DB Change Feed (append-only event log)
- **Saga orchestration**: Dapr Workflow (compensating transactions)
- **Competing consumers**: Service Bus + multiple workers (parallel processing)
