# TDD Anti-Patterns

Common mistakes when practicing TDD and how to avoid them.

## ❌ Anti-Pattern 1: Writing Tests After Implementation

### The Problem

```typescript
// WRONG: Implementation written first
class UserService {
  createUser(email: string, name: string) {
    // 50 lines of complex logic
    if (!email.includes('@')) throw new Error('Invalid email');
    if (name.length < 2) throw new Error('Name too short');
    // More validation and business logic...
  }
}

// Test written after to "cover" existing code
test('should create user', () => {
  const service = new UserService();
  const result = service.createUser('user@example.com', 'John');
  expect(result).toBeTruthy(); // What does this test prove?
});
```

### Why It's Bad

- Test is written to match implementation (not requirements)
- No confidence test is correct
- Often tests implementation details
- Hard to refactor later

### The Fix: Test-First Development

```typescript
// RIGHT: Test written FIRST (RED phase)
test('should reject invalid email', () => {
  const service = new UserService();
  expect(() => service.createUser('invalid', 'John'))
    .toThrow('Invalid email');
});

// Now implement just enough to pass (GREEN phase)
class UserService {
  createUser(email: string, name: string) {
    if (!email.includes('@')) throw new Error('Invalid email');
    // Implementation driven by test
  }
}
```

## ❌ Anti-Pattern 2: Skipping RED Phase

### The Problem

```typescript
// WRONG: Test passes immediately on first run
test('should add numbers', () => {
  function add(a: number, b: number) { return a + b; }
  expect(add(2, 3)).toBe(5);
});

// How do you know this test would catch a bug?
```

### Why It's Bad

- No verification that test works
- Test might be testing nothing
- False sense of security

### The Fix: See It Fail First

```typescript
// RIGHT: Test fails first
test('should add numbers', () => {
  expect(add(2, 3)).toBe(5); // ❌ ReferenceError: add is not defined
});

// Now implement
function add(a: number, b: number) { 
  return a + b; 
}

// Test passes ✅
```

## ❌ Anti-Pattern 3: Testing Implementation Details

### The Problem

```typescript
// WRONG: Testing private methods or internal state
class ShoppingCart {
  private items: Item[] = [];
  
  private calculateSubtotal() { }
  private applyDiscount() { }
  
  public getTotal() { 
    const subtotal = this.calculateSubtotal();
    return this.applyDiscount(subtotal);
  }
}

// BAD TEST: Tests internal implementation
test('should call calculateSubtotal', () => {
  const spy = jest.spyOn(cart as any, 'calculateSubtotal');
  cart.getTotal();
  expect(spy).toHaveBeenCalled(); // Brittle! Breaks if refactored
});
```

### Why It's Bad

- Test breaks when refactoring (even if behavior unchanged)
- Couples test to implementation
- Makes refactoring painful

### The Fix: Test Behavior, Not Implementation

```typescript
// RIGHT: Test public behavior
test('should calculate total with discount', () => {
  const cart = new ShoppingCart();
  cart.addItem({ price: 100, quantity: 2 }); // $200
  cart.applyDiscountCode('SAVE10'); // 10% off
  
  expect(cart.getTotal()).toBe(180); // Test outcome, not how
});
```

## ❌ Anti-Pattern 4: Large Test / Large Implementation

### The Problem

```typescript
// WRONG: Testing everything at once
test('should handle complete user registration flow', () => {
  // 50 lines of test setup
  const user = createUser();
  validateEmail(user);
  validatePassword(user);
  checkUsernameAvailability(user);
  saveToDatabase(user);
  sendWelcomeEmail(user);
  logActivity(user);
  updateAnalytics(user);
  
  // 20 different assertions
  expect(user.id).toBeDefined();
  expect(user.email).toBe('...');
  // ... 18 more assertions
});
```

### Why It's Bad

- Hard to identify what failed
- Long test cycles
- Breaks frequently
- Difficult to maintain

### The Fix: Small, Focused Tests

