# 0002. raw 원본 수정 차단은 저장소의 Claude Code 훅으로 한다

- 상태: 확정
- 결정 날짜: 2026-10-30
- 결정한 사람: 개발자
- 수정: 2026-10-30, `permissions.deny`의 `Edit(_docs/raw/**)`를 빼고 훅만으로 막도록 고쳤다
- 관련 문서: [AI 코딩 규칙 강제 방안](../../raw/2026-10-30-ai-harness-rules.md), [0001. AI 코딩 규칙은 md보다 검사 도구로 강제한다](0001-ai-coding-rule-enforcement.md)

## 상황

`_docs/CLAUDE.md`는 raw에 저장한 파일을 고치지 않는다고 정하고 있다. 결정 시점에는 이 규칙을 개발자 개인 환경의 Claude Code mod(docs-guard)가 강제하고 있었다. mod는 다른 기기나 클라우드 세션에서는 동작하지 않고, 제약이 있다는 사실이 저장소에 남지 않았다. (근거: `raw/2026-10-30-ai-harness-rules.md` "`_docs/raw` 수정 차단 방식")

## 결정

raw 차단 규칙을 저장소의 `.claude/settings.json`으로 옮긴다. PreToolUse 훅(`.claude/hooks/protect-raw.mjs`)이 `_docs/raw/` 아래 이미 있는 파일을 고치려는 작업만 막고, 새 원본 저장은 허용한다. `permissions.deny`에는 raw 관련 규칙을 넣지 않는다. Claude Code에서 `Edit(...)` 권한 규칙은 Write에도 적용되어, `Edit(_docs/raw/**)`를 deny하면 새 원본 저장까지 막히기 때문이다.

docs-guard mod는 끄지 않고 raw 차단 규칙만 뺀다. 새 문서 생성 전 확인과 log.md 기록 알림은 settings로 대신할 수 없기 때문이다.

## 검토한 대안

| 대안 | 장점 | 단점 | 택하지 않은 이유 |
| --- | --- | --- | --- |
| mod 유지 | 이미 동작하고 있다 | 개인 환경에서만 동작하고 저장소에 기록이 없다 | 다른 실행 환경에서 규칙이 빠진다 |
| `permissions.deny`에 `Write(_docs/raw/**)`까지 추가 | 설정 한 줄로 끝난다 | 새 원본을 저장하는 일도 막힌다 | raw에 자료를 추가하는 정상 작업을 할 수 없다 |
| 훅과 함께 `permissions.deny`에 `Edit(_docs/raw/**)` 추가 | 훅이 실패해도 한 번 더 막는다 | Edit 규칙이 Write에도 적용되어 새 원본 저장이 막힌다 | 처음에는 이 방식으로 정했지만, 실제로 새 원본 저장이 막혀 2026-10-30에 뺐다 |
| mod를 완전히 끄기 | 규칙을 관리하는 곳이 하나가 된다 | 생성 확인과 기록 알림 기능을 잃는다 | settings로 대신할 수 없는 기능이다 |

## 결과

- 저장소를 clone한 모든 Claude Code 환경에서 raw 원본이 보호되고, 규칙이 git 이력에 남는다.
- Bash 명령(`sed -i` 등)으로 고치는 경우와 Claude Code가 아닌 에이전트는 막지 못한다. `_docs/CLAUDE.md`의 문장 규칙은 이 빈틈을 설명하는 용도로 유지한다.
- `_docs` 규칙이 저장소 훅과 개인 mod 두 곳에 나뉘어 있다.

## 다시 검토할 조건

- 다른 에이전트로 raw를 다루게 되면 git pre-commit 검사를 추가할지 검토한다.
- docs-guard의 나머지 기능을 저장소로 옮길 방법이 생기면 mod를 끄는 방안을 다시 본다.
