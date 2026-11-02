import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient();

// 클라이언트는 서버 오류를 `{ error }`로 돌려주고, 네트워크가 끊기면 예외를 던진다. 둘 다 실패로 본다.
export async function succeeded(request: Promise<{ error: unknown }>) {
  try {
    return !(await request).error;
  } catch {
    return false;
  }
}
