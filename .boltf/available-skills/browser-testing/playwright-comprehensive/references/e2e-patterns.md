# E2E Testing Patterns - Advanced Page Object Model & Test Architecture

## Advanced Page Object Model

### Hierarchical Page Objects

Build complex page structures with inheritance:

```typescript
// base/BasePage.ts
export abstract class BasePage {
  constructor(protected page: Page) {}

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async takeScreenshot(name: string) {
    await this.page.screenshot({ path: `screenshots/${name}.png` });
  }
}

// pages/DashboardPage.ts
export class DashboardPage extends BasePage {
  readonly header: Header;
  readonly sidebar: Sidebar;

  constructor(page: Page) {
    super(page);
    this.header = new Header(page);
    this.sidebar = new Sidebar(page);
  }

  async navigateToSection(section: string) {
    await this.sidebar.clickItem(section);
    await this.waitForPageLoad();
  }
}
```

### Component-Based Architecture

Reusable UI components:

```typescript
// components/Modal.ts
export class Modal {
  readonly locator: Locator;
  readonly closeButton: Locator;
  readonly confirmButton: Locator;

  constructor(page: Page, dataTestId: string) {
    this.locator = page.locator(`[data-testid="${dataTestId}"]`);
    this.closeButton = this.locator.locator('[data-testid="close"]');
    this.confirmButton = this.locator.locator('[data-testid="confirm"]');
  }

  async isVisible(): Promise<boolean> {
    return await this.locator.isVisible();
  }

  async confirm() {
    await this.confirmButton.click();
    await this.locator.waitFor({ state: 'hidden' });
  }
}

// Usage in page object
export class UserProfilePage extends BasePage {
  readonly deleteModal: Modal;

  constructor(page: Page) {
    super(page);
    this.deleteModal = new Modal(page, 'delete-confirmation-modal');
  }

  async deleteAccount() {
    await this.page.click('[data-testid="delete-account"]');
    await this.deleteModal.confirm();
  }
}
```

## Advanced Fixtures Architecture

### Layered Fixtures

Build complex test scenarios with fixture composition:

```typescript
// fixtures/baseFixtures.ts
export const test = base.extend<{
  apiClient: APIClient;
  database: Database;
}>({
  apiClient: async ({}, use) => {
    const client = new APIClient(process.env.API_URL);
    await use(client);
  },

  database: async ({}, use) => {
    const db = await Database.connect(process.env.DB_URL);
    await use(db);
    await db.close();
  },
});

// fixtures/authFixtures.ts
export const authTest = test.extend<{
  authenticatedAPI: APIClient;
  adminPage: Page;
}>({
  authenticatedAPI: async ({ apiClient }, use) => {
    await apiClient.login('admin@example.com', 'password');
    await use(apiClient);
  },

  adminPage: async ({ page, authenticatedAPI }, use) => {
    const cookies = await authenticatedAPI.getCookies();
    await page.context().addCookies(cookies);
    await page.goto('/admin');
    await use(page);
  },
});
```

### Data Setup Fixtures

Automated test data creation:

```typescript
export const dataTest = test.extend<{
  testUser: User;
  testProduct: Product;
}>({
  testUser: async ({ database }, use) => {
    const user = await database.users.create({
      email: `test-${Date.now()}@example.com`,
      name: 'Test User',
      role: 'customer',
    });

    await use(user);

    // Cleanup
    await database.users.delete(user.id);
  },

  testProduct: async ({ database, testUser }, use) => {
    const product = await database.products.create({
      name: 'Test Product',
      price: 99.99,
      ownerId: testUser.id,
    });

    await use(product);

    await database.products.delete(product.id);
  },
});
```

## Parallel Execution Strategies

### Sharding

Distribute tests across multiple machines:

```bash
# Machine 1
npx playwright test --shard=1/3

# Machine 2
npx playwright test --shard=2/3

# Machine 3
npx playwright test --shard=3/3
```

