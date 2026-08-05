# Testing Patterns - Comprehensive Examples

## Unit Testing Patterns

### Good Unit Test Pattern (TypeScript/Vitest)

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { ShoppingCart } from './ShoppingCart';
import { Product } from './Product';

describe('ShoppingCart', () => {
  let cart: ShoppingCart;

  beforeEach(() => {
    cart = new ShoppingCart();
  });

  describe('addProduct', () => {
    it('should add product to cart', () => {
      // Arrange
      const product = new Product('Widget', 10.0);

      // Act
      cart.addProduct(product);

      // Assert
      expect(cart.getItemCount()).toBe(1);
      expect(cart.getTotal()).toBe(10.0);
    });

    it('should increase quantity when adding same product twice', () => {
      const product = new Product('Widget', 10.0);

      cart.addProduct(product);
      cart.addProduct(product);

      expect(cart.getItemCount()).toBe(1);
      expect(cart.getQuantity(product.id)).toBe(2);
      expect(cart.getTotal()).toBe(20.0);
    });

    it('should throw error when adding product with negative price', () => {
      const invalidProduct = new Product('Invalid', -5.0);

      expect(() => cart.addProduct(invalidProduct)).toThrow('Price cannot be negative');
    });
  });

  describe('removeProduct', () => {
    it('should remove product from cart', () => {
      const product = new Product('Widget', 10.0);
      cart.addProduct(product);

      cart.removeProduct(product.id);

      expect(cart.getItemCount()).toBe(0);
      expect(cart.getTotal()).toBe(0);
    });

    it('should do nothing when removing non-existent product', () => {
      cart.removeProduct('non-existent-id');

      expect(cart.getItemCount()).toBe(0);
    });
  });
});
```

### Bad Unit Test Pattern - Avoid These

```typescript
// ❌ BAD: Tests multiple things
it('should add product, update total, save to db, and send notification', async () => {
  // Too many responsibilities!
});

// ❌ BAD: Tests implementation details
it('should call private _calculateTax method', () => {
  const spy = jest.spyOn(cart, '_calculateTax' as any);
  cart.checkout();
  expect(spy).toHaveBeenCalled(); // Coupled to implementation!
});

// ❌ BAD: Fragile assertion
it('should format cart contents', () => {
  cart.addProduct(product);
  expect(cart.toString()).toBe('Cart: 1 item(s), Total: $10.00'); // Breaks if format changes!
});

// ✅ GOOD: Test behavior, not formatting
it('should include product count in cart summary', () => {
  cart.addProduct(product);
  const summary = cart.getSummary();
  expect(summary.itemCount).toBe(1);
  expect(summary.total).toBe(10.0);
});
```

### Unit Test Pattern (.NET/xUnit)

```csharp
using Xunit;
using FluentAssertions;

public class ShoppingCartTests
{
    private readonly ShoppingCart _cart;

    public ShoppingCartTests()
    {
        _cart = new ShoppingCart();
    }

    [Fact]
    public void AddProduct_WithValidProduct_AddsToCart()
    {
        // Arrange
        var product = new Product("Widget", 10.00m);

        // Act
        _cart.AddProduct(product);

        // Assert
        _cart.ItemCount.Should().Be(1);
        _cart.Total.Should().Be(10.00m);
    }

    [Fact]
    public void AddProduct_SameProductTwice_IncreasesQuantity()
    {
        // Arrange
        var product = new Product("Widget", 10.00m);

        // Act
        _cart.AddProduct(product);
        _cart.AddProduct(product);

        // Assert
        _cart.ItemCount.Should().Be(1);
        _cart.GetQuantity(product.Id).Should().Be(2);
        _cart.Total.Should().Be(20.00m);
    }

    [Fact]
    public void AddProduct_WithNegativePrice_ThrowsArgumentException()
    {
        // Arrange
        var invalidProduct = new Product("Invalid", -5.00m);

        // Act & Assert
        var action = () => _cart.AddProduct(invalidProduct);
        action.Should().Throw<ArgumentException>()
            .WithMessage("*price cannot be negative*");
    }

