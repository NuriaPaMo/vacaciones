# Communication Patterns – Code Examples

This document provides complete, production-ready code examples for each communication pattern covered in the skill. All examples follow Bolt Framework constitution mandates and demonstrate best practices.

---

## REST API Examples

### ASP.NET Core Minimal API with OpenAPI

**File:** `Program.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Products API",
        Version = "v1",
        Description = "RESTful product catalog API"
    });
});

// Add CORS for frontend clients
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://localhost:5173")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();

// Define endpoints
app.MapGet("/api/products", async ([FromServices] IProductRepository repo) =>
{
    var products = await repo.GetAllAsync();
    return Results.Ok(products);
})
.WithName("GetProducts")
.WithOpenApi();

app.MapGet("/api/products/{id:guid}", async (Guid id, [FromServices] IProductRepository repo) =>
{
    var product = await repo.GetByIdAsync(id);
    return product is null ? Results.NotFound() : Results.Ok(product);
})
.WithName("GetProduct")
.WithOpenApi();

app.MapPost("/api/products", async ([FromBody] CreateProductRequest request, [FromServices] IProductRepository repo) =>
{
    var product = new Product
    {
        Id = Guid.NewGuid(),
        Name = request.Name,
        Price = request.Price
    };
    await repo.AddAsync(product);
    return Results.Created($"/api/products/{product.Id}", product);
})
.WithName("CreateProduct")
.WithOpenApi();

app.MapPut("/api/products/{id:guid}", async (Guid id, [FromBody] UpdateProductRequest request, [FromServices] IProductRepository repo) =>
{
    var product = await repo.GetByIdAsync(id);
    if (product is null) return Results.NotFound();

    product.Name = request.Name;
    product.Price = request.Price;
    await repo.UpdateAsync(product);
    return Results.NoContent();
})
.WithName("UpdateProduct")
.WithOpenApi();

app.MapDelete("/api/products/{id:guid}", async (Guid id, [FromServices] IProductRepository repo) =>
{
    var product = await repo.GetByIdAsync(id);
    if (product is null) return Results.NotFound();

    await repo.DeleteAsync(id);
    return Results.NoContent();
})
.WithName("DeleteProduct")
.WithOpenApi();

app.Run();
```

### TypeScript/Node.js REST API with Express

**File:** `server.ts`

```typescript
import express, { Request, Response } from 'express';
import { z } from 'zod';
import swaggerUi from 'swagger-ui-express';
import { openApiSpec } from './openapi-spec';

const app = express();
app.use(express.json());

// Swagger/OpenAPI documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(openApiSpec));

// Schema validation with Zod
const createProductSchema = z.object({
  name: z.string().min(1).max(100),
  price: z.number().positive(),
});

// GET /api/products
app.get('/api/products', async (req: Request, res: Response) => {
  const products = await productRepository.getAll();
  res.json(products);
});

// GET /api/products/:id
app.get('/api/products/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const product = await productRepository.getById(id);

  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }

  res.json(product);
});

// POST /api/products
app.post('/api/products', async (req: Request, res: Response) => {
  const result = createProductSchema.safeParse(req.body);

  if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() });
  }

  const product = await productRepository.create(result.data);
  res.status(201).json(product);
});

app.listen(3000, () => console.log('API listening on port 3000'));
```

---

## gRPC Examples

### protobuf Contract Definition

**File:** `products.proto`

```proto
syntax = "proto3";

option csharp_namespace = "ProductService.Grpc";

package products;

service ProductService {
  rpc GetProduct (GetProductRequest) returns (GetProductResponse);
  rpc ListProducts (ListProductsRequest) returns (stream ProductResponse);
  rpc CreateProduct (CreateProductRequest) returns (CreateProductResponse);
  rpc UpdateProduct (UpdateProductRequest) returns (UpdateProductResponse);
}

message GetProductRequest {
  string id = 1;
}

message GetProductResponse {
  ProductResponse product = 1;
}

message ListProductsRequest {
  int32 page_size = 1;
  string page_token = 2;
}

message ProductResponse {
  string id = 1;
  string name = 2;
  double price = 3;
  int64 created_at = 4;
}

message CreateProductRequest {
  string name = 1;
  double price = 2;
}

message CreateProductResponse {
  string id = 1;
}

message UpdateProductRequest {
  string id = 1;
  string name = 2;
  double price = 3;
}

message UpdateProductResponse {
  bool success = 1;
}
```

