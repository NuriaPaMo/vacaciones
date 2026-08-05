# Async/Await Patterns for .NET

Master asynchronous programming in .NET with modern async/await patterns, best practices, and
performance optimizations.

## Core Concepts

### Basic Async/Await Pattern

```csharp
// ✅ Correct: async all the way
public class ProductService
{
    private readonly IProductRepository _repository;

    public async Task<Product> GetProductAsync(string id, CancellationToken ct)
    {
        // await keyword unwraps Task<Product> to Product
        var product = await _repository.GetByIdAsync(id, ct);

        if (product == null)
            throw new NotFoundException($"Product {id} not found");

        return product;
    }

    public async Task<List<Product>> GetLowStockProductsAsync(
        int threshold,
        CancellationToken ct)
    {
        // Chain async calls
        var products = await _repository.GetAllAsync(ct);

        // Filter synchronously after await
        return products
            .Where(p => p.Stock < threshold)
            .ToList();
    }
}
```

### CancellationToken Usage

**Always accept and pass CancellationToken**:

```csharp
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;

    public async Task CreateOrderAsync(
        CreateOrderRequest request,
        CancellationToken ct = default) // Default to CancellationToken.None
    {
        ct.ThrowIfCancellationRequested(); // Check early

        var order = new Order(request.CustomerId, request.Items);

        await _repository.SaveAsync(order, ct);

        // Propagate cancellation token through all async calls
        await _emailService.SendConfirmationAsync(order.CustomerEmail, ct);

        ct.ThrowIfCancellationRequested(); // Check after long operations
    }
}
```

**Controller usage**:

```csharp
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _service;

    [HttpPost]
    public async Task<ActionResult<OrderResponse>> CreateOrder(
        CreateOrderRequest request,
        CancellationToken ct) // ASP.NET Core provides this automatically
    {
        var result = await _service.CreateOrderAsync(request, ct);
        return Ok(result);
    }
}
```

## Advanced Patterns

### Async Streaming with IAsyncEnumerable

```csharp
public class LogService
{
    public async IAsyncEnumerable<LogEntry> StreamLogsAsync(
        [EnumeratorCancellation] CancellationToken ct = default)
    {
        await foreach (var line in ReadLinesAsync("app.log", ct))
        {
            yield return ParseLogEntry(line);

            // Throttle to avoid overwhelming caller
            await Task.Delay(10, ct);
        }
    }

    private async IAsyncEnumerable<string> ReadLinesAsync(
        string filePath,
        [EnumeratorCancellation] CancellationToken ct)
    {
        using var reader = new StreamReader(filePath);

        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync(ct);
            if (line != null)
                yield return line;
        }
    }
}

// Consumer
public async Task ProcessLogsAsync(CancellationToken ct)
{
    await foreach (var log in _logService.StreamLogsAsync(ct))
    {
        Console.WriteLine($"{log.Timestamp}: {log.Message}");

        if (log.Level == "ERROR")
            await _alertService.SendAlertAsync(log, ct);
    }
}
```

### Parallel Async Operations

#### Task.WhenAll (parallel execution)

```csharp
public class ReportService
{
    public async Task<CombinedReport> GenerateReportAsync(CancellationToken ct)
    {
        // Execute multiple async operations in parallel
        var salesTask = _salesService.GetSalesDataAsync(ct);
        var inventoryTask = _inventoryService.GetInventoryDataAsync(ct);
        var customersTask = _customerService.GetCustomersDataAsync(ct);

        // Wait for all to complete
        await Task.WhenAll(salesTask, inventoryTask, customersTask);

        return new CombinedReport
        {
            Sales = salesTask.Result,      // All tasks completed, safe to access .Result
            Inventory = inventoryTask.Result,
            Customers = customersTask.Result
        };
    }
}
```

#### Task.WhenAny (race condition)

```csharp
public class CacheService
{
    public async Task<Product?> GetFromMultipleCachesAsync(
        string key,
        CancellationToken ct)
    {
        // Try both caches simultaneously, return whichever responds first
        var memoryTask = GetFromMemoryCacheAsync(key, ct);
        var redisTask = GetFromRedisAsync(key, ct);

        var completed = await Task.WhenAny(memoryTask, redisTask);

        return await completed; // Return result from fastest cache
    }
}
```

### ConfigureAwait(false) in Libraries

**Rule**: Use `ConfigureAwait(false)` in library code to avoid capturing SynchronizationContext.

```csharp
// Library code (not UI or ASP.NET Core controller)
public class CryptoService
{
    public async Task<string> EncryptAsync(string plainText)
    {
        using var aes = Aes.Create();

        aes.GenerateKey();
        aes.GenerateIV();

        using var encryptor = aes.CreateEncryptor();
        using var ms = new MemoryStream();
        using var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
        using var sw = new StreamWriter(cs);

        // ConfigureAwait(false) - we don't need to resume on the same context
        await sw.WriteAsync(plainText).ConfigureAwait(false);
        await sw.FlushAsync().ConfigureAwait(false);

        return Convert.ToBase64String(ms.ToArray());
    }
}
```

