"use client";

import { useActionState } from "react";
import { submitStart } from "./actions";

export function StartForm() {
  const [state, formAction, pending] = useActionState(submitStart, null);

  return (
    // 폼은 제출이 끝나면 처음 값으로 돌아간다. 낸 값을 처음 값으로 두어 안내를 본 뒤에도 입력이 남는다.
    <form action={formAction} className="flex flex-col gap-4">
      <label className="flex flex-col gap-1">
        시험 날짜
        <input type="date" name="examDate" required defaultValue={state?.examDate} className="border p-2" />
      </label>
      <label className="flex items-start gap-2">
        <input type="checkbox" name="consent" defaultChecked={state?.consented} className="mt-1" />
        공부하며 남긴 질문과 확인 결과를 저장하고 분석하는 데 동의해요
      </label>
      {state && <p role="alert">{state.notice}</p>}
      <button type="submit" disabled={pending} className="border p-2">
        시작하기
      </button>
    </form>
  );
}
