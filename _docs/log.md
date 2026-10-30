| 날짜 | 작업 | 결과 | 확인 필요 |
| --- | --- | --- | --- |
| 2026-10-28 | PO에게 받은 PRD(노션 공개 페이지)를 raw에 저장했다 | `raw/2026-10-28-prd-recall-learning-agent.md`를 만들었다 | 노션 원문이 수정되면 새 날짜 파일로 다시 저장해야 한다 |
| 2026-10-28 | PRD를 바탕으로 index.md를 작성했다 | 프로젝트 요약, raw 목록, PRD 장별 위치, 만들 wiki 문서 후보를 정리했다 | 판단 기준 숫자는 PRD의 제안 값이라 팀 확정이 필요하다 |
| 2026-10-28 | 개발자와 논의한 최소 기술 스택을 wiki에 정리했다 | `wiki/tech-stack.md`를 만들고 index.md에 추가했다 | DB는 핵심 기능이 정해진 뒤 도입 여부를 판단한다 |
| 2026-10-28 | 설계 결정을 기록할 ADR 폴더를 만들었다 | `wiki/adr/_template.md`를 만들고 index.md에 ADR 목록 칸을 추가했다 | 기존 `tech-stack.md`의 결정을 ADR로 옮길지 정해야 한다 |
| 2026-10-30 | Claude Code 세션에서 개발자와 논의한 AI 코딩 규칙 강제 방안을 raw에 저장했다 | `raw/2026-10-30-ai-harness-rules.md`를 만들었다. 스택 확정 전에 도입할 규칙, 미룰 규칙, `_docs/raw` 차단을 mod에서 `.claude/settings.json`으로 옮기는 결정을 담았다 | `Write(_docs/raw/**)`를 deny하면 새 원본 저장도 막히므로 deny와 PreToolUse 훅 중 무엇으로 차단할지 정해야 한다. 규칙은 아직 코드베이스에 적용하지 않았다 |
| 2026-10-30 | `raw/2026-10-30-ai-harness-rules.md`의 결정을 ADR 두 건으로 정리하고 코드베이스에 반영했다 | `wiki/adr/0001-ai-coding-rule-enforcement.md`(검사 도구로 강제, 스택 무관 규칙만 도입)와 `0002-raw-protection-in-repo.md`(raw 차단을 저장소 훅으로 이전)를 만들었다. tsconfig, eslint, package.json 스크립트, `lib/env.ts`, `.claude/settings.json` 훅 3개, 루트 `CLAUDE.md`를 적용했고 `npm run check`가 통과했다. ADR 템플릿은 index.md ADR 목록에 추가하라고 하지만, index.md에 문서 목록을 두지 않는 CLAUDE.md 규칙을 따라 추가하지 않았다 | raw 문서의 "확인 필요"(deny와 훅 중 선택)는 0002에서 훅으로 정해 해소됐다. ADR 템플릿의 index.md 규칙을 CLAUDE.md에 맞게 고칠지 정해야 한다 |
