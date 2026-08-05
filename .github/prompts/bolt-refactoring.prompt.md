# Refactoring Prompt

## Agent Reference

> **Primary Agent**: [Surgical Refactorer](../copilot/agents/bolt-surgical-refactorer.md)
> **Phase**: Block 7 - Evolution
> **Constitution**: Read `.boltf/memory/constitution.digest.md` for coding standards and patterns

## Context

Use this prompt when improving code quality, eliminating code smells, or modernizing legacy code. This prompt guides Copilot to act as the **Surgical Refactorer Agent** from the Bolt Framework methodology.

## Instructions

When refactoring:

### 1. Constitution Alignment

- Read `.boltf/memory/constitution.digest.md` for coding standards
- Apply patterns defined in Constitution (SOLID, Clean Code, etc.)
- Use approved languages and frameworks
- Follow naming conventions specified

### 2. Refactoring Principles

- **Behavior Preservation**: Never change functionality
- **Test First**: Ensure coverage before refactoring
- **Small Steps**: Incremental, reversible changes
- **Evidence-Based**: Use static analysis to guide decisions

### 3. Refactoring Techniques

- Extract Method/Class
- Rename for clarity
- Replace conditional with polymorphism
- Introduce design patterns
- Remove duplication

### 4. Output Format

```markdown
# Refactoring Plan: [Component/Module]

## Summary
| Property | Value |
|----------|-------|
| Scope | [Files/Classes affected] |
| Goal | [Improvement objective] |
| Risk | Low/Medium/High |
| Effort | [Estimate] |

## Pre-Conditions
- [ ] Test coverage ≥ 80% for affected code
- [ ] All tests passing
- [ ] No pending changes in affected files
- [ ] Team notified of refactoring

## Code Analysis

### Current State
```

Complexity: 45 (target: <15)
Duplication: 12%
Lines: 800
Test Coverage: 72%

```text

### Issues Identified

| ID | Issue | Type | Severity | Line(s) |
|----|-------|------|----------|---------|
| R-001 | Long method (150 lines) | Complexity | High | 45-195 |
| R-002 | Duplicate validation | Duplication | Medium | 78, 234 |
| R-003 | Magic numbers | Readability | Low | 56, 89, 112 |
| R-004 | God class | Design | High | Entire file |

### SOLID Violations

| Principle | Violation | Location | Fix |
|-----------|-----------|----------|-----|
| SRP | Class handles orders AND payments | OrderService | Extract PaymentService |
| OCP | Switch on order type | ProcessOrder() | Strategy pattern |
| DIP | Direct DB dependency | OrderRepository | Inject interface |

## Refactoring Steps

### Step 1: Extract PaymentService (SRP)

**Goal**: Separate payment logic from order logic

**Before**:
```csharp
public class OrderService
{
    public async Task<Order> CreateOrder(OrderDto dto)
    {
        // Order creation logic (50 lines)
        var order = new Order { /* ... */ };

        // Payment logic mixed in (80 lines)
        var payment = await ProcessPayment(order);
        order.PaymentId = payment.Id;

        // More order logic (30 lines)
        return await _repository.Save(order);
    }

    private async Task<Payment> ProcessPayment(Order order)
    {
        // Payment processing (80 lines)
    }
}
```

**After**:

```csharp
public class OrderService
{
    private readonly IPaymentService _paymentService;

    public OrderService(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    public async Task<Order> CreateOrder(OrderDto dto)
    {
        var order = new Order { /* ... */ };
        var payment = await _paymentService.ProcessPayment(order);
        order.PaymentId = payment.Id;
        return await _repository.Save(order);
    }
}

public class PaymentService : IPaymentService
{
    public async Task<Payment> ProcessPayment(Order order)
    {
        // Payment processing (extracted)
    }
}
```

**Tests to Verify**:

- [ ] All existing OrderService tests pass
- [ ] New PaymentService tests added
- [ ] Integration tests updated

**Rollback Point**: Commit before this step

---

### Step 2: Replace Switch with Strategy (OCP)

**Goal**: Make order processing extensible without modification

**Before**:

```csharp
public decimal CalculateTotal(Order order)
{
    switch (order.Type)
    {
        case OrderType.Standard:
            return order.Subtotal + order.Tax;
        case OrderType.Premium:
            return (order.Subtotal * 0.9m) + order.Tax; // 10% discount
        case OrderType.Wholesale:
            return order.Subtotal * 0.75m; // Tax exempt, 25% off
        default:
            throw new NotSupportedException();
    }
}
```

**After**:

```csharp
public interface IOrderPricingStrategy
{
    decimal CalculateTotal(Order order);
}

public class StandardPricingStrategy : IOrderPricingStrategy
{
    public decimal CalculateTotal(Order order)
        => order.Subtotal + order.Tax;
}

public class PremiumPricingStrategy : IOrderPricingStrategy
{
    public decimal CalculateTotal(Order order)
        => (order.Subtotal * 0.9m) + order.Tax;
}

public class WholesalePricingStrategy : IOrderPricingStrategy
{
    public decimal CalculateTotal(Order order)
        => order.Subtotal * 0.75m;
}

// Usage
public class OrderService
{
    private readonly Dictionary<OrderType, IOrderPricingStrategy> _strategies;

