# Data Access Patterns for .NET

Master Entity Framework Core and Dapper for efficient database operations with performance
optimization strategies.

## Entity Framework Core Patterns

### Repository with AsNoTracking

```csharp
public class ProductRepository : IProductRepository
{
    private readonly AppDbContext _context;

    public ProductRepository(AppDbContext context)
    {
        _context = context;
    }

    // Read-only query: Use AsNoTracking for better performance
    public async Task<List<Product>> GetAllAsync(CancellationToken ct)
    {
        return await _context.Products
            .AsNoTracking() // No change tracking overhead
            .ToListAsync(ct);
    }

    // Write operation: Tracking enabled (default behavior)
    public async Task<Product> UpdateAsync(Product product, CancellationToken ct)
    {
        _context.Products.Update(product); // Attach and track changes
        await _context.SaveChangesAsync(ct);
        return product;
    }
}
```

### Eager Loading with Include

```csharp
public async Task<Order?> GetOrderWithDetailsAsync(string orderId, CancellationToken ct)
{
    return await _context.Orders
        .Include(o => o.OrderLines)       // Eager load lines
        .ThenInclude(l => l.Product)      // Eager load products
        .Include(o => o.Customer)         // Eager load customer
        .AsNoTracking()
        .FirstOrDefaultAsync(o => o.Id == orderId, ct);
}

// Generated SQL: Single query with LEFT JOINs
// SELECT o.*, ol.*, p.*, c.* FROM Orders o
// LEFT JOIN OrderLines ol ON o.Id = ol.OrderId
// LEFT JOIN Products p ON ol.ProductId = p.Id
// LEFT JOIN Customers c ON o.CustomerId = c.Id
// WHERE o.Id = @orderId
```

### Projections (Select Specific Columns)

```csharp
// ❌ BAD: Load entire entity when you only need 2 fields
public async Task<List<ProductSummary>> GetSummariesAsync()
{
    var products = await _context.Products.ToListAsync();
    return products.Select(p => new ProductSummary(p.Name, p.Price)).ToList();
}

// ✅ GOOD: Project to DTO in database query
public async Task<List<ProductSummary>> GetSummariesAsync(CancellationToken ct)
{
    return await _context.Products
        .Select(p => new ProductSummary
        {
            Name = p.Name,
            Price = p.Price
        })
        .ToListAsync(ct);

    // Generated SQL: SELECT Name, Price FROM Products (only 2 columns)
}
```

### Split Queries for Multiple Collections

```csharp
// ❌ CARTESIAN EXPLOSION: Include multiple collections in single query
public async Task<Customer> GetCustomerWithDataAsync(string id, CancellationToken ct)
{
    return await _context.Customers
        .Include(c => c.Orders)      // 1:N
        .Include(c => c.Addresses)   // 1:N
        .FirstAsync(c => c.Id == id, ct);

    // SQL: Cartesian product (10 orders × 5 addresses = 50 rows returned!)
}

// ✅ SPLIT QUERY: Separate queries for each collection
public async Task<Customer> GetCustomerWithDataAsync(string id, CancellationToken ct)
{
    return await _context.Customers
        .Include(c => c.Orders)
        .Include(c => c.Addresses)
        .AsSplitQuery() // Generates 3 queries instead of 1
        .FirstAsync(c => c.Id == id, ct);

    // Query 1: SELECT * FROM Customers WHERE Id = @id
    // Query 2: SELECT * FROM Orders WHERE CustomerId = @id
    // Query 3: SELECT * FROM Addresses WHERE CustomerId = @id
}
```

### Change Tracker Optimization

```csharp
public async Task BulkUpdatePricesAsync(List<string> productIds, CancellationToken ct)
{
    // Load entities with tracking
    var products = await _context.Products
        .Where(p => productIds.Contains(p.Id))
        .ToListAsync(ct);

    foreach (var product in products)
    {
        product.Price *= 1.10m; // 10% increase
    }

    // EF Core detects changes automatically via ChangeTracker
    await _context.SaveChangesAsync(ct);

    // Generated SQL: UPDATE Products SET Price = @p0 WHERE Id = @p1 (for each)
}

// Disable tracking when not needed
public async Task<int> CountActiveProductsAsync(CancellationToken ct)
{
    return await _context.Products
        .AsNoTracking()
        .CountAsync(p => p.IsActive, ct);
}
```

## Dapper Patterns

### Basic Query

