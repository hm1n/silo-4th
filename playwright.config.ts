import { defineConfig, devices } from "@playwright/test";

// E2E는 주요 사용자 흐름만 다룬다: _docs/wiki/adr/0006-test-strategy.md
export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: true,
  },
});
