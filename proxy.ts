import { type NextRequest, NextResponse } from "next/server";
import { DIRECT_SOURCE, normalizeSource, SOURCE_COOKIE } from "@/lib/source";

const THIRTY_DAYS = 60 * 60 * 24 * 30;

// Google 로그인을 다녀오면 주소의 `?from=`이 사라진다. 학습자를 만들 때 읽도록 처음 값만 쿠키에 남긴다.
export function proxy(request: NextRequest) {
  const source = normalizeSource(request.nextUrl.searchParams.get("from"));
  if (source === DIRECT_SOURCE) return;

  const response = NextResponse.next();
  response.cookies.set(SOURCE_COOKIE, source, {
    httpOnly: true,
    // Google에서 돌아오는 이동에도 쿠키가 실려야 한다.
    sameSite: "lax",
    secure: request.nextUrl.protocol === "https:",
    path: "/",
    maxAge: THIRTY_DAYS,
  });
  return response;
}

export const config = {
  matcher: [
    {
      source: "/((?!api/|_next/static|_next/image|favicon.ico).*)",
      has: [{ type: "query", key: "from" }],
      missing: [{ type: "cookie", key: "from" }],
    },
  ],
};