### ASP.NET Core gRPC Service Implementation

**File:** `ProductGrpcService.cs`

```csharp
using Grpc.Core;
using ProductService.Grpc;

namespace ProductService.Services;

public class ProductGrpcService : ProductService.Grpc.ProductService.ProductServiceBase
{
    private readonly IProductRepository _repository;
    private readonly ILogger<ProductGrpcService> _logger;

    public ProductGrpcService(IProductRepository repository, ILogger<ProductGrpcService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public override async Task<GetProductResponse> GetProduct(GetProductRequest request, ServerCallContext context)
    {
        var product = await _repository.GetByIdAsync(Guid.Parse(request.Id));

        if (product is null)
        {
            throw new RpcException(new Status(StatusCode.NotFound, $"Product {request.Id} not found"));
        }

        return new GetProductResponse
        {
            Product = new ProductResponse
            {
                Id = product.Id.ToString(),
                Name = product.Name,
                Price = product.Price,
                CreatedAt = product.CreatedAt.Ticks
            }
        };
    }

    public override async Task ListProducts(ListProductsRequest request, IServerStreamWriter<ProductResponse> responseStream, ServerCallContext context)
    {
        var products = await _repository.GetAllAsync();

        foreach (var product in products)
        {
            if (context.CancellationToken.IsCancellationRequested)
            {
                _logger.LogInformation("Client cancelled stream");
                break;
            }

            await responseStream.WriteAsync(new ProductResponse
            {
                Id = product.Id.ToString(),
                Name = product.Name,
                Price = product.Price,
                CreatedAt = product.CreatedAt.Ticks
            });
        }
    }

    public override async Task<CreateProductResponse> CreateProduct(CreateProductRequest request, ServerCallContext context)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Price = request.Price,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.AddAsync(product);

        return new CreateProductResponse { Id = product.Id.ToString() };
    }
}
```

**File:** `Program.cs` (gRPC service registration)

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddGrpc();
builder.Services.AddScoped<IProductRepository, ProductRepository>();

var app = builder.Build();

app.MapGrpcService<ProductGrpcService>();

app.Run();
```

### gRPC Client Usage

```csharp
using Grpc.Net.Client;
using ProductService.Grpc;

using var channel = GrpcChannel.ForAddress("https://localhost:5001");
var client = new ProductService.Grpc.ProductService.ProductServiceClient(channel);

// Call unary RPC
var response = await client.GetProductAsync(new GetProductRequest { Id = productId });
Console.WriteLine($"Product: {response.Product.Name} - ${response.Product.Price}");

// Call server streaming RPC
using var streamingCall = client.ListProducts(new ListProductsRequest { PageSize = 50 });
await foreach (var product in streamingCall.ResponseStream.ReadAllAsync())
{
    Console.WriteLine($"{product.Name}: ${product.Price}");
}
```

---

## GraphQL Examples

### HotChocolate GraphQL Server

**File:** `Query.cs`

```csharp
namespace ProductService.GraphQL;

public class Query
{
    [UseProjection]
    [UseFiltering]
    [UseSorting]
    public IQueryable<Product> GetProducts([Service] IProductRepository repository)
        => repository.GetAllQueryable();

    public async Task<Product?> GetProduct(Guid id, [Service] IProductRepository repository)
        => await repository.GetByIdAsync(id);
}
```

**File:** `Mutation.cs`

```csharp
namespace ProductService.GraphQL;