    public decimal CalculateTotal(Order order)
        => _strategies[order.Type].CalculateTotal(order);
}
```

**Tests to Verify**:

- [ ] Each strategy has unit tests
- [ ] Factory/DI properly configured
- [ ] All original test cases covered

---

### Step 3: Extract Magic Numbers to Constants

**Before**:

```csharp
if (order.Total > 1000)  // What is 1000?
{
    discount = 0.1m;     // What is 0.1?
}
if (items.Count > 50)    // What is 50?
{
    // bulk handling
}
```

**After**:

```csharp
public static class OrderConstants
{
    public const decimal FreeShippingThreshold = 1000m;
    public const decimal BulkDiscountRate = 0.10m;
    public const int BulkOrderItemCount = 50;
}

if (order.Total > OrderConstants.FreeShippingThreshold)
{
    discount = OrderConstants.BulkDiscountRate;
}
if (items.Count > OrderConstants.BulkOrderItemCount)
{
    // bulk handling
}
```

## Post-Refactoring Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Complexity | 45 | 12 | -73% |
| Duplication | 12% | 2% | -83% |
| Lines per class | 800 | 200 avg | -75% |
| Test Coverage | 72% | 92% | +20% |

## Verification Checklist

- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] No new warnings from static analysis
- [ ] Performance benchmarks unchanged (±5%)
- [ ] Code review approved
- [ ] Documentation updated

## Rollback Plan

If issues are discovered:

```bash
# Revert to pre-refactoring state
git revert --no-commit HEAD~[N]..HEAD
git commit -m "Revert: [refactoring description]"
```

```text

## Examples

### Input: Identify Code Smells
```csharp
public class UserService
{
    private readonly SqlConnection _db = new SqlConnection("...");

    public User GetUser(int id)
    {
        var cmd = new SqlCommand($"SELECT * FROM Users WHERE Id = {id}", _db);
        // ... 50 more lines
    }

    public void UpdateUser(User user)
    {
        // Duplicate validation
        if (string.IsNullOrEmpty(user.Email)) throw new Exception("Email required");
        if (!user.Email.Contains("@")) throw new Exception("Invalid email");
        // ... 80 more lines with same validation
    }

    public void CreateUser(User user)
    {
        // Same validation repeated
        if (string.IsNullOrEmpty(user.Email)) throw new Exception("Email required");
        if (!user.Email.Contains("@")) throw new Exception("Invalid email");
        // ... 100 more lines
    }

    public void SendWelcomeEmail(User user) { /* ... */ }
    public void SendPasswordReset(User user) { /* ... */ }
    public void GenerateReport() { /* ... */ }
}
```

### Expected Analysis

```markdown
## Issues Found

### Critical
1. **SQL Injection** (R-001): Line 6 - String interpolation in SQL
2. **God Class** (R-002): UserService has 6+ responsibilities

### High
3. **Duplicate Validation** (R-003): Lines 12-13 and 19-20
4. **Hard-coded Connection** (R-004): Line 3

### Recommendations
1. Extract EmailValidator class
2. Extract EmailService class
3. Use parameterized queries
4. Inject IDbConnection
5. Split UserService into UserRepository, UserValidator, EmailService
```

### Input: Safe Refactoring Plan

```text
Refactor this 500-line OrderProcessor class.
Current test coverage: 45%
Goal: Reduce complexity, improve testability
Constraint: Cannot change public API
```

### Input: Legacy Modernization

```text
Modernize this VB.NET code to C# following Constitution standards:

Function CalculateTax(amount, state)
    If state = "CA" Then
        CalculateTax = amount * 0.0725
    ElseIf state = "TX" Then
        CalculateTax = amount * 0.0625
    Else
        CalculateTax = amount * 0.05
    End If
End Function
```

## Integration Points

- **Input from**: `continuous-evolver.md` (priorities), `legacy-archaeologist.md` (legacy code), static analysis tools
- **Output to**: `test-inspector.md` (test updates), `coding-agent.md` (implementation)
- **Artifacts**: Refactored code, PRs with before/after, updated tests
