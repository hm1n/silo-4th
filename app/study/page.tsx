import { Suspense } from "react";
import { requireLearner } from "@/lib/auth";

// 학습 화면의 실제 내용은 질문, 확인 기능 이슈에서 만든다.
export default function StudyPage() {
  return (
    <main>
      <Suspense>
        <LearnerId />
      </Suspense>
    </main>
  );
}

// 레이아웃은 같은 레이아웃 안에서 페이지를 옮길 때 다시 그려지지 않으므로 페이지에서도 확인한다.
async function LearnerId() {
  const learner = await requireLearner();
  // 개발 중 확인용이다.
  return <p>현재 학습자 ID: {learner.id}</p>;
}