public class Mutation
{
    public async Task<Product> CreateProduct(CreateProductInput input, [Service] IProductRepository repository)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = input.Name,
            Price = input.Price,
            CreatedAt = DateTime.UtcNow
        };

        await repository.AddAsync(product);
        return product;
    }

    public async Task<Product> UpdateProduct(Guid id, UpdateProductInput input, [Service] IProductRepository repository)
    {
        var product = await repository.GetByIdAsync(id);
        if (product is null)
        {
            throw new GraphQLException("Product not found");
        }

        product.Name = input.Name;
        product.Price = input.Price;
        await repository.UpdateAsync(product);

        return product;
    }

    public async Task<bool> DeleteProduct(Guid id, [Service] IProductRepository repository)
    {
        var product = await repository.GetByIdAsync(id);
        if (product is null) return false;

        await repository.DeleteAsync(id);
        return true;
    }
}

public record CreateProductInput(string Name, decimal Price);
public record UpdateProductInput(string Name, decimal Price);
```

**File:** `Program.cs` (GraphQL registration)

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddGraphQLServer()
    .AddQueryType<Query>()
    .AddMutationType<Mutation>()
    .AddProjections()
    .AddFiltering()
    .AddSorting();

var app = builder.Build();

app.MapGraphQL();

app.Run();
```

### GraphQL Client Query (TypeScript)

```typescript
import { gql, request } from 'graphql-request';

const endpoint = 'https://localhost:5001/graphql';

// Query with projections (client specifies exact fields)
const query = gql`
  query GetProducts($minPrice: Decimal!) {
    products(where: { price: { gte: $minPrice } }, order: { name: ASC }) {
      id
      name
      price
    }
  }
`;

const data = await request(endpoint, query, { minPrice: 10.0 });
console.log(data.products);

// Mutation
const mutation = gql`
  mutation CreateProduct($input: CreateProductInput!) {
    createProduct(input: $input) {
      id
      name
      price
    }
  }
`;

const result = await request(endpoint, mutation, {
  input: { name: 'New Product', price: 29.99 },
});
```

---

## Service Bus Examples

### Azure Service Bus Producer (C#)

```csharp
using Azure.Messaging.ServiceBus;

public class OrderCommandPublisher
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusSender _sender;

    public OrderCommandPublisher(string connectionString, string queueName)
    {
        _client = new ServiceBusClient(connectionString);
        _sender = _client.CreateSender(queueName);
    }

    public async Task PublishOrderCreatedAsync(OrderCreatedCommand command)
    {
        var message = new ServiceBusMessage(JsonSerializer.Serialize(command))
        {
            ContentType = "application/json",
            MessageId = command.OrderId.ToString(),
            CorrelationId = command.CorrelationId,
            Subject = "OrderCreated"
        };

        // Add custom properties for routing/filtering
        message.ApplicationProperties["OrderType"] = command.OrderType;
        message.ApplicationProperties["CustomerId"] = command.CustomerId;

        await _sender.SendMessageAsync(message);
    }

    public async ValueTask DisposeAsync()
    {
        await _sender.DisposeAsync();
        await _client.DisposeAsync();
    }
}
```

### Azure Service Bus Consumer (C#)

```csharp
using Azure.Messaging.ServiceBus;

public class OrderCommandProcessor : BackgroundService
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusProcessor _processor;
    private readonly ILogger<OrderCommandProcessor> _logger;
    private readonly IServiceScopeFactory _scopeFactory;

    public OrderCommandProcessor(
        IConfiguration configuration,
        ILogger<OrderCommandProcessor> logger,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;

        var connectionString = configuration["ServiceBus:ConnectionString"];
        var queueName = configuration["ServiceBus:QueueName"];

        _client = new ServiceBusClient(connectionString);
        _processor = _client.CreateProcessor(queueName, new ServiceBusProcessorOptions
        {
            MaxConcurrentCalls = 10,
            AutoCompleteMessages = false,
            MaxAutoLockRenewalDuration = TimeSpan.FromMinutes(5)
        });

        _processor.ProcessMessageAsync += ProcessMessageAsync;
        _processor.ProcessErrorAsync += ProcessErrorAsync;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _processor.StartProcessingAsync(stoppingToken);
        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    private async Task ProcessMessageAsync(ProcessMessageEventArgs args)
    {
        try
        {
            var body = args.Message.Body.ToString();
            var command = JsonSerializer.Deserialize<OrderCreatedCommand>(body);

            _logger.LogInformation("Processing order {OrderId}", command.OrderId);

            using var scope = _scopeFactory.CreateScope();
            var handler = scope.ServiceProvider.GetRequiredService<IOrderCommandHandler>();
            await handler.HandleAsync(command);

            // Complete the message (remove from queue)
            await args.CompleteMessageAsync(args.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message {MessageId}", args.Message.MessageId);

            // Abandon message - will be retried (eventually dead-lettered if max delivery count exceeded)
            await args.AbandonMessageAsync(args.Message);
        }
    }

    private Task ProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Service Bus error in {Source}", args.ErrorSource);
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
        await _processor.DisposeAsync();
        await _client.DisposeAsync();
    }
}
```

