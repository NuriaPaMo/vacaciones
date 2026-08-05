# Database Selection – Code Examples

This document provides complete, production-ready code examples for each database technology covered in the skill. All examples follow Bolt Framework constitution mandates and demonstrate best practices.

---

## SQL Database Examples

### Entity Framework Core Setup with SQL Server

**File:** `Program.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// SQL Database with Entity Framework Core
builder.Services.AddDbContext<AppDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("SqlDatabase");
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
        sqlOptions.CommandTimeout(30);
    });
});

// Health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database");

var app = builder.Build();

// Apply migrations on startup (development only)
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}

app.MapHealthChecks("/health");
app.Run();
```

### DbContext Definition

**File:** `AppDbContext.cs`

```csharp
using Microsoft.EntityFrameworkCore;

namespace MyApp.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Product> Products => Set<Product>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure relationships
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Order)
            .WithMany(o => o.Items)
            .HasForeignKey(oi => oi.OrderId);

        modelBuilder.Entity<OrderItem>()
            .HasOne(oi => oi.Product)
            .WithMany()
            .HasForeignKey(oi => oi.ProductId);

        // Configure indexes
        modelBuilder.Entity<Order>()
            .HasIndex(o => o.OrderDate);

        modelBuilder.Entity<Customer>()
            .HasIndex(c => c.Email)
            .IsUnique();

        // Configure value objects
        modelBuilder.Entity<Order>()
            .OwnsOne(o => o.ShippingAddress, address =>
            {
                address.Property(a => a.Street).HasColumnName("ShippingStreet");
                address.Property(a => a.City).HasColumnName("ShippingCity");
                address.Property(a => a.PostalCode).HasColumnName("ShippingPostalCode");
            });
    }
}
```

### Entity Models

**File:** `Order.cs`

```csharp
namespace MyApp.Data;

public class Order
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; }

    // Foreign key
    public Guid CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;

    // Navigation property
    public List<OrderItem> Items { get; set; } = new();

    // Value object (owned entity)
    public Address ShippingAddress { get; set; } = null!;

    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; }
}

public class OrderItem
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal => Quantity * UnitPrice;
}

public class Customer
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public List<Order> Orders { get; set; } = new();
}

public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
}

public record Address(string Street, string City, string PostalCode, string Country);

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled
}
```

### Repository Pattern with EF Core

**File:** `OrderRepository.cs`

```csharp
using Microsoft.EntityFrameworkCore;

namespace MyApp.Data;

public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid id);
    Task<List<Order>> GetCustomerOrdersAsync(Guid customerId);
    Task<Order> CreateAsync(Order order);
    Task UpdateAsync(Order order);
}

public class OrderRepository : IOrderRepository
{
    private readonly AppDbContext _context;

    public OrderRepository(AppDbContext context) => _context = context;

    public async Task<Order?> GetByIdAsync(Guid id)
    {
        return await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Items)
                .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(o => o.Id == id);
    }

    public async Task<List<Order>> GetCustomerOrdersAsync(Guid customerId)
    {
        return await _context.Orders
            .Where(o => o.CustomerId == customerId)
            .OrderByDescending(o => o.OrderDate)
            .Take(50)
            .ToListAsync();
    }

    public async Task<Order> CreateAsync(Order order)
    {
        _context.Orders.Add(order);
        await _context.SaveChangesAsync();
        return order;
    }

    public async Task UpdateAsync(Order order)
    {
        _context.Entry(order).State = EntityState.Modified;
        await _context.SaveChangesAsync();
    }
}
```

### Transaction Handling

```csharp
public class OrderService
{
    private readonly AppDbContext _context;

    public OrderService(AppDbContext context) => _context = context;

    public async Task<Order> CreateOrderWithInventoryUpdateAsync(CreateOrderCommand command)
    {
        // Begin transaction
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // Create order
            var order = new Order
            {
                Id = Guid.NewGuid(),
                OrderNumber = GenerateOrderNumber(),
                OrderDate = DateTime.UtcNow,
                CustomerId = command.CustomerId,
                ShippingAddress = command.ShippingAddress,
                Status = OrderStatus.Pending
            };

            // Add order items and update inventory
            foreach (var item in command.Items)
            {
                var product = await _context.Products.FindAsync(item.ProductId);
                if (product == null)
                    throw new InvalidOperationException($"Product {item.ProductId} not found");

                if (product.StockQuantity < item.Quantity)
                    throw new InvalidOperationException($"Insufficient stock for {product.Name}");

                // Deduct inventory
                product.StockQuantity -= item.Quantity;

                order.Items.Add(new OrderItem
                {
                    Id = Guid.NewGuid(),
                    ProductId = item.ProductId,
                    Quantity = item.Quantity,
                    UnitPrice = product.Price
                });
            }

            order.TotalAmount = order.Items.Sum(i => i.LineTotal);

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // Commit transaction
            await transaction.CommitAsync();

            return order;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    private string GenerateOrderNumber() => $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString("N")[..8].ToUpper()}";
}
```

