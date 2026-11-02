import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

// 테스트 유형과 범위: _docs/wiki/adr/0006-test-strategy.md
// 단위 테스트는 `*.test.ts`, 통합 테스트는 `*.integration.test.ts`로 이름을 짓는다.
export default defineConfig({
  resolve: {
    tsconfigPaths: true,
    alias: [
      // `lib/db`가 import하는 server-only는 Next.js 밖에서 import하면 오류를 던진다.
      {
        find: /^server-only$/,
        replacement: fileURLToPath(new URL("./node_modules/server-only/empty.js", import.meta.url)),
      },
    ],
  },
  test: {
    environment: "node",
    passWithNoTests: true,
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          include: ["**/*.test.ts"],
          exclude: ["**/*.integration.test.ts", "node_modules/**", "e2e/**"],
        },
      },
      {
        extends: true,
        test: {
          name: "integration",
          include: ["**/*.integration.test.ts"],
          exclude: ["node_modules/**"],
        },
      },
    ],
  },
});
