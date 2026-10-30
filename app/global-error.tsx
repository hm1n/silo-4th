"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";

// 루트 레이아웃에서 난 오류는 Next.js가 먼저 잡으므로 여기서 Sentry로 보낸다.
export default function GlobalError({ error, retry }: { error: unknown; retry: () => void }) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="ko">
      <body>
        <h2>문제가 생겼어요.</h2>
        <button onClick={() => retry()}>다시 시도</button>
      </body>
    </html>
  );
}
