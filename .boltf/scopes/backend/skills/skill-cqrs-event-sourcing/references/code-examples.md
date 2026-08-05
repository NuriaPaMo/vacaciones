# CQRS & Event Sourcing - Code Examples

Complete implementation examples for CQRS and Event Sourcing patterns.

## Table of Contents

1. [Native CQRS (No MediatR)](#native-cqrs-no-mediatr)
2. [Event Sourcing with EventStoreDB](#event-sourcing-with-eventstoredb)
3. [Event Sourcing with Cosmos DB](#event-sourcing-with-cosmos-db)
4. [Event Sourcing with SQL Server](#event-sourcing-with-sql-server)
5. [Projections & Read Models](#projections--read-models)
6. [Event Versioning](#event-versioning)

---

## Native CQRS (No MediatR)

### C#/.NET Native CQRS

```csharp
// Define command and query interfaces
public interface ICommandHandler<in TCommand>
{
    Task HandleAsync(TCommand command, CancellationToken cancellationToken = default);
}

public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken cancellationToken = default);
}

// Example command
public record CreateOrderCommand(Guid CustomerId, List<OrderItem> Items);

// Command handler
public class CreateOrderCommandHandler : ICommandHandler<CreateOrderCommand>
{
    private readonly OrderDbContext _dbContext;
    private readonly IEventBus _eventBus;

    public CreateOrderCommandHandler(OrderDbContext dbContext, IEventBus eventBus)
    {
        _dbContext = dbContext;
        _eventBus = eventBus;
    }

    public async Task HandleAsync(CreateOrderCommand command, CancellationToken cancellationToken)
    {
        // Business logic
        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = command.CustomerId,
            Items = command.Items,
            Status = OrderStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Orders.Add(order);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // Publish domain event
        await _eventBus.PublishAsync(new OrderCreatedEvent(order.Id, order.CustomerId));
    }
}

// Example query
public record GetOrderByIdQuery(Guid OrderId);

// Query handler
public class GetOrderByIdQueryHandler : IQueryHandler<GetOrderByIdQuery, OrderDto?>
{
    private readonly OrderReadDbContext _readDb;

    public GetOrderByIdQueryHandler(OrderReadDbContext readDb)
    {
        _readDb = readDb;
    }

    public async Task<OrderDto?> HandleAsync(GetOrderByIdQuery query, CancellationToken cancellationToken)
    {
        // Query optimized read model
        return await _readDb.Orders
            .Where(o => o.Id == query.OrderId)
            .Select(o => new OrderDto(o.Id, o.CustomerId, o.Status, o.TotalAmount))
            .FirstOrDefaultAsync(cancellationToken);
    }
}

// Registration in Program.cs
builder.Services.AddScoped<ICommandHandler<CreateOrderCommand>, CreateOrderCommandHandler>();
builder.Services.AddScoped<IQueryHandler<GetOrderByIdQuery, OrderDto?>, GetOrderByIdQueryHandler>();

// Usage in controller
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly ICommandHandler<CreateOrderCommand> _createOrderHandler;
    private readonly IQueryHandler<GetOrderByIdQuery, OrderDto?> _getOrderHandler;

    public OrdersController(
        ICommandHandler<CreateOrderCommand> createOrderHandler,
        IQueryHandler<GetOrderByIdQuery, OrderDto?> getOrderHandler)
    {
        _createOrderHandler = createOrderHandler;
        _getOrderHandler = getOrderHandler;
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder(CreateOrderCommand command)
    {
        await _createOrderHandler.HandleAsync(command);
        return Accepted();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(Guid id)
    {
        var order = await _getOrderHandler.HandleAsync(new GetOrderByIdQuery(id));
        return order is not null ? Ok(order) : NotFound();
    }
}
```

### Node.js/TypeScript Native CQRS

```typescript
// Define command and query interfaces
export interface ICommandHandler<TCommand> {
  handle(command: TCommand): Promise<void>;
}

export interface IQueryHandler<TQuery, TResult> {
  handle(query: TQuery): Promise<TResult>;
}

// Example command
export interface CreateOrderCommand {
  customerId: string;
  items: OrderItem[];
}

// Command handler
export class CreateOrderCommandHandler implements ICommandHandler<CreateOrderCommand> {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly eventBus: IEventBus
  ) {}

  async handle(command: CreateOrderCommand): Promise<void> {
    // Business logic
    const order = {
      id: crypto.randomUUID(),
      customerId: command.customerId,
      items: command.items,
      status: 'PENDING',
      createdAt: new Date(),
    };

    await this.orderRepository.save(order);

    // Publish domain event
    await this.eventBus.publish({
      type: 'OrderCreated',
      orderId: order.id,
      customerId: order.customerId,
    });
  }
}

// Example query
export interface GetOrderByIdQuery {
  orderId: string;
}

// Query handler
export class GetOrderByIdQueryHandler implements IQueryHandler<GetOrderByIdQuery, OrderDto | null> {
  constructor(private readonly orderReadRepository: OrderReadRepository) {}

  async handle(query: GetOrderByIdQuery): Promise<OrderDto | null> {
    // Query optimized read model
    return this.orderReadRepository.findById(query.orderId);
  }
}

// Registration (dependency injection container)
container.registerSingleton('CreateOrderHandler', CreateOrderCommandHandler);
container.registerSingleton('GetOrderByIdHandler', GetOrderByIdQueryHandler);

// Usage in Express controller
router.post('/orders', async (req, res) => {
  const handler = container.resolve<CreateOrderCommandHandler>('CreateOrderHandler');
  await handler.handle(req.body as CreateOrderCommand);
  res.status(202).send();
});

router.get('/orders/:id', async (req, res) => {
  const handler = container.resolve<GetOrderByIdQueryHandler>('GetOrderByIdHandler');
  const order = await handler.handle({ orderId: req.params.id });
  order ? res.json(order) : res.status(404).send();
});
```

---

## Event Sourcing with EventStoreDB

### C#/.NET with EventStoreDB

```csharp
// Domain event base
public abstract record DomainEvent
{
    public Guid EventId { get; init; } = Guid.NewGuid();
    public DateTime OccurredAt { get; init; } = DateTime.UtcNow;
}

// Concrete events
public record OrderCreatedEvent(Guid OrderId, Guid CustomerId) : DomainEvent;
public record OrderItemAddedEvent(Guid OrderId, Guid ProductId, int Quantity, decimal Price) : DomainEvent;
public record OrderShippedEvent(Guid OrderId, string TrackingNumber) : DomainEvent;

// Aggregate root (Order)
public class Order
{
    private readonly List<DomainEvent> _uncommittedEvents = new();

    public Guid Id { get; private set; }
    public Guid CustomerId { get; private set; }
    public List<OrderItem> Items { get; private set; } = new();
    public OrderStatus Status { get; private set; }
    public int Version { get; private set; }

    // Factory method (creates new order)
    public static Order Create(Guid customerId)
    {
        var order = new Order();
        order.Apply(new OrderCreatedEvent(Guid.NewGuid(), customerId));
        return order;
    }

    // Command methods (mutate via events)
    public void AddItem(Guid productId, int quantity, decimal price)
    {
        Apply(new OrderItemAddedEvent(Id, productId, quantity, price));
    }

    public void Ship(string trackingNumber)
    {
        if (Status != OrderStatus.Confirmed)
            throw new InvalidOperationException("Only confirmed orders can be shipped");

        Apply(new OrderShippedEvent(Id, trackingNumber));
    }

    // Apply event (mutate state + track uncommitted)
    private void Apply(DomainEvent @event)
    {
        When(@event);
        _uncommittedEvents.Add(@event);
    }

    // Reconstruct from history
    public void Load(IEnumerable<DomainEvent> history)
    {
        foreach (var @event in history)
        {
            When(@event);
            Version++;
        }
    }

    // Event handlers (pure state transitions)
    private void When(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreatedEvent e:
                Id = e.OrderId;
                CustomerId = e.CustomerId;
                Status = OrderStatus.Pending;
                break;
            case OrderItemAddedEvent e:
                Items.Add(new OrderItem(e.ProductId, e.Quantity, e.Price));
                break;
            case OrderShippedEvent e:
                Status = OrderStatus.Shipped;
                break;
        }
    }

    public IEnumerable<DomainEvent> GetUncommittedEvents() => _uncommittedEvents;
    public void ClearUncommittedEvents() => _uncommittedEvents.Clear();
}

// EventStore repository
public class EventStoreRepository
{
    private readonly EventStoreClient _client;

    public EventStoreRepository(EventStoreClient client)
    {
        _client = client;
    }

    public async Task SaveAsync(Order aggregate)
    {
        var streamName = $"order-{aggregate.Id}";
        var events = aggregate.GetUncommittedEvents()
            .Select(e => new EventData(
                Uuid.NewUuid(),
                e.GetType().Name,
                JsonSerializer.SerializeToUtf8Bytes(e)
            ))
            .ToArray();

        await _client.AppendToStreamAsync(
            streamName,
            StreamRevision.FromInt64(aggregate.Version),
            events
        );

        aggregate.ClearUncommittedEvents();
    }

    public async Task<Order?> LoadAsync(Guid orderId)
    {
        var streamName = $"order-{orderId}";
        var result = _client.ReadStreamAsync(
            Direction.Forwards,
            streamName,
            StreamPosition.Start
        );

        if (await result.ReadState == ReadState.StreamNotFound)
            return null;

        var events = new List<DomainEvent>();
        await foreach (var resolvedEvent in result)
        {
            var eventType = Type.GetType($"MyApp.Events.{resolvedEvent.Event.EventType}");
            var @event = JsonSerializer.Deserialize(
                resolvedEvent.Event.Data.Span,
                eventType!
            ) as DomainEvent;
            events.Add(@event!);
        }

        var order = new Order();
        order.Load(events);
        return order;
    }
}
```

---

## Event Sourcing with Cosmos DB

### C#/.NET with Cosmos DB

```csharp
// Event envelope for Cosmos DB
public record EventEnvelope
{
    [JsonPropertyName("id")]
    public string Id { get; init; } = Guid.NewGuid().ToString();

    [JsonPropertyName("streamId")]
    public string StreamId { get; init; } = null!;

    [JsonPropertyName("eventType")]
    public string EventType { get; init; } = null!;

    [JsonPropertyName("eventData")]
    public string EventData { get; init; } = null!;

    [JsonPropertyName("version")]
    public int Version { get; init; }

    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
}

// Cosmos DB event store repository
public class CosmosEventStoreRepository
{
    private readonly Container _container;

    public CosmosEventStoreRepository(CosmosClient cosmosClient, string databaseId, string containerId)
    {
        _container = cosmosClient.GetContainer(databaseId, containerId);
    }

    public async Task SaveEventsAsync(string streamId, IEnumerable<DomainEvent> events, int expectedVersion)
    {
        var batch = _container.CreateTransactionalBatch(new PartitionKey(streamId));

        var version = expectedVersion;
        foreach (var @event in events)
        {
            version++;
            var envelope = new EventEnvelope
            {
                StreamId = streamId,
                EventType = @event.GetType().Name,
                EventData = JsonSerializer.Serialize(@event),
                Version = version
            };
            batch.CreateItem(envelope);
        }

        using var response = await batch.ExecuteAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Failed to save events: {response.StatusCode}");
    }

    public async Task<List<DomainEvent>> LoadEventsAsync(string streamId)
    {
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.streamId = @streamId ORDER BY c.version ASC")
            .WithParameter("@streamId", streamId);

        var iterator = _container.GetItemQueryIterator<EventEnvelope>(query);
        var events = new List<DomainEvent>();

        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            foreach (var envelope in response)
            {
                var eventType = Type.GetType($"MyApp.Events.{envelope.EventType}");
                var @event = JsonSerializer.Deserialize(envelope.EventData, eventType!) as DomainEvent;
                events.Add(@event!);
            }
        }

        return events;
    }

    // Change Feed for projections
    public async Task SubscribeToChangeFeedAsync(
        Func<IReadOnlyCollection<EventEnvelope>, Task> processor,
        CancellationToken cancellationToken)
    {
        var processor = _container.GetChangeFeedProcessorBuilder<EventEnvelope>(
            processorName: "OrderProjection",
            onChangesDelegate: async (changes, cancellationToken) =>
            {
                await processor(changes);
            })
            .WithInstanceName("instance1")
            .WithLeaseContainer(_container) // Use same container for leases
            .Build();

        await processor.StartAsync();
        await Task.Delay(-1, cancellationToken); // Run until cancelled
    }
}
```

---

## Event Sourcing with SQL Server

### C#/.NET with SQL Server

```csharp
// SQL table schema
/*
CREATE TABLE EventStore (
    Id BIGINT IDENTITY PRIMARY KEY,
    StreamId UNIQUEIDENTIFIER NOT NULL,
    EventType NVARCHAR(255) NOT NULL,
    EventData NVARCHAR(MAX) NOT NULL,
    Version INT NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_EventStore_StreamId_Version UNIQUE (StreamId, Version)
);

CREATE INDEX IX_EventStore_StreamId ON EventStore(StreamId, Version);
*/

// SQL event store repository
public class SqlEventStoreRepository
{
    private readonly string _connectionString;

    public SqlEventStoreRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task SaveEventsAsync(Guid streamId, IEnumerable<DomainEvent> events, int expectedVersion)
    {
        using var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync();
        using var transaction = connection.BeginTransaction();

        try
        {
            var version = expectedVersion;
            foreach (var @event in events)
            {
                version++;
                var command = new SqlCommand(@"
                    INSERT INTO EventStore (StreamId, EventType, EventData, Version)
                    VALUES (@StreamId, @EventType, @EventData, @Version)",
                    connection, transaction);

                command.Parameters.AddWithValue("@StreamId", streamId);
                command.Parameters.AddWithValue("@EventType", @event.GetType().Name);
                command.Parameters.AddWithValue("@EventData", JsonSerializer.Serialize(@event));
                command.Parameters.AddWithValue("@Version", version);

                await command.ExecuteNonQueryAsync();
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<List<DomainEvent>> LoadEventsAsync(Guid streamId)
    {
        using var connection = new SqlConnection(_connectionString);
        var command = new SqlCommand(@"
            SELECT EventType, EventData
            FROM EventStore
            WHERE StreamId = @StreamId
            ORDER BY Version ASC",
            connection);

        command.Parameters.AddWithValue("@StreamId", streamId);

        await connection.OpenAsync();
        using var reader = await command.ExecuteReaderAsync();

        var events = new List<DomainEvent>();
        while (await reader.ReadAsync())
        {
            var eventType = Type.GetType($"MyApp.Events.{reader.GetString(0)}");
            var eventData = reader.GetString(1);
            var @event = JsonSerializer.Deserialize(eventData, eventType!) as DomainEvent;
            events.Add(@event!);
        }

        return events;
    }
}
```

---

## Projections & Read Models

### Asynchronous Projection (Event Subscription)

```csharp
// Read model (denormalized view)
public class OrderSummaryReadModel
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public decimal TotalAmount { get; set; }
    public int ItemCount { get; set; }
    public string Status { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}

// Projection handler (subscribes to events)
public class OrderSummaryProjection
{
    private readonly OrderReadDbContext _readDb;

    public OrderSummaryProjection(OrderReadDbContext readDb)
    {
        _readDb = readDb;
    }

    public async Task HandleAsync(DomainEvent @event)
    {
        switch (@event)
        {
            case OrderCreatedEvent e:
                var summary = new OrderSummaryReadModel
                {
                    OrderId = e.OrderId,
                    CustomerId = e.CustomerId,
                    Status = "Pending",
                    CreatedAt = e.OccurredAt
                };
                _readDb.OrderSummaries.Add(summary);
                await _readDb.SaveChangesAsync();
                break;

            case OrderItemAddedEvent e:
                var order = await _readDb.OrderSummaries.FindAsync(e.OrderId);
                if (order != null)
                {
                    order.ItemCount++;
                    order.TotalAmount += e.Price * e.Quantity;
                    await _readDb.SaveChangesAsync();
                }
                break;

            case OrderShippedEvent e:
                var shipped = await _readDb.OrderSummaries.FindAsync(e.OrderId);
                if (shipped != null)
                {
                    shipped.Status = "Shipped";
                    await _readDb.SaveChangesAsync();
                }
                break;
        }
    }
}

// Event bus subscription
public class ProjectionSubscriber : BackgroundService
{
    private readonly IEventBus _eventBus;
    private readonly IServiceProvider _serviceProvider;

    public ProjectionSubscriber(IEventBus eventBus, IServiceProvider serviceProvider)
    {
        _eventBus = eventBus;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _eventBus.SubscribeAsync<DomainEvent>(async @event =>
        {
            using var scope = _serviceProvider.CreateScope();
            var projection = scope.ServiceProvider.GetRequiredService<OrderSummaryProjection>();
            await projection.HandleAsync(@event);
        }, stoppingToken);
    }
}
```

---

## Event Versioning

### Upcasting Pattern

```csharp
// V1 event
public record OrderCreatedEventV1(Guid OrderId, Guid CustomerId) : DomainEvent;

// V2 event (added CustomerEmail)
public record OrderCreatedEventV2(Guid OrderId, Guid CustomerId, string CustomerEmail) : DomainEvent;

// Upcaster interface
public interface IEventUpcaster<TFrom, TTo>
    where TFrom : DomainEvent
    where TTo : DomainEvent
{
    TTo Upcast(TFrom oldEvent);
}

// Concrete upcaster
public class OrderCreatedEventUpcaster : IEventUpcaster<OrderCreatedEventV1, OrderCreatedEventV2>
{
    private readonly ICustomerRepository _customerRepo;

    public OrderCreatedEventUpcaster(ICustomerRepository customerRepo)
    {
        _customerRepo = customerRepo;
    }

    public OrderCreatedEventV2 Upcast(OrderCreatedEventV1 oldEvent)
    {
        // Enrich with data from current system
        var customer = _customerRepo.GetById(oldEvent.CustomerId);
        return new OrderCreatedEventV2(
            oldEvent.OrderId,
            oldEvent.CustomerId,
            customer?.Email ?? "unknown@example.com"
        );
    }
}

// Event store with upcasting
public async Task<List<DomainEvent>> LoadEventsWithUpcastingAsync(Guid streamId)
{
    var rawEvents = await LoadEventsAsync(streamId);
    var upcastedEvents = new List<DomainEvent>();

    foreach (var @event in rawEvents)
    {
        if (@event is OrderCreatedEventV1 v1)
        {
            var upcaster = new OrderCreatedEventUpcaster(_customerRepo);
            upcastedEvents.Add(upcaster.Upcast(v1));
        }
        else
        {
            upcastedEvents.Add(@event);
        }
    }

    return upcastedEvents;
}
```

### Multi-Version Handler Pattern

```csharp
// Order aggregate handles both versions
private void When(DomainEvent @event)
{
    switch (@event)
    {
        case OrderCreatedEventV1 e:
            Id = e.OrderId;
            CustomerId = e.CustomerId;
            CustomerEmail = null; // No email in V1
            Status = OrderStatus.Pending;
            break;

        case OrderCreatedEventV2 e:
            Id = e.OrderId;
            CustomerId = e.CustomerId;
            CustomerEmail = e.CustomerEmail;
            Status = OrderStatus.Pending;
            break;

        // ... other events
    }
}
```
