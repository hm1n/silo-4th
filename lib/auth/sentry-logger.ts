import { captureMessage } from "@sentry/nextjs";
import type { Logger } from "better-auth";

const EMAIL = /[^\s@]+@[^\s@]+/g;
// Drizzle 오류 메시지는 `params:` 뒤에 쿼리 값을 붙인다. 토큰, 세션 토큰, IP가 그 자리에 들어간다.
const QUERY_PARAMS = /\nparams:[\s\S]*/;

export function safeMessage(value: unknown) {
  const message = value instanceof Error ? value.message : String(value);
  return `[better-auth] ${message.replace(QUERY_PARAMS, "").replace(EMAIL, "[email]")}`;
}

export function reportAuthError(error: unknown) {
  const safe = safeMessage(error);
  console.error(safe);
  captureMessage(safe, "error");
}

// Better Auth는 메시지 뒤 인자에 프로필 객체나 이메일이 담긴 DB 오류를 넘긴다.
// 콘솔 출력도 Sentry 브레드크럼으로 이벤트에 실리므로, 어디에도 메시지 문자열만 남긴다.
export const sentryLogger: Logger = {
  level: "warn",
  log(level, message) {
    if (level === "error") reportAuthError(message);
    else console[level](safeMessage(message));
  },
};
