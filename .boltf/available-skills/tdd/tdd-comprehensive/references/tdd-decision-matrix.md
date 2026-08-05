# TDD Decision Matrix - When and How to Apply TDD

## When to Use Different Testing Approaches

### TDD (Test-Driven Development)

**Best for:**

- ✅ **Domain logic** - Pure business logic, calculations, algorithms
- ✅ **Utilities** - Helper functions, formatters, validators
- ✅ **Services** - Application services with clear inputs/outputs
- ✅ **Bug fixes** - Write failing test that reproduces bug first
- ✅ **Complex algorithms** - Sorting, searching, graph traversal
- ✅ **Data transformations** - Parsers, serializers, mappers

**Why TDD works well:**

- Clear inputs and expected outputs
- Pure functions easy to test
- Fast feedback loop (milliseconds)
- No external dependencies

**Example:**

```typescript
// Perfect for TDD
test('calculates compound interest', () => {
  const result = calculateCompoundInterest(1000, 0.05, 10);
  expect(result).toBeCloseTo(1628.89, 2);
});

function calculateCompoundInterest(principal: number, rate: number, years: number): number {
  return principal * Math.pow(1 + rate, years);
}
```

### BDD (Behavior-Driven Development)

**Best for:**

- ✅ **User stories** - Features with acceptance criteria from stakeholders
- ✅ **Integration flows** - Multi-step processes involving multiple components
- ✅ **API contracts** - Endpoint behavior from consumer perspective
- ✅ **User journeys** - Complete workflows through the system

**Why BDD works well:**

- Describes behavior in business language
- Bridges gap between tech and business
- Natural language specifications (Gherkin)
- Focuses on outcomes not implementation

**Example (Gherkin):**

```gherkin
Feature: Shopping Cart Checkout

Scenario: Customer completes purchase with valid payment
  Given the customer has items in cart
    | product | quantity | price |
    | Widget  | 2        | 10.00 |
  When the customer proceeds to checkout
    And enters valid payment details
  Then the order should be confirmed
    And the customer should receive confirmation email
    And the cart should be empty
```

**When to use:**

- Product owner/stakeholder collaboration
- Acceptance testing
- E2E user flows

### Coverage-First (Legacy Code)

**Best for:**

- ✅ **Legacy code** - Existing code without tests
- ✅ **Refactoring** - Need safety net before changing code
- ✅ **Third-party code** - Wrapping external libraries
- ✅ **Characterization tests** - Document existing behavior

**Why coverage-first works:**

- Can't use TDD for existing code
- Need tests before refactoring
- Document current behavior (even if wrong)

**Example:**

```typescript
// Legacy function (no tests)
function processPayment(amount, card) {
  // Complex existing logic...
}

// Step 1: Add characterization tests
describe('processPayment (legacy)', () => {
  it('current behavior with valid card', () => {
    // Document WHAT IT DOES (not what it should do)
    const result = processPayment(100, validCard);
    expect(result).toMatchSnapshot();
  });

  it('current behavior with expired card', () => {
    const result = processPayment(100, expiredCard);
    expect(result).toMatchSnapshot();
  });
});

// Step 2: Now safe to refactor with test coverage
```

## Decision Tree

```text
┌─────────────────────────────────────────────────┐
│ Is this new code or existing code?              │
└────────────┬────────────────────────────────────┘
             │
     ┌───────┴───────┐
     │               │
   NEW            EXISTING
     │               │
     │               └──> Use Coverage-First
     │                    (Characterization tests)
     │
     ▼
┌─────────────────────────────────────┐
│ Is this user-facing feature with    │
│ acceptance criteria?                │
└────────────┬────────────────────────┘
             │
     ┌───────┴───────┐
     │               │
    YES             NO
     │               │
     └──> Use BDD    │
          (Gherkin)  │
                     ▼
         ┌────────────────────────────┐
         │ Use TDD                    │
         │ (Red-Green-Refactor)       │
         └────────────────────────────┘
```

## Scenario-Based Guide

### Scenario 1: New Feature Request

**Request:** "Add discount calculation for premium customers"

**Analysis:**

- ✅ New code
- ✅ Clear logic
- ✅ Pure calculation
- ❌ Not end-to-end flow

**Approach: TDD**

```typescript
// RED
test('applies 10% discount for premium customers', () => {
  const customer = { isPremium: true };
  const total = 100;

  const result = calculateDiscount(customer, total);

  expect(result).toBe(10);
});

// GREEN
function calculateDiscount(customer, total) {
  return customer.isPremium ? total * 0.1 : 0;
}

// REFACTOR (if needed)
```

### Scenario 2: User Story with Acceptance Criteria

**Request:**

```text
As a customer
I want to search for products
So that I can find items to purchase

Acceptance Criteria:
- Search results appear within 2 seconds
- Shows product image, name, and price
- Can filter by category
- Shows "No results" message when appropriate
```

**Analysis:**

- ✅ User-facing feature
- ✅ Acceptance criteria provided
- ✅ Multi-component flow
- ✅ Stakeholder language

**Approach: BDD**

```gherkin
Feature: Product Search

Scenario: Customer searches for products
  Given the customer is on the homepage
  When they enter "laptop" in the search box
    And click the search button
  Then they should see search results within 2 seconds
    And each result should display product image
    And each result should display product name
    And each result should display product price

Scenario: Customer finds no matching products
  Given the customer is on the homepage
  When they search for "nonexistent product"
  Then they should see "No results found" message
    And they should see suggestions for alternative searches
```

