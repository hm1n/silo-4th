import { eq } from "drizzle-orm";
import { afterEach, describe, expect, it, vi } from "vitest";
import { deleteCreatedLearners, learnerWithEmail, loginWithGoogle, newProfile } from "@/lib/auth/google-login.testing";
import { getDb } from "@/lib/db";
import { learner } from "@/lib/db/schema";
import { submitStart } from "./actions";

const request = vi.hoisted(() => ({ headers: new Headers() }));

vi.mock("next/headers", () => ({
  headers: async () => request.headers,
  cookies: async () => ({ set: () => undefined }),
}));
vi.mock("next/navigation", () => ({
  redirect: (url: string) => {
    throw new Error(`redirect:${url}`);
  },
}));

afterEach(async () => {
  vi.useRealTimers();
  await deleteCreatedLearners();
});

function startForm({ examDate, consent }: { examDate: string; consent: boolean }) {
  const form = new FormData();
  form.set("examDate", examDate);
  if (consent) form.set("consent", "on");
  return form;
}

function daysFromNow(days: number) {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

async function savedStart(email: string) {
  const found = await learnerWithEmail(email);
  return { examDate: found?.examDate, consentedAt: found?.consentedAt };
}

describe("시작 화면 서버 액션", () => {
  it("TC-25 시험 날짜와 저장 동의를 내면 학습자에 저장되고 학습 화면으로 가요", async () => {
    const a = newProfile();
    const b = newProfile();
    const { headers } = await loginWithGoogle(a);
    await loginWithGoogle(b);
    const bBefore = await savedStart(b.email);
    // 케이스의 시험 날짜가 실행하는 날에도 오늘 이후가 되도록 현재 시각을 케이스를 정한 날로 고정한다.
    vi.useFakeTimers({ toFake: ["Date"], now: new Date("2026-11-03T03:00:00Z") });
    request.headers = headers;

    const before = new Date();
    await expect(submitStart(null, startForm({ examDate: "2026-12-01", consent: true }))).rejects.toThrow(
      "redirect:/study",
    );
    const after = new Date();

    const saved = await savedStart(a.email);
    expect(saved.examDate).toBe("2026-12-01");
    expect(saved.consentedAt?.getTime()).toBeGreaterThanOrEqual(before.getTime());
    expect(saved.consentedAt?.getTime()).toBeLessThanOrEqual(after.getTime());
    expect(await savedStart(b.email)).toEqual(bBefore);
  });

  it("TC-26 시험 날짜와 저장 동의 제출이 조건에 맞지 않으면 요청을 거절해요", async () => {
    const profile = newProfile();
    const { headers } = await loginWithGoogle(profile);
    const before = await savedStart(profile.email);

    request.headers = headers;
    const withoutConsent = await submitStart(null, startForm({ examDate: daysFromNow(30), consent: false }));
    expect(withoutConsent?.notice).toBeTruthy();

    const pastDate = await submitStart(null, startForm({ examDate: "2020-01-01", consent: true }));
    expect(pastDate?.notice).toBeTruthy();

    request.headers = new Headers();
    await expect(submitStart(null, startForm({ examDate: daysFromNow(30), consent: true }))).rejects.toThrow(
      /^redirect:\/$/,
    );

    expect(await savedStart(profile.email)).toEqual(before);
  });

  it("TC-33 시험 날짜와 저장 동의를 이미 낸 학습자가 직접 요청을 보내도 처음 값을 유지해요", async () => {
    const profile = newProfile();
    const { headers } = await loginWithGoogle(profile);
    await getDb()
      .update(learner)
      .set({ examDate: daysFromNow(30), consentedAt: new Date("2026-11-01T00:00:00Z") })
      .where(eq(learner.email, profile.email));
    const before = await savedStart(profile.email);

    request.headers = headers;
    await expect(submitStart(null, startForm({ examDate: daysFromNow(60), consent: true }))).rejects.toThrow(
      "redirect:/study",
    );

    expect(await savedStart(profile.email)).toEqual(before);
  });
});
