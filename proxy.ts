import { getSessionCookie } from "better-auth/cookies";
import { type NextRequest, NextResponse } from "next/server";
import { isMobileRequest } from "@/lib/device";
import { HOME_PATH, isStudyPath, MOBILE_NOTICE_PATH } from "@/lib/routes";
import { DIRECT_SOURCE, normalizeSource, SOURCE_COOKIE } from "@/lib/source";

const THIRTY_DAYS = 60 * 60 * 24 * 30;

// 모바일 판별, 출처 쿠키, 학습 화면 접근 확인 순서로 본다.
export function proxy(request: NextRequest) {
  // 모바일 화면은 만들지 않는다. 주소는 그대로 두고 안내 화면을 보여 줘야 `?from=`까지 복사할 수 있다.
  if (isMobileRequest(request.headers)) {
    return NextResponse.rewrite(new URL(MOBILE_NOTICE_PATH, request.url));
  }
  // PC에서 안내 화면 주소로 바로 들어오거나 세션 쿠키 없이 학습 화면에 들어오면 첫 화면으로 보낸다.
  // 학습 화면은 쿠키만 보고 빠르게 돌려보내고, 학습자와 저장 동의는 `requireLearner()`가 DB로 다시 확인한다.
  // 돌려보낼 때도 주소의 `?from=`이 사라지므로 출처 쿠키를 남긴다.
  const sendHome =
    request.nextUrl.pathname === MOBILE_NOTICE_PATH ||
    (isStudyPath(request.nextUrl.pathname) && !getSessionCookie(request));
  const response = sendHome ? NextResponse.redirect(new URL(HOME_PATH, request.url)) : NextResponse.next();
  keepSource(request, response);
  return response;
}

// Google 로그인을 다녀오면 주소의 `?from=`이 사라진다. 학습자를 만들 때 읽도록 처음 값만 쿠키에 남긴다.
function keepSource(request: NextRequest, response: NextResponse) {
  if (request.cookies.has(SOURCE_COOKIE)) return;
  const source = normalizeSource(request.nextUrl.searchParams.get("from"));
  if (source === DIRECT_SOURCE) return;

  response.cookies.set(SOURCE_COOKIE, source, {
    httpOnly: true,
    // Google에서 돌아오는 이동에도 쿠키가 실려야 한다.
    sameSite: "lax",
    secure: request.nextUrl.protocol === "https:",
    path: "/",
    maxAge: THIRTY_DAYS,
  });
}

export const config = {
  // `monitoring`은 Sentry 이벤트를 보내는 경로라 모바일 안내 화면으로 바꾸면 안 된다.
  matcher: ["/((?!api/|_next/static|_next/image|favicon.ico|monitoring).*)"],
};
