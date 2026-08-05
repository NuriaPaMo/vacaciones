---
name: playwright-comprehensive
description: Comprehensive Playwright browser automation for E2E testing, general browser automation, and local webapp testing. Covers Page Object Model, fixtures, Aspire integration, dev server detection, responsive design validation, and complete test orchestration.
---

# Playwright Comprehensive - Browser Automation & Testing

**USE THIS SKILL WHEN** the user needs to create, modify, or debug browser-based tests or automation scripts using Playwright, including E2E testing with Page Object Model, general browser automation with helpers, and local webapp testing workflows.

## Quick Start

### TypeScript Installation

```bash
npm install -D @playwright/test @axe-core/playwright
npx playwright install
```

### .NET Installation

```bash
dotnet add package Microsoft.Playwright
dotnet build
pwsh bin/Debug/net8.0/playwright.ps1 install
```

### First Test Example (TypeScript)

```typescript
import { test, expect } from '@playwright/test';

test('basic navigation test', async ({ page }) => {
  await page.goto('https://example.com');
  await expect(page).toHaveTitle(/Example/);
  const heading = page.locator('h1');
  await expect(heading).toBeVisible();
});
```

### First Test Example (.NET)

```csharp
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;

[Test]
public async Task BasicNavigationTest()
{
    await Page.GotoAsync("https://example.com");
    await Expect(Page).ToHaveTitleAsync(new Regex("Example"));
    var heading = Page.Locator("h1");
    await Expect(heading).ToBeVisibleAsync();
}
```

## Core Capabilities

### 1. E2E Testing Best Practices

**Page Object Model (POM)** - Encapsulate page interactions:

```typescript
// pages/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.locator('[data-testid="username"]');
    this.passwordInput = page.locator('[data-testid="password"]');
    this.submitButton = page.locator('[data-testid="submit"]');
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}
```

**Fixtures** - Reusable test setup with dependency injection:

```typescript
// fixtures/authFixtures.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

type AuthFixtures = {
  loginPage: LoginPage;
  authenticatedPage: Page;
};

export const test = base.extend<AuthFixtures>({
  loginPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await use(loginPage);
  },

  authenticatedPage: async ({ page, loginPage }, use) => {
    await page.goto('/login');
    await loginPage.login('testuser', 'password123');
    await use(page);
  },
});
```

### 2. General Browser Automation

**Auto-Detect Dev Servers** - Automatically find running development servers:

```typescript
async function detectDevServers(): Promise<string[]> {
  const commonPorts = [3000, 4200, 5173, 8080, 8081];
  const servers: string[] = [];

  for (const port of commonPorts) {
    try {
      const response = await fetch(`http://localhost:${port}`);
      if (response.ok) {
        servers.push(`http://localhost:${port}`);
      }
    } catch {
      // Port not available
    }
  }

  return servers;
}

// Usage
const servers = await detectDevServers();
if (servers.length > 0) {
  await page.goto(servers[0]);
}
```

**Safe Interaction Helpers** - Robust element interactions:

```typescript
async function safeClick(page: Page, selector: string, timeout = 5000) {
  const element = page.locator(selector);
  await element.waitFor({ state: 'visible', timeout });
  await element.click();
}

