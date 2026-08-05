# Dependency Injection Patterns for .NET

Master dependency injection in .NET with service lifetimes, factory patterns, Options pattern, and
advanced registration techniques.

## Service Lifetimes

### Scoped (Default for Most Services)

**Lifetime**: One instance per HTTP request (or scope in background services).

```csharp
// Registration
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ICartRepository, CartRepository>();

// Usage in controller (automatic DI)
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService; // Same instance throughout request
    }
}

// Usage in background service (manual scope)
public class OrderProcessingWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public OrderProcessingWorker(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            // Create new scope for each iteration
            using var scope = _scopeFactory.CreateScope();
            var orderService = scope.ServiceProvider.GetRequiredService<IOrderService>();

            await orderService.ProcessPendingOrdersAsync(ct);
            await Task.Delay(TimeSpan.FromMinutes(1), ct);
        }
    }
}
```

**When to use Scoped**:

- ✅ Services that interact with database (DbContext is Scoped)
- ✅ Services that maintain request-specific state
- ✅ Most business logic services
- ✅ Repositories (they usually depend on Scoped DbContext)

### Singleton (One Instance for Application Lifetime)

**Lifetime**: Created once, shared across all requests.

```csharp
// Registration
builder.Services.AddSingleton<IMemoryCache, MemoryCache>();
builder.Services.AddSingleton<IPricingEngine, PricingEngine>();

// Thread-safe singleton service
public class PricingEngine : IPricingEngine
{
    private readonly ConcurrentDictionary<string, decimal> _cache = new();

    public decimal CalculatePrice(string productId, int quantity)
    {
        return _cache.GetOrAdd(productId, _ =>
        {
            // Expensive calculation cached for lifetime of app
            return CalculateBasePriceFromRules(productId) * quantity;
        });
    }
}
```

**When to use Singleton**:

- ✅ Thread-safe caches (IMemoryCache, ConcurrentDictionary)
- ✅ Configuration services (read-only)
- ✅ Heavy initialization services (ML models, pricing engines)
- ❌ Services with state (will leak across requests)
- ❌ Services depending on Scoped services (validation error at runtime)

### Transient (New Instance Every Time)

**Lifetime**: New instance for every injection.

```csharp
// Registration
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();
builder.Services.AddTransient<IGuidGenerator, GuidGenerator>();

// Example: Lightweight, stateless service
public class GuidGenerator : IGuidGenerator
{
    public Guid NewGuid() => Guid.NewGuid();
}

// Multiple injections = multiple instances
public class UserService
{
    private readonly IGuidGenerator _gen1;
    private readonly IGuidGenerator _gen2;

    public UserService(IGuidGenerator gen1, IGuidGenerator gen2)
    {
        // gen1 and gen2 are DIFFERENT instances
        _gen1 = gen1;
        _gen2 = gen2;
    }
}
```

**When to use Transient**:

- ✅ Lightweight, stateless services
- ✅ Services with operation-specific state
- ✅ When you need fresh instance every time
- ❌ Heavy services (DbContext should be Scoped, not Transient)
- ❌ Thread-safe caches (should be Singleton)

## Options Pattern

### Basic Options

```csharp
// appsettings.json
{
  "EmailSettings": {
    "SmtpHost": "smtp.example.com",
    "SmtpPort": 587,
    "FromEmail": "noreply@example.com"
  }
}

// Configuration class
public class EmailSettings
{
    public string SmtpHost { get; set; } = string.Empty;
    public int SmtpPort { get; set; }
    public string FromEmail { get; set; } = string.Empty;
}

// Registration
builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

// Usage with IOptions<T>
public class EmailService
{
    private readonly EmailSettings _settings;

    public EmailService(IOptions<EmailSettings> options)
    {
        _settings = options.Value; // Snapshot at construction time
    }

    public async Task SendAsync(string to, string subject, string body)
    {
        using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort);
        // ...
    }
}
```

### IOptionsSnapshot<T> (Reloads on Change)

