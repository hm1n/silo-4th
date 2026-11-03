import { expect, it } from "vitest";
import { parseExamDate } from "./exam-date";

it("TC-27 시험 날짜는 한국 시간 자정 기준으로 오늘 이후만 받아요", () => {
  const lastMinute = new Date("2026-11-03T14:59:00Z");
  expect(parseExamDate("2026-11-03", lastMinute)).toEqual({ ok: true, examDate: "2026-11-03" });
  expect(parseExamDate("2026-11-02", lastMinute)).toEqual({ ok: false, error: "past" });

  const midnight = new Date("2026-11-03T15:00:00Z");
  expect(parseExamDate("2026-11-04", midnight)).toEqual({ ok: true, examDate: "2026-11-04" });
  expect(parseExamDate("2026-11-03", midnight)).toEqual({ ok: false, error: "past" });

  expect(parseExamDate("", midnight)).toEqual({ ok: false, error: "required" });
  expect(parseExamDate("2026-02-30", midnight)).toEqual({ ok: false, error: "invalid" });
});