    [Theory]
    [InlineData(0, 0)]
    [InlineData(1, 10.00)]
    [InlineData(3, 30.00)]
    public void CalculateTotal_WithVariousQuantities_ReturnsCorrectTotal(
        int quantity,
        decimal expectedTotal)
    {
        // Arrange
        var product = new Product("Widget", 10.00m);

        // Act
        for (int i = 0; i < quantity; i++)
        {
            _cart.AddProduct(product);
        }

        // Assert
        _cart.Total.Should().Be(expectedTotal);
    }
}
```

## Integration Testing Patterns

### API Integration Test (TypeScript/Node.js)

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { NextRequest } from 'next/server';
import { GET, POST } from '@/app/api/products/route';

describe('Products API', () => {
  beforeAll(async () => {
    // Setup: Clear test database
    await clearTestDatabase();
  });

  afterAll(async () => {
    // Cleanup: Remove test data
    await clearTestDatabase();
  });

  describe('GET /api/products', () => {
    it('should return empty array when no products exist', async () => {
      const request = new NextRequest('http://localhost/api/products');
      const response = await GET(request);
      const data = await response.json();

      expect(response.status).toBe(200);
      expect(data.products).toEqual([]);
    });

    it('should return products successfully', async () => {
      // Arrange: Create test products
      await createTestProduct({ name: 'Product 1', price: 10.0 });
      await createTestProduct({ name: 'Product 2', price: 20.0 });

      // Act
      const request = new NextRequest('http://localhost/api/products');
      const response = await GET(request);
      const data = await response.json();

      // Assert
      expect(response.status).toBe(200);
      expect(data.products).toHaveLength(2);
      expect(data.products[0]).toMatchObject({
        name: 'Product 1',
        price: 10.0,
      });
    });
  });

  describe('POST /api/products', () => {
    it('should create product successfully', async () => {
      // Arrange
      const productData = {
        name: 'New Product',
        price: 15.0,
        category: 'Electronics',
      };

      // Act
      const request = new NextRequest('http://localhost/api/products', {
        method: 'POST',
        body: JSON.stringify(productData),
      });
      const response = await POST(request);
      const data = await response.json();

      // Assert
      expect(response.status).toBe(201);
      expect(data.product).toMatchObject(productData);
      expect(data.product.id).toBeDefined();
    });

    it('should return 400 when price is negative', async () => {
      const invalidData = {
        name: 'Invalid Product',
        price: -10.0,
      };

      const request = new NextRequest('http://localhost/api/products', {
        method: 'POST',
        body: JSON.stringify(invalidData),
      });
      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error).toContain('Price must be positive');
    });
  });
});
```

### Database Integration Test (.NET/xUnit with Testcontainers)

```csharp
using Testcontainers.PostgreSql;
using Xunit;
using FluentAssertions;

public class ProductRepositoryTests : IAsyncLifetime
{
    private PostgreSqlContainer _container;
    private IProductRepository _repository;
    private ApplicationDbContext _context;

    public async Task InitializeAsync()
    {
        // Start PostgreSQL container
        _container = new PostgreSqlBuilder()
            .WithImage("postgres:15")
            .Build();

        await _container.StartAsync();

        // Setup DbContext
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseNpgsql(_container.GetConnectionString())
            .Options;

        _context = new ApplicationDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new ProductRepository(_context);
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _container.DisposeAsync();
    }

    [Fact]
    public async Task GetById_ExistingProduct_ReturnsProduct()
    {
        // Arrange
        var product = new Product
        {
            Name = "Test Widget",
            Price = 10.00m
        };
        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        // Act
        var result = await _repository.GetByIdAsync(product.Id);

        // Assert
        result.Should().NotBeNull();
        result.Name.Should().Be("Test Widget");
        result.Price.Should().Be(10.00m);
    }

    [Fact]
    public async Task Create_ValidProduct_SavesToDatabase()
    {
        // Arrange
        var product = new Product
        {
            Name = "New Product",
            Price = 25.00m,
            Category = "Electronics"
        };

        // Act
        var created = await _repository.CreateAsync(product);

        // Assert
        created.Id.Should().NotBeEmpty();

        // Verify in database
        var fromDb = await _context.Products.FindAsync(created.Id);
        fromDb.Should().NotBeNull();
        fromDb.Name.Should().Be("New Product");
    }

    [Fact]
    public async Task GetByCategory_MultipleProducts_ReturnsFiltered()
    {
        // Arrange
        await _context.Products.AddRangeAsync(
            new Product { Name = "Phone", Price = 500, Category = "Electronics" },
            new Product { Name = "Shirt", Price = 30, Category = "Clothing" },
            new Product { Name = "Laptop", Price = 1000, Category = "Electronics" }
        );
        await _context.SaveChangesAsync();

        // Act
        var electronics = await _repository.GetByCategoryAsync("Electronics");

        // Assert
        electronics.Should().HaveCount(2);
        electronics.Should().OnlyContain(p => p.Category == "Electronics");
    }
}
```

## E2E Testing Patterns (Playwright)

### Complete E2E User Journey

