import { captureMessage } from "@sentry/nextjs";
import { eq } from "drizzle-orm";
import { afterEach, describe, expect, it, vi } from "vitest";
import { findLearner, getAuth } from "@/lib/auth";
import { getDb } from "@/lib/db";
import { account, learner, session } from "@/lib/db/schema";
import { deleteCreatedLearners, loginWithGoogle, newProfile } from "./google-login.testing";

vi.mock("@sentry/nextjs", () => ({ captureMessage: vi.fn() }));

function learnersWithEmail(email: string) {
  return getDb().select().from(learner).where(eq(learner.email, email));
}

afterEach(async () => {
  vi.restoreAllMocks();
  vi.clearAllMocks();
  await deleteCreatedLearners();
});

describe("현재 학습자", () => {
  it("TC-1 로그아웃하면 학습자가 없어요", async () => {
    const { headers } = await loginWithGoogle(newProfile());

    await getAuth().api.signOut({ headers });

    expect(await findLearner(headers)).toBeNull();
  });

  it("TC-2 로그인하지 않으면 학습자가 없어요", async () => {
    expect(await findLearner(new Headers())).toBeNull();
  });

  it("TC-3 로그인이 풀리면 학습자가 없어요", async () => {
    const profile = newProfile();
    const { headers } = await loginWithGoogle(profile);
    const [loggedIn] = await learnersWithEmail(profile.email);
    await getDb()
      .update(session)
      .set({ expiresAt: new Date(Date.now() - 60_000) })
      .where(eq(session.userId, loggedIn!.id));

    expect(await findLearner(headers)).toBeNull();
  });

  it("TC-5 로그인한 학습자를 정확히 찾아요", async () => {
    const first = newProfile();
    const second = newProfile();
    const firstLogin = await loginWithGoogle(first);
    await loginWithGoogle(second);
    const [expected] = await learnersWithEmail(first.email);

    const found = await findLearner(firstLogin.headers);

    expect(found?.id).toBe(expected!.id);
    expect(found?.email).toBe(first.email);
  });
});

describe("Google 로그인", () => {
  it("TC-8 처음 로그인하면 새 학습자가 생겨요", async () => {
    const profile = newProfile();

    await loginWithGoogle(profile);

    const learners = await learnersWithEmail(profile.email);
    expect(learners).toHaveLength(1);
    const accounts = await getDb()
      .select()
      .from(account)
      .where(eq(account.userId, learners[0]!.id));
    expect(accounts).toEqual([
      expect.objectContaining({ providerId: "google", accountId: profile.sub }),
    ]);
  });

  it("TC-9 다시 로그인하면 원래 학습자로 이어져요", async () => {
    const profile = newProfile();
    const firstLogin = await loginWithGoogle(profile);
    const firstLearner = await findLearner(firstLogin.headers);

    const secondLogin = await loginWithGoogle(profile);

    expect((await findLearner(secondLogin.headers))?.id).toBe(firstLearner?.id);
    const learners = await learnersWithEmail(profile.email);
    expect(learners).toHaveLength(1);
    const accounts = await getDb()
      .select()
      .from(account)
      .where(eq(account.userId, learners[0]!.id));
    expect(accounts).toHaveLength(1);
  });

  it("TC-11 오류 기록에 개인 정보를 남기지 않아요", async () => {
    // Postgres는 텍스트에 NUL 문자를 받지 않아, 학습자 저장이 이름과 이메일을 담은 DB 오류로 실패한다.
    const profile = newProfile("유출금지이름\u0000");

    const { callback } = await loginWithGoogle(profile);

    expect(callback.headers.get("location")).toContain("error=");
    expect(captureMessage).toHaveBeenCalled();
    const recorded = JSON.stringify(vi.mocked(captureMessage).mock.calls);
    expect(recorded).not.toContain(profile.email);
    expect(recorded).not.toContain("유출금지이름");
  });
});
