import { captureMessage } from "@sentry/nextjs";
import type { Logger } from "better-auth";

const EMAIL = /[^\s@]+@[^\s@]+/g;

// Better Auth는 메시지 뒤 인자에 프로필 객체나 이메일이 담긴 DB 오류를 넘긴다.
// 콘솔 출력도 Sentry 브레드크럼으로 이벤트에 실리므로, 어디에도 메시지 문자열만 남긴다.
export const sentryLogger: Logger = {
  level: "warn",
  log(level, message) {
    const safe = message.replace(EMAIL, "[email]");
    console[level](`[better-auth] ${safe}`);
    if (level === "error") captureMessage(`[better-auth] ${safe}`, "error");
  },
};
