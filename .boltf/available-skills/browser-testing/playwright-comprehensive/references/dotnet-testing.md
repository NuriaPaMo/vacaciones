# .NET Playwright Testing - C# Integration Patterns

## Setup and Installation

### Package Installation

```bash
# Install Playwright
dotnet add package Microsoft.Playwright

# Install test framework (choose one)
dotnet add package Microsoft.Playwright.NUnit
dotnet add package Microsoft.Playwright.MSTest
dotnet add package Microsoft.Playwright.xUnit

# Build and install browsers
dotnet build
pwsh bin/Debug/net8.0/playwright.ps1 install
```

### Project Configuration

```xml
<!-- YourProject.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Playwright.NUnit" Version="1.41.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
    <PackageReference Include="NUnit" Version="3.14.0" />
    <PackageReference Include="NUnit3TestAdapter" Version="4.5.0" />
  </ItemGroup>
</Project>
```

## NUnit Integration

### Basic Test Class

```csharp
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

namespace YourApp.Tests;

[TestFixture]
public class LoginTests : PageTest
{
    [Test]
    public async Task UserCanLogin()
    {
        await Page.GotoAsync("https://example.com/login");

        await Page.FillAsync("[data-testid='username']", "testuser");
        await Page.FillAsync("[data-testid='password']", "password123");
        await Page.ClickAsync("[data-testid='submit']");

        await Expect(Page).ToHaveURLAsync(new Regex(".*/dashboard"));
    }
}
```

### Page Object Model in C#

```csharp
public class LoginPage
{
    private readonly IPage _page;

    public LoginPage(IPage page)
    {
        _page = page;
    }

    private ILocator UsernameInput => _page.Locator("[data-testid='username']");
    private ILocator PasswordInput => _page.Locator("[data-testid='password']");
    private ILocator SubmitButton => _page.Locator("[data-testid='submit']");
    private ILocator ErrorMessage => _page.Locator("[data-testid='error']");

    public async Task NavigateAsync()
    {
        await _page.GotoAsync("https://example.com/login");
    }

    public async Task LoginAsync(string username, string password)
    {
        await UsernameInput.FillAsync(username);
        await PasswordInput.FillAsync(password);
        await SubmitButton.ClickAsync();
    }

    public async Task<string?> GetErrorMessageAsync()
    {
        return await ErrorMessage.TextContentAsync();
    }
}

// Usage in test
[Test]
public async Task InvalidCredentialsShowError()
{
    var loginPage = new LoginPage(Page);
    await loginPage.NavigateAsync();
    await loginPage.LoginAsync("invalid", "wrong");

    var error = await loginPage.GetErrorMessageAsync();
    Assert.That(error, Does.Contain("Invalid credentials"));
}
```

### Custom Fixtures

```csharp
public abstract class AuthenticatedPageTest : PageTest
{
    protected string? AuthToken { get; private set; }

    [SetUp]
    public async Task AuthenticatedSetup()
    {
        // Perform login
        await Page.GotoAsync("https://example.com/login");
        await Page.FillAsync("[data-testid='username']", "testuser");
        await Page.FillAsync("[data-testid='password']", "password123");
        await Page.ClickAsync("[data-testid='submit']");

        // Wait for authentication
        await Page.WaitForURLAsync(new Regex(".*/dashboard"));

        // Store auth token
        var cookies = await Context.CookiesAsync();
        AuthToken = cookies.FirstOrDefault(c => c.Name == "auth-token")?.Value;
    }
}

// Usage
[TestFixture]
public class DashboardTests : AuthenticatedPageTest
{
    [Test]
    public async Task CanAccessDashboard()
    {
        // Already authenticated from base class
        await Expect(Page.Locator("[data-testid='welcome']")).ToBeVisibleAsync();
    }
}
```

## MSTest Integration

```csharp
using Microsoft.Playwright;
using Microsoft.Playwright.MSTest;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace YourApp.Tests;

[TestClass]
public class LoginTests : PageTest
{
    [TestMethod]
    public async Task UserCanLogin()
    {
        await Page.GotoAsync("https://example.com/login");

        await Page.FillAsync("[data-testid='username']", "testuser");
        await Page.FillAsync("[data-testid='password']", "password123");
        await Page.ClickAsync("[data-testid='submit']");

        await Expect(Page).ToHaveURLAsync(new Regex(".*/dashboard"));
    }

    [TestInitialize]
    public async Task TestSetup()
    {
        // Runs before each test
        await Page.SetViewportSizeAsync(1920, 1080);
    }

    [TestCleanup]
    public async Task TestTeardown()
    {
        // Runs after each test
        if (TestContext.CurrentTestOutcome == UnitTestOutcome.Failed)
        {
            var screenshot = await Page.ScreenshotAsync();
            TestContext.AddResultFile($"failure-{TestContext.TestName}.png");
        }
    }
}
```

## xUnit Integration

```csharp
using Microsoft.Playwright;
using Xunit;

namespace YourApp.Tests;

public class LoginTests : IAsyncLifetime
{
    private IPlaywright? _playwright;
    private IBrowser? _browser;
    private IPage? _page;

    public async Task InitializeAsync()
    {
        _playwright = await Playwright.CreateAsync();
        _browser = await _playwright.Chromium.LaunchAsync(new()
        {
            Headless = true
        });
        _page = await _browser.NewPageAsync();
    }

    public async Task DisposeAsync()
    {
        if (_page != null)
            await _page.CloseAsync();

        if (_browser != null)
            await _browser.CloseAsync();

        _playwright?.Dispose();
    }

    [Fact]
    public async Task UserCanLogin()
    {
        await _page!.GotoAsync("https://example.com/login");

        await _page.FillAsync("[data-testid='username']", "testuser");
        await _page.FillAsync("[data-testid='password']", "password123");
        await _page.ClickAsync("[data-testid='submit']");

        var url = _page.Url;
        Assert.Contains("/dashboard", url);
    }
}
```

