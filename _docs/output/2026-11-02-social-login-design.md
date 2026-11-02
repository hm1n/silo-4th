# 소셜 로그인 설계

Linear 4-48에서 구현한 Google 로그인의 구조와 흐름을 정리한다. 기준은 2026-11-02 기준 `4-48` 브랜치의 커밋하지 않은 코드다. 인증 도구를 Better Auth로 정한 이유는 [ADR 0004](../wiki/adr/0004-social-login.md)에, 테스트 기준은 [ADR 0006](../wiki/adr/0006-test-strategy.md)에 있다.

## 한눈에 보기

- 로그인 방법은 Google 하나다. 카카오와 네이버는 공급자 목록에 항목을 더하는 방식으로 늘린다.
- 로그인 처리는 Better Auth가 맡고, 결과는 Neon Postgres의 `learner`, `account`, `session`, `verification` 테이블에 남는다.
- 세션 본문은 DB에 있고, 브라우저 쿠키에는 세션 토큰과 서명만 들어간다.
- 로그인에 성공하면 `/study`로, 실패하거나 취소하면 `/`로 돌아온다.
- 인증 오류는 이메일을 가린 메시지 문자열만 Sentry로 보낸다.

## 전체 구조

```mermaid
flowchart LR
  subgraph Browser["브라우저"]
    Page["/ 페이지<br/>app/page.tsx"]
    Buttons["SocialLoginButtons<br/>로그인 버튼과 안내 문구"]
    SignOut["SignOutButton"]
    Client["authClient<br/>lib/auth/client.ts"]
    Cookie[("세션 쿠키<br/>better-auth.session_token")]
  end

  subgraph Server["Next.js 서버"]
    Route["/api/auth/[...all]<br/>route.ts"]
    Auth["getAuth()<br/>lib/auth/index.ts"]
    Current["getCurrentLearner()"]
    Providers["providers.ts<br/>공급자 목록과 버튼 이름"]
    Notice["login-notice.ts<br/>오류 코드를 안내 문구로"]
    Logger["sentry-logger.ts<br/>이메일 가림"]
    Env["lib/env.ts<br/>AUTH_* 와 DATABASE_URL"]
  end

  subgraph External["외부 서비스"]
    Google["Google OAuth"]
    DB[("Neon Postgres")]
    Sentry["Sentry"]
  end

  Page --> Buttons
  Page --> SignOut
  Page --> Current
  Buttons --> Providers
  Buttons --> Notice
  Buttons --> Client
  SignOut --> Client
  Client -->|"fetch"| Route
  Route --> Auth
  Current --> Auth
  Auth --> Providers
  Auth --> Env
  Auth --> Logger
  Auth <-->|"Drizzle 어댑터"| DB
  Auth <-->|"인가 코드 교환"| Google
  Logger -->|"error 수준만"| Sentry
  Route -.->|"Set-Cookie"| Cookie
```

### 파일별 역할

| 파일 | 역할 |
| --- | --- |
| `lib/auth/providers.ts` | 브라우저와 서버가 함께 쓰는 공급자 목록이다. 비밀값은 두지 않는다. |
| `lib/auth/index.ts` | Better Auth 설정을 만든다. 첫 호출에서 만들어 환경 변수 없는 빌드가 실패하지 않게 한다. |
| `lib/auth/client.ts` | 브라우저에서 로그인과 로그아웃을 호출하는 Better Auth 클라이언트다. |
| `lib/auth/login-notice.ts` | `?error=` 코드를 학습자에게 보여 줄 문구로 바꾼다. |
| `lib/auth/sentry-logger.ts` | Better Auth 로그에서 이메일을 가리고, 오류만 Sentry에 보낸다. |
| `app/api/auth/[...all]/route.ts` | `/api/auth/*` 요청을 모두 Better Auth로 넘긴다. |
| `app/_components/social-login-buttons.tsx` | 켜진 공급자마다 버튼을 그리고 안내 문구를 보여 준다. |
| `app/_components/sign-out-button.tsx` | 로그아웃한 뒤 `/`로 보낸다. |
| `app/page.tsx` | 4-51에서 첫 화면을 만들기 전까지 로그인 확인용 화면이다. |

## 로그인 성공 흐름

```mermaid
sequenceDiagram
  autonumber
  actor L as 학습자
  participant B as 브라우저
  participant S as Next.js 서버<br/>Better Auth
  participant DB as Neon Postgres
  participant G as Google

  L->>B: Google로 계속하기 클릭
  B->>S: POST /api/auth/sign-in/social<br/>provider=google, callbackURL=/study
  S->>DB: verification에 state와 PKCE 값 저장
  S-->>B: Google 인가 URL과 state 쿠키
  B->>G: Google 로그인 화면으로 이동
  L->>G: 계정 선택과 동의
  G-->>B: /api/auth/callback/google?code&state 로 이동
  B->>S: GET /api/auth/callback/google
  S->>DB: state 확인 후 verification 행 삭제
  S->>G: code를 토큰으로 교환
  G-->>S: access token, id token
  S->>S: id token에서 sub, 이메일, 이름, 사진 추출

  alt 처음 로그인한 Google 계정
    S->>DB: learner 행 생성
    S->>DB: account 행 생성<br/>provider_id=google, account_id=sub
  else 이미 연결된 Google 계정
    S->>DB: account의 토큰 갱신
  end

  S->>DB: session 행 생성<br/>token, expires_at=7일 뒤
  S-->>B: 302 /study<br/>Set-Cookie: session_token
  B->>S: GET /study
```

