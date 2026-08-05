import { expect, test } from "@playwright/test";

test("dashboard layout should match snapshot", async ({ page }) => {
  await page.goto("/dashboard");
  await page.waitForLoadState("networkidle");

  // Take screenshot and compare
  await expect(page).toHaveScreenshot("dashboard.png", {
    fullPage: true,
    maxDiffPixels: 100,
  });
});