```csharp
// Use in SCOPED services to get updated config per request
public class PricingService
{
    private readonly PricingSettings _settings;

    public PricingService(IOptionsSnapshot<PricingSettings> options)
    {
        // Re-evaluated per request (if config file changes)
        _settings = options.Value;
    }
}
```

### IOptionsMonitor<T> (Reacts to Changes)

```csharp
// Use in SINGLETON services to react to config changes
public class FeatureFlagService
{
    private readonly IOptionsMonitor<FeatureFlags> _monitor;

    public FeatureFlagService(IOptionsMonitor<FeatureFlags> monitor)
    {
        _monitor = monitor;

        // Subscribe to changes
        _monitor.OnChange(flags =>
        {
            Console.WriteLine("Feature flags updated!");
        });
    }

    public bool IsEnabled(string feature)
    {
        return _monitor.CurrentValue.EnabledFeatures.Contains(feature);
    }
}
```

## Factory Patterns

### Keyed Services (.NET 8+)

**Best for multiple implementations of same interface**:

```csharp
// Registration with keys
builder.Services.AddKeyedScoped<IPaymentProvider, StripePaymentProvider>("stripe");
builder.Services.AddKeyedScoped<IPaymentProvider, PayPalPaymentProvider>("paypal");
builder.Services.AddKeyedScoped<IPaymentProvider, BankTransferProvider>("bank");

// Usage: Inject with [FromKeyedServices]
public class PaymentService
{
    private readonly IPaymentProvider _stripe;
    private readonly IPaymentProvider _paypal;

    public PaymentService(
        [FromKeyedServices("stripe")] IPaymentProvider stripe,
        [FromKeyedServices("paypal")] IPaymentProvider paypal)
    {
        _stripe = stripe;
        _paypal = paypal;
    }

    public async Task ProcessAsync(string method, decimal amount)
    {
        var provider = method switch
        {
            "stripe" => _stripe,
            "paypal" => _paypal,
            _ => throw new ArgumentException("Invalid payment method")
        };

        await provider.ChargeAsync(amount);
    }
}
```

### Factory with Func<T>

```csharp
// Registration: Singleton factory
builder.Services.AddSingleton<Func<string, IPaymentProvider>>(sp =>
{
    return providerName => providerName switch
    {
        "stripe" => sp.GetRequiredKeyedService<IPaymentProvider>("stripe"),
        "paypal" => sp.GetRequiredKeyedService<IPaymentProvider>("paypal"),
        _ => throw new ArgumentException($"Unknown provider: {providerName}")
    };
});

// Usage
public class CheckoutService
{
    private readonly Func<string, IPaymentProvider> _providerFactory;

    public CheckoutService(Func<string, IPaymentProvider> providerFactory)
    {
        _providerFactory = providerFactory;
    }

    public async Task<Result> ProcessCheckoutAsync(
        string paymentMethod,
        decimal amount)
    {
        var provider = _providerFactory(paymentMethod);
        await provider.ChargeAsync(amount);
        return Result.Success();
    }
}
```

### Explicit Factory Class

```csharp
// Factory interface
public interface IReportFactory
{
    IReport CreateReport(string reportType);
}

// Factory implementation
public class ReportFactory : IReportFactory
{
    private readonly IServiceProvider _serviceProvider;

    public ReportFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public IReport CreateReport(string reportType)
    {
        return reportType switch
        {
            "sales" => _serviceProvider.GetRequiredService<SalesReport>(),
            "inventory" => _serviceProvider.GetRequiredService<InventoryReport>(),
            _ => throw new ArgumentException($"Unknown report type: {reportType}")
        };
    }
}

// Registration
builder.Services.AddScoped<SalesReport>();
builder.Services.AddScoped<InventoryReport>();
builder.Services.AddScoped<IReportFactory, ReportFactory>();
```

## Advanced Registration

### Decorators

