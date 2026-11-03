import { expect, test } from "@playwright/test";

const SESSION_COOKIE = "better-auth.session_token";

test("TC-17 로그인하지 않고 학습 화면을 열면 첫 화면으로 가요", async ({ page }) => {
  await page.goto("/study");

  await expect(page).toHaveURL("/");
  await expect(page.getByRole("button", { name: "Google로 계속하기" })).toBeVisible();
});

test("TC-18 세션 쿠키로 학습자를 찾을 수 없으면 쿠키를 지우고 첫 화면으로 보내요", async ({ page, context, baseURL }) => {
  await context.addCookies([{ name: SESSION_COOKIE, value: "unknown-session", url: baseURL ?? "" }]);

  await page.goto("/study");

  await expect(page).toHaveURL("/");
  const cookies = await context.cookies();
  expect(cookies.map((cookie) => cookie.name)).not.toContain(SESSION_COOKIE);
});
