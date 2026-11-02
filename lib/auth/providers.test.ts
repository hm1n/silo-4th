import { expect, it } from "vitest";
import { loginButtons } from "./providers";

it("TC-7 켜 둔 로그인 방법만큼 버튼이 나와요", () => {
  expect(loginButtons(["google"])).toEqual([{ provider: "google", label: "Google로 계속하기" }]);
});
