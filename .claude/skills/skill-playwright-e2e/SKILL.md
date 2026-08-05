---
name: skill-playwright-e2e
description: "End-to-end testing with Playwright for frontend applications"
---

# Playwright E2E Testing

## When to Use

- Testing critical user journeys end-to-end
- Validating frontend behavior across browsers
- Automating UI regression testing
- Testing frontend integration with backend APIs
- Generating test reports with screenshots and traces
- The user or an agent needs to automate UI testing

## Quick Start

```bash
# Install Playwright
npm install -D @playwright/test
npx playwright install

# Or for .NET projects
dotnet add package Microsoft.Playwright
pwsh bin/Debug/net8.0/playwright.ps1 install

# Run tests
npx playwright test
# or: dotnet test
```

## Project Structure

```text
tests/e2e/
├── playwright.config.ts
├── tests/
│   ├── authentication/
│   │   ├── login.spec.ts
│   │   └── logout.spec.ts
│   ├── time-tracking/
│   │   ├── create-entry.spec.ts
│   │   └── edit-entry.spec.ts
│   └── reports/
│       └── generate-report.spec.ts
├── fixtures/
│   ├── test-users.ts
│   └── test-data.ts
└── utils/
    ├── page-objects/
    │   ├── LoginPage.ts
    │   ├── DashboardPage.ts
    │   └── TimeEntryPage.ts
    └── helpers.ts
```

