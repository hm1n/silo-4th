import { randomUUID } from "node:crypto";
import { eq, inArray } from "drizzle-orm";
import { vi } from "vitest";
import { getAuth } from "@/lib/auth";
import { getDb } from "@/lib/db";
import { learner } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { SOURCE_COOKIE } from "@/lib/source";

type GoogleProfile = { sub: string; email: string; name: string };

const realFetch = globalThis.fetch;
const createdEmails: string[] = [];

export function newProfile(name = "테스트 학습자"): GoogleProfile {
  const email = `${randomUUID()}@tc.test`;
  createdEmails.push(email);
  return { sub: randomUUID(), email, name };
}

export async function deleteCreatedLearners() {
  if (createdEmails.length === 0) return;
  await getDb().delete(learner).where(inArray(learner.email, createdEmails.splice(0)));
}

export async function learnerWithEmail(email: string) {
  const [found] = await getDb().select().from(learner).where(eq(learner.email, email));
  return found;
}

// 콜백은 id_token을 서명 검증 없이 해석하므로 서명 자리는 아무 값이나 둔다.
function idToken(profile: GoogleProfile) {
  const part = (value: object) => Buffer.from(JSON.stringify(value)).toString("base64url");
  const claims = {
    iss: "https://accounts.google.com",
    aud: env.AUTH_GOOGLE_ID,
    email_verified: true,
    ...profile,
  };
  return `${part({ alg: "RS256", kid: "test" })}.${part(claims)}.signature`;
}

function stubGoogleToken(profile: GoogleProfile) {
  vi.spyOn(globalThis, "fetch").mockImplementation((input, init) => {
    const url = input instanceof Request ? input.url : String(input);
    if (url !== "https://oauth2.googleapis.com/token") return realFetch(input, init);
    return Promise.resolve(
      Response.json({
        access_token: "access-token",
        token_type: "Bearer",
        expires_in: 3600,
        id_token: idToken(profile),
      }),
    );
  });
}

function cookiesFrom(response: Response) {
  return response.headers
    .getSetCookie()
    .map((cookie) => cookie.split(";")[0])
    .filter((pair) => pair && !pair.endsWith("="));
}

// Google 화면을 거치지 않고 콜백까지 진행한다. 콜백 응답과, 로그인한 학습자의 쿠키를 담은 헤더를 돌려준다.
export async function loginWithGoogle(profile: GoogleProfile, { source }: { source?: string } = {}) {
  stubGoogleToken(profile);
  try {
    const { handler } = getAuth();
    const start = await handler(
      new Request(`${env.AUTH_URL}/api/auth/sign-in/social`, {
        method: "POST",
        headers: { "content-type": "application/json", origin: env.AUTH_URL },
        body: JSON.stringify({ provider: "google", callbackURL: "/study" }),
      }),
    );
    const { url } = (await start.json()) as { url: string };
    const state = new URL(url).searchParams.get("state") ?? "";
    const sourceCookie = source === undefined ? [] : [`${SOURCE_COOKIE}=${source}`];
    const callback = await handler(
      new Request(`${env.AUTH_URL}/api/auth/callback/google?code=test-code&state=${state}`, {
        headers: { cookie: [...cookiesFrom(start), ...sourceCookie].join("; ") },
      }),
    );
    return { callback, headers: new Headers({ cookie: cookiesFrom(callback).join("; ") }) };
  } finally {
    vi.mocked(globalThis.fetch).mockRestore();
  }
}
