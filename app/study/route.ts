import { redirect } from "next/navigation";
import { requireLearner } from "@/lib/auth";
import { listUnits } from "@/lib/units";

// 로그인하면 이 주소로 온다. 페이지 안에서 redirect하면 화면을 그린 뒤 다시 불러오므로, 응답 단계에서 첫 단원 주소로 보낸다.
export async function GET() {
  await requireLearner();
  const [first] = await listUnits();
  if (!first) throw new Error("단원이 없다. 마이그레이션으로 단원을 넣는다.");
  redirect(`/study/${first.id}`);
}
