import { expect, test } from "@playwright/test";

test("should handle API errors gracefully", async ({ page }) => {
  // Mock API to return error
  await page.route("**/api/time-entries", (route) => {
    route.fulfill({
      status: 500,
      contentType: "application/json",
      body: JSON.stringify({ error: "Internal Server Error" }),
    });
  });

  await page.goto("/time-tracking");
  await page.locator('button:has-text("New Entry")').click();

  // Fill form
  await page.locator('input[name="hours"]').fill("2");
  await page.locator('button[type="submit"]').click();

  // Verify error handling
  await expect(page.locator('[role="alert"]')).toContainText("Failed to create entry");
});
