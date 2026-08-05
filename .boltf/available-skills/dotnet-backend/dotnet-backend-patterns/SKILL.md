---
name: dotnet-backend-patterns
description: Master C# backend development with Clean Architecture, dependency injection, async/await patterns, Entity Framework Core, Dapper, Result pattern, and SOLID principles. Use for .NET APIs, domain logic, data access layers, or service implementations. Triggers => "C# backend", ".NET backend", "dependency injection", "async programming", "EF Core", "Entity Framework", "clean architecture", "backend patterns .NET", "service layer", "repository pattern", "SOLID". ALWAYS use for .NET backend architecture questions.
---

# .NET Backend Patterns - Clean Architecture & Best Practices

Master C# backend development with proven patterns for dependency injection, async programming, data
access, and error handling.

## When to Use This Skill

✅ Developing .NET Web APIs, microservices, or backend services
✅ Implementing Clean Architecture / Vertical Slice Architecture
✅ Writing async/await code with proper CancellationToken handling
✅ Setting up dependency injection with correct service lifetimes
✅ Choosing between Entity Framework Core and Dapper
✅ Implementing Result<T> pattern for explicit error handling
✅ Optimizing database queries and avoiding N+1 problems
✅ Configuring multi-layer caching (Memory + Redis)

## Project Structure

```text
src/
├── Domain/              # Entities, interfaces, aggregates
│   ├── Entities/
│   ├── ValueObjects/
│   └── Interfaces/
├── Application/         # Use cases, commands, queries (CQRS)
│   ├── Commands/
│   ├── Queries/
│   └── Services/
├── Infrastructure/      # EF Core, Dapper, caching, external APIs
│   ├── Persistence/
│   │   ├── Configurations/  # EF entity configurations
│   │   └── Repositories/
│   ├── Caching/
│   └── ExternalServices/
└── API/                 # Controllers, minimal APIs, middleware
    ├── Controllers/
    ├── Middleware/
    └── Program.cs
```

**Key Principles**:

- 🎯 **Domain** depends on nothing (pure business logic)
- 🔧 **Application** depends on Domain (orchestrates use cases)
- 🏗️ **Infrastructure** depends on Application and Domain (implements interfaces)
- 🌐 **API** depends on all layers (composition root, DI registration)

## Quick Start

### 1. Dependency Injection Setup

```csharp
// Program.cs - API Layer
var builder = WebApplication.CreateBuilder(args);

// Register services from all layers
builder.Services
    .AddDomain()           // Domain services (if any)
    .AddApplication()      // Commands, queries, validators
    .AddInfrastructure(builder.Configuration);  // Repositories, DbContext, Redis

// Infrastructure layer registration (ServiceCollectionExtensions.cs)
public static IServiceCollection AddInfrastructure(
    this IServiceCollection services,
    IConfiguration configuration)
{
    // DbContext (Scoped - one per request)
    services.AddDbContext<AppDbContext>(options =>
        options.UseSqlServer(configuration.GetConnectionString("Default")));

    // Repositories (Scoped - depend on Scoped DbContext)
    services.AddScoped<IProductRepository, ProductRepository>();
    services.AddScoped<IOrderRepository, OrderRepository>();

    // Caching (Singleton - thread-safe, shared)
    services.AddSingleton<IMemoryCache, MemoryCache>();
    services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = configuration.GetConnectionString("Redis");
    });

    // Configuration binding
    services.Configure<CatalogOptions>(
        configuration.GetSection(CatalogOptions.SectionName));

    return services;
}
```

**Service Lifetimes**:

- **Scoped** (✅ Most services): One instance per HTTP request - Use for repositories, business
  services, DbContext
- **Singleton** (⚡ Shared): One instance for app lifetime - Use for caches, configuration,
  thread-safe services
- **Transient** (🔄 Always new): New instance every injection - Use for lightweight, stateless
  helpers

📖 **Deep Dive**: See [Dependency Injection Patterns](references/dependency-injection.md) for keyed
services, factory patterns, Options pattern, and lifetime pitfalls.

### 2. Async/Await Best Practices

