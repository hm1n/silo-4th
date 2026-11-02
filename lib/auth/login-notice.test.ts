import { describe, expect, it } from "vitest";
import { loginNotice } from "./login-notice";

describe("로그인 안내", () => {
  it("TC-4 직접 취소하면 취소 안내를 보여 줘요", () => {
    expect(loginNotice("access_denied")).toBe("로그인을 취소했어요");
  });

  it("TC-10 로그인에 실패하면 다시 시도 안내를 보여 줘요", () => {
    expect(loginNotice("unable_to_create_user")).toBe("로그인하지 못했어요. 다시 시도해 주세요.");
  });
});
