---
source: Claude Code 세션 대화와 웹 조사 결과
title: AI 응답 오류와 재시도 처리 조사, 정한 정책
retrieved: 2026-11-04
provider: 개발자
note: Linear 4-59 SSE 구현 뒤, 오래 멈춘 `pending`을 5분 기다리게 하는 방식이 학습자에게 맞지 않는다는 개발자의 판단에서 시작했다. Claude가 웹에서 조사하고 정책을 제안했고, 개발자가 그 정책을 쓰기로 정했다. 출처마다 공식 문서인지 비공식 자료인지 함께 적었다.
---

# AI 응답 오류와 재시도 처리 조사, 정한 정책

## 배경

4-59에서 질문 서버를 SSE 스트리밍으로 만들었다. 답을 만드는 함수가 중간에 죽으면 질문이 `pending`에 남고, 같은 질문 ID로 다시 보내도 409를 받는다. 처음 제안은 `attempted_at` 컬럼을 더해 5분이 지난 `pending`을 서버가 다시 가져가는 방식이었다. 개발자는 학습자가 5분을 기다리는 것은 맞지 않다고 보고, 다른 AI 서비스가 멈춘 응답과 오류, 재시도를 어떻게 처리하는지 먼저 조사하자고 했다.

## 조사한 내용

