import { expect, type Page, test as guest } from "@playwright/test";
import { daysFromNow, test } from "./fixtures";

const CONSENT_NOTICE = "기록을 저장해야 학습을 이어 갈 수 있어요";

function onStudy(url: URL) {
  return url.pathname === "/study" || url.pathname.startsWith("/study/");
}

function startScreen(page: Page) {
  return {
    examDate: page.getByLabel("시험 날짜"),
    consent: page.getByRole("checkbox"),
    submit: page.getByRole("button", { name: "시작하기" }),
    // Next.js의 경로 안내 영역도 alert라서 문구로 고른다.
    consentNotice: page.getByRole("alert").filter({ hasText: CONSENT_NOTICE }),
  };
}

test.describe("저장에 동의하지 않은 학습자", () => {
  test.use({ consented: false });

  test("TC-28 시작 화면에서 시험 날짜를 고르고 저장에 동의해야 학습 화면으로 넘어가요", async ({ page }) => {
    const screen = startScreen(page);

    await page.goto("/start");
    await screen.examDate.fill(daysFromNow(30));
    await screen.submit.click();

    await expect(screen.consentNotice).toBeVisible();
    await expect(page).toHaveURL("/start");

    await screen.consent.check();
    await screen.submit.click();

    await expect(page).toHaveURL(onStudy);
  });

  test("TC-29 저장에 동의하지 않으면 안내가 보이고 시작 화면에 머물러요", async ({ page }) => {
    const screen = startScreen(page);

    await page.goto("/start");
    await screen.examDate.fill(daysFromNow(30));
    await screen.submit.click();

    await expect(screen.consentNotice).toBeVisible();
    await expect(page).toHaveURL("/start");
  });
});

guest("TC-30 로그인하지 않고 시작 화면을 열면 첫 화면으로 가요", async ({ page }) => {
  await page.goto("/start");

  await expect(page).toHaveURL("/");
});

test("TC-31 시험 날짜와 저장 동의를 이미 낸 학습자는 첫 화면과 시작 화면을 건너뛰고 학습 화면으로 가요", async ({
  page,
}) => {
  await page.goto("/");
  await expect(page).toHaveURL(onStudy);

  await page.goto("/start");
  await expect(page).toHaveURL(onStudy);
});