### Scenario 3: Legacy Code Refactoring

**Request:** "Refactor messy payment processing function"

**Analysis:**

- ❌ Existing code
- ❌ No tests
- ✅ Needs refactoring
- ⚠️ Unknown behavior

**Approach: Coverage-First → TDD**

**Step 1: Characterization tests (document existing behavior)**

```typescript
describe('processPayment (legacy)', () => {
  it('processes valid payment', () => {
    const result = processPayment(100, validCard, customer);
    expect(result).toMatchSnapshot(); // Capture current behavior
  });

  it('handles expired card', () => {
    const result = processPayment(100, expiredCard, customer);
    expect(result.error).toBe('Card expired'); // Document current
  });
});
```

**Step 2: Now refactor with TDD**

```typescript
// Now that we have coverage, refactor with confidence
test('validates card before processing', () => {
  const validator = new CardValidator();
  expect(validator.isValid(expiredCard)).toBe(false);
});

// Refactor safely
```

### Scenario 4: API Endpoint

**Request:** "Create POST /api/users endpoint"

**Analysis:**

- ✅ New code
- ✅ Clear contract
- ⚠️ May involve multiple layers

**Approach: BDD for contract + TDD for logic**

**BDD (Integration level):**

```gherkin
Feature: User Registration API

Scenario: Register new user with valid data
  When the client sends POST to "/api/users"
    """
    {
      "email": "user@example.com",
      "name": "John Doe",
      "password": "SecurePass123!"
    }
    """
  Then the response status should be 201
    And the response should contain user ID
    And the response should not contain password
    And the user should receive welcome email
```

**TDD (Unit level for validation):**

```typescript
// Domain logic with TDD
test('rejects weak passwords', () => {
  const validator = new PasswordValidator();
  expect(() => validator.validate('12345')).toThrow('Password too weak');
});

test('accepts strong passwords', () => {
  const validator = new PasswordValidator();
  expect(() => validator.validate('SecurePass123!')).not.toThrow();
});
```

### Scenario 5: Bug Fix

**Request:** "User can submit order with negative quantity"

**Analysis:**

- ❌ Existing code (with bug)
- ✅ Clear expected behavior
- ✅ Reproducible bug

**Approach: TDD (Bug Reproduction Test)**

```typescript
// RED: Write failing test that reproduces bug
test('rejects negative quantity', () => {
  const order = new Order();

  expect(() => order.addItem('product-1', -5)).toThrow('Quantity must be positive');
});

// Currently FAILS (bug exists)

// GREEN: Fix the bug
class Order {
  addItem(productId: string, quantity: number) {
    if (quantity <= 0) {
      throw new Error('Quantity must be positive');
    }
    // ... rest of logic
  }
}

// Now test PASSES (bug fixed)
```

## Hybrid Approaches

### TDD + BDD Together

**Use TDD for:**

- Domain logic
- Business rules
- Calculations

**Use BDD for:**

- User journeys
- Integration flows
- API contracts

**Example Project Structure:**

```text
src/
├── domain/           # TDD
│   ├── Order.ts
│   ├── Order.test.ts
│   ├── Discount.ts
│   └── Discount.test.ts
├── api/              # BDD (integration)
│   └── orders/
│       ├── route.ts
│       └── route.spec.ts (BDD-style)
└── e2e/              # BDD (Gherkin)
    ├── checkout.feature
    └── checkout.steps.ts
```

## Quick Reference Table

| Scenario            | Approach                             | Reason                              |
| ------------------- | ------------------------------------ | ----------------------------------- |
| New domain logic    | **TDD**                              | Pure logic, fast feedback           |
| User story with ACs | **BDD**                              | Stakeholder collaboration           |
| Legacy code         | **Coverage-First**                   | No tests exist, need safety net     |
| Bug fix             | **TDD**                              | Write failing test reproducing bug  |
| API endpoint        | **BDD** (contract) + **TDD** (logic) | Test contract and logic separately  |
| Complex algorithm   | **TDD**                              | Clear inputs/outputs                |
| E2E user journey    | **BDD**                              | Multi-step flow, business language  |
| Utility function    | **TDD**                              | Simple, fast, deterministic         |
| Integration flow    | **BDD**                              | Multiple components, behavior focus |
| Refactoring         | **Coverage-First** → **TDD**         | Need tests before refactor          |

## When NOT to Write Tests

Very rarely, but valid cases:

- ❌ **Spike/Throwaway code** - Will be deleted, not in production
- ❌ **Configuration files** - YAML, JSON (though validate schema)
- ❌ **Generated code** - Framework scaffolding
- ❌ **Trivial getters/setters** - No logic, just property access

**But remember:** If you're unsure, write the test. Better safe than sorry.

## Summary

**Default to TDD for:**

- New code
- Domain logic
- Bug fixes
- Anything with clear inputs/outputs

**Use BDD when:**

- User stories with acceptance criteria
- Need stakeholder collaboration
- Testing behavior not implementation

**Use Coverage-First for:**

- Legacy code
- Refactoring without tests
- Characterization testing

**When in doubt:** Start with TDD. It's never wrong to write tests first.
