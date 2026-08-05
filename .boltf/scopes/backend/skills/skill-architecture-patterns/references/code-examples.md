# Architecture Patterns - Code Examples

Complete code examples for each architecture pattern.

## Table of Contents

1. [Modular Monolith Examples](#modular-monolith-examples)
2. [Microservices Examples](#microservices-examples)
3. [Serverless Examples](#serverless-examples)
4. [Event-Driven Architecture Examples](#event-driven-architecture-examples)
5. [Migration Patterns](#migration-patterns)

---

## Modular Monolith Examples

### C#/.NET Project Structure

```csharp
// src/Monolith.sln
// ├── Monolith.Api (ASP.NET Core Web API - entry point)
// ├── Modules/
// │   ├── Ordering/
// │   │   ├── Ordering.Core (domain logic)
// │   │   ├── Ordering.Infrastructure (data access)
// │   │   └── Ordering.Api (controllers - internal)
// │   ├── Catalog/
// │   │   ├── Catalog.Core
// │   │   ├── Catalog.Infrastructure
// │   │   └── Catalog.Api
// │   └── Identity/
// │       ├── Identity.Core
// │       ├── Identity.Infrastructure
// │       └── Identity.Api
// └── Shared/
//     ├── Shared.Abstractions (interfaces)
//     └── Shared.Infrastructure (cross-cutting)

// Monolith.Api/Program.cs
var builder = WebApplication.CreateBuilder(args);

// Register modules with clear boundaries
builder.Services.AddOrderingModule(builder.Configuration);
builder.Services.AddCatalogModule(builder.Configuration);
builder.Services.AddIdentityModule(builder.Configuration);

var app = builder.Build();

// Module-specific endpoints
app.MapGroup("/api/orders").MapOrderingEndpoints();
app.MapGroup("/api/catalog").MapCatalogEndpoints();
app.MapGroup("/api/identity").MapIdentityEndpoints();

app.Run();
```

### Node.js/TypeScript Project Structure

```typescript
// src/
// ├── modules/
// │   ├── ordering/
// │   │   ├── domain/ (entities, value objects)
// │   │   ├── application/ (use cases)
// │   │   ├── infrastructure/ (repositories)
// │   │   └── api/ (routes, controllers)
// │   ├── catalog/
// │   └── identity/
// ├── shared/
// │   ├── domain/
// │   └── infrastructure/
// └── server.ts (entry point)

// server.ts
import express from 'express';
import { orderingRouter } from './modules/ordering/api/routes';
import { catalogRouter } from './modules/catalog/api/routes';
import { identityRouter } from './modules/identity/api/routes';

const app = express();

// Module registration with clear boundaries
app.use('/api/orders', orderingRouter);
app.use('/api/catalog', catalogRouter);
app.use('/api/identity', identityRouter);

app.listen(3000, () => console.log('Modular monolith running on port 3000'));
```

---

## Microservices Examples

### C#/.NET Microservices Structure

```csharp
// Solution: ECommerce.Microservices.sln
// ├── services/
// │   ├── Ordering/
// │   │   ├── Ordering.API/
// │   │   ├── Ordering.Application/
// │   │   ├── Ordering.Domain/
// │   │   └── Ordering.Infrastructure/
// │   ├── Catalog/
// │   ├── Basket/
// │   └── Identity/
// ├── api-gateways/
// │   ├── Web.Gateway/ (BFF for web clients)
// │   └── Mobile.Gateway/ (BFF for mobile clients)
// ├── shared/
// │   ├── EventBus/ (messaging abstractions)
// │   └── Common/ (shared kernel)
// └── docker-compose.yml

// Ordering.API/Program.cs
var builder = WebApplication.CreateBuilder(args);

// Service-specific database
builder.Services.AddDbContext<OrderingContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("OrderingDb")));

// Service Bus for inter-service communication
builder.Services.AddAzureServiceBus(options => {
    options.ConnectionString = builder.Configuration["ServiceBus:ConnectionString"];
});

// Subscribe to events from other services
builder.Services.AddHostedService<BasketCheckoutEventHandler>();

var app = builder.Build();

app.MapGet("/api/orders/{id}", async (Guid id, OrderingContext db) =>
    await db.Orders.FindAsync(id));

app.MapPost("/api/orders", async (CreateOrderCommand cmd, IMediator mediator) =>
    await mediator.Send(cmd));

app.Run();
```

### Node.js/TypeScript Microservices Structure

```typescript
// microservices/
// ├── ordering-service/
// │   ├── src/
// │   │   ├── domain/
// │   │   ├── application/
// │   │   ├── infrastructure/
// │   │   └── api/
// │   ├── Dockerfile
// │   └── package.json
// ├── catalog-service/
// ├── basket-service/
// ├── api-gateway/
// └── docker-compose.yml

// ordering-service/src/api/server.ts
import express from 'express';
import { ServiceBusClient } from '@azure/service-bus';
import { OrderingRepository } from '../infrastructure/OrderingRepository';

const app = express();
const serviceBusClient = new ServiceBusClient(process.env.SERVICE_BUS_CONNECTION!);

// Service-specific database
const orderRepo = new OrderingRepository(process.env.MONGO_CONNECTION!);

// API endpoints
app.get('/api/orders/:id', async (req, res) => {
  const order = await orderRepo.findById(req.params.id);
  res.json(order);
});

app.post('/api/orders', async (req, res) => {
  const order = await orderRepo.create(req.body);

  // Publish event to other services
  const sender = serviceBusClient.createSender('order-created');
  await sender.sendMessages({ body: order });

  res.status(201).json(order);
});

// Subscribe to events from other services
const receiver = serviceBusClient.createReceiver('basket-checkout');
receiver.subscribe({
  processMessage: async (message) => {
    // Handle basket checkout event
    await orderRepo.createFromBasket(message.body);
  },
});

app.listen(3001);
```

---

## Serverless Examples

### C#/.NET Azure Functions

```csharp
// OrderProcessingFunctions.cs
public class OrderProcessingFunctions
{
    private readonly IOrderService _orderService;

    public OrderProcessingFunctions(IOrderService orderService)
    {
        _orderService = orderService;
    }

    // HTTP trigger - create order API
    [FunctionName("CreateOrder")]
    public async Task<IActionResult> CreateOrder(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "orders")] HttpRequest req,
        [Queue("order-processing")] IAsyncCollector<OrderMessage> queueCollector,
        ILogger log)
    {
        var orderDto = await req.ReadFromJsonAsync<CreateOrderDto>();
        var orderId = Guid.NewGuid();

        // Enqueue for async processing
        await queueCollector.AddAsync(new OrderMessage { OrderId = orderId, Data = orderDto });

        log.LogInformation($"Order {orderId} queued for processing");
        return new AcceptedResult($"/api/orders/{orderId}", new { orderId });
    }

    // Queue trigger - process order asynchronously
    [FunctionName("ProcessOrder")]
    public async Task ProcessOrder(
        [QueueTrigger("order-processing")] OrderMessage message,
        [ServiceBus("order-created", Connection = "ServiceBusConnection")] IAsyncCollector<OrderCreatedEvent> eventCollector,
        ILogger log)
    {
        var order = await _orderService.CreateOrderAsync(message.Data);

        // Publish event
        await eventCollector.AddAsync(new OrderCreatedEvent { Order = order });

        log.LogInformation($"Order {order.Id} processed successfully");
    }

    // Timer trigger - scheduled cleanup
    [FunctionName("CleanupExpiredOrders")]
    public async Task CleanupExpiredOrders(
        [TimerTrigger("0 0 2 * * *")] TimerInfo timer, // Daily at 2 AM
        ILogger log)
    {
        var deletedCount = await _orderService.DeleteExpiredOrdersAsync();
        log.LogInformation($"Cleaned up {deletedCount} expired orders");
    }

    // Blob trigger - process uploaded invoice
    [FunctionName("ProcessInvoice")]
    public async Task ProcessInvoice(
        [BlobTrigger("invoices/{name}", Connection = "StorageConnection")] Stream invoice,
        string name,
        ILogger log)
    {
        await _orderService.ProcessInvoiceAsync(invoice, name);
        log.LogInformation($"Invoice {name} processed");
    }
}
```

### Node.js/TypeScript Azure Functions

```typescript
// functions/createOrder.ts
import { app, HttpRequest, HttpResponseInit, InvocationContext, output } from '@azure/functions';

const queueOutput = output.storageQueue({
  queueName: 'order-processing',
  connection: 'StorageConnection',
});

export async function createOrder(
  req: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  const orderDto = await req.json();
  const orderId = crypto.randomUUID();

  // Enqueue for async processing
  context.extraOutputs.set(queueOutput, { orderId, data: orderDto });

  context.log(`Order ${orderId} queued for processing`);
  return { status: 202, jsonBody: { orderId } };
}

app.http('createOrder', {
  methods: ['POST'],
  route: 'orders',
  authLevel: 'function',
  extraOutputs: [queueOutput],
  handler: createOrder,
});

// functions/processOrder.ts
import { app, InvocationContext, output } from '@azure/functions';

const serviceBusOutput = output.serviceBusQueue({
  queueName: 'order-created',
  connection: 'ServiceBusConnection',
});

export async function processOrder(message: any, context: InvocationContext): Promise<void> {
  const order = await orderService.createOrder(message.data);

  // Publish event
  context.extraOutputs.set(serviceBusOutput, { order });

  context.log(`Order ${order.id} processed successfully`);
}

app.storageQueue('processOrder', {
  queueName: 'order-processing',
  connection: 'StorageConnection',
  extraOutputs: [serviceBusOutput],
  handler: processOrder,
});

// functions/cleanupExpiredOrders.ts
export async function cleanupExpiredOrders(timer: any, context: InvocationContext): Promise<void> {
  const deletedCount = await orderService.deleteExpiredOrders();
  context.log(`Cleaned up ${deletedCount} expired orders`);
}

app.timer('cleanupExpiredOrders', {
  schedule: '0 0 2 * * *', // Daily at 2 AM
  handler: cleanupExpiredOrders,
});
```

---

## Event-Driven Architecture Examples

### C#/.NET with Azure Service Bus

```csharp
// Publishing events (OrderService)
public class OrderService
{
    private readonly ServiceBusSender _eventSender;

    public OrderService(ServiceBusClient serviceBusClient)
    {
        _eventSender = serviceBusClient.CreateSender("order-events");
    }

    public async Task<Order> CreateOrderAsync(CreateOrderDto dto)
    {
        var order = new Order { /* ... */ };
        await _dbContext.Orders.AddAsync(order);
        await _dbContext.SaveChangesAsync();

        // Publish domain event
        var @event = new OrderCreatedEvent
        {
            OrderId = order.Id,
            CustomerId = order.CustomerId,
            TotalAmount = order.TotalAmount,
            CreatedAt = DateTime.UtcNow
        };

        var message = new ServiceBusMessage(JsonSerializer.Serialize(@event))
        {
            Subject = nameof(OrderCreatedEvent),
            CorrelationId = order.Id.ToString()
        };

        await _eventSender.SendMessageAsync(message);

        return order;
    }
}

// Subscribing to events (InventoryService)
public class OrderCreatedEventHandler : BackgroundService
{
    private readonly ServiceBusProcessor _processor;
    private readonly IInventoryService _inventoryService;

    public OrderCreatedEventHandler(ServiceBusClient serviceBusClient, IInventoryService inventoryService)
    {
        _processor = serviceBusClient.CreateProcessor("order-events", "inventory-subscription");
        _inventoryService = inventoryService;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _processor.ProcessMessageAsync += async args =>
        {
            var @event = JsonSerializer.Deserialize<OrderCreatedEvent>(args.Message.Body.ToString());

            // React to event
            await _inventoryService.ReserveInventoryAsync(@event.OrderId);

            // Complete message (remove from queue)
            await args.CompleteMessageAsync(args.Message, stoppingToken);
        };

        _processor.ProcessErrorAsync += args =>
        {
            Console.WriteLine($"Error processing: {args.Exception}");
            return Task.CompletedTask;
        };

        await _processor.StartProcessingAsync(stoppingToken);
    }
}
```

### Node.js/TypeScript with Azure Service Bus

```typescript
// Publishing events (orderService.ts)
import { ServiceBusClient } from '@azure/service-bus';

export class OrderService {
  private eventSender;

  constructor(serviceBusClient: ServiceBusClient) {
    this.eventSender = serviceBusClient.createSender('order-events');
  }

  async createOrder(dto: CreateOrderDto): Promise<Order> {
    const order = {
      /* ... */
    };
    await db.orders.insert(order);

    // Publish domain event
    const event: OrderCreatedEvent = {
      orderId: order.id,
      customerId: order.customerId,
      totalAmount: order.totalAmount,
      createdAt: new Date(),
    };

    await this.eventSender.sendMessages({
      body: event,
      subject: 'OrderCreatedEvent',
      correlationId: order.id,
    });

    return order;
  }
}

// Subscribing to events (inventoryService.ts)
import { ServiceBusClient } from '@azure/service-bus';

export class OrderCreatedEventHandler {
  private receiver;

  constructor(
    serviceBusClient: ServiceBusClient,
    private inventoryService: InventoryService
  ) {
    this.receiver = serviceBusClient.createReceiver('order-events', 'inventory-subscription');
  }

  async start(): Promise<void> {
    this.receiver.subscribe({
      processMessage: async (message) => {
        const event = message.body as OrderCreatedEvent;

        // React to event
        await this.inventoryService.reserveInventory(event.orderId);

        // Message automatically completed on success
      },
      processError: async (error) => {
        console.error('Error processing:', error);
      },
    });
  }
}
```

---

## Migration Patterns

### Strangler Fig Pattern (Monolith to Microservices)

#### Azure API Management Routing Policy

```xml
<policies>
    <inbound>
        <base />
        <!-- Canary deployment: gradually shift traffic -->
        <set-variable name="routingPercentage" value="50" />
        <choose>
            <when condition="@(new Random().Next(0, 100) < context.Variables.GetValueOrDefault<int>("routingPercentage", 0))">
                <!-- Route to new microservice -->
                <set-backend-service base-url="https://catalog-microservice.azurewebsites.net" />
            </when>
            <otherwise>
                <!-- Route to legacy monolith -->
                <set-backend-service base-url="https://legacy-monolith.azurewebsites.net" />
            </otherwise>
        </choose>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

#### Progressive Migration Steps

1. **10% traffic** to new service → monitor errors/latency
2. **50% traffic** after 1 week of stability
3. **100% traffic** after another week
4. **Decommission** monolith module

### Database-per-Service Pattern

```csharp
// OLD: Shared database in monolith
public class OrderService
{
    public async Task CreateOrder(Order order)
    {
        // Single transaction across modules
        using var transaction = _dbContext.Database.BeginTransaction();
        _dbContext.Orders.Add(order);
        _dbContext.Inventory.Update(/* reserve stock */);
        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
    }
}

// NEW: Separate databases with eventual consistency
public class OrderService
{
    private readonly OrderDbContext _orderDb;
    private readonly ServiceBusClient _serviceBus;

    public async Task CreateOrder(Order order)
    {
        // Save to order database
        _orderDb.Orders.Add(order);
        await _orderDb.SaveChangesAsync();

        // Publish event for inventory service
        var @event = new OrderCreatedEvent { OrderId = order.Id };
        await _serviceBus.SendAsync("order-events", @event);
    }
}
```
