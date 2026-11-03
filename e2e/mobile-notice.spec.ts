import { devices, expect, test } from "@playwright/test";

test.use(devices["Pixel 7"]);

test("TC-22 모바일로 서비스에 들어오면 PC 안내 화면이 보여요", async ({ page }) => {
  await page.goto("/?from=school-a");

  await expect(page).toHaveURL("/?from=school-a");
  await expect(page.getByRole("heading", { name: /PC에서/ })).toBeVisible();
});
