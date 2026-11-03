import "server-only";
import { asc, eq } from "drizzle-orm";
import { getDb } from "@/lib/db";
import { unit } from "@/lib/db/schema";

// 단원 ID가 출제기준 순서라서 ID 순서가 곧 학습 화면 단원 목록 순서다.
export function listUnits() {
  return getDb().select({ id: unit.id, title: unit.title }).from(unit).orderBy(asc(unit.id));
}

export async function findUnit(id: string) {
  const [found] = await getDb().select().from(unit).where(eq(unit.id, id));
  return found;
}
