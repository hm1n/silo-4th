import { expect, it } from "vitest";
import { normalizeSource } from "./source";

it("TC-15 출처 값을 정리하고, 형식에 맞지 않으면 direct로 남겨요", () => {
  expect(normalizeSource("  School-A  ")).toBe("school-a");
  expect(normalizeSource("a".repeat(32))).toBe("a".repeat(32));

  for (const invalid of [undefined, null, "", "a".repeat(33), "school a", "학교"]) {
    expect(normalizeSource(invalid)).toBe("direct");
  }
});
