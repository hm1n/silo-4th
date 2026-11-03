import { NextRequest } from "next/server";
import { expect, it } from "vitest";
import { proxy } from "./proxy";

const windowsChrome =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36";

function visit(path: string, cookie?: string) {
  const headers = new Headers({ "user-agent": windowsChrome });
  if (cookie) headers.set("cookie", cookie);
  return proxy(new NextRequest(`http://localhost:3000${path}`, { headers }));
}

it("TC-16 주소의 출처는 처음 값만 쿠키에 남겨요", () => {
  const first = visit("/?from=school-a");
  expect(first.cookies.get("from")).toMatchObject({ value: "school-a", maxAge: 60 * 60 * 24 * 30 });

  const second = visit("/?from=school-b", "from=school-a");
  expect(second.cookies.get("from")).toBeUndefined();
});

it("TC-44 로그인에 실패해 첫 화면으로 돌아오면 남은 세션 쿠키가 있어도 첫 화면에 머물러요", () => {
  const sessionCookie = "better-auth.session_token=stale.signature";

  expect(visit("/?error=access_denied", sessionCookie).headers.get("location")).toBeNull();
  expect(new URL(visit("/", sessionCookie).headers.get("location") ?? "").pathname).toBe("/study");
});
