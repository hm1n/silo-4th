# 기술 스택

## 한 문장 요약

스프린트 1 프로토타입은 Next.js, Vercel, Anthropic 공식 SDK, Tailwind CSS에 Neon Postgres와 Drizzle ORM, Sentry를 더해 만들고, 학습자는 Better Auth로 붙인 Google 로그인으로 구분한다. 질문 답변 AI 모델은 Claude Sonnet 5.5를 effort `low`로 쓴다. 카카오와 네이버 로그인은 추후 도입을 검토한다. UI 컴포넌트는 아직 정하지 않았다.

## 근거

- 원천 자료: [`raw/2026-10-30-tech-stack-decisions.md`](../raw/2026-10-30-tech-stack-decisions.md) (개발자의 결정), [`raw/2026-10-30-social-login-decision.md`](../raw/2026-10-30-social-login-decision.md) (PO와 개발자의 결정), Linear [01 브리프](https://linear.app/silo0/document/01-브리프-5fa343785a20), [02 화면 흐름](https://linear.app/silo0/document/02-화면-흐름-6dbdadb44bbb), [03 상세 일정](https://linear.app/silo0/document/03-상세-일정-1f1a08402713), [03-1 진행 가이드](https://linear.app/silo0/document/03-1-진행-가이드-7acec4859ba4), Linear [4-48 소셜 로그인으로 학습자 구분하기](https://linear.app/silo0/issue/4-48), [`raw/2026-11-04-ai-model-selection-research.md`](../raw/2026-11-04-ai-model-selection-research.md) (AI 모델 조사와 개발자의 결정), Linear [4-60](https://linear.app/silo0/issue/4-60)
- 확인 날짜: 2026-10-30, 인증 도구와 공급자는 2026-11-02, AI 모델은 2026-11-04
- 결정한 사람: 개발자 (01 브리프에서 "어떻게 동작하게 만드는지"의 DRI)
- 관련 문서: [개발 규칙](dev-rules.md)

## 스택을 정할 때 고려한 조건

- 만드는 기간은 11/2부터 11/4까지 사흘이고, 11/4 저녁에 기능을 동결한다. 11/6 저녁 마지막 배포 뒤에는 배포하지 않는다. (03 상세 일정, 03-1 "기능 동결")
- 로그인은 소셜 로그인으로 하고, 첫 화면에서 로그인한 뒤 시험 날짜와 저장 동의를 받는다. 같은 소셜 계정으로 다시 로그인하면 같은 학습자로 이어진다. (01 "만드는 것과 만들지 않는 것", 02 흐름 1, `raw/2026-10-30-social-login-decision.md`)
- 기록 여섯 가지(학습자, 질문, AI의 답, 확인, 이해 상태, 사용)를 출처와 함께 빠짐없이 남겨야 한다. (02 "남겨야 할 기록")
- AI는 질문에 답하는 데만 쓴다. 개념을 자동으로 고르거나 확인 문제를 만들지 않는다. (01 "만드는 것과 만들지 않는 것")
- 하루의 시작은 새벽 4시이고, 학습자에게 알림을 보내지 않는다. (02 상황별 규칙, 01)
- 모바일 화면은 만들지 않고 "PC에서 열어 주세요"만 보여 준다. (01, 02 상황별 규칙)

## 확정한 스택

| 영역 | 선택 | 이유 |
| --- | --- | --- |
| 프레임워크 | Next.js(App Router)와 TypeScript | 화면과 API를 한 저장소에서 만들 수 있어 사흘 일정에 알맞다 |
| 배포 | Vercel | Next.js를 별도 설정 없이 배포하고, Neon을 연결하기 쉽다 |
| LLM 연결 | `@anthropic-ai/sdk` | LLM을 답변에만 쓰고 Anthropic만 사용하므로 다른 연결 방식으로 바꿀 이유가 없다 |
| AI 모델 | Claude Sonnet 5.5 `claude-sonnet-5-5`, effort `low` | 단원 본문을 근거로 한 번 답하는 질의응답이라 Opus 5.5의 강점인 장시간 에이전트 작업이 필요 없다. Sonnet 5.5는 Opus 5.5보다 가격이 절반이고 첫 응답이 빠르다. Haiku 5.5는 분류와 추출용이라 시험 공부 설명의 정확도가 걱정되고, 학습자 8명 규모에서 아끼는 금액이 작다. 같은 질문으로 비교하는 테스트는 하지 않고 공식 문서와 비교 자료로 정했다. 정한 사람은 개발자다. [ADR 0007](adr/0007-ai-model.md) |
| DB | Neon Postgres | 기록 여섯 가지를 서버에 남겨야 하고, PO가 SQL로 지표를 뽑을 수 있다. [ADR 0003](adr/0003-neon-postgres-drizzle.md) |
| DB 접근 | Drizzle ORM | 스키마에서 타입이 나와 AI가 작성한 DB 코드의 오류를 컴파일 단계에서 잡을 수 있다. [ADR 0003](adr/0003-neon-postgres-drizzle.md) |
| 오류 알림 | Sentry | 03 상세 일정에 따라 11/6에 설정하고, 서버와 브라우저 오류를 모두 잡는다. 무료 요금제라 알림은 Apps Script가 Sentry API를 조회해 Slack으로 PO에게 보낸다. [ADR 0005](adr/0005-sentry-error-monitoring.md) |
| 인증 | Better Auth와 Drizzle 어댑터 | 설정에서 타입이 추론되고, Next.js 16을 공식 지원한다. Auth.js는 Better Auth로 넘어가 보안 수정만 하고, Neon Auth는 카카오와 네이버로 넓히기 어렵다. [ADR 0004](adr/0004-social-login.md) |
| 스타일 | Tailwind CSS | 이미 설치되어 있고, 새 문서와 부딪치는 내용이 없다 |

## 동작 방식에 대한 결정

| 영역 | 결정 |
| --- | --- |
| 학습자 구분 | 소셜 로그인으로 학습자를 구분하고, 이메일이 아니라 공급자와 공급자 계정 ID로 학습자를 찾는다. Google을 먼저 도입하고, 카카오와 네이버는 추후 도입을 검토한다. 서로 다른 공급자 계정은 한 학습자로 합치지 않는다. [ADR 0004](adr/0004-social-login.md) |
| 출처 기록 | 주소의 `from` 값 중 형식에 맞는 첫 값을 `proxy.ts`가 `from` 쿠키에 30일 동안 담아 Google 로그인을 다녀와도 남긴다. 쿠키가 있으면 덮어쓰지 않는다. 학습자를 만들 때 이 값을 `learners.source`에 고정하고, 값이 없거나 형식에 맞지 않으면 `direct`로 남긴다. 형식은 앞뒤 공백을 지우고 소문자로 바꾼 뒤 영문 소문자, 숫자, `-`, `_`로 된 32자 이하이고, 목록 밖의 값도 그대로 저장한다. 팀은 `from=test`로 들어오고 `is_test`가 `true`가 된다. 정한 사람은 개발자이고, 값 목록을 PO가 정하면 다시 본다. 근거는 [Linear 4-49](https://linear.app/silo0/issue/4-49)다 |
| 날짜 계산 | 시각은 UTC로 저장하고, 학습일은 "한국 시간에서 4시간을 뺀 날짜"로 한 함수에서만 계산한다. 테스트 학습자에게만 날짜 오프셋을 둔다 |

## 제안

- **학습 자료와 확인 문제의 형식:** 학습 자료는 단원마다 Markdown 파일로 저장소에 두고, 확인 문제는 JSON 파일로 받아 DB에 넣는다. 01 브리프에서 개발자와 PO가 함께 정하도록 했으므로 PO와 확정해야 한다.

## 넣지 않은 것

| 제외한 것 | 이유 |
| --- | --- |
| 알림 도구 | 학습자가 스스로 다시 오는지 봐야 한다 (01) |
| Vercel AI SDK | LLM을 답변에만 쓰고 Anthropic만 사용한다 |
| 구조화 출력 스키마 | AI가 개념을 고르거나 문제를 만들지 않아 필요하지 않다 (01) |

## 보류한 것

- **카카오와 네이버 로그인:** 일정에 여유가 생기면 별도 이슈로 도입을 검토한다. 카카오는 비즈 앱 심사 전에는 이메일을 주지 않아, Better Auth의 필수 이메일 필드에 넣을 대체 값을 정해야 한다. 같은 사람의 Google과 카카오 계정을 합칠지는 카카오를 도입하기 전에 PO가 정한다. ([ADR 0004](adr/0004-social-login.md))
- **UI 컴포넌트:** 학습 화면은 개발자가 기본 컴포넌트로 만든다(02 화면 목록). shadcn/ui를 도입할지는 디자이너와 상의한 뒤 정한다.

## 확인 필요

- Google OAuth 앱이 테스트 상태면 등록한 테스트 사용자만 로그인할 수 있다. 11/5 학습자 공개 전에 운영 상태로 바꿔야 한다.
- 같은 이메일로 다른 공급자에 로그인하면 지금은 `account_not_linked`로 거절한다. Linear 4-48은 다른 학습자로 만든다고 적고 있어 카카오 도입 전에 정해야 한다. ([ADR 0004](adr/0004-social-login.md) "결과")
- 실제로 쓸 `from` 값 목록은 PO가 정한다. 목록이 정해지면 목록 밖의 값을 `direct`로 바꿀지 다시 정한다. 근거는 Linear 4-49 "열린 질문"이다.
- 01 브리프에는 PO가 내 이해 기록과 지표 추출을 개발한다고 되어 있지만, 03 상세 일정의 최신본에서는 이 내용이 빠졌다. PO가 코드를 다루는지에 따라 Drizzle 스키마와 데이터 형식을 PO에게 어떻게 넘길지가 달라진다.
- 기능 동결 전에 Vercel 운영 환경의 `ANTHROPIC_MODEL`을 `claude-sonnet-5-5`로 바꿔야 한다. 모델 비교 테스트를 하지 않아 Sonnet 5.5 `low`의 한국어 답 품질은 운영에서 처음 확인한다. 시험 분야가 안전 분류기의 `cyber`, `bio` 범주에 가까우면 정상 질문이 거절될 수 있다. ([`raw/2026-11-04-ai-model-selection-research.md`](../raw/2026-11-04-ai-model-selection-research.md) "남은 위험")

## 다시 물어볼 질문

- 11/2 기록 구조 회의 결과가 Drizzle 스키마로 바로 옮겨지는가?
