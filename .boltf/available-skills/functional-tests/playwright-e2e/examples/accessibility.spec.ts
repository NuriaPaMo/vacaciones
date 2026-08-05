import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("login page should have no accessibility violations", async ({ page }) => {
  await page.goto("/login");

  const accessibilityScanResults = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();

  expect(accessibilityScanResults.violations).toEqual([]);
});
