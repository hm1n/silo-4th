import { createHmac, randomUUID } from "node:crypto";
import { test as base } from "@playwright/test";
import { asc, eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/neon-http";
import { learner, session, unit } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { TEST_SOURCE } from "@/lib/source";
import { unitSections } from "@/lib/unit-sections";

const db = drizzle({ connection: env.DATABASE_URL });

// Google 로그인 화면은 자동화로 통과할 수 없어, Better Auth가 로그인 끝에 남기는 세션 행과 서명 쿠키를 직접 만든다.
function signedSessionCookie(token: string) {
  const signature = createHmac("sha256", env.AUTH_SECRET).update(token).digest("base64");
  return encodeURIComponent(`${token}.${signature}`);
}

export function daysFromNow(days: number) {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

// 시험 날짜와 저장 동의는 한 폼에서 함께 저장하므로, 테스트 학습자도 둘 다 있거나 둘 다 없다.
export const test = base.extend<{ consented: boolean }>({
  consented: [true, { option: true }],
  context: async ({ context, baseURL, consented }, provide) => {
    const [created] = await db
      .insert(learner)
      .values({
        name: "E2E 학습자",
        email: `${randomUUID()}@e2e.test`,
        source: TEST_SOURCE,
        isTest: true,
        ...(consented && { consentedAt: new Date(), examDate: daysFromNow(30) }),
      })
      .returning({ id: learner.id });
    if (!created || !baseURL) throw new Error("E2E 학습자를 만들지 못했다.");

    try {
      const token = randomUUID();
      await db.insert(session).values({
        token,
        userId: created.id,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000),
      });
      await context.addCookies([
        { name: "better-auth.session_token", value: signedSessionCookie(token), url: baseURL },
      ]);
      // 실제 질문 서버는 AI를 부르고, 테스트 학습자에 질문을 남겨 아래에서 학습자를 지우지 못하게 한다.
      // 기본으로는 응답하지 않아 답을 기다리는 상태로 두고, 답을 다루는 테스트가 page.route로 응답을 정한다.
      await context.route("**/api/questions", () => {});

      await provide(context);
    } finally {
      await db.delete(learner).where(eq(learner.id, created.id));
    }
  },
});

export function firstUnits(count: number) {
  return db.select({ title: unit.title }).from(unit).orderBy(asc(unit.id)).limit(count);
}

export async function unitsWithSections() {
  const units = await db.select().from(unit).orderBy(asc(unit.id));
  return units.map(({ id, title, content }) => ({ id, title, sections: unitSections(content) }));
}
