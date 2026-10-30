// 배포 서버의 Neon 연결 확인용 임시 경로다. 프로덕션에서 확인하면 지운다.
import { sql } from "drizzle-orm";
import { connection } from "next/server";
import { getDb } from "@/lib/db";

export async function GET() {
  await connection();
  await getDb().execute(sql`select 1`);
  return Response.json({ ok: true });
}
