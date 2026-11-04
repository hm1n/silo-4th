import { describe, expect, it } from "vitest";
import { studyDay } from "./study-day";

describe("학습일", () => {
  it("TC-41 학습일은 한국 시간 새벽 4시를 기준으로 나눠요", () => {
    expect(studyDay(new Date("2026-11-04T03:59:00+09:00"))).toBe("2026-11-03");
    expect(studyDay(new Date("2026-11-04T04:00:00+09:00"))).toBe("2026-11-04");
    expect(studyDay(new Date("2026-11-03T20:00:00Z"))).toBe("2026-11-04");
  });
});