```csharp
// ✅ CORRECT: Accept CancellationToken, propagate through call chain
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;

    public async Task<Result<Order>> CreateOrderAsync(
        CreateOrderRequest request,
        CancellationToken ct = default)
    {
        // Validate input
        if (request.Items.Count == 0)
            return Result<Order>.Failure("NO_ITEMS", "At least 1 item required");

        // Create entity
        var order = new Order(request.CustomerId, request.Items);

        // Save to database (propagate ct)
        await _repository.SaveAsync(order, ct);

        // Send confirmation email (propagate ct)
        await _emailService.SendConfirmationAsync(order.CustomerEmail, ct);

        return Result<Order>.Success(order);
    }

    // Parallel execution with Task.WhenAll
    public async Task<OrderSummary> GetSummaryAsync(string orderId, CancellationToken ct)
    {
        var orderTask = _repository.GetByIdAsync(orderId, ct);
        var customerTask = _customerService.GetAsync(orderId, ct);
        var invoiceTask = _invoiceService.GetAsync(orderId, ct);

        await Task.WhenAll(orderTask, customerTask, invoiceTask);

        return new OrderSummary
        {
            Order = orderTask.Result,
            Customer = customerTask.Result,
            Invoice = invoiceTask.Result
        };
    }
}

// ✅ Controller: ASP.NET Core provides CancellationToken automatically
[HttpPost]
public async Task<ActionResult<Order>> CreateOrder(
    CreateOrderRequest request,
    CancellationToken ct) // Cancelled when user disconnects
{
    var result = await _service.CreateOrderAsync(request, ct);
    return result.IsSuccess ? Ok(result.Value) : BadRequest(result.ErrorMessage);
}
```

**Golden Rules**:

- ✅ Always accept `CancellationToken ct = default`
- ✅ Propagate `ct` to all async calls
- ✅ Use `Task.WhenAll` for parallel operations
- ❌ Never block with `.Result` or `.Wait()` (deadlock risk)
- ❌ Never use `async void` (except event handlers)

📖 **Deep Dive**: See [Async/Await Patterns](references/async-patterns.md) for IAsyncEnumerable,
ConfigureAwait, ValueTask, timeout patterns, and error handling.

### 3. Result Pattern (Error Handling Without Exceptions)

```csharp
// Result type (included in references/result-pattern.md)
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string ErrorCode { get; }
    public string ErrorMessage { get; }

    public static Result<T> Success(T value);
    public static Result<T> Failure(string errorCode, string errorMessage);
}

// Service returns Result instead of throwing exceptions
public async Task<Result<Product>> GetByIdAsync(string id, CancellationToken ct)
{
    if (string.IsNullOrWhiteSpace(id))
        return Result<Product>.Failure("INVALID_ID", "ID cannot be empty");

    var product = await _repository.GetByIdAsync(id, ct);

    return product == null
        ? Result<Product>.Failure("NOT_FOUND", $"Product {id} not found")
        : Result<Product>.Success(product);
}

// Controller converts Result to HTTP response
[HttpGet("{id}")]
public async Task<ActionResult<Product>> GetById(string id, CancellationToken ct)
{
    var result = await _service.GetByIdAsync(id, ct);

    return result.IsSuccess
        ? Ok(result.Value)
        : result.ErrorCode switch
        {
            "NOT_FOUND" => NotFound(new { error = result.ErrorMessage }),
            "INVALID_ID" => BadRequest(new { error = result.ErrorMessage }),
            _ => StatusCode(500, new { error = "Internal error" })
        };
}
```

**Benefits**:

- ✅ Explicit error handling (forces caller to check result)
- ✅ Errors are part of method signature (self-documenting)
- ✅ No exception overhead for expected failures (validation, not found)
- ✅ Railway-oriented programming with `Bind` and `Map`

📖 **Deep Dive**: See [Result Pattern](references/result-pattern.md) for railway-oriented
programming, chaining, error accumulation, and complex flows.

### 4. Data Access: EF Core vs Dapper

```csharp
// EF Core: Great for CRUD with relationships
public class OrderRepository : IOrderRepository
{
    private readonly AppDbContext _context;

    // Read-only: Use AsNoTracking (performance boost)
    public async Task<Order?> GetByIdAsync(string id, CancellationToken ct)
    {
        return await _context.Orders
            .AsNoTracking()
            .Include(o => o.OrderLines)    // Eager load
            .ThenInclude(l => l.Product)
            .FirstOrDefaultAsync(o => o.Id == id, ct);
    }

    // Write: Tracking enabled (default)
    public async Task UpdateAsync(Order order, CancellationToken ct)
    {
        _context.Orders.Update(order);
        await _context.SaveChangesAsync(ct);
    }
}

// Dapper: Great for complex queries, reporting, performance
public class ReportRepository : IReportRepository
{
    private readonly IDbConnection _connection;

    public async Task<List<SalesReport>> GetTopSellingProductsAsync(
        DateTime startDate,
        DateTime endDate)
    {
        const string sql = @"
            SELECT
                p.Id,
                p.Name,
                SUM(ol.Quantity) AS TotalSold,
                SUM(ol.Quantity * ol.UnitPrice) AS Revenue
            FROM OrderLines ol
            INNER JOIN Products p ON ol.ProductId = p.Id
            INNER JOIN Orders o ON ol.OrderId = o.Id
            WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
            GROUP BY p.Id, p.Name
            ORDER BY Revenue DESC";

        var results = await _connection.QueryAsync<SalesReport>(
            sql,
            new { StartDate = startDate, EndDate = endDate });

        return results.ToList();
    }
}
```

