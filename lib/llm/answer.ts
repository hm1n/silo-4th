import "server-only";
import Anthropic from "@anthropic-ai/sdk";
import { env } from "@/lib/env";

// Vercel Hobby는 함수를 300초에 끊는다. 끊기면 질문이 pending에 남으므로, 재시도까지 합쳐 그 전에 끝내고 error로 남긴다.
const ANSWER_DEADLINE_MS = 240_000;
// 학습자가 답이 시작되기를 마냥 기다리지 않게, 첫 글자가 늦으면 실패로 끝내고 다시 시도하게 한다.
const FIRST_TEXT_TIMEOUT_MS = 60_000;

let client: Anthropic | undefined;

// 학습자가 읽고 있던 단원 본문과 같은 대화의 앞 질문과 답을 함께 넘겨, 그 내용을 알고 답하게 한다.
// 답 글이 생기는 대로 onText로 넘기고, 끝까지 받은 답 전체를 돌려준다. 답을 끝까지 받지 못하면 예외를 던진다.
export async function streamAnswer(
  { unitContent, history, question }: { unitContent: string; history: Anthropic.MessageParam[]; question: string },
  onText: (text: string) => void,
) {
  client ??= new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const abort = new AbortController();
  const firstText = setTimeout(
    () => abort.abort(new Error(`AI가 ${FIRST_TEXT_TIMEOUT_MS / 1000}초 안에 답을 시작하지 않았다.`)),
    FIRST_TEXT_TIMEOUT_MS,
  );
  const deadline = setTimeout(
    () => abort.abort(new Error(`AI가 ${ANSWER_DEADLINE_MS / 1000}초 안에 답을 끝내지 않았다.`)),
    ANSWER_DEADLINE_MS,
  );
  try {
    const stream = client.messages.stream(
      {
        model: env.ANTHROPIC_MODEL,
        max_tokens: 16000,
        // 학습 중에 바로 읽을 답이라 깊이 생각하기보다 빨리 답하게 한다.
        output_config: { effort: "low" },
        system: [
          { type: "text", text: "학습자가 아래 단원을 읽다가 질문했다. 단원 내용을 바탕으로 한국어로 답한다." },
          { type: "text", text: `<unit>\n${unitContent}\n</unit>`, cache_control: { type: "ephemeral" } },
        ],
        messages: [...history, { role: "user", content: question }],
      },
      { signal: abort.signal },
    );
    for await (const event of stream) {
      if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
        clearTimeout(firstText);
        onText(event.delta.text);
      }
    }
    const response = await stream.finalMessage();
    if (response.stop_reason === "refusal") throw new Error("AI가 답을 거절했다.");
    if (response.stop_reason === "max_tokens" || response.stop_reason === "model_context_window_exceeded") {
      throw new Error("AI 답이 길이 제한에서 끊겼다.");
    }
    const answer = response.content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("");
    if (!answer.trim()) throw new Error("AI 답이 비어 있다.");
    return answer;
  } catch (error) {
    // SDK는 어느 제한에 걸렸는지 없이 중단 오류만 던진다. 제한 시간을 조정할 수 있게 걸린 제한을 Sentry에 남긴다.
    throw abort.signal.aborted ? abort.signal.reason : error;
  } finally {
    clearTimeout(firstText);
    clearTimeout(deadline);
  }
}
