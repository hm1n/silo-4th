# 0005. 오류 모니터링은 Sentry 무료 요금제로 하고, 알림은 Apps Script로 Slack에 보낸다

- 상태: 확정
- 결정 날짜: 2026-10-30
- 결정한 사람: 개발자
- 수정: 2026-11-02, 4-48 로그인 코드 리뷰에서 DB 오류 메시지에 쿼리 값이 담기는 것을 찾아 "결정"에 규칙 하나와 처리 방식을 더했다
- 관련 문서: [오류 모니터링 도구 결정](../../raw/2026-10-30-monitoring-sentry.md), [Sentry 오류 알림을 Slack으로 보내는 시스템](../prd/sentry-slack-alert.md), [기술 스택](../tech-stack.md), [개발 규칙](../dev-rules.md)

## 상황

03 상세 일정은 11/6에 오류 알림을 설정하고, 오류가 나면 PO가 알 수 있어야 한다고 정했다. 배포는 Vercel Hobby로 하므로 PO를 Vercel 프로젝트 멤버로 추가할 수 없고, Drains를 쓸 수 없으며, 런타임 로그는 1시간만 보관된다. 그래서 앱 코드에 SDK를 넣어 오류를 직접 보내는 도구가 필요했다. (근거: `raw/2026-10-30-monitoring-sentry.md` "확인한 제약", [03 상세 일정](https://linear.app/silo0/document/03-상세-일정-1f1a08402713) 11/6)

처음에는 개발자 메일함에서 Sentry 알림 메일을 PO에게 자동 전달하기로 했다. 그런데 메일 전달로는 메일 내용을 고칠 수 없어, 오류 메시지에 질문 원문이 섞이면 PO에게 그대로 간다. 이슈 [4-43](https://linear.app/silo0/issue/4-43)의 완료 기준은 "알림에 질문 원문과 이메일이 담기지 않음"이다. 그래서 2026-10-30에 전달 방식을 Slack으로 바꿨다. (근거: [Sentry 오류 알림을 Slack으로 보내는 시스템](../prd/sentry-slack-alert.md))

## 결정

Sentry 무료 요금제(Developer)와 `@sentry/nextjs`로 서버와 브라우저 오류를 잡는다. 무료 요금제는 사용자 1명이고 외부 이메일 알림과 Slack 연동을 지원하지 않으므로, Google Apps Script가 5분마다 Sentry API로 새 이슈를 조회해 Slack Incoming Webhook으로 `#프로젝트-4차-오류-알림` 채널에 보낸다.

연동할 때 다음을 지킨다.

- 세션 리플레이를 켜지 않는다.
- 오류와 함께 보내는 정보(breadcrumb, extra, context)에 질문 원문과 이메일을 넣지 않는다.
- DB 오류는 원본 그대로 서버 로그나 Sentry로 보내지 않는다. Drizzle 오류 메시지는 `params:` 뒤에 쿼리 값을 붙이므로, 그 뒤를 지우고 이메일을 가린 메시지 문자열만 남긴다.
- Slack 메시지에는 허용한 필드(이슈 ID, 레벨, 오류 종류, 발생 위치, 발생 횟수, 처음 발생 시각, Sentry 링크)만 담는다. 이슈 제목과 오류 메시지는 스크립트가 읽지 않는다.
- Sentry 토큰과 Slack Webhook URL은 Apps Script의 Script Properties에만 둔다.

2026-10-30 연동 때 확인한 내용: `@sentry/nextjs` v11에는 `sendDefaultPii`가 없고, `dataCollection`의 기본값이 사용자 정보, HTTP 본문과 헤더, 쿠키, 쿼리, LLM 입출력(`genAI`), 스택 프레임 로컬 변수를 모두 수집한다. 그래서 `lib/sentry.ts`의 공용 설정에서 이 항목을 모두 명시적으로 끄고, 서버, edge, 브라우저 초기화가 이 설정 하나를 함께 쓴다. (근거: `node_modules/@sentry/core/build/types/types/datacollection.d.ts`)

2026-10-30에 확인한 충돌: Sentry 가격표는 무료 요금제를 `API: No`로 표시한다. 하지만 개발자가 `event:read` 권한의 개인 토큰으로 issues API를 호출했을 때 200 응답을 받았다. 이 결정은 실제 호출 결과에 기대고 있다. (근거: [Sentry 가격표](https://sentry.io/pricing/), [Sentry 오류 알림을 Slack으로 보내는 시스템](../prd/sentry-slack-alert.md) "확인된 내용")

2026-11-02 4-48 로그인에서 정한 처리 방식: Drizzle 오류 메시지는 `Failed query: <SQL>` 다음 줄에 `params: <값>`을 붙인다. 로그인 쿼리에서는 이 자리에 access token, id token, 세션 토큰, IP, User-Agent가 들어간다. Better Auth의 라우터는 예외를 이 원본 그대로 `console.error`로 찍고, 세션 조회 오류는 원본을 `cause`에 달아 던진다. 그래서 인증 경계에서 다음과 같이 막는다. (근거: `node_modules/drizzle-orm/errors.js`, `node_modules/better-call/dist/router.mjs`, `node_modules/better-auth/dist/api/routes/session.mjs`)

- `lib/auth/sentry-logger.ts`의 `safeMessage`가 `params:` 뒤를 지우고 이메일을 가린다. `reportAuthError`는 이 메시지만 서버 로그와 Sentry에 남긴다. Better Auth 로거도 이 두 함수를 쓴다.
- Better Auth 설정에 `onAPIError.throw`를 켜 원본을 찍는 라우터 기본 처리를 건너뛰고, `app/api/auth/[...all]/route.ts`가 예외를 잡아 정리한 메시지만 남긴다. 로그인 콜백처럼 브라우저가 화면을 옮기는 요청은 `/?error=internal_server_error`로 보내고, fetch 요청은 500 JSON을 돌려준다. `sec-fetch-mode` 헤더로 구분하고, 이 헤더를 보내지 않는 오래된 브라우저의 GET 요청은 화면 이동으로 본다.
- `safeMessage`는 지운 쿼리 값 대신 원인을 찾을 단서로 오류 코드를 덧붙인다. Postgres 오류 코드나 Node 오류 코드에는 값이 담기지 않는다.
- Better Auth는 DB 호출마다 추적 구간을 만들고, 실패하면 원본 메시지를 구간 상태에 넣는다. Sentry는 이 상태를 성능 데이터로 보낸다. Sentry에 Better Auth 구간이 실제로 쌓이는 것을 확인하고 `experimental.instrumentation.enabled`를 껐다. (근거: `node_modules/@better-auth/core/dist/instrumentation/tracer.mjs`)
- `findLearner`는 세션 조회 오류를 `cause` 없이 정리한 메시지로 다시 던진다. Next.js가 이 오류를 Sentry로 보내도 원본은 실리지 않는다.
- 같은 날 다른 경로도 점검했다. Drizzle의 추적 구간은 OpenTelemetry를 연결하는 코드가 없어 만들어지지 않는다. Next.js 추적은 요청 밖으로 나간 예외만 기록하는데, 라우트 핸들러와 `findLearner`가 정리한 메시지만 내보낸다. OAuth 콜백 URL의 `code`, `state`는 Sentry 서버 요청 구간에 `[Filtered]`로 저장되는 것을 확인했다. 최근 7일 오류 이벤트에 쿼리 값이 담긴 것은 없었다.
- test 브랜치에서 세션 저장과 세션 조회를 일부러 실패시켜, 고치기 전에는 `params:`와 User-Agent가 로그에 남고 고친 뒤에는 남지 않는 것을 확인했다.

다음은 Claude가 제안했고 개발자가 아직 정하지 않았다. `제안`

- 인증 밖의 DB 오류, 예를 들어 질문과 기록 저장 오류는 아직 이 처리를 거치지 않는다. 그 기능을 만들 때 같은 방식으로 경계에서 정리하거나, `lib/sentry.ts`의 `beforeSend`와 `beforeBreadcrumb`에서 `params:` 뒤를 지우는 처리를 앱 전체에 더한다. 후자는 Vercel 로그에 찍히는 원본은 막지 못한다.

## 검토한 대안

오류 모니터링 도구

| 대안 | 장점 | 단점 | 택하지 않은 이유 |
| --- | --- | --- | --- |
| PostHog | 예외 월 10만 건이 무료이고 팀원을 초대할 수 있다. 분석 기능도 있다 | 오류 추적이 최근 추가된 기능이고, 서버 오류는 직접 연결해야 할 수 있다. 리플레이와 자동 수집을 꺼야 한다 | 오류 추적과 성능 모니터링에 집중하고 연동 품질이 좋은 도구를 우선했다 |
| Better Stack (Sentry SDK 호환) | DSN만 바꿔 Sentry SDK를 쓸 수 있다 | 소스맵을 지원하지 않고, 무료 한도와 Next.js 동작을 확인하지 못했다 | 스택 트레이스를 읽기 어렵다 |
| GlitchTip (직접 호스팅) | 오픈소스이고 Sentry SDK와 호환된다 | 서버를 직접 운영해야 한다 | 2주 운영에 비해 관리 부담이 크다 |
| Vercel 로그만 사용 | 추가 도구가 없다 | Hobby는 1시간만 보관하고 PO가 볼 수 없다 | 11/6 목표를 채우지 못한다 |
| Sentry Team 요금제 | Slack과 외부 이메일 알림을 쓸 수 있다 | 비용이 든다 | Apps Script로 같은 목표를 무료로 채울 수 있다 |

PO에게 알림을 전달하는 방식

| 대안 | 장점 | 단점 | 택하지 않은 이유 |
| --- | --- | --- | --- |
| 개발자 메일함에서 Sentry 메일을 PO에게 자동 전달 | 코드가 필요 없다 | 메일 내용을 고칠 수 없어 오류 메시지 원문이 그대로 간다 | 이슈 4-43의 완료 기준을 지킬 수 없다 |
| Gmail의 Sentry 메일을 Slack 채널 메일 주소로 전달 | 코드가 필요 없다 | 위와 같다 | 위와 같다 |
| Vercel Cron으로 앱 안에서 Sentry API 조회 | 앱 저장소 안에서 관리한다 | Hobby의 Cron은 하루 1회다 (확인 필요) | 알림이 최대 하루 늦는다 |
| GitHub Actions 예약 실행으로 조회 | 저장소 안에서 관리한다 | 5분 주기면 비공개 저장소의 무료 실행 시간을 넘는다 (추정) | 비용이 든다 |
| Apps Script가 Gmail의 Sentry 메일을 읽어 Slack으로 전송 | Sentry API 없이 된다 | 메일 형식이 바뀌면 깨진다 | 예비안으로 둔다 |
| Slack 봇 토큰(`chat.postMessage`) | 메시지 수정, 스레드 답글을 쓸 수 있다 | 봇 권한과 토큰을 관리해야 한다 | 한 채널에 보내기만 하므로 Webhook URL로 충분하다 |

## 결과

- 서버와 브라우저 오류를 소스맵과 함께 볼 수 있고, 성능 모니터링도 쓸 수 있다.
- Sentry 화면은 개발자만 볼 수 있다. PO는 Slack 메시지로 오류 발생 사실만 받고, 자세한 내용은 개발자에게 확인해야 한다.
- 질문 원문이 오류 메시지에 섞여도 Slack으로 나가지 않는다. 스크립트가 허용한 필드만 읽기 때문이다.
- 알림이 최대 5분 늦게 온다.
- 알림이 Apps Script와 개인 토큰에 의존한다. 토큰이 폐기되거나 Sentry가 API를 막으면 알림이 끊긴다. 이 경우 Apps Script 트리거 실패 메일과 Sentry의 개발자 메일 알림으로 개발자가 알아차린다.

## 다시 검토할 조건

- 오류가 월 5천 건을 넘거나, PO가 Sentry 화면을 직접 봐야 하는 상황이 생기면 Team 요금제나 PostHog를 다시 검토한다.
- Sentry가 무료 요금제의 API 접근을 막으면, Apps Script가 Gmail의 Sentry 메일을 읽어 Slack으로 보내는 예비안으로 바꾼다.