```typescript
import { test, expect } from '@playwright/test';

test.describe('E-Commerce Checkout Flow', () => {
  test('complete purchase flow', async ({ page }) => {
    // 1. Navigate to homepage
    await page.goto('/');
    await expect(page.locator('h1')).toContainText('Welcome');

    // 2. Search for product
    await page.fill('[data-testid="search-input"]', 'laptop');
    await page.click('[data-testid="search-button"]');
    await page.waitForURL('**/search?q=laptop');

    // 3. Verify search results
    const products = page.locator('[data-testid="product-card"]');
    await expect(products).toHaveCount(5, { timeout: 5000 });

    // 4. Click first product
    await products.first().click();
    await page.waitForURL('**/products/*');

    // 5. Add to cart
    await page.click('[data-testid="add-to-cart"]');
    await expect(page.locator('[data-testid="cart-badge"]')).toHaveText('1');

    // 6. Go to cart
    await page.click('[data-testid="cart-icon"]');
    await page.waitForURL('**/cart');

    // 7. Verify cart contents
    await expect(page.locator('[data-testid="cart-item"]')).toHaveCount(1);
    const total = page.locator('[data-testid="cart-total"]');
    await expect(total).toBeVisible();

    // 8. Proceed to checkout
    await page.click('[data-testid="checkout-button"]');
    await page.waitForURL('**/checkout');

    // 9. Fill shipping information
    await page.fill('[data-testid="name"]', 'John Doe');
    await page.fill('[data-testid="email"]', 'john@example.com');
    await page.fill('[data-testid="address"]', '123 Main St');
    await page.fill('[data-testid="city"]', 'New York');
    await page.selectOption('[data-testid="country"]', 'US');

    // 10. Fill payment information
    await page.fill('[data-testid="card-number"]', '4111111111111111');
    await page.fill('[data-testid="card-expiry"]', '12/25');
    await page.fill('[data-testid="card-cvc"]', '123');

    // 11. Submit order
    await page.click('[data-testid="submit-order"]');

    // 12. Verify success
    await page.waitForURL('**/order/confirmation');
    await expect(page.locator('[data-testid="success-message"]')).toContainText(
      'Order placed successfully'
    );

    const orderId = page.locator('[data-testid="order-id"]');
    await expect(orderId).toBeVisible();
  });

  test('handles out of stock products', async ({ page }) => {
    await page.goto('/products/out-of-stock-item');

    const addToCartButton = page.locator('[data-testid="add-to-cart"]');
    await expect(addToCartButton).toBeDisabled();
    await expect(page.locator('[data-testid="stock-status"]')).toContainText('Out of Stock');
  });
});
```

### Authentication Flow E2E

```typescript
test.describe('Authentication', () => {
  test('login with valid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[data-testid="email"]', 'user@example.com');
    await page.fill('[data-testid="password"]', 'password123');
    await page.click('[data-testid="login-button"]');

    await page.waitForURL('**/dashboard');
    await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('[data-testid="email"]', 'wrong@example.com');
    await page.fill('[data-testid="password"]', 'wrongpassword');
    await page.click('[data-testid="login-button"]');

    await expect(page.locator('[data-testid="error-message"]')).toContainText(
      'Invalid email or password'
    );
    await expect(page).toHaveURL(/.*login/);
  });
});
```

## Test Organization Best Practices

### File Structure

```text
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx        # Unit tests
│   │   └── Button.module.css
│   └── ShoppingCart/
│       ├── ShoppingCart.tsx
│       └── ShoppingCart.test.tsx
├── services/
│   ├── ProductService.ts
│   └── ProductService.test.ts      # Unit tests
├── app/
│   └── api/
│       └── products/
│           ├── route.ts
│           └── route.test.ts       # Integration tests
└── e2e/
    ├── checkout.spec.ts            # E2E tests
    ├── auth.spec.ts
    └── navigation.spec.ts
```

### Test Naming Conventions

**Pattern:** `[Method]_[Scenario]_[ExpectedResult]`

```csharp
// ✅ GOOD
CalculateDiscount_WithPremiumCustomer_Returns10PercentDiscount()
ValidateEmail_WithInvalidFormat_ThrowsValidationException()
CreateUser_WithExistingEmail_ReturnsDuplicateError()

// ❌ BAD
Test1()
TestDiscount()
TestValidation()
```

## AAA Pattern (Arrange-Act-Assert)

Every test should follow this structure:

```typescript
test('descriptive name', () => {
  // ARRANGE - Setup test data and dependencies
  const cart = new ShoppingCart();
  const product = new Product('Widget', 10.0);

  // ACT - Execute the behavior being tested
  cart.addProduct(product);

  // ASSERT - Verify the expected outcome
  expect(cart.getTotal()).toBe(10.0);
});
```

## Test Data Builders

For complex test data, use builder pattern:

```typescript
class ProductBuilder {
  private name = 'Default Product';
  private price = 10.0;
  private category = 'General';

  withName(name: string): ProductBuilder {
    this.name = name;
    return this;
  }

  withPrice(price: number): ProductBuilder {
    this.price = price;
    return this;
  }

  withCategory(category: string): ProductBuilder {
    this.category = category;
    return this;
  }

  build(): Product {
    return new Product(this.name, this.price, this.category);
  }
}

// Usage
const product = new ProductBuilder()
  .withName('Premium Widget')
  .withPrice(99.99)
  .withCategory('Electronics')
  .build();
```