## Playwright Configuration (TypeScript)

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['json', { outputFile: 'test-results/results.json' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:5173',
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
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

## Page Object Model

```typescript
// tests/e2e/utils/page-objects/LoginPage.ts
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly loginButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.locator('input[name="email"]');
    this.passwordInput = page.locator('input[type="password"]');
    this.loginButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator('[role="alert"]');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }

  async expectErrorMessage(message: string) {
    await this.errorMessage.waitFor({ state: 'visible' });
    await expect(this.errorMessage).toContainText(message);
  }
}
```

## Test Example (TypeScript)

```typescript
// tests/e2e/authentication/login.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../utils/page-objects/LoginPage';
import { DashboardPage } from '../utils/page-objects/DashboardPage';

test.describe('User Authentication', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.goto();
  });

  test('should login successfully with valid credentials', async ({ page }) => {
    // Arrange
    const email = 'test.user@example.com';
    const password = 'SecurePass123!';

    // Act
    await loginPage.login(email, password);

    // Assert
    await expect(page).toHaveURL('/dashboard');
    await expect(dashboardPage.welcomeMessage).toContainText('Welcome back');
  });

  test('should show error with invalid credentials', async ({ page }) => {
    // Act
    await loginPage.login('user@example.com', 'WrongPassword');

    // Assert
    await loginPage.expectErrorMessage('Invalid credentials');
    await expect(page).toHaveURL('/login');
  });

  test('should validate empty fields', async ({ page }) => {
    // Act
    await loginPage.loginButton.click();

    // Assert
    await expect(loginPage.emailInput).toHaveAttribute('aria-invalid', 'true');
    await expect(loginPage.passwordInput).toHaveAttribute('aria-invalid', 'true');
  });
});
```

## API Mocking

```typescript
// tests/e2e/time-tracking/create-entry.spec.ts
import { test, expect } from '@playwright/test';

test('should handle API errors gracefully', async ({ page }) => {
  // Mock API to return error
  await page.route('**/api/time-entries', (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: 'Internal Server Error' }),
    });
  });

  await page.goto('/time-tracking');
  await page.locator('button:has-text("New Entry")').click();

  // Fill form
  await page.locator('input[name="hours"]').fill('2');
  await page.locator('button[type="submit"]').click();

  // Verify error handling
  await expect(page.locator('[role="alert"]')).toContainText('Failed to create entry');
});
```

## Fixtures for Test Data

```typescript
// tests/e2e/fixtures/test-users.ts
import { test as base } from '@playwright/test';

type TestUser = {
  email: string;
  password: string;
  name: string;
};

type TestFixtures = {
  authenticatedUser: TestUser;
};

export const test = base.extend<TestFixtures>({
  authenticatedUser: async ({ page }, use) => {
    const user: TestUser = {
      email: 'test.user@example.com',
      password: 'SecurePass123!',
      name: 'Test User',
    };

    // Login before each test
    await page.goto('/login');
    await page.locator('input[name="email"]').fill(user.email);
    await page.locator('input[type="password"]').fill(user.password);
    await page.locator('button[type="submit"]').click();
    await page.waitForURL('/dashboard');

    await use(user);

    // Cleanup: logout
    await page.locator('[aria-label="User menu"]').click();
    await page.locator('text=Logout').click();
  },
});

export { expect } from '@playwright/test';
```

## Visual Regression Testing

```typescript
// tests/e2e/visual/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test('dashboard layout should match snapshot', async ({ page }) => {
  await page.goto('/dashboard');
  await page.waitForLoadState('networkidle');

  // Take screenshot and compare
  await expect(page).toHaveScreenshot('dashboard.png', {
    fullPage: true,
    maxDiffPixels: 100,
  });
});
```

## Accessibility Testing

```typescript
// tests/e2e/accessibility/login.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('login page should have no accessibility violations', async ({ page }) => {
  await page.goto('/login');

  const accessibilityScanResults = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
```

## Playwright for .NET

```csharp
// tests/TimeTracking.E2ETests/LoginTests.cs
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

namespace TimeTracking.E2ETests;

[TestFixture]
public class LoginTests : PageTest
{
    [SetUp]
    public async Task Setup()
    {
        await Page.GotoAsync("http://localhost:5173/login");
    }

    [Test]
    public async Task ShouldLoginSuccessfully()
    {
        // Arrange
        var emailInput = Page.Locator("input[name='email']");
        var passwordInput = Page.Locator("input[type='password']");
        var loginButton = Page.Locator("button[type='submit']");

        // Act
        await emailInput.FillAsync("test.user@example.com");
        await passwordInput.FillAsync("SecurePass123!");
        await loginButton.ClickAsync();

        // Assert
        await Expect(Page).ToHaveURLAsync(new Regex(".*/dashboard"));
        await Expect(Page.Locator("text=Welcome back")).ToBeVisibleAsync();
    }

    [Test]
    public async Task ShouldShowErrorWithInvalidCredentials()
    {
        // Act
        await Page.Locator("input[name='email']").FillAsync("user@example.com");
        await Page.Locator("input[type='password']").FillAsync("WrongPassword");
        await Page.Locator("button[type='submit']").ClickAsync();

        // Assert
        var errorMessage = Page.Locator("[role='alert']");
        await Expect(errorMessage).ToContainTextAsync("Invalid credentials");
    }
}
```

## Running Tests

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test login.spec.ts

# Run in headed mode (see browser)
npx playwright test --headed

# Run specific browser
npx playwright test --project=chromium

# Debug mode
npx playwright test --debug

# Generate HTML report
npx playwright show-report

# Update snapshots
npx playwright test --update-snapshots

# .NET
dotnet test
dotnet test --filter "FullyQualifiedName~Login"
```

## Best Practices

### Locators

- ✅ Use role-based selectors: `page.getByRole('button', { name: 'Submit' })`
- ✅ Use labels: `page.getByLabel('Email')`
- ✅ Use test IDs for dynamic content: `page.getByTestId('user-menu')`
- ❌ Avoid CSS selectors tied to implementation: `.css-xyz-123`
- ❌ Avoid XPath when possible

### Assertions

- ✅ Use auto-waiting assertions: `expect(locator).toBeVisible()`
- ✅ Check state, not implementation: test what user sees
- ✅ Use soft assertions for multiple checks
- ❌ Don't use `sleep()` or arbitrary waits

### Test Organization

- ✅ One user journey per test file
- ✅ Use Page Object Model for reusability
- ✅ Use fixtures for authentication
- ✅ Keep tests independent
- ❌ Don't share state between tests
- ❌ Don't test implementation details

### Performance

- ✅ Run tests in parallel
- ✅ Use `waitForLoadState('networkidle')` carefully
- ✅ Mock external dependencies
- ✅ Take screenshots/videos only on failure
- ❌ Don't run full test suite on every commit

## Integration with CI/CD

```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Run Playwright tests
        run: npx playwright test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
```

## References

- [Playwright Documentation](https://playwright.dev/)
- [Playwright for .NET](https://playwright.dev/dotnet/)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [Accessibility Testing](https://playwright.dev/docs/accessibility-testing)
