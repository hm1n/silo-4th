import { QuestionPanel } from "./_components/question-panel";

// 질문 창을 레이아웃에 두어 단원을 옮겨도 대화가 남는다.
export default function UnitLayout({ children }: LayoutProps<"/study">) {
  return (
    <div className="flex h-screen">
      <div className="flex min-w-0 flex-1">{children}</div>
      <QuestionPanel />
    </div>
  );
}