Configuration:

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: true,

  // Shard configuration (optional, can be passed via CLI)
  shard: process.env.SHARD
    ? {
        current: parseInt(process.env.SHARD_INDEX),
        total: parseInt(process.env.SHARD_TOTAL),
      }
    : undefined,
});
```

### Worker-Scoped Fixtures

Share expensive setup across tests in same worker:

```typescript
export const test = base.extend<
  {},
  {
    workerStorageState: string;
  }
>({
  workerStorageState: [
    async ({ browser }, use) => {
      // This runs once per worker
      const context = await browser.newContext();
      const page = await context.newPage();

      // Perform login
      await page.goto('/login');
      await page.fill('[data-testid="username"]', 'testuser');
      await page.fill('[data-testid="password"]', 'password123');
      await page.click('[data-testid="submit"]');
      await page.waitForURL('**/dashboard');

      // Save authenticated state
      const storageState = await context.storageState();
      const path = 'auth-state.json';
      await fs.writeFile(path, JSON.stringify(storageState));

      await context.close();
      await use(path);
    },
    { scope: 'worker' },
  ],
});
```

### Parallel Test Isolation

Ensure tests don't interfere with each other:

```typescript
test.describe('User Management', () => {
  test('create user', async ({ page, database }) => {
    // Use unique identifiers
    const userId = `user-${test.info().workerIndex}-${Date.now()}`;

    await page.goto('/admin/users/create');
    await page.fill('[data-testid="user-id"]', userId);
    await page.click('[data-testid="submit"]');

    // Verify in database
    const user = await database.users.findById(userId);
    expect(user).toBeTruthy();
  });
});
```

## Retry Strategies

### Conditional Retries

Retry only on specific errors:

```typescript
export default defineConfig({
  retries: process.env.CI ? 2 : 0,

  use: {
    actionTimeout: 10000,
    navigationTimeout: 30000,
  },
});

// In test file
test('flaky operation', async ({ page }) => {
  let attempts = 0;

  await test.step('retry operation', async () => {
    while (attempts < 3) {
      try {
        await page.click('[data-testid="submit"]');
        await page.waitForURL('**/success', { timeout: 5000 });
        break; // Success
      } catch (error) {
        attempts++;
        if (attempts >= 3) throw error;
        await page.reload();
      }
    }
  });
});
```

## Visual Regression Testing

### Snapshot Testing

```typescript
test('visual regression', async ({ page }) => {
  await page.goto('/');

  // Full page screenshot comparison
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixels: 100,
  });

  // Element-specific comparison
  const header = page.locator('header');
  await expect(header).toHaveScreenshot('header.png');
});
```

### Update Snapshots

```bash
# Update all snapshots
npx playwright test --update-snapshots

# Update specific test snapshots
npx playwright test homepage.spec.ts --update-snapshots
```

## Multi-Browser Testing Matrix

```typescript
export default defineConfig({
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
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 13'] },
    },
  ],
});
```

Run specific browser:

```bash
npx playwright test --project=chromium
npx playwright test --project=mobile-safari
```

## Trace Viewer Integration

Enable tracing for debugging:

```typescript
export default defineConfig({
  use: {
    trace: 'on-first-retry', // Options: 'on', 'off', 'retain-on-failure', 'on-first-retry'
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

View traces:

```bash
npx playwright show-trace trace.zip
```

## Reporting

Multiple reporters configuration:

```typescript
export default defineConfig({
  reporter: [
    ['html', { outputFolder: 'test-results/html' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['json', { outputFile: 'test-results/results.json' }],
    ['list'], // Console output
  ],
});
```

## Best Practices

- Use Page Object Model for all UI interactions
- Implement fixtures for complex setup/teardown
- Enable parallel execution with proper isolation
- Use worker-scoped fixtures for expensive operations
- Implement visual regression for critical UI paths
- Configure appropriate retry strategies
- Use trace viewer for debugging failures
- Test across multiple browsers and devices