---

## PostgreSQL Examples

### Entity Framework Core Setup with PostgreSQL

**File:** `Program.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// PostgreSQL with Entity Framework Core
builder.Services.AddDbContext<AppDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("PostgreSQL");
    options.UseNpgsql(connectionString, npgsqlOptions =>
    {
        npgsqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorCodesToAdd: null);
        npgsqlOptions.CommandTimeout(30);
    });
});

var app = builder.Build();
app.Run();
```

### JSONB Column Example (Hybrid Model)

**File:** `ProductCatalog.cs`

```csharp
using System.Text.Json;

namespace MyApp.Data;

public class ProductCatalog
{
    public Guid Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;

    // JSONB column for flexible attributes
    public JsonDocument Attributes { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
}

// DbContext configuration
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<ProductCatalog>()
        .Property(p => p.Attributes)
        .HasColumnType("jsonb");

    // Index on JSONB field
    modelBuilder.Entity<ProductCatalog>()
        .HasIndex(p => p.Attributes)
        .HasMethod("gin");
}
```

### Querying JSONB Columns

```csharp
public class ProductCatalogRepository
{
    private readonly AppDbContext _context;

    public ProductCatalogRepository(AppDbContext context) => _context = context;

    // Query JSONB field
    public async Task<List<ProductCatalog>> FindByColorAsync(string color)
    {
        return await _context.ProductCatalogs
            .Where(p => EF.Functions.JsonContains(p.Attributes, $"{{\"color\": \"{color}\"}}"))
            .ToListAsync();
    }

    // Full-text search on JSONB
    public async Task<List<ProductCatalog>> SearchAttributesAsync(string searchTerm)
    {
        return await _context.ProductCatalogs
            .Where(p => EF.Functions.ToTsVector("english", p.Attributes.RootElement.ToString())
                .Matches(EF.Functions.PlainToTsQuery("english", searchTerm)))
            .ToListAsync();
    }
}
```

---

## Cosmos DB Examples

### Cosmos DB Client Setup

**File:** `Program.cs`

```csharp
using Microsoft.Azure.Cosmos;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Cosmos DB client with managed identity
builder.Services.AddSingleton<CosmosClient>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var endpoint = config["Cosmos:Endpoint"];

    var options = new CosmosClientOptions
    {
        SerializerOptions = new CosmosSerializationOptions
        {
            PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase
        },
        ConnectionMode = ConnectionMode.Direct,
        MaxRetryAttemptsOnRateLimitedRequests = 9,
        MaxRetryWaitTimeOnRateLimitedRequests = TimeSpan.FromSeconds(30)
    };

    return new CosmosClient(endpoint, new DefaultAzureCredential(), options);
});

// Register repositories
builder.Services.AddScoped<IProductRepository, CosmosProductRepository>();

var app = builder.Build();
app.Run();
```

### Cosmos DB Document Model

**File:** `ProductDocument.cs`

```csharp
using System.Text.Json.Serialization;

namespace MyApp.Data;

public class ProductDocument
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("productId")]
    public string ProductId { get; set; } = string.Empty;

    // Partition key
    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string Description { get; set; } = string.Empty;

    [JsonPropertyName("price")]
    public decimal Price { get; set; }

    // Nested complex object
    [JsonPropertyName("specifications")]
    public Dictionary<string, string> Specifications { get; set; } = new();

    [JsonPropertyName("reviews")]
    public List<Review> Reviews { get; set; } = new();

    [JsonPropertyName("createdAt")]
    public DateTime CreatedAt { get; set; }

    [JsonPropertyName("_etag")]
    public string? ETag { get; set; }
}

public class Review
{
    [JsonPropertyName("reviewId")]
    public string ReviewId { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("userId")]
    public string UserId { get; set; } = string.Empty;

    [JsonPropertyName("rating")]
    public int Rating { get; set; }

    [JsonPropertyName("comment")]
    public string Comment { get; set; } = string.Empty;

    [JsonPropertyName("reviewedAt")]
    public DateTime ReviewedAt { get; set; }
}
```

