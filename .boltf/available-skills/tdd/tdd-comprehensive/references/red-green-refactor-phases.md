# Red-Green-Refactor Phases - Detailed Workflows

## 🔴 RED Phase - Write Failing Test

### Goal

Define WHAT should happen (not HOW). The test specifies the desired behavior before implementation exists.

### Detailed Workflow

1. **Understand the requirement**
   - What behavior needs implementation?
   - What are the inputs and expected outputs?
   - What edge cases exist?

2. **Write the test**
   - Use AAA pattern (Arrange, Act, Assert)
   - Name test clearly: `should_[expected behavior]_when_[condition]`
   - Keep test focused on ONE behavior

3. **Run the test - MUST FAIL**
   - Execute test runner
   - Verify it FAILS (not errors)
   - Check failure reason is correct

4. **Verify failure reason**
   - ✅ **Good failure reasons:**
     - Method doesn't exist
     - Wrong return value
     - Expected behavior not implemented
   - ❌ **Bad failure reasons (fix your test!):**
     - Syntax error
     - Import error
     - Type error

5. **Commit the failing test**

   ```bash
   git add .
   git commit -m "test: add failing test for [feature]"
   ```

### RED Phase Examples

#### Backend Example (.NET/xUnit)

```csharp
// RED: Write failing test FIRST
[Fact]
public void CreateAccount_WithValidData_ReturnsAccountWithId()
{
    // Arrange
    var service = new AccountService();
    var request = new CreateAccountRequest
    {
        Name = "John Doe",
        Email = "john@example.com"
    };

    // Act
    var result = service.CreateAccount(request);

    // Assert
    result.Should().NotBeNull();
    result.Id.Should().NotBeEmpty();
    result.Name.Should().Be("John Doe");
    result.Email.Should().Be("john@example.com");
}

// Run: dotnet test
// Expected: FAIL - AccountService.CreateAccount does not exist
```

#### Frontend Example (TypeScript/Vitest)

```typescript
// RED: Write failing test FIRST
describe('UserValidator', () => {
  it('should reject email with invalid domain', () => {
    const validator = new UserValidator();
    const result = validator.validateEmail('user@invalid');

    expect(result.isValid).toBe(false);
    expect(result.error).toBe('Invalid email domain');
  });
});

// Run: npm test
// Expected: FAIL - UserValidator is not defined
```

### RED Phase Checklist

- [ ] Test follows AAA pattern (Arrange, Act, Assert)
- [ ] Test name clearly describes expected behavior
- [ ] Test runs and FAILS (not errors)
- [ ] Failure message is clear and expected
- [ ] Only ONE new test added
- [ ] Test is minimal (no unnecessary setup)
- [ ] Test committed to version control: `test: add failing test for X`

### Common RED Phase Mistakes

| Mistake                                      | Why It's Wrong                                | Fix                                  |
| -------------------------------------------- | --------------------------------------------- | ------------------------------------ |
| Test passes immediately                      | You tested existing code, not new requirement | Write test for unimplemented feature |
| Test errors instead of fails                 | Syntax/import issue, not testing behavior     | Fix test syntax first                |
| Didn't run test                              | Don't know if test actually works             | Always run and watch it fail         |
| Multiple assertions testing different things | Test loses focus, hard to debug               | Split into multiple tests            |
| Complex test setup                           | Test becomes fragile and hard to maintain     | Simplify or use test fixtures        |

## 🟢 GREEN Phase - Make Test Pass

### Goal

Write the SIMPLEST code to make the test pass. Resist the urge to over-engineer.

### Detailed Workflow

1. **Write minimal code**
   - Focus ONLY on making the failing test pass
   - Don't add features not covered by tests
   - Don't optimize prematurely
   - Hardcoding is OK if it passes the test!

2. **Run the new test**
   - Should turn GREEN (pass)
   - If still red, continue implementing

3. **Run ALL tests**
   - Ensure existing tests still pass
   - If any fail, fix before continuing

4. **Commit the implementation**

   ```bash
   git add .
   git commit -m "feat: implement [feature]"
   ```

### GREEN Phase Examples

#### Backend Example (.NET) - Minimal Implementation

```csharp
// GREEN: Simplest code to pass test
public class AccountService
{
    public Account CreateAccount(CreateAccountRequest request)
    {
        return new Account
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Email = request.Email
        };
    }
}

// Run: dotnet test
// Expected: PASS ✓ CreateAccount_WithValidData_ReturnsAccountWithId
```