**Rule**: Don't use `ConfigureAwait(false)` in:

- ASP.NET Core controllers (no SynchronizationContext to worry about)
- UI applications (WPF, WinForms) where you need to resume on UI thread

## Performance Patterns

### Avoid Async Overhead for Fast Operations

```csharp
public class CacheService
{
    private readonly IMemoryCache _cache;

    // ✅ Good: ValueTask for potentially synchronous operation
    public ValueTask<Product?> GetAsync(string key)
    {
        // Check cache synchronously
        if (_cache.TryGetValue(key, out Product? cached))
        {
            // Return completed ValueTask without allocation
            return new ValueTask<Product?>(cached);
        }

        // Cache miss - actually async database call
        return new ValueTask<Product?>(_repository.GetByIdAsync(key));
    }
}
```

### Avoid Async Void

```csharp
// ❌ BAD: async void (exceptions cannot be caught)
public async void ProcessOrder(string orderId)
{
    await _orderService.ProcessAsync(orderId);
}

// ✅ GOOD: async Task
public async Task ProcessOrderAsync(string orderId)
{
    await _orderService.ProcessAsync(orderId);
}

// ⚠️ EXCEPTION: Event handlers can be async void
public class OrderEventHandler
{
    public async void OnOrderCreated(object sender, OrderEventArgs e)
    {
        try
        {
            await _emailService.SendConfirmationAsync(e.Order.Email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send order confirmation");
        }
    }
}
```

### Timeout Pattern

```csharp
public class ExternalApiClient
{
    public async Task<ApiResponse> CallApiAsync(
        string endpoint,
        CancellationToken ct)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        cts.CancelAfter(TimeSpan.FromSeconds(30)); // 30s timeout

        try
        {
            return await _httpClient.GetFromJsonAsync<ApiResponse>(
                endpoint,
                cts.Token);
        }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested)
        {
            // Timeout occurred (not user cancellation)
            throw new TimeoutException($"API call to {endpoint} timed out");
        }
    }
}
```

## Error Handling

### Try-Catch in Async

```csharp
public async Task<Result<Order>> CreateOrderAsync(
    CreateOrderRequest request,
    CancellationToken ct)
{
    try
    {
        var order = new Order(request);
        await _repository.SaveAsync(order, ct);

        await _eventBus.PublishAsync(new OrderCreatedEvent(order), ct);

        return Result.Success(order);
    }
    catch (ValidationException ex)
    {
        _logger.LogWarning(ex, "Order validation failed");
        return Result.Failure<Order>("VALIDATION_ERROR", ex.Message);
    }
    catch (DbUpdateException ex)
    {
        _logger.LogError(ex, "Database error creating order");
        return Result.Failure<Order>("DATABASE_ERROR", "Failed to save order");
    }
    catch (OperationCanceledException)
    {
        _logger.LogInformation("Order creation cancelled");
        throw; // Re-throw cancellation
    }
}
```

## Best Practices Summary

### ✅ DO

- ✅ Use `async Task<T>` for async methods returning values
- ✅ Use `async Task` for async void methods
- ✅ Accept `CancellationToken ct = default` parameter
- ✅ Propagate `CancellationToken` to all async calls
- ✅ Use `Task.WhenAll` for parallel operations
- ✅ Use `ValueTask<T>` for frequently synchronous operations
- ✅ Use `ConfigureAwait(false)` in library code
- ✅ Check `ct.ThrowIfCancellationRequested()` before long operations

### ❌ DON'T

- ❌ Use `async void` (except event handlers)
- ❌ Block on async with `.Result` or `.Wait()`
- ❌ Forget to pass `CancellationToken` through call chain
- ❌ Use `ConfigureAwait(false)` in ASP.NET Core controllers (unnecessary)
- ❌ Mix sync and async code (`Task.Run` for sync in async context)
- ❌ Create `new Task()` manually (use `Task.Run` or `Task.FromResult`)
- ❌ Ignore `OperationCanceledException`

## Common Pitfalls

### Deadlock with .Result

```csharp
// ❌ DEADLOCK: Blocking async call on UI thread
public void Button_Click(object sender, EventArgs e)
{
    var product = GetProductAsync("123").Result; // DEADLOCK!
}

// ✅ CORRECT: Async all the way
public async void Button_Click(object sender, EventArgs e)
{
    var product = await GetProductAsync("123");
}
```

### Fire-and-Forget (Dangerous)

```csharp
// ❌ BAD: Exception will be lost
public void ProcessOrder(string orderId)
{
    _ = ProcessOrderAsync(orderId); // Fire-and-forget
}

// ✅ GOOD: Await or explicitly handle
public async Task ProcessOrderAsync(string orderId)
{
    await _orderService.ProcessAsync(orderId);
}

// ⚠️ ACCEPTABLE: Log exceptions in fire-and-forget
public void ProcessOrder(string orderId)
{
    _ = Task.Run(async () =>
    {
        try
        {
            await _orderService.ProcessAsync(orderId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fire-and-forget task failed");
        }
    });
}
```

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
