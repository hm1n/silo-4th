import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";
import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { requireLearner } from "@/lib/auth";
import { remarkSectionIds, sectionConceptId, unitSections } from "@/lib/unit-sections";
import { findUnit, listUnits } from "@/lib/units";
import { ScrollToSection } from "../_components/scroll-to-section";
import { UnitBody } from "../_components/unit-body";

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
  const sections = unitSections(current.content);
  const trackedSections = sections.map((section) => ({ key: section.key, conceptId: sectionConceptId(current.id, section) }));

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
              {id === current.id && sections.length > 0 && (
                <nav aria-label="목차">
                  <ul className="mt-1 ml-3 space-y-1 text-sm">
                    {sections.map(({ key, title: sectionTitle }) => (
                      <li key={key}>
                        <a href={`#${key}`} className="block rounded px-2 py-1">
                          {sectionTitle}
                        </a>
                      </li>
                    ))}
                  </ul>
                </nav>
              )}
            </li>
          ))}
        </ul>
        <button type="button" disabled className="mt-4 px-2 py-1">
          내 이해 기록
        </button>
      </nav>
      <UnitBody sections={trackedSections}>
        <Markdown remarkPlugins={[remarkGfm, remarkSectionIds]}>{current.content}</Markdown>
        <ScrollToSection />
      </UnitBody>
    </>
  );
}
