"use client";

import { useParams, useRouter } from "next/navigation";
import { Fragment, type KeyboardEvent, useRef, useState } from "react";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { askQuestion } from "@/lib/answer-stream";

const SLOW_MS = 5_000;

const FAIL_MESSAGES = {
  failed: "답을 가져오지 못했어요. 다시 보내 주세요.",
  cut: "응답이 끊겼어요",
};

type Question = { id: string; unitId: string; content: string };

type Turn = Question &
  (
    | { status: "sending"; answer: string; slow: boolean }
    | { status: "answered"; answer: string }
    | { status: "failed"; reason: keyof typeof FAIL_MESSAGES }
  );

export function QuestionPanel() {
  const { unitId } = useParams<{ unitId: string }>();
  const router = useRouter();
  const [turns, setTurns] = useState<Turn[]>([]);
  const input = useRef<HTMLTextAreaElement>(null);

  function update(id: string, change: (turn: Turn) => Turn) {
    setTurns((previous) => previous.map((turn) => (turn.id === id ? change(turn) : turn)));
  }

  // 다시 보낼 때도 처음 만든 질문 ID와 그때 열려 있던 단원, 원문을 그대로 보내 서버에 한 질문으로 이어지게 한다.
  async function ask(question: Question, replacing = question.id) {
    const sending: Turn = { ...question, status: "sending", answer: "", slow: false };
    setTurns((previous) =>
      previous.some(({ id }) => id === replacing)
        ? previous.map((turn) => (turn.id === replacing ? sending : turn))
        : [...previous, sending],
    );
    const slow = setTimeout(
      () => update(question.id, (turn) => (turn.status === "sending" && !turn.answer ? { ...turn, slow: true } : turn)),
      SLOW_MS,
    );
    const result = await askQuestion({ questionId: question.id, unitId: question.unitId, content: question.content }, (answer) =>
      update(question.id, (turn) => (turn.status === "sending" ? { ...turn, answer } : turn)),
    );
    clearTimeout(slow);
    if (result.ok) {
      update(question.id, () => ({ ...question, status: "answered", answer: result.answer }));
      return;
    }
    const { reason } = result;
    // 첫 화면으로 다시 불러오면 남은 세션 쿠키는 학습 화면의 기존 흐름이 정리한다.
    if (reason === "signed-out") {
      router.replace("/");
      return;
    }
    // 끊긴 뒤에도 서버는 그 질문에 계속 답하고 있을 수 있다. 끝나기를 기다리지 않고 같은 내용을 새 질문으로 묻는다.
    // 새 ID로 다시 물은 질문도 409를 받으면 서버 쪽 문제로 보고 실패로 끝내, 질문이 끝없이 쌓이지 않게 한다.
    if (reason === "pending" && replacing === question.id) {
      return ask({ ...question, id: crypto.randomUUID() }, question.id);
    }
    update(question.id, () => ({ ...question, status: "failed", reason: reason === "pending" ? "failed" : reason }));
  }

  function send(formData: FormData) {
    const content = String(formData.get("question") ?? "").trim();
    if (!content) return;
    void ask({ id: crypto.randomUUID(), unitId, content });
  }

  // 한글을 조합하는 중에 누른 Enter는 글자를 확정하는 입력이라 보내지 않는다.
  function sendOnEnter(event: KeyboardEvent<HTMLTextAreaElement>) {
    if (event.key !== "Enter" || event.shiftKey || event.nativeEvent.isComposing) return;
    event.preventDefault();
    event.currentTarget.form?.requestSubmit();
  }

  const waiting = turns.filter(
    (turn): turn is Extract<Turn, { status: "sending" }> => turn.status === "sending" && !turn.answer,
  );

  return (
    <aside aria-label="AI 질문" className="flex w-96 shrink-0 flex-col border-l">
      <ol aria-label="대화" className="flex-1 space-y-2 overflow-y-auto p-4">
        {turns.map(({ id, unitId: askedUnitId, content, ...turn }) => (
          <Fragment key={id}>
            <li className="whitespace-pre-wrap rounded bg-black/5 p-2">{content}</li>
            {turn.status !== "failed" && turn.answer && (
              <li className="unit-body p-2">
                <Markdown remarkPlugins={[remarkGfm]}>{turn.answer}</Markdown>
              </li>
            )}
            {turn.status === "failed" && (
              <li className="space-y-1 p-2">
                <p role="alert">{FAIL_MESSAGES[turn.reason]}</p>
                <button
                  type="button"
                  onClick={() => {
                    // 누른 버튼이 사라지므로 포커스를 질문 입력으로 옮겨 키보드 사용자가 자리를 잃지 않게 한다.
                    input.current?.focus();
                    void ask({ id, unitId: askedUnitId, content });
                  }}
                  className="rounded border px-3 py-1"
                >
                  다시 시도
                </button>
              </li>
            )}
          </Fragment>
        ))}
      </ol>
      <p role="status" className="px-4 text-sm">
        {waiting.length > 0 && (waiting.some((turn) => turn.slow) ? "답을 기다리는 중이에요" : "답을 준비하고 있어요")}
      </p>
      <form action={send} className="flex gap-2 border-t p-4">
        <textarea
          ref={input}
          name="question"
          aria-label="질문"
          placeholder="읽다가 궁금한 게 생기면 편하게 물어보세요"
          rows={3}
          onKeyDown={sendOnEnter}
          className="flex-1 resize-none rounded border p-2"
        />
        <button type="submit" className="self-end rounded border px-3 py-1">
          보내기
        </button>
      </form>
    </aside>
  );
}
