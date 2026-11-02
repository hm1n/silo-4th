"use client";

import { useEffect } from "react";
import { authClient } from "@/lib/auth/client";

// 서버 컴포넌트는 쿠키를 쓸 수 없어 세션을 연장해도 쿠키가 그대로 만료된다.
// 브라우저에서 세션을 한 번 확인하면 하루가 지났을 때 Better Auth가 쿠키를 새로 내려준다.
export function SessionRefresh() {
  useEffect(() => {
    void authClient.getSession();
  }, []);
  return null;
}
