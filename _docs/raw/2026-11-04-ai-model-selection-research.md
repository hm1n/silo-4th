---
source: Claude Code 세션 대화와 웹 조사 결과
title: 질문 답변 AI 모델 조사와 정한 모델
retrieved: 2026-11-04
provider: 개발자
note: Linear 4-60 "열린 질문"의 AI 모델 선택에서 시작했다. Claude가 질문 서버 코드를 읽고 Anthropic 공식 문서와 비교 사이트를 조사해 모델을 제안했고, 개발자가 그 제안대로 정했다. 공식 문서의 수정 시각은 페이지에 표시되지 않아 조회 날짜만 적는다. 출처마다 공식 문서인지 비공식 자료인지 함께 적었다.
---

# 질문 답변 AI 모델 조사와 정한 모델

## 배경

`wiki/tech-stack.md`는 11/2까지 같은 질문으로 모델을 비교해 정하고, 11/4 기능 동결 뒤에는 바꾸지 않는다고 적었다. 11/4까지 정하지 못했고, 질문 서버는 `.env.example` 기본값인 `claude-opus-5-5`와 effort `low`로 동작하고 있었다. 개발자는 비교 테스트를 돌릴 시간이 부족하고 공식 문서에 정리된 자료가 있으므로, 조사 결과만으로 모델을 정하기로 했다.

## 질문 기능의 특성

2026-11-04 `4-60` 브랜치 코드를 기준으로 확인했다.

- `lib/llm/answer.ts`는 질문 하나에 Claude를 한 번 호출하고 답을 스트리밍한다. 이전 대화를 넘기지 않고, 도구 호출이나 에이전트 루프가 없다.
- 시스템 프롬프트에 학습자가 읽던 단원 본문을 넣고 캐시를 건다. 사용자 메시지는 질문 하나이고, 길이는 4,000자까지다.
- `max_tokens`는 16000, effort는 `low`이고, `thinking`은 따로 정하지 않는다. 모델은 환경 변수 `ANTHROPIC_MODEL`로 정한다.
- 첫 글자 60초, 전체 240초 제한이 있고, 화면은 10초가 지나면 기다리는 중이라는 문구로 바꾼다. 근거는 `raw/2026-11-04-ai-error-retry-research.md`다.
- 학습자는 8명이다. 근거는 `output/2026-11-03-question-server.md`다.

단원 본문을 근거로 한 번 답하는 질의응답이라, 긴 추론이나 에이전트 작업이 필요하지 않다.

## 조사한 내용

