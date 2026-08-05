---
name: playwright-e2e
description: >
  Playwright E2E testing patterns: Page Object Model, locators, assertions, visual regression,
  accessibility, and CI setup. For database reset between tests and Playwright tag taxonomy
  (@smoke, @regression, @integration) see the integration-e2e-testing skill.
---

# Playwright E2E Testing

> 🔗 Database reset, tag taxonomy, worker isolation → [`integration-e2e-testing`](../integration-e2e-testing/SKILL.md)  
> 🔗 xUnit unit + architecture tests → [`backend-testing-dotnet`](../backend-testing-dotnet/SKILL.md)

## Quick Start

```bash
npm install -D @playwright/test
npx playwright install
npx playwright test
```

## Examples

| Example | What it shows |
| ------- | ------------- |
| [playwright.config.ts](examples/playwright.config.ts) | Parallel execution, retries, multi-browser, HTML/JUnit/JSON reporters |
| [LoginPage.ts](examples/LoginPage.ts) | Page Object Model — encapsulate page actions and locators |
| [login.spec.ts](examples/login.spec.ts) | AAA structure, POM usage, `beforeEach`, happy path + error cases |
| [api-mocking.spec.ts](examples/api-mocking.spec.ts) | `page.route()` for isolated tests without live backend |
| [test-users.ts](examples/test-users.ts) | Playwright fixtures for auth state, setup/teardown, composition |
| [visual-regression.spec.ts](examples/visual-regression.spec.ts) | `toHaveScreenshot()`, cross-browser pixel diff |
| [accessibility.spec.ts](examples/accessibility.spec.ts) | `@axe-core/playwright` WCAG validation |
| [LoginTests.cs](examples/LoginTests.cs) | Playwright for .NET (xUnit + async/await) |
| [e2e-tests.yml](examples/e2e-tests.yml) | GitHub Actions CI — install, run, upload report artefacts |

**Extra installs**: `npm install -D @axe-core/playwright` (accessibility)  
**For .NET**: `dotnet add package Microsoft.Playwright.NUnit` + `pwsh bin/Debug/net8.0/playwright.ps1 install`

## Running Tests

```bash
npx playwright test                  # all
npx playwright test login.spec.ts    # specific file
npx playwright test --headed         # watch browser
npx playwright test --project=chromium
npx playwright test --debug
npx playwright test --grep @smoke    # filter by tag
npx playwright show-report
npx playwright test --update-snapshots

# .NET
dotnet test --filter "FullyQualifiedName~Login"
```

## E2E Testing with Aspire

Full guide: [AGENT-GUIDE.md](examples/AGENT-GUIDE.md) · [ASPIRE-E2E-FLOW.md](examples/ASPIRE-E2E-FLOW.md)

**Agent responsibility — in order:**

1. Start — `aspire run --project src/backend/AppHost/Peritec.AppHost.csproj`
2. Wait via Aspire MCP tools until ALL services are `Running` & `Healthy`
3. Run `npx playwright test` — Playwright has **no** Aspire wait logic
4. Stop Aspire in `finally`

Playwright config for Aspire (no `webServer`):

```typescript
export default defineConfig({
  use: { baseURL: process.env.FRONTEND_URL ?? "http://localhost:4200", actionTimeout: 15_000 },
});
```

Database reset + tag taxonomy → [`integration-e2e-testing`](../integration-e2e-testing/SKILL.md)

## Best Practices

**Locators** — role › label › test-id; avoid CSS tied to implementation; avoid XPath  
**Assertions** — use auto-waiting (`expect(locator).toBeVisible()`); never `sleep()`  
**Structure** — one user journey per file; Page Objects for reuse; independent tests; no shared state  
**Performance** — parallel workers; screenshots/videos only on failure; mock external deps

## Integration with CI/CD

See → [examples/e2e-tests.yml](examples/e2e-tests.yml)

## References

- [Playwright Documentation](https://playwright.dev/) · [for .NET](https://playwright.dev/dotnet/) · [Best Practices](https://playwright.dev/docs/best-practices)
- [`integration-e2e-testing`](../integration-e2e-testing/SKILL.md) — DB reset, tag taxonomy, worker setup
- [`backend-testing-dotnet`](../backend-testing-dotnet/SKILL.md) — xUnit unit + architecture tests
