// 설계: _docs/wiki/prd/sentry-slack-alert.md
// Script Properties: SENTRY_TOKEN, SLACK_WEBHOOK_URL, SENTRY_ORG, SENTRY_PROJECT_ID

const SENTRY_API = "https://us.sentry.io/api/0";
const MAX_NOTIFIED_IDS = 100;

/**
 * @typedef {Object} Issue
 * @property {string} id
 * @property {string} shortId
 * @property {string} level
 * @property {string} errorType
 * @property {string} culprit
 * @property {string} count
 * @property {string} firstSeen
 * @property {string} permalink
 */

/** 처음 한 번 편집기에서 실행한다. 다시 실행해도 상태와 트리거가 늘지 않는다. */
function setup() {
  const props = PropertiesService.getScriptProperties();
  if (!props.getProperty("SINCE")) props.setProperty("SINCE", new Date().toISOString());
  if (!props.getProperty("NOTIFIED_IDS")) props.setProperty("NOTIFIED_IDS", "[]");

  const hasTrigger = ScriptApp.getProjectTriggers().some((t) => t.getHandlerFunction() === "run");
  if (!hasTrigger) ScriptApp.newTrigger("run").timeBased().everyMinutes(5).create();

  const issues = fetchIssues(props);
  console.log(`Sentry 조회 성공: SINCE 이후 이슈 ${issues.length}건`);
}

function run() {
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) return;
  try {
    const props = PropertiesService.getScriptProperties();
    const notified = JSON.parse(props.getProperty("NOTIFIED_IDS") || "[]");
    const fresh = selectNew(fetchIssues(props), notified);

    for (const issue of fresh) {
      postToSlack(props.getProperty("SLACK_WEBHOOK_URL"), formatMessage(issue));
      notified.push(issue.id);
      props.setProperty("NOTIFIED_IDS", JSON.stringify(notified.slice(-MAX_NOTIFIED_IDS)));
    }
  } finally {
    lock.releaseLock();
  }
}

/** @returns {Issue[]} */
function fetchIssues(props) {
  const query = encodeURIComponent(`firstSeen:>${props.getProperty("SINCE")}`);
  const url =
    `${SENTRY_API}/organizations/${props.getProperty("SENTRY_ORG")}/issues/` +
    `?project=${props.getProperty("SENTRY_PROJECT_ID")}&sort=new&limit=100&query=${query}`;
  const res = UrlFetchApp.fetch(url, {
    headers: { Authorization: `Bearer ${props.getProperty("SENTRY_TOKEN")}` },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) {
    throw new Error(`Sentry API 응답 ${res.getResponseCode()}`);
  }
  return parseIssues(JSON.parse(res.getContentText("UTF-8")));
}

/**
 * 질문 원문이 섞일 수 있는 title과 metadata.value는 읽지 않는다.
 * @returns {Issue[]}
 */
function parseIssues(raw) {
  return raw.map((r) => ({
    id: String(r.id),
    shortId: String(r.shortId),
    level: String(r.level),
    errorType: String((r.metadata && r.metadata.type) || "종류 없음"),
    culprit: String(r.culprit || "알 수 없음"),
    count: String(r.count),
    firstSeen: String(r.firstSeen),
    permalink: String(r.permalink),
  }));
}

/** sort=new라 최신순으로 오므로, 먼저 생긴 이슈부터 보내도록 뒤집는다. */
function selectNew(issues, notifiedIds) {
  const seen = new Set(notifiedIds);
  return issues.filter((issue) => !seen.has(issue.id)).reverse();
}

const LEVEL_LABELS = { fatal: "🔥 치명적 오류", error: "🚨 오류", warning: "⚠️ 경고", info: "ℹ️ 정보" };

/** text는 알림 미리보기에만 쓰이고, 채널에는 blocks가 보인다. */
function formatMessage(issue) {
  const label = LEVEL_LABELS[issue.level] || `🚨 ${issue.level}`;
  const at = Utilities.formatDate(new Date(issue.firstSeen), "Asia/Seoul", "M월 d일 HH:mm");
  const field = (name, value) => ({ type: "mrkdwn", text: `*${name}*\n${value}` });
  return {
    text: `${label}: ${escapeSlack(issue.errorType)} (${issue.shortId})`,
    blocks: [
      { type: "header", text: { type: "plain_text", text: `${label} · ${issue.shortId}` } },
      {
        type: "section",
        fields: [
          field("오류 종류", `\`${escapeSlack(issue.errorType)}\``),
          field("발생 위치", `\`${escapeSlack(issue.culprit)}\``),
          field("처음 발생", at),
          field("발생 횟수", `${issue.count}회`),
        ],
      },
      {
        type: "actions",
        elements: [{ type: "button", text: { type: "plain_text", text: "Sentry에서 보기" }, url: issue.permalink }],
      },
    ],
  };
}

function escapeSlack(text) {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function postToSlack(webhookUrl, message) {
  const res = UrlFetchApp.fetch(webhookUrl, {
    method: "post",
    contentType: "application/json",
    payload: JSON.stringify(message),
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) {
    throw new Error(`Slack Webhook 응답 ${res.getResponseCode()}`);
  }
}