| 항목 | Opus 5.5 | Sonnet 5.5 | Haiku 5.5 | 출처 | 구분 |
| --- | --- | --- | --- | --- | --- |
| 공식 설명 | 오래 걸리는 에이전트 코딩과 지식 작업용 | 속도와 지능의 균형이 가장 좋다 | 분류, 추출, 라우팅 같은 대량, 저지연 작업용 | [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview) | 공식 |
| 입력, 출력 가격, 100만 토큰당 | $4, $20 | $2, $10 | $0.10, $0.50. 프롬프트가 10만 토큰을 넘으면 $0.50, $2.50 | [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview), [Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/overview) | 공식 |
| 캐시 읽기, 100만 토큰당 | $0.20 | $0.10 | $0.01 | [Sonnet 5.5](https://platform.claude.com/docs/en/models/sonnet-5-5/overview), [Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/overview) | 공식 |
| 상대 지연 | 보통 | 빠름 | 가장 빠름 | [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview) | 공식 |
| 기본 effort | `medium` | `high` | `medium` | [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview) | 공식 |
| 생각 끄기 | 끌 수 없고 effort로만 조절한다 | `between_tools`로 미리 생각하기를 끌 수 있다 | `high` 이하에서 끌 수 있다 | [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview), [What's new in Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/whats-new-haiku-5-5) | 공식 |
| 안전 분류기가 거절했을 때 서버 쪽 대체 모델 | 지원한다 | 지원한다 | 지원하지 않는다 | [What's new in Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/whats-new-haiku-5-5) | 공식 |
| 최소 캐시 길이 | 확인하지 않았다 | 512토큰 | 512토큰 | [Sonnet 5.5](https://platform.claude.com/docs/en/models/sonnet-5-5/overview), [Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/overview) | 공식 |
| 첫 응답 중앙값 | 약 4.5초 | 약 3.0초 | 측정치를 찾지 못했다 | [OrcaRouter 비교](https://www.orcarouter.ai/compare/claude-opus-5.5-vs-claude-sonnet-5.5) | 비공식 |
| 출력 속도 | 약 96 tok/s | 약 140 tok/s | 측정치를 찾지 못했다 | [OrcaRouter 비교](https://www.orcarouter.ai/compare/claude-opus-5.5-vs-claude-sonnet-5.5) | 비공식 |
| 종합 점수 | 9.0 | 9.0 | 없음 | [OrcaRouter 비교](https://www.orcarouter.ai/compare/claude-opus-5.5-vs-claude-sonnet-5.5) | 비공식 |

- 세 모델 모두 컨텍스트 100만 토큰, 최대 출력 128K 토큰, 지식 기준 2026년 6월이다. 출처는 [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview)이고 공식 자료다.
- 공식 모델 선택 안내는 같은 모델 안에서 effort를 조절하는 편이 모델을 바꾸는 것보다 나은 경우가 많다고 한다. 실시간 응답과 비용에 민감한 작업은 Haiku 5.5부터, 복잡한 추론이나 정확도가 비용보다 중요한 작업은 Opus 5.5부터 시작하라고 한다. 출처는 [Choosing a model](https://platform.claude.com/docs/en/about-claude/models/choosing-a-model)이고 공식 자료다.
- OrcaRouter의 지연 수치는 측정 시점마다 다르다. 9월 페이지에는 Opus 5.5의 첫 응답 중앙값이 10초로 적혀 있었다.

## 비용 추정

단원 본문 4,000토큰, 질문 100토큰, 생각과 답을 합친 출력 1,000토큰으로 가정한 추정이다. 실제 단원 길이와 답 길이는 재지 않았다.

| | Opus 5.5 | Sonnet 5.5 | Haiku 5.5 |
| --- | --- | --- | --- |
| 질문 1건, 캐시 없음 | 약 $0.036 | 약 $0.018 | 약 $0.001 |
| 질문 1건, 캐시 적중 | 약 $0.021 | 약 $0.011 | 약 $0.001 |
| 질문 1,000건 | 약 $21~36 | 약 $11~18 | 약 $1 |

8명이 하루 20개씩 일주일 동안 물으면 1,000건 남짓이다. 어느 모델을 골라도 비용은 수십 달러 안쪽이라, 비용보다 답의 정확도와 응답 속도가 선택 기준이 된다.

## 정한 모델

개발자가 2026-11-04에 질문 답변 모델을 Claude Sonnet 5.5 `claude-sonnet-5-5`, effort `low`로 정했다. 같은 질문으로 모델을 비교하는 테스트는 하지 않았다.

1. Opus 5.5가 앞서는 분야는 장시간 에이전트 작업과 복잡한 코딩이라, 단원 본문을 근거로 한 번 답하는 질의응답에서는 차이가 작다고 봤다. Sonnet 5.5는 가격이 절반이다.
2. Sonnet 5.5는 비공식 측정에서 첫 응답이 Opus 5.5보다 약 33% 빠르고 출력 속도는 약 1.5배다. 10초 문구와 60초 제한에 걸릴 일이 줄어든다.
3. Haiku 5.5는 공식 설명이 분류와 추출용이고, 시험 공부에서 틀린 설명은 피해가 크다. 아낄 수 있는 금액은 일주일에 수십 달러 수준이고, 거절됐을 때 서버 쪽 대체 모델도 쓸 수 없다.
4. 지금 코드는 `thinking`을 정하지 않고 effort `low`만 넘기므로 Sonnet 5.5에서도 코드를 고치지 않아도 된다. Vercel의 `ANTHROPIC_MODEL` 값만 바꾸면 된다.

## 남은 위험

- 비교 테스트를 하지 않아, Sonnet 5.5 `low`의 한국어 답 품질은 운영에서 처음 확인한다.
- 시험 분야가 안전 분류기의 `cyber`, `bio` 범주에 가깝다면 정상 질문이 거절될 수 있다. 지금 코드는 거절되면 `error`로 끝난다. 서버 쪽 대체 모델 `fallbacks: "default"`는 넣지 않았다.
- 단원 본문이 512토큰보다 짧으면 캐시가 걸리지 않는다.