**Note:** No validation, no database, no error handling yet. Just enough to pass THIS test.

#### Frontend Example (TypeScript) - Minimal Implementation

```typescript
// GREEN: Simplest code to pass test
class UserValidator {
  validateEmail(email: string): { isValid: boolean; error?: string } {
    if (!email.includes('@') || !email.split('@')[1].includes('.')) {
      return { isValid: false, error: 'Invalid email domain' };
    }
    return { isValid: true };
  }
}

// Run: npm test
// Expected: PASS ✓ should reject email with invalid domain
```

### Handling "But What About..." Scenarios

When implementing GREEN phase, you might think:

- ❓ "But what about validation?" → **Write a test for it first**
- ❓ "But what about error handling?" → **Write a test for it first**
- ❓ "But what about performance?" → **Write a test for it first (if needed)**
- ❓ "But what about edge cases?" → **Write tests for them first**

### GREEN Phase Checklist

- [ ] Minimal code written (no over-engineering)
- [ ] New test PASSES
- [ ] ALL existing tests still pass
- [ ] No functionality added beyond test requirements
- [ ] Code is readable (even if not perfect)
- [ ] Code committed: `feat: implement X`

### Common GREEN Phase Mistakes

| Mistake                             | Why It's Wrong                             | Fix                               |
| ----------------------------------- | ------------------------------------------ | --------------------------------- |
| Over-engineering                    | Added features not tested, YAGNI violation | Remove untested code              |
| Premature optimization              | Complexity before it works                 | Optimize in REFACTOR phase        |
| Adding error handling without tests | Can't verify it works                      | Write test for error case first   |
| Trying to make code "perfect"       | Perfectionism slows cycle                  | Make it work, improve in REFACTOR |
| Not running all tests               | Might have broken something                | Always verify all tests green     |

### The "Fake It Till You Make It" Pattern

Sometimes the simplest implementation is almost absurd:

```typescript
// Test
test('adds two numbers', () => {
  expect(add(2, 3)).toBe(5);
});

// Simplest possible GREEN implementation (yes, really!)
function add(a: number, b: number): number {
  return 5; // Hardcoded! But test passes...
}
```

When you write the NEXT test:

```typescript
test('adds different numbers', () => {
  expect(add(3, 4)).toBe(7);
});
```

NOW you need a real implementation:

```typescript
function add(a: number, b: number): number {
  return a + b; // Both tests pass
}
```

