# Local Webapp Testing Guide - Development Workflows & Debugging

## Local Development Setup

### Starting Dev Server Before Tests

Automated dev server management:

```typescript
// test-setup.ts
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function startDevServer(command: string, port: number): Promise<() => void> {
  console.log(`Starting dev server: ${command}`);

  const serverProcess = exec(command, {
    cwd: process.cwd(),
  });

  serverProcess.stdout?.pipe(process.stdout);
  serverProcess.stderr?.pipe(process.stderr);

  // Wait for server to be ready
  await waitForServer(port, 30000);

  console.log(`Dev server ready on port ${port}`);

  // Return cleanup function
  return () => {
    serverProcess.kill();
  };
}

async function waitForServer(port: number, timeout: number): Promise<void> {
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    try {
      const response = await fetch(`http://localhost:${port}`, {
        method: 'HEAD',
      });

      if (response.ok || response.status === 304) {
        return;
      }
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  throw new Error(`Dev server did not start on port ${port} within ${timeout}ms`);
}

// Usage in playwright.config.ts
export default defineConfig({
  webServer: {
    command: 'npm run start',
    port: 4200,
    timeout: 120000,
    reuseExistingServer: !process.env.CI,
  },
});
```

### Multiple Dev Servers

Test with frontend and backend running:

```typescript
export default defineConfig({
  webServer: [
    {
      command: 'npm run start:frontend',
      port: 4200,
      reuseExistingServer: true,
    },
    {
      command: 'npm run start:api',
      port: 3000,
      reuseExistingServer: true,
    },
  ],
});
```

## Hot Reload Integration

### Watching for Changes

```typescript
test('hot reload verification', async ({ page }) => {
  await page.goto('http://localhost:4200');

  // Initial state
  const heading = page.locator('h1');
  await expect(heading).toHaveText('Welcome');

  // Simulate file change (in actual workflow, developer edits file)
  // Wait for hot reload
  await page.waitForFunction(
    () => {
      return document.querySelector('h1')?.textContent !== 'Welcome';
    },
    { timeout: 10000 }
  );

  // Verify updated content
  await expect(heading).not.toHaveText('Welcome');
});
```

### Network Idle After HMR

```typescript
async function waitForHMR(page: Page): Promise<void> {
  // Wait for Hot Module Replacement to complete
  await page.waitForLoadState('networkidle');

  // Additional wait for framework-specific HMR
  await page.waitForTimeout(500);
}

test('test after code change', async ({ page }) => {
  await page.goto('http://localhost:4200');

  // Make code change...
  await waitForHMR(page);

  // Continue testing with updated code
  const component = page.locator('[data-testid="updated-component"]');
  await expect(component).toBeVisible();
});
```

## Console Log Inspection

### Comprehensive Log Capture

```typescript
interface ConsoleMessage {
  type: string;
  text: string;
  location: string;
  timestamp: Date;
}

class ConsoleLogger {
  private logs: ConsoleMessage[] = [];

  attach(page: Page): void {
    page.on('console', (msg) => {
      this.logs.push({
        type: msg.type(),
        text: msg.text(),
        location: msg.location().url || 'unknown',
        timestamp: new Date(),
      });
    });
  }

  getErrors(): ConsoleMessage[] {
    return this.logs.filter((log) => log.type === 'error');
  }

  getWarnings(): ConsoleMessage[] {
    return this.logs.filter((log) => log.type === 'warning');
  }

  getAllLogs(): ConsoleMessage[] {
    return this.logs;
  }

  clear(): void {
    this.logs = [];
  }

  printSummary(): void {
    console.log('\n=== Console Summary ===');
    console.log(`Total messages: ${this.logs.length}`);
    console.log(`Errors: ${this.getErrors().length}`);
    console.log(`Warnings: ${this.getWarnings().length}`);

    if (this.getErrors().length > 0) {
      console.log('\nErrors:');
      this.getErrors().forEach((err) => {
        console.log(`  [${err.timestamp.toISOString()}] ${err.text}`);
      });
    }
  }
}

// Usage
test('capture console logs', async ({ page }) => {
  const logger = new ConsoleLogger();
  logger.attach(page);

  await page.goto('http://localhost:4200');

  // Interact with page
  await page.click('[data-testid="trigger-error"]');

  // Check for errors
  const errors = logger.getErrors();
  expect(errors).toHaveLength(0);

  logger.printSummary();
});
```

### Network Error Detection

```typescript
class NetworkMonitor {
  private failedRequests: any[] = [];

  attach(page: Page): void {
    page.on('requestfailed', (request) => {
      this.failedRequests.push({
        url: request.url(),
        method: request.method(),
        failure: request.failure()?.errorText,
        timestamp: new Date(),
      });
    });
  }

  getFailedAPICalls(): any[] {
    return this.failedRequests.filter((req) => req.url.includes('/api/'));
  }

  assertNoFailures(): void {
    if (this.failedRequests.length > 0) {
      throw new Error(
        `Found ${this.failedRequests.length} failed requests:\n` +
          this.failedRequests.map((r) => `  - ${r.method} ${r.url}: ${r.failure}`).join('\n')
      );
    }
  }
}

test('monitor network', async ({ page }) => {
  const monitor = new NetworkMonitor();
  monitor.attach(page);

  await page.goto('http://localhost:4200');

  // Verify no failed requests
  monitor.assertNoFailures();
});
```

## Screenshot Debugging

### Automatic Screenshot on Failure

```typescript
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== 'passed') {
    const screenshot = await page.screenshot({ fullPage: true });
    await testInfo.attach('failure-screenshot', {
      body: screenshot,
      contentType: 'image/png',
    });
  }
});
```

### Progressive Screenshot Capture

```typescript
class ScreenshotDebugger {
  private stepCount = 0;

