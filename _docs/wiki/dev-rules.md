# 개발 규칙

## 한 문장 요약

이 문서는 개발과 관련한 규칙과 ADR을 한곳에 모은 목록이며, 기계로 검사할 수 있는 규칙은 타입 검사, 린트, Claude Code 훅으로 강제한다.

## 근거

- 원천 자료: [`raw/2026-10-30-ai-harness-rules.md`](../raw/2026-10-30-ai-harness-rules.md), [`raw/2026-10-30-tech-stack-decisions.md`](../raw/2026-10-30-tech-stack-decisions.md)
- 확인 날짜: 2026-10-30
- 결정한 사람: 개발자
- 관련 문서: [기술 스택](tech-stack.md)

## 적용된 규칙

| 규칙 | 강제하는 곳 | 근거 |
| --- | --- | --- |
| `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`를 켠다 | `tsconfig.json` | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| 타입을 `any`로 덮지 않는다 | `eslint.config.mjs` (`no-explicit-any`) | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| 타입 import는 `import type`으로 쓴다 | `eslint.config.mjs` (`consistent-type-imports`) | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| 환경 변수는 `lib/env.ts`의 `env`로만 읽는다 | `eslint.config.mjs` (`process.env` 직접 접근 금지), `lib/env.ts` | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| 경고도 실패로 본다 | `package.json` `lint` (`--max-warnings=0`) | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| `npm run check`(타입 검사와 린트)가 통과해야 작업이 끝난다 | `.claude/settings.json` Stop 훅, 루트 `CLAUDE.md` | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| 파일을 고칠 때마다 그 파일을 린트한다 | `.claude/settings.json` PostToolUse 훅 | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| `.env` 파일을 읽지 않는다 | `.claude/settings.json` `permissions.deny` | [0001](adr/0001-ai-coding-rule-enforcement.md) |
| `_docs/raw/`에 이미 있는 파일은 고치지 않는다. 새 원본 저장은 허용한다 | `.claude/hooks/protect-raw.mjs` (PreToolUse 훅) | [0002](adr/0002-raw-protection-in-repo.md) |
| Sentry는 `lib/sentry.ts`의 `sentryOptions`로만 초기화한다. 세션 리플레이를 넣지 않고, `dataCollection`으로 사용자 정보, HTTP 본문, LLM 입출력, 로컬 변수 수집을 끈다 | `lib/sentry.ts`, `instrumentation.ts`, `instrumentation-client.ts` | [0005](adr/0005-sentry-error-monitoring.md) |
| 오류 정보(breadcrumb, extra, context)에 질문 원문과 이메일을 넣지 않는다 | 코드 리뷰 (기계 검사 없음) | [0005](adr/0005-sentry-error-monitoring.md) |
| DB는 `lib/db`의 `getDb()`로만 접근하고, 테이블은 `lib/db/schema.ts`에만 정의한다. 이 모듈을 클라이언트 컴포넌트에서 import하면 빌드가 실패한다 | `lib/db/index.ts` (`server-only`) | [0003](adr/0003-neon-postgres-drizzle.md) |

## 설계 결정

| 번호 | 결정 | 상태 |
| --- | --- | --- |
| [0001](adr/0001-ai-coding-rule-enforcement.md) | AI 코딩 규칙은 md보다 검사 도구로 강제한다 | 확정 |
| [0002](adr/0002-raw-protection-in-repo.md) | raw 원본 수정 차단은 저장소의 Claude Code 훅으로 한다 | 확정 |
| [0003](adr/0003-neon-postgres-drizzle.md) | 기록 저장은 Neon Postgres에 하고, Drizzle ORM으로 접근한다 | 확정 |
| [0004](adr/0004-social-login.md) | 소셜 로그인으로 학습자를 구분한다 (인증 도구와 공급자는 정하지 않았다) | 확정 |
| [0005](adr/0005-sentry-error-monitoring.md) | 오류 모니터링은 Sentry 무료 요금제로 하고, 알림은 Apps Script로 Slack에 보낸다 | 확정 |

## 아직 도입하지 않은 규칙

0001에서 스택이 확정된 뒤로 미룬 규칙이다. 도입하면 위 "적용된 규칙"으로 옮긴다.

| 규칙 | 기다리는 결정 |
| --- | --- |
| SDK import 경계 (`lib/llm/`에서만 허용) | LLM 연결 방식은 `@anthropic-ai/sdk`로 정했으므로 도입할 수 있다 |
| 모델 ID 하드코딩 금지 | AI 모델 선택 (11/2까지 보류) |
| `lib/db` 밖 서버 코드의 `server-only` 적용 위치 | 서버 코드의 디렉터리 구조 |
| Edge runtime 금지, `cacheComponents` 관련 규칙 | Next.js 설정을 유지할지 여부 |
| `.claude/rules/` 경로별 규칙과 기준 예시 파일 | 디렉터리 구조 |
| 테스트 도구, CI, pre-commit | 의존성과 배포 방식 |

LLM 출력 스키마 규칙은 이번 스프린트에서 AI가 개념을 고르거나 문제를 만들지 않아 필요하지 않다. (근거: `raw/2026-10-30-tech-stack-decisions.md` "확정한 것")

## 확인 필요

- 0001과 0002는 Claude Code에서만 동작한다. 다른 에이전트는 `npm run check`를 직접 실행해야 같은 기준을 지킨다.
