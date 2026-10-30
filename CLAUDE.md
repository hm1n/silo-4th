@AGENTS.md

# 작업 규칙

## 완료 기준

- 코드를 바꿨다면 `npm run check`(타입 검사와 린트)가 통과해야 작업이 끝난 것이다. Stop 훅이 이를 강제한다.
- 경고도 실패로 본다. 규칙을 끄는 주석(`eslint-disable`, `@ts-ignore`)으로 넘어가지 않는다.

## 코드 규칙

- 환경 변수는 `lib/env.ts`의 `env`로만 읽는다.
- 타입을 `any`로 덮지 않는다.

## 문서

- 프로젝트 자료는 `_docs/`에 있고, 작업 규칙은 `_docs/CLAUDE.md`를 따른다.
- 모든 개발 규칙은 `_docs/wiki/dev-rules.md`에서 볼 수 있고, 규칙을 왜 이렇게 정했는지는 `_docs/wiki/adr/`에 있다. 규칙을 바꾸려면 ADR을 먼저 만들거나 고친다.
