# Browser Automation Patterns - Advanced Helpers & Utilities

## Dev Server Detection Algorithms

### Multi-Port Scanner

Detect running development servers across common frameworks:

```typescript
interface DevServer {
  port: number;
  url: string;
  framework?: string;
  responsive: boolean;
}

async function detectDevServers(): Promise<DevServer[]> {
  const commonPorts = [
    { port: 3000, framework: 'React/Next.js' },
    { port: 4200, framework: 'Angular' },
    { port: 5173, framework: 'Vite' },
    { port: 8080, framework: 'Webpack Dev Server' },
    { port: 8081, framework: 'Metro (React Native)' },
    { port: 5000, framework: 'Flask/ASP.NET' },
    { port: 3001, framework: 'Custom' },
    { port: 4000, framework: 'GraphQL' },
  ];

  const servers: DevServer[] = [];

  for (const { port, framework } of commonPorts) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);

      const response = await fetch(`http://localhost:${port}`, {
        signal: controller.signal,
        method: 'HEAD',
      });

      clearTimeout(timeoutId);

      if (response.ok || response.status === 304) {
        servers.push({
          port,
          url: `http://localhost:${port}`,
          framework,
          responsive: true,
        });
      }
    } catch (error) {
      // Port not available or timeout
    }
  }

  return servers;
}

// Usage
const servers = await detectDevServers();
if (servers.length === 0) {
  throw new Error('No development servers detected. Start your dev server first.');
}

console.log(`Found ${servers.length} dev server(s):`);
servers.forEach((s) => console.log(`  - ${s.url} (${s.framework})`));

await page.goto(servers[0].url);
```

### Process Detection

Detect servers by checking running processes:

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function detectServerByProcess(): Promise<string | null> {
  try {
    // Windows
    if (process.platform === 'win32') {
      const { stdout } = await execAsync('netstat -ano | findstr LISTENING');
      const lines = stdout.split('\n');

      for (const line of lines) {
        if (line.includes(':4200') || line.includes(':3000')) {
          const port = line.match(/:(\d+)/)?.[1];
          return port ? `http://localhost:${port}` : null;
        }
      }
    }

    // macOS/Linux
    else {
      const { stdout } = await execAsync('lsof -i -P | grep LISTEN');
      const lines = stdout.split('\n');

      for (const line of lines) {
        if (line.includes('*:4200') || line.includes('*:3000')) {
          const port = line.match(/\*:(\d+)/)?.[1];
          return port ? `http://localhost:${port}` : null;
        }
      }
    }
  } catch (error) {
    console.error('Error detecting server process:', error);
  }

  return null;
}
```

## Advanced Interaction Helpers

### Safe Click with Retry

Robust clicking with multiple fallback strategies:

```typescript
async function safeClick(
  page: Page,
  selector: string,
  options: {
    timeout?: number;
    retries?: number;
    scrollIntoView?: boolean;
    force?: boolean;
  } = {}
): Promise<void> {
  const { timeout = 5000, retries = 3, scrollIntoView = true, force = false } = options;

  let lastError: Error | undefined;

  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const element = page.locator(selector);

      // Wait for element
      await element.waitFor({ state: 'visible', timeout });

      // Scroll into view
      if (scrollIntoView) {
        await element.scrollIntoViewIfNeeded();
      }

      // Try regular click
      if (!force) {
        await element.click({ timeout });
      } else {
        await element.click({ force: true, timeout });
      }

      return; // Success
    } catch (error) {
      lastError = error as Error;

      // Wait before retry
      if (attempt < retries - 1) {
        await page.waitForTimeout(500 * (attempt + 1));
      }
    }
  }

  throw new Error(
    `Failed to click element "${selector}" after ${retries} attempts. ` +
      `Last error: ${lastError?.message}`
  );
}
```

### Safe Type with Clear

Enhanced text input with validation:

```typescript
async function safeType(
  page: Page,
  selector: string,
  text: string,
  options: {
    timeout?: number;
    clearFirst?: boolean;
    pressEnter?: boolean;
    delay?: number;
    verify?: boolean;
  } = {}
): Promise<void> {
  const {
    timeout = 5000,
    clearFirst = true,
    pressEnter = false,
    delay = 0,
    verify = true,
  } = options;

  const element = page.locator(selector);

  // Wait for element
  await element.waitFor({ state: 'visible', timeout });

  // Clear existing text
  if (clearFirst) {
    await element.clear();
  }

  // Type text
  await element.fill(text, { timeout });

  // Optional: Type character by character with delay
  if (delay > 0) {
    await element.clear();
    await element.type(text, { delay });
  }

  // Verify text was entered
  if (verify) {
    const value = await element.inputValue();
    if (value !== text) {
      throw new Error(
        `Text verification failed for "${selector}". ` + `Expected: "${text}", Got: "${value}"`
      );
    }
  }

  // Optional: Press Enter
  if (pressEnter) {
    await element.press('Enter');
  }
}
```

### Wait for Stable Element

Wait for element to stop moving (useful for animations):

```typescript
async function waitForStableElement(
  page: Page,
  selector: string,
  options: {
    timeout?: number;
    stableFor?: number;
  } = {}
): Promise<void> {
  const { timeout = 10000, stableFor = 500 } = options;

  const element = page.locator(selector);
  const startTime = Date.now();

  let previousBox = await element.boundingBox();
  let stableStartTime = Date.now();

  while (Date.now() - startTime < timeout) {
    await page.waitForTimeout(100);

    const currentBox = await element.boundingBox();

    if (!currentBox || !previousBox) {
      previousBox = currentBox;
      stableStartTime = Date.now();
      continue;
    }

    // Check if position/size changed
    const changed =
      currentBox.x !== previousBox.x ||
      currentBox.y !== previousBox.y ||
      currentBox.width !== previousBox.width ||
      currentBox.height !== previousBox.height;

    if (changed) {
      stableStartTime = Date.now();
      previousBox = currentBox;
    } else if (Date.now() - stableStartTime >= stableFor) {
      return; // Element is stable
    }
  }

  throw new Error(`Element "${selector}" did not stabilize within ${timeout}ms`);
}
```

## Custom HTTP Headers

### Environment-Based Headers

```typescript
interface CustomHeaders {
  [key: string]: string;
}