### Cosmos DB Repository Pattern

**File:** `CosmosProductRepository.cs`

```csharp
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Cosmos.Linq;

namespace MyApp.Data;

public interface IProductRepository
{
    Task<ProductDocument?> GetByIdAsync(string id, string partitionKey);
    Task<List<ProductDocument>> GetByCategoryAsync(string category);
    Task<ProductDocument> CreateAsync(ProductDocument product);
    Task<ProductDocument> UpdateAsync(ProductDocument product);
    Task DeleteAsync(string id, string partitionKey);
}

public class CosmosProductRepository : IProductRepository
{
    private readonly Container _container;

    public CosmosProductRepository(CosmosClient cosmosClient, IConfiguration configuration)
    {
        var databaseName = configuration["Cosmos:DatabaseName"];
        var containerName = configuration["Cosmos:ContainerName"];
        _container = cosmosClient.GetContainer(databaseName, containerName);
    }

    public async Task<ProductDocument?> GetByIdAsync(string id, string partitionKey)
    {
        try
        {
            var response = await _container.ReadItemAsync<ProductDocument>(
                id,
                new PartitionKey(partitionKey));
            return response.Resource;
        }
        catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public async Task<List<ProductDocument>> GetByCategoryAsync(string category)
    {
        var queryable = _container.GetItemLinqQueryable<ProductDocument>()
            .Where(p => p.Category == category)
            .OrderByDescending(p => p.CreatedAt);

        using var iterator = queryable.ToFeedIterator();

        var results = new List<ProductDocument>();
        while (iterator.HasMoreResults)
        {
            var response = await iterator.ReadNextAsync();
            results.AddRange(response);
        }

        return results;
    }

    public async Task<ProductDocument> CreateAsync(ProductDocument product)
    {
        product.CreatedAt = DateTime.UtcNow;
        var response = await _container.CreateItemAsync(
            product,
            new PartitionKey(product.Category));
        return response.Resource;
    }

    public async Task<ProductDocument> UpdateAsync(ProductDocument product)
    {
        // Optimistic concurrency with ETag
        var response = await _container.ReplaceItemAsync(
            product,
            product.Id,
            new PartitionKey(product.Category),
            new ItemRequestOptions { IfMatchEtag = product.ETag });

        return response.Resource;
    }

    public async Task DeleteAsync(string id, string partitionKey)
    {
        await _container.DeleteItemAsync<ProductDocument>(
            id,
            new PartitionKey(partitionKey));
    }
}
```

### Cosmos DB Change Feed (Event Sourcing / CQRS)

```csharp
using Microsoft.Azure.Cosmos;

public class ProductChangeFeedProcessor : BackgroundService
{
    private readonly CosmosClient _cosmosClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ProductChangeFeedProcessor> _logger;

    public ProductChangeFeedProcessor(
        CosmosClient cosmosClient,
        IConfiguration configuration,
        ILogger<ProductChangeFeedProcessor> logger)
    {
        _cosmosClient = cosmosClient;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var databaseName = _configuration["Cosmos:DatabaseName"];
        var containerName = _configuration["Cosmos:ContainerName"];
        var leaseContainerName = _configuration["Cosmos:LeaseContainerName"];

        var container = _cosmosClient.GetContainer(databaseName, containerName);
        var leaseContainer = _cosmosClient.GetContainer(databaseName, leaseContainerName);

        var changeFeedProcessor = container
            .GetChangeFeedProcessorBuilder<ProductDocument>("productProcessor", HandleChangesAsync)
            .WithInstanceName("instance1")
            .WithLeaseContainer(leaseContainer)
            .WithStartTime(DateTime.UtcNow.AddDays(-1))
            .Build();

        await changeFeedProcessor.StartAsync();
        _logger.LogInformation("Change feed processor started");

        await Task.Delay(Timeout.Infinite, stoppingToken);

        await changeFeedProcessor.StopAsync();
    }

    private async Task HandleChangesAsync(
        ChangeFeedProcessorContext context,
        IReadOnlyCollection<ProductDocument> changes,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing {Count} changes", changes.Count);

        foreach (var product in changes)
        {
            // Update read model, trigger workflows, send notifications, etc.
            _logger.LogInformation("Product changed: {ProductId} in category {Category}",
                product.ProductId, product.Category);
        }

        await Task.CompletedTask;
    }
}
```

