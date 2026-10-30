---
source: Claude Code 세션 대화 (개발자와 Claude의 논의)
title: 오류 모니터링 도구 결정 (Sentry)
retrieved: 2026-10-30
provider: 개발자
note: 대화에서 개발자가 정한 내용과 Claude가 조사한 근거를 정리해 저장했다. 요금제 수치는 대부분 제3자 비교 자료에서 가져왔으며, 링크는 2026-10-30에 확인했다.
---

# 오류 모니터링 도구 결정 (Sentry)

## 결정

개발자는 오류 모니터링 도구로 Sentry를 쓰기로 정했다. 오류 추적과 성능 모니터링이라는 본래 목적에 충실하고, Next.js 연동 품질이 좋으며, 알림으로 PO에게 오류를 전달할 수 있다는 점을 이유로 들었다.

## 논의 흐름

1. 저장소를 어디에 둘지 논의하면서, Vercel Hobby에서는 PO를 프로젝트 멤버로 추가할 수 없어 PO가 Vercel 대시보드에서 오류를 볼 수 없다는 점을 확인했다.
2. 개발자는 오류를 Sentry 같은 모니터링 도구로 받을 것이라 대시보드 권한은 필요 없다고 판단하고, Sentry 외의 무료 도구를 조사해 달라고 요청했다.
3. Claude는 PostHog, Sentry, Better Stack, GlitchTip 등을 비교했고, Sentry 무료 요금제가 사용자 1명으로 제한된다는 이유로 PostHog를 추천했다.
4. 두 도구를 다시 비교한 뒤, 개발자는 알림으로 PO에게 오류를 전달할 수 있다면 사용자 1명 제한은 문제가 되지 않는다고 보고 Sentry를 골랐다.

## 비교한 내용

| 기준 | Sentry | PostHog |
| --- | --- | --- |
| 주력 분야 | 오류 추적과 성능 모니터링 전문 도구다 | 제품 분석 도구에 오류 추적을 더한 형태다 |
| 무료 한도 | 오류 월 5천 건, 사용자 1명이다 | 예외 월 10만 건이다 |
| Next.js 연동 | `@sentry/nextjs` 공식 SDK가 서버, 클라이언트, edge 오류를 자동으로 잡는다 | 클라이언트 오류는 자동으로 잡지만 서버 쪽은 직접 연결해야 할 수 있다 |
| 오류 분석 | 소스맵, 그룹핑, 릴리스 추적, 알림 규칙이 성숙하다 | 기본 기능은 있지만 최근에 추가된 기능이다 |
| 분석 기능 | 없다 | 이벤트, 퍼널, 대시보드가 있다 |
| 개인정보 | 리플레이를 켜면 질문 원문이 수집될 수 있다 | 리플레이와 자동 수집이 기본으로 켜져 있을 수 있어 더 주의해야 한다 |

트레이드오프는 다음 한 줄로 정리했다. Sentry는 오류 추적의 품질과 Next.js 연동이 강하지만 무료로는 한 명만 볼 수 있고, PostHog는 팀이 함께 보면서 분석까지 할 수 있지만 오류 추적의 깊이와 개인정보 설정 부담에서 손해를 본다.

## 확인한 제약

- Vercel Hobby에서는 Drains를 쓸 수 없어, Vercel 로그를 받아 가는 방식의 도구는 후보에서 뺐다. Hobby의 런타임 로그는 1시간만 보관된다. ([Vercel Hobby Plan](https://vercel.com/docs/plans/hobby), 최종 수정 2026-09-14)
- Sentry 무료 요금제(Developer)는 사용자 1명이고 오류 월 5천 건이다. ([비교 자료](https://costbench.com/software/developer-tools/sentry/free-plan/))
- Sentry 무료 요금제는 이메일 알림을 지원하지만 Slack 알림은 Team 요금제 이상에서만 지원한다는 자료가 있다. ([Bugsink 비교 글](https://www.bugsink.com/blog/does-sentry-free-plan-support-slack-alerts/), 경쟁사 글이라 확인 필요)
- Sentry 조직 멤버가 아닌 외부 이메일로 알림을 보내는 기능은 Team 요금제 이상에 해당한다. 공식 지원 문서는 대안으로 받는 사람을 조직 멤버로 추가하라고 안내한다. ([Sentry 지원 문서](https://sentry.zendesk.com/hc/en-us/articles/41229927489819-Can-I-send-alerts-to-external-email-addresses))

## PO에게 알림을 전달하는 방법

무료 요금제에서는 Sentry가 PO에게 직접 알림을 보낼 수 없다. 그래서 Sentry 밖에서 전달한다.

- 개발자 메일함에 Sentry 알림 메일을 PO에게 자동 전달하는 필터를 건다. Sentry 요금제와 관계없이 동작한다.
- Sentry의 webhook으로 Slack에 보내는 비공식 방법도 있지만 검증하지 않았다.

## 함께 정한 주의 사항

- 세션 리플레이를 켜지 않는다. 학습자의 질문 원문이 외부 서비스로 넘어가면 `_docs/CLAUDE.md` 민감 정보 규칙과 PRD 7장의 개인정보 미확인 사항에 걸린다.
- 오류와 함께 보내는 정보(breadcrumb, extra, context)에 질문 원문과 이메일을 넣지 않는다.

## 확인 필요

- 메일 전달 필터로 PO가 알림을 실제로 받는지 11/6 오류 알림 설정 때 확인해야 한다.
- 요금제 수치와 알림 제한은 Sentry 공식 가격 페이지에서 다시 확인해야 한다.