| 주제 | 내용 | 출처 | 자료 성격 |
| --- | --- | --- | --- |
| ChatGPT가 끊긴 답을 다루는 방식 | 스트리밍 도중 연결이 끊기면 "network error"를 보여 주고, 사용자가 Regenerate로 다시 만든다. 긴 답에서 자주 생긴다 | [ChatGPT network error 가이드](https://gptprompts.ai/ai-errors-and-fixes/chatgpt-network-error), [OpenAI 커뮤니티 글](https://community.openai.com/t/chat-gpt-4-gives-network-error-after-80-of-generation/108287) | 비공식 |
| Claude.ai가 끊긴 답을 다루는 방식 | 답이 끊기면 Retry 버튼으로 같은 질문의 답을 다시 만든다 | [Claude.ai retry 가이드](https://www.guideflow.com/tutorial/how-to-retry-a-response-in-a-chat-in-claudeai) | 비공식 |
| AI SDK의 오류 화면 | 사용자에게는 "Something went wrong" 같은 일반 메시지를 보여 줘 서버 정보를 드러내지 않는다. 예제는 오류가 있으면 Retry 버튼으로 `regenerate()`를 불러 새 요청을 보낸다 | [AI SDK Error Handling](https://ai-sdk.dev/docs/ai-sdk-ui/error-handling) | 공식 |
| 끊긴 스트림에 다시 붙기, AI SDK | Redis에 스트림을 저장하고, 채팅마다 진행 중인 스트림 ID를 따로 저장해야 한다. 화면은 GET 요청으로 다시 붙는다. 탭을 닫거나 새로 고쳐도 생성은 계속된다 | [AI SDK Resume Streams](https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams) | 공식 |
| 끊긴 스트림에 다시 붙기, OpenAI | background 모드는 오래 걸리는 작업용이다. `queued`, `in_progress` 동안 폴링하고, 스트림 이벤트의 `sequence_number`를 기록했다가 `starting_after`로 이어 받는다 | [OpenAI Background mode](https://developers.openai.com/api/docs/guides/background) | 공식 |
| Claude API 오류와 SDK 재시도 | SDK는 연결 오류, 429, 5xx를 지수 백오프로 기본 2번 다시 시도하고 `retry-after`를 따른다. 스트림은 200 응답 뒤에도 중간에 오류 이벤트가 올 수 있다 | [Claude API errors](https://platform.claude.com/docs/en/api/errors) | 공식 |
| Claude 스트림 이벤트 | 스트림에는 `ping` 이벤트가 섞여 올 수 있고, 사용량이 많을 때는 `overloaded_error` 이벤트가 올 수 있다 | [Claude Streaming](https://platform.claude.com/docs/en/build-with-claude/streaming) | 공식 |
| 재시도 원칙 | 재시도는 스택의 한 지점에서만 한다. 지수 백오프에 무작위 지연을 더한다. 부작용이 있는 API는 멱등성이 없으면 다시 보내면 안 된다. 재시도가 가용성을 높이지 못하면 멈춘다 | [AWS Builders' Library, Timeouts, retries and backoff with jitter](https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter) | 공식 |
| 기다림의 한계 | 0.1초, 1초, 10초가 기준이다. 10초가 넘으면 사용자의 주의가 흩어지므로 언제 끝날지 알려 줘야 한다 | [NN/g Response Times](https://www.nngroup.com/articles/response-times-3-important-limits/) | 공식 |
| 멈춘 작업을 시간으로 판단할 때의 위험 | 작업자가 멈춘 사이 시간 기준이 만료되면 작업자는 그 사실을 모른 채 쓸 수 있다. 늘어나는 번호인 펜싱 토큰으로 늦은 쓰기를 거부해야 한다 | [Kleppmann, How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html) | 공식 |
| 연결 유지 | HTTP/1.1 클라이언트와 중간 장비는 조용한 연결을 끊을 수 있으므로, 작업 중에는 진행 데이터나 하트비트를 보내라고 권한다 | [Vercel 함수 실행 시간](https://vercel.com/docs/functions/configuring-functions/duration) | 공식 |
| Vercel Hobby cron | 하루 한 번만 실행할 수 있고, 실행 시각은 정한 시각부터 59분 사이로 흔들린다 | [Vercel Cron Jobs 사용량](https://vercel.com/docs/cron-jobs/usage-and-pricing) | 공식 |
| `after`의 실행 시간 | `waitUntil`에 넘긴 작업은 함수와 같은 제한 시간을 받고, 시간이 지나면 함께 취소된다. Next.js 15.1 이상은 `after`가 이를 쓴다 | [Vercel Functions API](https://vercel.com/docs/functions/functions-api-reference/vercel-functions-package) | 공식 |

공식 Help Center에서 ChatGPT와 Claude.ai의 처리 방식을 설명한 글은 찾지 못했다. 두 서비스의 동작은 비공식 자료로만 확인했다.

## 정한 정책

개발자가 2026-11-04에 아래 정책을 쓰기로 정했다. 핵심은 학습자가 `pending`을 기다리지 않게 하는 것이다. 서버가 멈춘 줄을 다시 가져가지 않고, 화면이 새 질문 ID로 바로 다시 묻는다. 그래서 `attempted_at` 마이그레이션은 하지 않는다.

1. 재시도는 한 계층에서만 한다. Claude 오류는 SDK 기본 재시도 2번에 맡기고, 첫 글자가 오기 전에만 동작한다. 답이 중간에 실패하면 서버는 다시 시도하지 않고 `error`로 끝낸다. 화면은 자동으로 다시 보내지 않고 학습자가 누른 "다시 시도"만 보낸다.
2. 보내자마자 "답을 준비하고 있어요"를 보여 주고, 10초가 지나도 첫 글자가 없으면 기다리는 중이라는 문구로 바꾼다.
3. 서버는 첫 글자 60초, 전체 240초 안에 끝나지 않으면 끊고 `error`를 보낸다. 60초는 운영하며 조정할 출발값이다.
4. 서버는 답을 기다리는 동안 15초마다 SSE 주석을 보내 연결을 유지한다.
5. "다시 시도"는 상황별로 처리한다.

| 상황 | 화면 처리 |
| --- | --- |
| `error` 이벤트를 받음 | 일반 문구와 "다시 시도"를 보여 준다. 같은 질문 ID로 보내 같은 줄에서 다시 답한다. 05-1 규칙과 같다 |
| `done`이나 `error` 없이 스트림이 끊김 | "응답이 끊겼어요"와 "다시 시도"를 보여 준다. 같은 질문 ID로 보내고, 서버가 이미 답을 저장했다면 그 답을 바로 받는다 |
| 다시 보냈는데 409 | 기다리지 않고 같은 질문 내용을 새 질문 ID로 바로 보낸다 |

6. 남은 `pending`은 05-1 규칙대로 5분이 지나면 기록 화면과 지표에서 `error`로 해석한다. DB는 고치지 않는다.
7. 오류 문구는 일반 문구로 보여 주고 서버 오류 내용은 화면에 보내지 않는다.

## 받아들인 비용과 넣지 않은 것

- 409 뒤에 새 ID로 보낼 때 예전 요청이 살아 있으면 같은 질문에 AI 답이 두 번 만들어지고, 기록에 같은 질문이 두 줄 남을 수 있다. 연결이 끊긴 뒤 다시 시도할 때만 생기고, 학습자 8명 규모라 받아들였다.
- 끊긴 스트림에 다시 붙는 기능은 Redis나 별도 저장소가 필요해 넣지 않았다.
- 서버가 멈춘 줄을 5분보다 빨리 가져가는 방식은 펜싱 토큰과 컬럼 추가가 필요해 넣지 않았다.
- 같은 학습자에게 `pending`이 있으면 새 질문을 409로 막는 안은 받지 않는다. 남은 `pending`이 그 학습자의 새 질문을 모두 막기 때문이다.

## 나눈 작업

- 4-59 서버에서 할 일은 3번과 4번이다. 노션 Test-case DB에 TC-48과 TC-49를 검토 중으로 더했다.
- 나머지는 4-60 질문 창에서 한다.