---

## Table Storage Examples

### Azure Table Storage Client Setup

**File:** `Program.cs`

```csharp
using Azure.Data.Tables;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Table Storage client
builder.Services.AddSingleton<TableServiceClient>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var endpoint = new Uri(config["TableStorage:Endpoint"]!);
    return new TableServiceClient(endpoint, new DefaultAzureCredential());
});

builder.Services.AddScoped<IAuditLogRepository, TableStorageAuditLogRepository>();

var app = builder.Build();
app.Run();
```

### Table Entity Model

**File:** `AuditLogEntity.cs`

```csharp
using Azure;
using Azure.Data.Tables;

namespace MyApp.Data;

public class AuditLogEntity : ITableEntity
{
    // Partition key: date (YYYY-MM-DD) for efficient time-based queries
    public string PartitionKey { get; set; } = string.Empty;

    // Row key: GUID for uniqueness
    public string RowKey { get; set; } = Guid.NewGuid().ToString();

    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    // Custom properties
    public string UserId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Resource { get; set; } = string.Empty;
    public string Details { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
}
```

### Table Storage Repository

**File:** `TableStorageAuditLogRepository.cs`

```csharp
using Azure.Data.Tables;

namespace MyApp.Data;

public interface IAuditLogRepository
{
    Task LogAsync(string userId, string action, string resource, string details, string ipAddress);
    Task<List<AuditLogEntity>> GetLogsForDateAsync(DateTime date);
    Task<List<AuditLogEntity>> GetUserLogsAsync(string userId, DateTime startDate, DateTime endDate);
}

public class TableStorageAuditLogRepository : IAuditLogRepository
{
    private readonly TableClient _tableClient;

    public TableStorageAuditLogRepository(TableServiceClient serviceClient, IConfiguration configuration)
    {
        var tableName = configuration["TableStorage:TableName"] ?? "AuditLogs";
        _tableClient = serviceClient.GetTableClient(tableName);
        _tableClient.CreateIfNotExists();
    }

    public async Task LogAsync(string userId, string action, string resource, string details, string ipAddress)
    {
        var entity = new AuditLogEntity
        {
            PartitionKey = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            RowKey = Guid.NewGuid().ToString(),
            UserId = userId,
            Action = action,
            Resource = resource,
            Details = details,
            IpAddress = ipAddress
        };

        await _tableClient.AddEntityAsync(entity);
    }

    public async Task<List<AuditLogEntity>> GetLogsForDateAsync(DateTime date)
    {
        var partitionKey = date.ToString("yyyy-MM-dd");
        var query = _tableClient.QueryAsync<AuditLogEntity>(e => e.PartitionKey == partitionKey);

        var results = new List<AuditLogEntity>();
        await foreach (var entity in query)
        {
            results.Add(entity);
        }

        return results;
    }

    public async Task<List<AuditLogEntity>> GetUserLogsAsync(string userId, DateTime startDate, DateTime endDate)
    {
        var results = new List<AuditLogEntity>();

        // Query across multiple partitions (date range)
        for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
        {
            var partitionKey = date.ToString("yyyy-MM-dd");
            var query = _tableClient.QueryAsync<AuditLogEntity>(
                e => e.PartitionKey == partitionKey && e.UserId == userId);

            await foreach (var entity in query)
            {
                results.Add(entity);
            }
        }

        return results;
    }
}
```

---

## Redis Cache Examples

### Redis Client Setup

**File:** `Program.cs`

```csharp
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// Redis connection multiplexer (singleton)
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var connectionString = config.GetConnectionString("Redis");
    return ConnectionMultiplexer.Connect(connectionString);
});

// Distributed cache with Redis
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
    options.InstanceName = "MyApp:";
});

builder.Services.AddScoped<IProductCacheService, ProductCacheService>();

var app = builder.Build();
app.Run();
```

### Caching Pattern (Cache-Aside)

**File:** `ProductCacheService.cs`

