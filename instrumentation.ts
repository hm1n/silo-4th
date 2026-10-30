import * as Sentry from "@sentry/nextjs";
import { sentryOptions } from "@/lib/sentry";

// register는 서버 런타임(nodejs, edge)에서만 실행되고, 두 런타임의 설정이 같아 분기하지 않는다.
export function register() {
  Sentry.init(sentryOptions);
}

// 서버 컴포넌트, Route Handler, Server Action에서 처리되지 않은 오류를 잡는다.
export const onRequestError = Sentry.captureRequestError;