**Decision Guide**:

- **Use EF Core** when: Complex object graphs, relationships, change tracking, LINQ queries
- **Use Dapper** when: Performance-critical, complex SQL, reporting, legacy databases, dynamic
  queries

📖 **Deep Dive**: See [Data Access Patterns](references/data-access.md) for AsNoTracking,
projections, split queries, N+1 prevention, Dapper multi-mapping, bulk operations.

## Best Practices Highlights

### ✅ DO

- ✅ Use **Scoped** lifetime for repositories and business services
- ✅ Use **AsNoTracking()** for all read-only EF Core queries
- ✅ Accept **CancellationToken** in all async methods
- ✅ Return **Result<T>** instead of throwing exceptions for expected errors
- ✅ Use **IOptions\<T\>** to bind configuration from appsettings.json
- ✅ Use **projections** (`Select`) to load only needed columns
- ✅ Use **Task.WhenAll** for parallel async operations
- ✅ Inject **interfaces**, not concrete classes (testability)

### ❌ DON'T

- ❌ Block on async with `.Result` or `.Wait()` (deadlock risk)
- ❌ Inject **Scoped** services into **Singleton** (captive dependency)
- ❌ Load entire entities when you need 2 fields (`Select` instead)
- ❌ Use `Include` without pagination (cartesian explosion)
- ❌ Iterate database calls in loops (N+1 query problem)
- ❌ Use `async void` (except event handlers - exceptions lost)
- ❌ Forget to propagate `CancellationToken` through call chain

## References

📖 **[Async/Await Patterns](references/async-patterns.md)**
Deep dive: CancellationToken usage, IAsyncEnumerable streaming, Task.WhenAll/WhenAny,
ConfigureAwait, ValueTask, timeout patterns, error handling, common pitfalls.

📖 **[Dependency Injection Patterns](references/dependency-injection.md)**
Deep dive: Service lifetimes (Scoped/Singleton/Transient), Options pattern
(IOptions/IOptionsSnapshot/IOptionsMonitor), keyed services (.NET 8+), factory patterns, decorators,
captive dependencies.

📖 **[Data Access Patterns](references/data-access.md)**
Deep dive: EF Core (AsNoTracking, Include, projections, split queries, change tracking), Dapper
(dynamic SQL, multi-mapping, bulk operations), when to use each, performance tips, N+1 prevention.

📖 **[Result Pattern](references/result-pattern.md)**
Deep dive: Result<T> implementation, railway-oriented programming, chaining with Bind/Map, error
accumulation, complex business flows, converting to HTTP responses.

## Common Pitfalls

### Captive Dependency (Singleton → Scoped)

```csharp
// ❌ WRONG: Singleton captures Scoped dependency
builder.Services.AddSingleton<CacheService>(); // Singleton
builder.Services.AddScoped<AppDbContext>();    // Scoped

public class CacheService
{
    private readonly AppDbContext _db; // ❌ DbContext outlives requests!
    public CacheService(AppDbContext db) { _db = db; }
}

// ✅ FIX: Use IServiceScopeFactory in Singleton
public class CacheService
{
    private readonly IServiceScopeFactory _factory;
    public CacheService(IServiceScopeFactory factory) { _factory = factory; }

    public async Task<Product> GetAsync(string id)
    {
        using var scope = _factory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return await db.Products.FindAsync(id);
    }
}
```

### N+1 Query Problem

```csharp
// ❌ WRONG: 1 query + N queries = 101 queries for 100 orders
var orders = await _context.Orders.ToListAsync();
foreach (var order in orders)
{
    var customer = await _context.Customers.FindAsync(order.CustomerId);
}

// ✅ FIX: Single query with Include
var orders = await _context.Orders
    .Include(o => o.Customer)
    .ToListAsync();
```

---

**Last Updated**: 2026-01-26
**Version**: 2.0 (Progressive Disclosure)