async function safeType(page: Page, selector: string, text: string, timeout = 5000) {
  const element = page.locator(selector);
  await element.waitFor({ state: 'visible', timeout });
  await element.clear();
  await element.fill(text);
}
```

**Custom HTTP Headers** - Add headers for testing:

```typescript
await page.goto('https://example.com', {
  headers: {
    'X-Test-User': 'automation',
    'X-Custom-Header': process.env.CUSTOM_VALUE || '',
  },
});
```

### 3. Local Webapp Testing

**Responsive Design Validation** - Test across viewports:

```typescript
test('responsive layout', async ({ page }) => {
  const viewports = [
    { width: 375, height: 667, name: 'Mobile' },
    { width: 768, height: 1024, name: 'Tablet' },
    { width: 1920, height: 1080, name: 'Desktop' },
  ];

  for (const viewport of viewports) {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.goto('http://localhost:4200');

    await page.screenshot({
      path: `screenshots/${viewport.name}.png`,
      fullPage: true,
    });

    // Verify layout elements
    const nav = page.locator('nav');
    await expect(nav).toBeVisible();
  }
});
```

**Console Log Capture** - Debug frontend issues:

```typescript
test('capture console logs', async ({ page }) => {
  const logs: string[] = [];

  page.on('console', (msg) => {
    logs.push(`${msg.type()}: ${msg.text()}`);
  });

  await page.goto('http://localhost:4200');

  // Log all console messages
  console.log('Frontend Console Logs:');
  logs.forEach((log) => console.log(log));
});
```

**Form Testing** - Validate form interactions:

```typescript
test('form validation', async ({ page }) => {
  await page.goto('http://localhost:4200/signup');

  // Test empty submission
  await page.click('[data-testid="submit"]');
  const errorMessage = page.locator('[data-testid="error"]');
  await expect(errorMessage).toBeVisible();

  // Test valid submission
  await page.fill('[data-testid="email"]', 'user@example.com');
  await page.fill('[data-testid="password"]', 'SecurePass123');
  await page.click('[data-testid="submit"]');

  await expect(page).toHaveURL(/dashboard/);
});
```

### 4. Advanced Features

**API Mocking** - Control backend responses:

```typescript
test('mock API response', async ({ page }) => {
  await page.route('**/api/users', (route) => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([{ id: 1, name: 'Test User', email: 'test@example.com' }]),
    });
  });

  await page.goto('http://localhost:4200');
  const userList = page.locator('[data-testid="user-list"]');
  await expect(userList).toContainText('Test User');
});
```

**Accessibility Testing** - Automated a11y checks:

```typescript
import { injectAxe, checkA11y } from 'axe-playwright';

test('accessibility check', async ({ page }) => {
  await page.goto('http://localhost:4200');
  await injectAxe(page);

  const violations = await checkA11y(page);
  expect(violations).toHaveLength(0);
});
```

## Essential Patterns

### Pattern 1: Complete Login Flow

```typescript
import { test, expect } from '@playwright/test';

test('complete login flow', async ({ page }) => {
  // Navigate
  await page.goto('http://localhost:4200/login');

  // Fill credentials
  await page.fill('[data-testid="username"]', 'testuser');
  await page.fill('[data-testid="password"]', 'password123');

  // Submit
  await page.click('[data-testid="login-button"]');

  // Wait for navigation
  await page.waitForURL('**/dashboard');

  // Verify authenticated state
  const userName = page.locator('[data-testid="user-name"]');
  await expect(userName).toContainText('testuser');

  // Take screenshot for documentation
  await page.screenshot({ path: 'screenshots/dashboard.png' });
});
```

## Running Tests

### TypeScript

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test tests/login.spec.ts

# Run in headed mode (visible browser)
npx playwright test --headed

# Run in debug mode
npx playwright test --debug

# Run with specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit
```

### .NET

```bash
# Run all tests
dotnet test

# Run specific test
dotnet test --filter "FullyQualifiedName~LoginTest"

# Run with detailed output
dotnet test --logger "console;verbosity=detailed"
```

## Configuration

### TypeScript Configuration (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['junit', { outputFile: 'test-results/junit.xml' }]],
  use: {
    baseURL: 'http://localhost:4200',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
});
```

### .NET Configuration (Example)

```csharp
public class PlaywrightTest : PageTest
{
    [SetUp]
    public async Task Setup()
    {
        await Context.Tracing.StartAsync(new()
        {
            Screenshots = true,
            Snapshots = true,
            Sources = true
        });
    }

    [TearDown]
    public async Task Teardown()
    {
        await Context.Tracing.StopAsync(new()
        {
            Path = $"traces/{TestContext.CurrentContext.Test.Name}.zip"
        });
    }
}
```

## Aspire Integration

For .NET Aspire distributed applications, Playwright integrates with the Testing.Agent library to orchestrate backend services during E2E tests:

```csharp
public class AspireIntegrationTests : IClassFixture<DistributedApplicationTestingBuilder>
{
    private readonly DistributedApplicationTestingBuilder _builder;