```csharp
using Dapper;

public class ProductRepository
{
    private readonly IDbConnection _connection;

    public async Task<Product?> GetByIdAsync(string id)
    {
        const string sql = "SELECT * FROM Products WHERE Id = @Id";

        return await _connection.QueryFirstOrDefaultAsync<Product>(
            sql,
            new { Id = id });
    }

    public async Task<List<Product>> GetLowStockAsync(int threshold)
    {
        const string sql = @"
            SELECT Id, Name, Stock, Price
            FROM Products
            WHERE Stock < @Threshold AND IsActive = 1";

        var results = await _connection.QueryAsync<Product>(
            sql,
            new { Threshold = threshold });

        return results.ToList();
    }
}
```

### Dynamic SQL Building

```csharp
public async Task<List<Product>> SearchAsync(
    string? name,
    decimal? minPrice,
    decimal? maxPrice,
    string? sortBy,
    int page,
    int pageSize)
{
    var sql = new StringBuilder("SELECT * FROM Products WHERE 1=1");
    var parameters = new DynamicParameters();

    // Build WHERE clause dynamically
    if (!string.IsNullOrEmpty(name))
    {
        sql.Append(" AND Name LIKE @Name");
        parameters.Add("Name", $"%{name}%");
    }

    if (minPrice.HasValue)
    {
        sql.Append(" AND Price >= @MinPrice");
        parameters.Add("MinPrice", minPrice.Value);
    }

    if (maxPrice.HasValue)
    {
        sql.Append(" AND Price <= @MaxPrice");
        parameters.Add("MaxPrice", maxPrice.Value);
    }

    // Build ORDER BY clause
    sql.Append(" ORDER BY ");
    sql.Append(sortBy switch
    {
        "price" => "Price ASC",
        "price_desc" => "Price DESC",
        "name" => "Name ASC",
        _ => "Id ASC"
    });

    // Pagination
    sql.Append(" OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY");
    parameters.Add("Offset", (page - 1) * pageSize);
    parameters.Add("PageSize", pageSize);

    var results = await _connection.QueryAsync<Product>(sql.ToString(), parameters);
    return results.ToList();
}
```

### Multi-Mapping (JOIN Queries)

```csharp
public async Task<List<Order>> GetOrdersWithCustomersAsync()
{
    const string sql = @"
        SELECT
            o.Id, o.OrderDate, o.Total,
            c.Id, c.Name, c.Email
        FROM Orders o
        INNER JOIN Customers c ON o.CustomerId = c.Id";

    var orderDict = new Dictionary<string, Order>();

    await _connection.QueryAsync<Order, Customer, Order>(
        sql,
        (order, customer) =>
        {
            if (!orderDict.TryGetValue(order.Id, out var existingOrder))
            {
                existingOrder = order;
                existingOrder.Customer = customer;
                orderDict.Add(order.Id, existingOrder);
            }

            return existingOrder;
        },
        splitOn: "Id"); // Split at Customer.Id column

    return orderDict.Values.ToList();
}
```

### Bulk Insert

```csharp
public async Task BulkInsertProductsAsync(List<Product> products)
{
    const string sql = @"
        INSERT INTO Products (Id, Name, Price, Stock, CreatedAt)
        VALUES (@Id, @Name, @Price, @Stock, @CreatedAt)";

    // Execute same SQL for each product in single round-trip
    await _connection.ExecuteAsync(sql, products);

    // Dapper generates: INSERT ... VALUES (...), (...), (...)
}
```

### Stored Procedures

```csharp
public async Task<List<Product>> GetTopSellingProductsAsync(int topN)
{
    var results = await _connection.QueryAsync<Product>(
        "GetTopSellingProducts",
        new { TopN = topN },
        commandType: CommandType.StoredProcedure);

    return results.ToList();
}
```

## When to Use EF Core vs Dapper

### Use Entity Framework Core

✅ **Complex object graphs** - Entities with relationships (1:1, 1:N, N:N)  
✅ **Change tracking** - Update entities and automatically detect changes  
✅ **Lazy loading** - Load related data on-demand  
✅ **Convention-based** - Less boilerplate, automatic schema inference  
✅ **LINQ queries** - Type-safe queries in C#  
✅ **Migrations** - Database schema versioning

**Example use case**: CRUD operations on domain entities with relationships