```typescript
// RIGHT: One concern per test
test('should validate email format', () => {
  expect(() => validateEmail('invalid'))
    .toThrow('Invalid email format');
});

test('should validate password strength', () => {
  expect(() => validatePassword('weak'))
    .toThrow('Password too weak');
});

test('should save user to database', () => {
  const user = new User('email@test.com', 'StrongPass123!');
  const saved = repository.save(user);
  expect(saved.id).toBeDefined();
});
```

## ❌ Anti-Pattern 5: Not Running Tests Frequently

### The Problem

```typescript
// Write 10 tests
test('test 1', () => { });
test('test 2', () => { });
// ... 8 more tests

// Write implementation for all at once
class BigFeature { 
  // 200 lines of code
}

// Run tests → 7 fail
// Which code broke which test? 🤷
```

### Why It's Bad

- Debugging is hard
- Long feedback cycles
- Lost flow state
- Temptation to skip tests

### The Fix: Short RED-GREEN-REFACTOR Cycles

```typescript
// 1. One test
test('should validate email', () => {
  expect(() => validate('bad')).toThrow();
});

// 2. Implement
function validate(email: string) {
  if (!email.includes('@')) throw new Error('Invalid');
}

// 3. Test passes ✅

// 4. Next test...
```

## ❌ Anti-Pattern 6: Testing Trivial Code

### The Problem

```typescript
// WRONG: Testing getters/setters
test('should set name', () => {
  user.setName('John');
  expect(user.getName()).toBe('John'); // So what?
});

// WRONG: Testing framework code
test('should filter array', () => {
  const result = [1, 2, 3].filter(x => x > 1);
  expect(result).toEqual([2, 3]); // Testing JavaScript, not your code
});
```

### Why It's Bad

- Wastes time
- False sense of coverage
- Maintenance burden
- Distracts from real tests

### The Fix: Test Business Logic Only

```typescript
// RIGHT: Test your logic
test('should calculate overtime pay', () => {
  const employee = new Employee({ hourlyRate: 20 });
  const pay = employee.calculatePay(45); // 45 hours worked
  
  expect(pay).toBe(950); // 40 * 20 + 5 * 30 (1.5x for overtime)
});
```

## ❌ Anti-Pattern 7: Fragile Tests (Over-Mocking)

### The Problem

```typescript
// WRONG: Mocking everything
test('should create order', () => {
  const mockRepo = { save: jest.fn() };
  const mockEmail = { send: jest.fn() };
  const mockLogger = { log: jest.fn() };
  const mockValidator = { validate: jest.fn(() => true) };
  const mockCalculator = { calculate: jest.fn(() => 100) };
  
  const service = new OrderService(
    mockRepo, mockEmail, mockLogger, mockValidator, mockCalculator
  );
  
  service.createOrder({ });
  
  expect(mockRepo.save).toHaveBeenCalledWith(
    expect.objectContaining({ /* specific structure */ })
  );
});
```

### Why It's Bad

- Tests implementation, not behavior
- Breaks when refactoring
- Lots of setup code
- Not testing real integration

### The Fix: Mock Only External Dependencies

```typescript
// RIGHT: Mock only what you don't control
test('should create order', () => {
  const mockEmailService = { send: jest.fn() }; // External service
  const service = new OrderService(mockEmailService);
  
  const order = service.createOrder({
    items: [{ id: 1, quantity: 2 }],
    customer: validCustomer
  });
  
  expect(order.total).toBe(200);
  expect(order.status).toBe('pending');
  expect(mockEmailService.send).toHaveBeenCalled();
});
```

## Summary: TDD Best Practices

### ✅ DO

- Write test FIRST (RED)
- See it FAIL for right reason
- Write MINIMAL code (GREEN)
- REFACTOR with confidence
- Test behavior, not implementation
- Keep tests small and focused
- Run tests frequently

### ❌ DON'T

- Write tests after code
- Skip RED phase
- Test private methods
- Mock everything
- Write huge tests
- Test trivial code
- Ignore failing tests
