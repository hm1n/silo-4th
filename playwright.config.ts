import { existsSync, readFileSync } from "node:fs";
import { parseEnv } from "node:util";
import { defineConfig, devices } from "@playwright/test";

// E2E는 주요 사용자 흐름만 다룬다: _docs/wiki/adr/0006-test-strategy.md
// 테스트 학습자를 만들고 지우므로 통합 테스트와 같은 Neon test 브랜치에 붙는다.
const PORT = 3100;
const baseURL = `http://localhost:${PORT}`;
// 파일이 없으면 개발 서버가 .env.local의 운영 DB로 뜨므로 시작하지 않는다.
if (!existsSync(".env.test.local")) {
  throw new Error(".env.test.local이 없다. README의 통합 테스트와 E2E 항목을 보고 만든다.");
}
const testEnv = { ...parseEnv(readFileSync(".env.test.local", "utf8")), AUTH_URL: baseURL };
// 테스트 코드도 lib/env.ts로 같은 test 브랜치 값을 읽는다.
Object.assign(process.env, testEnv);

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  // 개발 서버는 화면을 처음 열 때 컴파일한다. `.next`가 비어 있으면 여러 화면을 동시에 컴파일하느라 기본 시간을 넘긴다.
  timeout: 60_000,
  expect: { timeout: 15_000 },
  use: {
    baseURL,
    trace: "on-first-retry",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    // 이미 떠 있는 개발 서버는 운영 DB에 붙어 있을 수 있어 다시 쓰지 않는다.
    // Next 16은 한 프로젝트에 개발 서버를 하나만 띄우므로, 먼저 켜 둔 `npm run dev`를 끄고 실행한다.
    command: `npm run dev -- --port ${PORT}`,
    url: baseURL,
    reuseExistingServer: false,
    env: testEnv,
  },
});
