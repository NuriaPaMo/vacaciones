# Result Pattern for .NET

Implement railway-oriented programming with the Result<T> pattern for explicit error handling
without exceptions.

## Core Result Type

```csharp
public class Result
{
    public bool IsSuccess { get; }
    public bool IsFailure => !IsSuccess;
    public string ErrorCode { get; } = string.Empty;
    public string ErrorMessage { get; } = string.Empty;

    protected Result(bool isSuccess, string errorCode, string errorMessage)
    {
        IsSuccess = isSuccess;
        ErrorCode = errorCode;
        ErrorMessage = errorMessage;
    }

    public static Result Success() => new(true, string.Empty, string.Empty);

    public static Result Failure(string errorCode, string errorMessage)
        => new(false, errorCode, errorMessage);
}

public class Result<T> : Result
{
    public T? Value { get; }

    private Result(T value) : base(true, string.Empty, string.Empty)
    {
        Value = value;
    }

    private Result(string errorCode, string errorMessage) : base(false, errorCode, errorMessage)
    {
        Value = default;
    }

    public static Result<T> Success(T value) => new(value);

    public static new Result<T> Failure(string errorCode, string errorMessage)
        => new(errorCode, errorMessage);
}
```

## Basic Usage

### Service Layer

```csharp
public class ProductService
{
    private readonly IProductRepository _repository;

    public async Task<Result<Product>> GetByIdAsync(string id, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(id))
            return Result<Product>.Failure("INVALID_ID", "Product ID cannot be empty");

        var product = await _repository.GetByIdAsync(id, ct);

        if (product == null)
            return Result<Product>.Failure("NOT_FOUND", $"Product {id} not found");

        return Result<Product>.Success(product);
    }

    public async Task<Result<Product>> CreateAsync(
        CreateProductRequest request,
        CancellationToken ct)
    {
        // Validation
        if (request.Price <= 0)
            return Result<Product>.Failure("INVALID_PRICE", "Price must be greater than 0");

        // Business logic
        var product = new Product(request.Name, request.Price);

        try
        {
            await _repository.SaveAsync(product, ct);
            return Result<Product>.Success(product);
        }
        catch (DbUpdateException ex)
        {
            return Result<Product>.Failure("DATABASE_ERROR", "Failed to save product");
        }
    }
}
```

### Controller Layer

```csharp
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _service;

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
                _ => StatusCode(500, new { error = "Internal server error" })
            };
    }

    [HttpPost]
    public async Task<ActionResult<Product>> Create(
        CreateProductRequest request,
        CancellationToken ct)
    {
        var result = await _service.CreateAsync(request, ct);

        if (result.IsFailure)
        {
            return result.ErrorCode switch
            {
                "INVALID_PRICE" => BadRequest(new { error = result.ErrorMessage }),
                "DATABASE_ERROR" => StatusCode(500, new { error = result.ErrorMessage }),
                _ => StatusCode(500, new { error = "Internal server error" })
            };
        }

        return CreatedAtAction(
            nameof(GetById),
            new { id = result.Value!.Id },
            result.Value);
    }
}
```

## Railway-Oriented Programming

### Chaining Results

```csharp
public static class ResultExtensions
{
    public static Result<TOut> Map<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, TOut> map)
    {
        return result.IsSuccess
            ? Result<TOut>.Success(map(result.Value!))
            : Result<TOut>.Failure(result.ErrorCode, result.ErrorMessage);
    }

    public static async Task<Result<TOut>> MapAsync<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, Task<TOut>> map)
    {
        return result.IsSuccess
            ? Result<TOut>.Success(await map(result.Value!))
            : Result<TOut>.Failure(result.ErrorCode, result.ErrorMessage);
    }

    public static Result<TOut> Bind<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, Result<TOut>> bind)
    {
        return result.IsSuccess
            ? bind(result.Value!)
            : Result<TOut>.Failure(result.ErrorCode, result.ErrorMessage);
    }

    public static async Task<Result<TOut>> BindAsync<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, Task<Result<TOut>>> bind)
    {
        return result.IsSuccess
            ? await bind(result.Value!)
            : Result<TOut>.Failure(result.ErrorCode, result.ErrorMessage);
    }
}
```

### Complex Business Flow

