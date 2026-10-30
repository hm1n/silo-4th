import * as Sentry from "@sentry/nextjs";
import { sentryOptions } from "@/lib/sentry";

Sentry.init(sentryOptions);

// App Router 화면 이동을 트레이싱한다.
export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
