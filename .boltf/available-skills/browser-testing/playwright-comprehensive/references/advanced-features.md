# Advanced Playwright Features

## Visual Regression Testing

### Component-Level Visual Testing

```typescript
test('header visual regression', async ({ page }) => {
  await page.goto('http://localhost:4200');

  const header = page.locator('header');

  await expect(header).toHaveScreenshot('header.png', {
    maxDiffPixels: 100,
    threshold: 0.2,
  });
});
```

### Full-Page Visual Comparison

```typescript
test('homepage visual regression', async ({ page }) => {
  await page.goto('http://localhost:4200');

  // Wait for all images to load
  await page.waitForLoadState('networkidle');

  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01, // Allow 1% difference
  });
});
```

### Cross-Browser Visual Testing

```typescript
// playwright.config.ts
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
  ],
});

// Test runs across all browsers
test('cross-browser appearance', async ({ page, browserName }) => {
  await page.goto('http://localhost:4200');

  await expect(page).toHaveScreenshot(`homepage-${browserName}.png`);
});
```

### Updating Snapshots

```bash
# Update all snapshots
npx playwright test --update-snapshots

# Update specific browser
npx playwright test --update-snapshots --project=chromium

# Update specific test
npx playwright test homepage.spec.ts --update-snapshots
```

## Mobile Emulation

### Mobile Device Testing

```typescript
import { test, expect, devices } from '@playwright/test';

test.use({ ...devices['iPhone 13 Pro'] });

test('mobile navigation', async ({ page }) => {
  await page.goto('http://localhost:4200');

  // Mobile-specific interactions
  const menuButton = page.locator('[data-testid="mobile-menu"]');
  await expect(menuButton).toBeVisible();

  await menuButton.click();

  const nav = page.locator('nav');
  await expect(nav).toHaveClass(/open/);
});
```

### Custom Mobile Viewport

```typescript
test('custom mobile size', async ({ page }) => {
  await page.setViewportSize({
    width: 375,
    height: 812,
  });

  await page.goto('http://localhost:4200');

  // Test mobile layout
});
```

### Touch Events

```typescript
test('swipe gesture', async ({ page }) => {
  test.use({ ...devices['iPhone 13'] });

  await page.goto('http://localhost:4200/carousel');

  const carousel = page.locator('[data-testid="carousel"]');
  const box = await carousel.boundingBox();

  if (box) {
    // Swipe left
    await page.mouse.move(box.x + box.width - 10, box.y + box.height / 2);
    await page.mouse.down();
    await page.mouse.move(box.x + 10, box.y + box.height / 2);
    await page.mouse.up();
  }

  // Verify carousel moved
  await expect(carousel).toHaveAttribute('data-slide', '2');
});
```

### Geolocation

```typescript
test('location-based feature', async ({ page, context }) => {
  // Set geolocation to San Francisco
  await context.setGeolocation({
    latitude: 37.7749,
    longitude: -122.4194,
  });

  await context.grantPermissions(['geolocation']);

  await page.goto('http://localhost:4200/nearby');

  await expect(page.locator('[data-testid="location"]')).toContainText('San Francisco');
});
```

## Network Interception

### API Mocking

```typescript
test('mock API response', async ({ page }) => {
  // Mock users endpoint
  await page.route('**/api/users', (route) => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 1, name: 'Test User 1', email: 'test1@example.com' },
        { id: 2, name: 'Test User 2', email: 'test2@example.com' },
      ]),
    });
  });

  await page.goto('http://localhost:4200/users');

  // Verify UI shows mocked data
  await expect(page.locator('[data-testid="user-1"]')).toContainText('Test User 1');
  await expect(page.locator('[data-testid="user-2"]')).toContainText('Test User 2');
});
```

### Request Modification

```typescript
test('modify request headers', async ({ page }) => {
  await page.route('**/api/**', (route) => {
    route.continue({
      headers: {
        ...route.request().headers(),
        Authorization: 'Bearer test-token',
        'X-Custom-Header': 'test-value',
      },
    });
  });

  await page.goto('http://localhost:4200');
});
```

### Network Monitoring

