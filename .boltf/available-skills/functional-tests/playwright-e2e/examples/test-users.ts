import { test as base } from "@playwright/test";

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
      email: "test.user@example.com",
      password: "SecurePass123!",
      name: "Test User",
    };

    // Login before each test
    await page.goto("/login");
    await page.locator('input[name="email"]').fill(user.email);
    await page.locator('input[type="password"]').fill(user.password);
    await page.locator('button[type="submit"]').click();
    await page.waitForURL("/dashboard");

    await use(user);

    // Cleanup: logout
    await page.locator('[aria-label="User menu"]').click();
    await page.locator("text=Logout").click();
  },
});

export { expect } from "@playwright/test";
