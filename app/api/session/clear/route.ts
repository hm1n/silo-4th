import { type NextRequest, NextResponse } from "next/server";
import { expireSessionCookies, findLearner } from "@/lib/auth";
import { HOME_PATH, STUDY_PATH } from "@/lib/routes";

// 서버 컴포넌트는 쿠키를 지울 수 없어서, 쿠키는 있지만 학습자가 없으면 `requireLearner()`가 이곳으로 보낸다.
// 쿠키를 지워 로그아웃하고 첫 화면으로 보낸다.
export async function GET(request: NextRequest) {
  // 링크만으로 다른 학습자를 로그아웃시키지 못하게, 학습자가 있으면 지우지 않고 학습 화면으로 돌려보낸다.
  if (await findLearner(request.headers)) return NextResponse.redirect(new URL(STUDY_PATH, request.url));

  const response = NextResponse.redirect(new URL(HOME_PATH, request.url));
  await expireSessionCookies(response.cookies);
  return response;
}