---

## Event Hubs Examples

### Event Hubs Producer (C#)

```csharp
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;

public class TelemetryEventPublisher
{
    private readonly EventHubProducerClient _producerClient;

    public TelemetryEventPublisher(string connectionString, string eventHubName)
    {
        _producerClient = new EventHubProducerClient(connectionString, eventHubName);
    }

    public async Task PublishTelemetryBatchAsync(IEnumerable<DeviceTelemetry> telemetryData)
    {
        using var eventBatch = await _producerClient.CreateBatchAsync();

        foreach (var telemetry in telemetryData)
        {
            var eventData = new EventData(JsonSerializer.SerializeToUtf8Bytes(telemetry))
            {
                ContentType = "application/json"
            };

            // Partition key ensures events from same device go to same partition (ordering)
            eventData.Properties["DeviceId"] = telemetry.DeviceId;

            if (!eventBatch.TryAdd(eventData))
            {
                // Batch full - send and create new batch
                await _producerClient.SendAsync(eventBatch);
                eventBatch.Dispose();
                eventBatch = await _producerClient.CreateBatchAsync();
                eventBatch.TryAdd(eventData);
            }
        }

        if (eventBatch.Count > 0)
        {
            await _producerClient.SendAsync(eventBatch);
        }
    }

    public async ValueTask DisposeAsync()
    {
        await _producerClient.DisposeAsync();
    }
}
```

### Event Hubs Consumer (C#)

```csharp
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.EventHubs.Processor;
using Azure.Storage.Blobs;

public class TelemetryEventProcessor : BackgroundService
{
    private readonly EventProcessorClient _processor;
    private readonly ILogger<TelemetryEventProcessor> _logger;
    private readonly IServiceScopeFactory _scopeFactory;

    public TelemetryEventProcessor(
        IConfiguration configuration,
        ILogger<TelemetryEventProcessor> logger,
        IServiceScopeFactory scopeFactory)
    {
        _logger = logger;
        _scopeFactory = scopeFactory;

        var ehubConnectionString = configuration["EventHubs:ConnectionString"];
        var eventHubName = configuration["EventHubs:EventHubName"];
        var blobConnectionString = configuration["Storage:ConnectionString"];
        var blobContainerName = configuration["Storage:CheckpointContainer"];

        var storageClient = new BlobContainerClient(blobConnectionString, blobContainerName);

        _processor = new EventProcessorClient(
            storageClient,
            EventHubConsumerClient.DefaultConsumerGroupName,
            ehubConnectionString,
            eventHubName);

        _processor.ProcessEventAsync += ProcessEventAsync;
        _processor.ProcessErrorAsync += ProcessErrorAsync;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _processor.StartProcessingAsync(stoppingToken);
        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    private async Task ProcessEventAsync(ProcessEventArgs args)
    {
        try
        {
            if (args.Data == null) return;

            var telemetry = JsonSerializer.Deserialize<DeviceTelemetry>(args.Data.Body.ToArray());

            _logger.LogInformation("Processing telemetry from device {DeviceId}", telemetry.DeviceId);

            using var scope = _scopeFactory.CreateScope();
            var handler = scope.ServiceProvider.GetRequiredService<ITelemetryHandler>();
            await handler.HandleAsync(telemetry);

            // Update checkpoint (tracks progress)
            await args.UpdateCheckpointAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing event from partition {PartitionId}", args.Partition.PartitionId);
        }
    }

    private Task ProcessErrorAsync(ProcessErrorEventArgs args)
    {
        _logger.LogError(args.Exception, "Event Hubs error in operation {Operation}", args.Operation);
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await _processor.StopProcessingAsync(cancellationToken);
    }
}
```

