import { describe, expect, it } from "vitest";
import { parseQuizProblem } from "./quiz-problem";

const common = { stem: "WHERE와 HAVING의 차이는?", hint: "그룹을 만든 뒤를 떠올려 보세요", explanation: "HAVING은 그룹 조건이다" };
const mcq = {
  ...common,
  format: "mcq",
  answer: { choices: [{ text: "WHERE 절" }, { text: "HAVING 절" }], answerIndex: 1 },
};
const blank = {
  ...common,
  format: "blank",
  stem: "두 테이블을 공통 컬럼으로 잇는 것을 ____이라고 한다",
  answer: { accepted: ["JOIN", "조인"] },
};
const free = {
  ...common,
  format: "free",
  answer: { modelAnswer: "GROUP BY 뒤 그룹 조건은 HAVING에 쓴다", keyPoints: ["HAVING은 그룹 조건", "WHERE는 행 조건"] },
};

describe("퀴즈 문제 모양 검사", () => {
  it("TC-128 문제 모양을 포맷마다 검사하고, 공백만 있는 값은 빈 값으로 봐요", () => {
    const passing = [
      mcq,
      { ...mcq, answer: { choices: [{ text: "가" }, { text: "나" }, { text: "다" }, { text: "라" }], answerIndex: 3 } },
      blank,
      free,
      { ...mcq, stem: "결과는?\n\n```sql\nSELECT COUNT(*) FROM emp;\n```" },
    ];
    for (const problem of passing) expect(parseQuizProblem(problem)).toEqual(problem);

    const failing: [string, unknown][] = [
      ["범위 밖 answerIndex", { ...mcq, answer: { ...mcq.answer, answerIndex: 2 } }],
      ["음수 answerIndex", { ...mcq, answer: { ...mcq.answer, answerIndex: -1 } }],
      ["보기 1개", { ...mcq, answer: { choices: [{ text: "가" }], answerIndex: 0 } }],
      [
        "보기 5개",
        { ...mcq, answer: { choices: ["가", "나", "다", "라", "마"].map((text) => ({ text })), answerIndex: 0 } },
      ],
      ["공백 보기", { ...mcq, answer: { choices: [{ text: "SELECT 절" }, { text: "  " }], answerIndex: 0 } }],
      ["빈칸 표시 없음", { ...blank, stem: "두 테이블을 잇는 것을 무엇이라 하나" }],
      ["빈칸 표시 둘", { ...blank, stem: "____과 ____의 차이" }],
      ["빈 accepted", { ...blank, answer: { accepted: [] } }],
      ["공백 accepted", { ...blank, answer: { accepted: ["JOIN", "  "] } }],
      ["빈 keyPoints", { ...free, answer: { ...free.answer, keyPoints: [] } }],
      ["공백 keyPoints", { ...free, answer: { ...free.answer, keyPoints: ["HAVING은 그룹 조건", "  "] } }],
      ["알 수 없는 format", { ...free, format: "essay" }],
    ];
    for (const field of ["stem", "hint", "explanation"] as const) {
      for (const value of ["", "  "]) failing.push([`${field} ${JSON.stringify(value)}`, { ...mcq, [field]: value }]);
    }
    for (const value of ["", "  "]) {
      failing.push([`modelAnswer ${JSON.stringify(value)}`, { ...free, answer: { ...free.answer, modelAnswer: value } }]);
    }
    for (const [name, problem] of failing) expect(parseQuizProblem(problem), name).toBeUndefined();
  });
});