```csharp
// EF Core excels at this
var order = await _context.Orders
    .Include(o => o.OrderLines)
    .ThenInclude(l => l.Product)
    .FirstAsync(o => o.Id == orderId);

order.OrderLines.Add(new OrderLine { ProductId = "123", Quantity = 2 });
await _context.SaveChangesAsync(); // Automatically tracks changes
```

### Use Dapper

✅ **Performance-critical queries** - 2-3x faster than EF Core  
✅ **Complex SQL** - Stored procedures, CTEs, window functions  
✅ **Dynamic queries** - Build SQL conditionally at runtime  
✅ **Read-only scenarios** - Reporting, analytics, DTOs  
✅ **Legacy databases** - Non-standard schemas, views

**Example use case**: Complex reporting query with dynamic filters

```csharp
// Dapper excels at this
const string sql = @"
    WITH RankedProducts AS (
        SELECT
            p.Id,
            p.Name,
            SUM(ol.Quantity) AS TotalSold,
            ROW_NUMBER() OVER (PARTITION BY c.Name ORDER BY SUM(ol.Quantity) DESC) AS Rank
        FROM Products p
        INNER JOIN OrderLines ol ON p.Id = ol.ProductId
        INNER JOIN Categories c ON p.CategoryId = c.Id
        WHERE ol.CreatedAt >= @StartDate
        GROUP BY p.Id, p.Name, c.Name
    )
    SELECT * FROM RankedProducts WHERE Rank <= 10";

var topProducts = await _connection.QueryAsync<ProductRank>(
    sql,
    new { StartDate = DateTime.UtcNow.AddMonths(-1) });
```

### Hybrid Approach (Best of Both Worlds)

```csharp
public class OrderService
{
    private readonly AppDbContext _context;      // EF Core for writes
    private readonly IDbConnection _connection;  // Dapper for reads

    // Write with EF Core (change tracking, validation)
    public async Task<Result> CreateOrderAsync(CreateOrderRequest request, CancellationToken ct)
    {
        var order = new Order(request.CustomerId, request.Items);

        _context.Orders.Add(order);
        await _context.SaveChangesAsync(ct);

        return Result.Success();
    }

    // Read with Dapper (performance)
    public async Task<List<OrderSummary>> GetOrderSummariesAsync(string customerId)
    {
        const string sql = @"
            SELECT
                o.Id,
                o.OrderDate,
                o.Total,
                COUNT(ol.Id) AS ItemCount
            FROM Orders o
            LEFT JOIN OrderLines ol ON o.Id = ol.OrderId
            WHERE o.CustomerId = @CustomerId
            GROUP BY o.Id, o.OrderDate, o.Total
            ORDER BY o.OrderDate DESC";

        var results = await _connection.QueryAsync<OrderSummary>(
            sql,
            new { CustomerId = customerId });

        return results.ToList();
    }
}
```

## Performance Tips

### ✅ DO

- ✅ Use `AsNoTracking()` for read-only queries (EF Core)
- ✅ Use projections (`Select`) to load only needed columns
- ✅ Use `AsSplitQuery()` for multiple collections (EF Core)
- ✅ Use Dapper for complex analytical queries
- ✅ Use parameterized queries (both EF Core and Dapper)
- ✅ Use `await` properly (don't block with `.Result`)

### ❌ DON'T

- ❌ Load entire entity when you need 2 fields (`Select` instead)
- ❌ Use `Include` for large collections without pagination
- ❌ Iterate database calls in loops (N+1 problem)
- ❌ Concatenate SQL strings (SQL injection risk)
- ❌ Use `ToList()` before filtering (filter in database)

## Common Pitfalls

### N+1 Query Problem

```csharp
// ❌ BAD: 1 query for orders + N queries for customers
var orders = await _context.Orders.ToListAsync();
foreach (var order in orders)
{
    var customer = await _context.Customers.FindAsync(order.CustomerId); // N queries!
}

// ✅ GOOD: Single query with JOIN
var orders = await _context.Orders
    .Include(o => o.Customer)
    .ToListAsync();
```

### Client-Side Evaluation

```csharp
// ❌ BAD: Filter in C# (loads all products into memory)
var activeProducts = _context.Products
    .ToList() // Loads ALL products
    .Where(p => p.IsActive) // Filters in C#
    .ToList();

// ✅ GOOD: Filter in database
var activeProducts = await _context.Products
    .Where(p => p.IsActive) // SQL WHERE clause
    .ToListAsync();
```

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
