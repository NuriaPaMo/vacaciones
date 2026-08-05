# Domain Modeling Prompt

## Agent Reference

> **Primary Agents**:
>
> - [DDD Master](../copilot/agents/bolt-ddd-master.md) - Domain modeling and tactical patterns
> - [Domain Sage](../copilot/agents/bolt-domain-sage.md) - Business rules and ubiquitous language
>
> **Phase**: Block 3 - Design
> **Constitution**: Read `.boltf/memory/constitution.digest.md` for domain patterns and conventions

## Context

Use this prompt when creating domain models using Domain-Driven Design (DDD) patterns. This prompt guides Copilot to act as the **DDD Master Agent** from the Bolt Framework methodology.

## Instructions

When creating domain models:

### 1. Strategic Design

- Identify bounded contexts and their boundaries
- Map context relationships (upstream/downstream)
- Define the ubiquitous language for each context
- Document context maps and integration patterns

### 2. Tactical Patterns

Apply appropriate DDD building blocks:

- **Entities**: Objects with identity that persists over time
- **Value Objects**: Immutable objects defined by their attributes
- **Aggregates**: Clusters of entities with a root entity
- **Domain Services**: Operations that don't belong to entities
- **Domain Events**: Record of something that happened
- **Repositories**: Abstractions for aggregate persistence
- **Factories**: Complex object creation logic

### 3. Model Validation

- Ensure model reflects business reality
- Validate ubiquitous language with domain experts
- Check aggregate boundaries for consistency
- Verify invariants are protected

### 4. Output Format

```markdown
## Bounded Context: [Context Name]

### Ubiquitous Language
| Term | Definition |
|------|------------|
| [Term] | [Domain-specific definition] |

### Aggregates

#### [Aggregate Name]
- **Root Entity**: [EntityName]
- **Invariants**:
  - [Business rule that must always be true]
- **Entities**: [List of contained entities]
- **Value Objects**: [List of value objects]

### Domain Events
- `[EventName]`: Triggered when [condition]

### Context Map
- Upstream: [Context] via [Pattern]
- Downstream: [Context] via [Pattern]
```

## Examples

### Input

```text
E-commerce order management: customers place orders with multiple items,
apply discount codes, and track delivery status.
```

### Output

```markdown
## Bounded Context: Order Management

### Ubiquitous Language
| Term | Definition |
|------|------------|
| Order | A customer's request to purchase items |
| LineItem | A single product with quantity in an order |
| Discount | A price reduction applied to an order |
| Fulfillment | The process of preparing and shipping an order |

### Aggregates

#### Order Aggregate
- **Root Entity**: Order
  ```typescript
  class Order {
    id: OrderId;
    customerId: CustomerId;
    lineItems: LineItem[];
    discount?: Discount;
    status: OrderStatus;

    // Invariants enforced through methods
    addItem(product: ProductSnapshot, quantity: Quantity): void;
    applyDiscount(code: DiscountCode): Result<void, DiscountError>;
    submit(): Result<void, OrderError>;
  }
  ```

- **Invariants**:
  - Order must have at least one line item to be submitted
  - Discount can only be applied once per order
  - Total cannot be negative
- **Entities**: LineItem
- **Value Objects**:
  - OrderId, CustomerId, ProductSnapshot
  - Money, Quantity, DiscountCode
  - OrderStatus (enum)

#### Fulfillment Aggregate

- **Root Entity**: Fulfillment
- **Invariants**:
  - Fulfillment can only be created for submitted orders
  - Status transitions must follow defined workflow
- **Value Objects**: FulfillmentId, ShippingAddress, TrackingNumber

### Domain Events

- `OrderPlaced`: Triggered when order is successfully submitted
- `OrderItemAdded`: Triggered when item added to draft order
- `DiscountApplied`: Triggered when valid discount is applied
- `OrderShipped`: Triggered when fulfillment marks as shipped
- `OrderDelivered`: Triggered when delivery is confirmed

### Domain Services

- `DiscountValidationService`: Validates discount codes against rules
- `InventoryReservationService`: Reserves inventory for order items

### Context Map

- Upstream: Catalog Context via Anticorruption Layer (product snapshots)
- Upstream: Customer Context via Shared Kernel (customer identity)
- Downstream: Fulfillment Context via Domain Events
- Downstream: Notification Context via Domain Events

```text

## Constraints

- Always use ubiquitous language in code and documentation
- Keep aggregates small - optimize for consistency boundaries
- Entities should encapsulate behavior, not just data
- Value objects must be immutable
- Don't leak domain logic to application or infrastructure layers
- Domain events should be past tense (something happened)
- Repositories only for aggregate roots

## DDD Anti-Patterns to Avoid

1. **Anemic Domain Model**: Entities with only getters/setters, no behavior
2. **God Aggregate**: Aggregate that's too large, hard to maintain
3. **Phantom Boundaries**: Artificial context boundaries that don't match reality
4. **Leaky Abstractions**: Domain concepts polluted with infrastructure concerns

## Related Agents

- **DDD Master Agent**: Primary agent for this prompt
- **Domain Sage Agent**: For domain knowledge validation
- **Omega Architect Agent**: For system-level integration

## Bolt Framework Stage

**ANALYZE** → This prompt implements the second cognitive stage, decomposing business concepts into structured domain models.