```csharp
using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

namespace MyApp.Services;

public interface IProductCacheService
{
    Task<ProductDocument?> GetProductAsync(string id);
    Task SetProductAsync(ProductDocument product);
    Task RemoveProductAsync(string id);
}

public class ProductCacheService : IProductCacheService
{
    private readonly IDistributedCache _cache;
    private readonly IProductRepository _repository;
    private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(15);

    public ProductCacheService(IDistributedCache cache, IProductRepository repository)
    {
        _cache = cache;
        _repository = repository;
    }

    public async Task<ProductDocument?> GetProductAsync(string id)
    {
        // Try cache first
        var cachedJson = await _cache.GetStringAsync($"product:{id}");
        if (cachedJson != null)
        {
            return JsonSerializer.Deserialize<ProductDocument>(cachedJson);
        }

        // Cache miss - fetch from database
        var product = await _repository.GetByIdAsync(id, "categoryPartitionKey");
        if (product != null)
        {
            // Store in cache
            await SetProductAsync(product);
        }

        return product;
    }

    public async Task SetProductAsync(ProductDocument product)
    {
        var json = JsonSerializer.Serialize(product);
        await _cache.SetStringAsync(
            $"product:{product.Id}",
            json,
            new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = _cacheExpiration });
    }

    public async Task RemoveProductAsync(string id)
    {
        await _cache.RemoveAsync($"product:{id}");
    }
}
```

### Redis Advanced Patterns

```csharp
using StackExchange.Redis;

public class RedisPatternsService
{
    private readonly IDatabase _db;

    public RedisPatternsService(IConnectionMultiplexer redis)
    {
        _db = redis.GetDatabase();
    }

    // Leaderboard (Sorted Set)
    public async Task AddScoreAsync(string userId, double score)
    {
        await _db.SortedSetAddAsync("leaderboard", userId, score);
    }

    public async Task<List<(string UserId, double Score)>> GetTopPlayersAsync(int count)
    {
        var entries = await _db.SortedSetRangeByRankWithScoresAsync(
            "leaderboard",
            start: 0,
            stop: count - 1,
            order: Order.Descending);

        return entries.Select(e => (e.Element.ToString(), e.Score)).ToList();
    }

    // Rate Limiting (Sliding Window)
    public async Task<bool> IsRateLimitedAsync(string userId, int maxRequests, TimeSpan window)
    {
        var key = $"ratelimit:{userId}";
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var windowStart = now - (long)window.TotalMilliseconds;

        // Remove old entries
        await _db.SortedSetRemoveRangeByScoreAsync(key, 0, windowStart);

        // Count current requests
        var currentCount = await _db.SortedSetLengthAsync(key);

        if (currentCount >= maxRequests)
        {
            return true; // Rate limited
        }

        // Add new request
        await _db.SortedSetAddAsync(key, Guid.NewGuid().ToString(), now);
        await _db.KeyExpireAsync(key, window);

        return false;
    }

    // Distributed Lock
    public async Task<bool> AcquireLockAsync(string resource, string lockId, TimeSpan expiration)
    {
        return await _db.StringSetAsync(
            $"lock:{resource}",
            lockId,
            expiration,
            When.NotExists);
    }

    public async Task<bool> ReleaseLockAsync(string resource, string lockId)
    {
        var script = @"
            if redis.call('get', KEYS[1]) == ARGV[1] then
                return redis.call('del', KEYS[1])
            else
                return 0
            end";

        var result = await _db.ScriptEvaluateAsync(
            script,
            new RedisKey[] { $"lock:{resource}" },
            new RedisValue[] { lockId });

        return (int)result == 1;
    }
}
```

---

## Database Selection Summary

| Database          | Setup Complexity          | Query Flexibility  | Scale Ceiling    | Best Use Case                 |
| ----------------- | ------------------------- | ------------------ | ---------------- | ----------------------------- |
| **SQL Database**  | Low (EF Core)             | High (SQL)         | 50K RPS          | Transactional systems         |
| **PostgreSQL**    | Low (EF Core)             | High (SQL + JSONB) | 50K RPS          | Cost-optimized relational     |
| **Cosmos DB**     | Medium (SDK)              | Medium (NoSQL)     | Millions RPS     | Global scale, flexible schema |
| **Table Storage** | Low (SDK)                 | Low (PK + RK)      | Hundreds K RPS   | Audit logs, telemetry         |
| **Redis**         | Low (StackExchange.Redis) | Low (Key-value)    | Millions ops/sec | Caching, real-time features   |

Choose based on your data model, scale requirements, and consistency needs. Combine multiple databases (polyglot persistence) for optimal architecture.