```csharp
public class OrderService
{
    public async Task<Result<Order>> CreateOrderAsync(
        CreateOrderRequest request,
        CancellationToken ct)
    {
        return await ValidateRequest(request)
            .BindAsync(r => GetCustomerAsync(r.CustomerId, ct))
            .BindAsync(customer => CheckCreditLimitAsync(customer, request.Total, ct))
            .BindAsync(customer => CreateOrderEntityAsync(customer, request, ct))
            .BindAsync(order => SaveOrderAsync(order, ct))
            .MapAsync(order => PublishOrderCreatedEventAsync(order, ct));
    }

    private Result<CreateOrderRequest> ValidateRequest(CreateOrderRequest request)
    {
        if (request.Items.Count == 0)
            return Result<CreateOrderRequest>.Failure("NO_ITEMS", "Order must have at least 1 item");

        if (request.Total <= 0)
            return Result<CreateOrderRequest>.Failure("INVALID_TOTAL", "Total must be greater than 0");

        return Result<CreateOrderRequest>.Success(request);
    }

    private async Task<Result<Customer>> GetCustomerAsync(string customerId, CancellationToken ct)
    {
        var customer = await _customerRepository.GetByIdAsync(customerId, ct);

        return customer == null
            ? Result<Customer>.Failure("CUSTOMER_NOT_FOUND", $"Customer {customerId} not found")
            : Result<Customer>.Success(customer);
    }

    private async Task<Result<Customer>> CheckCreditLimitAsync(
        Customer customer,
        decimal orderTotal,
        CancellationToken ct)
    {
        var hasCredit = await _creditService.HasAvailableCreditAsync(customer.Id, orderTotal, ct);

        return hasCredit
            ? Result<Customer>.Success(customer)
            : Result<Customer>.Failure("INSUFFICIENT_CREDIT", "Customer has insufficient credit");
    }

    private Task<Result<Order>> CreateOrderEntityAsync(
        Customer customer,
        CreateOrderRequest request,
        CancellationToken ct)
    {
        var order = new Order(customer.Id, request.Items);
        return Task.FromResult(Result<Order>.Success(order));
    }

    private async Task<Result<Order>> SaveOrderAsync(Order order, CancellationToken ct)
    {
        try
        {
            await _orderRepository.SaveAsync(order, ct);
            return Result<Order>.Success(order);
        }
        catch (DbUpdateException)
        {
            return Result<Order>.Failure("DATABASE_ERROR", "Failed to save order");
        }
    }

    private async Task<Order> PublishOrderCreatedEventAsync(Order order, CancellationToken ct)
    {
        await _eventBus.PublishAsync(new OrderCreatedEvent(order), ct);
        return order;
    }
}
```

## Error Accumulation

```csharp
public class ValidationResult : Result
{
    public List<string> Errors { get; } = new();

    private ValidationResult(List<string> errors) : base(errors.Count == 0, string.Empty, string.Empty)
    {
        Errors = errors;
    }

    public static ValidationResult Success() => new(new List<string>());

    public static ValidationResult Failure(params string[] errors)
        => new(errors.ToList());

    public ValidationResult AddError(string error)
    {
        Errors.Add(error);
        return this;
    }
}

// Usage
public ValidationResult ValidateProduct(CreateProductRequest request)
{
    var errors = new List<string>();

    if (string.IsNullOrWhiteSpace(request.Name))
        errors.Add("Name is required");

    if (request.Price <= 0)
        errors.Add("Price must be greater than 0");

    if (request.Stock < 0)
        errors.Add("Stock cannot be negative");

    return errors.Count == 0
        ? ValidationResult.Success()
        : ValidationResult.Failure(errors.ToArray());
}
```

## Best Practices

### ✅ DO

- ✅ Use Result<T> for operations that can fail predictably
- ✅ Return specific error codes (NOT_FOUND, INVALID_INPUT, etc.)
- ✅ Chain results with `Bind` and `Map` for complex flows
- ✅ Keep error messages user-friendly
- ✅ Convert Result to ActionResult in controllers

### ❌ DON'T

- ❌ Throw exceptions for expected failures (validation, not found)
- ❌ Access `Value` without checking `IsSuccess`
- ❌ Re-throw exceptions caught in Result (log and return Failure)
- ❌ Use Result for programming errors (null reference, etc.)

---

**Return to**: [SKILL.md](../SKILL.md) for main documentation.
