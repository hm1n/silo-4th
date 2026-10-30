import "server-only";
import { drizzle } from "drizzle-orm/neon-http";
import { env } from "@/lib/env";
import * as schema from "./schema";

function createDb() {
  return drizzle({ connection: env.DATABASE_URL, schema });
}

let db: ReturnType<typeof createDb> | undefined;

// 첫 호출에서 만든다. 모듈 로드 시점에 만들면 DATABASE_URL 없는 빌드가 실패한다.
export function getDb() {
  db ??= createDb();
  return db;
}
