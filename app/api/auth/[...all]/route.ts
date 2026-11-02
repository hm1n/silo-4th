import { toNextJsHandler } from "better-auth/next-js";
import { getAuth } from "@/lib/auth";
import { reportAuthError } from "@/lib/auth/sentry-logger";

// Better Auth가 던진 예외를 그대로 두면 라우터가 쿼리 값이 담긴 원본을 서버 로그에 찍는다.
export const { GET, POST } = toNextJsHandler(async (request) => {
  try {
    return await getAuth().handler(request);
  } catch (error) {
    reportAuthError(error);
    if (request.method === "GET") {
      return Response.redirect(new URL("/?error=internal_server_error", request.url));
    }
    return Response.json({ code: "INTERNAL_SERVER_ERROR" }, { status: 500 });
  }
});
