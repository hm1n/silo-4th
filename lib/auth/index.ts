import "server-only";
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { headers } from "next/headers";
import { getDb } from "@/lib/db";
import * as schema from "@/lib/db/schema";
import { env } from "@/lib/env";
import { enabledProviders, type ProviderId } from "./providers";
import { sentryLogger } from "./sentry-logger";

const credentials: Record<ProviderId, () => { clientId: string; clientSecret: string }> = {
  google: () => ({ clientId: env.AUTH_GOOGLE_ID, clientSecret: env.AUTH_GOOGLE_SECRET }),
};

function createAuth() {
  return betterAuth({
    secret: env.AUTH_SECRET,
    baseURL: env.AUTH_URL,
    // 학습자와 계정을 함께 저장한다. 따로 저장하다 계정만 실패하면 연결 없는 학습자가 남아 다시 로그인할 수 없다.
    database: drizzleAdapter(getDb(), { provider: "pg", schema, transaction: true }),
    user: { modelName: "learner" },
    socialProviders: Object.fromEntries(enabledProviders.map((id) => [id, credentials[id]()])),
    // 같은 이메일의 다른 로그인 방법을 기존 학습자에 자동으로 붙이지 않는다.
    account: { accountLinking: { enabled: false } },
    onAPIError: { errorURL: "/" },
    logger: sentryLogger,
  });
}

let auth: ReturnType<typeof createAuth> | undefined;

// 첫 호출에서 만든다. 모듈 로드 시점에 만들면 환경 변수 없는 빌드가 실패한다.
export function getAuth() {
  auth ??= createAuth();
  return auth;
}

export async function findLearner(requestHeaders: Headers) {
  const result = await getAuth().api.getSession({ headers: requestHeaders });
  return result?.user ?? null;
}

export async function getCurrentLearner() {
  return findLearner(await headers());
}