    public AspireIntegrationTests(DistributedApplicationTestingBuilder builder)
    {
        _builder = builder;
    }

    [Fact]
    public async Task FullStackTest()
    {
        await using var app = await _builder.BuildAsync();
        await app.StartAsync();

        // Get frontend URL from Aspire
        var frontendUrl = app.GetEndpoint("frontend");

        // Run Playwright test
        using var playwright = await Playwright.CreateAsync();
        await using var browser = await playwright.Chromium.LaunchAsync();
        var page = await browser.NewPageAsync();

        await page.GotoAsync(frontendUrl);
        // ... test interactions
    }
}
```

See [aspire-integration.md](references/aspire-integration.md) for complete Aspire workflows.

## Best Practices

**DO:**

- ✅ Use `data-testid` attributes for stable selectors
- ✅ Prefer `page.locator()` over `page.$()` for auto-waiting
- ✅ Use Page Object Model for maintainable tests
- ✅ Implement fixtures for reusable setup
- ✅ Capture screenshots on failure for debugging
- ✅ Use explicit waits (`waitForSelector`, `waitForURL`)
- ✅ Test across multiple browsers (Chromium, Firefox, WebKit)
- ✅ Enable trace on retry for debugging
- ✅ Mock external APIs for deterministic tests

**DON'T:**

- ❌ Use fragile CSS selectors (`.btn-primary`, `#submit-button-123`)
- ❌ Use `page.waitForTimeout()` for synchronization (use explicit waits)
- ❌ Hardcode delays or sleep calls
- ❌ Ignore accessibility violations
- ❌ Skip cross-browser testing
- ❌ Test against production environments
- ❌ Store credentials in test code (use environment variables)

## Troubleshooting

**Issue: Tests timeout waiting for selectors**

- Solution: Check if element exists with correct `data-testid`, increase timeout, verify application loaded

**Issue: Flaky tests that pass/fail randomly**

- Solution: Add explicit waits, avoid `waitForTimeout`, use network idle state, check for race conditions

**Issue: Cannot find running dev server**

- Solution: Use `detectDevServers()` helper, verify server is running, check port configuration

**Issue: Screenshots not captured**

- Solution: Ensure `screenshot: 'only-on-failure'` in config, check output directory exists

**Issue: Aspire tests fail to start services**

- Solution: Verify Aspire app builds successfully, check service health endpoints, review logs

## Progressive Disclosure - Advanced Topics

- **[E2E Patterns](references/e2e-patterns.md)** - Advanced Page Object Model, fixtures architecture, parallel execution strategies
- **[Automation Patterns](references/automation-patterns.md)** - Dev server detection algorithms, advanced helpers, /tmp scripting pattern
- **[Local Testing Guide](references/local-testing-guide.md)** - Local development workflows, debugging techniques, hot reload integration
- **[Aspire Integration](references/aspire-integration.md)** - Complete .NET Aspire orchestration, agent coordination, service health checks
- **[.NET Testing](references/dotnet-testing.md)** - C#/.NET Playwright usage, NUnit/MSTest/xUnit integration, async patterns
- **[Advanced Features](references/advanced-features.md)** - Visual regression testing, mobile emulation, network interception, video recording

## Technology Stack

- **Playwright**: Cross-browser automation (Chromium, Firefox, WebKit)
- **TypeScript**: Type-safe test authoring
- **.NET/C#**: .NET Playwright bindings with NUnit/MSTest/xUnit
- **Axe-core**: Automated accessibility testing
- **Page Object Model**: Maintainable test architecture
- **Fixtures**: Reusable test setup with dependency injection
- **.NET Aspire**: Distributed application orchestration for E2E testing
- **Dev Tools**: Chrome DevTools Protocol integration for debugging
