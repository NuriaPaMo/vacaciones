# Mocking Guide - Complete Strategies

## Mocking Principles

**When to Mock:**

- ✅ External APIs (third-party services)
- ✅ Payment gateways, email services
- ✅ AI models (OpenAI, embeddings)
- ✅ Time-sensitive operations (dates, timers)
- ✅ File system operations
- ✅ Network calls

**When NOT to Mock:**

- ❌ Internal business logic (test the real thing)
- ❌ Databases (use Testcontainers or in-memory DB)
- ❌ Simple utilities (not worth mocking)
- ❌ Value objects (they're data, not dependencies)

## TypeScript/JavaScript Mocking

### Vitest Mocking

#### Mock External Module

```typescript
import { vi, describe, it, expect } from 'vitest';
import { generateEmbedding } from '@/lib/openai';
import { processDocument } from './documentService';

// Mock the entire module
vi.mock('@/lib/openai', () => ({
  generateEmbedding: vi.fn(),
}));

describe('DocumentService', () => {
  it('should generate embedding for document', async () => {
    // Arrange
    const mockEmbedding = new Array(1536).fill(0.1);
    vi.mocked(generateEmbedding).mockResolvedValue(mockEmbedding);

    // Act
    const result = await processDocument('test content');

    // Assert
    expect(generateEmbedding).toHaveBeenCalledWith('test content');
    expect(result.embedding).toEqual(mockEmbedding);
  });
});
```

#### Mock with Different Return Values

```typescript
it('should retry on failure then succeed', async () => {
  const apiCall = vi
    .fn()
    .mockRejectedValueOnce(new Error('Network error'))
    .mockRejectedValueOnce(new Error('Timeout'))
    .mockResolvedValueOnce({ success: true });

  const result = await retryOperation(apiCall, { maxRetries: 3 });

  expect(apiCall).toHaveBeenCalledTimes(3);
  expect(result).toEqual({ success: true });
});
```

### Jest Mocking

#### Mock Axios HTTP Client

```typescript
import axios from 'axios';
import { fetchUserData } from './api';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('API Client', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should fetch user data successfully', async () => {
    // Arrange
    const mockData = { id: 1, name: 'John Doe' };
    mockedAxios.get.mockResolvedValue({ data: mockData });

    // Act
    const result = await fetchUserData(1);

    // Assert
    expect(mockedAxios.get).toHaveBeenCalledWith('/api/users/1');
    expect(result).toEqual(mockData);
  });

  it('should handle network errors', async () => {
    mockedAxios.get.mockRejectedValue(new Error('Network error'));

    await expect(fetchUserData(1)).rejects.toThrow('Network error');
  });
});
```

#### Mock OpenAI

```typescript
import { OpenAI } from 'openai';

jest.mock('openai');

describe('AI Service', () => {
  let mockCreate: jest.Mock;

  beforeEach(() => {
    mockCreate = jest.fn();
    (OpenAI as jest.MockedClass<typeof OpenAI>).mockImplementation(
      () =>
        ({
          chat: {
            completions: {
              create: mockCreate,
            },
          },
        }) as any
    );
  });

  it('should generate chat completion', async () => {
    mockCreate.mockResolvedValue({
      choices: [
        {
          message: { content: 'AI response' },
        },
      ],
    });

    const result = await generateResponse('Hello');

    expect(mockCreate).toHaveBeenCalledWith({
      model: 'gpt-4',
      messages: [{ role: 'user', content: 'Hello' }],
    });
    expect(result).toBe('AI response');
  });
});
```

### Mock Supabase

```typescript
import { createClient } from '@supabase/supabase-js';

vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(),
}));

describe('Supabase Service', () => {
  let mockSupabase: any;

  beforeEach(() => {
    mockSupabase = {
      from: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      insert: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      single: vi.fn(),
    };

    vi.mocked(createClient).mockReturnValue(mockSupabase);
  });

  it('should fetch user by id', async () => {
    const mockUser = { id: '123', name: 'John' };
    mockSupabase.single.mockResolvedValue({ data: mockUser, error: null });

    const result = await getUserById('123');

    expect(mockSupabase.from).toHaveBeenCalledWith('users');
    expect(mockSupabase.eq).toHaveBeenCalledWith('id', '123');
    expect(result).toEqual(mockUser);
  });
});
```

### Mock Time/Dates

```typescript
import { vi, beforeEach, afterEach } from 'vitest';

describe('Time-sensitive operations', () => {
  beforeEach(() => {
    // Mock Date to fixed time
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2024-01-15T10:30:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should check if subscription is expired', () => {
    const subscription = {
      expiresAt: new Date('2024-01-10T00:00:00Z'),
    };

    const isExpired = checkExpiration(subscription);

    expect(isExpired).toBe(true);
  });

  it('should handle setTimeout', () => {
    const callback = vi.fn();

    setTimeout(callback, 5000);

    // Fast-forward time
    vi.advanceTimersByTime(5000);

    expect(callback).toHaveBeenCalled();
  });
});
```

## .NET/C# Mocking

### Moq - Basic Mocking

```csharp
using Moq;
using Xunit;
using FluentAssertions;

public class UserServiceTests
{
    [Fact]
    public void GetUser_ExistingId_ReturnsUser()
    {
        // Arrange
        var mockRepository = new Mock<IUserRepository>();
        var expectedUser = new User { Id = 1, Name = "John" };

        mockRepository
            .Setup(r => r.GetById(1))
            .Returns(expectedUser);

        var service = new UserService(mockRepository.Object);

        // Act
        var result = service.GetUser(1);

        // Assert
        result.Should().Be(expectedUser);
        mockRepository.Verify(r => r.GetById(1), Times.Once);
    }
}
```

### Mock Async Methods

```csharp
[Fact]
public async Task CreateUser_ValidData_CallsRepositoryAsync()
{
    // Arrange
    var mockRepository = new Mock<IUserRepository>();
    var newUser = new User { Name = "Jane", Email = "jane@example.com" };

    mockRepository
        .Setup(r => r.CreateAsync(It.IsAny<User>()))
        .ReturnsAsync(new User { Id = 1, Name = "Jane", Email = "jane@example.com" });

    var service = new UserService(mockRepository.Object);

    // Act
    var result = await service.CreateUserAsync(newUser);

    // Assert
    result.Id.Should().Be(1);
    mockRepository.Verify(
        r => r.CreateAsync(It.Is<User>(u => u.Name == "Jane")),
        Times.Once
    );
}
```

### Mock with Callbacks

```csharp
[Fact]
public void SaveUser_ModifiesUserBeforeSaving()
{
    // Arrange
    var mockRepository = new Mock<IUserRepository>();
    User savedUser = null;

    mockRepository
        .Setup(r => r.Save(It.IsAny<User>()))
        .Callback<User>(u => savedUser = u);

    var service = new UserService(mockRepository.Object);
    var user = new User { Name = "John" };

    // Act
    service.SaveUser(user);

    // Assert
    savedUser.Should().NotBeNull();
    savedUser.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
}
```

### Mock Entity Framework DbContext

```csharp
using Microsoft.EntityFrameworkCore;
using MockQueryable.Moq;

public class ProductServiceTests
{
    [Fact]
    public async Task GetProductsByCategory_ReturnsFilteredProducts()
    {
        // Arrange
        var products = new List<Product>
        {
            new Product { Id = 1, Name = "Phone", Category = "Electronics" },
            new Product { Id = 2, Name = "Shirt", Category = "Clothing" },
            new Product { Id = 3, Name = "Laptop", Category = "Electronics" }
        };

        var mockSet = products.AsQueryable().BuildMockDbSet();

        var mockContext = new Mock<ApplicationDbContext>();
        mockContext.Setup(c => c.Products).Returns(mockSet.Object);

        var service = new ProductService(mockContext.Object);

        // Act
        var result = await service.GetByCategoryAsync("Electronics");

        // Assert
        result.Should().HaveCount(2);
        result.Should().OnlyContain(p => p.Category == "Electronics");
    }
}
```

### Mock HTTP Client (.NET)

```csharp
using System.Net;
using System.Net.Http;
using Moq;
using Moq.Protected;

public class ApiClientTests
{
    [Fact]
    public async Task FetchData_SuccessfulResponse_ReturnsData()
    {
        // Arrange
        var mockHandler = new Mock<HttpMessageHandler>();
        var responseContent = new StringContent("{\"id\":1,\"name\":\"Test\"}");

        mockHandler
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>()
            )
            .ReturnsAsync(new HttpResponseMessage
            {
                StatusCode = HttpStatusCode.OK,
                Content = responseContent
            });

        var httpClient = new HttpClient(mockHandler.Object);
        var apiClient = new ApiClient(httpClient);

        // Act
        var result = await apiClient.FetchDataAsync(1);

        // Assert
        result.Id.Should().Be(1);
        result.Name.Should().Be("Test");
    }
}
```

### Mock Redis Cache

```csharp
public class CachingServiceTests
{
    [Fact]
    public async Task GetCached_WhenExists_ReturnsFromCache()
    {
        // Arrange
        var mockCache = new Mock<IDistributedCache>();
        var cachedData = Encoding.UTF8.GetBytes("{\"id\":1,\"name\":\"Cached\"}");

        mockCache
            .Setup(c => c.GetAsync("key:1", It.IsAny<CancellationToken>()))
            .ReturnsAsync(cachedData);

        var service = new CachingService(mockCache.Object);

        // Act
        var result = await service.GetAsync<User>("key:1");

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(1);
        result.Name.Should().Be("Cached");
    }

    [Fact]
    public async Task SetCached_CallsCache()
    {
        // Arrange
        var mockCache = new Mock<IDistributedCache>();
        var service = new CachingService(mockCache.Object);
        var user = new User { Id = 1, Name = "John" };

        // Act
        await service.SetAsync("key:1", user, TimeSpan.FromMinutes(5));

        // Assert
        mockCache.Verify(
            c => c.SetAsync(
                "key:1",
                It.IsAny<byte[]>(),
                It.Is<DistributedCacheEntryOptions>(o =>
                    o.AbsoluteExpirationRelativeToNow == TimeSpan.FromMinutes(5)),
                It.IsAny<CancellationToken>()
            ),
            Times.Once
        );
    }
}
```

## Spy vs Mock vs Stub

### Spy - Real object with tracked calls

```typescript
const realService = new EmailService();
const spy = vi.spyOn(realService, 'sendEmail');

await realService.sendEmail('test@example.com', 'Hello');

expect(spy).toHaveBeenCalledWith('test@example.com', 'Hello');
```

### Mock - Fake implementation

```typescript
const mockService = {
  sendEmail: vi.fn().mockResolvedValue(true),
};

await mockService.sendEmail('test@example.com', 'Hello');

expect(mockService.sendEmail).toHaveBeenCalled();
```

### Stub - Returns predefined values

```typescript
const stub = vi
  .fn()
  .mockReturnValueOnce('first')
  .mockReturnValueOnce('second')
  .mockReturnValue('default');

expect(stub()).toBe('first');
expect(stub()).toBe('second');
expect(stub()).toBe('default');
```

## Best Practices

1. **Use real implementations when possible** - Only mock external dependencies
2. **Don't mock what you don't own** - Wrap third-party APIs in adapters
3. **Verify interactions** - Use `.verify()` or `.toHaveBeenCalled()` to check mocks were used correctly
4. **Clear mocks between tests** - Use `afterEach` to reset mock state
5. **Prefer dependency injection** - Makes mocking easier
6. **Mock at the boundaries** - External APIs, databases, file system
7. **Keep mocks simple** - Complex mock setup indicates design issues

## Common Pitfalls

❌ **Over-mocking** - Mocking everything makes tests fragile
❌ **Under-verification** - Not checking that mocks were called correctly
❌ **Leaking state** - Not resetting mocks between tests
❌ **Testing the mock** - Verifying mock behavior instead of real code
❌ **Complex mock setup** - Indicates poor design, refactor instead
