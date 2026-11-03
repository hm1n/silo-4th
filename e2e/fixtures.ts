import { createHmac, randomUUID } from "node:crypto";
import { test as base } from "@playwright/test";
import { asc, eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/neon-http";
import { learner, session, unit } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { TEST_SOURCE } from "@/lib/source";

const db = drizzle({ connection: env.DATABASE_URL });

// Google 로그인 화면은 자동화로 통과할 수 없어, Better Auth가 로그인 끝에 남기는 세션 행과 서명 쿠키를 직접 만든다.
function signedSessionCookie(token: string) {
  const signature = createHmac("sha256", env.AUTH_SECRET).update(token).digest("base64");
  return encodeURIComponent(`${token}.${signature}`);
}

export const test = base.extend({
  context: async ({ context, baseURL }, provide) => {
    const [created] = await db
      .insert(learner)
      .values({
        name: "E2E 학습자",
        email: `${randomUUID()}@e2e.test`,
        source: TEST_SOURCE,
        isTest: true,
        consentedAt: new Date(),
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

      await provide(context);
    } finally {
      await db.delete(learner).where(eq(learner.id, created.id));
    }
  },
});

export function firstUnits(count: number) {
  return db.select({ title: unit.title }).from(unit).orderBy(asc(unit.id)).limit(count);
}
