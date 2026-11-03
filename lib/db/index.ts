import "server-only";
import { drizzle } from "drizzle-orm/neon-serverless";
import { env } from "@/lib/env";
import * as schema from "./schema";

function createDb() {
  const db = drizzle({ connection: env.DATABASE_URL, schema });
  // 쉬던 연결이 끊기면 Pool이 error 이벤트를 낸다. 받는 곳이 없으면 Node가 프로세스를 끝낸다.
  // WebSocket 오류는 Error가 아닌 이벤트로 올 수 있다.
  db.$client.on("error", (error: unknown) => {
    console.error(`[db] idle connection error: ${error instanceof Error ? error.message : "connection closed"}`);
  });
  return db;
}

let db: ReturnType<typeof createDb> | undefined;

// 첫 호출에서 만든다. 모듈 로드 시점에 만들면 DATABASE_URL 없는 빌드가 실패한다.
export function getDb() {
  db ??= createDb();
  return db;
}
