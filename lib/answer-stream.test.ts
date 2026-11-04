import { expect, it } from "vitest";
import { readAnswer } from "./answer-stream";

// 본문을 바이트 단위로 잘라 보내, 이벤트 중간과 한글 글자 중간에서 끊긴 덩어리를 만든다.
function sse(body: string, { chunkBytes = 3, status = 200 } = {}) {
  const bytes = new TextEncoder().encode(body);
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      for (let start = 0; start < bytes.length; start += chunkBytes) {
        controller.enqueue(bytes.slice(start, start + chunkBytes));
      }
      controller.close();
    },
  });
  return new Response(stream, { status, headers: { "Content-Type": "text/event-stream" } });
}

const delta = (text: string) => `event: delta\ndata: ${JSON.stringify({ text })}\n\n`;

it("TC-53 질문 응답을 읽어 답 조각을 잇고 연결 유지 신호는 건너뛰어요", async () => {
  const body = [delta("안녕"), ": ping\n\n", delta("하세요"), ": ping\n\n", delta("."), "event: done\ndata: {}\n\n"].join("");

  await expect(readAnswer(sse(body))).resolves.toEqual({ ok: true, answer: "안녕하세요." });
});

it("TC-54 응답이 done 없이 끝나거나 성공 코드가 아니면 실패로 봐요", async () => {
  const endsWithError = [delta("WHERE는 "), delta("행을"), "event: error\ndata: {}\n\n"].join("");
  const cutOff = [delta("WHERE는 "), delta("행을")].join("");
  const serverError = new Response(null, { status: 500 });
  const stillAnswering = new Response(null, { status: 409 });

  await expect(readAnswer(sse(endsWithError))).resolves.toEqual({ ok: false, reason: "failed" });
  await expect(readAnswer(sse(cutOff))).resolves.toEqual({ ok: false, reason: "cut" });
  await expect(readAnswer(serverError)).resolves.toEqual({ ok: false, reason: "failed" });
  await expect(readAnswer(stillAnswering)).resolves.toEqual({ ok: false, reason: "pending" });
  await expect(readAnswer(new Response(null, { status: 401 }))).resolves.toEqual({ ok: false, reason: "signed-out" });
  for (const status of [403, 400, 404]) {
    await expect(readAnswer(new Response(null, { status }))).resolves.toEqual({ ok: false, reason: "failed" });
  }
});