## Async Patterns

### async/await Best Practices

```csharp
// ✅ Good: Proper async/await
public async Task GoodAsyncPattern()
{
    await Page.GotoAsync("https://example.com");
    await Page.ClickAsync("button");
    await Page.WaitForSelectorAsync(".result");
}

// ❌ Bad: Blocking on async code
public void BadAsyncPattern()
{
    Page.GotoAsync("https://example.com").Wait(); // Don't do this!
    Page.ClickAsync("button").GetAwaiter().GetResult(); // Don't do this!
}

// ✅ Good: Parallel execution
public async Task ParallelRequests()
{
    var tasks = new[]
    {
        Page.GotoAsync("https://example.com/page1"),
        Page.GotoAsync("https://example.com/page2"),
        Page.GotoAsync("https://example.com/page3")
    };

    await Task.WhenAll(tasks);
}
```

### Cancellation Token Support

```csharp
[Test]
public async Task TestWithCancellation()
{
    using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));

    try
    {
        await Page.GotoAsync("https://example.com");

        // Long-running operation
        await Page.WaitForSelectorAsync(".slow-element", new()
        {
            Timeout = 60000
        });
    }
    catch (OperationCanceledException)
    {
        Assert.Fail("Test was cancelled due to timeout");
    }
}
```

## Advanced C# Patterns

### Extension Methods

```csharp
public static class PlaywrightExtensions
{
    public static async Task<bool> IsVisibleAsync(
        this ILocator locator,
        int timeoutMs = 5000)
    {
        try
        {
            await locator.WaitForAsync(new()
            {
                State = WaitForSelectorState.Visible,
                Timeout = timeoutMs
            });
            return true;
        }
        catch (TimeoutException)
        {
            return false;
        }
    }

    public static async Task FillAndVerifyAsync(
        this ILocator locator,
        string text)
    {
        await locator.FillAsync(text);

        var value = await locator.InputValueAsync();
        if (value != text)
        {
            throw new Exception(
                $"Failed to fill input. Expected: '{text}', Got: '{value}'");
        }
    }
}

// Usage
[Test]
public async Task UseExtensions()
{
    var input = Page.Locator("[data-testid='email']");

    if (await input.IsVisibleAsync())
    {
        await input.FillAndVerifyAsync("test@example.com");
    }
}
```

### Generic Page Objects

```csharp
public abstract class BasePage<T> where T : BasePage<T>
{
    protected readonly IPage Page;

    protected BasePage(IPage page)
    {
        Page = page;
    }

    public async Task<T> NavigateAsync(string url)
    {
        await Page.GotoAsync(url);
        return (T)this;
    }

    public async Task<T> WaitForLoadAsync()
    {
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        return (T)this;
    }
}

public class DashboardPage : BasePage<DashboardPage>
{
    public DashboardPage(IPage page) : base(page) { }

    public ILocator WelcomeMessage => Page.Locator("[data-testid='welcome']");

    public async Task<DashboardPage> LoadDataAsync()
    {
        await Page.ClickAsync("[data-testid='load-data']");
        await Page.WaitForResponseAsync(r => r.Url.Contains("/api/data"));
        return this;
    }
}

// Fluent usage
[Test]
public async Task FluentPageObjects()
{
    var dashboard = new DashboardPage(Page);

    await dashboard
        .NavigateAsync("https://example.com/dashboard")
        .WaitForLoadAsync()
        .LoadDataAsync();

    await Expect(dashboard.WelcomeMessage).ToBeVisibleAsync();
}
```

### Retry Policies

```csharp
public static class RetryHelper
{
    public static async Task<T> RetryAsync<T>(
        Func<Task<T>> action,
        int maxAttempts = 3,
        TimeSpan? delay = null)
    {
        delay ??= TimeSpan.FromSeconds(1);
        Exception? lastException = null;

        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            try
            {
                return await action();
            }
            catch (Exception ex)
            {
                lastException = ex;

                if (attempt < maxAttempts)
                {
                    await Task.Delay(delay.Value * attempt);
                }
            }
        }

        throw new Exception(
            $"Operation failed after {maxAttempts} attempts",
            lastException);
    }
}

// Usage
[Test]
public async Task RetryableOperation()
{
    var result = await RetryHelper.RetryAsync(async () =>
    {
        await Page.GotoAsync("https://example.com");
        return await Page.TextContentAsync("h1");
    });

    Assert.That(result, Does.Contain("Welcome"));
}
```

## Configuration

### appsettings.json Integration

```csharp
public class TestConfiguration
{
    public string BaseUrl { get; set; } = string.Empty;
    public bool Headless { get; set; } = true;
    public int Timeout { get; set; } = 30000;
    public BrowserType Browser { get; set; } = BrowserType.Chromium;
}

public enum BrowserType
{
    Chromium,
    Firefox,
    Webkit
}

// Load configuration
var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")}.json", optional: true)
    .Build();

var testConfig = configuration.GetSection("TestConfiguration").Get<TestConfiguration>();
```

## Best Practices

- Use `PageTest` base class for NUnit/MSTest (includes automatic cleanup)
- Implement Page Object Model for maintainability
- Use async/await properly (never use `.Wait()` or `.Result`)
- Leverage C# language features (extension methods, generics, LINQ)
- Configure test framework in `*.csproj` file
- Use `IAsyncLifetime` for xUnit async setup/teardown
- Implement retry policies for flaky operations
- Use cancellation tokens for long-running tests
- Store screenshots/traces on test failure
