import "server-only";
import { env } from "@/lib/env";
import { anthropic } from "./client";

// 분류는 모든 질문의 첫 글자를 늦추므로 짧게 끊고, 실패하면 과거 요약 없이 답한다.
const CLASSIFY_TIMEOUT_MS = 10_000;
// 요약은 답을 보낸 뒤에 돈다. 분류 10초, 답 240초와 더하면 280초라 DB 왕복을 빼면 Vercel의 300초까지 여유가 적다.
// 넘겨서 함수가 끊겨도 답은 이미 저장돼 있고 요약만 비어 남는다.
const SUMMARY_TIMEOUT_MS = 30_000;

const STRINGS = { type: "array", items: { type: "string" } };

export type Classification = { conceptIds: string[]; keywords: string[] };
export type Summary = { summary: string; keywords: string[] };

// 질문이 개념 목록의 어느 개념에 대한 것인지 고르고 핵심 용어를 뽑는다. 돌려준 ID가 목록에 있는지는 확인하지 않는다.
export async function classifyQuestion(
  question: string,
  concepts: readonly { id: string; title: string }[],
): Promise<Classification> {
  const reply = await askJson({
    system:
      "학습자의 질문이 아래 개념 목록의 어느 개념에 대한 질문인지 고른다. 해당하는 개념이 없으면 conceptIds를 비운다. keywords에는 질문의 핵심 용어를 1~5개 넣는다.",
    content: `<concepts>\n${concepts.map(({ id, title }) => `${id}: ${title}`).join("\n")}\n</concepts>\n\n<question>\n${question}\n</question>`,
    properties: { conceptIds: STRINGS, keywords: STRINGS },
    timeoutMs: CLASSIFY_TIMEOUT_MS,
  });
  return { conceptIds: strings(reply.conceptIds), keywords: strings(reply.keywords) };
}

// 다음 질문의 답변 프롬프트에 원문 대신 넣을 요약을 만든다.
export async function summarizeQuestion(question: string, answer: string): Promise<Summary> {
  const reply = await askJson({
    system:
      "학습자의 질문과 AI의 답을 읽고, 학습자가 무엇을 물었고 어떤 답을 받았는지 한국어 2~3문장, 300자 이내로 요약한다. keywords에는 핵심 용어를 1~5개 넣는다.",
    content: `<question>\n${question}\n</question>\n\n<answer>\n${answer}\n</answer>`,
    properties: { summary: { type: "string" }, keywords: STRINGS },
    timeoutMs: SUMMARY_TIMEOUT_MS,
  });
  if (typeof reply.summary !== "string" || !reply.summary.trim()) throw new Error("AI 요약이 비어 있다.");
  return { summary: reply.summary.trim(), keywords: strings(reply.keywords) };
}

async function askJson({
  system,
  content,
  properties,
  timeoutMs,
}: {
  system: string;
  content: string;
  properties: Record<string, object>;
  timeoutMs: number;
}): Promise<Record<string, unknown>> {
  const abort = new AbortController();
  const timer = setTimeout(
    () => abort.abort(new Error(`AI가 ${timeoutMs / 1000}초 안에 답하지 않았다.`)),
    timeoutMs,
  );
  try {
    const response = await anthropic().messages.create(
      {
        model: env.ANTHROPIC_UTILITY_MODEL,
        max_tokens: 4000,
        output_config: {
          effort: "low",
          format: {
            type: "json_schema",
            schema: { type: "object", properties, required: Object.keys(properties), additionalProperties: false },
          },
        },
        system,
        messages: [{ role: "user", content }],
      },
      { signal: abort.signal },
    );
    if (response.stop_reason !== "end_turn") throw new Error(`AI 응답이 ${response.stop_reason}로 끝났다.`);
    const text = response.content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("");
    return parseObject(text);
  } catch (error) {
    throw abort.signal.aborted ? abort.signal.reason : error;
  } finally {
    clearTimeout(timer);
  }
}

// JSON.parse 오류 메시지는 입력 일부를 담아, 질문 원문이 Sentry로 가지 않게 메시지를 바꾼다.
function parseObject(text: string): Record<string, unknown> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error("AI 응답이 JSON이 아니다.");
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw new Error("AI 응답이 JSON 객체가 아니다.");
  }
  return parsed as Record<string, unknown>;
}

function strings(value: unknown): string[] {
  if (!Array.isArray(value) || !value.every((item) => typeof item === "string")) {
    throw new Error("AI 응답의 목록이 문자열 배열이 아니다.");
  }
  return value;
}
