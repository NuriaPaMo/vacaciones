import { expect, test } from "@playwright/test";
import { DashboardPage } from "../utils/page-objects/DashboardPage";
import { LoginPage } from "../utils/page-objects/LoginPage";

test.describe("User Authentication", () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.goto();
  });

  test("should login successfully with valid credentials", async ({ page }) => {
    // Arrange
    const email = "test.user@example.com";
    const password = "SecurePass123!";

    // Act
    await loginPage.login(email, password);

    // Assert
    await expect(page).toHaveURL("/dashboard");
    await expect(dashboardPage.welcomeMessage).toContainText("Welcome back");
  });

  test("should show error with invalid credentials", async ({ page }) => {
    // Act
    await loginPage.login("user@example.com", "WrongPassword");

    // Assert
    await loginPage.expectErrorMessage("Invalid credentials");
    await expect(page).toHaveURL("/login");
  });

  test("should validate empty fields", async ({ page }) => {
    // Act
    await loginPage.loginButton.click();

    // Assert
    await expect(loginPage.emailInput).toHaveAttribute("aria-invalid", "true");
    await expect(loginPage.passwordInput).toHaveAttribute("aria-invalid", "true");
  });
});
