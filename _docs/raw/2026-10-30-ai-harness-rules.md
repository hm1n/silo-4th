---
source: Claude Code 세션 대화 (개발자와 Claude의 논의)
title: AI 코딩 규칙 강제 방안
retrieved: 2026-10-30
provider: 개발자
note: 대화에서 정한 내용을 정리해 저장했다. 기술 스택을 수정하는 작업이 진행 중인 시점의 결정이다.
---

# AI 코딩 규칙 강제 방안

## 배경

AI가 규칙을 더 잘 지키고 일관된 코드를 쓰도록 강제할 방법을 논의했다. 논의 시점의 코드베이스는 `create-next-app` 템플릿 상태였고, 규칙은 `AGENTS.md`의 Next.js 관리 블록과 `_docs/CLAUDE.md`에만 있었다. 기술 스택을 새로 정해진 사항에 맞게 수정하는 작업이 진행 중이어서, 스택이 확정되기 전에 도입할 수 있는 규칙과 확정 뒤로 미룰 규칙을 나눴다.

## 원칙

기계로 검사할 수 있는 규칙은 md에 적지 않고 린트, 타입 검사, 훅으로 강제한다. md 규칙은 AI가 따르지 않을 수 있지만, 검사 도구는 실패하고 그 에러가 AI에게 돌아가 스스로 고치게 만들기 때문이다. md에는 이유, 완료 기준처럼 기계로 판단하기 어려운 내용만 남긴다.

## 스택 확정 전에 도입할 규칙

스택이 바뀌어도 유지되는 규칙만 골랐다.

| 규칙 | 이유 |
| --- | --- |
| tsconfig 추가 옵션 (`noUncheckedIndexedAccess`, `noImplicitOverride`, `noFallthroughCasesInSwitch`) | TypeScript 설정이라 프레임워크나 라이브러리와 관계없이 유지된다. |
| `no-explicit-any: error` | AI가 타입 문제를 `any`로 덮고 넘어가는 일을 막는다. |
| `consistent-type-imports` | import 스타일이 파일마다 달라지지 않게 맞춘다. |
| `eslint --max-warnings=0` | 경고가 쌓이면 AI가 그 코드를 따라 해도 되는 패턴으로 받아들인다. |
| `typecheck`, `check` 스크립트 | 어떤 스택이든 "검사 명령 하나가 통과하면 완료"라는 기준은 같다. |
| env 단일 진입점 (`lib/env.ts`) | 어떤 외부 서비스를 붙이더라도 키를 읽는 위치를 한 곳으로 모은다. |
| `process.env` 직접 접근 금지 (lint) | env 단일 진입점을 실제로 지키게 강제한다. |
| PostToolUse 린트 훅 | 파일을 고칠 때마다 검사하는 방식이라 스택과 관계없다. |
| Stop 훅 (`npm run check`) | 검사를 통과하기 전에는 AI가 작업을 끝냈다고 말하지 못하게 막는다. |
| `_docs/raw/**` 수정 차단 | 원본 보존 규칙이 md에만 있으면 실제로 막지 못한다. |
| `.env` 읽기 차단 (`permissions.deny`) | 어떤 서비스를 쓰든 키가 AI 컨텍스트에 들어가지 않게 한다. |
| 루트 `CLAUDE.md` (`@AGENTS.md` import와 완료 기준) | 디렉터리 지도를 빼고 완료 기준만 적으면 스택이 바뀌어도 고칠 내용이 없다. |

이 가운데 Stop 훅과 `_docs/raw` 수정 차단을 가장 먼저 도입할 대상으로 꼽았다. 다른 작업과 충돌하지 않고 효과가 바로 나타나기 때문이다.

## 스택 확정 뒤로 미룬 규칙

| 규칙 | 기다리는 결정 |
| --- | --- |
| SDK import 경계 (`lib/llm/`에서만 허용) | LLM 연결 방식 (공식 SDK, AI SDK 등) |
| 모델 ID 하드코딩 금지 | 모델을 선택하고 바꾸는 방식 |
| `server-only` 적용 위치 | 서버 코드의 디렉터리 구조 |
| LLM 출력 zod 스키마 | 구조화 출력을 받는 API |
| Edge runtime 금지, `cacheComponents` 관련 규칙 | Next.js 설정을 유지할지 여부 |
| `.claude/rules/` 경로별 규칙과 기준 예시 파일 | 디렉터리 구조 |
| 테스트 도구, CI, pre-commit | 의존성과 배포 방식 |

## `_docs/raw` 수정 차단 방식

논의 시점에는 `_docs/raw` 수정 차단이 Claude Code의 mod로 적용되어 있었다. mod를 유지할지, 코드베이스에 제약을 기록할지 비교했다.

- mod는 개발자의 Claude Code에서만 동작한다. 다른 기기나 클라우드 세션에서는 적용되지 않고, 제약이 있다는 사실이 저장소에 남지 않는다.
- 코드베이스 제약(`.claude/settings.json`의 `permissions.deny`)은 저장소를 clone한 모든 환경에서 적용되고 git 이력에 남는다. 다만 Claude Code에서만 동작하므로 다른 에이전트(Codex, Cursor 등)는 막지 못한다.
- 혼자 개발하는 상황이라 공유 이점은 작지만, 규칙의 기록과 실행 환경 간 일관성은 여전히 가치가 있다.

개발자는 아래 방식으로 진행하기로 정했다.

1. `.claude/settings.json`에 `"deny": ["Edit(_docs/raw/**)", "Write(_docs/raw/**)"]`를 넣고 커밋해 차단 기준을 저장소 한 곳에 둔다.
2. 같은 규칙을 두 곳에서 관리하면 한쪽만 고쳐져 어긋날 수 있으므로 mod는 끈다. 단, mod가 차단 시 알림처럼 settings로 대신할 수 없는 기능을 하고 있다면 mod는 남기고 차단 기준만 settings로 옮긴다.
3. `_docs/CLAUDE.md`의 "저장한 파일은 고치지 않는다" 규칙은 유지한다. 차단 이유를 설명하고, settings를 읽지 않는 다른 에이전트에게도 규칙을 전달하기 때문이다.

## 확인 필요

- `permissions.deny`에 `Write(_docs/raw/**)`를 넣으면 raw에 새 원본을 저장하는 일도 막힌다. 새 파일 생성은 허용하고 기존 파일 수정만 막으려면 deny 대신 PreToolUse 훅으로 "이미 있는 파일인지"를 검사해야 한다.
- 이 문서를 저장한 시점에는 위 규칙을 아직 코드베이스에 적용하지 않았다.
