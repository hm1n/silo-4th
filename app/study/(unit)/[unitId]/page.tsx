import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { requireLearner } from "@/lib/auth";
import { findUnit, listUnits } from "@/lib/units";

type Params = PageProps<"/study/[unitId]">["params"];

export default function UnitPage({ params }: { params: Params }) {
  return (
    <Suspense>
      <StudyUnit params={params} />
    </Suspense>
  );
}

// 레이아웃은 단원을 옮길 때 다시 그려지지 않으므로 페이지에서도 확인한다.
async function StudyUnit({ params }: { params: Params }) {
  await requireLearner();
  const { unitId } = await params;
  const [units, current] = await Promise.all([listUnits(), findUnit(unitId)]);
  if (!current) notFound();

  return (
    <>
      <nav aria-label="단원" className="w-56 shrink-0 overflow-y-auto border-r p-4">
        <ul className="space-y-1">
          {units.map(({ id, title }) => (
            <li key={id}>
              <Link
                href={`/study/${id}`}
                aria-current={id === current.id ? "page" : undefined}
                className="block rounded px-2 py-1 aria-[current=page]:font-bold"
              >
                {title}
              </Link>
            </li>
          ))}
        </ul>
        <button type="button" disabled className="mt-4 px-2 py-1">
          내 이해 기록
        </button>
      </nav>
      <article className="unit-body min-w-0 flex-1 overflow-y-auto p-8">
        <Markdown remarkPlugins={[remarkGfm]}>{current.content}</Markdown>
      </article>
    </>
  );
}