---

## Background Jobs Examples

### Hangfire Background Job (C#)

**File:** `Program.cs` (Hangfire registration)

```csharp
var builder = WebApplication.CreateBuilder(args);

// Add Hangfire with SQL Server storage
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(builder.Configuration.GetConnectionString("HangfireDb")));

builder.Services.AddHangfireServer();

var app = builder.Build();

app.UseHangfireDashboard("/hangfire");

app.Run();
```

**File:** `ReportGenerationJob.cs`

```csharp
public class ReportGenerationJob
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportGenerationJob> _logger;

    public ReportGenerationJob(IReportService reportService, ILogger<ReportGenerationJob> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    // Fire-and-forget job
    public async Task GenerateMonthlyReportAsync(int month, int year)
    {
        _logger.LogInformation("Generating report for {Month}/{Year}", month, year);
        await _reportService.GenerateReportAsync(month, year);
    }

    // Scheduled job (called by Hangfire on schedule)
    public async Task DailyCleanupAsync()
    {
        _logger.LogInformation("Running daily cleanup");
        await _reportService.CleanupOldReportsAsync();
    }
}
```

**File:** `ReportController.cs` (enqueueing jobs)

```csharp
[ApiController]
[Route("api/reports")]
public class ReportController : ControllerBase
{
    [HttpPost("generate")]
    public IActionResult GenerateReport([FromBody] GenerateReportRequest request)
    {
        // Fire-and-forget - returns immediately
        var jobId = BackgroundJob.Enqueue<ReportGenerationJob>(
            job => job.GenerateMonthlyReportAsync(request.Month, request.Year));

        return Accepted(new { jobId });
    }

    [HttpPost("schedule-cleanup")]
    public IActionResult ScheduleDailyCleanup()
    {
        // Recurring job - runs every day at 2 AM
        RecurringJob.AddOrUpdate<ReportGenerationJob>(
            "daily-cleanup",
            job => job.DailyCleanupAsync(),
            Cron.Daily(2));

        return Ok();
    }

    [HttpPost("delayed")]
    public IActionResult ScheduleDelayedReport([FromBody] GenerateReportRequest request)
    {
        // Delayed job - runs after 1 hour
        var jobId = BackgroundJob.Schedule<ReportGenerationJob>(
            job => job.GenerateMonthlyReportAsync(request.Month, request.Year),
            TimeSpan.FromHours(1));

        return Accepted(new { jobId });
    }
}
```

---

## Pattern Selection Summary

| Pattern             | Response Time | Coupling | Complexity | Best For                 |
| ------------------- | ------------- | -------- | ---------- | ------------------------ |
| **REST**            | 10-50ms       | Tight    | Low        | Public APIs, CRUD        |
| **gRPC**            | 1-10ms        | Tight    | Medium     | Service-to-service       |
| **GraphQL**         | 10-50ms       | Medium   | Medium     | Mobile, flexible queries |
| **Service Bus**     | 50-200ms      | Loose    | Medium     | Workflows, commands      |
| **Event Hubs**      | 100-500ms     | Loose    | High       | Telemetry, analytics     |
| **Background Jobs** | Async         | Loose    | Low        | Scheduled tasks, retries |

Choose based on your latency tolerance, coupling requirements, and architectural goals. Combine patterns (e.g., REST for frontend, gRPC for backend, Service Bus for workflows) as appropriate.