function getTestHeaders(): CustomHeaders {
  return {
    'X-Test-Run': 'true',
    'X-Test-User': process.env.TEST_USER || 'automation',
    'X-Test-Environment': process.env.TEST_ENV || 'local',
    'X-Build-ID': process.env.BUILD_ID || 'local-build',
    'X-Custom-Feature-Flag': process.env.FEATURE_FLAG || '',
  };
}

// Apply to all requests
test('with custom headers', async ({ page }) => {
  await page.setExtraHTTPHeaders(getTestHeaders());
  await page.goto('http://localhost:4200');
});

// Apply to specific request
test('selective headers', async ({ page }) => {
  await page.route('**/api/**', (route) => {
    route.continue({
      headers: {
        ...route.request().headers(),
        ...getTestHeaders(),
      },
    });
  });

  await page.goto('http://localhost:4200');
});
```

### Authentication Headers

```typescript
async function setAuthHeaders(page: Page, token: string) {
  await page.setExtraHTTPHeaders({
    Authorization: `Bearer ${token}`,
    'X-API-Key': process.env.API_KEY || '',
  });
}

// Usage
test('authenticated request', async ({ page }) => {
  const token = await getAuthToken();
  await setAuthHeaders(page, token);
  await page.goto('http://localhost:4200/dashboard');
});
```

## /tmp Script Pattern

### Inline Script Execution

Execute temporary scripts without creating files:

```typescript
async function executeTmpScript(page: Page, script: string): Promise<any> {
  return await page.evaluate((scriptContent) => {
    // Execute script in browser context
    const fn = new Function(scriptContent);
    return fn();
  }, script);
}

// Usage
test('tmp script execution', async ({ page }) => {
  await page.goto('http://localhost:4200');

  const result = await executeTmpScript(
    page,
    `
    // Extract all link URLs
    return Array.from(document.querySelectorAll('a'))
      .map(a => a.href)
      .filter(href => href.startsWith('http'));
  `
  );

  console.log('Found links:', result);
});
```

### Dynamic Script Injection

```typescript
async function injectHelperScript(page: Page) {
  await page.addInitScript(() => {
    // Add helper functions to window object
    (window as any).testHelpers = {
      getFormData: (formSelector: string) => {
        const form = document.querySelector(formSelector) as HTMLFormElement;
        if (!form) return null;

        const formData = new FormData(form);
        const data: Record<string, any> = {};

        formData.forEach((value, key) => {
          data[key] = value;
        });

        return data;
      },

      getAllErrors: () => {
        return Array.from(document.querySelectorAll('[role="alert"], .error'))
          .map((el) => el.textContent?.trim())
          .filter(Boolean);
      },

      simulateHover: (selector: string) => {
        const element = document.querySelector(selector);
        if (element) {
          element.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
        }
      },
    };
  });
}

// Usage
test('with helper script', async ({ page }) => {
  await injectHelperScript(page);
  await page.goto('http://localhost:4200');

  // Use injected helpers
  const formData = await page.evaluate(() => {
    return (window as any).testHelpers.getFormData('#login-form');
  });

  console.log('Form data:', formData);
});
```

## Cookie Banner Handling

```typescript
async function dismissCookieBanner(page: Page): Promise<void> {
  const cookieSelectors = [
    '[data-testid="cookie-accept"]',
    '[aria-label="Accept cookies"]',
    '#onetrust-accept-btn-handler',
    '.cookie-consent-accept',
    'button:has-text("Accept")',
    'button:has-text("I agree")',
  ];

  for (const selector of cookieSelectors) {
    try {
      const button = page.locator(selector);
      if (await button.isVisible({ timeout: 1000 })) {
        await button.click();
        return;
      }
    } catch {
      // Try next selector
    }
  }
}
```

## Table Data Extraction

```typescript
async function extractTableData(page: Page, tableSelector: string): Promise<any[]> {
  return await page.evaluate((selector) => {
    const table = document.querySelector(selector) as HTMLTableElement;
    if (!table) return [];

    const headers = Array.from(table.querySelectorAll('thead th')).map(
      (th) => th.textContent?.trim() || ''
    );

    const rows = Array.from(table.querySelectorAll('tbody tr'));

    return rows.map((row) => {
      const cells = Array.from(row.querySelectorAll('td'));
      const rowData: Record<string, string> = {};

      cells.forEach((cell, index) => {
        const header = headers[index] || `column_${index}`;
        rowData[header] = cell.textContent?.trim() || '';
      });

      return rowData;
    });
  }, tableSelector);
}

// Usage
test('extract table', async ({ page }) => {
  await page.goto('http://localhost:4200/users');
  const userData = await extractTableData(page, '[data-testid="user-table"]');
  console.log('Users:', userData);
});
```

## Best Practices

- Use auto-detect helpers for flexible local testing
- Implement retry logic for flaky operations
- Verify text input after typing
- Wait for animations to complete before interaction
- Use custom headers for environment identification
- Inject helper scripts for complex DOM operations
- Handle cookie banners automatically
- Extract structured data from tables efficiently
