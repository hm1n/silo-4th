# 0001. AI 코딩 규칙은 md보다 검사 도구로 강제한다

- 상태: 확정
- 결정 날짜: 2026-10-30
- 결정한 사람: 개발자
- 관련 문서: [AI 코딩 규칙 강제 방안](../../raw/2026-10-30-ai-harness-rules.md), [기술 스택](../tech-stack.md)

## 상황

AI가 규칙을 지키며 일관된 코드를 쓰게 할 방법이 필요했다. 결정 시점의 코드베이스는 `create-next-app` 템플릿 상태였고, 규칙은 `AGENTS.md`의 Next.js 관리 블록과 `_docs/CLAUDE.md`에만 있었다. 기술 스택을 새로 정해진 사항에 맞게 수정하는 작업이 진행 중이어서, 스택에 따라 달라지는 규칙은 아직 정할 수 없었다. (근거: `raw/2026-10-30-ai-harness-rules.md` "배경")

## 결정

기계로 검사할 수 있는 규칙은 타입 검사, 린트, Claude Code 훅으로 강제하고, md에는 이유와 완료 기준만 남긴다. 지금은 스택이 바뀌어도 유지되는 규칙만 도입하고, 스택에 의존하는 규칙은 스택이 확정된 뒤에 도입한다.

지금 도입하는 규칙은 다음과 같다.

| 규칙 | 적용 위치 |
| --- | --- |
| `noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch` | `tsconfig.json` |
| `no-explicit-any`, `consistent-type-imports`, `process.env` 직접 접근 금지 | `eslint.config.mjs` |
| 경고도 실패로 처리 (`--max-warnings=0`) | `package.json` `lint` |
| `typecheck`, `check` 스크립트 | `package.json` |
| env 단일 진입점 | `lib/env.ts` |
| 파일 수정 직후 린트 | `.claude/settings.json` PostToolUse 훅 |
| 검사를 통과해야 작업 종료 | `.claude/settings.json` Stop 훅 |
| `.env` 읽기 차단 | `.claude/settings.json` `permissions.deny` |
| 완료 기준 명시 | 루트 `CLAUDE.md` |

스택 확정 뒤로 미룬 규칙은 SDK import 경계, 모델 ID 하드코딩 금지, `server-only` 적용 위치, LLM 출력 스키마, Edge runtime 금지, 경로별 규칙(`.claude/rules/`), 테스트 도구, CI, pre-commit이다. (근거: `raw/2026-10-30-ai-harness-rules.md` "스택 확정 뒤로 미룬 규칙")

## 검토한 대안

| 대안 | 장점 | 단점 | 택하지 않은 이유 |
| --- | --- | --- | --- |
| md 규칙만 작성 | 만들기 쉽고 이유를 함께 설명할 수 있다 | AI가 따르지 않아도 막을 방법이 없다 | 규칙을 어겼을 때 실패하지 않으면 일관성을 보장할 수 없다 |
| 스택 확정 뒤 한 번에 도입 | 규칙을 다시 고칠 일이 없다 | 그동안 쌓인 코드는 규칙 없이 작성된다 | 스택과 무관한 규칙은 지금 넣어도 바뀔 일이 없다 |

## 결과

- 규칙을 어기면 검사가 실패하고, 그 에러가 AI에게 전달되어 스스로 고치게 된다.
- Stop 훅 때문에 코드를 바꾼 턴은 끝날 때마다 타입 검사와 린트 시간이 추가된다.
- 훅은 Claude Code에서만 동작하므로 다른 에이전트는 `npm run check`를 직접 실행해야 같은 기준을 지킨다.

## 다시 검토할 조건

- 기술 스택이 확정되면 미룬 규칙을 도입하는 새 ADR을 만든다.
- Stop 훅 때문에 작업 흐름이 눈에 띄게 느려지면 검사 범위를 다시 정한다.
