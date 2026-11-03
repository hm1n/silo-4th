import { afterEach, describe, expect, it } from "vitest";
import { getAuth } from "@/lib/auth";
import { env } from "@/lib/env";
import { deleteCreatedLearners, learnerWithEmail, loginWithGoogle, newProfile } from "./google-login.testing";

afterEach(deleteCreatedLearners);

describe("학습자 출처", () => {
  it("TC-12 처음 로그인하면 출처와 테스트 여부가 함께 기록돼요", async () => {
    const fromSchool = newProfile();
    const fromTest = newProfile();

    await loginWithGoogle(fromSchool, { source: "school-a" });
    await loginWithGoogle(fromTest, { source: "test" });

    expect(await learnerWithEmail(fromSchool.email)).toMatchObject({ source: "school-a", isTest: false });
    expect(await learnerWithEmail(fromTest.email)).toMatchObject({ source: "test", isTest: true });
  });

  it("TC-13 다시 로그인하면 출처가 달라도 처음 출처를 그대로 둬요", async () => {
    const profile = newProfile();
    await loginWithGoogle(profile, { source: "school-a" });
    const first = await learnerWithEmail(profile.email);

    await loginWithGoogle(profile, { source: "school-b" });

    expect(await learnerWithEmail(profile.email)).toMatchObject({ id: first?.id, source: "school-a" });
  });

  it("TC-14 학습자가 직접 요청을 보내도 출처와 저장 동의 시각은 바뀌지 않아요", async () => {
    const profile = newProfile();
    const { headers } = await loginWithGoogle(profile);
    const before = await learnerWithEmail(profile.email);

    const response = await getAuth().handler(
      new Request(`${env.AUTH_URL}/api/auth/update-user`, {
        method: "POST",
        headers: { cookie: headers.get("cookie") ?? "", "content-type": "application/json", origin: env.AUTH_URL },
        body: JSON.stringify({
          source: "test",
          isTest: true,
          consentedAt: new Date().toISOString(),
          examDate: "2026-12-01",
        }),
      }),
    );

    expect(response.status).toBe(400);
    const after = await learnerWithEmail(profile.email);
    expect(after).toMatchObject({
      source: before?.source,
      isTest: before?.isTest,
      consentedAt: before?.consentedAt,
      examDate: before?.examDate,
    });
    expect(before).toMatchObject({ source: "direct", isTest: false, consentedAt: null });
  });
});