  async captureStep(page: Page, description: string): Promise<void> {
    this.stepCount++;
    const filename = `step-${this.stepCount.toString().padStart(2, '0')}-${description.replace(/\s+/g, '-')}.png`;

    await page.screenshot({
      path: `debug-screenshots/${filename}`,
      fullPage: true
    });

    console.log(`📸 Screenshot saved: ${filename}`);
  }
}

test('debug workflow', async ({ page }) => {
  const debugger = new ScreenshotDebugger();

  await page.goto('http://localhost:4200');
  await debugger.captureStep(page, 'initial-load');

  await page.click('[data-testid="open-modal"]');
  await debugger.captureStep(page, 'modal-opened');

  await page.fill('[data-testid="input"]', 'test data');
  await debugger.captureStep(page, 'form-filled');

  await page.click('[data-testid="submit"]');
  await debugger.captureStep(page, 'form-submitted');
});
```

### Element-Specific Screenshots

```typescript
async function screenshotElement(page: Page, selector: string, filename: string): Promise<void> {
  const element = page.locator(selector);
  await element.waitFor({ state: 'visible' });

  await element.screenshot({
    path: `screenshots/${filename}`,
    animations: 'disabled', // Remove CSS animations
  });
}

test('component screenshots', async ({ page }) => {
  await page.goto('http://localhost:4200');

  await screenshotElement(page, '[data-testid="header"]', 'header-component.png');
  await screenshotElement(page, '[data-testid="sidebar"]', 'sidebar-component.png');
  await screenshotElement(page, '[data-testid="footer"]', 'footer-component.png');
});
```

## Form Testing Patterns

### Complete Form Validation

```typescript
interface FormField {
  selector: string;
  value: string;
  label?: string;
}

async function fillForm(page: Page, fields: FormField[]): Promise<void> {
  for (const field of fields) {
    await page.fill(field.selector, field.value);

    // Verify value was set
    const actualValue = await page.inputValue(field.selector);
    if (actualValue !== field.value) {
      throw new Error(
        `Form field ${field.label || field.selector} validation failed. ` +
          `Expected: "${field.value}", Got: "${actualValue}"`
      );
    }
  }
}

test('registration form', async ({ page }) => {
  await page.goto('http://localhost:4200/register');

  await fillForm(page, [
    { selector: '[data-testid="first-name"]', value: 'John', label: 'First Name' },
    { selector: '[data-testid="last-name"]', value: 'Doe', label: 'Last Name' },
    { selector: '[data-testid="email"]', value: 'john@example.com', label: 'Email' },
    { selector: '[data-testid="password"]', value: 'SecurePass123!', label: 'Password' },
  ]);

  await page.click('[data-testid="submit"]');
  await expect(page).toHaveURL(/dashboard/);
});
```

### Form Error Validation

```typescript
test('form validation errors', async ({ page }) => {
  await page.goto('http://localhost:4200/register');

  // Submit empty form
  await page.click('[data-testid="submit"]');

  // Check required field errors
  const errors = page.locator('[role="alert"]');
  await expect(errors).toHaveCount(4); // 4 required fields

  // Verify specific error messages
  await expect(page.locator('[data-testid="email-error"]')).toContainText('Email is required');

  // Fill invalid email
  await page.fill('[data-testid="email"]', 'invalid-email');
  await page.click('[data-testid="submit"]');

  await expect(page.locator('[data-testid="email-error"]')).toContainText(
    'Please enter a valid email address'
  );
});
```

## Responsive Design Testing

### Viewport Testing Matrix

```typescript
const viewports = [
  { name: 'Mobile S', width: 320, height: 568 },
  { name: 'Mobile M', width: 375, height: 667 },
  { name: 'Mobile L', width: 425, height: 812 },
  { name: 'Tablet', width: 768, height: 1024 },
  { name: 'Laptop', width: 1024, height: 768 },
  { name: 'Laptop L', width: 1440, height: 900 },
  { name: 'Desktop 4K', width: 2560, height: 1440 },
];

for (const viewport of viewports) {
  test(`responsive layout on ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize({
      width: viewport.width,
      height: viewport.height,
    });

    await page.goto('http://localhost:4200');

    // Verify responsive elements
    const mobileMenu = page.locator('[data-testid="mobile-menu"]');
    const desktopMenu = page.locator('[data-testid="desktop-menu"]');

    if (viewport.width < 768) {
      await expect(mobileMenu).toBeVisible();
      await expect(desktopMenu).toBeHidden();
    } else {
      await expect(desktopMenu).toBeVisible();
      await expect(mobileMenu).toBeHidden();
    }

    // Capture screenshot
    await page.screenshot({
      path: `screenshots/responsive-${viewport.name}.png`,
      fullPage: true,
    });
  });
}
```

## Performance Monitoring

### Page Load Metrics

```typescript
test('page load performance', async ({ page }) => {
  await page.goto('http://localhost:4200');

  const metrics = await page.evaluate(() => {
    const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;

    return {
      domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
      loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
      firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime || 0,
      firstContentfulPaint:
        performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
    };
  });

  console.log('Performance Metrics:', metrics);

  // Assert performance thresholds
  expect(metrics.domContentLoaded).toBeLessThan(2000); // 2s
  expect(metrics.firstContentfulPaint).toBeLessThan(1000); // 1s
});
```

## Best Practices

- Start dev server automatically with `webServer` config
- Monitor console logs and network errors during tests
- Capture progressive screenshots for debugging complex workflows
- Test forms comprehensively including validation errors
- Verify responsive layouts across multiple viewports
- Monitor page load performance metrics
- Use element-specific screenshots for component documentation
- Integrate with Hot Module Replacement for efficient testing