This feels silly but enforces YAGNI (You Aren't Gonna Need It) and prevents over-engineering.

## ♻️ REFACTOR Phase - Improve Code Quality

### Goal

Improve code while keeping ALL tests GREEN. Focus on code quality without changing behavior.

### When to Refactor

Refactor when you see:

- **Duplication** - Same code in multiple places (DRY violation)
- **Long methods** - Methods with >20 lines
- **Complex conditionals** - Nested if/else, multiple conditions
- **Magic numbers/strings** - Hardcoded values without constants
- **Poor naming** - Unclear variable/method names
- **God classes** - Classes doing too many things
- **SOLID violations** - Single Responsibility, Open/Closed, etc.

### Common Refactorings

#### 1. Extract Method

**Before:**

```typescript
function processOrder(order: Order): void {
  // Validate order
  if (!order.items || order.items.length === 0) {
    throw new Error('Order must have items');
  }
  if (order.total < 0) {
    throw new Error('Order total cannot be negative');
  }

  // Calculate discounts
  let discount = 0;
  if (order.isPremium) {
    discount = order.total * 0.1;
  }

  // Apply discount
  order.finalTotal = order.total - discount;
}
```

**After:**

```typescript
function processOrder(order: Order): void {
  validateOrder(order);
  const discount = calculateDiscount(order);
  applyDiscount(order, discount);
}

function validateOrder(order: Order): void {
  if (!order.items || order.items.length === 0) {
    throw new Error('Order must have items');
  }
  if (order.total < 0) {
    throw new Error('Order total cannot be negative');
  }
}

function calculateDiscount(order: Order): number {
  return order.isPremium ? order.total * 0.1 : 0;
}

function applyDiscount(order: Order, discount: number): void {
  order.finalTotal = order.total - discount;
}
```

#### 2. Extract Class

**Before:**

```csharp
public class Order
{
    public Guid Id { get; set; }
    public List<Item> Items { get; set; }
    public decimal Total { get; set; }

    // Customer data embedded
    public string CustomerName { get; set; }
    public string CustomerEmail { get; set; }
    public string CustomerAddress { get; set; }
    public string CustomerPhone { get; set; }
}
```

**After:**

```csharp
public class Order
{
    public Guid Id { get; set; }
    public List<Item> Items { get; set; }
    public decimal Total { get; set; }
    public Customer Customer { get; set; }
}

public class Customer
{
    public string Name { get; set; }
    public string Email { get; set; }
    public string Address { get; set; }
    public string Phone { get; set; }
}
```

#### 3. Remove Duplication (DRY)

**Before:**

```typescript
function calculateShippingForStandard(weight: number): number {
  const baseRate = 5.0;
  const perKgRate = 2.5;
  return baseRate + weight * perKgRate;
}

function calculateShippingForExpress(weight: number): number {
  const baseRate = 10.0;
  const perKgRate = 5.0;
  return baseRate + weight * perKgRate;
}
```

**After:**

```typescript
function calculateShipping(weight: number, shippingType: 'standard' | 'express'): number {
  const rates = {
    standard: { base: 5.0, perKg: 2.5 },
    express: { base: 10.0, perKg: 5.0 },
  };

  const rate = rates[shippingType];
  return rate.base + weight * rate.perKg;
}
```

#### 4. Simplify Conditionals

**Before:**

```csharp
public string GetDiscountLevel(Customer customer)
{
    if (customer.OrderCount > 100)
    {
        if (customer.TotalSpent > 10000)
        {
            return "Platinum";
        }
        else
        {
            return "Gold";
        }
    }
    else if (customer.OrderCount > 50)
    {
        return "Silver";
    }
    else if (customer.OrderCount > 10)
    {
        return "Bronze";
    }
    else
    {
        return "Standard";
    }
}
```

**After (Guard Clauses):**

```csharp
public string GetDiscountLevel(Customer customer)
{
    if (customer.OrderCount > 100 && customer.TotalSpent > 10000)
        return "Platinum";

    if (customer.OrderCount > 100)
        return "Gold";

    if (customer.OrderCount > 50)
        return "Silver";

    if (customer.OrderCount > 10)
        return "Bronze";

    return "Standard";
}
```

### REFACTOR Phase Workflow

1. **Keep tests green**: Run all tests before refactoring
2. **Make ONE change**: Extract method, rename variable, etc.
3. **Run all tests**: Must stay GREEN
4. **Commit**: `refactor: extract validation logic`
5. **Repeat**: Continue until satisfied

### REFACTOR Phase Checklist

- [ ] Code follows SOLID principles
- [ ] No code duplication (DRY)
- [ ] Clear, descriptive names
- [ ] Appropriate design patterns applied
- [ ] ALL tests still GREEN after each change
- [ ] Code complexity reduced
- [ ] Each refactor committed separately

### Common REFACTOR Mistakes

| Mistake                   | Why It's Wrong                | Fix                         |
| ------------------------- | ----------------------------- | --------------------------- |
| Adding behavior           | Changes what code does        | Only change HOW, not WHAT   |
| Big bang refactor         | Risk breaking everything      | Small incremental changes   |
| Not running tests         | Don't know if broke something | Run tests after each change |
| Refactoring without tests | No safety net                 | Write tests first           |
| Over-refactoring          | Premature abstraction         | Stop when code is clear     |

## Cycle Metrics

### Typical Cycle Times

| Phase     | Time Range        | Notes                  |
| --------- | ----------------- | ---------------------- |
| RED       | 2-5 minutes       | Writing test           |
| GREEN     | 2-10 minutes      | Minimal implementation |
| REFACTOR  | 5-15 minutes      | Improving code quality |
| **Total** | **10-30 minutes** | Complete cycle         |

### When Cycles Are Too Long

If cycles exceed 30 minutes:

- ❌ Test is too complex → Split into smaller tests
- ❌ Implementation is too ambitious → Break into smaller steps
- ❌ Refactoring is too broad → Focus on one smell at a time

### When TDD Is Working Well

- ✅ Cycle time is short (< 30 min)
- ✅ Tests are green most of the time (>90%)
- ✅ Refactoring is fearless
- ✅ Code coverage is high naturally (>80%)
- ✅ Bugs are caught early in RED phase

### When TDD Is Not Working

- ❌ Cycle time > 1 hour
- ❌ Tests frequently break
- ❌ Afraid to refactor
- ❌ Coverage gaps after TDD
- ❌ Tests feel like burden

**If experiencing these → Review workflow, simplify tests, ask for help**
