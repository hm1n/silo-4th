import "server-only";
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { headers } from "next/headers";
import { getDb } from "@/lib/db";
import * as schema from "@/lib/db/schema";
import { env } from "@/lib/env";
import { DIRECT_SOURCE, normalizeSource, SOURCE_COOKIE, TEST_SOURCE } from "@/lib/source";
import { enabledProviders, type ProviderId } from "./providers";
import { safeMessage, sentryLogger } from "./sentry-logger";

const credentials: Record<ProviderId, () => { clientId: string; clientSecret: string }> = {
  google: () => ({ clientId: env.AUTH_GOOGLE_ID, clientSecret: env.AUTH_GOOGLE_SECRET }),
};

function createAuth() {
  return betterAuth({
    secret: env.AUTH_SECRET,
    baseURL: env.AUTH_URL,
    // 학습자와 계정을 함께 저장한다. 따로 저장하다 계정만 실패하면 연결 없는 학습자가 남아 다시 로그인할 수 없다.
    database: drizzleAdapter(getDb(), { provider: "pg", schema, transaction: true }),
    user: {
      modelName: "learner",
      // 로그인 요청으로는 바꿀 수 없게 막고, 현재 학습자 조회 결과에는 함께 담는다.
      additionalFields: {
        consentedAt: { type: "date", required: false, input: false },
        // 하루를 뜻하는 값이라 Date로 바꾸지 않고 `YYYY-MM-DD` 문자열로 둔다.
        examDate: { type: "string", required: false, input: false },
        source: { type: "string", defaultValue: DIRECT_SOURCE, input: false },
        isTest: { type: "boolean", defaultValue: false, input: false },
      },
    },
    databaseHooks: {
      user: {
        create: {
          // 출처는 학습자를 만들 때 한 번만 정하고 바꾸지 않는다.
          before: async (user, context) => {
            const source = normalizeSource(context?.getCookie(SOURCE_COOKIE));
            return { data: { ...user, source, isTest: source === TEST_SOURCE } };
          },
        },
      },
    },
    socialProviders: Object.fromEntries(enabledProviders.map((id) => [id, credentials[id]()])),
    account: { accountLinking: { enabled: false } },
    // API 오류가 아닌 예외를 라우트 핸들러로 던져, 원본 대신 정리한 메시지만 남긴다.
    onAPIError: { errorURL: "/", throw: true },
    logger: sentryLogger,
    // Better Auth 추적 구간은 실패한 DB 호출의 원본 메시지를 담아 Sentry로 보낸다.
    experimental: { instrumentation: { enabled: false } },
    advanced: { database: { generateId: "uuid" } },
  });
}

let auth: ReturnType<typeof createAuth> | undefined;

// 첫 호출에서 만든다. 모듈 로드 시점에 만들면 환경 변수 없는 빌드가 실패한다.
export function getAuth() {
  auth ??= createAuth();
  return auth;
}

export async function findLearner(requestHeaders: Headers) {
  try {
    // 서버 컴포넌트는 쿠키를 쓸 수 없다. 여기서 DB 만료일만 늘리면 브라우저의 세션 확인이 쿠키를 새로 쓰지 않는다.
    const result = await getAuth().api.getSession({
      headers: requestHeaders,
      query: { disableRefresh: true },
    });
    return result?.user ?? null;
  } catch (error) {
    // 세션 조회 오류는 cause에 세션 토큰이 담긴 DB 오류를 달고 온다. 그대로 던지면 Sentry가 cause까지 보낸다.
    throw new Error(safeMessage(error));
  }
}

export async function getCurrentLearner() {
  return findLearner(await headers());
}
