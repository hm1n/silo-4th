import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs/config";

const nextConfig: NextConfig = {
  /* config options here */
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default withSentryConfig(nextConfig, {
  org: "eb5a968646b3",
  project: "4th-silo",
  // 소스맵 업로드용 빌드 시점 비밀값. 없으면 업로드만 건너뛴다.
  authToken: process.env.SENTRY_AUTH_TOKEN,
  widenClientFileUpload: true,
  // 광고 차단기에 막히지 않도록 이벤트를 앱 경로로 우회한다.
  tunnelRoute: "/monitoring",
  silent: !process.env.CI,
});