```csharp
// Base service
public interface IOrderService
{
    Task CreateOrderAsync(Order order);
}

public class OrderService : IOrderService
{
    private readonly IOrderRepository _repository;

    public async Task CreateOrderAsync(Order order)
    {
        await _repository.SaveAsync(order);
    }
}

// Decorator: Add logging
public class LoggingOrderService : IOrderService
{
    private readonly IOrderService _inner;
    private readonly ILogger<LoggingOrderService> _logger;

    public LoggingOrderService(
        IOrderService inner,
        ILogger<LoggingOrderService> logger)
    {
        _inner = inner;
        _logger = logger;
    }

    public async Task CreateOrderAsync(Order order)
    {
        _logger.LogInformation("Creating order {OrderId}", order.Id);

        await _inner.CreateOrderAsync(order);

        _logger.LogInformation("Order {OrderId} created successfully", order.Id);
    }
}

// Registration (manual decoration)
builder.Services.AddScoped<OrderService>(); // Concrete type
builder.Services.AddScoped<IOrderService>(sp =>
{
    var concrete = sp.GetRequiredService<OrderService>();
    var logger = sp.GetRequiredService<ILogger<LoggingOrderService>>();
    return new LoggingOrderService(concrete, logger);
});
```

### Conditional Registration

```csharp
// Register different implementation based on environment
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddScoped<IEmailService, ConsoleEmailService>();
}
else
{
    builder.Services.AddScoped<IEmailService, SmtpEmailService>();
}

// Register based on configuration
var useCaching = builder.Configuration.GetValue<bool>("Features:EnableCaching");
if (useCaching)
{
    builder.Services.AddSingleton<IMemoryCache, MemoryCache>();
    builder.Services.AddScoped<IProductService, CachedProductService>();
}
else
{
    builder.Services.AddScoped<IProductService, ProductService>();
}
```

### TryAdd (Register Only If Not Already Registered)

```csharp
// Won't override existing registration
builder.Services.TryAddScoped<IOrderService, OrderService>();

// Useful in libraries that provide default implementations
public static class LibraryServiceExtensions
{
    public static IServiceCollection AddMyLibrary(this IServiceCollection services)
    {
        // User can override by registering ICache before calling AddMyLibrary
        services.TryAddSingleton<ICache, MemoryCache>();
        services.AddScoped<IMyLibraryService, MyLibraryService>();
        return services;
    }
}
```

## Best Practices

### ✅ DO

- ✅ Use **Scoped** for most business services and repositories
- ✅ Use **Singleton** for thread-safe caches and configuration
- ✅ Use **Transient** for lightweight, stateless services
- ✅ Use **IOptions<T>** for configuration binding
- ✅ Use **keyed services** (.NET 8+) for multiple implementations
- ✅ Inject interfaces, not concrete classes (testability)
- ✅ Validate lifetimes (Singleton can't depend on Scoped)

### ❌ DON'T

- ❌ Inject `IServiceProvider` to manually resolve (Service Locator anti-pattern)
- ❌ Make Singleton services stateful (race conditions)
- ❌ Make DbContext Singleton (must be Scoped)
- ❌ Inject Scoped services into Singleton (captive dependency)
- ❌ Over-use Transient (performance overhead for heavy services)

## Common Pitfalls

### Captive Dependency

```csharp
// ❌ BAD: Singleton depends on Scoped (DbContext)
builder.Services.AddSingleton<ProductCache>(); // Singleton
builder.Services.AddScoped<ProductDbContext>(); // Scoped

public class ProductCache
{
    private readonly ProductDbContext _dbContext; // ❌ PROBLEM!

    // This DbContext will be "captured" and kept alive for entire app lifetime
    public ProductCache(ProductDbContext dbContext)
    {
        _dbContext = dbContext; // ❌ DbContext should not outlive requests
    }
}

// ✅ FIX: Use IServiceScopeFactory
public class ProductCache
{
    private readonly IServiceScopeFactory _scopeFactory;

    public ProductCache(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    public async Task<Product> GetAsync(string id)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ProductDbContext>();
        return await dbContext.Products.FindAsync(id);
    }
}
```

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
