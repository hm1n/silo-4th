"use client";

import { useParams } from "next/navigation";
import { type KeyboardEvent, useState } from "react";

type Question = { id: string; unitId: string; content: string };

// 실제 전송은 4-60에서 붙인다. 지금은 보낸 질문을 그때 열린 단원과 함께 대화 목록에만 남긴다.
export function QuestionPanel() {
  const { unitId } = useParams<{ unitId: string }>();
  const [questions, setQuestions] = useState<Question[]>([]);

  function send(formData: FormData) {
    const content = String(formData.get("question") ?? "").trim();
    if (!content) return;
    setQuestions((previous) => [...previous, { id: crypto.randomUUID(), unitId, content }]);
  }

  // 한글을 조합하는 중에 누른 Enter는 글자를 확정하는 입력이라 보내지 않는다.
  function sendOnEnter(event: KeyboardEvent<HTMLTextAreaElement>) {
    if (event.key !== "Enter" || event.shiftKey || event.nativeEvent.isComposing) return;
    event.preventDefault();
    event.currentTarget.form?.requestSubmit();
  }

  return (
    <aside aria-label="AI 질문" className="flex w-96 shrink-0 flex-col border-l">
      <ol aria-label="대화" className="flex-1 space-y-2 overflow-y-auto p-4">
        {questions.map(({ id, content }) => (
          <li key={id} className="whitespace-pre-wrap rounded bg-black/5 p-2">
            {content}
          </li>
        ))}
      </ol>
      <form action={send} className="flex gap-2 border-t p-4">
        <textarea
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
