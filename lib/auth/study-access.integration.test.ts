import { eq } from "drizzle-orm";
import { NextRequest } from "next/server";
import { afterEach, describe, expect, it, vi } from "vitest";
import { GET as clearSession } from "@/app/api/session/clear/route";
import { findLearner, requireLearner } from "@/lib/auth";
import { getDb } from "@/lib/db";
import { learner } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { deleteCreatedLearners, learnerWithEmail, loginWithGoogle, newProfile } from "./google-login.testing";

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

afterEach(deleteCreatedLearners);

describe("학습 화면 접근", () => {
  it("TC-19 저장에 동의하지 않은 학습자는 시작 화면으로 보내요", async () => {
    const consented = newProfile();
    const notConsented = newProfile();
    const { headers: consentedHeaders } = await loginWithGoogle(consented);
    const { headers: notConsentedHeaders } = await loginWithGoogle(notConsented);
    await getDb().update(learner).set({ consentedAt: new Date() }).where(eq(learner.email, consented.email));

    request.headers = notConsentedHeaders;
    await expect(requireLearner()).rejects.toThrow("redirect:/start");

    request.headers = consentedHeaders;
    const found = await requireLearner();
    expect(found.id).toBe((await learnerWithEmail(consented.email))?.id);
  });

  it("TC-20 세션 쿠키로 학습자를 찾을 수 있으면 세션 정리 주소를 열어도 로그아웃되지 않아요", async () => {
    const profile = newProfile();
    const { headers } = await loginWithGoogle(profile);

    const response = await clearSession(new NextRequest(`${env.AUTH_URL}/api/session/clear`, { headers }));

    expect(response.status).toBe(307);
    expect(new URL(response.headers.get("location") ?? "").pathname).toBe("/study");
    expect(response.headers.getSetCookie()).toEqual([]);
    expect((await findLearner(headers))?.email).toBe(profile.email);
  });
});
