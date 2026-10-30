// 서버, edge, 브라우저가 함께 쓰는 Sentry 설정. 근거: _docs/wiki/adr/0005-sentry-error-monitoring.md
// @sentry/nextjs v11은 dataCollection의 기본값이 대부분 "수집"이라, 학습자의 질문 원문과 이메일이
// 담길 수 있는 경로를 모두 명시적으로 끈다. 세션 리플레이는 어느 런타임에도 넣지 않는다.
import type { init } from "@sentry/nextjs";

type SentryOptions = NonNullable<Parameters<typeof init>[0]>;

export const sentryOptions = {
  // DSN은 이벤트를 보내는 주소일 뿐 비밀값이 아니다.
  dsn: "https://f2550150b2da09b3599a501ea3958760@o4512343473258496.ingest.us.sentry.io/4512343569793024",
  // 학습자 8명 규모라 전부 수집해도 무료 한도 안에 든다.
  tracesSampleRate: 1.0,
  dataCollection: {
    userInfo: false,
    cookies: false,
    httpHeaders: false,
    httpBodies: [],
    urlQueryParams: false,
    genAI: { inputs: false, outputs: false },
    mcp: { inputs: false, outputs: false },
    databaseQueryData: false,
    queues: false,
    stackFrameVariables: false,
  },
} satisfies SentryOptions;