## 로그인 실패와 취소 흐름

```mermaid
sequenceDiagram
  autonumber
  actor L as 학습자
  participant B as 브라우저
  participant S as Next.js 서버<br/>Better Auth
  participant G as Google
  participant SE as Sentry

  alt Google 화면에서 취소
    L->>G: 취소
    G-->>B: callback?error=access_denied
    B->>S: GET /api/auth/callback/google
    S-->>B: 302 /?error=access_denied
    B->>S: GET /?error=access_denied
    S-->>B: "로그인을 취소했어요"
  else DB 저장 실패나 그 밖의 오류
    B->>S: GET /api/auth/callback/google
    S->>S: 오류 발생
    S->>SE: 이메일을 가린 메시지만 전송
    S-->>B: 302 /?error=<코드>
    B->>S: GET /?error=<코드>
    S-->>B: "로그인하지 못했어요. 다시 시도해 주세요."
  end
```

`errorCallbackURL`과 `onAPIError.errorURL`을 모두 `/`로 두어, 어느 단계에서 실패해도 로그인 버튼이 있는 화면으로 돌아온다.

## 세션 확인과 로그아웃

```mermaid
sequenceDiagram
  autonumber
  participant B as 브라우저
  participant P as / 페이지<br/>LoginStatus
  participant A as getAuth().api
  participant DB as Neon Postgres

  B->>P: GET / 와 세션 쿠키
  P->>A: getSession(headers)
  A->>A: 쿠키 서명을 AUTH_SECRET으로 검증
  A->>DB: session을 token으로 조회
  alt 세션이 있고 만료 전
    A->>DB: learner 조회
    A-->>P: learner
    P-->>B: 현재 학습자 ID와 로그아웃 버튼
  else 세션이 없거나 만료
    A-->>P: null
    P-->>B: 로그인 버튼
  end

  Note over B,DB: 로그아웃
  B->>A: POST /api/auth/sign-out
  A->>DB: session 행 삭제
  A-->>B: 쿠키 비움
  B->>P: router.push("/")
```

세션 쿠키는 `HttpOnly`, `SameSite=Lax`이고, HTTPS에서는 `Secure`와 `__Secure-` 접두어가 붙는다. 만료는 7일이며, 하루가 지난 뒤 요청이 오면 다시 7일로 늘어난다. 쿠키 캐시는 켜지 않아서 세션을 확인할 때마다 DB를 조회한다.

## 데이터 구조

```mermaid
erDiagram
  learner ||--o{ account : "로그인 방법"
  learner ||--o{ session : "로그인 상태"

  learner {
    text id PK
    text name
    text email UK
    boolean email_verified
    text image
    timestamp created_at
    timestamp updated_at
  }

  account {
    text id PK
    text provider_id "google"
    text account_id "Google sub"
    text learner_id FK
    text access_token
    text refresh_token
    text id_token
    timestamp access_token_expires_at
    text scope
  }

  session {
    text id PK
    text token UK
    timestamp expires_at
    text ip_address
    text user_agent
    text learner_id FK
  }

  verification {
    text id PK
    text identifier "OAuth state"
    text value
    timestamp expires_at
  }
```

- `account`에는 `provider_id`와 `account_id` 묶음에 고유 인덱스가 있다. 같은 Google 계정이 두 학습자로 나뉘지 않는다.
- `learner`를 지우면 연결된 `account`와 `session`도 함께 지워진다.
- `verification`은 로그인 도중에만 쓰고, 콜백을 처리하면 지운다.
- Better Auth가 쓰는 이름은 `user`와 `userId`지만, 테이블은 `learner`, 열은 `learner_id`로 바꿨다.

## 공급자를 늘리는 방법

```mermaid
flowchart TD
  A["providers.ts에 항목 추가<br/>kakao: { label }"] --> B["lib/env.ts와 .env.example에<br/>AUTH_KAKAO_ID, AUTH_KAKAO_SECRET 추가"]
  B --> C["lib/auth/index.ts의 credentials에 키 연결"]
  C --> D["enabledProviders에 kakao 켜기"]
  D --> E["공급자 콘솔에<br/>AUTH_URL/api/auth/callback/kakao 등록"]
```

`credentials`의 타입이 `Record<ProviderId, ...>`라서, 목록에 항목을 넣고 키를 잇지 않으면 타입 검사가 실패한다.

## 남은 결정과 확인 필요

| 항목 | 현재 상태 | 영향 |
| --- | --- | --- |
| 계정 자동 연결 | 꺼 두었다 | 카카오로 로그인한 이메일이 기존 Google 학습자와 같으면 `account_not_linked`로 거절된다. 이슈의 기대와 다르므로 카카오 도입 전에 정해야 한다. `확인 필요` |
| 이메일 필수 | Better Auth가 `learner.email`을 요구한다 | 카카오가 이메일을 주지 않으면 대체 값이 필요하다. `확인 필요` |
| 저장하는 개인 정보 | 이름, 이메일, 사진, OAuth 토큰을 저장하고 토큰은 암호화하지 않는다 | 저장 범위를 줄일지 정해야 한다. `제안` |
| 운영 DB 마이그레이션 | test 브랜치에만 적용했다 | 운영 배포 전에 `drizzle/0000_login_tables.sql`을 적용해야 한다 |
| 운영 환경 변수 | 로컬에서만 설정했다 | 운영의 `AUTH_*` 값과 Google 리디렉션 URI 등록이 필요하다 |
| `/study` 화면 | 아직 없다 | 로그인 직후 404가 난다. 다른 이슈에서 만든다 |
