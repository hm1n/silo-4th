"use client";

import { authClient } from "@/lib/auth/client";

// 서버 컴포넌트는 쿠키를 쓸 수 없어 세션을 연장해도 쿠키가 그대로 만료된다.
// useSession은 처음 열 때와 탭으로 돌아올 때 세션을 확인하고, 하루가 지났으면 Better Auth가 쿠키를 새로 내려준다.
export function SessionRefresh() {
  authClient.useSession();
  return null;
}
