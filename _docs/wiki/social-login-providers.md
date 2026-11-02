# 로그인 공급자 추가 절차

## 한 문장 요약

로그인 공급자는 `lib/auth/providers.ts`의 목록에 항목을 넣고, 환경 변수 두 개와 서버 설정 한 줄을 이은 뒤 켜면 늘어나며, 버튼은 목록을 보고 자동으로 그려진다.

## 근거

- 원천 자료: Linear [4-48 소셜 로그인으로 학습자 구분하기](https://linear.app/silo0/issue/4-48) "범위", "완료 기준"
- 확인 날짜: 2026-11-02
- 자료 성격: 코드. `4-48` 브랜치의 `lib/auth/providers.ts`, `lib/auth/index.ts`, `lib/env.ts`, `app/_components/social-login-buttons.tsx`와 설치된 `better-auth` `1.7.15`
- 결정한 사람: 개발자
- 관련 문서: [ADR 0004](adr/0004-social-login.md), [기술 스택](tech-stack.md), [소셜 로그인 설계](../output/2026-11-02-social-login-design.md)

## 확인된 내용

### 구조

- 공급자 목록은 `lib/auth/providers.ts` 한 곳에 있다. 브라우저와 서버가 함께 읽으므로 이 파일에는 버튼 이름만 두고 비밀값은 두지 않는다.
- `enabledProviders`에 넣은 공급자만 서버 설정에 들어가고 버튼으로 그려진다. 목록에만 있고 켜지 않은 공급자는 키가 없어도 앱이 뜬다.
- 비밀값은 `lib/auth/index.ts`의 `credentials`에서 `env`로 읽는다. `credentials`의 타입이 `Record<ProviderId, ...>`라서, 목록에 공급자를 넣고 키를 잇지 않으면 `npm run check`가 실패한다.
- 콜백 주소는 Better Auth가 `AUTH_URL/api/auth/callback/{공급자 ID}`로 만든다. 라우트 파일은 따로 만들지 않는다.
- 설치된 Better Auth에는 `kakao`와 `naver` 공급자가 들어 있다.

### 추가 순서

카카오를 예로 든다.

1. **공급자 콘솔에서 앱을 만든다.** 리디렉션 URI에 로컬 `http://localhost:3000/api/auth/callback/kakao`와 운영 `{운영 AUTH_URL}/api/auth/callback/kakao`를 등록하고, 클라이언트 ID와 시크릿을 받는다.
2. **환경 변수 이름을 더한다.** `lib/env.ts`에 `AUTH_KAKAO_ID`, `AUTH_KAKAO_SECRET`을 `required()`로 추가하고, `.env.example`에도 같은 이름을 적는다.
3. **목록에 항목을 넣는다.** `lib/auth/providers.ts`의 `providers`에 `kakao: { label: "카카오로 계속하기" }`를 더한다.
4. **키를 잇는다.** `lib/auth/index.ts`의 `credentials`에 `kakao: () => ({ clientId: env.AUTH_KAKAO_ID, clientSecret: env.AUTH_KAKAO_SECRET })`를 더한다.
5. **켠다.** `enabledProviders`에 `"kakao"`를 넣는다.
6. **값을 넣는다.** 로컬은 `.env.local`에, 운영은 Vercel 환경 변수에 두 값을 넣는다.
7. **확인한다.** `npm run check`와 `npm test`를 돌리고, 로컬에서 버튼이 하나 늘었는지와 로그인 뒤 `account` 테이블에 `provider_id`가 `kakao`인 행이 생기는지 본다.

DB 스키마는 바꾸지 않는다. `account` 테이블이 `provider_id`와 `account_id`로 공급자 계정을 구분한다.

## 확인 필요

- **카카오 이메일.** Better Auth 카카오 공급자는 기본으로 `account_email` 범위를 요청한다. 비즈 앱 심사 전에는 카카오가 이메일을 주지 않는데, `learner.email`은 필수이고 고유값이다. 이메일이 없을 때의 대체 값을 정하고 `mapProfileToUser`로 넣어야 한다. 실제 카카오 응답으로는 아직 확인하지 않았다.
- **같은 이메일의 다른 공급자.** 계정 자동 연결을 꺼 두었고 `learner.email`이 고유값이라, Google로 가입한 이메일로 카카오 로그인을 하면 새 학습자를 만들지 않고 `account_not_linked`로 거절한다. Linear 4-48 "예외 상황"은 다른 학습자로 만든다고 적고 있어 서로 다르다. 합칠지는 카카오를 도입하기 전에 PO가 정한다.
- **네이버.** 네이버 공급자는 이메일 인증 여부를 항상 `false`로 넣는다. 지금 코드는 이 값을 쓰지 않지만, 나중에 인증된 이메일만 믿는 기능을 만들면 영향을 받는다.

## 다시 물어볼 질문

- 카카오 이메일이 없을 때 `learner.email`에 무엇을 넣을지, 아니면 이메일을 필수에서 뺄지
- Google과 카카오를 같은 사람으로 합칠지, 다른 학습자로 둘지