```typescript
test('track API calls', async ({ page }) => {
  const apiCalls: string[] = [];

  page.on('request', (request) => {
    if (request.url().includes('/api/')) {
      apiCalls.push(`${request.method()} ${request.url()}`);
    }
  });

  await page.goto('http://localhost:4200');
  await page.click('[data-testid="load-data"]');

  // Verify expected API calls
  expect(apiCalls).toContain('GET http://localhost:3000/api/data');
});
```

### Offline Testing

```typescript
test('offline mode', async ({ page, context }) => {
  await page.goto('http://localhost:4200');

  // Go offline
  await context.setOffline(true);

  await page.click('[data-testid="load-more"]');

  // Verify offline message
  await expect(page.locator('[data-testid="offline-banner"]')).toBeVisible();

  // Go back online
  await context.setOffline(false);

  await expect(page.locator('[data-testid="offline-banner"]')).toBeHidden();
});
```

## Video Recording

### Enable Video Recording

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    video: 'on', // Options: 'on', 'off', 'retain-on-failure', 'on-first-retry'
    videosPath: 'test-results/videos/',
  },
});
```

### Custom Video Recording

```typescript
test('record specific test', async ({ page }) => {
  // Start recording
  const context = page.context();
  await context.tracing.start({
    screenshots: true,
    snapshots: true,
  });

  await page.goto('http://localhost:4200');
  // ... test actions

  // Stop and save
  await context.tracing.stop({
    path: 'traces/custom-trace.zip',
  });
});
```

### Video in CI/CD

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    video: process.env.CI ? 'retain-on-failure' : 'off',
  },
});
```

## Trace Viewer

### Generate Traces

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    trace: 'on-first-retry', // Options: 'on', 'off', 'retain-on-failure', 'on-first-retry'
  },
});
```

### View Traces

```bash
# View trace file
npx playwright show-trace trace.zip

# Automatically open traces on failure
npx playwright test --trace on
```

### Programmatic Tracing

```typescript
test('custom trace', async ({ page }) => {
  await page.context().tracing.start({
    screenshots: true,
    snapshots: true,
    sources: true,
  });

  try {
    await page.goto('http://localhost:4200');
    // ... test actions
  } finally {
    await page.context().tracing.stop({
      path: `traces/${test.info().title}.zip`,
    });
  }
});
```

## Authentication State

### Save Authentication State

```typescript
// auth.setup.ts
import { test as setup } from '@playwright/test';

setup('authenticate', async ({ page }) => {
  await page.goto('http://localhost:4200/login');
  await page.fill('[data-testid="username"]', 'testuser');
  await page.fill('[data-testid="password"]', 'password123');
  await page.click('[data-testid="submit"]');

  await page.waitForURL('**/dashboard');

  // Save authenticated state
  await page.context().storageState({ path: 'auth.json' });
});
```

### Reuse Authentication

```typescript
// playwright.config.ts
export default defineConfig({
  projects: [
    {
      name: 'setup',
      testMatch: /auth\.setup\.ts/,
    },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'auth.json',
      },
      dependencies: ['setup'],
    },
  ],
});

// All tests are now authenticated
test('authenticated test', async ({ page }) => {
  await page.goto('http://localhost:4200/dashboard');
  // Already logged in!
});
```

## Performance Testing

### Measure Page Load Time

```typescript
test('page load performance', async ({ page }) => {
  await page.goto('http://localhost:4200');

  const metrics = await page.evaluate(() => JSON.stringify(performance.timing));
  const timing = JSON.parse(metrics);

  const loadTime = timing.loadEventEnd - timing.navigationStart;

  console.log(`Page load time: ${loadTime}ms`);
  expect(loadTime).toBeLessThan(3000); // 3 seconds
});
```

### Lighthouse Integration

```typescript
import { playAudit } from 'playwright-lighthouse';

test('lighthouse audit', async ({ page }) => {
  await page.goto('http://localhost:4200');

  await playAudit({
    page,
    thresholds: {
      performance: 80,
      accessibility: 90,
      'best-practices': 85,
      seo: 80,
    },
    port: 9222,
  });
});
```

## Best Practices

- Use visual regression for critical UI components
- Test mobile viewports for responsive designs
- Mock external APIs for consistent tests
- Record videos only on failure in CI
- Use trace viewer for debugging complex failures
- Save/reuse authentication state across tests
- Monitor network requests for debugging
- Test offline scenarios for PWAs
- Implement geolocation testing for location-based features
- Use Lighthouse for performance/accessibility audits
